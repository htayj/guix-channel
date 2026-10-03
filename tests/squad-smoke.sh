#!/bin/sh
# Real installed CLI, SDK SQLite/WASM persistence, PTY and FFI consumer proof.
# GUIX selects Guix; an optional argument supplies an already-built output.
# SQUAD_EVIDENCE_DIR retains bounded logs and a JSON report in a new subdirectory.
# Runtime requires util-linux unshare with rootless user/network namespaces.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if test "$#" -gt 1; then
    echo "usage: $0 [squad-output]" >&2
    exit 64
fi
unshare_bin=$(command -v unshare) || {
    echo 'Squad smoke requires util-linux unshare for private network isolation; no fallback' >&2
    exit 69
}
case "$unshare_bin" in
    /*) ;;
    *) echo 'Squad smoke requires an absolute executable path for unshare' >&2; exit 69 ;;
esac
env_bin=$(command -v env)
host_net_namespace=$(readlink /proc/self/ns/net)
if test "$#" -eq 1; then
    out=$1
else
    out=$("$guix_bin" build -L "$channel_dir/guix" --no-grafts squad)
fi
# Git is a real dependency of init, not a host executable or a test stub.
git_out=$("$guix_bin" build --no-grafts git-minimal)
case "$out" in
    /gnu/store/*) ;;
    *) echo 'Squad output must be an absolute /gnu/store path' >&2; exit 64 ;;
esac
test -x "$out/bin/squad"
test -x "$out/bin/squad-node"
test -x "$git_out/bin/git"
before=$("$guix_bin" hash -S nar "$out")
scratch=$(mktemp -d "${TMPDIR:-/tmp}/squad-smoke.XXXXXX")
evidence=
cleanup() {
    exit_status=$?
    if test "$exit_status" -ne 0 && test -n "$evidence"; then
        # Retain only this proof's generated repository and preset home data,
        # never the host HOME, credentials, or unrelated temporary files.
        if mkdir -p -- "$evidence/failed-project/home/.squad"; then
            if test -d "$scratch/repo"; then
                cp -R -- "$scratch/repo" "$evidence/failed-project/repo" ||
                    echo 'Could not retain failed Squad repository evidence' >&2
            fi
            if test -d "$scratch/home/.squad/presets"; then
                cp -R -- "$scratch/home/.squad/presets" \
                    "$evidence/failed-project/home/.squad/presets" ||
                    echo 'Could not retain failed Squad preset evidence' >&2
            fi
        else
            echo 'Could not create failed Squad project evidence directory' >&2
        fi
    fi
    rm -rf -- "$scratch"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' HUP TERM
if test -n "${SQUAD_EVIDENCE_DIR:-}"; then
    mkdir -p -- "$SQUAD_EVIDENCE_DIR"
    evidence=$(mktemp -d "$SQUAD_EVIDENCE_DIR/squad-smoke.XXXXXX")
    evidence=$(CDPATH= cd -- "$evidence" && pwd)
    printf '%s\n' "$before" >"$evidence/output-nar-before.txt"
fi
mkdir -p "$scratch/home" "$scratch/config" "$scratch/cache" \
    "$scratch/state" "$scratch/data" "$scratch/tmp" "$scratch/repo" \
    "$scratch/node_modules/@bradygaster"
ln -s "$out/lib/node_modules/@bradygaster/squad-sdk" \
    "$scratch/node_modules/@bradygaster/squad-sdk"
ln -s "$out/lib/node_modules/node-pty" "$scratch/node_modules/node-pty"
ln -s "$out/lib/node_modules/koffi" "$scratch/node_modules/koffi"

cat >"$scratch/consumer.mjs" <<'EOF'
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { FSStorageProvider, SQLiteStorageProvider } from '@bradygaster/squad-sdk';

const [phase, scratch] = process.argv.slice(2);
if (phase === 'filesystem') {
    const storage = new FSStorageProvider(scratch);
    const source = path.join(scratch, 'readonly-template.md');
    const original = '# Local template\n';
    fs.writeFileSync(source, original);
    fs.chmodSync(source, 0o444);
    for (const method of ['copy', 'copySync']) {
        const fresh = path.join(scratch, `${method}-fresh.md`);
        const existing = path.join(scratch, `${method}-existing.md`);
        await storage[method](source, fresh);
        assert.equal(fs.readFileSync(fresh, 'utf8'), original);
        assert.equal(fs.statSync(fresh).mode & 0o200, 0o200,
            `${method} must make a new copied template owner-writable`);
        await storage.append(fresh, 'User-authored local edit.\n');
        assert.equal(fs.readFileSync(fresh, 'utf8'), original + 'User-authored local edit.\n');
        fs.writeFileSync(existing, 'Old local content.\n');
        fs.chmodSync(existing, 0o640);
        await storage[method](source, existing);
        assert.equal(fs.readFileSync(existing, 'utf8'), original);
        assert.equal(fs.statSync(existing).mode & 0o777, 0o640,
            `${method} must preserve an existing destination mode`);
        assert.equal(fs.statSync(source).mode & 0o777, 0o444,
            `${method} must leave the source template read-only`);
    }
    console.log('Installed filesystem provider copies remain editable and preserve existing modes');
} else if (phase === 'native') {
    const { default: koffi } = await import('koffi');
    const libc = koffi.load('libc.so.6');
    assert.equal(libc.func('int getpid()')(), process.pid,
        'native Koffi must invoke the actual libc getpid');
    const { default: pty } = await import('node-pty');
    const marker = 'squad-native-pty-roundtrip';
    await new Promise((resolve, reject) => {
        const terminal = pty.spawn(process.execPath,
            ['-e', `process.stdout.write(${JSON.stringify(marker)} + '\\n')`],
            { name: 'xterm', cols: 80, rows: 24, cwd: scratch, env: process.env });
        let text = '';
        const timer = setTimeout(() => {
            terminal.kill();
            reject(new Error('native PTY child exceeded 10 seconds'));
        }, 10000);
        terminal.onData(data => { text += data; });
        terminal.onExit(({ exitCode, signal }) => {
            clearTimeout(timer);
            try {
                assert.equal(exitCode, 0, `PTY child failed (signal ${signal})`);
                assert.ok(text.replace(/\r\n/g, '\n').split('\n').includes(marker),
                    'native PTY must return the real child output');
                resolve();
            } catch (error) { reject(error); }
        });
    });
    console.log('Native libc FFI and actual PTY child roundtrip passed');
} else {
    // No locateFile override: the installed sql.js must find its official WASM.
    const dbPath = path.join(scratch, 'storage', 'sessions.db');
    const storage = new SQLiteStorageProvider(dbPath);
    await storage.init();
    const sessionPath = '.squad/sessions/2026-10-03T00-00-00-000Z_smoke.json';
    const auditPath = '.squad/sessions/smoke.audit.jsonl';
    const keepPath = '.squad/decisions.md';
    // Local user-authored records, not a fabricated model/provider response.
    const initial = {
        id: 'smoke', createdAt: '2026-10-03T00:00:00.000Z',
        lastActiveAt: '2026-10-03T00:00:00.000Z',
        messages: [{ role: 'user', content: 'Record a local decision.' }]
    };
    const updated = {
        ...initial, lastActiveAt: '2026-10-03T00:01:00.000Z',
        messages: [...initial.messages,
            { role: 'user', content: 'Local decision: retain durable audit records.' }]
    };
    if (phase === 'write') {
        await storage.write(sessionPath, JSON.stringify(initial));
        await storage.write(keepPath, '# Decisions\nRetain this unrelated record.\n');
        await storage.append(auditPath, JSON.stringify({ event: 'created', id: 'smoke' }) + '\n');
        assert.deepEqual(JSON.parse(await storage.read(sessionPath)), initial);
        assert.equal(fs.readFileSync(dbPath).subarray(0, 16).toString(), 'SQLite format 3\0');
    } else if (phase === 'update') {
        // This process has loaded the database written by the previous process.
        assert.deepEqual(JSON.parse(await storage.read(sessionPath)), initial);
        await storage.write(sessionPath, JSON.stringify(updated));
        await storage.append(sessionPath, '\n');
        await storage.append(auditPath, JSON.stringify({ event: 'updated', id: 'smoke' }) + '\n');
    } else if (phase === 'read') {
        assert.deepEqual(JSON.parse(await storage.read(sessionPath)), updated);
        assert.equal((await storage.read(sessionPath)).endsWith('\n'), true);
        assert.deepEqual((await storage.read(auditPath)).trim().split('\n').map(JSON.parse),
            [{ event: 'created', id: 'smoke' }, { event: 'updated', id: 'smoke' }]);
        assert.deepEqual((await storage.list('.squad/sessions')).sort(),
            [path.basename(sessionPath), path.basename(auditPath)].sort());
    } else if (phase === 'delete') {
        assert.deepEqual(JSON.parse(await storage.read(sessionPath)), updated);
        await storage.delete(sessionPath);
    } else if (phase === 'absent') {
        assert.equal(await storage.read(sessionPath), undefined);
        assert.equal(await storage.exists(sessionPath), false);
        assert.deepEqual(await storage.list('.squad/sessions'), [path.basename(auditPath)]);
        assert.equal(await storage.read(keepPath), '# Decisions\nRetain this unrelated record.\n');
        assert.deepEqual((await storage.read(auditPath)).trim().split('\n').map(JSON.parse),
            [{ event: 'created', id: 'smoke' }, { event: 'updated', id: 'smoke' }]);
    } else {
        throw new Error(`Unknown storage phase: ${phase}`);
    }
    console.log(`Installed SDK SQLite/WASM ${phase} passed`);
}
EOF

cat >"$scratch/proof.mjs" <<'EOF'
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';

const [out, scratch, git, evidence, hostNetNamespace] = process.argv.slice(2);
const netNamespace = fs.readlinkSync('/proc/self/ns/net');
assert.notEqual(netNamespace, hostNetNamespace,
    'Squad runtime requires a private network namespace; no fallback is permitted');
const networkIsolation = { enabled: true, host: hostNetNamespace, runtime: netNamespace };
if (evidence) fs.writeFileSync(path.join(evidence, 'network-isolation.json'),
    JSON.stringify(networkIsolation, null, 2) + '\n');
console.log('Private network isolation enabled (rootless user + network namespaces)');
const repo = path.join(scratch, 'repo');
const deadline = Date.now() + 180000;
const steps = [];
function run(label, command, args, cwd = repo) {
    // Non-TTY, closed stdin, hard child deadline, bounded captured output.
    const remaining = deadline - Date.now();
    assert.ok(remaining > 0, 'Squad proof exceeded its total runtime limit');
    const result = spawnSync(command, args, {
        cwd, env: process.env, input: '', encoding: 'utf8',
        timeout: Math.min(30000, remaining), killSignal: 'SIGKILL', maxBuffer: 1024 * 1024
    });
    const log = `${result.stdout || ''}${result.stderr || ''}`;
    if (evidence) fs.writeFileSync(path.join(evidence, `${label}.log`), log);
    process.stdout.write(log);
    assert.ifError(result.error);
    assert.equal(result.signal, null, `${label} killed by ${result.signal}`);
    assert.equal(result.status, 0, `${label} exited with ${result.status}`);
    // CLI error output is a failure even when upstream incorrectly exits zero.
    // Keep legitimate warnings and informational stderr in the retained log.
    if (command === path.join(out, 'bin/squad')) {
        assert.doesNotMatch(log, /\u274c/u, `${label} emitted a CLI error`);
    }
    steps.push(label);
}
function read(relative) { return fs.readFileSync(path.join(repo, relative), 'utf8'); }
const agents = ['lead', 'reviewer', 'devrel', 'security', 'docs'];
const workflows = ['squad-heartbeat.yml', 'squad-issue-assign.yml',
    'squad-triage.yml', 'sync-squad-labels.yml'];
run('git-init', git, ['-c', 'init.defaultBranch=main', 'init']);
run('init-first', path.join(out, 'bin/squad'), ['init', '--preset', 'default']);
assert.equal(fs.statSync(path.join(repo, '.git')).isDirectory(), true);
const team = read('.squad/team.md');
for (const name of agents) {
    assert.match(team, new RegExp(`^\\| ${name} \\|`, 'im'));
    assert.match(read(`.squad/agents/${name}/charter.md`), /^# /m);
    assert.match(fs.readFileSync(path.join(process.env.HOME,
        '.squad/presets/default/agents', name, 'charter.md'), 'utf8'), /^# /m);
}
const routing = read('.squad/routing.md');
const routingSection = routing.split(/^## Work Type → Agent\s*$/m)[1];
assert.notEqual(routingSection, undefined, 'Preset routing must expose work-type assignments');
const routingRows = routingSection.split(/^## /m)[0].split('\n')
    .filter(line => line.startsWith('|')).map(line => line.split('|').slice(1, -1).map(cell => cell.trim()));
for (const name of agents) {
    const member = team.split('\n').filter(line => line.startsWith('|'))
        .map(line => line.split('|').slice(1, -1).map(cell => cell.trim()))
        .find(cells => cells[0].toLowerCase() === name);
    assert.ok(routingRows.some(cells => cells[0] === member[1] && cells[1].toLowerCase() === name),
        `Preset must route ${member[1]} work to ${name}`);
}
function castingState() {
    const registry = JSON.parse(read('.squad/casting/registry.json'));
    const history = JSON.parse(read('.squad/casting/history.json'));
    for (const name of agents) {
        const entry = registry.agents[name];
        assert.equal(entry.persistent_name.toLowerCase(), name);
        assert.equal(entry.status, 'active');
        assert.equal(entry.universe, 'preset:default');
    }
    assert.ok(Object.values(history.assignment_cast_snapshots).some(snapshot =>
        snapshot.universe === 'preset:default' &&
        JSON.stringify([...snapshot.agents].sort()) === JSON.stringify([...agents].sort())),
        'Casting history must record the complete default preset team');
    assert.ok(history.universe_usage_history.some(entry => entry.universe === 'preset:default'),
        'Casting usage must record the applied preset');
    return { registry, history };
}
const firstCasting = castingState();
for (const name of workflows) {
    const workflow = read(`.github/workflows/${name}`);
    assert.match(workflow, /^on:/m);
    assert.match(workflow, /^jobs:/m);
}
assert.match(read('.github/agents/squad.agent.md'), /Squad/i);
const mcp = JSON.parse(read('.mcp.json'));
assert.equal(mcp.mcpServers.squad_state.command, path.join(out, 'bin/squad'));
assert.deepEqual(mcp.mcpServers.squad_state.args, ['state-mcp']);
// User edits must survive merge-only init; casting history intentionally grows.
const teamEdit = team + '\n## Local policy\nKeep the smoke repository offline.\n';
fs.writeFileSync(path.join(repo, '.squad/team.md'), teamEdit);
const charterPath = '.squad/agents/lead/charter.md';
const charterEdit = read(charterPath) + '\nLocal lead responsibility: retain user decisions.\n';
fs.writeFileSync(path.join(repo, charterPath), charterEdit);
const routingPath = '.squad/routing.md';
assert.equal(fs.statSync(path.join(repo, routingPath)).mode & 0o200, 0o200,
    'Installed routing template must be owner-writable');
const routingEdit = read(routingPath) + '\n<!-- Local routing policy: preserve user decisions. -->\n';
fs.writeFileSync(path.join(repo, routingPath), routingEdit);
const stablePaths = [charterPath, routingPath, '.squad/config.json',
    '.github/agents/squad.agent.md', '.mcp.json',
    ...workflows.map(name => `.github/workflows/${name}`)];
const stable = new Map(stablePaths.map(name => [name, read(name)]));
run('init-repeat', path.join(out, 'bin/squad'), ['init', '--preset', 'default']);
assert.equal(read('.squad/team.md'), teamEdit);
assert.equal(read(routingPath), routingEdit);
for (const [name, content] of stable) assert.equal(read(name), content, `${name} was overwritten`);
for (const name of agents) {
    assert.equal((read('.squad/team.md').match(new RegExp(`^\\| ${name} \\|`, 'gim')) || []).length,
        1, `${name} was duplicated by init`);
}
const repeatedCasting = castingState();
assert.deepEqual(repeatedCasting.registry, firstCasting.registry,
    'Repeat init must retain established casting identities');
for (const [key, snapshot] of Object.entries(firstCasting.history.assignment_cast_snapshots)) {
    assert.deepEqual(repeatedCasting.history.assignment_cast_snapshots[key], snapshot,
        'Repeat init must retain existing assignment history');
}
assert.deepEqual(repeatedCasting.history.universe_usage_history.slice(0,
    firstCasting.history.universe_usage_history.length), firstCasting.history.universe_usage_history,
    'Repeat init must retain existing preset usage history');
for (const phase of ['filesystem', 'write', 'update', 'read', 'delete', 'absent', 'native']) {
    run(`consumer-${phase}`, process.execPath,
        [path.join(scratch, 'consumer.mjs'), phase, scratch], scratch);
}
assert.ok(Date.now() <= deadline, 'Squad proof exceeded its total runtime limit');
const report = {
    output: out, steps, cli: 'preset/default scaffold and retained edits',
    filesystem: 'read-only template copy/copySync to editable new files; existing modes retained',
    storage: 'SQLite/WASM write/update/append/reopen/delete/reopen',
    native: 'node-pty child and Koffi libc getpid',
    isolation: 'private network isolation enabled; empty environment and temporary HOME/XDG/repository',
    networkIsolation
};
if (evidence) fs.writeFileSync(path.join(evidence, 'report.json'), JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify(report, null, 2));
EOF

# Do not pass host credentials, git configuration, Node hooks or provider settings.
# All runtime children inherit a private network namespace, with no external
# interfaces. Failure to create rootless namespaces is fatal, never a fallback.
status=0
"$unshare_bin" --user --map-root-user --net -- "$env_bin" -i \
    HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" \
    XDG_CACHE_HOME="$scratch/cache" XDG_STATE_HOME="$scratch/state" \
    XDG_DATA_HOME="$scratch/data" TMPDIR="$scratch/tmp" \
    PATH="$git_out/bin" LC_ALL=C TERM=dumb NO_COLOR=1 \
    GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null \
    GIT_TERMINAL_PROMPT=0 \
    "$out/bin/squad-node" "$scratch/proof.mjs" "$out" "$scratch" \
    "$git_out/bin/git" "$evidence" "$host_net_namespace" || status=$?
after=$("$guix_bin" hash -S nar "$out")
if test -n "$evidence"; then
    printf '%s\n' "$after" >"$evidence/output-nar-after.txt"
    printf '%s\n' "Squad smoke evidence: $evidence"
fi
test "$before" = "$after" || { echo 'Squad output NAR changed' >&2; exit 1; }
if test "$status" -ne 0; then
    echo 'Squad smoke failed; private rootless network isolation is required (no fallback)' >&2
    exit "$status"
fi
printf '%s\n' 'Squad installed CLI, durable SQLite/WASM and native consumer smoke passed; store unchanged'
