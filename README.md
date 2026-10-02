# Taylor's Guix channel

This channel preserves reviewed public GitHub source collections as immutable,
commit-pinned Guix source snapshots, and separately provides installable
packages for reviewed project artifacts, applications, tools, and data
collections.  Source snapshots preserve submodule pointers but do not fetch
submodule contents.

The 2026-08-14 source collection contains 629 unique source packages:

| Collection | Source packages | Disposition |
| --- | ---: | --- |
| Owned `htayj` and `drbeefsupreme` originals | 51 | Nonempty owned public repositories; two empty owned repositories have no commit to package. |
| Lars Brinkhoff historical-computing inventory | 177 | 192 relevant repositories less three empty repositories and 12 canonical PDP-10 redirects or duplicates already represented by the PDP-10 collection. |
| PDP-10 organization inventory | 68 | Relevant original repositories, including nine archived sources retained for preservation; forks are excluded. |
| `htayj` starred public repositories | 333 | Canonical, non-self-hosted source candidates after server/self-host, archive/reference, and overlap/collision exclusions, including 17 additional clear server/self-host removals. |

The starred inventory examined 452 public repositories.  The historical Lars
inventory retains its archived `tv11` source snapshot, but archived material is
source-only and not an issue candidate.  See [`PROJECTS.md`](PROJECTS.md) for
the collection-level scope, exclusions, and overlap handling.

## Runtime evidence corrections

Diabaig issue #675: the package's smoke runner preserves the unmodified
80×34 PTY dungeon redraw and the following movement update.  Capture it with
`GOOCASTLE_RUNTIME_RAW_CAPTURE=/absolute/path/diabaig.raw` when running
`tests/diabaig-smoke.sh`; the variable is a capture destination, not a dependency
on Goocastle.  Replay those bytes in an 80×34 terminal for a faithful screenshot;
the historical 80×24 renderer loses cursor positioning and must not be used for
this proof.  `.goocastle/evidence/issue-675.png` shows the actual post-move dungeon,
one player glyph, controls and live floor/HP status.  On 2026-09-29, the local
build, `--check` reproducibility rebuild, offline lint and network-isolated
save/load smoke passed using OMP tooling.  Runtime output was
`DIABAIG_RUNTIME_OK`; no user game state or installed profile was changed.

## NarwhaRL original-game runtime proof

`narwharl` packages Nathan Hetherington's full original **NarwhaRL 0.0.1**
C++/ncurses game, not a replacement UI or prebuilt executable.  The pinned
[Google Code source archive](https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/narwharl/narwharl-0.0.1.tar.gz)
has SHA256
`393744ba92536f16053c9813680c82634e327947fffc33d1fc9a288c16af0da5`
(Guix base32 `198dmwb8qa4szk8k7z7z8xwk4kk3h866h4wq7h2icvskjax48drr`).
The source headers grant **GPL-2.0-or-later**, not GPL-2.0-only; README's
abbreviated GPL 2.0 label does not narrow that grant.  Bundled Mtrand retains
its BSD-3-Clause notice.  Original documentation, GPL text, the source grant,
Mtrand provenance and `THIRD-PARTY-NOTICES` are installed under
`share/doc/narwharl`.

The source-built game retains its complete original curses interface and all
six definition files, installed immutably under `share/narwharl/defs`.
The launcher creates private writable native state under
`${XDG_STATE_HOME:-$HOME/.local/state}/narwharl`, runs the game there, and
preserves the optional positional numeric random seed.  Saves remain the
original four files below `save/`: `map.m`, `creatures.m`, `items.m` and
`itemknowledge.txt`.  The package corrects RNG initialization order, undefined
Map initialization and missing generator returns.  Actual native restore
initially exposed a SIGILL from `list_merge`, a non-returning mutator wrongly
declared to return a pointer; both declaration and definition now return
`void`.  Strict floor-item comparison then exposed stacked ammunition placed
with stale `(0, 0)` coordinates and lost on load; `Map::put` now maintains the
item's actual floor coordinates.  Remaining upstream return warnings are
visible and unsuppressed.

```sh
guix build -L guix --no-grafts narwharl
make check-narwharl
narwharl
```

On 2026-10-01, local source build, reproducibility rebuild (`--check`), offline
lint and isolated real-game smoke passed for
`/gnu/store/inwvnccc51p46m2yq7xbihmdfrkjifrr-narwharl-0.0.1` using OMP tooling.
`tests/narwharl-smoke.sh` and `tests/narwharl-pty-runner.py` drive six native
80×54 PTY sessions, three each for explicit XDG state and HOME fallback, with
fresh user directories and isolated user, network and PID namespaces.
Both scenarios make the original six skill choices, move the live player
from `(8, 32)` to `(9, 32)` (zero-based native map x/y), inspect inventory and
use the native `S` then `Y` save-and-quit action.  A separate process resumes
the moved position and saves without moving; comparison verifies player
identity/skills, position, inventory, every floor-item record, item knowledge
and dungeon terrain.  A third process resumes, moves to `(10, 32)` and
re-saves all four native files.  Writes remain confined to fresh user state
and the installed output NAR is unchanged.  The runtime marker is
`NARWHARL-SMOKE: actual-map-movement-save-restore-continued-save-ok`.

This is **not a byte-identical whole-save claim**: the native scheduler runs
monsters before the resumed input prompt, so HP/MP, door state and monster
locations can change.  Terrain comparison treats open and closed doors as
the same door feature; floor items are compared as complete record multisets
because native loading reverses list order.  Upstream duplicate-frostbolt,
view-distance, active-state and ordering limitations remain; the proof does
not claim these are fixed or establish campaign-wide correctness.

Set `OMP_RUNTIME_RAW_CAPTURE=/absolute/path` and optionally
`OMP_RUNTIME_TEXT_CAPTURE` and `OMP_RUNTIME_TRANSCRIPT` when running the
smoke to retain the exact resumed gameplay stream, decoded frame and six
complete PTY sessions.  Native save evidence for the final local run is at
`/tmp/narwharl-smoke.YBc5SfMS` (temporary, not a durable fixture).
`.goocastle/evidence/issue-707.png` is the inspected xterm rendering of the
exact restored 80×54 stream, showing Player, Lvl 1, HP 10/10, MP 50/50,
Unarmed and the live map.  It is OMP-produced evidence, not a Goocastle
execution or a campaign playthrough.  No user profile or deployed system
changed; no network OKF update applies to this repository-only addition.

## Pyro original-game runtime proof

`pyro` packages Eric Burgess's complete original **Pyro 0.04a** Python 2
curses game, without porting it or bundling Windows binaries.  The pinned
[source-only release](https://sourceforge.net/projects/pyrogue/files/pyro/0.04a/pyro-0.04a-source.zip/download)
has SHA256
`74dfcbdf5b1624c4b347058b14e88c0f7483152d4c729667e81bc44c1c5f5b7c`
(Guix base32 `0z2vbwf4ri0vx1krcwjc5laq6x0gikl192q58yrw890nbggwppvl`).
The research digest beginning `81451f8d` describes the full Windows release
`pyro-0.04a.zip`, not this source-only archive; all 16 source members are
byte-identical between the two.  The package retains every original member,
the MIT game notice and the zlib-style Philip Chu / Technicat installer
notice.  `setup.py` and `install.nsi` remain inert historical packaging
recipes; the original readme and MIT notice are also installed under
`share/doc/pyro`.

The public launcher runs the unmodified game with packaged Python 2 from
`${XDG_STATE_HOME:-$HOME/.local/state}/pyro`, where its only native persistent
file, `pyro.log`, is writable.  It preserves inherited terminal settings,
including custom terminfo paths, and appends the packaged ncurses terminfo
database as a fallback.  Python bytecode writes and accidental host Python
dependencies are disabled.  **Upstream has no save/load facility**: a new
process starts a new game and rewrites the log, rather than resuming a saved
character.

```sh
guix build -L guix --no-grafts pyro
make check-pyro
pyro
```

On 2026-10-01, local source build, reproducibility rebuild (`--check`), offline
lint and isolated real-game smoke passed for
`/gnu/store/w3rpgbrm2zziv6gvnk7gifvqkfmfm929-pyro-0.04a` using OMP tooling.
`tests/pyro-smoke.sh` and `tests/pyro-smoke.py` drive two separate 80×25 PTY
sessions through the original name/god/race prompts.  Each session verifies
four actual numpad movements by tracking the live `@` position, opens and
returns from inventory and command help, and confirms a clean native quit.
The first launch creates `pyro.log`; a sentinel appended between sessions is
absent after the second launch, proving native log rewrite only, **not
save/load**.  Fresh HOME/XDG directories, isolated user/network/PID
namespaces and a private read-only bind mount confine this proof; the output
NAR hashes remain identical and no other native state file is created.

Set `PYRO_SMOKE_ARTIFACTS=/absolute/new-or-empty/directory` to retain the
report, both complete PTY streams, native logs and exact live capture.
`.goocastle/evidence/issue-713.png` is the inspected xterm rendering of the
final output's exact first-session prefix after the fourth verified move,
before inventory, help or quit.  The real dungeon map and `HP:16/16`, `Lvl:1`
and `DLvl:1` are visible.  This is local gameplay/log-rewrite evidence, not
a campaign playthrough or a Goocastle execution.  No user profile was
installed or changed, nothing was deployed, and no network OKF update
applies to this repository-only addition.

## Umoria original-game runtime proof

`umoria` packages the full original **Umoria 5.7.15** terminal game, the
maintained restoration of Moria, not a replacement game or prebuilt executable.
The source is pinned to
[`624a051dd368d19e86cc0c0908d658a7876809b3`](https://github.com/dungeons-of-moria/umoria/tree/624a051dd368d19e86cc0c0908d658a7876809b3),
the peeled `v5.7.15` release commit, with Guix recursive NAR SHA256 base32
`0hr90nbnvdrpr3j4zv20wgk8mz7w6lwh5ajf6grw8lgp9n810gnn`.
This release is **GPL-3.0-or-later**, superseding issue #706's original GPL-2.0
claim: upstream `AUTHORS` records the 2008 relicense, and
[`CHANGELOG.md`](https://github.com/dungeons-of-moria/umoria/blob/624a051dd368d19e86cc0c0908d658a7876809b3/CHANGELOG.md)
records the 5.7.15 correction of an accidentally reverted license.
Historical GPLv2 and public-domain contributor credits are retained in
`AUTHORS`; the release license, authors, changelog, historical documentation
and `THIRD-PARTY-NOTICES` are installed under `share/doc/umoria`.

The original C++/ncurses game is compiled from source.  Its complete generated
ASCII help, splash and death-screen data and license use absolute immutable
store paths under `share/umoria`.  The launcher redirects only scores and the
default `game.sav` to `${XDG_STATE_HOME:-$HOME/.local/state}/umoria`, initializing
a private writable `scores.dat` from the packaged score file when absent.
It does not change the caller's working directory: explicit save arguments,
including relative paths with subdirectories, and native character-description
export paths retain their upstream meaning.  The private directory creation
uses `umask 077` in a subshell; the game inherits the caller's original umask.
Normal command-line options and the original interactive game remain intact.

```sh
guix build -L guix --no-grafts umoria
make check-umoria
umoria
```

On 2026-10-01, local source build, reproducibility rebuild (`--check`), offline
lint and isolated runtime smoke passed for
`/gnu/store/pxd60ny82krfs1rdw3p08l3znir4nhrp-umoria-5.7.15` using OMP tooling.
`tests/umoria-smoke.sh` drives the real game through
`tests/umoria-pty-runner.py` in fresh HOME/XDG directories and isolated user,
network and PID namespaces.  Three scenarios exercise the XDG default save,
HOME-fallback default save and caller-relative `saves/explicit.sav`.
Each created an original Human Warrior, moved the live player from
`(19, 22)` to `(19, 23)` (zero-based terminal row/column), and used the original
Ctrl-X save action.  The helper waits for and acknowledges the real `-more-`
prompt before waiting for `Rank` and acknowledging the scoreboard; it does not
skip those original UI transitions.  A separate OS process resumed each native
save at the same moved coordinate, exported an exactly identical native
character description (identity, stats, equipment and inventory), and saved
again.  Scores and default saves stayed in user state, custom saves and exports
stayed relative to the caller, and installed-file hashes were unchanged.
The runtime marker was `UMORIA-SMOKE: actual-movement-save-resume-native-character-ok`.

Set `OMP_RUNTIME_RAW_CAPTURE=/absolute/path` when running the smoke to retain
the exact resumed 80×24 gameplay PTY bytes before the second save;
`OMP_RUNTIME_TEXT_CAPTURE`, `OMP_RUNTIME_NATIVE_CAPTURE` and
`OMP_RUNTIME_TRANSCRIPT` optionally retain the decoded frame, original native
character-description export and complete pair of XDG-scenario PTY sessions.
The native export is a character sheet, **not** a native dungeon screenshot.
`.goocastle/evidence/issue-706.png` is the inspected xterm rendering of that
exact resumed raw gameplay capture: Warrior, MHP 19, CHP 19, the live town map
and `Town level` are visible.  It is OMP-produced visual gameplay evidence,
not a Goocastle execution or by itself the persistence proof.
The upstream CMake deprecation warning remains visible and unsuppressed.
This proves the exercised movement and persistence paths, not a full campaign.
No user profile, existing game state or deployed system changed; no OKF catalog
update applies to this repository-only addition.

## Six Two One original-game runtime proof

`six-two-one` packages Jeff Lait's original **Six Two One 2016-03-06**
Seven Day Roguelike release, not a replacement game or prebuilt executable.
The canonical pinned source is
[`sixtwoone7drl.zip`](http://www.zincland.com/7drl/sixtwoone/sixtwoone7drl.zip),
with SHA256 `c3597321994f25a092e2b66cbeee0bf044331af4961bc434ec688770a63d6843`
and Guix base32 `0hv87nk711v8xhsc86wnyhd36i7h1gpbwv5nwa9a09agk4hp6nf3`.
Upstream's HTTPS endpoint has a certificate-name mismatch; the HTTP archive
matched the HTTPS bytes, and the fixed digest pins those contents.
Game source and libtcod 1.5.0 are BSD-3-Clause, the room map and Moby wordlist
are public domain, and the Oxygen Mono glyph image is SIL OFL 1.1.
Upstream notices and `THIRD-PARTY-NOTICES.txt` are installed under
`share/doc/six-two-one`.

The original C++ game and its private static libtcod archive are compiled
from source, using Guix SDL12-compat, libpng and zlib.  Bundled executables,
shared libraries, Windows DLLs, demo fonts and unused music are not installed.
The libtcod font-lifecycle fix calls `TCOD_sys_startup()` before loading the
custom font: without it, static linkage can defer startup until after glyph
loading, resetting ASCII mappings and the first-draw colour cache and causing
real glyph corruption.  The launcher execs `libexec/six-two-one` from a writable
`linux` layout under `${XDG_DATA_HOME:-$HOME/.local/share}/six-two-one`.
Configuration, world definitions and native saves stay there; original text,
glyphs, room map and wordlist are symlinked from the immutable store.  A newly
copied configuration is explicitly made mode 0600, fixing the otherwise
read-only mode inherited from a 0444 store file.  Existing configuration is
preserved.  The launcher accepts no command-line options.

```sh
guix build -L guix --no-grafts six-two-one
make check-six-two-one
six-two-one
```

On 2026-10-01, local source build, reproducibility rebuild (`--check`), offline
lint and the isolated graphical runtime smoke passed for
`/gnu/store/jdc1rr95nv42k1s1iqkg85hgcxkr0flh-six-two-one-2016-03-06`.
`tests/six-two-one-smoke.sh` drives the actual original SDL window in private
Xvfb with fresh HOME/XDG directories and user, mount, network and PID namespaces.
It enters the real Play/welcome screens, opens and dismisses original help,
and sends actual cardinal arrow keys before using the original `Q` quit/save
action.  Native time advanced to 14.  A distinct OS process then consumed
`save/Default.sav` through the original loader, displayed the return welcome
and restored dungeon, and saved again without a turn-taking action.  All six
faces' words, discovered letters and room topology, map depth and clock were
restored; the entire 44,566-byte save was identical in this run.  The runner
asserts native-field restoration; whole-file identity is additional observed
evidence, not a promise for every future run.

The final artifacts in `/tmp/omp-six-two-one-final` include `proof.json`, native
saves and unmodified XWD/PNG window captures.  Set
`SIX_TWO_ONE_SMOKE_ARTIFACTS=/absolute/path` to retain another run's evidence.
Mutable writes remained confined to the launcher's XDG data directory, the
caller's working directory stayed empty, and before/after output NAR hashes
matched.  No user profile or existing game state was changed.
`.goocastle/evidence/issue-720.png` is the exact inspected `played.png` capture
(640×425): Depth 1, discoveries `nnvet`, and `You punch a one.  You kill a one!`
are legible.  It is actual visual gameplay evidence produced with OMP tooling,
not a Goocastle execution or by itself the save/restore proof.  Legacy
`thread.h` return warnings and headless Mesa/XKB warnings remain visible and
unsuppressed.  This proves the exercised gameplay and persistence paths, not
a full campaign or safety of every legacy path.  No deployed system changed;
no OKF catalog update applies to this repository-only addition.

## Atrogue original-game runtime proof

`atrogue` packages the original **Atrogue 0.3.0** GPL-3.0-or-later source,
not a replacement game or prebuilt executable.  The canonical pinned archive is
[`atrogue-0.3.0.tar.gz`](https://downloads.sourceforge.net/project/atrogue/atrogue/atrogue-0.3.0/atrogue-0.3.0.tar.gz),
with SHA256 `279847b357da5a2840c91f304ac0b9007671bb3e154d762367b8e56f37517999`
and verified Guix base32
`16bra4vnzrdqcwipck8m7sxp2xh0p704lc0zr502hnnsayrlg617`.
The package retains `COPYING`, `README`, `INSTALL`, upstream `docu` and the
manual page.  Its serial source build uses GNU89 inline linkage semantics.
The `key2dir` direction string is changed from a fully occupied 32-byte array
to an unsized array that includes its terminating NUL, fixing the `strchr`
overread for non-movement commands rather than suppressing the warning.

The launcher runs the actual ncurses executable from `libexec/atrogue` in
`${XDG_DATA_HOME:-$HOME/.local/share}/atrogue`, with a private write umask.
It changes to that directory and exports `HOME=.` for the game: upstream
rejects HOME paths longer than 50 bytes and would otherwise fall back to the
caller's working directory.  Relative HOME keeps native filename buffers
bounded while supporting long external HOME/XDG paths.  Mutable files are
native text screenshots and an optional message log; logging stays disabled
by default.  **Upstream does not implement dungeon save/load**: quitting ends
the current game, and screenshot/log persistence is not saved-game restoration.

```sh
guix build -L guix --no-grafts atrogue
make check-atrogue
atrogue
```

On 2026-10-01, local source build, reproducibility rebuild (`--check`), offline
lint and the network-isolated runtime smoke passed.  `tests/atrogue-smoke.sh`
drives three actual event-driven 80×24 PTY sessions with isolated HOME/XDG
directories, not preloaded key input or a substitute renderer.  It enters the
real preferences/game screens, sends movement commands and proves a player
coordinate change from upstream's native screenshots, then rests until the
displayed dungeon tick advances.  Two sessions share explicit XDG data state:
the first proves default logging is off, and the second enables logging and
checks that a real in-game version message reaches the private log.  Existing
native screenshot bytes survive the second process without being overwritten.
A third session exercises the HOME fallback with `XDG_DATA_HOME` unset.
All use paths longer than upstream's 50-byte limit; runtime writes stay in the
launcher-owned directory, the caller's working directory stays empty, and
installed file hashes confirm unchanged immutable output.  No user profile
or existing game state was changed.  The success marker is
`ATROGUE-SMOKE: actual-gameplay-native-state-ok; no dungeon save/load upstream`.

`.goocastle/evidence/issue-658.png` shows the inspected actual live dungeon,
including the player `@`, room walls/floor and status `L:a1`, `H:n12/12`,
`T:1`.  This is visual gameplay evidence, not dungeon save/restore proof.
Set `OMP_RUNTIME_RAW_CAPTURE=/absolute/path/atrogue.raw` and
`OMP_RUNTIME_NATIVE_CAPTURE=/absolute/path/atrogue.txt` when running the smoke
to retain the live PTY bytes before quitting and the original game's native
text screenshot, respectively.  Legacy compiler warnings remain visible and
unsuppressed: `-Wpointer-to-int-cast` in `object.c:1969` (`MY_POINTER_TO_INT`)
and `-Wint-to-pointer-cast` in `object.c:2011` (`MY_INT_TO_POINTER`).  The
exercised paths do not establish safety of every legacy pointer/integer path.

## The Sewer Massacre original-game runtime proof

`sewer-massacre` packages the original **The Sewer Massacre 1.0** Common Lisp
source, not a replacement game or prebuilt executable.  The fixed-hash archive
is [`sewers-src.zip`](http://common-lisp.net/project/lifp/sewers-src.zip)
(SHA256 `817be571edb562c0a808455be2019e85b404b684b41e7eb7b0ec6e41e3982066`).
The game is GPL-2.0-only; `license.txt` permits use of `curses.lisp` for any
purpose.  Both `license.txt` and `GNU-GPL` are installed under
`share/doc/sewer-massacre`.  Upstream `readme.txt` and `controls.cfg` have no
explicit redistribution grant and are excluded from the installed package.
Instead of copying `controls.cfg`, the package independently generates the
documented default command bindings as the original `init-controls` fallback:
arrows/numpad move, `5` or `.` waits, `Q` quits, `S` saves, `i` shows inventory,
and `e` shows equipment.  The original controls-file loader remains available.

The launcher loads the normally compiled ASDF `sewers` FASLs with SBCL and
the packaged dependency registry, without ambient Quicklisp or user ASDF
configuration.  Source timestamps are normalized and FASLs compile at stable
store paths.  It does **not** dump a build-time SBCL core: ASDF `build-program`
creates an extra `*-exec.lisp` after timestamp normalization, introducing a
wall-clock mtime as well as nondeterministic live-process contents in the core.
The curses binding uses the absolute packaged `libncurses.so.6`, replacing
upstream's unavailable `libncurses.so.5`.  The generated controls fallback
matches the actual CRLF source expression and checks that it replaced the
upstream error branch; a silently unmatched substitution is not accepted.

Mutable game files live under
`${XDG_STATE_HOME:-$HOME/.local/state}/sewer-massacre`, not the caller's working
directory or immutable store.  With no arguments, `sewer-massacre` still calls
the original `start-game`, retaining the normal interactive curses game and
its random seeding.  Only `--smoke` uses the fixed seed for repeatable evidence.

```sh
guix build -L guix --no-grafts sewer-massacre
make check-sewer-massacre
sewer-massacre
```

On 2026-10-01, local source build, reproducibility rebuild (`--check`), offline
lint and the network-isolated runtime smoke passed.  The smoke runs the
actual original game in an 80×25 curses PTY, but it is **game-model smoke,
not keyboard automation of the interactive loop**.  It calls the original
`test-levels`, `init-controls` and `go-to-level`, then dispatches a real
`move-to` through `do-action` to a passable, unoccupied neighbor.  It preserves
the actor invariant normally provided by `run-stack`: bind `*curmonster*` to
the player and remove that player's queued stack entry before dispatch, so
`cast` can temporarily push the actor without duplicating it.  Coordinate
and cancellation assertions prove that movement occurred.

The smoke obtains a real knife, sets cash to 7, saves `current.sav` through
the original CL-STORE serialization, then mutates cash to 99, HP to 1 and
inventory to empty before loading that save.  It asserts restoration of
position, HP, cash and the knife, including identity between the restored
player and the map-cell actor.  This is saved-object restoration in the same
process, not proof of keyboard save/restore or a second-process load.  The
runner requires `SEWERS_SMOKE_OK`, isolates HOME/XDG state and user, network,
IPC and PID namespaces, checks that the caller's working directory stays
empty, and compares package NAR hashes before and after: the immutable output
is unchanged.  No package was deployed into a user profile.

`.goocastle/evidence/issue-729.png` shows the actual restored map, HP 10/10,
Level 1 and Cash 7.  It comes from the exact 80×25 raw curses stream captured
after `redraw-screen`/`refresh` and **before `endwin`**, not a replacement
renderer or a Goocastle execution.  Set `SEWERS_SMOKE_ARTIFACTS=/absolute/path`
when running `tests/sewer-massacre-smoke.sh` to retain `gameplay.raw` (that
pre-teardown prefix) and `terminal.raw` (the complete session).  The screenshot
is visual evidence, not by itself the save-mutation-restoration proof.
Legacy ASDF/CFFI warnings remain visible and unsuppressed: `cl-store.asd`
defines `cl-store-tests` rather than an ASDF secondary `cl-store/*` system,
CFFI reports deprecated bare struct references, and generic-method
redefinitions are reported.  The exercised paths do not establish safety of
every legacy path.

## The Rougelike! original-game runtime proof

`rouge` packages the original **The Rougelike! 1.61** Linux/source release
from 2007-04-16, not a replacement game or the Windows 1.6 executable.
The fixed-hash source is
[`rouge-src.zip`](https://common-lisp.net/project/lifp/rouge-src.zip)
(SHA256 `e3049336dd733e3d98d8da15a0682e589c6b49b2409dc38f653cf85de9511d7d`).
Upstream `rouge.lisp` is GPL-2.0-or-later and `curses.lisp` is public domain.
The package retains `license.txt`, `GNU-GPL`, `readme.txt` and dependency
`THIRD-PARTY-NOTICES` under `share/doc/rouge`, plus the original default
`share/rouge/controls.cfg`; no external game assets or prebuilt executables
are installed.

The only installed executable, `bin/rouge`, starts the actual curses game
with SBCL and runtime-loads the normally compiled ASDF FASLs.  There is no
dumped SBCL core: avoiding its entropy/timestamp-bearing contents permits
reproducible package output.  The CFFI binding uses the absolute packaged
ncurses library, its `unsigned-int` `chtype` ABI and ncurses `ungetch` rather
than PDCurses' `PDC_ungetch`.  The controls reader dynamically binds
`*package*` to `ROUGELIKE`, so action symbols resolve to the game package
even when loaded through ASDF; read-time evaluation remains disabled.

Custom controls come from `${XDG_CONFIG_HOME:-$HOME/.config}/rouge/controls.cfg`
when present, otherwise from the installed defaults.  High scores live in
`${XDG_STATE_HOME:-$HOME/.local/state}/rouge/hiscore`.  Empty or relative XDG
values use the HOME fallback.  The caller's working directory and immutable
package output are not used for mutable state.  Default `5` waits, `w`
switches the primary weapon between word and banhammer, and `Q` ends the
game and reaches the original name/high-score prompts.  This persistence
is a high-score file, not a saved-game/restore feature.

```sh
guix build -L guix --no-grafts rouge
make check-rouge
rouge
```

On 2026-10-01, local source build, reproducibility rebuild (`--check`), offline
lint and the network-isolated runtime smoke passed.  `tests/rouge-smoke.sh`
drives four real event-driven 80×25 curses PTY sessions under a timeout in
private user, network and PID namespaces, with fresh HOME/XDG directories.
It exercises actual wait and weapon-switch actions, enters two names through
the real quit prompts, independently verifies the score file's 16-octet MD5
checksum and sorted entries, and observes the prior name on a second process's
high-score screen.  Both explicit XDG state and the HOME fallback are exercised.
A user controls override removes `5` and binds wait to `.`, proving that the
original loader honors remapping.  The runner requires `ROUGE_RUNTIME_OK`;
the shell checks installed licenses, read-only files and unchanged output
hashes.  No user profile or existing game state was changed.

`.goocastle/evidence/issue-728.png` shows the actual live dungeon stream,
HP 10/10 and primary weapon word; it is visual evidence, **not score-persistence
proof**.  Set `GOOCASTLE_RUNTIME_RAW_CAPTURE=/absolute/path/rouge.raw` when
running the smoke to retain that exact live PTY prefix before `Q` and curses
teardown.  Legacy upstream Lisp style warnings remain visible and unsuppressed;
the exercised runtime paths do not establish safety of every legacy path.

## FreeLarn original-game runtime proof

`freelarn` preserves the original Apache-2.0-licensed `atsb/freelarn` source
at commit `8cd18cbaef70b9763a9f76cdfa11b78524ebcf5e` (version `0-8cd18cb`),
not a replacement game or stub.  The installed documentation retains upstream
`LICENSE`, `docs/LICENSE`, `README.md`, `docs/HISTORY` and `docs/CHANGELOG`.
The launcher runs the actual C++11/ncurses game from `libexec/freelarn` and
keeps mutable files under `${XDG_STATE_HOME:-$HOME/.local/state}/freelarn`.

```sh
guix build -L guix --no-grafts freelarn
make check-freelarn
```

On 2026-10-01, local build, reproducibility rebuild, offline lint and the
network-isolated runtime smoke passed.
`tests/freelarn-smoke.sh` drives actual 80×24 PTYs through event-driven
welcome/name/status/inventory prompts, new-game save (`S`), restoration in a
second process, and confirmed quit (`Q`, `y`); it does not pipe preloaded
keystrokes or substitute a rendered scene.  Independent disposable sessions
exercise both explicit `XDG_STATE_HOME` and the `$HOME/.local/state` fallback
with `XDG_STATE_HOME` unset.  HOME and the other XDG directories are isolated;
the caller's working directory stays empty, and package-file hashes confirm
that the immutable store is unchanged.  No host profile or user game state
was changed.

Restore proof checks the save's actual 20-byte player-name record for
`OMP Smoke`, observes `Restoring . . .` and the named live HP/SPL/cave-level
status without new-character prompts, verifies that restoration consumes
`fl_savefile.dat`, exercises restored inventory, and confirms that quitting
does not recreate a save.  Nonempty score and message files are also checked.
Runtime output includes `FREELARN_RUNTIME_OK` and the smoke pass message.
`.goocastle/evidence/issue-633.png` shows the actual restored live game
(`OMP Smoke`, 10/10 HP, level 1, Cave Level and map); this screenshot is visual
evidence, not by itself proof of save/restore.  Set
`GOOCASTLE_RUNTIME_RAW_CAPTURE=/absolute/path/freelarn.raw` for the exact raw
PTY prefix ending at the restored screen before inventory/quit/teardown.

Legacy upstream compiler warnings remain visible and unsuppressed:
`-Waddress` for the always-nonnull `potionname`/`scrollname` arrays, and
`-Wmismatched-new-delete` for `free` applied to `operator new` storage in
`FLPlayerSpells.cpp:447`.  Successful smoke does not establish that these
unexercised legacy paths are safe.

## Talmudifier local document rendering

`talmudifier` packages `subalterngames/talmudifier` at commit
`1f23206f7b6c899d6ff56bc4ce3fb610ef5cbe56` as `1.1.0-1.1f23206`, using
the existing fixed-hash source snapshot.  The Python code is MIT/Expat.
Bundled Averia, EB Garamond, Fell French Canon and Fell Flowers fonts carry
SIL OFL 1.1 notices.  FrankRuehlCLM-Medium is GPL-2.0-only, with no embedding
exception; the Culmus Bitstream notice applies to the unshipped David font,
not FrankRuehl.  Mekorot-Rashi is LPPL-licensed.
The package preserves upstream notices and adds the missing Hebrew-font
notices from the fixed-hash frozen TeX Live 2024 `culmus.doc.r68495` archive
(Culmus 1.1 notices) and Mekorot-Fonts 0.03 archive under
`share/doc/talmudifier/fonts`.  The fonts are the pinned upstream assets,
not claimed source-rebuilt fonts.

The obsolete PyHyphen dependency is replaced by Guix Pyphen with its local
`en_US` dictionary and `right=3`, matching its `RIGHTHYPHENMIN`.  Pyphen's
longest-first splits are reversed to preserve upstream's ascending split order
and styled `Word` pairs.  The installed
Python modules and header resource are retained.  The TeX closure includes
`kvoptions`, `kvsetkeys` and `ltxcmds`, fixing the missing dependencies needed
by `lineno`; runtime rendering does not install TeX packages or fetch fonts.

```sh
guix build -L guix --no-grafts talmudifier
make check-talmudifier
talmudifier
```

The no-argument launcher typesets the **fixed bundled example**, not arbitrary
command-line input.  It runs the real local XeLaTeX engine in a disposable
writable workspace and copies only `test_page.pdf` and `test_page.tex` into
the caller's `Output/` directory.  These are freshly generated outputs, not
downloaded PDFs or screenshots.  XeLaTeX failures propagate nonzero status,
print compiler diagnostics and preserve generated logs in a caller-side
`talmudifier-diagnostics-*` directory rather than being swallowed or reported
as success.  Separately, the installed Python `Talmudifier(left, center, right)`
API accepts caller-supplied local text and defaults to the installed recipe,
fonts and absolute store XeLaTeX executable, with disposable TeX state per
call.  Importing the API does not create `Output/`; rendering creates it in
the caller's working directory.  Explicit caller recipes remain supported.

On 2026-10-01, local source build, package reproducibility rebuild (`--check`),
offline lint and two real network-isolated example renders passed.  The smoke
runner uses fresh HOME/XDG/TeX state and fixed `SOURCE_DATE_EPOCH`, validates
PDF/TeX content and font notices, and checks that the immutable package tree
is unchanged.  It also renders independent three-column caller text through
the Python API with `PATH=/nonexistent` and no local recipe/font directories,
checks that the resulting PDF contains that text, and verifies the `Morbi`
hyphenation boundary does not leave a two-character suffix.  Generated example
TeX was byte-identical and normalized rendered PDF text
was equal across both runs; **PDF files differed bytewise**, so this is not a
claim of deterministic PDF output.  `.goocastle/evidence/issue-646.png` is the
actual rendered page: the title “Talmudifier Test Page,” a bold central block
surrounded by columns, and visible Hebrew glyphs, with no obvious clipping at
the captured resolution.  No package was deployed into a user profile.

## DicomToMesh command-line conversion

`dicom2mesh` packages the MIT-licensed upstream revision
`c552b4fd6c6776dab7437f83fb06cb6264f5e831` (version `0.823-0.c552b4f`),
built from source against Guix VTK.  The Qt GUI and optional VTK-DICOM backend
are disabled.  Upstream's GoogleTest FetchContent targets are disabled to keep
the build offline; the package-specific smoke tests real conversion instead.

```sh
guix build -L guix --no-grafts dicom2mesh
make check-dicom2mesh
dicom2mesh -ipng '[slice1.png,slice2.png,slice3.png]' -sxyz 1.0 1.0 1.0 -o mesh.ply
```

On 2026-09-29, the local build, reproducibility rebuild, offline lint and
network-isolated smoke passed.  Three generated grayscale slices produced
48 vertices and 92 triangles with the expected bounds and closed-surface
topology; a missing slice failed without producing a mesh.  HOME/XDG state and
the immutable store remained unchanged.  The real terminal capture is
`.goocastle/evidence/issue-743.png`.  The correct runtime marker includes the
output filename: `Mesh export as ply file: mesh.ply`, not the incomplete marker
in the original research contract.  No medical data or live display was used.
The OMP capture runs the installed command in a disposable working directory
containing those generated slices.  The legacy Goocastle adapter does not stage
them and is not the proof runner; do not put fixtures or mesh outputs in the
repository root to accommodate it.

## Hosted Modus Lisp

`modus` is the x86_64-linux hosted CLI built with SBCL from
`modus-lisp/modus` commit `501f2ee2069e98210627e53ce487f23eabca9032`
(`0.2.0-0.501f2ee`).  It uses upstream's documented `MODUS_NO_JIT=1`
interpreter build, not a bare-metal image.  The executable contains no SBCL
runtime dependency; the installed offline quickload assets include the
Apache-2.0 SHA-1 system alongside Modus's MIT license.

```sh
guix build -L guix --no-grafts modus
make check-modus
modus --noinform --no-userinit --no-sysinit --non-interactive \
  --eval '(format t "= ~D~%" (+ 1 2))'
```

The result is `= 3`.  Bare `--eval '(+ 1 2)'` intentionally prints nothing;
the research contract was corrected to request output through the evaluator's
own `format`, without changing runtime semantics.  On 2026-09-29, local build,
reproducibility rebuild and offline lint passed.  Network-isolated smoke
verified silent evaluation, computed output, true/false assertion exit status,
the REPL, and offline quickload from an unrelated directory using the known
SHA-1 of `abc`.  HOME/XDG and store integrity checks passed.  The real PTY
result is captured in `.goocastle/evidence/issue-752.png`.

## Amstelvar variable fonts

`amstelvar` installs the Roman and Italic v1.001 TTFs from upstream commit
`f44f670affec72a37c69a1bf103bddc044020f49`, with all accompanying OFL notices.
These are the licensed upstream release fonts, **not a claimed source rebuild**.
The issue explicitly permits this fallback: the historical fontmake/ufoLib
toolchain is incompatible with the available Python stack, the build references
missing source directories, and the v1.001 metadata fixes exist only in the
committed fonts.  The complete pinned source remains available through
`googlefonts-amstelvar-source`.

The repository rename to `googlefonts/amstelvar-beta` changed the codeload
archive's root directory and thus its byte hash.  The snapshot hash was updated
after comparing the extracted tree with the same pinned Git revision; no source
revision or font bytes changed.

```sh
guix build -L guix --no-grafts amstelvar
make check-amstelvar
amstelvar-smoke --specimen /tmp/amstelvar.png
```

On 2026-09-29, build, reproducibility rebuild, offline lint and network-isolated
runtime proof passed.  The helper loads both installed fonts, validates their
names and variable axes, and exercises actual outline/advance changes and
FreeType rendering.  `.goocastle/evidence/issue-745.png` shows Roman and Italic
weight/width/optical-size specimens.  Store NAR and read-only checks passed;
no font was installed into a user profile.  Copyright 2016 The Amstelvar Project
Authors; SIL OFL 1.1, with no Reserved Font Name declared.  Notices are under
`share/doc/amstelvar-1.001`.

## Trial by Combat

`trial-by-combat` packages upstream `0.1.0` at commit
`4263df6da017acfe3240288266de4a9400d904a4`.  Its 70 runtime npm archives are
fixed-hash inputs matching the lockfile; development-only Biome is omitted.
Pixi.js 8.2.6 and the OFL-licensed Press Start 2P font are served locally,
without a CDN.  MIT/ISC/BSD dependency notices and the font's OFL grant are
installed under `share/doc/trial-by-combat`.

```sh
guix build -L guix --no-grafts trial-by-combat
make check-trial-by-combat
PORT=4178 trial-by-combat
```

Open `http://localhost:4178/?player=spectate` or `?player=admin`.  Match logging
defaults to `TBC_MATCH_LOG=0`, avoiding writes into the installed source tree.
The upstream server has no provider/model requirement; no service is activated
by installation.

On 2026-09-29, local build, all 129 upstream tests, reproducibility rebuild and
offline lint passed.  Isolated loopback-only runtime proof exercised player
join/ready, a real match turn, spectator WebSocket updates, admin pause/resume,
and clean shutdown.  Chromium rendered both spectator and admin pages using
the vendored renderer/font, with no page errors or failed loads; output NAR
remained unchanged.  `make check-trial-by-combat` explicitly regenerates
`.goocastle/evidence/issue-749.png` via `--evidence`, rather than accepting an
old image.  The final proof uses OMP calls, not the legacy Goocastle adapter.

## XRogue

`xrogue` 8.0.3 is built from Roguelike Restoration Project commit
`544e05aa5ff86884f87569fd5c8810005e8ea6e8` with ncurses.  The installed
`LICENSE.TXT` preserves all incorporated notices, including XRogue/Advanced
Rogue naming restrictions; it is not represented as unqualified BSD-3-Clause.
Save and score files live under `$XDG_DATA_HOME/xrogue`, falling back to
`~/.local/share/xrogue` when XDG_DATA_HOME is absent or relative.

```sh
guix build -L guix --no-grafts xrogue
make check-xrogue
xrogue
xrogue -s
```

The package fixes LP64 reads/writes of the 32-bit save format, missing passwd
entries, unsafe state-path copies and read-only score listing.  State paths
over 244 bytes are rejected instead of truncated.  The research fixture's
score layout was incorrect: records use 10-byte system and 9-byte login fields,
five 16-bit fields and per-field XOR encoding, not raw 80-byte strings.

On 2026-09-29, local build and reproducibility rebuild passed; offline lint
reported only the existing relative patch-resolution warnings.  The isolated
non-root, network-disabled smoke verified seeded score decoding, an unwritable
score file, real gameplay/inventory/save/restore/quit, relative-XDG fallback,
244/245-byte path boundaries and unchanged read-only store output.  The actual
`xrogue -s` terminal screenshot is `.goocastle/evidence/issue-736.png`.

## Keymapper

`keymapper` packages fixed revision `2ddd5cc3957f5faabb5232c13cb0c18f86d933cf`
as `5.6.0-0.2ddd5cc` (two commits after upstream 5.6.0, not an exact release
tag).  It installs `keymapper`, `keymapperd` and `keymapperctl` with explicit
X11, Wayland, D-Bus and tray support.  Licensing is GPL-3.0-only, Boost-1.0 for
the test framework, and the bundled Wayland protocol's HPND grant.

Installation activates nothing.  The autostart file is an inert template at
`share/keymapper/xdg/autostart/keymapper.desktop`, not on XDG_CONFIG_DIRS.
The systemd unit is supplied but not enabled; device access and service/session
activation are explicit administrator/user actions.  No udev rule is installed.

```sh
guix build -L guix --no-grafts keymapper
make check-keymapper
keymapper --check --no-notify --config /path/to/keymapper.conf
```

On 2026-09-29, the local build, 4326 assertions in 201 upstream test cases,
reproducibility rebuild and offline lint passed.  The isolated network/PID
namespace smoke accepts a real valid mapping and rejects an invalid mapping
with a located error, while proving no active autostart or store mutation.
`.goocastle/evidence/issue-747.png` captures the actual checker output.
The research's `keymapperctl --print` proposal was not device-free: it connects
to the client before processing requests and can wait indefinitely.  The
corrected contract uses `keymapper --check --no-notify --config valid.conf`
with a generated temporary fixture and `The configuration is valid` marker;
no runtime semantics were patched to manufacture success.

## Liquid terminal editor

`liquid` packages the EPL-1.0 editor at commit
`045f587b3914485baf85d9eae4f97f968cbfafaa` (`2.1.2-0.045f587`).  It is AOT
compiled with Guix's source-built Clojure 1.12.4 and data.json 2.5.2 on IcedTea,
not downloaded Maven jars.  These replace upstream's older dependency pins;
the upstream suite and real editor smoke cover the used APIs.  Help resources
and the required AOT `user` namespace classes are included.

```sh
guix build -L guix --no-grafts liquid
make check-liquid
liquid
```

On 2026-09-29, build, reproducibility rebuild and offline lint passed.  The
network-disabled private HOME/XDG smoke launched the installed editor in an
80×24 PTY, opened a deterministic Clojure fixture, checked its four rendered
lines, then quit normally and verified terminal restoration, unchanged fixture,
no leaked state and immutable store output.  The unmodified PTY capture,
replayed in a real terminal, is `.goocastle/evidence/issue-753.png`.

## Input Remapper

`input-remapper` packages revision `3b519a18fc39c4d3b4b3074ca96fbcd46585a9ac`
as `2.2.1-0.3b519a1`, under the upstream GPL-3.0-or-later declaration.
Python and GObject typelib paths are wrapped to store inputs; translations
are compiled from source.  D-Bus policy, polkit, systemd and udev integration
files are supplied but not activated.  The autoload desktop entry is an inert
template under `share/input-remapper/xdg/autostart`, not active XDG configuration.
Device permissions and host service integration remain administrator actions;
`pkexec` must come from the host's privileged setup.

```sh
guix build -L guix --no-grafts input-remapper
make check-input-remapper
input-remapper-control --symbol-names
```

On 2026-09-29, local build, reproducibility rebuild and offline lint passed.
The upstream unit suite ran 525 tests with five exclusions: one requires the
system D-Bus and four impose wall-clock timing bounds.  Isolated network-disabled
runtime proof enumerated 641 real symbols including `KEY_A`, without opening
input devices or activating a daemon, and checked empty HOME/XDG state plus
immutable store output.  `.goocastle/evidence/issue-756.png` contains verbatim
symbol output, not a generated success caption.  GUI/device remapping was not
exercised against the live desktop.

## Common Lisp implemented in Emacs Lisp

`emacs-cl` packages `larsbrinkhoff/emacs-cl` revision
`19e950e73a336aad476b0d051819a682863a2eff` as `0-19e950e`, under GPL-2.0-only.
The compatibility patch supports Emacs 30.2 by renaming conflicting local
implementation symbols and adapting evaluator/compiler representations; it
does not override Emacs's global compiler or macroexpansion internals.
The installed library is loaded through its `load-cl.el`, not Emacs's own
deprecated `cl` compatibility library.

```sh
guix build -L guix --no-grafts emacs-cl
make check-emacs-cl
```

On 2026-09-29, local build and reproducibility rebuild passed with the complete
upstream suite: 180 passes and zero evaluation, compilation or execution
failures.  Offline lint had only relative patch-resolution warnings.  The
installed, network-isolated evaluator smoke passed arithmetic, functions,
keyword arguments, loops, integer parsing/formatting, bignums, compilation,
closures, mixed nested backquotes, condition handling and bounded debugger EOF
exit; store files remained unchanged/read-only.  Upstream obsolete-alias
warnings remain visible, not suppressed.  `.goocastle/evidence/issue-606.png`
shows the actual result `(42)` of defining and calling a Common Lisp function.

## Org popup posframes

`emacs-org-popup-posframe` packages the existing recipe for
`A7R7/org-popup-posframe` at revision
`d39cb7c2c9a996689b0d6519695eed3d807c0c85` (`0.0.1-0.d39cb7c`), covering
source issue #62 and runtime issue #619.  The GPL-3.0-or-later Elisp library
propagates `emacs-posframe`; Org is supplied by Emacs.  The upstream license is
installed under `share/doc/emacs-org-popup-posframe`; source screenshots are
not installed.  Installation does not enable the global minor mode or modify
the user's Emacs configuration.

```sh
guix build -L guix --no-grafts emacs-org-popup-posframe
make check-emacs-org-popup-posframe
```

In a graphical Emacs session, load `org-popup-posframe` and explicitly enable
`org-popup-posframe-mode` to display supported Org popup buffers as child
frames.  Batch/non-graphical posframe display is intentionally a no-op.

On 2026-10-01, the local build, `--check` reproducibility rebuild and offline
lint passed.  The revised smoke passed batch mode enable/disable, rendered the
real `org-capture` menu in a child frame, selected a template and finalized
its Org content, and exercised posframe show/hide/delete.  It used private
HOME/XDG state and private Xvfb sockets in an isolated namespace; host Emacs
configuration was not touched and the output NAR remained unchanged.
`.goocastle/evidence/issue-619.png` was visually inspected and shows the live
menu's `s Offline capture` and `x Alternate` options plus the `Template key`
prompt; it is menu-rendering evidence, not an image of capture finalization.
The existing upstream `original-set-window-buffer` byte-compilation warning
remains disclosed, not suppressed.

## You Only Live Once

`liveonce` 005 builds the original game's curses port from the pinned Zincland
source archive.  Prebuilt programs, DLLs, the SDL port and the bitmap font with
unclear licensing are excluded.  The upstream BSD-style/MT19937 notices and
public-domain map declaration are preserved.  Immutable game data stays in
the store; only `valley.sav` is written beneath `$XDG_DATA_HOME/liveonce`
(fallback `~/.local/share/liveonce`).

```sh
guix build -L guix --no-grafts liveonce
make check-liveonce
liveonce
```

Local build and reproducibility rebuild passed on 2026-09-29; offline lint
reported only relative patch-resolution warnings.  A non-root, network-isolated
two-session PTY proof creates a save, restores and consumes it, then saves again,
checks confinement and unchanged store NAR, and prints `Done.`.  Evidence
`.goocastle/evidence/issue-737.png` is a real 80×30 terminal replay of the
loaded-game frame before quitting, not the blank alternate-screen restoration.
The exported raw stream is a byte-identical prefix of the complete successful
session.  No user save or installed profile is touched.

## xNetHack

`xnethack` 10.0 builds the TTY game from upstream commit
`6eef39403f16f65e13f5d57242ee8d036307687a`, statically linked with Guix's Lua
5.4.8.  The NGPL and Lua MIT notices are installed.  The release `linux.500`
build hint replaces the research's debug-only hint; no PDCurses or unneeded
submodules are fetched.  Immutable data lives in `share/xnethack`, while save,
lock and score files use `$XDG_STATE_HOME/xnethack` (fallback
`~/.local/state/xnethack`).  Playground paths over 128 bytes fail before writes.

```sh
guix build -L guix --no-grafts xnethack
make check-xnethack
xnethack
```

Local build, reproducibility rebuild and offline lint passed on 2026-09-29.
The network-isolated PTY smoke moves a configured character until the turn
counter advances, saves, restores the same turn, and quits cleanly.  It also
checks UTF-8 byte-length boundaries and unchanged read-only store contents.
Runtime proof exposed a real game-end crash when dump-log paths are unset;
the package guards the nullable paths before calling the upstream nonnull
formatter instead of enabling writes to `/tmp`.  The actual restored dungeon
and `T:2` status appear in `.goocastle/evidence/issue-735.png`.  No host game
state or installed profile changed.

## Qiling binary emulation framework

`qiling` 1.4.10 packages revision `da210f0757f3581de7e607b2b826b26eaa5aef66`
with the `qltool` CLI and its Python dependency closure, including Unicorn
2.1.3.  The pinned README explicitly grants GPL-2.0-or-later, correcting the
research brief's GPL-2.0-only classification.  No unlicensed rootfs submodule,
firmware or prebuilt example guest is included.  The package assembles its own
freestanding x86-64 ELF fixture from installed assembly source; this recipe
currently supports x86_64-linux hosts because it uses native x86-64 binutils.

```sh
guix build -L guix --no-grafts qiling
make check-qiling
qiling-smoke
```

Local build, reproducibility rebuild and offline lint passed on 2026-09-29.
Thirteen upstream tests cover CPU models and real inline shellcode emulation
on x86, x86-64, MIPS, ARM, Thumb and ARM64.  Tests requiring the excluded rootfs
are not claimed.  The isolated installed `qiling-smoke` invokes real `qltool`
on the source-built guest and emits exactly `Hello, World!` on stdout, with
write/exit emulation traces on stderr.  Store-integrity and no-state-leak checks
passed.  `.goocastle/evidence/issue-755.png` captures that actual execution;
Qiling is an emulator, not a security sandbox for arbitrary untrusted samples.

## AI Code Interface for Emacs

`ai-code-interface-el` 1.930 packages Apache-2.0 source revision
`9d046a302c2902fa819d988309078361a6aef9fe`, including runtime prompts and
snippets.  The launcher uses explicit store load paths for Emacs and Magit
dependencies.  Provider CLIs, credentials and model access remain user-supplied;
installation starts no backend.

```sh
guix build -L guix --no-grafts ai-code-interface-el
make check-ai-code-interface-el
```

On 2026-09-30, build, reproducibility rebuild and offline lint passed.  The
upstream ERT suite ran 1342 tests: 1329 expected results, zero unexpected,
and 13 upstream skips for optional integrations.  Running it exposed a real
Guix incompatibility in the generated editor helper's `/bin/sh` shebang;
the package now uses the store shell rather than skipping those tests.
The bounded, network/PID-isolated smoke loads the installed interface with an
empty PATH, verifies its menu and backend selection, and checks no leaked
state or output mutation.  `.goocastle/evidence/issue-647.png` captures the
actual `AI_CODE_RUNTIME_OK` output, including the expected with-editor warning
that an empty PATH provides no Emacsclient.  Provider sessions are not claimed
as tested; no user profile changed.

## BootRogue source and proof refresh

BootRogue remains pinned to `118e1cb7818fdd152b4f008548408ed0ed45e06f`, now
fetched as a fixed Git tree instead of an autogenerated archive.  On 2026-09-30,
its source build, reproducibility rebuild and offline lint passed.  The existing
QEMU guest smoke now uses direct coreutils timeout and network/PID namespaces,
not a Goocastle executor.  It boots the installed 512-byte image, sends arrow
keys, captures a real VGA screendump, quits, and verifies isolated state and
unchanged store contents.  `.goocastle/evidence/issue-662.png` was regenerated
from that framebuffer.  The tiny boot-sector game's sparse symbols and HUD
are expected; the execution proof comes from QEMU interaction, not image text.

## ChatGPT.el

`chatgpt-el` packages the GPL-3.0 client at revision
`51c658aa40a106a4ee3afe4376f5ed3d6024c8a9` (`0.2-0.51c658a`) with Polymode.
It is an Emacs frontend for a separately supplied `lwe` executable, not the
OpenAI desktop application.  CLI discovery uses `executable-find`, avoiding
upstream's broken shell-error default when `which` is absent.

`make check-chatgpt-el` tests the installed client in a fresh network-disabled
environment: missing-key rejection, slash completion, a real subprocess pipe,
and `cg-query` sending a multiline request.  The local fixture computes 43 from
the supplied expression and the client receives a fenced response.  This is
client/transport proof, **not a provider/model response claim**.  Source build,
reproducibility rebuild and offline lint passed on 2026-09-30; upstream Emacs
and Polymode warnings remain visible.  `.goocastle/evidence/issue-642.png`
shows the actual captured client buffer.  Real provider use requires the user's
external CLI and credentials; no profile or account was changed.

## ECA Emacs client

`eca-emacs` packages Apache-2.0 revision
`f1455057000612a8ef5f9ba0b4eebf3368b0f0fd` as `0.0.1-0.f145505`.
It installs the Elisp client only: provide `eca` on PATH or set
`eca-custom-command`.  The package removes automatic server downloading,
updating and removal; a missing server produces an explicit install/provide
error.  Opening an ordinary chat does not synchronously probe server versions.

On 2026-09-30, source build, reproducibility rebuild, 417 Buttercup specs and
offline lint passed (relative patch-path warnings remain).  `make check-eca-emacs`
uses a private local JSON-RPC fixture process, not a provider: real client
initialize/chat/completion requests, controlled error replies, malformed frames,
early exit, shutdown and process cleanup are asserted.  Network access and
download commands are denied, HOME/XDG are temporary, and output integrity is
checked.  Removed downloader specs are replaced by custom/PATH/missing-server
coverage rather than excluding the entire process test file.

`.goocastle/evidence/issue-640.png` shows the actual Emacs buffers and handled
`FAKE_COMPLETION_ERROR`.  Its unchanged terminal-stream prefix ends before
terminal restoration.  This proves client error handling, not model inference.
The runtime is Emacs loading the installed library; no nonexistent package
executable or legacy capture-adapter compatibility is claimed.

## UltraRogue

`urogue` 1.0.8 builds pinned revision
`0cebe8a805d64e9593fd4e84790e9c0b2353f169` from source with ncurses.
The complete custom redistribution license is installed, including attribution,
advertising and derived-name conditions; it is not mislabeled as plain BSD.
The wrapper confines saves and scores to `$XDG_DATA_HOME/urogue` (fallback
`~/.local/share/urogue`) and rejects state paths exceeding 68 bytes before
creating directories, including under UTF-8 locales.

On 2026-09-30, source build, reproducibility rebuild and offline lint passed
(relative patch-resolution warnings remain).  `make check-urogue` exercises
real character creation, a turn-consuming food action, inventory, save,
restore and score recording in a private non-root network/PID namespace.
The seeded read-only score file rejects writes; valid/overlong state paths and
UTF-8 byte limits are checked.  Output NAR and read-only checks pass.
`.goocastle/evidence/issue-732.png` shows actual terminal gameplay; the image
alone is not the evidence for save/restore, which is asserted by the PTY runner.

## Letter Hunt

`letter-hunt` 002 builds the pinned `letterhunt002.tar.gz` source archive
(SHA-256 `c53398658812dc6aa9300748f5fa0f89665d692ee15dafa8af464ff08a6f5059`)
as the curses port only.  The source snippet removes the prebuilt Linux and
Windows programs and libraries, the unclearly licensed bitmap fonts, and the
SDL port; the installed output contains no SDL references.  `LICENSE.TXT`
(the game's BSD-style notice, the complete MT19937 notice, and the
public-domain dedications of the maps and word list) and `README.TXT` are
installed, and the unmodified upstream data files are checked by hash.  The
launcher keeps the save and high scores in `$XDG_STATE_HOME/letter-hunt`
(fallback `~/.local/state/letter-hunt`), never in the store.

On 2026-09-30, source build, reproducibility rebuild (`--check`) and offline
lint passed (relative patch-resolution warnings remain).
`make check-letter-hunt` runs `letter-hunt --guix-smoke` from `PATH` in a
fresh HOME/XDG tree inside an unprivileged network namespace and requires
`LETTER_HUNT_RUNTIME_OK`.  The first PTY session takes a turn, shows the
character sheet and saves; the second, reaching the same directory through
the HOME fallback, must consume the save (the game unlinks it after loading,
before drawing the first screen), shows the character sheet and saves again.
The re-save must match the first byte-for-byte through the avatar, score,
captured words, letter buffer and dungeon map header.  The output NAR stays
unchanged, is read-only, and receives no save or score files.
`.goocastle/evidence/issue-703.png` shows the actual restored game's maze,
`Shields:` status line and character sheet; the image alone is not the
save/restore evidence, which is asserted by the PTY runner.

## Pyrosimple

`pyrosimple` builds pinned upstream revision
`d24655a708059d322633e361e2e204983e51f491` (16 commits after v2.14.2) with
its missing Python helpers (`bencode.py`, `parsimonious`, `lockfile`), each
installing its exact upstream notice; the complete GPLv3 `COPYING` is
installed.  pyrotorque needs the lockfile-backed PID API (`is_locked`,
`read_pid`), which Guix's filelock-patched `python-daemon` lacks, so a private
variant uses the unpatched upstream 3.1.2 release with its declared `lockfile`
dependency.  A build phase passes mktor's `--no-date` through to
`Metafile.from_path`, so the option really omits `creation date`.  A
`pyrosimple` command runs `rtcontrol`.

On 2026-09-30, the build with its test suite (374 passed; the 4 live rTorrent
tests skipped), reproducibility rebuild (`--check`) and offline lint passed.
`make check-pyrosimple` loads all eight commands and, with an empty `PATH`, a
fresh HOME/XDG tree and networking unshared, uses `mktor` to create the same
two-file private metainfo twice byte-for-byte (pinned digest), checks its
pieces with an independent decoder, verifies good and corrupted payloads with
`lstor --check-data`, and edits the comment with `chtor` without changing the
info hash.  `pyrotorque --status` reports no daemon.  The output stays
unchanged and read-only.  `.goocastle/evidence/issue-643.png` shows the actual
`lstor` listing of that metainfo.

This is a local-only proof: no rTorrent instance, XML-RPC endpoint, seedbox or
running pyrotorque daemon was exercised, and nothing was deployed.

## Hydra Slayer

`hydra-slayer` 18.3 builds the standalone ncurses console game from pinned
NotEye revision `55bb69d716a9fb269c6364f9df89d4bc260cb1a1`, without NotEye's
graphical frontend or assets, and installs the complete GPL notice.  The
launcher keeps the game's files in `$XDG_STATE_HOME/hydra-slayer` (fallback
`~/.local/state/hydra-slayer`).

On 2026-09-30, source build, reproducibility rebuild and offline lint passed.
`make check-hydra-slayer` runs `hydra --guix-smoke` directly under a
90-second `timeout` and `unshare` with private user, network and PID
namespaces.  The full lifecycle is asserted: the first PTY session starts a new
game, takes a turn and must report and create the save; the second must load
it (`Welcome back to Hydra Slayer!`) and quit without recording a score.  All
state stays in the disposable XDG tree, and the output NAR is unchanged and
read-only.  `.goocastle/evidence/issue-697.png` shows a genuine
alternate-screen prefix of the loaded session, up to its first leave of the
alternate screen; it supersedes the earlier mixed-screen image.

## Save Scummer

`savescummer` 002 builds the pinned `savescummer002.tar.gz` source archive
(SHA-256 `793cc9cc9d486a22709714ba20d73826656083f829e2c5f2d6d3aa4074bf0ace`)
as the curses port only.  The source snippet removes the prebuilt Linux,
Windows and Mac programs, the bundled DLLs and PDCurses libraries, the bitmap
fonts and the SDL and Windows ports; the installed output contains no SDL
references.  `LICENSE.TXT` (BSD-style terms for the sources and text, the
public-domain room pieces, and the complete MT19937 notice) and `README.TXT`
are installed, and the unmodified upstream data files are checked by hash.
Nine sources keep a stale "PROPRIETARY INFORMATION" template header; the
archive-wide `LICENSE.TXT` by the same author covers them.  The launcher keeps
the save and high scores in `$XDG_STATE_HOME/savescummer` (fallback
`~/.local/state/savescummer`), never in the store.

On 2026-09-30, source build, reproducibility rebuild (`--check`) and offline
lint passed (relative patch-resolution warnings remain).  The build shows an
upstream compiler warning that `getAvatarMap` can reach its end without
returning a value; it is disclosed here, not suppressed.
`make check-savescummer` runs `savescummer --smoke` from `PATH` in a fresh
HOME/XDG tree inside an unprivileged network namespace and requires
`SAVESCUMMER_RUNTIME_OK`.  The first PTY session accepts a character, advances
turns, writes backup slot 0, advances again, restores that slot, shows the
character sheet and saves.  A new process, reaching the same directory through
the HOME fallback, must load and consume the save (`Welcome back to Save
Scummer!`), show the character sheet and save again.  The re-save must match
the first byte-for-byte through the score, avatar, HP distribution and dungeon
map header.  The output NAR stays unchanged, is read-only, and receives no
save or score files.  `.goocastle/evidence/issue-718.png` shows the restored
game's welcome-back message and character sheet; the image alone is
not the save/restore evidence, which is asserted by the PTY runner.

## RapidBrogue

`rapidbrogue` 1.4.0 builds the pinned upstream commit
`02e6715fd81c4c9da1546943700da7b2b3ed482a`, restoring the original SDL
frontend with text, tiles and hybrid graphics; `rapidbrogue -t` selects the
optional ncurses frontend.  The complete upstream tile atlas (including
embedded glyphs), precomputed tile cache and icon are installed.  Engine
code is AGPL-3.0-or-later, legacy platform code is GPL-3.0-or-later, and the
tile atlas and derived cache are CC BY-SA 4.0.  Full license texts, asset
notices and source-header attributions are installed under
`share/doc/rapidbrogue`.  The launcher keeps the editable keymap, saves,
recordings, high scores and native screenshots in
`$XDG_STATE_HOME/rapidbrogue` (fallback `~/.local/state/rapidbrogue`), while
using immutable packaged resources.  The fake package-owned smoke path
and the issue-714 legacy contract are retired.

On 2026-10-01, source build, reproducibility rebuild (`--check`), offline
lint and isolated native save/resume proof passed for both frontends.
`make check-rapidbrogue` resolves the output with `$(GUIX) build -L guix
--no-grafts rapidbrogue`, allocates a fresh evidence directory and passes
both required arguments to `tests/rapidbrogue-smoke.sh OUTPUT EVIDENCE_DIR`.
The proof uses private user, mount, network and PID namespaces, fresh
HOME/XDG state, a private Xvfb display and SDL's software renderer.  Each
frontend starts seed 1 at depth 1, takes real rest turns, saves at turn 3,
restores in a second process and saves at turn 5.  Native save decoding
asserts the preserved event prefix, saved-game-loaded marker and two live
rest events after restoration; the package output NAR remains unchanged.

`.goocastle/evidence/issue-714.png` is the exact native hybrid capture,
inspected with actual graphical tiles, the switched-to-hybrid message,
depth 1 and `Str: 12  Armor: 3`; a restored original-text frame was also
inspected.  Screenshots are visual evidence, not the save/resume assertion.
The build log retains unsuppressed upstream `-Warray-parameter`,
`-Wstringop-overread`, `-Wstringop-overflow` and `-Wstringop-truncation`
warnings, plus Guile's imported `delete` binding warning.  Full-campaign
play, GPU acceleration and desktop window-manager integration were not
verified.  Parent issue 480 remains open; child issue 714 is historically
closed, and its historical proof is not accepted as current verification.
This is repository/store verification, not a profile or OKF deployment.

## Avanor

`avanor` remains the existing 0.5.8 package built from the SourceForge
source release with ncurses; its saves, recipes and high scores stay in
`$XDG_STATE_HOME/.avanor`.  On 2026-09-30, a refreshed source build,
reproducibility rebuild, offline lint and runtime check passed; the build
still shows legacy `-Wwrite-strings` warnings from upstream code.
`make check-avanor` now drives the game with an event-driven PTY runner in
private user, PID and network namespaces: every key is sent only after the
screen that consumes it is drawn.  The first session creates the character
`smoke`, opens the manual and inventory, passes a turn, saves and quits; the
second restores the game and must show the restored hero's named status
line.  `.goocastle/evidence/issue-659.png` renders the exact raw byte prefix
of that restore session, ending before the quit prompt and before curses
leaves the alternate screen.

## Super-Rogue

`srogue` 9.0 builds Super-Rogue from the pinned Roguelike Gallery
`early-roguelike-rel2021.03-src.tgz` collection release; the source snippet
keeps only its `srogue/` tree.  The custom `LICENSE.TXT` is installed and
labelled as such: BSD-style terms plus Super-Rogue endorsement and naming
conditions, with the complete notices for the Rogue 3.6, save/restore and
FreeSec portions; it is not labelled as plain BSD.  The game is built
without setgid or host-wide score, log and save files.  The launcher keeps
saves and the personal score list in `$XDG_DATA_HOME/srogue` (fallback
`~/.local/share/srogue`) and rejects state directories longer than 68 bytes
before creating anything, counting bytes under UTF-8 locales.  The patch
also bounds the game's own HOME, message and save-path buffers, and reads
saved long values as 4-byte integers so restored games on LP64 systems no
longer pick up garbage upper halves.

On 2026-09-30, source build, reproducibility rebuild and offline lint passed
(relative patch-resolution warnings remain).  `make check-srogue` runs
`srogue --guix-smoke` from `PATH` in a fresh HOME/XDG tree inside an
unprivileged network namespace: the first PTY session eats starting food,
which takes a turn, and saves; the second, through the HOME fallback,
restores and consumes the save, and its pack must match the first
session's.  A second non-root runner lists and preserves a read-only seeded
score file, decodes the recorded score of a real game, ignores a relative
`XDG_DATA_HOME`, and checks the 68-byte and UTF-8 path bounds of both the
launcher and the game.  The output NAR is unchanged and receives no save or
score files.  `.goocastle/evidence/issue-725.png` shows actual gameplay: the
restored game's map with `Hp: 9(12)`; the pack comparison is asserted by
the PTY runner, not shown in the image.

## Bcrawl

`bcrawl` 1.42.1 builds the pinned `bcrawl-1.42.1` tag
(`d9800d219b5e0ab840c8065e44f875fa19dd63ff`) as a console-only game, without
SDL, fonts or tiles.  The GPL `LICENSE`, `CREDITS.txt` and the bundled
component notices are installed.  Game state lives in
`$XDG_DATA_HOME/bcrawl` (fallback `~/.local/share/bcrawl`).

On 2026-09-30, source build, reproducibility rebuild (`--check`), offline
lint and runtime check passed.  The successful build log still shows
existing upstream compiler warnings and the install step's `cc`/`git`
probes.  `make check-bcrawl` runs `bcrawl --smoke` directly under `timeout`
and `unshare` with private user, network and PID namespaces; no Node-based
executor is involved.  Two real PTY sessions run: the first creates a seeded
Human Fighter, advances the game clock three turns, saves and exits; the
second restores the character, must show the same game clock, then takes
another turn and saves again.  The output NAR is unchanged and read-only.
`.goocastle/evidence/issue-660.png` is an independent xterm rendering of the
restore session that was inspected: it shows the welcome-back message,
`Time: 3.0`, `Health: 18/18` and the map.

## LineRogue

`linerogue` 2 builds Chris Morris's pinned `linerogue2-src.tgz` source
release (an unmodified Internet Archive capture of the author's archive)
with the channel's private, source-built Kaya 0.4.4 compiler, using Kaya's
seed mode so the build is reproducible.  The GPL-2.0-or-later `COPYING` and
`GPL-2`, the PCRE notice and the notices of the statically linked Kaya
runtime are installed.  The launcher keeps the high-score table in
`$XDG_DATA_HOME/linerogue` (fallback `~/.local/share/linerogue`); nothing is
setuid or setgid.

On 2026-09-30, source build, reproducibility rebuild (`--check`) and offline
lint passed cleanly.  The runtime check passed after the test stopped
searching for literal map rows, which curses splits with colour escapes, and
searched for the HUD, player, trail and wall glyphs instead.
`make check-linerogue` runs `linerogue --smoke` from `PATH` in a fresh
HOME/XDG tree under a timeout and private user, network and PID namespaces.
The first PTY session steers the bike through at least ten verified moves,
each checked against the drawn position, then reverses into its own trail
to crash and declines another game; the high-score file it writes must
decode to the table it displayed.  Because such a short game usually scores
0 and leaves the default table unchanged, the test then replaces only the
five integer scores in that task-owned, game-written file with the distinct
sentinel table 9105, 7304, 5203, 3102, 1001, keeping the executable's
marshalling header and layout.  This is an explicit fixture, not naturally
earned scores.  A second process must load it, display the expected top five
on its Game Over screen and rewrite the file with that table.  Its own
low score does not prove that a new score is inserted into the top five.  No
other files are written and the output NAR is unchanged.
`.goocastle/evidence/issue-704.png` shows actual gameplay: the map with the
player and its trail, and the `Power: 3` / `Score: 0` HUD.  The high-score
persistence is asserted by the PTY runner, not shown in the image.

## Bloatcrawl 2

`bloatcrawl2` 2.2.0 builds the Bloatcrawl 2.2.0 tag (published 2020-01-01)
from `https://github.com/Hellmonk/bloatcrawl2`, pinned to commit
`ff89137ce52d26b891517517c0aec9013ed8bea5`, as a console-only build (empty
`TILES`, so no SDL, fonts, sound or tile sources).  Two build patches adapt
the release to current tools: `util/species-gen.py` uses Python 3.11's
`collections.abc.MutableMapping`, and `ui.cc` includes `<cwctype>` for
current libstdc++.  The upstream test suite is not run.  The GPL `LICENSE`,
`CREDITS.txt` and the bundled component notices (CC0, LGPL, libpng, Lua,
PCRE, Worley and the public-domain RLTiles notice) are installed under
`share/doc/bloatcrawl2`.  The launcher keeps all game state in
`$XDG_DATA_HOME/bloatcrawl2` (fallback `~/.local/share/bloatcrawl2`) as
`CRAWL_DIR`, and points `HOME` there so the game's legacy `.crawl`
directory stays in that tree too.

On 2026-09-30, source build, reproducibility rebuild (`--check`), offline
lint and the runtime check passed.  The successful build log still shows
existing upstream compiler and Yacc warnings and the install step's `cc` and
`git` probes; neither stopped the build.
`make check-bloatcrawl2` runs `bloatcrawl2 --smoke` directly under a timeout
with private user, network and PID namespaces, a fresh HOME/XDG tree and
`PATH` limited to the package output.  The PTY runner starts a seeded Human
Fighter, answers the real weapon-choice and Game Modifiers prompts, requires
the new-character welcome, then waits three turns, each of which must advance
the HUD `Time:` clock.  It then quits cleanly through the abandon
confirmation, death pager, inventory and goodbye screens with exit status 0.
The caller's directories stay empty and the output NAR is unchanged and
read-only.  The proof is a seeded `-no-save` session, not proof of normal
scoring or of saving and restoring a game.
`.goocastle/evidence/issue-661.png` shows the actual dungeon map with
`Health: 18/18` and `Time: 3.0`; its HUD also visibly includes `*WIZARD*`.

## Ighalsk

`ighalsk` 0.1.16 runs the original Python 2/Tk application from the fixed
SourceForge source release (embedded SVN metadata identifies
`release_0_1_16`, revision 380).  It is a graphical Tk game, not a curses
port.  The build runs all 644 upstream tests before applying the state/data
integration patch, and makes upstream test failures fatal rather than relying
on `TestAll.py`'s exit status.  Source headers and `COPYING` grant
GPL-3.0-or-later despite SourceForge's GPLv2 metadata.  `COPYING`, `CREDITS`
and the upstream documentation are installed; embedded SVN state and the
unlicensed Windows-only `igh2exe.py` helper are excluded.

The launcher keeps saves, scores and editor output under
`$XDG_DATA_HOME/ighalsk` (fallback `~/.local/share/ighalsk`), while dictionaries,
quests and other game data remain immutable in the store.  The original level
and monster editors are available through `--level-editor` and
`--monster-editor`.  Saves retain upstream's legacy Python pickle format:
**loading an untrusted save is unsafe and can execute arbitrary Python code**.
The state-directory integration does not make this format safe.

On 2026-10-01, local source build, reproducibility rebuild (`--check`), offline
lint and actual Tk runtime proof passed.  `make check-ighalsk` launches
`ighalsk --guix-smoke` with a private Xvfb and fresh HOME/XDG directories under
a timeout in private user, mount, network, IPC and PID namespaces; X sockets
are private and Xvfb has no TCP listener.  The real UI creates the Mighty
`GuixHero`, accepts a palace quest, enters dungeon level one, moves to a
traversable adjacent square, and saves.  A fresh Tk session uses the ordinary
load menu.  The runner compares the live pre-save, serialized and loaded
compressed hero/quest/level state, requires the load to consume the save, and
checks that the output NAR is unchanged and store files stay read-only.
The same real Tk proof edits a monster's HP, saves `GuixHerd` and reloads the
changed HP while requiring the shipped monster dictionary to remain unchanged.
It also loads the shipped TOLD level template, edits and saves a user template
under the same name, and reloads its changed geometry while requiring the
shipped template to remain unchanged.  The package's `--guix-smoke` mode runs
these checks on a supplied display even without the optional capture variables;
it does not provision its own display.  The outer smoke passed both captured
and no-capture runs.
`.goocastle/evidence/issue-698.png` is a native capture of the restored Tk
window, showing the hero with `HP = 19/19`, `Tunnels of Lost Dreams` and
`Depth = 1`; it is not a rendered terminal approximation.

## A Quest Too Far

`aquesttoofar` 1.3 builds Geoffrey White's original C++/SDL game and bundled
CharLib from the fixed `AQuestTooFar1.3-091010.zip` upstream source release.
The measured archive SHA-256 is
`377b99a0b59b85c966c85b7f0dc287db09293db39a157c7af1889fadddc79b9c`, whose
correct Guix base32 encoding is
`174vqzfsv7w8y5x7q5csncyjj2fvhz10szsvr1kck1cvnnh9jyrp`; the preliminary
research encoding was incorrect.  Upstream `readme.txt` grants
GPL-3.0-or-later for the game and its bitmap assets; it and the complete
`gpl-3.0.txt` are installed.  Bundled Windows executables and DLLs are removed,
and SDL is supplied by Guix's SDL 1.2 compatibility input.  The build places
libraries after objects in the link command, selects the C++ compiler and
disables parallel make to avoid upstream's Build-directory prerequisite race.
No gameplay source changes are needed and upstream provides no test target.

On 2026-10-01, local source build, reproducibility rebuild (`--check`), offline
lint and actual SDL runtime proof passed.  `make check-aquesttoofar` runs the
installed launcher under a timeout with fresh HOME/XDG directories and private
user, mount, network and PID namespaces.  A private Xvfb uses private X
sockets and no TCP listener; the runner sends actual X11 keys to the game.
It enters from the intro, opens help and returns to the same dungeon/HUD,
then rests three times.  Each rest must change the rendered decline-counter
field while preserving the decline label and dungeon-level HUD.  The runner
recognizes the real highlighted SPACE prompt and acknowledges queued messages
before the next rest; it does not count ignored keys as turns.  Native X11
window dumps and unmodified PNGs supply the visual proof.
`.goocastle/evidence/issue-649.png` shows the actual dungeon with `hp:50/50`
and `dlvl:1`.  Caller state stays empty and the output NAR remains unchanged
and read-only.  This game has no save/configuration writes, and the help-return
check is **not** a claim of saved-game restoration.

Both packages were verified locally and published to the Forgejo channel on
2026-10-01 in signed commit `57a81493bca4f3a24e47eb3feab98f185e86dbc1`, after
repair of the remote's corrupt Git objects.  This is a channel-publication
receipt, not a claim that either package was deployed in a host profile.

## Kbredir keyboard-event tools

`kbredir` 0.9 builds the GPL-2.0-only source at revision
`9b82cf66a60842a97a5b6ffac219e59bcd9f069a`, using Guix X11/XTEST libraries
and Linux headers.  It installs `read_vt220`, `read_linux_console`, `read_xev`,
`write_vt220`, `write_xsendevent` and `write_xtest`, plus `COPYING` under
`share/doc/kbredir`.  The package removes the legacy `/usr/X11R6/lib` build
path and explicitly uses GNU C89; it installs no wrapper, privilege escalation,
device rule or service.

```sh
guix build -L guix --no-grafts kbredir
make check-kbredir
```

The tools exchange `<key> down`/`<key> up` lines.  The four non-X-writer
programs have no conventional help option: arguments are rejected with
`<program> takes no options`.  The X writers require an authorized display,
optionally selected with `--display` and `--window`.  `read_linux_console`
changes its controlling console tty to `K_MEDIUMRAW` and can activate a virtual
terminal; do not run it on an unintended host tty.

On 2026-09-30, source build, reproducibility rebuild (`--check`), offline lint
and the installed-runtime smoke passed.  In private user, mount, network and
PID namespaces, the smoke checks VT220 pipe round trips, Control-c encoding,
and a real raw-mode PTY session with terminal restoration.  A private Xvfb
receives actual XTEST `a`/F6 and XSendEvent `b` press/release events; `read_xev`
decodes the receiver's report back to the exact protocol sequence.  HOME/XDG
state stays confined and the output NAR is unchanged and read-only.
`.goocastle/evidence/issue-608.png` was visually inspected and shows the actual
PTY protocol for `a`, Shift-modified `b`, F6 and Home; the X11 delivery claim
comes from the runtime assertions, not that terminal image.  No host keyboard,
console or live X display was exercised, and no installed profile was changed.
Existing legacy compiler warnings remain visible in the successful build log.

## PDP-10 ITS disassembler and utilities

`pdp10-its-disassembler` `0-c745bb5` builds revision
`c745bb51e6b38f89b2d0ce95edb45833dbdd937d`, recursively fetching the pinned
LodePNG submodule `34628e89e80cd007179b25b0b2695e6af0f57fac` used by `tvpic`.
The installed suite includes `dis10`, `itsarc`, word-format and tape/dump
utilities, with `mini-dumper` and `failsafe` retained as distinct invoked names
because their basenames select formats.  The GPL-2.0-only and LodePNG zlib
notices are installed under `share/doc/pdp10-its-disassembler`.  Non-default
`ast` and the external-tool-dependent `harscntopdf` helper are not included.

```sh
guix build -L guix --no-grafts pdp10-its-disassembler
make check-pdp10-its-disassembler
dis10 -r -Wbin -mkl10 /path/to/program.bin
```

On 2026-09-30, source build, reproducibility rebuild (`--check`), offline lint
and the installed-runtime smoke passed.  The package check phase runs upstream
`check.sh` and explicitly compares every expected transcript and scrambling
round trip, rather than relying on the script's permissive exit status.  The
separate smoke runs installed `dis10` in real PTYs with private HOME/XDG,
network and PID namespaces: a hand-encoded 14-word program matches exact KL10
and KA10 listings, including decoding `adjbp 3, 14` only on KL10.  Upstream's
MIDAS-assembled SBLK sample also matches `-Sall` and `-Sddt` symbol-mode
expectations.  The installed `itsarc -t` archive proof also passed: upstream's
included `samples/arc.code` produces the complete nine-member listing matching
the expected names, word counts, timestamps and byte sizes.  HOME/XDG stays
empty and the store output is unchanged and read-only.
`.goocastle/evidence/issue-611.png` was visually inspected and shows
the actual 14-word KL10 listing.  This proves disassembly, not execution on a
PDP-10; no hardware, network service or live profile was changed.  Existing
legacy compiler warnings remain visible in the successful build log.

## Tapeutils local tape-image tools

`tapeutils` `0.6-0.84a3a78` builds the GPL-2.0-only upstream revision
`84a3a78d2c028d7a4e2e68b89be0411cebd94563`.  A bounded GNU-make portability
change replaces the BSD `UNAME != uname` assignment.  It installs `tapecopy`,
`tapedump`, `taperead`, `tapewrite`, `t10backup`, `read20` and `tapex`, with
`COPYING` under `share/doc/tapeutils`; no service, device rule, remote setup or
runtime wrapper is installed.  Use explicit local filenames for image-only
operation: `/dev/` paths select hardware, colon-containing names select remote
`rmt`, and omitting the name can consult `TAPE`.

```sh
guix build -L guix --no-grafts tapeutils
make check-tapeutils
```

On 2026-09-30, source build, reproducibility rebuild (`--check`), offline lint
and the installed-runtime smoke passed.  With an empty environment apart from
private HOME/XDG settings and networking disabled, `tapewrite -n 80` creates a
Wilson image containing two files and five 80-byte records.  The smoke compares
the complete image with independently framed expected bytes, checks every
`tapedump` record and payload, copies it with `tapecopy`, and extracts both files
byte-for-byte with `taperead`.  It also checks the copy's extra tape mark and
upstream's empty end-of-tape extraction file.  A deliberately mismatched
trailing record length is rejected with exit status 1 and `?Corrupt tape image`
before any record is listed.  HOME/XDG remains empty; all generated images and
extracted files stay in the disposable working tree.  The before/after output
NAR comparison and absence of writable store files passed, preserving the
immutable-store invariant.
`.goocastle/evidence/issue-614.png` was visually inspected and shows the actual
listing: file 0 has three records/240 bytes, file 1 has two records/160 bytes,
then `end of tape`.  No tape hardware, remote tape server or installed profile
was used or changed.  Existing legacy compiler warnings remain visible in the
successful build log.

## VT05 classic terminal emulators

`vt05` `0.1-1.934fe88` builds the MIT-licensed revision
`934fe8898bd656749b323abbdab62939148cfe3e` from `aap/vt05`, linked with Guix
SDL2.  It installs `vt05`, `vt50`, `vt52`, `dp3300`, `gecon` and `dm2500`, plus
`LICENSE` under `share/doc/vt05`.  Each emulator opens an SDL window and starts
the supplied command on a POSIX PTY; `vt50`/`vt52` set `TERM=vt52`, while the
others set `TERM=dumb`.  No runtime wrapper or service is installed.

```sh
guix build -L guix --no-grafts vt05
make check-vt05
vt52 sh
```

On 2026-09-30, source build, reproducibility rebuild (`--check`), offline lint
and the installed-runtime rendering smoke passed.  All six actual emulators
receive three fixture lines through their own PTY, with the expected `TERM`;
their SDL windows visibly change from the blank baseline.  Terminal-specific
clear/home sequences then erase the text, leaving zero changed pixels in the
compared screen region.  This is actual window rendering and erase behavior,
not a window-title or child-marker-only check.  The screen comparison excludes
the blinking cursor and uses a cropped region containing the fixture text.
The smoke uses software SDL rendering, a private Xvfb with private X sockets
and no TCP listener, user/mount/network/IPC/PID namespaces and fresh HOME/XDG
state.  The output NAR is unchanged and store files remain read-only; no host
display, terminal hardware, service or installed profile was changed.
`.goocastle/evidence/issue-616.png` is an actual VT52-window capture, visually
inspected with all three lines readable: `VT05 OFFLINE RENDER`,
`0123456789 ABCDEFGHIJKLMNOPQRSTUVWXYZ` and `REAL PTY OUTPUT`, without visible
errors or clipping.

## Heroic GOGDL offline helper proof

`heroic-gogdl` 1.3.0 builds release revision
`4fe373914d625cbce75973e92f6c5c4faf9815e2`, recursively including xdelta
`0525275fe4b553a10f38e455d30c60dc6ed9b45d`.  The installed command remains
`gogdl`; its `gogdl_xdelta3` C extension is compiled from source, not a
downloaded binary.  Guix's Python wrapper includes the installed module and
Requests dependency.  The parent GPL-3.0-only and bundled xdelta Apache-2.0
notices are installed under `share/doc/heroic-gogdl`.

```sh
guix build -L guix --no-grafts heroic-gogdl
make check-heroic-gogdl
gogdl lang-match en
```

On 2026-09-30, source build, reproducibility rebuild (`--check`) and the revised
installed-runtime smoke passed.  Offline lint retains the `python-wheel`
native-input advisory: upstream `pyproject.toml` explicitly requires wheel and
the build system does not supply it, so the input remains.  Existing legacy
xdelta C compiler warnings remain visible in the successful build log.

The credential-free smoke runs in private user/network namespaces with fresh
HOME/XDG/GOGDL state and an empty inherited environment.  Actual CLI calls
check version/help, English and unknown-language matching, the missing-import
path parser error and a synthetic Linux installer import reporting version
`1.2.3`.  Local v2 manifest checks cover selected DLC, normalized languages,
download/disk sizes and serialization; chunk comparison checks reuse at the
correct old byte offset and distinguishes a new chunk.  File checks cross the
checksum reader's 16 KiB boundary, resolve an actual case-insensitive path and
verify `SyncFile`'s deterministic gzip checksum and UTC timestamp metadata.
The installed xdelta decoder applies a real VCDIFF COPY-plus-ADD patch and
produces exactly `hello world\n`, leaving its source bytes unchanged.  Fresh
state directories remain empty and the installed output digest is unchanged
and non-writable.

`.goocastle/evidence/issue-622.png` was visually inspected and contains the
actual language JSON, expected missing-path error and fixture import JSON
with platform `linux` and version `1.2.3`.  These are local CLI/file proofs,
not evidence of current GOG service compatibility: no live GOG account,
authentication, game download, cloud synchronization or credentials were used.
Authentication remains the caller's explicit `--auth-config-path` token-file
contract; no account, service or installed profile was changed.

## Pinned Forth mode for Emacs

The channel's `emacs-forth-mode` `0-4450a3a` packages GPL-3.0-only revision
`4450a3a5629b579f5d2045d0d8aec84193e9a31f`, whose upstream header declares
0.3.  Select the module explicitly: a bare `emacs-forth-mode` lookup currently
selects Guix's separate 0.3 package, not this pinned channel build.

```sh
guix build -L guix --no-grafts \
  -e '(@ (tay packages forth-mode) emacs-forth-mode)'
make check-emacs-forth-mode
```

The package includes the major/block/interaction modes and nested interpreter
backends, including the SwiftForth helper.  Guix generates its autoloads; the
upstream build helper and test-generated autoload file are not installed.
`run-forth` uses the absolute store path of the packaged Gforth interpreter,
without a PATH-dependent wrapper.

On 2026-09-30, the explicitly selected source build, reproducibility rebuild
(`--check`), offline lint and installed editor/runtime proof passed.  The build
ERT run, including compilation, reports 28 tests: 27 expected results, one
network-dependent skip and zero unexpected results.  The separate ERT run
reports 27 tests: 26 expected results, the same skip and zero unexpected
results.  Only the live Forth-standard index retrieval test is skipped;
Gforth-backed completion remains exercised.  Existing byte-compilation and
Gforth load-path warnings remain visible, not suppressed.

With private HOME/XDG, no user init files, an empty PATH and networking disabled,
the installed mode visits copied upstream text/block fixtures and edits a real
`.fth` buffer by inserting `*`.  It checks two-space indentation, comment/string/
definition-name faces, definition and sexp navigation and the Imenu word index.
The actual packaged Gforth backend evaluates the edited `square` definition at
7 to produce 49, completes `2c` to `2Constant`, and exits normally with status 0
after `bye`.  The installed output fingerprint is unchanged and store files
remain read-only; no user source file, interpreter setup or installed profile
was changed.  `.goocastle/evidence/issue-44.png` was visually inspected and shows
the actual edited Forth buffer and the `Forth finished` runtime sentinel.

## Pinned Mentor Emacs client

`emacs-mentor-pinned` `0.5-0.ed42ae8` builds revision
`ed42ae8333d801c841ecf80fb5e4957badb99b51`, 21 commits beyond release 0.5.
This scoped, distinctly named variant includes the added `mentor-trackers.el`
library and does not shadow Guix's existing `emacs-mentor` release package.
It inherits the Async, URL-SCGI and XML-RPC Emacs dependencies, but neither
includes nor starts rTorrent.  The shipped libraries explicitly grant
GPL-3.0-or-later; the source snapshot's license declaration was corrected to
match, rather than retaining the research record's ambiguous GPL-3.0 label.
`COPYING` is installed under `share/doc/emacs-mentor-pinned`.

```sh
guix build -L guix --no-grafts emacs-mentor-pinned
make check-emacs-mentor-pinned
```

On 2026-09-30, source build, reproducibility rebuild (`--check`), offline lint
and both installed-runtime ERT tests passed.  The package's normal autoload
file activates the tracker library only after Mentor loads.  The smoke uses
private user/network namespaces, fresh HOME/XDG, no user init files and an
empty PATH, with explicit guards rejecting process startup and RPC/network I/O.
It exercises local endpoint normalization and temporary configuration-file
generation without creating a daemon, download directory, session or socket.

A fixed local rTorrent-shaped data fixture exercises the actual client parser,
item storage, tracker-name display, sorting, navigation, marking/unmarking and
sparse refresh behavior, including preservation of an existing name and
rejection of an uninitialized new item.  `.goocastle/evidence/issue-166.png`
was visually inspected and shows the actual offline Mentor view: Alpha at
25%, Zulu at 50%, with Zulu marked and the `no RPC` mode line.  The installed
output fingerprint is unchanged and store files remain read-only.  This proves
local client/configuration behavior, **not torrent operations, daemon startup,
SCGI/XML-RPC integration or live tracker actions**.  No torrent, rTorrent
instance, credentials, user configuration or installed profile was used or
changed.

## License

The channel-authored Scheme package definitions, channel metadata, build and
test files, reports, documentation, and other original material in this
repository are licensed under the GNU General Public License, version 3 or
any later version (GPL-3.0-or-later); see [`LICENSE`](LICENSE).

This grant applies only to material authored for this channel.  It does not
relicense upstream source snapshots, fonts, applications, documents, data,
submodules, or other artifacts fetched or packaged by these definitions.  Those
materials retain their respective upstream licenses and notices.  A package
definition's `license` field describes the corresponding packaged upstream
material; it does not change that material's license or grant rights to
relicense it.

## Add the channel

Add this channel to `~/.config/guix/channels.scm`:

```scheme
(cons
 (channel
  (name 'tay)
  (url "https://github.com/htayj/guix-channel")
  (branch "master")
  (introduction
   (make-channel-introduction
    "5de4b5693fae9aa776d089d9818126bc253a69a9"
    (openpgp-fingerprint
     "997E 2BA6 B523 4026 8A39 87E3 D94F 0A11 ACD7 8333"))))
 %default-channels)
```

The introduction commit is signed and its key is published on the channel's
`keyring` branch.  Then run:

```sh
guix pull
```

For a clone of the channel, packages can be used immediately without pulling:

```sh
guix build -L guix cadr-fonts-latin
guix install -L guix sbcl-qbcl
guix build -L guix htayj-ivory-key-source
```

Channel modules live below `guix/`, as declared by the `directory` field in
`.guix-channel`.  Keep repository tooling and generated Goocastle manifests
outside that directory so `guix pull` only compiles actual channel modules.

Source snapshots install below `share/ACCOUNT/projects/REPOSITORY`.  They are
development and preservation inputs, not claims that every repository has a
standalone executable.  A source definition and its hash do not grant
redistribution permission.  Repositories without an explicit license carry a
custom no-permission marker; do not redistribute those package outputs or
publish substitutes for them without a separate rights review.  This caveat
applies to the drbeefsupreme snapshots except `tassh`, which records MIT.

## Installable packages

| Package | Upstream | Installed contents |
| --- | --- | --- |
| `atarist-font` | ntwk/atarist-font | Atari ST 8x16 Unicode BDF and generated PCF font |
| `cadr-fonts-latin` | CADR-fonts 0.1.2 | Unicode BDF and OTB Latin fonts |
| `cadr-fonts-symbols` | CADR-fonts 0.1.2 | Unicode BDF and OTB specialty fonts |
| `dec-fonts` | DEC-Fonts 0.1.0-alpha.2 | BDF, OTB, and Linux-console PSF fonts |
| `genera-fonts-latin` | genera-fonts 0.1.1 | Unicode BDF and OTB Latin fonts |
| `genera-fonts-symbols` | genera-fonts 0.1.1 | Unicode BDF and OTB specialty fonts |
| `aptitude-custom-aliases` | aptitude-custom-aliases | Zsh plugin and documentation |
| `bell-museum` | bell-museum | Museum documentation and Inferno specimen renderer |
| `computer-builder` | computer-builder | Offline-built PC component catalog web application |
| `rust-computus` | computus | Redistributable Rust simulation core |
| `custom-nix-pkgs` | custom-nix-pkgs | Preserved Nix expressions plus a snapshot validator |
| `databases-team75` | Databases-Team75 | Preserved legacy client source and documentation |
| `dorxng-mcp` | dorxng-mcp | MCP server and its packaged Python dependencies |
| `fontra` | fontra/fontra 2026.9.0 | Browser-based font editor, local server, conversion and workflow commands |
| `opencode` | anomalyco/opencode 1.18.18 | Coding-agent command-line interface and terminal UI |
| `opencode-desktop` | anomalyco/opencode desktop 1.18.18 | Electron graphical client with a bundled local backend |
| `claude-code` | Anthropic Claude Code 2.1.233 | Proprietary agentic coding command-line interface |
| `claude-desktop` | Anthropic Claude Desktop 1.30096.1 | Proprietary Electron client for Claude on Linux |
| `hyprland-preview-share-picker` | WhySoBad/hyprland-preview-share-picker | GTK4 Hyprland screencast picker with window previews |
| `hy3` | outfoxxed/hy3 (`d7e0c58`, matched to Hyprland 0.55.4) | Manual tree layout and tabbed groups, `lib/hyprland/libhy3.so` |
| `dank-material-shell-shell-only` | DankMaterialShell 0.5.1 | Full upstream shell with external GTK/Qt icon mutation guarded by the user's settings and `DMS_DISABLE_MATUGEN` |
| `caelestia-shell` | caelestia-dots/shell 2.5.0 | Quickshell desktop shell, `Caelestia` QML plugin, and `caelestia-shell` launcher |
| `caelestia-cli` | caelestia-dots/cli 1.1.3 | `caelestia` shell control, colour scheme, screenshot, recording, and picker command |
| `quickshell-for-caelestia` | Quickshell 0.3.1 + 10 commits (`2d3b3e9`) | `qs`/`quickshell` at the commit pinned by Caelestia shell 2.5.0 |
| `libcava` | LukashonakV/cava 1.0.0 | CAVA audio visualizer as a shared library |
| `m3shapes` | soramanew/m3shapes (`32ad9ce`) | Material 3 Expressive shape QML module |
| `dart-sass` | sass 1.105.0 (npm) | Reference Sass compiler with the module system, run on Node.js |
| `gpu-screen-recorder` | GPU Screen Recorder 6.1.3 | VA-API/Vulkan screen recorder and `gsr-kms-server` |
| `font-rubik` | googlefonts/rubik 2.300 | Rubik variable font |
| `font-material-symbols-rounded` | material-design-icons 2.972 | Material Symbols Rounded variable icon font |
| `font-nerd-caskaydia-cove` | Nerd Fonts 3.5.1 | CaskaydiaCove Nerd Font |
| `sbcl-ivory-key` | ivory-key | Declarative keyboard-layout compiler |
| `manna-cadet` | manna-cadet | Space Cadet keyboard layouts and helper tools |
| `sbcl-qbcl` | qbcl | qBittorrent command-line controller |
| `sbcl-rplaca` | rplaca | Lisp-native LLM chat interface |
| `emacs-mentor-pinned` | skangas/mentor 0.5 + 21 commits (`ed42ae8`) | Distinct pinned Emacs rTorrent frontend with the post-0.5 tracker library; no daemon activation |
| `terminaldrome` | thafaker/TerminalDrome | Rust terminal client for Navidrome and Subsonic servers |
| `image-tape` | larsbrinkhoff/image-tape | Magnetic-tape image reader with safe output handling |
| `apout` | DoctorWkt/Apout 2.4.0 | PDP-11 Unix a.out user-mode emulator; supply a user-owned `APOUT_ROOT` |
| `kitty-bitmap` | Kitty 0.49.1 (pinned tag `v0.49.1`) | Kitty variant that selects native bitmap fonts and encodes XKB Meta as terminal Alt |
| `halloy` | squidowl/halloy 2026.8 | Upstream x86_64 Linux desktop IRC client release with Wayland/X11 runtime libraries |
| `shader-slang` | shader-slang/slang 2026.14.1 | `slangc` Slang shader compiler and libraries; build dependency of `kitty-bitmap` |
| `axmud` | Axmud 2.0.0 | Perl/GTK3 graphical MUD client with GMCP and configurable scripting |
| `aquarium-arena` | valrak/AquariumRL 0.4 | Underwater pygame arena roguelike with XDG high scores |
| `atlas-warriors` | lkingsford/AtlasWarriors alpha-009 | Graphical fantasy roguelike with XDG state |
| `ighalsk` | Ighalsk 0.1.16 | Original Python 2/Tk dungeon adventure with XDG saves and editors |
| `aquesttoofar` | A Quest Too Far 1.3 | Source-built C++/SDL dungeon adventure starring an aging hero |
| `talmudifier` | subalterngames/talmudifier 1.1.0 + 1 revision (`1f23206`) | Offline XeLaTeX rendering of the bundled Talmud-style example; Python API installed |
| `rouge` | The Rougelike! 1.61 | Original curses Wikipedia-satire roguelike with XDG controls and high scores |
| `sewer-massacre` | The Sewer Massacre 1.0 | Original Common Lisp curses roguelike with ASDF FASLs and XDG save state |
| `six-two-one` | Six Two One 2016-03-06 | Original source-built C++/SDL word-puzzle roguelike with libtcod and XDG configuration/saves |
| `umoria` | Umoria 5.7.15 (`624a051`) | Full original source-built C++/ncurses Moria with immutable data and XDG scores/default save |
| `pyro` | Pyro 0.04a | Complete original Python 2/curses roguelike with XDG native log; no upstream save/load |
| `narwharl` | NarwhaRL 0.0.1 | Full original source-built C++/ncurses roguelike with immutable definitions and XDG/HOME native saves |
| `blightmud` | Blightmud 5.7.1 | Rust terminal MUD client with Lua, TLS, MCCP2, GMCP, and MSDP |
| `bell-labs-rogue7` | Bell Labs release 7.7.1 | Historical terminal dungeon game with XDG-managed score and save state |
| `chessrogue` | ChessRogue 0.3.1 | Historical terminal chess roguelike built from the canonical SourceForge release |
| `bcrawl` | b-crawl/bcrawl 1.42.1 | Terminal-only Dungeon Crawl Stone Soup fork with XDG-managed state |
| `avanor` | Avanor 0.5.8 | Historical terminal roguelike with XDG-managed saves and high scores |
| `nlarn` | NLarn 0.8.0 | Curses roguelike rewrite of Larn with isolated user state |
| `durthang` | Durthang 0.2.0 | Rust TUI MUD client with TLS, GMCP, automapping, and encrypted Secret Service transport |
| `frostbite` | Frostbite 1.18.2 | Qt5 DragonRealms client with Ruby scripting, profiles, maps, sound, and XDG state |
| `godisc` | DavidSatimeWallin/godisc | Discworld-oriented terminal MUD client with an optional tmux workspace |
| `go-mud` | go-mud 0.6.6 | UTF-8 terminal MUD client with Lua scripting |
| `kbtin` | kilobyte/kbtin | TinTin-compatible terminal MUD client with TLS and MCCP |
| `kbredir` | larsbrinkhoff/kbredir 0.9 | VT220, Linux-console, xev, XSendEvent, and XTEST keyboard-event redirects |
| `kildclient` | KildClient 3.2.3 | GTK MUD client with Perl scripting, plugins, triggers, aliases, and multiple worlds |
| `kmuddy` | KMuddy 1.1 | KDE MUD client with scripting, mapping, MCCP, MSP, and MXP |
| `ks10-udis` | larsbrinkhoff/ks10-udis | KS10 microcode disassembler and offline fixture |
| `lyntin` | Lyntin V 5.0.1 | Text-mode Python MUD client with aliases, triggers, scripting, and module support |
| `mmapper` | MMapper 26.06.0 | Qt graphical MUME client, local TLS proxy, and empty-map editor |
| `mudlet` | Mudlet 4.22.0 | Qt6 graphical MUD client with Lua scripting, mapping, multimedia, MXP, and GMCP |
| `mudpuppy` | Mudpuppy 20251214 | Rust terminal MUD client with embedded Python scripting and TLS |
| `notion-river` | Marenz/notion-river 0.6.0-14.ge79dea3 | Static tiling window manager for a separately supplied River 0.4.x+ compositor |
| `mushkin` | Mushkin 0.5.1 | Qt MUSHclient-compatible MUD client with Lua, TLS, and MSP |
| `mushtato` | MushTato 1.9.3 | Python/Qt MUSH client with sandboxed scripting, TLS, and SSH |
| `potato` | Potato 2.0.0b19 | Tcl/Tk graphical MUSH client; insecure upstream TLS is deliberately disabled |
| `pycat` | cizra/pycat | Modular Python MUD proxy client with user-defined world modules |
| `rune` | Rune 0.10.1 | Pure-Go terminal MUD client with Lua, TLS, MCCP2, and GMCP |
| `secretpathway` | SecretPathway 1.0.0 | Java/Swing MUD client with an LPC source editor |
| `tinyfugue` | TinyFugue Rebirth 5.2.2 | Scriptable terminal MUD client with TLS, MCCP, GMCP, and IPv6 |
| `trebuchet` | Trebuchet 1082 | Tcl/Tk graphical MUD, MUCK, and MUSH client with MCP support |
| `vt05` | aap/vt05 | SDL emulators for six classic text terminals |
| `weidu` | WeiDU 252.01 | Offline-built Infinity Engine modding command-line tool |
| `emacs-treesit-sexp` | alexispurslane/treesit-sexp | Tree-sitter-aware structural editing for Emacs |
| `dipc` | doprz/dipc | Offline-built image palette converter |
| `nrl-text-to-phoneme` | greg-kennedy/p5-NRL-TextToPhoneme | NRL text-to-phoneme command and rule tables |
| `you-can-datamosh-on-linux` | happyhorseskull/you-can-datamosh-on-linux | Datamoshing and video-to-GIF commands with argv-safe FFmpeg calls |
| `ffglitch` | [FFglitch 0.10.2](https://ffglitch.org/) / [ramiropolla/ffglitch-core](https://github.com/ramiropolla/ffglitch-core) | Native bitstream editor, glitch encoder, live scripted player, and private QuickJS/JSON helpers |
| `xq` | sibprogrammer/xq | Offline-built XML and HTML beautifier and extractor |
| `sentinelone` | SentinelOne Linux agent 24.3.3.1 | Proprietary x86_64 agent; authorized installer required |

These installable packages do not add source snapshots; the source
collection remains 629 packages.

The release font packages consume immutable generic GitHub Release archives
rather than repackaging `.deb`, RPM, Arch, or XBPS artifacts.  `atarist-font`
uses its immutable GitHub source snapshot; its build corrects the upstream BDF
`CHARS` header from 324 to the actual 322 glyph records and generates a PCF
copy.  CADR and DEC releases carry their upstream licenses.  Genera packages
preserve the project's separate BSD-3-Clause code/documentation license and
required typeface publication notice; that notice is not represented as an
upstream license grant.

`custom-nix-pkgs` and `databases-team75` are intentionally source-oriented
data packages, not replacements for a native application.  `bell-museum` does
not package its Inferno submodule; use its renderer with an independently
acquired checkout when source artwork is required.

`fontra` pins upstream tag `2026.9.0` at commit
`cc0a3b40bcd9860d8b6382df1faf6122ec306a5b`.  The Python package and frontend
are built offline after Guix acquires their fixed-hash inputs.  The frontend
uses 329 individual pinned npm archives and `npm ci --offline --ignore-scripts`
with optional packages omitted, not a fetched `node_modules` bundle.  The
unused npm 12 development subtree and optional native TypeScript compilers
are pruned; missing lock metadata is filled without changing retained
versions or workspace links.  Guix's Node/npm and Babel/Webpack compile the
frontend.  This is not a fully source-rebuilt npm/WASM closure: `harfbuzzjs`,
`build-shaper-font`, and build-time `source-map` WASM remain precompiled,
pinned upstream artifacts.  Their redistribution notices are packaged under
`share/doc/fontra/npm`; Fontra's GPL-3.0 license is under `share/doc/fontra`.

Channel dependency variants provide the required FontTools, Unicode data,
UFO tooling, Skia path operations, Pillow, aiohttp, and Watchfiles versions;
Guix supplies cattrs, PyYAML, and the build/test tools.  Fontra's actual
`test-py` pytest suite and JavaScript `npm test` suite are retained.  Pillow's
two memory-heavy WebP tests (`test_write_encoding_error_message` and
`test_write_encoding_error_bad_dimension`) are excluded; its adversarial
fuzz cases run with a temporary 256 MiB address-space limit, restored for
normal tests.  UFOMerge's own suite is disabled because its `fontFeatures`
test dependency is absent from Guix; Fontra's workflow tests remain enabled.

From a channel clone, normal installation is `guix install -L guix fontra`.
For the verified local build and smoke path:

```sh
guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 fontra
make check-fontra   # project creation, UFO roundtrip, workflow and HTTP assets
# Or reuse an existing output without building it again:
FONTRA_PACKAGE=/gnu/store/…-fontra-2026.9.0 make check-fontra
fontra new /path/to/fonts/example.fontra
fontra --host 127.0.0.1 --http-port 8000 filesystem /path/to/fonts
fontra-copy /path/to/fonts/input.ufo /path/to/fonts/output.fontra
fontra-workflow /path/to/workflow.yaml
```

Open `http://127.0.0.1:8000/` in a browser.  Use a user-owned font directory;
the channel installs no persistent server or profile automatically.
Local font editing and shaping work without external network access, but
optional remote glyphset presets (including GF Latin Kernel from jsDelivr)
require network access; the entire runtime is not claimed offline.  Chromium
verification exercised the project overview and Glyph Editor with a local
triangle glyph and text shaping enabled.
`make build-fontra` also uses `--no-grafts --no-offload`.  The verified local
closure used those flags: a default graft-enabled attempt hit an unrelated
Python 3.12 graft build test failure, so normal graft-enabled builds are not
claimed verified.  Initial source/dependency acquisition may use the network;
the package build does not resolve dependencies online.

`opencode` packages the official Bun-compiled release executable because the
channel's Guix revision does not provide Bun and upstream's build performs
additional network installs of platform-specific dependencies.  The package
uses upstream's baseline x86_64 glibc archive (which avoids an AVX2 requirement)
or its aarch64 glibc archive, verifies each with the digest published on the
GitHub release, and runs the unmodified ELF through Guix's glibc loader.  The
exact source tag is retained for provenance and its MIT notice is installed
with the package.  The executable embeds the Bun runtime, JavaScript bundle,
web UI, and native dependencies selected by upstream; they are not rebuilt or
separately audited by this channel.  Provider credentials and services,
downloaded language servers, and optional integrations remain runtime concerns.

`dank-material-shell-shell-only` inherits the complete upstream
DankMaterialShell 0.5.1 package from Guix, keeping every helper, and exports
the unique shell variant.  External GTK and Qt icon configuration writes run
only when the respective `gtkThemingEnabled` or `qtThemingEnabled` setting is
enabled and `DMS_DISABLE_MATUGEN` is neither `1` nor `true`.  Icon changes never
purge user caches or signal unrelated GTK applications.  The shell's own
`iconTheme` setting and normal icon resolution are retained; application icon
rendering follows the shell process's Qt platform theme.  The source patch
uses exact context (`--fuzz=0`) and fails if that upstream context drifts.
Because both
packages install the same QML paths, migrate from a previous
`dank-material-shell` installation with a single transaction from a clone:

```sh
guix package -L ~/projects/guix-channel/guix \
  --remove=dank-material-shell --install=dank-material-shell-shell-only
```

A fresh installation uses `guix install -L ~/projects/guix-channel/guix
dank-material-shell-shell-only`.  The explicit package expression is
`(@ (tay packages dank-material-shell) dank-material-shell-shell-only)`.

`opencode-desktop` uses the official architecture-specific Debian release
bundle.  A source build is not currently reproducible in this channel: Guix
does not package Bun, upstream requires Electron 42.3.3 while the channel has
Electron 41, and the Bun monorepo build resolves platform-specific native Node
modules.  The package retains the exact source tag and its MIT license for
provenance, verifies the x86_64 or aarch64 release archive, and patches the
bundled Electron and glibc native modules for Guix.  The default v1 desktop
backend is JavaScript inside `app.asar` and runs locally; the experimental v2
service CLI is neither enabled nor downloaded.  Updater provider metadata is
removed so replacement application bundles remain Guix-managed.  The Electron
license and Chromium's bundled third-party notices are installed alongside the
application.  The launcher automatically selects Wayland or X11, retains the
`opencode:` URL handler, and stores credentials and project state only in the
user's normal configuration and data directories.

`claude-code` packages Anthropic's official x86_64 or aarch64 glibc Debian
release.  Upstream distributes a Bun-compiled native executable rather than a
buildable application source tree; the package pins the release repository's
published digest, patches the ELF interpreter and glibc runpath for Guix,
retains the bundled cross-architecture `ripgrep`, and sets
`DISABLE_UPDATES=1` so neither automatic nor manual update paths replace the
store-managed executable.  The vendor copyright file says
that use is governed by Anthropic's applicable consumer or commercial terms.
Authentication, provider access, settings, plugins, MCP servers, hooks, and
session data remain runtime concerns in the user's directories.

`claude-desktop` packages Anthropic's official x86_64 or aarch64 Linux beta
Debian release.  The package identifies the application as proprietary and
contains Electron 42.7, native Node modules, helper executables, Cowork VM
assets, Chromium notices, and separate Apache-2.0/BSD-3-Clause virtiofsd
notices.  The Guix package patches the dynamic components, installs the
upstream desktop entry and icons, and never runs the Debian maintainer script
that would register Anthropic's apt repository.  Anthropic documents that the
Linux application does not self-update.  Core desktop use supports Wayland or
X11 and relies on the user's secret service and desktop portals.  Cowork is
not configured: it additionally needs KVM access, QEMU, architecture-specific
firmware, virtiofsd integration, about 25 GB of mutable storage, and at least
8 GB of RAM.

`image-tape` creates its optional output file safely and propagates write
errors to its exit status.  The `check-image-tape` regression uses Guix's
`tar`, `patch`, `coreutils`, and pure `gcc-toolchain` inputs with a tape shim,
so it exercises output framing and write failures without tape hardware.
`apout` runs PDP-11 a.out binaries against host system-call implementations.
Set `APOUT_ROOT` to a user-owned guest root; it is not a security sandbox,
because Apout can access host filesystem, process, and socket APIs directly.
Its optional smoke needs an externally supplied V7 `echo` a.out fixture whose
provenance and redistribution clearance have been reviewed; it never fetches
or packages a guest binary or filesystem image.
`you-can-datamosh-on-linux` invokes FFmpeg with
argument vectors rather than shell-command strings, so filenames and options
containing shell metacharacters are not interpreted by a shell; its dedicated
argv security smoke test is part of `make check`.  `dipc` and `xq` retain their
reviewed, pinned Rust and Go dependency graphs and build without network
resolution.

`kitty-bitmap` pins Kitty 0.49.1's upstream tag, commit, source hash, source
snippet, and version-sensitive build phases inside this channel rather than
following Guix's rolling `kitty` source.  Generic dependency packages remain
inherited from Guix, with one exception: Go modules Kitty 0.49.1's `go.mod`
needs that Guix does not reliably provide come from the channel-private
`kitty-bitmap-go-deps` module.  `emmansun/base64` and `sgtdi/fswatcher` are
missing from pre-2026-08-26 Guix revisions, and `kovidgoyal/go-shm/v2` is not
packaged by Guix at all, so the package builds on older and newer Guix alike
without colliding with upstream's identically-named definitions.  Kitty 0.49
also compiles its shaders with `slangc` at build time, so the channel's
`shader-slang` package, Slang 2026.14.1 as pinned by Kitty's own bundle
builds, is a native input.  It builds only the compiler and `slang-glslang`
from source, taking miniz and unordered-dense from Guix and keeping the
SPIRV-Headers, SPIRV-Tools, glslang and lz4 submodules bundled because Guix's
versions are too old or lack a CMake config.  Its
documented AUR-derived Fontconfig patch enables
native BDF/PCF font selection by default.  Such fixed bitmap strikes do not
zoom or scale cleanly;
use an available native size and, if needed, an explicit line height.  Its
separate channel patch translates the raw GLFW Meta bit to Alt only at the
child-process encoding boundary: Kitty shortcut matching still sees Meta,
while legacy terminal applications receive ESC-prefixed Alt chords and the
extended keyboard protocol reports Alt.  Physical Alt/XKB bindings are not
changed.  The `check-kitty-bitmap` smoke checks that both the evaluated
package and the built program report Kitty 0.49.1, then uses Kitty's native
key encoder, Unscii's non-scalable PCF face, and Kitty's native Fontconfig
calls through `kitty +runpy`, without a display server.  It verifies raw-Meta
shortcut matching, Meta-to-Alt child encoding, font selection, and nonempty
glyph-cell rasterization, but not a live GUI window.

Verified on 2026-09-28 with host Guix `21c3d67`: a local `guix build
--no-offload --no-grafts --cores=2 --max-jobs=1 kitty-bitmap` (building
`shader-slang` from source) produced
`/gnu/store/3yn35mdxl2y0aj8z72416dliwbiwdp1m-kitty-bitmap-0.49.1`, and the
smoke passed against it.  `guix lint` is clean for `shader-slang`; for
`kitty-bitmap` it reports only the inherited `bash-minimal` suggestion and
relative patch-path warnings.  The verification is headless only: no live GUI
window was opened and the package was not installed into a profile.  At run
time Kitty needs `slangc` only for user custom shaders; `shader-slang` is a
build-time input, so install it separately if you use those.

The twenty-one MUD clients cover distinct local interfaces.  `axmud`, `frostbite`,
`kildclient`, `kmuddy`, `mmapper`, `mudlet`, `mushkin`, `mushtato`, `potato`,
`secretpathway`, and `trebuchet` provide GTK,
KDE/Qt, Tcl/Tk, and Java/Swing desktops; `go-mud`, `lyntin`, `tinyfugue`,
`godisc`, and `kbtin` provide different text-mode workflows; `blightmud`,
`durthang`, and `mudpuppy` are modern Rust TUIs with GMCP and
scripting features; and `pycat` is a
terminal-facing proxy whose world modules load from the invoking directory.
Rune is a pure-Go terminal client with an embedded Lunar Lua interpreter.
Dedicated smokes use Guix's Xvfb where needed, fresh homes, and loopback
fake-MUD or frontend sockets.  GoDisc also creates and removes a real
three-pane tmux session, Durthang verifies persisted GMCP map state and
explicit headless keyring failure, and Pycat checks safe sibling imports and
live reload.  None contacts a public MUD.

`sentinelone` is source-required and is checked for enumeration, dry-run, and
lint, but is excluded from the default `make build`.  No proprietary installer
is included in this channel.  To build it, supply an authorized matching
x86_64 `.deb` explicitly:

```sh
guix build -L guix --with-source=sentinelone=/path/to/SentinelAgent-Linux-24-3-3-1-x86-64-release-24-3-3_linux_x86_64_v24_3_3_1.deb sentinelone
```

The channel's package definition and documentation are GPL-3.0-or-later under
[`LICENSE`](LICENSE); any upstream notices are recorded separately in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).  Neither those notices nor
the channel license grants rights to the proprietary SentinelOne agent.  Never
commit the installer or a management token to this repository.
`--with-source` imports the authorized installer into the local Guix store for
the build, so treat that source and local-store exposure as sensitive: the
fixed-output source may remain there.  The package output is marked
non-substitutable, but that alone does not prevent proprietary source or output
paths from being served by `guix publish`; isolate, remove, or ACL such paths
and never publish them.  Never supply a management token at build time or place
it in the repository or store.  Running the agent requires a privileged system
service and persistent state; this channel does not configure or validate that
runtime deployment.

### FFglitch: native bitstream editing and live preview

`(tay packages ffglitch)` builds the official
[0.10.2 source release](https://ffglitch.org/pub/src/ffglitch-0.10.2.tar.xz),
corresponding to `ffglitch-core` commit
`225c210d02a30949e7d0443109c4cd2a8bea94d0`.  The
[official download page](https://ffglitch.org/download) and
[release announcement](https://ffglitch.org/2024/10/ffglitch_0_11_2.html)
identify 0.10.2 as the current official release; research on 2026-10-02 found
no evidenced successor project.  The
[ffglitch-scripts repository](https://github.com/ramiropolla/ffglitch-scripts)
is a companion script collection, not a replacement.

```sh
guix install -L guix ffglitch
# Or build without installing into a profile:
ffglitch_out=$(guix build -L guix --no-grafts ffglitch)
```

The public commands are `ffedit` (bitstream editing), `ffgac` (glitch-oriented
encoding), `fflive` (live scripting/playback), and `ffglitch-ffprobe` (the fork's
probe).  They coexist with stock FFmpeg: the package does not install commands
named `ffmpeg`, `ffplay`, `ffprobe`, or `qjs`, nor conflicting libav headers,
libraries, pkg-config files, or public generic FFmpeg man pages.  Under the
package output, the standalone interpreter is `libexec/ffglitch/qjs`; the
helpers are `share/ffglitch/ffglitch.js` (standalone JSON transformation) and
`share/ffglitch/ffglitch.py` (Python media workflow).  Generic manuals and
QuickJS HTML documentation are private under `share/doc/ffglitch/`.

The build retains upstream's default JavaScript/QuickJS, native Python with
NumPy, bundled Xvid, ZeroMQ messaging, SDL live preview, and RtMidi support;
it does not enable nonfree components.  Native Python loads the package's
Python library and wrapped NumPy environment rather than depending on a host
Python installation.  The configured build is GPL-2.0-or-later because it
enables GPL components including bundled Xvid; LGPL, Expat/MIT, MPL-2.0, BSD,
and IJG component terms also apply.  `share/doc/ffglitch/` retains `LICENSE.md`,
the GPL/LGPL license texts, `CREDITS`, and `NOTICES`, with bundled component
licenses and required source copyright/disclaimer notices under `licenses/`.

This original example is the exercised native JavaScript API, not a stock
FFmpeg filter.  Work in a writable directory.  Generate a 36-frame, 320×240,
12-fps RGB fixture with Python, then encode it with the tested `ffgac` options:

```sh
python3 - <<'PY'
image = bytearray()
for y in range(240):
    for x in range(320):
        image.extend(((x * 3 + y) % 256,
                      (y * 5 + (x // 16) * 31) % 256,
                      ((x // 12 ^ y // 12) & 1) * 220 + 20))
with open("fixture.rgb", "wb") as stream:
    for _ in range(36):
        stream.write(image)
PY
"$ffglitch_out/bin/ffgac" -hide_banner -nostdin -y -f rawvideo \
    -pixel_format rgb24 -video_size 320x240 -framerate 12 -i fixture.rgb \
    -frames:v 36 -an -c:v mpeg4 -pix_fmt yuv420p -threads 1 -bf 0 \
    -qscale:v 2 -mpv_flags +nopimb+forcemv -fcode 6 -g max \
    -sc_threshold max source.avi
cat > native.js <<'JS'
let mutate = false;
export function setup(args) {
  args.features.push("mv");
  mutate = args.params === true;
}
export function glitch_frame(frame) {
  if (mutate && frame.mv && frame.mv.forward)
    frame.mv.forward.fill(MV(16, 0));
}
JS
"$ffglitch_out/bin/ffedit" -threads 1 -i source.avi -s native.js \
    -sp false -o control.avi
"$ffglitch_out/bin/ffedit" -threads 1 -i source.avi -s native.js \
    -sp true -o glitched.avi
# Preview the same transformation directly from the original encoded source.
# Requires a working display; press q to quit.
"$ffglitch_out/bin/fflive" -i source.avi -s native.js -sp true -an \
    -noframedrop -x 320 -y 240 -noborder -window_title "FFglitch native proof"
```

`setup` requests the motion-vector feature and receives the JSON value from
`-sp`; `MV(16, 0)` changes forward vectors horizontally.  Use `-sp false` for
the no-op control.  In `fflive`, `-f` selects the demuxer format, so feature
selection belongs in `setup`, not a guessed `-f mv` player option.  For
`ffedit`'s separate JSON workflow, the exercised commands are:

```sh
"$ffglitch_out/bin/ffedit" -threads 1 -i source.avi -f mv -e vectors.json
"$ffglitch_out/bin/ffedit" -threads 1 -i source.avi -f mv \
    -a vectors.json -o json-roundtrip.avi
```

See the official [ffedit reference](https://ffglitch.org/docs/0.10.0/ffedit/),
[ffgac reference](https://ffglitch.org/docs/0.10.1/ffgac/), and
[fflive reference](https://ffglitch.org/docs/0.10.2/fflive/) for further modes.
User scripts execute code; use only scripts you trust.

Verified 2026-10-02: the local build produced
`/gnu/store/r0mgvnyaiaydpf0fwr3xxih1r1vc8wlm-ffglitch-0.10.2`.  A subsequent
`guix build -L guix --no-grafts --check ffglitch` passed, confirming the
rebuild reproduced the output.  FFglitch's no-network lint and integrated
`make check-ffglitch` also passed.  Its offline
FATE tests passed after reclassifying three upstream tests that require an
external Lena sample into the external-sample group; those three were not
run.  Six bundled QuickJS tests and the complete shipped `ffedit` fixture
checks passed.  The real runtime smoke exported 10,500 motion vectors from
the synthetic MPEG-4 fixture.  The native JavaScript mutation changed decoded
pixels with mean absolute error 86.987 against the control; native Python and
standalone JavaScript/Python transformations matched it exactly.  No-op
scripting and JSON export/import preserved the source.  The actual SDL
`fflive` preview matched the decoded glitch frame pixel-for-pixel (MAE 0),
showed colored, displaced horizontal strips, and exited cleanly on `q`.
The smoke ran in private user/mount/network/PID namespaces with no external
network interface and verified an unchanged immutable output NAR.  This is
software-rendered Xvfb verification, not physical MIDI, GPU acceleration,
audio, live-camera, or desktop-session verification.  No user profile was
changed or deployed.

### hy3 layout plugin

`(tay packages hy3)` pins `d7e0c58a1116df3d79f24a225f17b988112ca1ad`,
the upstream `hyprpm.toml` match for Hyprland 0.55.4 (`a0136d8c`).
It uses GCC 15 and the compositor's header dependency versions, builds in
Release mode, and retains the plugin's runtime ABI check. The recipe rejects
a different Hyprland package version: update the source pin and rebuild
together with compositor upgrades. Guix's Hyprland package omits hyprpm.

```sh
guix build -L ~/projects/guix-channel/guix hy3 --cores=1 --max-jobs=1
guix install -L ~/projects/guix-channel/guix hy3
```

Load with `plugin = ~/.guix-profile/lib/hyprland/libhy3.so` in hyprland.conf.
Use `workspace = N, layout:hy3` for an individual workspace rather than
changing every workspace's default. The basedbox dotfiles provide active
workspace selection and layout-aware navigation; the package itself does
not alter user configuration.

Verified 2026-09-30: Release build, scoped install and live ABI-checked load;
temporary-window IPC exercise of hy3 tabs, focus, movement and group actions.
Selected offline metadata/derivation lint passed; full lint timed out fetching
the CVE database. The initial debug compilation was terminated; Release
succeeded. Physical key-event and visual layout verification are not claimed.

### Caelestia shell

The Caelestia desktop is packaged as ordinary versioned Guix packages rather
than through upstream's Arch installer.  `caelestia-shell` pins shell commit
`d999d48` (2.5.0) and `caelestia-cli` pins tag `v1.1.3`; the other packages
above are their native, QML, compiler, recorder, and font dependencies.  Guix
already has `quickshell` 0.3.0, but the shell requires the development commit
pinned by its 2.5.0 `flake.lock`, so `quickshell-for-caelestia` builds exactly
that commit with the Qt image-format plugins and `m3shapes` on its QML and
plugin search paths.  Nothing assumes pacman, AUR helpers, `/usr` or
`/etc/xdg` layouts, or systemd units; nothing is started automatically.

The builds are memory-intensive; build locally one job at a time:

```sh
guix build -L ~/projects/guix-channel/guix --cores=1 --max-jobs=1 \
  caelestia-shell caelestia-cli
guix install -L ~/projects/guix-channel/guix caelestia-shell caelestia-cli
```

The compiled shell (QML, plugin, assets, and PAM stacks) is immutable under
`/gnu/store/…-caelestia-shell-2.5.0/share/caelestia-shell`; do not copy it into
`~/.config/quickshell`.  User settings live separately, as upstream intends,
in `~/.config/caelestia/shell.json` (and optional
`~/.config/caelestia/monitors/<monitor>/shell.json`).  Upstream does not create
that file and uses defaults for omitted keys, so keep only the options you
change there, for example in selectively managed dotfiles, rather than
copying upstream's complete example configuration.

`caelestia-shell` is a wrapper that runs the pinned `qs -p` on the store
configuration, with the plugin, M3Shapes, and Qt image plugins on
`QML_IMPORT_PATH`/`QT_PLUGIN_PATH`, the three fonts on `XDG_DATA_DIRS`, a
default `FONTCONFIG_FILE` from Guix's fontconfig (an existing value is kept),
and the shell's helper commands appended to `PATH` so the user's compositor
tools and the system's setuid/pkexec programs take precedence.  Other
arguments are passed to Quickshell, so `caelestia-shell ipc show` and
`caelestia-shell list` work.  Normal control goes through the CLI, which calls
that wrapper:

```sh
caelestia shell -d            # start detached (e.g. from Hyprland exec-once)
caelestia shell -s            # list IPC targets
caelestia shell drawers toggle launcher
caelestia shell -l            # print the shell log
caelestia shell -k            # stop it
caelestia scheme set -n caelestia -f default -m dark
caelestia wallpaper -f ~/Pictures/Wallpapers/example.png
```

Patches, all applied with `--fuzz=0` so upstream context drift fails the build:

- `caelestia-shell-qt-6.9-compat.patch`: Guix provides Qt 6.9.2, while shell
  2.5.0 targets Qt 6.10.  It replaces `QJsonObject::asKeyValueRange()` with
  explicit iteration and includes `<ranges>` where `std::views` is used; it
  replaces Qt 6.10's `DoubleSpinBox` in `StyledSpinBox`/`StepperRow` with a
  scaled integer `SpinBox` that keeps fractional ranges, steps, decimals, and
  locale formatting; it rebuilds `Elevation` so per-corner radii work with Qt
  6.9's single-radius `RectangularShadow`; and it renames the lock-screen
  `id: char`, which Qt 6.9's QML parser rejects.
- `caelestia-shell-guix-pam.patch`: the lock screen's password stack includes
  the system `/etc/pam.d/login` (pam_unix through the setuid `unix_chkpwd`)
  instead of unprivileged `pam_faillock`/`pam_unix`; the optional fprintd and
  howdy stacks load modules from `/run/current-system/profile/lib/security`.
- `caelestia-shell-weather-toggle.patch`: adds the global shell option
  `services.weatherEnabled` (default `true`, keeping upstream behaviour).
  Upstream geolocates through ip-api.com whenever `services.weatherLocation`
  is empty, from startup, the dashboard, and the lock screen's 15-minute
  timer, and `dashboard.showWeather` only hides a tab.  With `false`, no
  ip-api, Nominatim, or Open-Meteo request is made, in-flight replies are
  ignored, fetched weather is cleared, and the lock-screen weather card and
  dashboard weather tab are hidden.
- `caelestia-cli-guix-integration.patch`: accepts Guix's Python 3.12, starts
  and messages the shell through `caelestia-shell` instead of `qs -c
  caelestia`, and finds the shell's `version` helper beside that launcher or
  via `CAELESTIA_LIB_DIR` instead of `/usr/lib/caelestia`.

Build phases also replace `/usr/share/X11/xkb` paths and the terminal-helper
shebang with store paths.  `caelestia-cli` wraps `caelestia` with its runtime
commands (Dart Sass, grim, slurp, fuzzel, cliphist, gpu-screen-recorder, …)
appended to `PATH`; its build check compiles a module-based SCSS theme with
`dart-sass`, which `sassc` cannot parse.

Limitations and cautions:

- Do not run `caelestia install` or `caelestia update`.  They are upstream
  dotfiles operations: they manage Arch packages through pacman/AUR helpers
  and clone, back up, and overwrite `~/.config` content.  They are not Guix
  upgrades and must not run against Guix-managed or dotfile-managed
  configuration.  Upgrade with `guix pull`/`guix package -u` or by bumping this
  channel's pins.
- Caelestia draws its own bar, notifications, OSDs, and lock screen and claims
  the notification D-Bus name.  Do not launch it alongside an existing shell or
  notification daemon (such as DankMaterialShell, mako, or dunst); stop that
  one first.  Switching an existing live session to Caelestia has not been
  done.
- The lock screen UI locks and unlocks over IPC, but password (PAM)
  authentication has not been tested; fprintd and howdy were disabled.
- Power-profile controls use Quickshell's `PowerProfiles` service, which talks
  to `power-profiles-daemon` over the system D-Bus.  The daemon is optional,
  is not installed or configured by these packages, and was absent in testing;
  without it those controls have no effect.
- Direct KMS monitor capture in `gpu-screen-recorder` runs `gsr-kms-server`,
  which needs `CAP_SYS_ADMIN` and otherwise is started through `pkexec`.  That
  requires system configuration (a polkit policy/agent or a privileged
  program in the Guix System configuration); the packages do not install one.
  Portal and window capture do not need it.  NVIDIA encoding needs the
  proprietary driver libraries, which are not provided.
- Runtime verification is a passing isolated smoke test, not a live session.
  The unmodified built package
  `/gnu/store/m5sf2h8g8gvaab1mmbn81vrafnbpl1sc-caelestia-shell-2.5.0`, with
  `caelestia-cli` 1.1.3 and its real wrapper, ran under labwc 0.20.1 (headless)
  and a nested Hyprland 0.55.4 at 1920x1080.  It had a private HOME, XDG
  directories, and session D-Bus, with no system bus or PipeWire.  `caelestia
  shell -d` started one instance and `caelestia shell -k` stopped it.  The
  bar, screen frame, sidebar, launcher, dashboard, toasts, Nexus settings
  window, and lock screen rendered, confirmed by screenshots of the headless
  output, with no missing-glyph boxes.  `caelestia shell drawers toggle
  sidebar|launcher|dashboard`, `toaster info`, `nexus open`, and
  `lock lock`/`unlock` worked over IPC.  A fractional settings stepper
  (0.5–10, step 0.5) changed, clamped at its minimum, and saved to
  `shell.json`.  With `FONTCONFIG_FILE` unset there was no Fontconfig error.
  `caelestia --version` reports shell 2.5.0 revision `d999d48…` distributed by
  GNU Guix (tay channel); Quickshell shows as not on PATH because `qs` is
  reached only through the wrapper.  Warnings seen came from the isolated
  setup: no system bus (UPower, Bluetooth, power profiles), no PipeWire, no
  `~/.face`, missing launcher application icons without an icon theme, and a
  `qt.svg` warning about the `guix-icon.svg` system asset.  Not tested:
  password/PAM authentication, fprintd/howdy, notifications on the user's real
  session bus, clipboard, audio/brightness/network backends, physical input or
  a DRM seat, and live cutover.

## Validate

```sh
make check          # source-count/dry-run, no-network lint, and smoke tests
make check-datamosh-security # package build plus argv-injection smoke test
make check-ffglitch  # native/JSON/Python/QuickJS editing, independent decode and isolated SDL preview
make check-axmud    # Xvfb setup plus namespaced loopback Telnet/GMCP log smoke
make check-blightmud # channel-pinned Guix plus fresh-HOME PTY protocol/TLS smoke
make check-image-tape # Guix-toolchain output-safety regression; no tape hardware
make check-fontra   # local no-graft build plus conversion/workflow/HTTP smoke
make check-ighalsk  # private Xvfb Tk creation/quest/move/save/load state proof
make check-aquesttoofar # private Xvfb SDL intro/help-return/three decline turns
make check-talmudifier # two isolated real XeLaTeX renders, notices and store integrity
make check-rouge    # four real curses PTYs, controls, score reload/MD5 and store integrity
make check-sewer-massacre # original curses game-model movement, CL-STORE restoration and NAR integrity
make check-six-two-one # isolated original SDL arrows, native second-process restore and NAR integrity
make check-umoria   # three real PTY movement/Ctrl-X saves, separate-process resume and exact native character exports
make check-pyro     # two isolated real 80x25 PTYs, four moves each, inventory/help, native log rewrite and NAR integrity
make check-narwharl # six isolated real PTYs, native movement/save/restore/re-save, complete floor items and NAR integrity
make check-rapidbrogue # fresh evidence, original SDL/terminal native save/resume and NAR integrity
make build-fontra   # local --no-grafts --no-offload build
APOUT_FIXTURE=/path/to/cleared-v7-echo APOUT_FIXTURE_PROVENANCE='recorded source' APOUT_FIXTURE_REDISTRIBUTION_CLEARANCE=yes make check-apout
make check-durthang  # headless keyring failure plus loopback Telnet/GMCP map smoke
make check-frostbite # namespaced Xvfb, XDG state, Ruby API, and loopback MUD smoke
make check-go-mud   # fresh-HOME PTY, UTF-8, and Telnet negotiation smoke
make check-godisc   # fresh-HOME tmux workspace plus loopback Telnet smoke
make check-kbtin    # fresh-HOME loopback Telnet/parser smoke
make check-kildclient # Guix Xvfb plus fresh-HOME loopback fake-MUD connection
make check-kmuddy   # fresh-XDG Xvfb plus loopback Telnet/MCCP/MXP smoke
make check-kitty-bitmap # channel-pinned Guix build plus runtime version, Meta/Alt key-encoding, and headless PCF rasterization
make check-kitty-bitmap-oldguix # clean-clone build under a Guix pinned to the pre-2026-08-26 dependency graph
make check-lyntin   # fresh-HOME version and loopback fake-MUD protocol smoke
make check-mmapper  # fresh-XDG Qt plus namespaced local TLS-proxy smoke
make check-mudlet   # namespaced Qt6, Lua modules, multimedia, and loopback Telnet smoke
make check-mudpuppy # fresh-HOME PTY, embedded Python, loopback, and TLS-rejection smoke
make check-notion-river # private XDG session wrapper, IPC path, notices, and immutable-output smoke
make check-mushkin  # namespaced Xvfb, Lua version, MSP traversal, and LuaSec TLS smoke
make check-mushtato # fresh XDG/HOME Xvfb GUI plus loopback Telnet smoke
make check-potato   # fresh-HOME Xvfb, disabled TLS/update, and loopback smoke
make check-pycat    # loopback-only fake-MUD proxy and user world-module smoke
make check-rune     # namespaced PTY Telnet/GMCP/MCCP2 and verified-TLS smoke
make check-secretpathway # fresh-HOME Xvfb Swing plus loopback Telnet smoke
make check-tinyfugue # sanitized fresh-HOME loopback fake-MUD protocol smoke
make check-weidu # namespaced fresh-XDG offline TP2 installation smoke
make check-trebuchet # fresh-HOME Xvfb Tcl/Tk plus loopback protocol smoke
make check-vt05 # isolated Xvfb SDL window plus PTY TERM-contract smoke
make check-sentinelone # no SentinelOne artifact/vendor network; free deps may use substitutes
make lint           # offline/local linters; no source-URL network checks
make lint-cve       # optional network-backed CVE database pass
make build          # build free installable packages (not sentinelone)
make build-sources  # fetch and build all 629 source snapshots
```

`check-kitty-bitmap` uses `guix time-machine -C channels.guix --` by default
because the host Guix may have an older Kitty definition.  Override
`KITTY_BITMAP_GUIX` with an equivalent current Guix command prefix when
needed.  `check-kitty-bitmap-oldguix` clones the channel at the committed
HEAD (uncommitted work is invisible to it, so stage new files first) and
builds `kitty-bitmap` under a Guix pinned to commit 21c3d67, the last
revision whose rolling `kitty` predates `emmansun/base64` and
`sgtdi/fswatcher`, after realizing every channel-private Go module and
`shader-slang` by name;
override that commit with `OLD_GUIX_COMMIT`.

The first signed commit authorizes subsequent channel commits through
`.guix-authorizations`.  The authorized OpenPGP fingerprint is
`997E 2BA6 B523 4026 8A39 87E3 D94F 0A11 ACD7 8333`.
