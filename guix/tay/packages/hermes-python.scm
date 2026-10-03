;;; Binary-assisted, immutable Python runtime for Hermes.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages hermes-python)
  #:use-module (guix gexp)
  #:export (%hermes-wheel-installer %hermes-bytecode-normalizer))

;; The wheel archives retain their complete data and license trees.  Installing
;; without pip avoids resolving dependencies or contacting an index at build or
;; run time.  All archives are immutable origins from the release's uv.lock.
(define %hermes-wheel-installer
  (plain-file
   "install-hermes-wheels.py"
   "import configparser
import os
from pathlib import Path
import subprocess
import sys
import zipfile

out = Path(sys.argv[1])
python = sys.argv[2]
external = sys.argv[3].split(':')
site = out / 'lib/python3.11/site-packages'
site.mkdir(parents=True, exist_ok=True)
(out / 'bin').mkdir(exist_ok=True)

for archive in sys.argv[4:]:
    with zipfile.ZipFile(archive) as wheel:
        for item in wheel.infolist():
            if item.is_dir():
                continue
            parts = Path(item.filename).parts
            # Keep the Apache bindings, not unlicensed vendor engine/models.
            if len(parts) > 1 and parts[0] == 'pvporcupine' and parts[1] in ('lib', 'resources'):
                continue
            if not parts or '..' in parts or item.filename.startswith('/'):
                raise ValueError('unsafe wheel path: ' + item.filename)
            if parts[0].endswith('.data'):
                kind = parts[1]
                base = {'purelib': site, 'platlib': site, 'scripts': out / 'bin',
                        'data': out, 'headers': out / 'include'}.get(kind)
                if base is None:
                    raise ValueError('unsupported wheel data: ' + item.filename)
                target = base.joinpath(*parts[2:])
            else:
                target = site.joinpath(*parts)
            data = wheel.read(item)
            if target.exists() and target.read_bytes() != data:
                raise ValueError('wheel path collision: ' + str(target))
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            mode = item.external_attr >> 16
            target.chmod((mode & 0o777) or 0o644)

# Import-time keyword discovery needs this empty directory.  Explicit user
# keyword_paths remain available without any packaged vendor keyword bytes.
(site / 'pvporcupine/resources/keyword_files/linux').mkdir(parents=True, exist_ok=True)

# Wheel console scripts are useful to subprocess-based provider integrations.
# They re-enter the same sealed runtime, never a host Python/pip environment.
for entry_file in site.glob('*.dist-info/entry_points.txt'):
    config = configparser.ConfigParser(interpolation=None)
    config.optionxform = str
    config.read(entry_file)
    if config.has_section('console_scripts'):
        for name, entry in config.items('console_scripts'):
            module, symbol = entry.split(':', 1)
            symbol = symbol.split('[', 1)[0].strip()
            script = out / 'bin' / name
            script.write_text('#!' + python + '\\nimport importlib, sys\\n'
                              + 'target = importlib.import_module(' + repr(module.strip()) + ')\\n'
                              + 'for part in ' + repr(symbol.split('.')) + ': target = getattr(target, part)\\n'
                              + 'sys.exit(target())\\n')
            script.chmod(0o755)

# The native wheels use manylinux paths, while Guix has no global loader or
# /usr/lib.  Preserve vendor $ORIGIN RPATHs and add all bundled library dirs,
# plus explicitly supplied Guix libraries used by ctypes and extensions.
elfs = []
for file in out.rglob('*'):
    if file.is_file():
        with file.open('rb') as stream:
            if stream.read(4) == b'\\x7fELF':
                elfs.append(file)
libdirs = sorted({str(file.parent) for file in elfs})
for file in elfs:
    # Intel's binary grant forbids modifying its statically linked code.  This
    # aggregate already uses vendor $ORIGIN linkage; patch only the MIT Python
    # extension and GPL-with-runtime-exception support library, never this ELF.
    if file.parent.name == 'ctranslate2.libs' and file.name.startswith('libctranslate2-'):
        continue
    file.chmod(file.stat().st_mode | 0o200)
    old = subprocess.check_output(['patchelf', '--print-rpath', str(file)], text=True).strip()
    command = ['patchelf']
    if file.parent.name == 'ctranslate2' and file.name.startswith('_ext.'):
        # Only this MIT extension needs inherited DT_RPATH for the unmodified
        # Intel aggregate.  All other ELFs use independently valid DT_RUNPATH.
        command.append('--force-rpath')
    subprocess.run(command + ['--set-rpath', ':'.join(filter(None, [old] + libdirs + external)), str(file)], check=True)
    result = subprocess.run(['patchelf', '--print-interpreter', str(file)], capture_output=True, text=True)
    if result.returncode == 0:
        subprocess.run(['patchelf', '--set-interpreter', os.environ['HERMES_GLIBC_LOADER'], str(file)], check=True)
"))

;; Recompiles every existing .pyc under the installed site tree as a
;; checked-hash cache, removing timestamps without changing runtime behavior
;; or sources.  Only caches that already exist are touched, so non-Python
;; wheel data is never compiled.
(define %hermes-bytecode-normalizer
  (plain-file
   "normalize-hermes-bytecode.py"
   "from pathlib import Path
import importlib.util
import py_compile
import sys

for cache in sorted(Path(sys.argv[1]).rglob('*.pyc')):
    source = importlib.util.source_from_cache(str(cache))
    if not Path(source).is_file():
        raise FileNotFoundError(source)
    py_compile.compile(str(source), cfile=str(cache), doraise=True,
                       invalidation_mode=py_compile.PycInvalidationMode.CHECKED_HASH)
"))
