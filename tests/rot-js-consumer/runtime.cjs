// SPDX-License-Identifier: AGPL-3.0-or-later
// A real Node consumer of the installed native ESM, readable UMD and minified UMD builds.
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {pathToFileURL} = require('node:url');
const EXPORTS = ['Color','DEFAULT_HEIGHT','DEFAULT_WIDTH','DIRS','Display','Engine','EventQueue','FOV',
                 'KEYS','Lighting','Map','Noise','Path','RNG','Scheduler','StringGenerator','Text','Util'];
const root = fs.realpathSync(process.argv[2]);
const evidence = process.argv[3];
const key = (x, y) => `${x},${y}`;
const directions = [[0,-1],[1,0],[0,1],[-1,0]];
const digest = value => crypto.createHash('sha256').update(JSON.stringify(value)).digest('hex');
assert.equal(fs.realpathSync(require.resolve('rot-js')), path.join(root, 'dist/rot.js'));

function dungeon(ROT) {
    ROT.RNG.setSeed(151);
    const width = 40, height = 25;
    const cells = new Map();
    // Fixed seed and finite small dimensions; runtime timeout enforces a bound.
    // Infinity prevents Digger's wall-clock escape from accepting a partial map.
    const digger = new ROT.Map.Digger(width, height, {timeLimit: Infinity});
    digger.create((x, y, value) => {
        assert.ok(Number.isInteger(x) && x >= 0 && x < width);
        assert.ok(Number.isInteger(y) && y >= 0 && y < height);
        assert.ok(value === 0 || value === 1);
        assert.equal(cells.has(key(x,y)), false, 'duplicate map callback');
        cells.set(key(x,y), value);
    });
    assert.equal(cells.size, width * height);
    const rows = Array.from({length: height}, (_, y) =>
        Array.from({length: width}, (_, x) => cells.get(key(x,y)) === 0 ? '.' : '#').join(''));
    const passable = (x, y) => cells.get(key(x,y)) === 0;
    for (let x = 0; x < width; x++) {
        assert.equal(passable(x,0), false); assert.equal(passable(x,height-1), false);
    }
    for (let y = 0; y < height; y++) {
        assert.equal(passable(0,y), false); assert.equal(passable(width-1,y), false);
    }
    const rooms = digger.getRooms().map(room => {
        const bounds = [room.getLeft(),room.getTop(),room.getRight(),room.getBottom()];
        for (let x = bounds[0]; x <= bounds[2]; x++) {
            for (let y = bounds[1]; y <= bounds[3]; y++) assert.equal(passable(x,y), true);
        }
        room.getDoors((x,y) => assert.equal(passable(x,y), true));
        assert.equal(passable(...room.getCenter()), true);
        return bounds;
    });
    // Digger promises an initial room; this is structural, not a floor-count heuristic.
    assert.ok(rooms.length !== 0);
    const floor = [...cells].filter(([, value]) => value === 0).map(([id]) => id.split(',').map(Number));
    const start = digger.getRooms()[0].getCenter();
    // Independent four-neighbour BFS, not ROT.Path or a duplicate library algorithm.
    const distances = new Map([[key(...start), 0]]), queue = [start];
    for (let i = 0; i < queue.length; i++) {
        const [x,y] = queue[i];
        for (const [dx,dy] of directions) {
            const nx=x+dx, ny=y+dy, id=key(nx,ny);
            if (passable(nx,ny) && !distances.has(id)) {
                distances.set(id, distances.get(key(x,y))+1); queue.push([nx,ny]);
            }
        }
    }
    assert.equal(distances.size, floor.length, 'all generated floors must be connected');
    // Both algorithms must reach EVERY floor by a shortest passable route.
    const routes = {};
    for (const algorithm of ['AStar', 'Dijkstra']) {
        routes[algorithm] = [];
        for (const end of floor) {
            const route=[];
            new ROT.Path[algorithm](...end,passable,{topology:4})
                .compute(...start,(x,y)=>route.push([x,y]));
            assert.equal(route.length, distances.get(key(...end))+1);
            assert.deepEqual(route[0],start); assert.deepEqual(route.at(-1),end);
            route.forEach(([x,y],i) => {
                assert.equal(passable(x,y),true);
                if (i) assert.equal(Math.abs(x-route[i-1][0])+Math.abs(y-route[i-1][1]),1);
            });
            routes[algorithm].push(route);
        }
        const unreachable=[];
        new ROT.Path[algorithm](...start,passable,{topology:4})
            .compute(0,0,(x,y)=>unreachable.push([x,y]));
        assert.deepEqual(unreachable, [], 'wall origin is unreachable');
    }
    return {rows, rooms, corridors: digger.getCorridors().length, floors: floor.length,
            connected: distances.size, start, maximumDistance: Math.max(...distances.values()),
            routes: {AStar: digest(routes.AStar), Dijkstra: digest(routes.Dijkstra)}};
}

function fov(ROT) {
    const collect = (lightPasses, radius) => {
        const cells = [];
        new ROT.FOV.PreciseShadowcasting(lightPasses).compute(0,0,radius,
            (x,y,range,visibility)=>cells.push([x,y,range,visibility]));
        return cells.sort((a,b)=>a[0]-b[0] || a[1]-b[1]);
    };
    // Open space: every Chebyshev-ring tile has exact full visibility.
    const openExpected=[];
    for (let x=-3; x<=3; x++) for(let y=-3;y<=3;y++)
        openExpected.push([x,y,Math.max(Math.abs(x),Math.abs(y)),1]);
    const open=collect(()=>true,3);
    assert.deepEqual(open,openExpected);
    // Eight opaque neighbours are visible, but form a complete shadow ring.
    const enclosedExpected=[];
    for (let x=-1;x<=1;x++) for(let y=-1;y<=1;y++)
        enclosedExpected.push([x,y,Math.max(Math.abs(x),Math.abs(y)),1]);
    const enclosed=collect((x,y)=>x===0 && y===0,3);
    assert.deepEqual(enclosed,enclosedExpected);
    assert.deepEqual(collect(()=>false,3),[[0,0,0,1]], 'opaque origin only');
    assert.deepEqual(collect(()=>true,0),[[0,0,0,1]], 'zero radius only');
    return {open,enclosed,opaqueOrigin:[[0,0,0,1]],zeroRadius:[[0,0,0,1]]};
}

function schedules(ROT) {
    const simple = new ROT.Scheduler.Simple();
    simple.add('hero',true).add('once',false).add('monster',true);
    const simpleTurns=Array.from({length:6},()=>simple.next());
    assert.deepEqual(simpleTurns,['hero','once','monster','hero','monster','hero']);
    assert.equal(simple.remove('monster'),true);
    assert.equal(simple.remove('absent'),false);
    assert.equal(simple.next(),'hero');
    simple.clear(); assert.equal(simple.next(),null); assert.equal(simple.getTime(),0);

    const fast={name:'fast',getSpeed:()=>2}, slow={name:'slow',getSpeed:()=>1};
    const speed = new ROT.Scheduler.Speed();
    speed.add(fast,true).add(slow,true);
    const speedTurns=Array.from({length:6},()=>[speed.next().name,speed.getTime()]);
    assert.deepEqual(speedTurns,[['fast',0.5],['slow',1],['fast',1],
                                ['fast',1.5],['slow',2],['fast',2]]);
    speed.clear(); assert.equal(speed.next(),null); assert.equal(speed.getTime(),2);

    const action=new ROT.Scheduler.Action();
    action.add('hero',true,1).add('monster',true,2);
    const actionTurns=[[action.next(),action.getTime()]];
    action.setDuration(3);
    actionTurns.push([action.next(),action.getTime()]);
    action.setDuration(1);
    actionTurns.push([action.next(),action.getTime()]);
    actionTurns.push([action.next(),action.getTime()]);
    assert.deepEqual(actionTurns,[['hero',1],['monster',2],['monster',3],['hero',4]]);
    const queue = new ROT.EventQueue();
    queue.add('late',3); queue.add('early',1); queue.add('tie',1);
    const events=Array.from({length:3},()=>[queue.get(),queue.getTime()]);
    assert.deepEqual(events,[['early',1],['tie',1],['late',3]]);
    assert.equal(queue.get(),null);
    const turns=[];
    const actors=new ROT.Scheduler.Simple();
    actors.add({act:()=>turns.push('hero')},false).add({act:()=>turns.push('monster')},false);
    new ROT.Engine(actors).start();
    assert.deepEqual(turns,['hero','monster']);
    return {simpleTurns,speedTurns,actionTurns,events,engineTurns:turns};
}

async function main() {
    const reports=[];
    const builds=[['lib/index.js','esm'],['dist/rot.js','umd'],['dist/rot.min.js','umd']];
    for (const [bundle,kind] of builds) {
        const resolved=fs.realpathSync(path.join(root,bundle));
        assert.equal(resolved,path.join(root,bundle));
        const ROT=kind==='esm' ? await import(pathToFileURL(resolved).href) : require(resolved);
        assert.deepEqual(Object.keys(ROT).filter(name=>name!=='default').sort(), EXPORTS);
        const first=dungeon(ROT), repeat=dungeon(ROT);
        assert.deepEqual(repeat,first,'seed reset must reproduce full map and paths');
        const semantics={dungeon:first,fov:fov(ROT),schedulers:schedules(ROT)};
        if (reports.length) assert.deepEqual(semantics,reports[0].semantics,`${bundle} changed semantics`);
        reports.push({bundle,kind,resolved,sha256:crypto.createHash('sha256').update(fs.readFileSync(resolved)).digest('hex'),semantics});
    }
    fs.writeFileSync(evidence,JSON.stringify(reports,null,2)+'\n');
    console.log('ROT_JS_RUNTIME_OK builds=3 seed=151 connectivity=all-floors shortest-paths=all-floors fov=exact schedulers=exact');
}
main().catch(error=>{ console.error(error); process.exitCode=1; });
