// SPDX-License-Identifier: GPL-3.0-or-later
// External Ink consumer: an ordinary interactive counter built only from
// Ink's public API.  It reads real keypresses from its controlling terminal;
// "a" increments the counter and "q" exits through useApp().exit().
import React, {useState} from 'react';
import {Box, Text, render, useApp, useInput} from 'ink';

const h = React.createElement;

function Counter() {
	const [count, setCount] = useState(0);
	const {exit} = useApp();
	useInput(input => {
		if (input === 'a') {
			setCount(previous => previous + 1);
		} else if (input === 'q') {
			exit(count);
		}
	});
	return h(
		Box,
		{flexDirection: 'column', borderStyle: 'round', borderColor: 'cyan', paddingX: 1, width: 40},
		h(Text, {bold: true, color: 'green'}, 'Ink カウンター ✓'),
		h(
			Box,
			null,
			h(Text, null, 'count: '),
			h(Text, {bold: true, color: 'yellow'}, String(count)),
		),
		h(Text, {color: 'magenta'}, 'a: +1 · q: quit'),
	);
}

const instance = render(h(Counter), {patchConsole: false});
const finalCount = await instance.waitUntilExit();
process.stdout.write(`INK_COUNTER_EXIT count=${finalCount}\n`);
