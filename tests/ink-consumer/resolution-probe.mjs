// SPDX-License-Identifier: GPL-3.0-or-later
// Load the same public entry points counter.mjs imports, without rendering.
import React from 'react';
import * as ink from 'ink';

const api = {};
for (const name of ['render', 'useInput', 'useApp', 'Box', 'Text']) {
	api[name] = typeof ink[name];
}
process.stdout.write(JSON.stringify({reactVersion: React.version, api}) + '\n');
