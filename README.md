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
| `hyprland-preview-share-picker` | WhySoBad/hyprland-preview-share-picker | GTK4 Hyprland screencast picker with window previews |
| `sbcl-ivory-key` | ivory-key | Declarative keyboard-layout compiler |
| `manna-cadet` | manna-cadet | Space Cadet keyboard layouts and helper tools |
| `sbcl-qbcl` | qbcl | qBittorrent command-line controller |
| `sbcl-rplaca` | rplaca | Lisp-native LLM chat interface |
| `terminaldrome` | thafaker/TerminalDrome | Rust terminal client for Navidrome and Subsonic servers |
| `image-tape` | larsbrinkhoff/image-tape | Magnetic-tape image reader with safe output handling |
| `kitty-bitmap` | Kitty 0.46.2 | Kitty variant that selects native bitmap fonts and encodes XKB Meta as terminal Alt |
| `ks10-udis` | larsbrinkhoff/ks10-udis | KS10 microcode disassembler and offline fixture |
| `emacs-treesit-sexp` | alexispurslane/treesit-sexp | Tree-sitter-aware structural editing for Emacs |
| `dipc` | doprz/dipc | Offline-built image palette converter |
| `nrl-text-to-phoneme` | greg-kennedy/p5-NRL-TextToPhoneme | NRL text-to-phoneme command and rule tables |
| `you-can-datamosh-on-linux` | happyhorseskull/you-can-datamosh-on-linux | Datamoshing and video-to-GIF commands with argv-safe FFmpeg calls |
| `xq` | sibprogrammer/xq | Offline-built XML and HTML beautifier and extractor |
| `sentinelone` | SentinelOne Linux agent 24.3.3.1 | Proprietary x86_64 agent; authorized installer required |

These eight added installable wrappers do not add source snapshots; the source
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

`image-tape` creates its optional output file safely and propagates write
errors to its exit status.  The `check-image-tape` regression uses Guix's
`tar`, `patch`, `coreutils`, and pure `gcc-toolchain` inputs with a tape shim,
so it exercises output framing and write failures without tape hardware.
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
make check-image-tape # Guix-toolchain output-safety regression; no tape hardware
make check-kitty-bitmap # channel-pinned Guix build plus source/key-encoding invariants and headless PCF rasterization
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
