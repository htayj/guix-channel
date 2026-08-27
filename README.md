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
guix build -L . cadr-fonts-latin
guix install -L . sbcl-qbcl
guix build -L . htayj-ivory-key-source
```

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
| `opencode` | anomalyco/opencode 1.18.18 | Coding-agent command-line interface and terminal UI |
| `opencode-desktop` | anomalyco/opencode desktop 1.18.18 | Electron graphical client with a bundled local backend |
| `claude-code` | Anthropic Claude Code 2.1.233 | Proprietary agentic coding command-line interface |
| `claude-desktop` | Anthropic Claude Desktop 1.30096.1 | Proprietary Electron client for Claude on Linux |
| `hyprland-preview-share-picker` | WhySoBad/hyprland-preview-share-picker | GTK4 Hyprland screencast picker with window previews |
| `sbcl-ivory-key` | ivory-key | Declarative keyboard-layout compiler |
| `manna-cadet` | manna-cadet | Space Cadet keyboard layouts and helper tools |
| `sbcl-qbcl` | qbcl | qBittorrent command-line controller |
| `sbcl-rplaca` | rplaca | Lisp-native LLM chat interface |
| `terminaldrome` | thafaker/TerminalDrome | Rust terminal client for Navidrome and Subsonic servers |
| `image-tape` | larsbrinkhoff/image-tape | Magnetic-tape image reader with safe output handling |
| `apout` | DoctorWkt/Apout 2.4.0 | PDP-11 Unix a.out user-mode emulator; supply a user-owned `APOUT_ROOT` |
| `kitty-bitmap` | Kitty 0.46.2 | Kitty variant that selects native bitmap fonts and encodes XKB Meta as terminal Alt |
| `axmud` | Axmud 2.0.0 | Perl/GTK3 graphical MUD client with GMCP and configurable scripting |
| `blightmud` | Blightmud 5.7.1 | Rust terminal MUD client with Lua, TLS, MCCP2, GMCP, and MSDP |
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

`kitty-bitmap` inherits Guix's current `kitty` package rather than replacing
it.  Its documented AUR-derived Fontconfig patch enables native BDF/PCF font
selection by default.  Such fixed bitmap strikes do not zoom or scale cleanly;
use an available native size and, if needed, an explicit line height.  Its
separate channel patch translates the raw GLFW Meta bit to Alt only at the
child-process encoding boundary: Kitty shortcut matching still sees Meta,
while legacy terminal applications receive ESC-prefixed Alt chords and the
extended keyboard protocol reports Alt.  Physical Alt/XKB bindings are not
changed.  The `check-kitty-bitmap` smoke uses Unscii's non-scalable PCF face
and Kitty's native Fontconfig calls through `kitty +runpy`, without a display
server.  It verifies selection and nonempty glyph-cell rasterization, but not
a live GUI window.

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
guix build -L . --with-source=sentinelone=/path/to/SentinelAgent-Linux-24-3-3-1-x86-64-release-24-3-3_linux_x86_64_v24_3_3_1.deb sentinelone
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

## Validate

```sh
make check          # source-count/dry-run, no-network lint, and smoke tests
make check-datamosh-security # package build plus argv-injection smoke test
make check-axmud    # Xvfb setup plus namespaced loopback Telnet/GMCP log smoke
make check-blightmud # channel-pinned Guix plus fresh-HOME PTY protocol/TLS smoke
make check-image-tape # Guix-toolchain output-safety regression; no tape hardware
APOUT_FIXTURE=/path/to/cleared-v7-echo APOUT_FIXTURE_PROVENANCE='recorded source' APOUT_FIXTURE_REDISTRIBUTION_CLEARANCE=yes make check-apout
make check-durthang  # headless keyring failure plus loopback Telnet/GMCP map smoke
make check-frostbite # namespaced Xvfb, XDG state, Ruby API, and loopback MUD smoke
make check-go-mud   # fresh-HOME PTY, UTF-8, and Telnet negotiation smoke
make check-godisc   # fresh-HOME tmux workspace plus loopback Telnet smoke
make check-kbtin    # fresh-HOME loopback Telnet/parser smoke
make check-kildclient # Guix Xvfb plus fresh-HOME loopback fake-MUD connection
make check-kmuddy   # fresh-XDG Xvfb plus loopback Telnet/MCCP/MXP smoke
make check-kitty-bitmap # channel-pinned Guix build plus source/key-encoding invariants and headless PCF rasterization
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
needed.

The first signed commit authorizes subsequent channel commits through
`.guix-authorizations`.  The authorized OpenPGP fingerprint is
`997E 2BA6 B523 4026 8A39 87E3 D94F 0A11 ACD7 8333`.
