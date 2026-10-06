#!/usr/bin/env node
// SPDX-License-Identifier: AGPL-3.0-or-later
// Run with the source root or an installed lib/node_modules/rot-js directory.
'use strict';
const assert = require('node:assert/strict');
const path = require('node:path');
const fs = require('node:fs');
const root = path.resolve(process.argv[2]);
assert.equal(JSON.parse(fs.readFileSync(path.join(root, 'package.json'))).version, '2.2.1');
for (const filename of ['dist/rot.js', 'dist/rot.min.js']) {
    const ROT = require(path.join(root, filename));
    ROT.RNG.setSeed(151);
    const cells = new Map();
    const width = 40, height = 25;
    new ROT.Map.Digger(width, height, { timeLimit: 5000 }).create((x, y, value) => {
        assert.ok(x >= 0 && x < width && y >= 0 && y < height);
        assert.ok(value === 0 || value === 1);
        cells.set(`${x},${y}`, value);
    });
    assert.equal(cells.size, width * height);
    const floor = [...cells].filter(([, value]) => value === 0)
        .map(([key]) => key.split(',').map(Number));
    assert.ok(floor.length > 10, 'Digger generated real traversable terrain');
    const start = floor[0], end = floor[floor.length - 1];
    const passable = (x, y) => cells.get(`${x},${y}`) === 0;
    const route = [];
    new ROT.Path.AStar(...end, passable, { topology: 4 })
        .compute(...start, (x, y) => route.push([x, y]));
    assert.ok(route.length > 1, 'AStar found a route through the generated dungeon');
    // rot.js reports the route from the compute() origin toward the target.
    assert.deepEqual(route[0], start);
    assert.deepEqual(route[route.length - 1], end);
    route.forEach(([x, y], index) => {
        assert.ok(passable(x, y));
        if (index) assert.equal(Math.abs(x - route[index - 1][0]) + Math.abs(y - route[index - 1][1]), 1);
    });
    let visible = 0;
    new ROT.FOV.PreciseShadowcasting(passable).compute(...start, 8, (x, y, range, visibility) => {
        assert.ok(range >= 0 && range <= 8);
        assert.ok(visibility >= 0 && visibility <= 1);
        visible++;
    });
    assert.ok(visible > 1);
    const scheduler = new ROT.Scheduler.Simple();
    scheduler.add('hero', true).add('monster', true);
    assert.equal(scheduler.next(), 'hero');
    assert.equal(scheduler.next(), 'monster');
    assert.equal(scheduler.next(), 'hero');
    console.log(`${filename}: Digger ${floor.length} floor cells, AStar ${route.length} steps, FOV ${visible}, scheduler passed`);
}
