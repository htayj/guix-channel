#!/usr/bin/env python3
"""Observe CalcRogue 6a-SP1 through its ordinary curses/save interface.

Decoder contract is derived from the pinned upstream files.c, rle.c,
huffman.c, hufftable.h and include/{world,player,monst,items,timer,constdata}.h.
The package builds the original 32-bit i686 ABI, including four-byte longs and
pointers. Saves are only read/copied, never created or modified by this test.
"""
import bisect
import codecs
import ctypes as C
import errno
import fcntl
import gzip
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

import pyte

ROWS, COLS = 25, 80
SOURCE_URL = 'https://www.ticalc.org/pub/89/asm/games/rpg/crogue.zip'
SOURCE_SHA256 = '6338d8d5460d7b7d270601aed9f76289a759b6d8602e5f48bd6e133fa3962c90'


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def record(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def namespace_proof(proc, evidence, label, uid, gid, host):
    ns = {key: os.readlink(proc / 'ns' / key) for key in host}
    files = {key: (proc / key).read_text() for key in
             ('status', 'uid_map', 'gid_map', 'net/dev', 'net/route', 'net/ipv6_route')}
    record(evidence / (label + '-namespace.json'), {'namespaces': ns, 'files': files})
    for key in ('user', 'mnt', 'net', 'pid'):
        require(ns[key] != host[key], 'not a private ' + key + ' namespace')
        require(ns[key] == os.readlink('/proc/self/ns/' + key), 'game escaped ' + key)
    for kind, number, field in (('uid', uid, 'Uid'), ('gid', gid, 'Gid')):
        values = re.search(r'^' + field + r':\s*(.+)$', files['status'], re.M)
        require(values and [int(x) for x in values[1].split()] == [number] * 4,
                'caller ' + kind + ' changed')
        require([int(x) for x in files[kind + '_map'].split()] == [number, number, 1],
                'not a same-identity ' + kind + ' mapping')
    interfaces = [line.split(':')[0].strip() for line in files['net/dev'].splitlines()[2:]
                  if ':' in line]
    require(interfaces == ['lo'], 'external network interfaces present')
    require(len(files['net/route'].splitlines()) <= 1, 'IPv4 routes present')
    require(all(row.split()[-1] == 'lo' for row in files['net/ipv6_route'].splitlines()
                if row.strip()), 'external IPv6 routes present')
    return ns


def readonly_store(evidence):
    def entries():
        text = Path('/proc/self/mountinfo').read_text()
        found = []
        for line in text.splitlines():
            fields = line.split()
            target = fields[4]
            for escaped, literal in (('\\040', ' '), ('\\011', '\t'),
                                     ('\\012', '\n'), ('\\134', '\\')):
                target = target.replace(escaped, literal)
            if target == '/gnu/store' or target.startswith('/gnu/store/'):
                found.append((target, fields[5].split(','), fields[6:fields.index('-')]))
        return text, found

    commands = []

    def mount(*args):
        result = subprocess.run([os.environ['MOUNT'], *args], capture_output=True,
                                text=True, timeout=10)
        commands.append({'args': args, 'status': result.returncode,
                         'stdout': result.stdout, 'stderr': result.stderr})
        record(evidence / 'mount-commands.json', commands)
        require(result.returncode == 0, 'store remount failed: ' + result.stderr)

    (evidence / 'mountinfo-before.txt').write_text(entries()[0])
    mount('--rbind', '/gnu/store', '/gnu/store')
    mount('--make-rprivate', '/gnu/store')
    for target in sorted({entry[0] for entry in entries()[1]}, key=len, reverse=True):
        mount('-o', 'remount,bind,ro', target)
    text, found = entries()
    (evidence / 'mountinfo-after.txt').write_text(text)
    require(found and any(target == '/gnu/store' for target, _, _ in found),
            'store mount missing')
    require(all('ro' in options and 'rw' not in options and not
                any(item.startswith(('shared:', 'master:')) for item in optional)
                for _, options, optional in found), 'store not recursively private/read-only')
    require(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY, 'store filesystem writable')
    return found


class Screen(pyte.Screen):
    last_graphic = ''

    def draw(self, data):
        super().draw(data)
        if data:
            self.last_graphic = data[-1]

    def repeat_character(self, count=1):
        if self.last_graphic:
            super().draw(self.last_graphic * (count or 1))


class Stream(pyte.Stream):
    # ncurses xterm terminfo emits REP, not supported by stock pyte 0.8.
    csi = dict(pyte.Stream.csi, b='repeat_character')
    events = pyte.Stream.events | {'repeat_character'}


ERRORS = re.compile(r'corrupt|segmentation fault|backtrace|couldn.t open|'
                    r'error initializing|returned ERR|no such file|permission denied|'
                    r'not found|traceback|you die', re.I)


class Session:
    def __init__(self, output, evidence):
        self.evidence = evidence
        evidence.mkdir(mode=0o700)
        self.screen = Screen(COLS, ROWS)
        self.stream = Stream(self.screen)
        self.decoder = codecs.getincrementaldecoder('utf-8')('strict')
        self.raw = bytearray()
        self.error_tail = ''
        self.inputs = []
        self.status = None
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            try:
                os.chdir(os.environ['HOME'])
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', ROWS, COLS, 0, 0))
                launcher = str(output / 'bin/calcrogue')
                env = {key: os.environ[key] for key in
                       ('PATH', 'LC_ALL', 'TERM', 'HOME', 'XDG_STATE_HOME',
                        'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'TERMINFO', 'TERMINFO_DIRS')
                       if key in os.environ}
                os.execve(launcher, [launcher], env)
            except BaseException:
                os.write(2, traceback.format_exc().encode())
                os._exit(127)

    def exited(self):
        if self.status is None:
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.status = os.waitstatus_to_exitcode(status)
        return self.status is not None

    def pump(self, delay=0.05):
        if self.fd not in select.select([self.fd], [], [], delay)[0]:
            return False
        try:
            data = os.read(self.fd, 65536)
        except OSError as error:
            if error.errno != errno.EIO:
                raise
            data = b''
        if not data:
            return False
        self.raw.extend(data)
        text = self.decoder.decode(data)
        self.stream.feed(text)
        self.error_tail += text
        require(not ERRORS.search(self.error_tail), 'native error in PTY output')
        self.error_tail = self.error_tail[-256:]
        return True

    def snapshot(self, label):
        record(self.evidence / (label + '.screen.json'),
               {'rows': self.screen.display,
                'cursor': {'x': self.screen.cursor.x, 'y': self.screen.cursor.y},
                'raw_bytes': len(self.raw)})
        (self.evidence / (label + '.screen.txt')).write_text('\n'.join(self.screen.display) + '\n')

    def await_screen(self, predicate, label, after=-1):
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            self.pump()
            if len(self.raw) > after and predicate():
                while self.pump(0.15):
                    require(time.monotonic() < deadline, 'terminal never settled: ' + label)
                if predicate():
                    self.snapshot(label)
                    return
            require(not self.exited(), 'game exited before ' + label)
        self.snapshot('timeout-' + label)
        raise RuntimeError('native screen timeout: ' + label)

    def send(self, label, key):
        require(not self.exited(), 'sending to exited native process')
        before = len(self.raw)
        data = key.encode('ascii')
        self.inputs.append({'label': label, 'hex': data.hex(), 'raw_offset': before})
        require(os.write(self.fd, data) == len(data), 'short PTY write')
        return before

    def action(self, label, key):
        self.send(label, key)
        # A wait can change only internal time/fuel. ncurses may legitimately
        # emit no bytes when the visible screen is unchanged. Save decoding,
        # not fabricated screen output, proves that these keys advanced turns.
        deadline = time.monotonic() + 0.5
        while time.monotonic() < deadline:
            self.pump()
        require(not self.exited() and self.is_game(), 'ordinary action left gameplay: ' + label)
        self.snapshot(label)

    def is_game(self):
        return bool(re.search(r'HP\d+/\d+ PW\d+/\d+ LV\d+ \$:',
                              '\n'.join(self.screen.display)))

    def position(self):
        require(self.is_game(), 'missing native gameplay HUD')
        x, y = self.screen.cursor.x, self.screen.cursor.y
        require(2 <= y < 22 and 0 <= x < COLS and self.screen.display[y][x] == '@',
                'native cursor does not identify drawn player')
        return x, y

    def move(self, label):
        old = self.position()
        # Use only visible clear floor; no seed, generated input/save or debug menu.
        for key, dx, dy in (('6', 1, 0), ('4', -1, 0), ('2', 0, 1), ('8', 0, -1),
                            ('3', 1, 1), ('1', -1, 1), ('9', 1, -1), ('7', -1, -1)):
            x, y = old[0] + dx, old[1] + dy
            if 0 <= x < COLS and 2 <= y < 22 and self.screen.display[y][x] == '.':
                self.action(label, key)
                require(self.position() != old, 'ordinary direction failed to move player')
                return {'key': key, 'before': old, 'after': self.position()}
        raise RuntimeError('no visible clear floor neighbor for ordinary movement')

    def save_quit(self):
        self.snapshot('before-save')
        self.send('native-save-and-quit', 'S')
        deadline = time.monotonic() + 15
        while not self.exited() and time.monotonic() < deadline:
            self.pump()
        require(self.exited(), 'ordinary S did not naturally terminate native game')
        while self.pump(0.05):
            pass
        self.snapshot('exited')
        require(self.status == 0, 'native game nonzero/signal exit: ' + str(self.status))

    def close(self):
        (self.evidence / 'terminal.raw').write_bytes(self.raw)
        record(self.evidence / 'pty-inputs.json', self.inputs)
        record(self.evidence / 'process.json', {'pid': self.pid, 'exit_status': self.status})
        # A failure is not accepted as gameplay. Private PID namespace teardown
        # handles any failed child; no signal is used as successful game exit.
        os.close(self.fd)


# Native i686 C ABI records: uint is ushort, longs and pointers are four bytes.
# Distinct pointer marker prevents semantic comparisons of relocated addresses
# even when the Python consumer itself is an x86_64 process.
U8, I8, U16, I16, U32, I32 = C.c_uint8, C.c_int8, C.c_uint16, C.c_int16, C.c_uint32, C.c_int32


class PTR(C.c_uint32):
    pass


class Link(C.Structure):
    _fields_ = [('type', I8), ('file', U8), ('offset', U16)]


class Descriptor(C.Structure):
    _fields_ = [(name, Link) for name in
                ('tileoffset', 'itemoffset', 'generate_item', 'generate_currency',
                 'startinginventory', 'spelllist', 'playerclasses', 'stsizes', 'stdata',
                 'shopdescs', 'titlescreen_light_plane', 'titlescreen_dark_plane')] + [
                    (name, U16) for name in ('itementries', 'numspells', 'numplayerclasses',
                    'tutorialclass', 'numshuffletabs', 'shuffletabsize', 'numshoptypes', 'padding')] + [
                    (name, Link) for name in ('mainmap', 'tutorialmap', 'misc_links')]


class Item(C.Structure):
    _fields_ = [('type', U16), ('next', U16), ('stacksize', U32), ('flags', U8),
                ('plus', I8), ('hotkey', U8), ('rustiness', U8), ('x', U8), ('y', U8), ('padding', U16)]


class Items(C.Structure):
    _fields_ = [('num', U16), ('alloced', U16), ('items', PTR)]


class Monster(C.Structure):
    _fields_ = [('type', Link), ('hps', I16), ('energy', U8), ('power', U8),
                ('x', I16), ('y', I16), ('flags', U16), ('pad2', U16)]


class Timer(C.Structure):
    _fields_ = [('type', U16), ('padding', U16), ('desc', PTR), ('expiry', U32)]


class Player(C.Structure):
    _fields_ = [(name, I16) for name in ('x', 'y', 'class', 'hps', 'hps_max',
                'hps_max_mod', 'pps', 'pps_max', 'pps_max_mod')] + [
                (name, U16) for name in ('partialhps', 'partialpps', 'level')] + [
                ('facing_forced', I8), ('facing', I8), ('velocity', U16),
                ('stat_timers', Timer * 10), ('intrinsic', I16 * 22),
                ('extrinsic', I16 * 22), ('maximum', I16 * 22), ('skill', U16 * 9),
                ('skill_marks', U16 * 9), ('xp', U32), ('satiation', I32), ('debt', U32),
                ('inventory', Item * 50), ('spellknowledge', PTR), ('score', U32)]


class World(C.Structure):
    _fields_ = [('desc', Descriptor)] + [(name, PTR) for name in
                ('constfileoffset', 'dll_functions', 'dll_interface', 'tiledescs')] + [
                ('current_map_link', Link)] + [(name, PTR) for name in
                ('current_map', 'itemdescs', 'spelldescs', 'shopdescs', 'playerclasses',
                 'shuffledata', 'shuffletranslation')] + [
                ('mapsize_x', U16), ('mapsize_y', U16), ('t', PTR), ('items', Items),
                ('m', Monster * 128), ('plr', Player), ('wandering_monsters', PTR),
                ('wandering_monsters_num', U16), ('pad', U16), ('itemids', PTR),
                ('time', U32), ('level', U8), ('maxlevel', U8), ('messagevis', U8),
                ('interrupt', U8), ('options', U8 * 2), ('game_flags', U8 * 64),
                ('debug_mode', U8)]


class Tile(C.Structure):
    _fields_ = [('type', U8), ('flags', U8), ('special', U16)]


def semantic(value):
    if isinstance(value, C.Array):
        return [semantic(item) for item in value]
    if isinstance(value, C.Structure):
        return {name: semantic(getattr(value, name)) for name, kind in value._fields_
                if kind is not PTR and name not in ('padding', 'pad', 'pad2', 'messagevis', 'interrupt')}
    return value


# Exact pinned hufftable.h decoder entries are inserted below, not learned
# from the running game or its saves.
HUFFMAN = (
    (0x0, 6, 0x31), (0x400, 6, 0x21), (0x800, 9, 0x3C), (0x880, 9, 0xFF),
    (0x900, 8, 0x15), (0xA00, 7, 0x10), (0xC00, 7, 0xD), (0xE00, 9, 0x4F),
    (0xE80, 9, 0xCA), (0xF00, 9, 0x17), (0xF80, 9, 0x1F), (0x1000, 5, 0x8),
    (0x1800, 5, 0x5), (0x2000, 5, 0x7), (0x2800, 9, 0x2A), (0x2880, 9, 0x35),
    (0x2900, 12, 0xB1), (0x2910, 12, 0xB2), (0x2920, 11, 0x52), (0x2940, 12, 0xDF),
    (0x2950, 12, 0x93), (0x2960, 12, 0xE0), (0x2970, 12, 0x91), (0x2980, 12, 0xDC),
    (0x2990, 12, 0x97), (0x29A0, 12, 0x87), (0x29B0, 12, 0x88), (0x29C0, 10, 0x40),
    (0x2A00, 8, 0x81), (0x2B00, 11, 0xA0), (0x2B20, 12, 0xEE), (0x2B30, 12, 0x73),
    (0x2B40, 12, 0xCF), (0x2B50, 12, 0xA8), (0x2B60, 12, 0xF2), (0x2B70, 12, 0x6B),
    (0x2B80, 11, 0x74), (0x2BA0, 12, 0x77), (0x2BB0, 12, 0x78), (0x2BC0, 12, 0xCC),
    (0x2BD0, 12, 0xAD), (0x2BE0, 12, 0xF6), (0x2BF0, 12, 0x63), (0x2C00, 12, 0xCE),
    (0x2C10, 12, 0xA9), (0x2C20, 11, 0x68), (0x2C40, 11, 0xA7), (0x2C60, 12, 0xF3),
    (0x2C70, 12, 0x6A), (0x2C80, 12, 0xBA), (0x2C90, 12, 0xBB), (0x2CA0, 11, 0x43),
    (0x2CC0, 11, 0xC4), (0x2CE0, 12, 0x45), (0x2CF0, 12, 0x47), (0x2D00, 12, 0xDA),
    (0x2D10, 12, 0x99), (0x2D20, 12, 0xE8), (0x2D30, 12, 0x84), (0x2D40, 11, 0xC8),
    (0x2D60, 12, 0xFB), (0x2D70, 12, 0x51), (0x2D80, 12, 0xB4), (0x2D90, 12, 0xB5),
    (0x2DA0, 12, 0xFC), (0x2DB0, 12, 0x4E), (0x2DC0, 10, 0x4C), (0x2E00, 12, 0xD8),
    (0x2E10, 12, 0x9C), (0x2E20, 11, 0x7B), (0x2E40, 12, 0x55), (0x2E50, 12, 0x5B),
    (0x2E60, 11, 0x57), (0x2E80, 10, 0x83), (0x2EC0, 12, 0xC3), (0x2ED0, 12, 0xBC),
    (0x2EE0, 12, 0x42), (0x2EF0, 12, 0x44), (0x2F00, 12, 0xD9), (0x2F10, 12, 0x9A),
    (0x2F20, 12, 0xE9), (0x2F30, 12, 0x7E), (0x2F40, 12, 0xC9), (0x2F50, 12, 0xB3),
    (0x2F60, 12, 0xFA), (0x2F70, 12, 0x54), (0x2F80, 12, 0xDB), (0x2F90, 12, 0x98),
    (0x2FA0, 11, 0x82), (0x2FC0, 12, 0xC7), (0x2FD0, 12, 0xB6), (0x2FE0, 11, 0x4B),
    (0x3000, 4, 0x3), (0x4000, 2, 0x5F), (0x8000, 12, 0xC2), (0x8010, 12, 0xBD),
    (0x8020, 11, 0x3F), (0x8040, 10, 0x3D), (0x8080, 12, 0xD6), (0x8090, 12, 0x9F),
    (0x80A0, 12, 0xED), (0x80B0, 12, 0x75), (0x80C0, 12, 0xCD), (0x80D0, 12, 0xAC),
    (0x80E0, 12, 0xF4), (0x80F0, 12, 0x69), (0x8100, 12, 0xDE), (0x8110, 12, 0x94),
    (0x8120, 12, 0xE3), (0x8130, 12, 0x8D), (0x8140, 10, 0x5C), (0x8180, 10, 0x86),
    (0x81C0, 12, 0xC1), (0x81D0, 12, 0xBE), (0x81E0, 11, 0x39), (0x8200, 11, 0xAB),
    (0x8220, 11, 0x62), (0x8240, 11, 0xAA), (0x8260, 12, 0xF5), (0x8270, 12, 0x66),
    (0x8280, 11, 0xB8), (0x82A0, 12, 0xFE), (0x82B0, 12, 0x4A), (0x82C0, 12, 0xC5),
    (0x82D0, 12, 0xB9), (0x82E0, 11, 0x49), (0x8300, 10, 0xE6), (0x8340, 10, 0x27),
    (0x8380, 12, 0x95), (0x8390, 12, 0x96), (0x83A0, 12, 0x89), (0x83B0, 12, 0x8A),
    (0x83C0, 10, 0x2C), (0x8400, 9, 0x1C), (0x8480, 11, 0x1E), (0x84A0, 11, 0x26),
    (0x84C0, 12, 0xC0), (0x84D0, 12, 0xBF), (0x84E0, 11, 0x2D), (0x8500, 11, 0x5D),
    (0x8520, 11, 0xF7), (0x8540, 12, 0xCB), (0x8550, 12, 0xAF), (0x8560, 12, 0x60),
    (0x8570, 12, 0x61), (0x8580, 12, 0xD3), (0x8590, 12, 0xA3), (0x85A0, 12, 0xF0),
    (0x85B0, 12, 0x6F), (0x85C0, 12, 0xD1), (0x85D0, 12, 0xA5), (0x85E0, 11, 0x6C),
    (0x8600, 9, 0x2E), (0x8680, 12, 0xD4), (0x8690, 12, 0xA2), (0x86A0, 12, 0xEF),
    (0x86B0, 12, 0x71), (0x86C0, 12, 0xD0), (0x86D0, 12, 0xA6), (0x86E0, 12, 0xF1),
    (0x86F0, 12, 0x6E), (0x8700, 12, 0xD7), (0x8710, 12, 0x9E), (0x8720, 12, 0xEB),
    (0x8730, 12, 0x79), (0x8740, 11, 0x58), (0x8760, 12, 0xF8), (0x8770, 12, 0x5E),
    (0x8780, 10, 0x30), (0x87C0, 10, 0x33), (0x8800, 9, 0x9D), (0x8880, 12, 0xE5),
    (0x8890, 12, 0x8B), (0x88A0, 12, 0xE4), (0x88B0, 12, 0x8C), (0x88C0, 12, 0xC6),
    (0x88D0, 12, 0xB7), (0x88E0, 12, 0xFD), (0x88F0, 12, 0x4D), (0x8900, 11, 0x9B),
    (0x8920, 12, 0xEA), (0x8930, 12, 0x7C), (0x8940, 10, 0x56), (0x8980, 12, 0xD5),
    (0x8990, 12, 0xA1), (0x89A0, 11, 0x72), (0x89C0, 12, 0xE2), (0x89D0, 12, 0x8E),
    (0x89E0, 12, 0xE1), (0x89F0, 12, 0x8F), (0x8A00, 7, 0xC), (0x8C00, 6, 0xA),
    (0x9000, 5, 0x20), (0x9800, 7, 0x13), (0x9A00, 8, 0x18), (0x9B00, 12, 0xD2),
    (0x9B10, 12, 0xA4), (0x9B20, 11, 0x6D), (0x9B40, 10, 0x1A), (0x9B80, 9, 0x1D),
    (0x9C00, 9, 0x7D), (0x9C80, 9, 0x28), (0x9D00, 8, 0x41), (0x9E00, 9, 0xAE),
    (0x9E80, 9, 0x3A), (0x9F00, 8, 0x14), (0xA000, 5, 0x6), (0xA800, 7, 0xE),
    (0xAA00, 7, 0x80), (0xAC00, 6, 0x9), (0xB000, 9, 0x92), (0xB080, 10, 0x48),
    (0xB0C0, 10, 0x50), (0xB100, 10, 0x2B), (0xB140, 10, 0x2F), (0xB180, 10, 0xE7),
    (0xB1C0, 10, 0x34), (0xB200, 8, 0x19), (0xB300, 9, 0x1B), (0xB380, 10, 0x23),
    (0xB3C0, 10, 0x25), (0xB400, 10, 0x53), (0xB440, 10, 0xEC), (0xB480, 10, 0x36),
    (0xB4C0, 10, 0x37), (0xB500, 8, 0x24), (0xB600, 8, 0x11), (0xB700, 9, 0x3E),
    (0xB780, 9, 0x22), (0xB800, 7, 0xF), (0xBA00, 7, 0xB), (0xBC00, 9, 0x12),
    (0xBC80, 9, 0x16), (0xBD00, 11, 0x70), (0xBD20, 11, 0x76), (0xBD40, 10, 0x32),
    (0xBD80, 11, 0xF9), (0xBDA0, 11, 0x64), (0xBDC0, 10, 0x59), (0xBE00, 11, 0x90),
    (0xBE20, 11, 0xB0), (0xBE40, 11, 0x7A), (0xBE60, 11, 0x7F), (0xBE80, 11, 0x38),
    (0xBEA0, 11, 0x46), (0xBEC0, 10, 0x3B), (0xBF00, 10, 0x5A), (0xBF40, 11, 0x65),
    (0xBF60, 11, 0x67), (0xBF80, 10, 0x29), (0xBFC0, 11, 0x85), (0xBFE0, 11, 0xDD),
    (0xC000, 4, 0x2), (0xD000, 5, 0x4), (0xD800, 5, 0x1), (0xE000, 3, 0x0),
)


class SaveReader:
    """Read gzip's native four-byte header, Huffman, RLE and byte transpose."""
    def __init__(self, payload):
        require(len(payload) > 6 and payload[:4] == b'\0' * 4,
                'invalid native PC save header (expected fixed 32-bit zero checksum)')
        self.data = payload[4:]
        self.bit = 0
        self.run = 0
        self.char = 0
        self.starts = [entry[0] for entry in HUFFMAN]

    def huffman(self):
        require(self.bit < len(self.data) * 8, 'truncated native Huffman payload')
        start, shift = divmod(self.bit, 8)
        look = int.from_bytes((self.data[start:start + 3] + b'\0\0\0')[:3], 'big')
        look = ((look << shift) >> 8) & 0xffff
        code, width, char = HUFFMAN[bisect.bisect_right(self.starts, look) - 1]
        require((look >> (16 - width)) == (code >> (16 - width)), 'invalid Huffman code')
        require(self.bit + width <= len(self.data) * 8, 'truncated Huffman symbol')
        self.bit += width
        return char

    def byte(self):
        if not self.run:
            char = self.huffman()
            if char != 0x5f:
                return char
            self.char = self.huffman()
            self.run = self.huffman()
            if self.run & 0x80:
                self.run = ((self.run & 0x7f) << 8) | self.huffman()
            require(0 < self.run <= 0x7fff, 'invalid native RLE run')
        self.run -= 1
        return self.char

    def block(self, size, granularity):
        require(0 <= size <= 16 * 1024 * 1024 and granularity > 0,
                'invalid native serialized block length')
        result = bytearray(size)
        for offset in range(granularity):
            for index in range(offset, size, granularity):
                result[index] = self.byte()
        return bytes(result)


def native_save(state, evidence, label):
    path = state / 'rgsave.gz'
    require(path.is_file() and not path.is_symlink(), 'native rgsave.gz missing')
    blob = path.read_bytes()
    (evidence / (label + '.save.gz')).write_bytes(blob)
    payload = gzip.decompress(blob)
    (evidence / (label + '.save.payload')).write_bytes(payload)
    reader = SaveReader(payload)
    world_bytes = reader.block(C.sizeof(World), C.sizeof(Monster))
    (evidence / (label + '.world.bytes')).write_bytes(world_bytes)
    world = World.from_buffer_copy(world_bytes)
    require(0 < world.mapsize_x <= 128 and 0 < world.mapsize_y <= 128,
            'invalid native map dimensions; ABI/layout changed')
    require(0 <= world.plr.x < world.mapsize_x and 0 <= world.plr.y < world.mapsize_y,
            'saved player outside native map')
    require(world.plr.hps > 0 and getattr(world.plr, 'class') == 0,
            'save is not the living ordinary Fighter')
    require(world.debug_mode == 0, 'debug-mode game rejected')
    require(world.items.num <= world.items.alloced <= 65535 and
            0 < world.desc.itementries <= 4096 and world.desc.numspells <= 4096 and
            world.desc.shuffletabsize <= 4096 and world.wandering_monsters_num <= 128,
            'invalid native save counts; ABI/layout changed')
    parts = [('tiles', C.sizeof(Tile) * world.mapsize_x * world.mapsize_y, C.sizeof(Tile)),
             ('shuffle', 2 * world.desc.shuffletabsize, 2),
             ('identifications', (world.desc.itementries // 32 + 1) * 4, 1),
             ('spells', 4 * world.desc.numspells, 4),
             ('floor_items', C.sizeof(Item) * world.items.alloced, C.sizeof(Item)),
             ('wandering_monsters', C.sizeof(Monster) * world.wandering_monsters_num,
              C.sizeof(Monster))]
    blocks = {}
    for name, size, granularity in parts:
        block = reader.block(size, granularity)
        (evidence / (label + '.' + name + '.bytes')).write_bytes(block)
        blocks[name] = hashlib.sha256(block).hexdigest()
    # flush pads a final 16-bit Huffman word; it cannot contain another block.
    require(reader.run == 0 and 0 <= len(reader.data) * 8 - reader.bit <= 16,
            'unexpected extra save data or unconsumed RLE run')
    values = semantic(world)
    result = {'world': values, 'block_sha256': blocks}
    record(evidence / (label + '.semantic.json'), result)
    record(evidence / (label + '.save-format.json'), {
        'source_url': SOURCE_URL, 'source_sha256': SOURCE_SHA256,
        'gzip_sha256': hashlib.sha256(blob).hexdigest(),
        'payload_sha256': hashlib.sha256(payload).hexdigest(),
        'sizes': {kind.__name__: C.sizeof(kind) for kind in
                  (World, Descriptor, Player, Monster, Item, Items, Timer, Tile, Link)},
        'pointer_bytes': C.sizeof(PTR), 'decoded_bits': reader.bit,
        'discarded_semantics': 'raw pointers, C padding and UI messagevis/interrupt only',
        'format': 'gzip -> 32-bit PC checksum header -> pinned Huffman -> RLE -> per-block byte transpose'})
    return result


def process_proof(session, output, state, evidence, label, uid, gid, host):
    proc = Path('/proc') / str(session.pid)
    namespaces = namespace_proof(proc, evidence, label, uid, gid, host)
    executable = os.readlink(proc / 'exe')
    native = output / 'libexec/calcrogue/calcrogue'
    elf = native.read_bytes()[:20]
    require(elf[:6] == b'\x7fELF\x01\x01' and int.from_bytes(elf[18:20], 'little') == 3,
            'native executable is not the source-compatible i686 little-endian ABI')
    require(Path(executable).resolve() == native.resolve(), 'launcher did not exec native game')
    argv = [os.fsdecode(part) for part in (proc / 'cmdline').read_bytes().split(b'\0') if part]
    require(argv == [str(native)], 'nonordinary native argv')
    require(os.readlink(proc / 'cwd') == str(state), 'game escaped private XDG state cwd')
    child_env = dict(part.split(b'=', 1) for part in (proc / 'environ').read_bytes().split(b'\0')
                     if b'=' in part)
    require(child_env[b'HOME'] == os.fsencode(os.environ['HOME']), 'game HOME changed')
    require(child_env[b'XDG_STATE_HOME'] == os.fsencode(os.environ['XDG_STATE_HOME']),
            'game XDG state escaped')
    require(not any(key in child_env for key in (b'MOUNT', b'PYTHONPATH', b'HOST_UID', b'HOST_GID'))
            and not any(key.startswith(b'HOST_') for key in child_env),
            'native game inherited harness-only environment')
    fds = [os.readlink(proc / 'fd' / str(fd)) for fd in (0, 1, 2)]
    require(os.isatty(session.fd) and len(set(fds)) == 1 and fds[0].startswith('/dev/pts/'),
            'native stdio not attached to one real PTY')
    require(os.getpgid(session.pid) == session.pid and os.tcgetpgrp(session.fd) == session.pid,
            'native process not controlling PTY foreground group')
    record(evidence / (label + '-process-proof.json'), {
        'pid': session.pid, 'executable': executable, 'argv': argv, 'cwd': str(state),
        'home': os.environ['HOME'], 'terminal_fds': fds, 'foreground_group': session.pid,
        'namespaces': namespaces})
    return session.pid


DOC_SHA256 = {
    'COPYING': '12704ed7033575740b513fc3e8e403ce1b6e4c4254a7dba4f4dd31712973bea3',
    'README': '51d10b2496c4468b4dd816d66ee5339a5669f72ac44e9a55676b40eaaa289410',
    'CHANGELOG': '05f030b634062eacac513c1ad67c73c2f1de61396feb70a659924e8906da74d5',
    'readme.txt': '352c238dad36961a644b75182c1645622dc03ad83b35b56c91f59dae9ae6da45',
    'crogue.c': 'b051e0f1d9c14b1effab0fe3ae3adaef957252f5495e8166e7924d21521dcf62',
    'sgt/COPYING': '12704ed7033575740b513fc3e8e403ce1b6e4c4254a7dba4f4dd31712973bea3',
    'mibic/main.c': '0ae8fa6821032315c84599720529eb6b897431ea8901c73f8c5b7dae46cf68d6',
    'COPYING.LGPL-2.1': 'a9bdde5616ecdd1e980b44f360600ee8783b1f99b8cc83a2beb163a0a390e861',
}


def notices(output, evidence):
    hashes = {}
    for name, expected in DOC_SHA256.items():
        blob = (output / 'share/doc/calcrogue' / name).read_bytes()
        actual = hashlib.sha256(blob).hexdigest()
        require(actual == expected, 'canonical source notice changed: ' + name)
        hashes[name] = {'sha256': actual, 'bytes': len(blob)}
    record(evidence / 'license-closure.json', {
        'source_url': SOURCE_URL, 'source_sha256': SOURCE_SHA256,
        'canonical_documents': hashes,
        'main_grant': 'GPL2-or-later explicit crogue.c grant, original notice and GPL2 terms retained',
        'mibic': 'original unversioned LGPL banner retained; canonical LGPL2.1 terms selected under section 13, not author-explicit 2.1',
        'lgpl_terms_url': 'https://raw.githubusercontent.com/gcc-mirror/gcc/d0ca130aa5d50cdaeea8e5c343d65250cdf51955/COPYING.LIB',
        'scope': 'native Linux source port; excluded upstream bin* prebuilts and Palm fonts not claimed GPL'})


def main():
    require(len(sys.argv) == 6, 'usage: DRIVER OUTPUT EVIDENCE UID GID HOST_NAMESPACE_JSON')
    output, evidence = map(Path, sys.argv[1:3])
    uid, gid = map(int, sys.argv[3:5])
    host = json.loads(Path(sys.argv[5]).read_text())
    require(set(host) == {'user', 'mnt', 'net', 'pid'}, 'invalid host namespace receipt')
    require(output.is_absolute() and str(output.resolve()) == str(output), 'noncanonical output')
    require(output.parent == Path('/gnu/store'), 'output is not one prebuilt store item')
    require((output / 'bin/calcrogue').is_file(), 'ordinary calcrogue launcher missing')
    namespace_proof(Path('/proc/self'), evidence, 'driver', uid, gid, host)
    mounts = readonly_store(evidence)
    notices(output, evidence)
    state = Path(os.environ['XDG_STATE_HOME']) / 'calcrogue'
    require(not state.exists(), 'new game requires pristine private state')
    sessions = []
    pids = []

    def start(label, fresh=False):
        session = Session(output, evidence / label)
        sessions.append(session)
        if fresh:
            session.await_screen(lambda: 'New game' in '\n'.join(session.screen.display), 'new-game-menu')
            session.send('choose-new-game', 'a')
            session.await_screen(lambda: 'Fighter' in '\n'.join(session.screen.display), 'class-menu')
            session.send('choose-fighter', 'a')
            session.await_screen(lambda: 'After the Creation' in '\n'.join(session.screen.display),
                                 'ordinary-intro')
            session.send('acknowledge-intro', '\n')
        session.await_screen(session.is_game, 'native-gameplay')
        require(not ('New game' in '\n'.join(session.screen.display)), 'restore entered new-game menu')
        pids.append(process_proof(session, output, state, evidence, label, uid, gid, host))
        return session

    try:
        first = start('new-game', fresh=True)
        initial = first.position()
        movement = first.move('ordinary-movement')
        first.action('ordinary-wait', '5')
        first.save_quit()
        saved = native_save(state, evidence, 'first')
        require(saved['world']['time'] >= 2, 'ordinary new-game actions did not advance turns')
        require(movement['after'] != initial, 'no meaningful movement observed')

        # Independent process restores via startup, then ordinary S resaves with
        # no gameplay action. Compare the complete non-pointer semantic payload.
        checkpoint = start('restore-checkpoint')
        checkpoint.save_quit()
        restored = native_save(state, evidence, 'checkpoint')
        require(restored == saved, 'no-action restore/resave changed saved semantic state')

        continued = start('continued-game')
        next_movement = continued.move('continued-movement')
        continued.action('continued-wait', '5')
        continued.save_quit()
        resaved = native_save(state, evidence, 'continued')
        require(resaved['world']['time'] >= restored['world']['time'] + 2,
                'restored game did not continue its saved turn counter')
        require((resaved['world']['plr']['x'], resaved['world']['plr']['y']) !=
                (restored['world']['plr']['x'], restored['world']['plr']['y']),
                'continued movement absent from native save')
        for field in ('desc', 'current_map_link', 'level', 'maxlevel', 'mapsize_x', 'mapsize_y'):
            require(resaved['world'][field] == restored['world'][field],
                    'continued save lost level/descriptor continuity: ' + field)
        for field in ('class', 'intrinsic', 'maximum'):
            require(resaved['world']['plr'][field] == restored['world']['plr'][field],
                    'continued save lost player continuity: ' + field)
        elapsed = resaved['world']['time'] - restored['world']['time']
        for old, new in zip(restored['world']['plr']['inventory'], resaved['world']['plr']['inventory']):
            require({key: value for key, value in old.items() if key != 'stacksize'} ==
                    {key: value for key, value in new.items() if key != 'stacksize'},
                    'continued save lost carried equipment identity')
            # timepass burns equipped Fighter torch fuel once per turn. Other
            # inventory members must retain their quantities under move/wait.
            require(new['stacksize'] == old['stacksize'] or
                    (old['flags'] & 1 and 0 < old['stacksize'] - new['stacksize'] <= elapsed),
                    'inventory quantity changed beyond ordinary equipped fuel burn')
        require(resaved['block_sha256']['shuffle'] == restored['block_sha256']['shuffle'] and
                resaved['block_sha256']['identifications'] == restored['block_sha256']['identifications'],
                'continued save lost shuffled/identified item identity')
        require(len(set(pids)) == 3, 'gameplay did not use independent native processes')
        record(evidence / 'result.json', {
            'status': 'CALCROGUE_NATIVE_OK', 'source_url': SOURCE_URL, 'source_sha256': SOURCE_SHA256,
            'rng_control': None, 'injected_save': False, 'engine_hooks': False,
            'natural_exit_statuses': [session.status for session in sessions], 'pids': pids,
            'movements': [movement, next_movement],
            'turns': [saved['world']['time'], restored['world']['time'], resaved['world']['time']],
            'restore_checkpoint_semantically_equal': True, 'readonly_store_mounts': mounts,
            'save_files': [str(path.relative_to(state)) for path in sorted(state.rglob('*')) if path.is_file()]})
    finally:
        for session in sessions:
            session.close()
    print('CALCROGUE_NATIVE_OK')


if __name__ == '__main__':
    try:
        main()
    except BaseException:
        if len(sys.argv) >= 3 and Path(sys.argv[2]).is_dir():
            (Path(sys.argv[2]) / 'failure.txt').write_text(traceback.format_exc())
        raise
