#!/usr/bin/env python3
"""External consumer of official Boohu 0.14.1's unmodified tcell binary.

Controls and save fields come from commit 686c990bf30e8f8e57d8ef561641079d3a75b6a5
(main.go, ui.go, player.go, encoding.go, draw.go). A real PTY is mirrored into
xterm on private Xvfb. PNGs are X-server captures, never transcript renderings.
The embedded stdlib-only Go mirror reads zlib/gob; it cannot generate game state.
"""
import codecs
import errno
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import select
import struct
import subprocess
import sys
import termios
import time
import traceback
import tty

import pyte

ROWS, COLS = 26, 100
COMMIT = '686c990bf30e8f8e57d8ef561641079d3a75b6a5'

# Struct field names/types mirror the pinned upstream exported gob state. Gob
# ignores unexported game/UI/RNG fields. gruid's GobEncoder cache payloads are
# retained verbatim, rather than falsely claiming to reconstruct their internals.
READER = r'''package main
import (
 "compress/zlib"
 "encoding/gob"
 "encoding/json"
 "fmt"
 "io"
 "os"
 "reflect"
 "sort"
 "time"
)
type point struct { X, Y int }
type blob []byte
func (b *blob) GobDecode(data []byte) error { *b = append((*b)[:0], data...); return nil }
type potion int
type projectile int
type armour int
type weapon int
type shield int
type simpleEvent struct { ERank, EAction int }
type monsterEvent struct { ERank, NMons, EAction int }
type cloudEvent struct { ERank int; P point; EAction int }
type iEvent struct { Event interface{}; Index int }
type cell struct { T int; Explored bool }
type dungeon struct { Gen int; Cells []cell; PR *blob }
type rodProps struct { Charge int }
type player struct {
 HP, MP, Simellas int; Armour armour; Weapon weapon; Shield shield
 Consumables map[interface{}]int; Rods map[int]rodProps
 Aptitudes map[int]bool; Statuses, Expire map[int]int; P, Target point
 LOS map[point]bool; FOV *blob; Bored, AccScore int; Blocked bool
}
type monster struct {
 Kind, Band, Index, Attack, Accuracy, Armor, Evasion, HPmax, HP, State int
 Statuses [4]int; P, Target point; Path []point; Obstructing, FireReady, Seen bool
}
type monsInterval struct { Min, Max int }
type monsterBandData struct {
 Distribution map[int]monsInterval; Rarity, MinDepth, MaxDepth int
 Band bool; Monster int; Unique bool
}
type collectable struct { Consumable interface{}; Quantity int }
type UICell struct { Fg, Bg int; R rune; InMap bool }
type cellDraw struct { Cell UICell; X, Y int }
type drawFrame struct { Draws []cellDraw; Time time.Time }
type logEntry struct { Text string; Index int; Tick bool; Style, Dups int }
type stats struct {
 Story []string; Killed int; KilledMons map[int]int
 Moves, Hits, Misses, ReceivedHits, Dodges, Blocks, Drinks, Evocations, UsedStones, Throws, TimesLucky, Damage int
 DExplPerc, DSleepingPerc, DKilledPerc [12]int; DLayout [12]string
 Burns, Digs, Rest, RestInterrupt, Turns, TWounded, TMWounded, TMonsLOS int; UsedRod [13]int
}
type startOpts struct { Alternate, StoneLevel int; SpecialBands map[int][]monsterBandData; UnstableLevel int }
type game struct {
 Dungeon *dungeon; Player *player; Monsters []*monster; MonstersPosCache []int
 Bands []int; BandData []monsterBandData; Events *[]iEvent; Ev interface{}
 EventIndex, Depth, ExploredLevels, DepthPlayerTurn, Turn int
 Highlight map[point]bool; Collectables map[point]collectable; CollectableScore int
 LastConsumables []interface{}; Equipables map[point]interface{}; Rods, Stairs, Clouds, Fungus map[point]int
 Doors, TemporalWalls map[point]bool; MagicalStones map[point]int
 GeneratedUniques map[int]int; GeneratedEquipables map[interface{}]bool; GeneratedRods map[int]bool
 GenPlan [12]int; FoundEquipables map[interface{}]bool; Simellas map[point]int
 WrongWall, WrongFoliage, WrongDoor, ExclusionsMap, Noise, DreamingMonster map[point]bool
 Resting bool; RestingTurns int; Autoexploring, DijkstraMapRebuild bool; Targeting point
 PR, PRauto *blob; AutoTarget point; AutoDir int; AutoHalt, AutoNext bool
 DrawBuffer []UICell; DrawLog []drawFrame; Log []logEntry; LogIndex, LogNextTick int
 InfoEntry string; Stats stats; Boredom int; Quit, Wizard, WizardMap bool; Version string; Opts startOpts
}
// JSON cannot represent Point/interface map keys: retain sorted typed key/value
// pairs, including interface concrete type identity. Do not drop map entries.
func normalize(v reflect.Value) interface{} {
 if !v.IsValid() { return nil }
 if v.Kind() == reflect.Interface {
  if v.IsNil() { return nil }
  return map[string]interface{}{"Type": v.Elem().Type().String(), "Value": normalize(v.Elem())}
 }
 if v.Kind() == reflect.Pointer {
  if v.IsNil() { return nil }; return normalize(v.Elem())
 }
 switch v.Kind() {
 case reflect.Struct:
  if v.Type() == reflect.TypeOf(time.Time{}) { return v.Interface() }
  m := map[string]interface{}{}
  for i:=0; i<v.NumField(); i++ { if v.Type().Field(i).IsExported() { m[v.Type().Field(i).Name] = normalize(v.Field(i)) } }
  return m
 case reflect.Map:
  pairs := make([]interface{},0,v.Len())
  for _, k := range v.MapKeys() { pairs = append(pairs, []interface{}{normalize(k), normalize(v.MapIndex(k))}) }
  sort.Slice(pairs,func(i,j int) bool { a,_:=json.Marshal(pairs[i]); b,_:=json.Marshal(pairs[j]); return string(a)<string(b) })
  return pairs
 case reflect.Array, reflect.Slice:
  if v.Type() == reflect.TypeOf(blob{}) { return []byte(v.Interface().(blob)) }
  a := make([]interface{},v.Len()); for i:=range a { a[i]=normalize(v.Index(i)) }; return a
 default: return v.Interface()
 }
}
func run() error {
 if len(os.Args)!=2 { return fmt.Errorf("usage: boohu-save-reader SAVE") }
 for _, v := range []interface{}{potion(0), projectile(0), &simpleEvent{}, &monsterEvent{}, &cloudEvent{}, armour(0), weapon(0), shield(0)} { gob.Register(v) }
 f,e:=os.Open(os.Args[1]); if e!=nil{return e}; defer f.Close()
 z,e:=zlib.NewReader(f); if e!=nil{return e}; defer z.Close()
 d:=gob.NewDecoder(z); var g game; if e=d.Decode(&g); e!=nil{return e}
 var extra interface{}; if e=d.Decode(&extra); e!=io.EOF{return fmt.Errorf("trailing gob value: %v",e)}
 if g.Version!="v0.14" || g.Dungeon==nil || len(g.Dungeon.Cells)!=79*21 || g.Player==nil { return fmt.Errorf("wrong native game version/shape") }
 return json.NewEncoder(os.Stdout).Encode(normalize(reflect.ValueOf(g)))
}
func main(){if e:=run(); e!=nil {fmt.Fprintln(os.Stderr,e);os.Exit(1)}}
'''


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def record(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def terminal_color(index):
    # pyte represents ANSI 0-15 by names and indexed 16-255 by RGB hex.
    basic = ('black', 'red', 'green', 'brown', 'blue', 'magenta', 'cyan', 'white',
             'brightblack', 'brightred', 'brightgreen', 'brightbrown', 'brightblue',
             'brightmagenta', 'brightcyan', 'brightwhite')
    require(0 <= index < 256, 'native color outside xterm palette')
    if index < 16:
        return basic[index]
    if index >= 232:
        value = 8 + 10 * (index - 232)
        return '%02x%02x%02x' % (value, value, value)
    number = index - 16
    levels = (0, 95, 135, 175, 215, 255)
    return '%02x%02x%02x' % (levels[number // 36], levels[(number // 6) % 6], levels[number % 6])


def namespace_proof(proc):
    namespaces = {n: os.readlink(proc / 'ns' / n) for n in ('user', 'mnt', 'pid', 'net')}
    for name, host in (('user', 'HOST_USER_NS'), ('mnt', 'HOST_MOUNT_NS'),
                       ('pid', 'HOST_PID_NS'), ('net', 'HOST_NET_NS')):
        require(namespaces[name] != os.environ[host], 'not in private ' + name + ' namespace')
        require(namespaces[name] == os.readlink(Path('/proc/self/ns') / name),
                'native process escaped ' + name + ' namespace')
    identity = {}
    for line in (proc / 'status').read_text().splitlines():
        key, _, value = line.partition(':')
        if key in ('Uid', 'Gid', 'Groups'):
            identity[key] = [int(x) for x in value.split()]
    require(identity['Uid'] == [int(os.environ['HOST_UID'])] * 4, 'caller UID changed')
    require(identity['Gid'] == [int(os.environ['HOST_GID'])] * 4, 'caller GID changed')
    maps = {name: (proc / (name + '_map')).read_text() for name in ('uid', 'gid')}
    for name, variable in (('uid', 'HOST_UID'), ('gid', 'HOST_GID')):
        value = int(os.environ[variable])
        require([int(x) for x in maps[name].split()] == [value, value, 1], 'wrong ' + name + ' mapping')
    devices = sorted(line.split(':')[0].strip() for line in
                     (proc / 'net/dev').read_text().splitlines()[2:] if ':' in line)
    require(devices == ['lo'], 'offline network namespace has non-loopback interfaces')
    return dict(namespaces=namespaces, identity=identity, maps=maps, interfaces=devices,
                executable=os.readlink(proc / 'exe'))


def readonly_store(root):
    commands = []

    def mount(*args):
        result = subprocess.run([os.environ['MOUNT'], *args], capture_output=True, text=True, timeout=15)
        commands.append(dict(args=args, status=result.returncode, stdout=result.stdout, stderr=result.stderr))
        record(root / 'mount-commands.json', commands)
        require(result.returncode == 0, 'read-only store mount failed: ' + result.stderr)

    def entries():
        text = Path('/proc/self/mountinfo').read_text()
        found = []
        for line in text.splitlines():
            fields = line.split()
            target = fields[4]
            for escaped, literal in (('\\040', ' '), ('\\011', '\t'), ('\\012', '\n'), ('\\134', '\\')):
                target = target.replace(escaped, literal)
            if target == '/gnu/store' or target.startswith('/gnu/store/'):
                found.append((target, fields[5].split(','), fields[6:fields.index('-')]))
        return text, found

    (root / 'mountinfo-before.txt').write_text(entries()[0])
    mount('--rbind', '/gnu/store', '/gnu/store')
    mount('--make-rprivate', '/gnu/store')
    targets = sorted({x[0] for x in entries()[1]}, key=len, reverse=True)
    require('/gnu/store' in targets, 'recursive store bind missing')
    for target in targets:
        mount('-o', 'remount,bind,ro', target)
    text, found = entries()
    (root / 'mountinfo-after.txt').write_text(text)
    require(found and all('ro' in opts and 'rw' not in opts and not
                         any(x.startswith(('shared:', 'master:')) for x in optional)
                         for _, opts, optional in found), 'store not recursively private/read-only')
    return found


def environment(root):
    env = os.environ.copy()
    for var, name in (('HOME', 'home'), ('TMPDIR', 'tmp'), ('XDG_CONFIG_HOME', 'config'),
                      ('XDG_DATA_HOME', 'data'), ('XDG_CACHE_HOME', 'cache'),
                      ('XDG_STATE_HOME', 'state'), ('XDG_RUNTIME_DIR', 'runtime')):
        (root / name).mkdir(mode=0o700)
        env[var] = str(root / name)
    (root / 'work').mkdir()
    env.update(LC_ALL='C.UTF-8', PATH='', TERM='xterm-256color')
    return env


class Session:
    def __init__(self, output, root, number):
        self.root, self.number = root, number
        self.raw = bytearray()
        self.screen = pyte.Screen(COLS, ROWS)
        self.stream = pyte.Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('strict')
        self.alive = True
        self.inputs = []
        env = {'HOME': str(root / 'home'), 'TMPDIR': str(root / 'tmp'),
               'TERM': 'xterm-256color', 'LC_ALL': 'C.UTF-8', 'PATH': ''}
        for var, name in (('XDG_CONFIG_HOME', 'config'), ('XDG_DATA_HOME', 'data'),
                          ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                          ('XDG_RUNTIME_DIR', 'runtime')):
            env[var] = str(root / name)
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(root / 'work')
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
                # First run disables animations through a documented option;
                # ALL restore launches have no arguments, using the default load.
                executable = str(output / 'bin/boohu')
                os.execve(executable, [executable] + (['-n'] if number == 1 else []), env)
            except BaseException:
                os._exit(127)
        os.write(1, b'\x1b[2J\x1b[H')

    def text(self):
        return '\n'.join(self.screen.display) + '\n'

    def exited(self):
        if not self.alive:
            return True
        pid, status = os.waitpid(self.pid, os.WNOHANG)
        if pid:
            self.alive = False
            self.status = os.waitstatus_to_exitcode(status)
            return True
        return False

    def read(self, timeout=0.1):
        ready = select.select([self.fd, 0], [], [], timeout)[0]
        if 0 in ready:
            reply = os.read(0, 4096)
            if reply and self.alive:
                os.write(self.fd, reply)  # Only real xterm terminal-query replies.
        if self.fd not in ready:
            return bool(ready)
        try:
            data = os.read(self.fd, 65536)
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            data = b''
        if not data:
            return False
        self.raw.extend(data)
        require(len(self.raw) < 4000000, 'unbounded native terminal output')
        self.stream.feed(self.decoder.decode(data))
        os.write(1, data)
        return True

    def wait(self, predicate, label, timeout=20):
        deadline = time.monotonic() + timeout
        while not predicate():
            self.read()
            require(not self.exited(), label + ': game exited\n' + self.text())
            require(time.monotonic() < deadline, label + ': timed out\n' + self.text())

    def settle(self):
        deadline = time.monotonic() + 5
        while self.read(.2):
            require(time.monotonic() < deadline, 'terminal failed to become idle')

    def send(self, key):
        require(not self.exited(), 'game exited before ordinary key input')
        self.inputs.append(key.decode('ascii'))
        os.write(self.fd, key)
        self.read(.2)
        self.settle()

    def turns(self):
        match = re.search(r'^Turns: (\d+)\.(\d)$', self.screen.display[9][81:].strip())
        require(match is not None, 'missing native large-layout turn HUD')
        return int(match[1]) * 10 + int(match[2])

    def live(self):
        return (self.screen.display[4][81:].startswith('HP: ') and
                self.screen.display[8][81:].startswith('Depth: 1') and
                self.screen.display[9][81:].startswith('Turns: '))

    def start(self):
        title = '       Boohu v0.14'
        self.wait(lambda: self.screen.display[3][10:10 + len(title)] == title, 'native welcome')
        self.send(b' ')
        self.wait(self.live, 'playable native map and HUD')
        self.settle()
        proof = namespace_proof(Path('/proc') / str(self.pid))
        require(proof['executable'] == str(self.output_binary), 'not executing supplied normal output')
        record(self.root / ('session-%d.process.json' % self.number), proof)

    @property
    def output_binary(self):
        return Path(os.environ['BOOHU_OUTPUT']) / 'bin/boohu'

    def cells(self):
        return [[tuple(self.screen.buffer[y][x]) for x in range(COLS)] for y in range(ROWS)]

    def snapshot(self):
        cells = self.cells()
        record(self.root / ('screen-%d.cells.json' % self.number), cells)
        (self.root / ('screen-%d.txt' % self.number)).write_text(self.text())
        subprocess.run([os.environ['IMPORT'], '-display', os.environ['DISPLAY'], '-window', 'root',
                        str(self.root / ('screen-%d.png' % self.number))], check=True, timeout=20)
        require((self.root / ('screen-%d.png' % self.number)).read_bytes().startswith(b'\x89PNG\r\n\x1a\n'),
                'X screenshot is not PNG')
        return cells

    def finish(self):
        deadline = time.monotonic() + 15
        while not self.exited():
            self.read()
            require(time.monotonic() < deadline, 'save and quit did not exit')
        self.settle()
        require(self.status == 0, 'native exit status: ' + str(self.status))
        (self.root / ('session-%d.raw' % self.number)).write_bytes(self.raw)
        record(self.root / ('session-%d.inputs.json' % self.number), self.inputs)
        os.close(self.fd)

    def save(self, cells):
        turn = self.turns()
        self.send(b'S')
        self.finish()
        data = (self.root / 'data/boohu/save').read_bytes()
        copy = self.root / ('save-%d.native' % self.number)
        copy.write_bytes(data)
        decoded = subprocess.run([str(self.root / 'boohu-save-reader'), str(copy)],
                                 check=True, capture_output=True, timeout=15)
        (self.root / ('save-%d.json' % self.number)).write_bytes(decoded.stdout)
        state = json.loads(decoded.stdout)
        require(state['Turn'] == turn, 'decoded turn differs from real native HUD')
        require(state['Version'] == 'v0.14' and state['Depth'] == 1 and
                not state['Wizard'] and not state['WizardMap'], 'wrong native game/version/mode')
        player = state['Player']
        x, y = player['P']['X'], player['P']['Y']
        require(cells[y][x][0] == '@', 'decoded player position differs from terminal glyph')
        # Source ColorFgPlayer=33/ColorBgLOS=235 in the default dark palette.
        require(cells[y][x][1:3] == ('0087ff', '262626'), 'player rendition differs from native palette')
        require(self.screen is not None and len(state['DrawBuffer']) == COLS * ROWS, 'wrong save UI geometry')
        require('HP: %d' % player['HP'] == ''.join(c[0] for c in cells[4][81:]).strip(), 'saved HP differs from HUD')
        require('MP: %d' % player['MP'] == ''.join(c[0] for c in cells[5][81:]).strip(), 'saved MP differs from HUD')
        # Every displayed cell must match the game's own native DrawBuffer,
        # including colors. The player's cell is additionally source-derived.
        for index, native in enumerate(state['DrawBuffer']):
            actual = cells[index // COLS][index % COLS]
            require(actual[0] == chr(native['R']), 'native DrawBuffer glyph mismatch at %d' % index)
            require(actual[1:3] == (terminal_color(native['Fg']), terminal_color(native['Bg'])),
                    'native DrawBuffer color mismatch at %d' % index)
        return state


# Restore executes simpleEvent.PlayerTurn at the SAME rank. That explicitly
# recomputes Noise (random footsteps), LogNextTick, AutoNext and draw frames.
# Compare authoritative world/player/events/Stats, not those derived UI/runtime
# caches. Preserve complete decoded saves and every cell regardless of scope.
RESTORE_FIELDS = (
    'Player', 'Monsters', 'MonstersPosCache', 'Bands', 'BandData', 'EventIndex',
    'Depth', 'ExploredLevels', 'DepthPlayerTurn', 'Turn', 'Collectables', 'CollectableScore',
    'LastConsumables', 'Equipables', 'Rods', 'Stairs', 'Clouds', 'Fungus', 'Doors',
    'TemporalWalls', 'MagicalStones', 'GeneratedUniques', 'GeneratedEquipables',
    'GeneratedRods', 'GenPlan', 'FoundEquipables', 'Simellas', 'WrongWall',
    'WrongFoliage', 'WrongDoor', 'ExclusionsMap', 'DreamingMonster', 'Stats', 'Boredom',
    'Version', 'Opts', 'Wizard', 'WizardMap')


def stable_state(state):
    result = {key: state[key] for key in RESTORE_FIELDS}
    result['Dungeon'] = {key: state['Dungeon'][key] for key in ('Gen', 'Cells')}
    result['Events'] = sorted(state['Events'], key=lambda event: json.dumps(event, sort_keys=True))
    result['Ev'] = state['Ev']
    return result


def restore_cells(cells, state):
    # Noise is rendered only outside LOS; mask ONLY the native positions in
    # the saved Noise map. All other map/HUD cell attributes compare exactly.
    result = [row[:] for row in cells[:22]]
    for point, value in state['Noise']:
        if value:
            result[point['Y']][point['X']] = None
    return result


def play(output, root):
    saves, screens = [], []
    for number in range(1, 5):
        session = Session(output, root, number)
        session.start()
        if number == 1:
            require(session.turns() == 0, 'new game did not start at rank zero')
        else:
            require(session.turns() == saves[-1]['Turn'], 'default restart did not load saved rank')
            require((root / 'data/boohu/save').read_bytes() == (root / ('save-%d.native' % (number - 1))).read_bytes(),
                    'default restore modified save before gameplay')
        if number in (1, 3):
            before = session.turns()
            session.send(b'.')  # ui.go KeyWaitTurn -> player.go WaitTurn -> Renew(g,10).
            session.wait(lambda: session.live() and session.turns() == before + 10, 'one native wait turn')
        screens.append(session.snapshot())
        saves.append(session.save(screens[-1]))
        if number in (2, 4):
            require(stable_state(saves[-2]) == stable_state(saves[-1]), 'no-action restore changed authoritative native state')
            left, right = restore_cells(screens[-2], saves[-2]), restore_cells(screens[-1], saves[-1])
            # Union of exact source Noise positions, not heuristic glyph/OCR masking.
            for state in saves[-2:]:
                for point, value in state['Noise']:
                    if value:
                        left[point['Y']][point['X']] = right[point['Y']][point['X']] = None
            require(left == right, 'no-action restore changed exact map/HUD cells outside native noise')
    require([s['Turn'] for s in saves] == [10, 10, 20, 20], 'wrong native wait/save/restore ranks')
    require([s['Stats']['Turns'] for s in saves] == [1, 1, 2, 2], 'wrong native action counters')
    require(all(s['Player']['P'] == saves[0]['Player']['P'] for s in saves), 'waiting displaced player')
    for name in ('home', 'work', 'config', 'cache', 'state', 'runtime', 'tmp'):
        require(not any(p.is_file() for p in (root / name).rglob('*')), 'game wrote outside XDG data: ' + name)
    files = sorted(str(p.relative_to(root / 'data')) for p in (root / 'data').rglob('*') if p.is_file())
    require(files == ['boohu/save'], 'unexpected native data files: ' + str(files))
    record(root / 'receipt.json', dict(commit=COMMIT, version='v0.14', turns=[s['Turn'] for s in saves],
           action_counters=[s['Stats']['Turns'] for s in saves], restore_fields=list(RESTORE_FIELDS),
           exact_authoritative_restore=True, exact_map_hud_restore_outside_native_noise=True,
           default_no_argument_restore=True, clean_save_exit=True, native_data_files=files,
           screenshots=['screen-%d.png' % n for n in range(1, 5)],
           save_sha256=[hashlib.sha256((root / ('save-%d.native' % n)).read_bytes()).hexdigest() for n in range(1, 5)],
           limits=['PTY stream parsed by pyte; screenshots captured from real xterm on Xvfb, not a game GUI.',
                   'Save includes every mirrored exported gob field; opaque gruid GobEncoder payloads retained as base64.',
                   'Restore comparisons exclude derived UI/path/noise/log/automation state; Player FOV payload is retained and compared.',
                   'DrawLog includes wall-clock time; save byte identity is not claimed.',
                   'Unexported UI/runtime/RNG state is not serialized by upstream gob.']))


def stop(process):
    # Only processes started by this consumer; never global process cleanup.
    if process is not None and process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)


def main():
    output, root = [Path(value).resolve(strict=True) for value in sys.argv[1:3]]
    if '--terminal' in sys.argv:
        sys.stderr = (root / 'terminal.log').open('w', buffering=1)
        original = termios.tcgetattr(0)
        tty.setraw(0)
        try:
            play(output, root)
        except BaseException:
            (root / 'failure.txt').write_text(traceback.format_exc())
            raise
        finally:
            termios.tcsetattr(0, termios.TCSANOW, original)
        return
    require(len(sys.argv) == 3 and not any(root.iterdir()), 'usage: boohu-native.py OUTPUT EMPTY_EVIDENCE')
    require(Path('/gnu/store') not in root.parents and output not in root.parents, 'evidence must be outside store/output')
    require(os.access(output / 'bin/boohu', os.X_OK), 'normal output lacks executable')
    server = terminal = None
    readfd = writefd = None
    try:
        record(root / 'namespace.json', namespace_proof(Path('/proc/self')))
        store = readonly_store(root)
        env = environment(root)
        env['BOOHU_OUTPUT'] = str(output)
        # Reader compilation is external to the package and strictly offline.
        source = root / 'boohu-save-reader.go'
        source.write_text(READER)
        buildenv = dict(env, GO111MODULE='off', GOPROXY='off', GOSUMDB='off', GOTOOLCHAIN='local',
                        GOTELEMETRY='off', CGO_ENABLED='0', GOMAXPROCS='2',
                        GOCACHE=str(root / 'go-cache'), GOTMPDIR=str(root / 'go-tmp'),
                        HOME=str(root / 'go-home'), XDG_CONFIG_HOME=str(root / 'go-config'),
                        XDG_CACHE_HOME=str(root / 'go-user-cache'))
        for name in ('go-tmp', 'go-home', 'go-config', 'go-user-cache'):
            (root / name).mkdir(mode=0o700)
        with (root / 'reader-build.log').open('wb') as log:
            subprocess.run([os.environ['GO'], 'build', '-trimpath', '-o', str(root / 'boohu-save-reader'), str(source)],
                           env=buildenv, stdout=log, stderr=log, check=True, timeout=240)
        readfd, writefd = os.pipe()
        with (root / 'xvfb.log').open('wb') as log:
            server = subprocess.Popen([os.environ['XVFB'], '-displayfd', str(writefd), '-screen', '0',
                                       '1024x768x24', '-nolisten', 'tcp', '-ac'], env=env,
                                      pass_fds=(writefd,), stdin=subprocess.DEVNULL, stdout=log, stderr=log)
        os.close(writefd)
        writefd = None
        require(select.select([readfd], [], [], 20)[0], 'Xvfb did not publish display')
        display = ':' + os.read(readfd, 100).decode().strip()
        require(re.fullmatch(r':\d+', display), 'invalid private X display')
        env['DISPLAY'] = display
        record(root / 'xvfb.process.json', namespace_proof(Path('/proc') / str(server.pid)))
        with (root / 'xterm.log').open('wb') as log:
            terminal = subprocess.Popen([os.environ['XTERM'], '-display', display, '-geometry', '100x26+0+0',
                                         '-fn', 'fixed', '-xrm', 'XTerm*allowTitleOps: false',
                                         '-e', sys.executable, '-B', '-s', str(Path(__file__).resolve()),
                                         str(output), str(root), '--terminal'], env=env, stdout=log, stderr=log)
        status = terminal.wait(timeout=180)
        require(status == 0 and (root / 'receipt.json').is_file(), 'native xterm gameplay failed; see terminal/failure logs')
        record(root / 'proof.json', dict(output=str(output), official_expression='(@ (gnu packages games) boohu)',
               pinned_commit=COMMIT, readonly_store=store, receipt='receipt.json'))
    except BaseException:
        (root / 'launcher-failure.txt').write_text(traceback.format_exc())
        raise
    finally:
        stop(terminal)
        stop(server)
        if readfd is not None:
            os.close(readfd)
        if writefd is not None:
            os.close(writefd)


if __name__ == '__main__':
    main()
