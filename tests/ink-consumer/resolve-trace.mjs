// SPDX-License-Identifier: GPL-3.0-or-later
// Pass-through module resolution recorder for the resolution preflight only;
// it never runs in the PTY session and never alters a resolution result.
import {appendFileSync} from 'node:fs';
import {registerHooks} from 'node:module';

const trace = process.env.INK_RESOLVE_TRACE;
registerHooks({
	resolve(specifier, context, nextResolve) {
		const result = nextResolve(specifier, context);
		appendFileSync(trace, JSON.stringify({
			specifier,
			parent: context.parentURL ?? null,
			url: result.url,
		}) + '\n');
		return result;
	},
});
