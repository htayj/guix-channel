// SPDX-License-Identifier: AGPL-3.0-or-later
// Public package import: no checkout imports, ambient substitutes or skipLibCheck.
import * as ROT from 'rot-js';
import type { SpeedActor } from 'rot-js';

function equal(actual: unknown, expected: unknown): void {
    if (JSON.stringify(actual) !== JSON.stringify(expected)) {
        throw new Error(`typed consumer: ${JSON.stringify(actual)} != ${JSON.stringify(expected)}`);
    }
}
const cells: number[][] = Array.from({length: 5}, () => Array<number>(5).fill(-1));
const arena = new ROT.Map.Arena(5, 5);
arena.create((x: number, y: number, contents: number) => { cells[x][y] = contents; });
const passable = (x: number, y: number): boolean => cells[x]?.[y] === 0;
equal(cells.flat().filter(value => value === 0).length, 9);
const route: number[][] = [];
new ROT.Path.AStar(3, 1, passable, {topology: 4})
    .compute(1, 1, (x: number, y: number) => route.push([x, y]));
equal(route, [[1, 1], [2, 1], [3, 1]]);
const visibility: number[][] = [];
new ROT.FOV.PreciseShadowcasting(passable).compute(2, 2, 1,
    (x: number, y: number, range: number, fraction: number) => {
        visibility.push([x, y, range, fraction]);
    });
equal(visibility, [[2,2,0,1],[1,3,1,1],[1,2,1,1],[1,1,1,1],
                   [2,1,1,1],[3,1,1,1],[3,2,1,1],[3,3,1,1],[2,3,1,1]]);
interface Actor extends SpeedActor { name: string; }
const actor: Actor = {name: 'typed-hero', getSpeed: () => 2};
const scheduler = new ROT.Scheduler.Speed<Actor>();
scheduler.add(actor, false);
if (scheduler.next() !== actor) { throw new Error('typed consumer: Speed scheduler lost actor identity'); }
equal(scheduler.getTime(), 0.5);
equal(scheduler.next(), null);
const rng: number[] = ROT.RNG.setSeed(151).getState();
ROT.RNG.setState(rng);
equal(ROT.RNG.getSeed(), 151);
console.log(JSON.stringify({arenaFloors: cells.flat().filter(value => value === 0).length,
                            path: route, visible: visibility.length, actor: actor.name,
                            time: scheduler.getTime(), seed: ROT.RNG.getSeed()}));
