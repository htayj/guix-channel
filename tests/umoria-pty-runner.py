#!/usr/bin/env python3
"""Exercise the unmodified Umoria UI, movement, save/resume and character files.

Uses pyte only to decode the real terminal stream; never invents a frame.
OMP_RUNTIME_RAW_CAPTURE: exact restored live gameplay bytes, before saving.
OMP_RUNTIME_NATIVE_CAPTURE: exact upstream character description bytes.
OMP_RUNTIME_TEXT_CAPTURE: decoded live gameplay screen (24 by 80).
OMP_RUNTIME_TRANSCRIPT: exact concatenation of both complete PTY sessions.
"""
import errno
import fcntl
import os
from pathlib import Path
import select
import signal
import socket
import struct
import sys
import termios
import time

import pyte


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


class Session:
    def __init__(self, executable, args, env, work):
        self.raw = bytearray()
        self.screen = pyte.Screen(80, 24)
        self.stream = pyte.Stream(self.screen)
        self.raw_path = Path(work).parent / ('resume.raw' if '-n' not in args
                                            else 'new-game.raw')
        self.pid, self.fd = os.forkpty()
        if self.pid == 0:
            os.chdir(work)
            fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack('HHHH', 24, 80, 0, 0))
            os.execve(executable, [executable] + args, env)
        self.alive = True

    def read(self, timeout=0.1):
        if not select.select([self.fd], [], [], timeout)[0]:
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
        # TERM=vt100 avoids modern ncurses REP optimisation and all upstream
        # game data here is ASCII.  Chunk boundaries therefore need no decoder.
        self.stream.feed(data.decode('ascii'))
        require(len(self.raw) < 4000000, 'excessive terminal output')
        return True

    def wait(self, predicate, description, timeout=20):
        deadline = time.monotonic() + timeout
        while not predicate():
            require(time.monotonic() < deadline,
                    description + '\nPTY suffix: ' + repr(bytes(self.raw[-1800:])))
            self.read()

    def marker(self, text, start=0):
        self.wait(lambda: text in self.raw[start:]
                  or text.decode('ascii') in '\n'.join(self.screen.display),
                  'missing UI prompt ' + repr(text))

    def send(self, data):
        start = len(self.raw)
        os.write(self.fd, data)
        return start

    def settle(self):
        deadline = time.monotonic() + 5
        while self.read(0.2):
            require(time.monotonic() < deadline, 'terminal did not settle')

    def gameplay(self):
        self.wait(lambda: len(self.positions()) == 1, 'no unique player on live map')
        self.settle()
        require('HP' in '\n'.join(self.screen.display), 'missing character status')
        return self.positions()[0]

    def positions(self):
        return [(row, col) for row, text in enumerate(self.screen.display[1:23], 1)
                for col, char in enumerate(text) if char == '@']

    def sheet(self, work, filename):
        start = self.send(b'C')
        self.marker(b'<f>ile character description.', start)
        start = self.send(b'f')
        self.marker(b'File name:', start)
        target = work / filename
        self.send(filename.encode() + b'\r')
        self.wait(lambda: target.exists() and target.stat().st_size > 0,
                  'upstream character file not written')
        self.settle()
        data = target.read_bytes()
        require(b'OMP-Moria' in data and b"[Character's Equipment List]" in data
                and b'[General Inventory List]' in data,
                'character description missing identity/equipment/inventory')
        return data

    def save(self, path):
        start = self.send(b'\x18')
        self.marker(b'Saving game...', start)
        # endGame() first calls printMessage(nullptr): the pending save
        # message must be acknowledged before it flushes input and shows scores.
        self.marker(b'-more-', start)
        self.send(b' ')
        self.marker(b'Rank', start)
        self.settle()
        require(path.is_file() and path.stat().st_size > 1000, 'missing real save')
        # The scoreboard waits for a key after flushing earlier input.
        self.send(b' ')
        deadline = time.monotonic() + 15
        while True:
            self.read()
            pid, status = os.waitpid(self.pid, os.WNOHANG)
            if pid:
                self.alive = False
                require(os.waitstatus_to_exitcode(status) == 0, 'game exit failed')
                break
            require(time.monotonic() < deadline, 'game failed to exit after save')

    def close(self):
        if self.alive:
            os.kill(self.pid, signal.SIGKILL)
            os.waitpid(self.pid, 0)
            self.alive = False
        os.close(self.fd)
        self.raw_path.write_bytes(self.raw)


def exercise(executable, root, explicit, custom_save=False, capture=False):
    root.mkdir(parents=True)
    for name in ('home', 'config', 'data', 'cache', 'state', 'runtime', 'tmp', 'work'):
        (root / name).mkdir(mode=0o700)
    env = {'HOME': str(root / 'home'), 'XDG_CONFIG_HOME': str(root / 'config'),
           'XDG_DATA_HOME': str(root / 'data'), 'XDG_CACHE_HOME': str(root / 'cache'),
           'XDG_RUNTIME_DIR': str(root / 'runtime'), 'TMPDIR': str(root / 'tmp'),
           'TERM': 'vt100', 'LC_ALL': 'C', 'PATH': '/nonexistent'}
    if explicit:
        env['XDG_STATE_HOME'] = str(root / 'state')
    state = (root / 'state' if explicit else root / 'home/.local/state') / 'umoria'
    work = root / 'work'
    # Custom paths must remain relative to the caller, not be silently reduced
    # to a basename or redirected below XDG state by the launcher.
    if custom_save:
        (work / 'saves').mkdir()
        save_arg = ['saves/explicit.sav']
        save = work / save_arg[0]
    else:
        save_arg = []
        save = state / 'game.sav'
    transcript = bytearray()
    session = Session(executable, ['-n', '-s', '424242'] + save_arg, env, work)
    try:
        # Wait for the real splash prompt, never send before curses raw input
        # has been initialized (the historical Expect helper raced this).
        session.marker(b'press any key')
        start = session.send(b' ')
        session.marker(b'Choose a race', start)
        start = session.send(b'a')
        session.marker(b'Choose a sex', start)
        start = session.send(b'm')
        session.marker(b'Hit space to re-roll', start)
        start = session.send(b'\x1b')
        session.marker(b'Choose a class', start)
        start = session.send(b'a')
        session.marker(b"Enter your player's name", start)
        start = session.send(b'OMP-Moria\r')
        session.marker(b'press any key to continue, or Q to exit', start)
        start = session.send(b' ')
        session.marker(b'Press ? for help', start)
        before = session.gameplay()
        moved = before
        # Default Umoria uses numeric directions, not vi's j/l keys.  Try
        # adjacent ordinary movement commands until the live @ actually moves.
        for key in (b'6', b'2', b'4', b'8', b'3', b'1', b'7', b'9'):
            session.send(key)
            session.settle()
            moved = session.gameplay()
            if moved != before:
                break
        require(moved != before, 'movement never changed player coordinates')
        original_sheet = session.sheet(work, 'before.txt')
        session.gameplay()
        session.save(save)
        transcript.extend(session.raw)
        saved = save.read_bytes()
        require(saved[:3] == bytes((5, 7, 15)), 'wrong upstream save format version')
    finally:
        session.close()
    require((state / 'scores.dat').is_file(), 'no persistent per-user scores')
    require(save.stat().st_mode & 0o077 == 0, 'save file is not private')
    require((state / 'scores.dat').stat().st_mode & 0o077 == 0,
            'per-user scores are not private')
    session = Session(executable, save_arg, env, work)
    try:
        session.marker(b'press any key')
        start = session.send(b' ')
        session.marker(b'Restoring Memory...', start)
        session.marker(b'<f>ile character description.', start)
        start = session.send(b' ')
        session.marker(b'Press ? for help', start)
        restored = session.gameplay()
        require(restored == moved, 'save/resume did not retain moved coordinates')
        gameplay_raw = bytes(session.raw)
        gameplay_text = '\n'.join(session.screen.display) + '\n'
        restored_sheet = session.sheet(work, 'after.txt')
        require(restored_sheet == original_sheet,
                'save/resume changed character identity/stats/equipment/inventory')
        if capture:
            for variable, data in (
                ('OMP_RUNTIME_RAW_CAPTURE', gameplay_raw),
                ('OMP_RUNTIME_TEXT_CAPTURE', gameplay_text.encode()),
                ('OMP_RUNTIME_NATIVE_CAPTURE', restored_sheet)):
                if os.environ.get(variable):
                    Path(os.environ[variable]).write_bytes(data)
        session.gameplay()
        session.save(save)
        transcript.extend(session.raw)
    finally:
        session.close()
    require(not (work / 'scores.dat').exists(), 'scores escaped user state')
    if not custom_save:
        require(not (work / 'game.sav').exists(), 'default save escaped user state')
    else:
        require(not (state / 'explicit.sav').exists(), 'explicit save was relocated')
    for name in ('config', 'data', 'cache', 'runtime', 'tmp'):
        require(not any((root / name).iterdir()), 'unexpected mutable files in ' + name)
    require(save.read_bytes()[:3] == bytes((5, 7, 15)), 'second save invalid')
    if capture and os.environ.get('OMP_RUNTIME_TRANSCRIPT'):
        Path(os.environ['OMP_RUNTIME_TRANSCRIPT']).write_bytes(transcript)
    print('UMORIA: %s %s moved %s -> %s, restored same position and exact character sheet'
          % ('XDG' if explicit else 'HOME fallback',
             'explicit save' if custom_save else 'default save', before, moved))


def main():
    require(len(sys.argv) == 3, 'usage: umoria-pty-runner.py UMORIA SCRATCH')
    require(socket.if_nameindex() == [(1, 'lo')], 'proof needs isolated network namespace')
    executable = str(Path(sys.argv[1]).resolve())
    scratch = Path(sys.argv[2]).resolve()
    exercise(executable, scratch / 'xdg', True, capture=True)
    exercise(executable, scratch / 'home', False)
    exercise(executable, scratch / 'explicit', True, custom_save=True)
    print('UMORIA-SMOKE: actual-movement-save-resume-native-character-ok')


if __name__ == '__main__':
    main()
