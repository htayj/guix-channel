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
| `terminaldrome` | thafaker/TerminalDrome | Rust terminal client for Navidrome and Subsonic servers |
| `image-tape` | larsbrinkhoff/image-tape | Magnetic-tape image reader with safe output handling |
| `apout` | DoctorWkt/Apout 2.4.0 | PDP-11 Unix a.out user-mode emulator; supply a user-owned `APOUT_ROOT` |
| `kitty-bitmap` | Kitty 0.49.1 (pinned tag `v0.49.1`) | Kitty variant that selects native bitmap fonts and encodes XKB Meta as terminal Alt |
| `halloy` | squidowl/halloy 2026.8 | Upstream x86_64 Linux desktop IRC client release with Wayland/X11 runtime libraries |
| `shader-slang` | shader-slang/slang 2026.14.1 | `slangc` Slang shader compiler and libraries; build dependency of `kitty-bitmap` |
| `axmud` | Axmud 2.0.0 | Perl/GTK3 graphical MUD client with GMCP and configurable scripting |
| `aquarium-arena` | valrak/AquariumRL 0.4 | Underwater pygame arena roguelike with XDG high scores |
| `atlas-warriors` | lkingsford/AtlasWarriors alpha-009 | Graphical fantasy roguelike with XDG state |
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
make check-axmud    # Xvfb setup plus namespaced loopback Telnet/GMCP log smoke
make check-blightmud # channel-pinned Guix plus fresh-HOME PTY protocol/TLS smoke
make check-image-tape # Guix-toolchain output-safety regression; no tape hardware
make check-fontra   # local no-graft build plus conversion/workflow/HTTP smoke
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
