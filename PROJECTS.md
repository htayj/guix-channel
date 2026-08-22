# Public project inventory

Inventory date: 2026-08-14.  Scope: public repositories owned by `htayj` and
`drbeefsupreme`, including archived originals.  Each `source` entry installs
the exact pinned Git tree.  The `htayj` entries are exported from
`(tay packages projects)`; the `drbeefsupreme` entries are exported from their
corresponding `(tay packages drbeefsupreme ...)` modules.  Entries in the
additional-package column are current installable project packages; some are
intentionally source-oriented data packages, as described in the README.

## Current source collections

The channel exports 629 unique immutable source packages.  This is a current
collection summary, not a future-package backlog.

| Collection | Public inventory | Source packages | Exclusions and overlap handling |
| --- | ---: | ---: | --- |
| Owned `htayj` and `drbeefsupreme` originals | 53 | 51 | Two empty owned repositories have no branch or commit.  Public forks are excluded. |
| Lars Brinkhoff historical-computing inventory | 192 relevant | 177 | Three empty repositories are omitted.  Twelve canonical PDP-10 redirects or duplicates are deduplicated against the PDP-10 collection.  The archived `tv11` source remains preserved, with no issue follow-up. |
| PDP-10 organization inventory | 68 relevant originals | 68 | Nine archived sources remain available as snapshots.  Forks are excluded. |
| `htayj` starred public repositories | 452 | 333 | Server/self-hosting software, archived/reference material, and source-origin or package-name overlaps/collisions are excluded, including 17 additional clear server/self-host removals. |

Source snapshots are preservation inputs, not assertions that a repository is
host-installable software.  Their package definitions and hashes do not grant
permission to redistribute upstream material; preserve and review upstream
license terms independently.

## htayj owned originals

| Repository | Source package | Additional package | License recorded | State |
| --- | --- | --- | --- | --- |
| aptitude-custom-aliases | `htayj-aptitude-custom-aliases-source` | `aptitude-custom-aliases` | unknown | archived |
| bell-museum | `htayj-bell-museum-source` | `bell-museum` | MIT | active |
| CADR-fonts | `htayj-cadr-fonts-source` | `cadr-fonts-latin`, `cadr-fonts-symbols` | BSD-3-Clause | active |
| computer-builder | `htayj-computer-builder-source` | `computer-builder` | AGPL-3.0-or-later | active |
| computus | `htayj-computus-source` | `rust-computus` | mixed; review required | active |
| custom-nix-pkgs | `htayj-custom-nix-pkgs-source` | `custom-nix-pkgs` | unknown | active |
| Databases-Team75 | `htayj-databases-team75-source` | `databases-team75` | unknown | active |
| DEC-Fonts | `htayj-dec-fonts-source` | `dec-fonts` | MIT | active |
| doom_emacs.d | `htayj-doom-emacs-d-source` | — | unknown | active |
| dorxng-mcp | `htayj-dorxng-mcp-source` | `dorxng-mcp` | MIT declaration | active |
| dotfiles | `htayj-dotfiles-source` | — | unknown | active |
| emacs-illiterate | — | — | unknown | empty; no branch or commit |
| flaghack | `htayj-flaghack-source` | — | AGPL-3.0-or-later | active |
| genera-fonts | `htayj-genera-fonts-source` | `genera-fonts-latin`, `genera-fonts-symbols` | mixed; required notice | active |
| gimp-stipple-script | `htayj-gimp-stipple-script-source` | — | unknown | active |
| gmatr | `htayj-gmatr-source` | — | unknown | archived |
| gramps-effect-mcp | `htayj-gramps-effect-mcp-source` | — | unknown | active |
| htayj | `htayj-profile-source` | — | unknown | active |
| hyprland-dot | `htayj-hyprland-dot-source` | — | unknown | active |
| ivory-key | `htayj-ivory-key-source` | `sbcl-ivory-key` | GPL-3.0-only | active |
| lisp-machine-container-museum | `htayj-lisp-machine-container-museum-source` | — | unknown | active |
| manna-cadet | `htayj-manna-cadet-source` | `manna-cadet` | MIT | active |
| moby-mcp | `htayj-moby-mcp-source` | — | AGPL-3.0-only | active |
| nix | `htayj-nix-source` | — | unknown | active |
| os-directory | `htayj-os-directory-source` | — | unknown | active |
| qbcl | `htayj-qbcl-source` | `sbcl-qbcl` | GPL-2.0-or-later declaration | active |
| rplaca | `htayj-rplaca-source` | `sbcl-rplaca` | AGPL-3.0-only | active |
| slophack | `htayj-slophack-source` | — | AGPL-3.0-or-later declaration | archived |
| Sockets-Programming-Homework | `htayj-sockets-programming-homework-source` | — | unknown | active |
| src | `htayj-src-source` | — | unknown | active |
| stumpwm-config | `htayj-stumpwm-config-source` | — | unknown | active |
| SubgeniusFortunes | `htayj-subgenius-fortunes-source` | — | unknown | active |
| Sublime-LC2200 | `htayj-sublime-lc2200-source` | — | unknown | active |
| Taydemacs | `htayj-taydemacs-source` | — | unknown | active |
| vexillomancy-matrix-custom | `htayj-vexillomancy-matrix-custom-source` | — | unknown | active |
| waybar-dot | `htayj-waybar-dot-source` | — | unknown | active |
| www-vexillomancy-org | `htayj-www-vexillomancy-org-source` | — | AGPL-3.0-only | active |
| yaourt-custom-aliases | `htayj-yaourt-custom-aliases-source` | — | unknown | active |

## drbeefsupreme owned originals

This current disposition contains 15 owned originals: 14 nonempty source
packages and the empty `flaghack` repository.  It is an inventory, not a
future-package backlog.

| Repository | Source package | Additional package | License recorded | State |
| --- | --- | --- | --- | --- |
| dotfiles | `drbeefsupreme-dotfiles-source` | — | unknown; no explicit redistribution permission | active |
| flaghack | — | — | unknown; no explicit redistribution permission | empty; no branch or commit |
| flaghack-infinity | `drbeefsupreme-flaghack-infinity-source` | — | unknown; no explicit redistribution permission | active |
| flaghack2 | `drbeefsupreme-flaghack2-source` | — | unknown; no explicit redistribution permission | active |
| flaghack3 | `drbeefsupreme-flaghack3-source` | — | unknown; no explicit redistribution permission | active |
| flags | `drbeefsupreme-flags-source` | — | unknown; no explicit redistribution permission | active |
| ghostty-vexillomancy | `drbeefsupreme-ghostty-vexillomancy-source` | — | unknown; no explicit redistribution permission | active |
| qyron | `drbeefsupreme-qyron-source` | — | unknown; no explicit redistribution permission | active |
| qyron-teensy | `drbeefsupreme-qyron-teensy-source` | — | unknown; no explicit redistribution permission | active |
| qyron-tui | `drbeefsupreme-qyron-tui-source` | — | unknown; no explicit redistribution permission | active |
| rlox | `drbeefsupreme-rlox-source` | — | unknown; no explicit redistribution permission | active |
| sign-of-itself | `drbeefsupreme-sign-of-itself-source` | — | unknown; no explicit redistribution permission | active |
| swarm | `drbeefsupreme-swarm-source` | — | unknown; no explicit redistribution permission | active |
| tassh | `drbeefsupreme-tassh-source` | — | MIT | active |
| test-repo | `drbeefsupreme-test-repo-source` | — | unknown; no explicit redistribution permission | active |

## Excluded forks

The `htayj` public forks `abtop`, `awesome-fonts`, `docker-rtorrent-pyro`,
`pi-dynamic-workflows`, `prezto`, `q4`, `react-blessed`,
`rms-support-letter.github.io`, `stickerpicker`, and `winamp` are not packaged.
The `drbeefsupreme` public forks `SmartMatrix`, `arduino-simple-rpc`,
`documentation`, `fib-anyon`, `hyperbolic_canvas`, `kalshi-trade-rs`,
`libnotcurses-sys`, `nockchain`, `pyduino`, `simpleRPC`, and `trezor-agent`
are likewise excluded.  Their upstream maintainers remain the appropriate
source for Guix packaging and release metadata.

## Additional installable packages

These reviewed applications are installable packages outside the owned-source
inventory above.  They are included in the channel build inventory when their
Guix definitions enumerate and pass the package dry-run.

These installable packages do not add source snapshots; the channel
source collection remains 629 packages.  `atarist-font` corrects the upstream
BDF glyph-count header before generating a PCF copy.  `image-tape` uses safe
output-file creation and propagates write failures; its `check-image-tape`
regression uses Guix's tar, patch, coreutils, and pure gcc-toolchain inputs
with a tape shim, so no tape hardware is required.  The datamosh wrapper uses
argv-based FFmpeg calls to prevent shell injection, with a dedicated security
smoke test.  `dipc` and `xq` keep their exact pinned offline Rust and Go
dependency graphs.

`sentinelone` is the exception to the default build inventory: it is checked
for enumeration, dry-run, and lint, but its authorized proprietary source must
be supplied locally.  The channel's package-definition code is
GPL-3.0-or-later; that license does not license the SentinelOne agent.
Building requires `guix build -L . --with-source=sentinelone=/path/to/authorized-x86_64.deb sentinelone`, which
copies the authorized installer into the local Guix store.  The package output
is non-substitutable, but that alone does not prevent proprietary source or
output paths from being served by `guix publish`; isolate, remove, or ACL those
paths and never publish them.  Management tokens must never enter the
repository or Guix store, and the privileged service/state needed at runtime is
outside this channel's implementation and validation scope.  `make
check-sentinelone` runs only a synthetic smoke test: it needs no SentinelOne
artifact or SentinelOne/vendor network access, although realizing free Guix
dependencies may use configured substitutes.

`kitty-bitmap` inherits the current Guix `kitty` package and its full upstream
dependency graph; it does not replace the regular `kitty` package.  It carries
the AUR `kitty-bitmap` Fontconfig-default change with recorded provenance,
plus a separate channel-local child-encoding patch that turns raw XKB Meta
into terminal Alt while leaving Kitty shortcut matching and physical Alt
unchanged.  Bitmap-font verification is deliberately headless: Unscii PCF
selection and nonempty glyph-cell rasterization are tested, but a live GUI
window is not claimed.

The MUD-client additions are end-user applications, not game servers.
`axmud`, `kildclient`, `kmuddy`, `mmapper`, `mushtato`, `potato`, `secretpathway`, and `trebuchet`
are graphical clients; `go-mud`, `lyntin`, `tinyfugue`, `godisc`, and `kbtin`
provide text-mode workflows; `blightmud`, `durthang`, and `mudpuppy` are Rust
TUIs; `rune` is a pure-Go TUI with an embedded Lua interpreter; and
`pycat` is a modular terminal proxy.  Their
channel smokes use fresh homes and loopback fake-MUD/frontend sockets.
KildClient, SecretPathway, and Trebuchet run under Guix's Xvfb; GoDisc exercises
a real tmux workspace; Durthang checks GMCP map persistence and absent-keyring
failure; and Pycat checks safe sibling imports and live world reload.

| Package | Upstream | Installed contents |
| --- | --- | --- |
| `atarist-font` | ntwk/atarist-font | Atari ST 8x16 Unicode BDF and generated PCF font |
| `hyprland-preview-share-picker` | `WhySoBad/hyprland-preview-share-picker` | GTK4 Hyprland screencast picker with window previews |
| `terminaldrome` | `thafaker/TerminalDrome` | Rust terminal client for Navidrome and Subsonic servers |
| `image-tape` | `larsbrinkhoff/image-tape` | Magnetic-tape image reader with safe output handling |
| `kitty-bitmap` | `kovidgoyal/kitty` | Native bitmap-font Kitty variant with XKB Meta-to-terminal-Alt encoding |
| `axmud` | `axcore/axmud` | Perl/GTK3 graphical MUD client with GMCP and configurable scripting |
| `blightmud` | `Blightmud/Blightmud` | Rust terminal MUD client with Lua, TLS, MCCP2, GMCP, and MSDP |
| `durthang` | `Pommersche92/durthang` | Rust TUI MUD client with TLS, GMCP, automapping, and Secret Service integration |
| `godisc` | `DavidSatimeWallin/godisc` | Discworld terminal client and tmux workspace launcher |
| `go-mud` | `mudclient/go-mud` | UTF-8 terminal MUD client with Lua scripting |
| `kbtin` | `kilobyte/kbtin` | TinTin-compatible terminal MUD client with TLS and MCCP |
| `kildclient` | KildClient | GTK MUD client with Perl scripting and plugins |
| `kmuddy` | `KDE/kmuddy` | KDE MUD client with scripting, mapping, MCCP, MSP, and MXP |
| `ks10-udis` | `larsbrinkhoff/ks10-udis` | KS10 microcode disassembler and offline fixture |
| `lyntin` | Lyntin V | Text-mode Python MUD client and module API |
| `mmapper` | `MUME/MMapper` | Qt graphical MUME client, local TLS proxy, and empty-map editor |
| `mudpuppy` | `mudpuppy-rs/mudpuppy` | Rust terminal MUD client with embedded Python scripting and TLS |
| `mushtato` | `N0NJY/mushtato` | Python/Qt MUSH client with sandboxed scripting, TLS, and SSH |
| `potato` | `potatomushclient/potato` | Tcl/Tk graphical MUSH client with TLS deliberately disabled |
| `pycat` | `cizra/pycat` | Modular Python MUD proxy client and world-module framework |
| `rune` | `mmcdole/rune` | Pure-Go terminal MUD client with Lua, TLS, MCCP2, and GMCP |
| `secretpathway` | `mhahnFr/SecretPathway` | Java/Swing MUD client with an LPC source editor |
| `tinyfugue` | `ingwarsw/tinyfugue` | Scriptable terminal MUD client with TLS, MCCP, GMCP, and IPv6 |
| `trebuchet` | `fuzzball-muck/trebuchet` | Tcl/Tk graphical MUD, MUCK, and MUSH client with MCP support |
| `emacs-treesit-sexp` | `alexispurslane/treesit-sexp` | Tree-sitter-aware structural editing for Emacs |
| `dipc` | `doprz/dipc` | Offline-built image palette converter |
| `nrl-text-to-phoneme` | `greg-kennedy/p5-NRL-TextToPhoneme` | NRL text-to-phoneme command and rule tables |
| `you-can-datamosh-on-linux` | `happyhorseskull/you-can-datamosh-on-linux` | Datamoshing and video-to-GIF commands with argv-safe FFmpeg calls |
| `xq` | `sibprogrammer/xq` | Offline-built XML and HTML beautifier and extractor |
| `sentinelone` | SentinelOne Linux agent 24.3.3.1 | Proprietary x86_64 agent; authorized `.deb` required via `--with-source` |
