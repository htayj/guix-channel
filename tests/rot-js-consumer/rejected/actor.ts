// SPDX-License-Identifier: AGPL-3.0-or-later
import * as ROT from 'rot-js';
new ROT.Scheduler.Speed().add({ getSpeed: () => 'fast' }, true); // expect TS2322
