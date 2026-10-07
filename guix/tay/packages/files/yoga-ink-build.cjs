// SPDX-License-Identifier: GPL-3.0-or-later
// Run Yoga's prepack transformations without just-scripts or npm lifecycle hooks.
const fs = require('node:fs');
const path = require('node:path');
const {createRequire} = require('node:module');

const root = process.cwd();
const localRequire = createRequire(path.join(root, 'package.json'));
const babel = localRequire('@babel/core');
const typescript = localRequire('typescript');

// The public declaration surface is src, not the upstream Jest test suite.
// Keep the upstream TS 5.0 compiler options, including .ts import specifiers.
const configFile = typescript.readConfigFile('tsconfig.json', typescript.sys.readFile);
if (configFile.error) {
  throw new Error(typescript.flattenDiagnosticMessageText(configFile.error.messageText, '\n'));
}
const config = typescript.parseJsonConfigFileContent({
  ...configFile.config,
  include: ['src/**/*'],
  compilerOptions: {
    ...configFile.config.compilerOptions,
    types: [],
    emitDeclarationOnly: true,
    rootDir: '.',
    declarationDir: 'dist',
  },
}, typescript.sys, root);
const program = typescript.createProgram(config.fileNames, config.options);
const emitted = program.emit();
const diagnostics = [...config.errors, ...typescript.getPreEmitDiagnostics(program), ...emitted.diagnostics];
if (diagnostics.length || emitted.emitSkipped) {
  process.stderr.write(typescript.formatDiagnosticsWithColorAndContext(diagnostics, {
    getCanonicalFileName: file => file,
    getCurrentDirectory: () => root,
    getNewLine: () => '\n',
  }));
  throw new Error('Yoga declaration compilation failed');
}

function transform(directory) {
  for (const entry of fs.readdirSync(directory, {withFileTypes: true}).sort((a, b) => a.name.localeCompare(b.name, 'en'))) {
    const source = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      transform(source);
    } else if (entry.isFile() && /\.(?:js|cjs|mjs|ts|cts|mts)$/.test(entry.name) && !entry.name.endsWith('.d.ts')) {
      const relative = path.relative('src', source);
      const destination = path.join('dist/src', relative.replace(/\.(?:ts|cts|mts)$/, extension => ({'.ts': '.js', '.cts': '.cjs', '.mts': '.mjs'})[extension]));
      const result = babel.transformFileSync(source, {
        configFile: path.join(root, 'babel.config.cjs'),
        envName: 'dist',
        sourceMaps: true,
        sourceFileName: path.relative(path.dirname(destination), source),
      });
      if (!result || typeof result.code !== 'string' || !result.map) {
        throw new Error(`Babel did not transform ${source}`);
      }
      fs.mkdirSync(path.dirname(destination), {recursive: true});
      fs.writeFileSync(destination, `${result.code}\n//# sourceMappingURL=${path.basename(destination)}.map\n`);
      fs.writeFileSync(`${destination}.map`, `${JSON.stringify(result.map)}\n`);
    }
  }
}
transform('src');
fs.cpSync('binaries', 'dist/binaries', {recursive: true});

// Exactly the export-path rewrite used by upstream prepack-package-json.
const manifest = JSON.parse(fs.readFileSync('package.json', 'utf8'));
const distributionPath = value => value.replace(/^\.\/src\/(.*)\.ts/, './dist/src/$1.js');
function rewriteExports(value) {
  if (typeof value === 'string') return distributionPath(value);
  if (value && typeof value === 'object') {
    for (const key of Object.keys(value)) value[key] = rewriteExports(value[key]);
  }
  return value;
}
manifest.main = distributionPath(manifest.main);
manifest.types = manifest.main.replace(/(.*)\.js/, '$1.d.ts');
manifest.exports = rewriteExports(manifest.exports);
fs.writeFileSync('package.json', `${JSON.stringify(manifest, null, 2)}\n`);
