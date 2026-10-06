// SPDX-License-Identifier: AGPL-3.0-or-later
import * as ROT from 'rot-js';
new ROT.Path.AStar(2, 2, (_x, _y) => true, { topology: 5 }); // expect TS2322
