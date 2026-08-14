# Public project inventory

Inventory date: 2026-08-14.  Scope: public repositories owned by `htayj` and
`drbeefsupreme`, including archived originals.  Each `source` entry installs
the exact pinned Git tree.  The `htayj` entries are exported from
`(tay packages projects)`; the `drbeefsupreme` entries are exported from their
corresponding `(tay packages drbeefsupreme ...)` modules.  Entries in the
additional-package column are current installable project packages; some are
intentionally source-oriented data packages, as described in the README.

## Current source collections

The channel exports 646 unique immutable source packages.  This is a current
collection summary, not a future-package backlog.

| Collection | Public inventory | Source packages | Exclusions and overlap handling |
| --- | ---: | ---: | --- |
| Owned `htayj` and `drbeefsupreme` originals | 53 | 51 | Two empty owned repositories have no branch or commit.  Public forks are excluded. |
| Lars Brinkhoff historical-computing inventory | 192 relevant | 177 | Three empty repositories are omitted.  Twelve canonical PDP-10 redirects or duplicates are deduplicated against the PDP-10 collection.  The archived `tv11` source remains preserved, with no issue follow-up. |
| PDP-10 organization inventory | 68 relevant originals | 68 | Nine archived sources remain available as snapshots.  Forks are excluded. |
| `htayj` starred public repositories | 452 | 350 | Server/self-hosting software, archived/reference material, and source-origin or package-name overlaps/collisions are excluded. |

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
