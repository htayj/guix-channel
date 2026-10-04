#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Exercise the installed upstream compiler/CLI in offline namespaces."""

import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


output = Path(sys.argv[1])
evidence = Path(sys.argv[2])
node = Path(sys.argv[3]) / "bin/node"
for namespace in ("user", "net", "mnt", "pid"):
    require(os.readlink(f"/proc/self/ns/{namespace}") !=
            os.environ[f"WENYAN_HOST_{namespace.upper()}"],
            f"{namespace} namespace was inherited")
require(os.getuid() == int(os.environ["WENYAN_HOST_UID"]), "consumer UID changed")
require([name for _, name in socket.if_nameindex()] == ["lo"],
        "host network interface exposed")
mount = shutil.which("mount")
require(mount, "missing realized mount tool")
subprocess.run([mount, "--bind", "/gnu/store", "/gnu/store"], check=True)
subprocess.run([mount, "-o", "remount,bind,ro", "/gnu/store"], check=True)
mounts = [line.split() for line in Path("/proc/self/mountinfo").read_text().splitlines()]
require(any(row[4] == "/gnu/store" and "ro" in row[5].split(",") for row in mounts),
        "store is not read-only")
root = evidence / "consumer"
root.mkdir()
environment = {"PATH": "", "LC_ALL": "C.UTF-8", "LANG": "C.UTF-8"}
for variable, directory in {
    "HOME": "home", "XDG_CONFIG_HOME": "config", "XDG_DATA_HOME": "data",
    "XDG_CACHE_HOME": "cache", "XDG_STATE_HOME": "state",
    "XDG_RUNTIME_DIR": "runtime", "TMPDIR": "tmp"
}.items():
    path = root / directory
    path.mkdir(mode=0o700)
    environment[variable] = str(path)

runs = []


def run(label, command):
    result = subprocess.run([str(part) for part in command], cwd=root,
                            env=environment, text=True, capture_output=True,
                            timeout=45)
    (evidence / f"{label}.stdout").write_text(result.stdout)
    (evidence / f"{label}.stderr").write_text(result.stderr)
    # Upstream CLI sometimes prints an error and exits zero.  Neither success
    # status alone nor a nonempty generated file is sufficient evidence.
    require(result.returncode == 0, f"{label} failed: {result.stderr}")
    require(not result.stderr.strip(), f"{label} emitted native errors: {result.stderr}")
    runs.append({"label": label, "returncode": result.returncode,
                 "stdout": result.stdout})
    return result.stdout


cli = output / "bin/wenyan"
examples = output / "share/wenyan/examples"
hello = run("bundled-hello", [cli, "--no-outputHanzi", examples / "helloworld.wy"])
require(hello == "問天地好在。\n", "bundled hello output differs")
# An external file exercises recursion twice and an embedded standard-library
# import.  Its code is real Wenyan input, never an installed test hook.
source = (examples / "factorial.wy").read_text()
source += '\n施「階乘」於八。書之。\n'
source += '吾嘗觀「「算經」」之書。方悟「絕對」之義。\n施「絕對」於負七。書之。\n'
(root / "consumer.wy").write_text(source)
expected = "120\n40320\n7\n"
compiled = run("compile", [cli, "--compile", "--lang", "js", "--output",
                           "consumer.js", "consumer.wy"])
require(compiled == "", "compile unexpectedly wrote to stdout")
require(run("compiled-run", [node, "consumer.js"]) == expected,
        "separate Node execution produced wrong factorial/import results")
require(run("direct-run", [cli, "--no-outputHanzi", "consumer.wy"]) == expected,
        "direct native CLI execution differs from compiled program")
# Normal installed library import, with no source checkout or NODE_PATH.
(root / "node_modules").mkdir()
(root / "node_modules/wenyanlang").symlink_to(output / "lib/node_modules/wenyanlang")
(root / "consumer-api.js").write_text('''const assert = require('assert');
const fs = require('fs');
const wenyan = require('wenyanlang');
const diagnostics = [];
const code = wenyan.compile(fs.readFileSync('consumer.wy', 'utf8'), {
  logCallback: (...entry) => diagnostics.push(entry),
  errorCallback: message => { throw new Error(message); }
});
fs.writeFileSync('compiler-diagnostics.json', JSON.stringify(diagnostics, null, 2));
const values = [];
wenyan.evalCompiled(code, {outputHanzi:false, output:(...xs)=>values.push(xs)});
assert.deepStrictEqual(values, [[120],[40320],[7]]);
console.log(JSON.stringify(values));
''')
require(run("library-run", [node, "consumer-api.js"]) == "[[120],[40320],[7]]\n",
        "installed compiler API output differs")
for variable in ("HOME", "XDG_CONFIG_HOME", "XDG_DATA_HOME", "XDG_CACHE_HOME",
                 "XDG_STATE_HOME", "XDG_RUNTIME_DIR"):
    require(not list(Path(environment[variable]).iterdir()),
            f"compiler unexpectedly wrote persistent state: {variable}")
(evidence / "proof.json").write_text(json.dumps({
    "schema": "wenyan-native-consumer-v1", "store_readonly": True,
    "uid": os.getuid(), "namespaces": {ns: os.readlink(f"/proc/self/ns/{ns}")
        for ns in ("user", "net", "mnt", "pid")}, "interfaces": ["lo"],
    "runs": runs, "expected": {"factorial_5": 120, "factorial_8": 40320,
                               "stdlib_absolute_minus_7": 7}
}, ensure_ascii=False, indent=2) + "\n")
print("native Wenyan CLI/library compiled recursive factorial and standard-library import")
