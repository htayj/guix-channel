// SPDX-License-Identifier: GPL-3.0-or-later
// Materialize npm's bin links and copy only the selected installation graph.
// Archives and paths are fixed by ink-package-lock.json, never resolved here.
import fs from 'node:fs';
import path from 'node:path';

const [operation, ...args] = process.argv.slice(2);
const lock = JSON.parse(fs.readFileSync('package-lock.json', 'utf8'));

if (operation === 'bins') {
  for (const [location, metadata] of Object.entries(lock.packages)) {
    if (!location || metadata.os || metadata.cpu || !fs.existsSync(location)) {
      continue;
    }

    const manifest = JSON.parse(fs.readFileSync(`${location}/package.json`, 'utf8'));
    const bins = typeof manifest.bin === 'string'
      ? {[manifest.name.split('/').at(-1)]: manifest.bin}
      : manifest.bin ?? {};
    const modules = location.slice(0, location.lastIndexOf('node_modules/') + 12);
    const directory = `${modules}/.bin`;
    for (const [name, target] of Object.entries(bins)) {
      const file = path.resolve(location, target);
      if (!fs.existsSync(file)) {
        throw new Error(`Missing locked executable ${file}`);
      }

      fs.mkdirSync(directory, {recursive: true});
      const link = `${directory}/${name}`;
      if (!fs.existsSync(link)) {
        fs.symlinkSync(path.relative(path.resolve(directory), file), link);
      }

      // Source-built replacements are immutable store packages; their bins
      // must already be executable.  Only normalize extracted archive files.
      const mode = fs.statSync(file).mode;
      if ((mode & 0o111) !== 0o111) {
        if (fs.realpathSync(file).startsWith('/gnu/store/')) {
          throw new Error(`Non-executable source package binary ${file}`);
        }

        fs.chmodSync(file, mode | 0o111);
      }
    }
  }
} else if (operation === 'install') {
  const [output, ...locations] = args;
  const module = `${output}/lib/node_modules/ink`;
  fs.mkdirSync(module, {recursive: true});
  for (const file of ['build', 'license', 'readme.md']) {
    fs.cpSync(file, `${module}/${file}`, {recursive: true, dereference: true});
  }

  const manifest = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  delete manifest.devDependencies;
  delete manifest.scripts;
  fs.writeFileSync(`${module}/package.json`, `${JSON.stringify(manifest, null, '\t')}\n`);
  for (const location of locations) {
    const sibling = ['node_modules/react', 'node_modules/@types/react', 'node_modules/csstype'].includes(location);
    const destination = sibling
      ? `${output}/lib/${location}`
      : `${module}/${location}`;
    // Do not pull hoisted/nested development packages into a runtime parent.
    // Every selected nested runtime path is copied separately below.
    fs.cpSync(location, destination, {
      recursive: true,
      dereference: true,
      filter: source => source === location || path.basename(source) !== 'node_modules',
    });
  }
} else {
  throw new Error(`Unknown closure operation ${operation}`);
}
