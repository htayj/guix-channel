# Taylor's Guix channel

A personal GNU Guix channel for desktop tools, coding assistants, historical
computing, fonts, MUD clients, and a large collection of roguelikes. It also
preserves reviewed repositories as immutable source snapshots. Packages are
pinned; adding the channel does not start services or change your desktop.

## Contents

- [Add the channel](#add-the-channel)
- [Install, build, or try a package](#install-build-or-try-a-package)
- [Programs](#programs)
  - [Desktop, window layouts and input](#desktop-window-layouts-and-input)
  - [AI and coding assistants](#ai-and-coding-assistants)
  - [Editors and Emacs tools](#editors-and-emacs-tools)
  - [Audio, video, fonts and documents](#audio-video-fonts-and-documents)
  - [Fonts and keyboard layouts](#fonts-and-keyboard-layouts)
  - [Browsers](#browsers)
  - [MUD clients](#mud-clients)
  - [Historical computing and languages](#historical-computing-and-languages)
  - [Roguelikes and other games](#roguelikes-and-other-games)
    - [NetHack, Hack and Rogue variants](#nethack-hack-and-rogue-variants)
    - [Crawl and Brogue variants](#crawl-and-brogue-variants)
    - [Other terminal and graphical games](#other-terminal-and-graphical-games)
  - [Programming libraries and developer tools](#programming-libraries-and-developer-tools)
  - [Other utilities and game launchers](#other-utilities-and-game-launchers)
  - [Source-oriented collections](#source-oriented-collections)
  - [Desktop support libraries](#desktop-support-libraries)
  - [Local acceptance and restricted packages](#local-acceptance-and-restricted-packages)
- [Source snapshots and research](#source-snapshots-and-research)
  - [Research and definitions outside the normal build inventory](#research-and-definitions-outside-the-normal-build-inventory)
- [Caveats](#caveats)
- [Documentation and contributing](#documentation-and-contributing)
- [License](#license)

## Add the channel

Add this entry to `~/.config/guix/channels.scm`, retaining your other channels:

```scheme
(use-modules (guix channels))

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

Then run `guix pull`. The signed introduction's key is published on the
`keyring` branch. The channel declares an authenticated Nonguix dependency in
[`.guix-channel`](.guix-channel); some entries are proprietary or binary-assisted,
so this is not a free-software-only channel.

[Forgejo](https://192.168.7.121/tay/guix-channel) is the authoritative repository
and issue tracker (LAN/tailnet access). The public GitHub URL above is the code
push mirror, convenient for users outside that network. Authorized local users
can substitute `ssh://git@192.168.7.121/tay/guix-channel.git` while keeping the
same branch and introduction. A local uncommitted change is not yet published
through either channel URL.

## Install, build, or try a package

After `guix pull`, use ordinary Guix commands:

```sh
guix search nlarn
guix install nlarn
guix build nlarn              # realize an output without installing it
guix shell nlarn -- nlarn     # try it in a temporary environment
```

To use a checkout immediately, without pulling it into your Guix:

```sh
git clone https://github.com/htayj/guix-channel
cd guix-channel
guix install -L guix nlarn
guix build -L guix cadr-fonts-latin
guix build -L guix htayj-ivory-key-source
```

Modules live under `guix/`, so the load path is **`-L guix`**, not `-L .`.
When a package name also exists in upstream Guix, select the channel version
explicitly. For example:

```sh
guix install -L guix -e '(@ (tay packages praat) praat)'
guix build -L guix praat@7.0.02
```

CalcRogue preserves the upstream 32-bit VM/C ABI and is defined only for
`i686-linux`, even on an x86_64 workstation. Select that system explicitly:

```sh
guix build -L guix -s i686-linux calcrogue
guix install -L guix -s i686-linux calcrogue
```

`make build-calcrogue` supplies the same explicit system selection. The default
native `make build` and `make check` build dry-run exclude this i686-only
package; it remains in the installable inventory and lint lists.

Running it requires a Linux kernel with IA32 execution support; native execution
was observed on the acceptance host, not established for every x86_64 system.
See the [CalcRogue receipt](ACCOUNTING.md#calcrogue--native-i686-gameplay-and-save-continuity-2026-10-09)
for the source-build invocation, state layout and remaining lint gates.

Builds can be memory-intensive. Package-specific instructions document tested
flags and runtime setup; for example, [Fontra](ACCOUNTING.md#installable-packages)
uses a locally verified `--no-grafts --no-offload` path, while Hyprland plugins
must match the compositor ABI. Installation alone does not configure a service,
load a plugin, choose a font, connect to a MUD, or authenticate an AI provider.

## Programs

Versions below are the package definition's version, including snapshot
suffixes where used—not guesses at an upstream release. The inherited
DankMaterialShell variant is 0.5.1 on the documented/selected Guix base; its
version follows that base if a different Guix revision is selected. Package names link to
implementation metadata. The catalog covers the declared top-level build
inventory, including older deliveries; private npm/Python/Java/Rust/Haskell
closures are deliberately not expanded into user-facing tables.

**Status:** **Verified** means the existing accounting records an exercised
package-specific path, with the limits in that receipt. **Defined** means a
package is included in the build inventory, but this guide does not establish
complete native acceptance. Neither status alone claims the current checkout
has been published, every feature tested, or the program deployed. Explicit
publication, source-required, and build gates appear in the final table.

### Desktop, window layouts and input

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`azurra-gtk-theme`](guix/tay/packages/azurra.scm) | `4.2.7` | Azurra theme for GTK 3 applications | Defined |
| [`caelestia-cli`](guix/tay/packages/caelestia-cli.scm) | `1.1.3` | `caelestia` shell control, colour scheme, screenshot, recording, and picker command | Verified isolated IPC |
| [`caelestia-panes`](guix/tay/packages/caelestia-panes.scm) | `1.0.0` | Persistent native SilverBullet reader, Memos capture and glirc desktop panes | Verified surface; login-gated workflows |
| [`caelestia-shell`](guix/tay/packages/caelestia-shell.scm) | `2.5.0` | Quickshell desktop shell, `Caelestia` QML plugin, and `caelestia-shell` launcher | Verified isolated surface |
| [`dank-material-shell-shell-only`](guix/tay/packages/dank-material-shell.scm) | `0.5.1` | Full upstream shell with external GTK/Qt icon mutation guarded by the user's settings and `DMS_DISABLE_MATUGEN` | Defined |
| [`flex-launcher`](guix/tay/packages/flex-launcher.scm) | `2.2-0.cc0d987` | HTPC and gamepad application launcher | Defined |
| [`halloy`](guix/tay/packages/halloy.scm) | `2026.8` | Upstream x86_64 Linux desktop IRC client release with Wayland/X11 runtime libraries | Defined |
| [`hy3`](guix/tay/packages/hy3.scm) | `0.55.4-0.d7e0c58` | Manual tree layout and tabbed groups, `lib/hyprland/libhy3.so` | Verified ABI load and IPC |
| [`hyprland-dualmaster`](guix/tay/packages/hyprland-dualmaster.scm) | `0.55.4-0.1.1` | Coupled centered masters, adjustable 60% default and side stacks, `lib/hyprland/libdualmaster.so` | Verified ABI/input path |
| [`hyprland-preview-share-picker`](guix/tay/packages/hyprland-preview-share-picker.scm) | `0.2.1-9.e2f30ff` | GTK4 Hyprland screencast picker with window previews | Defined |
| [`input-remapper`](guix/tay/packages/input-remapper.scm) | `2.2.1-0.3b519a1` | Remap input device buttons and axes | Verified |
| [`kbredir`](guix/tay/packages/kbredir.scm) | `0.9` | VT220, Linux-console, xev, XSendEvent, and XTEST keyboard-event redirects | Verified |
| [`keymapper`](guix/tay/packages/keymapper.scm) | `5.6.0-0.2ddd5cc` | Context-aware keyboard and mouse remapper | Verified |
| [`kitty-bitmap`](guix/tay/packages/kitty-bitmap.scm) | `0.49.1` | Kitty variant that selects native bitmap fonts and encodes XKB Meta as terminal Alt | Verified headless path |
| [`notion-river`](guix/tay/packages/notion-river.scm) | `0.6.0-14.ge79dea3` | Static tiling window manager for a separately supplied River 0.4.x+ compositor | Defined |
| [`wired`](guix/tay/packages/wired.scm) | `0.10.7` | Configurable X11 desktop notification daemon | Verified |

### AI and coding assistants

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`ai-code-interface-el`](guix/tay/packages/ai-code-interface-el.scm) | `1.930` | Emacs interface for AI coding assistants | Verified |
| [`buzz`](guix/tay/packages/buzz.scm) | `0.5.23` | Local-first desktop workspace for humans and AI agents | Defined |
| [`chatgpt-el`](guix/tay/packages/chatgpt-el.scm) | `0.2-0.51c658a` | Emacs ChatGPT frontend requiring the user-provided lwe CLI | Verified |
| [`claude-code`](guix/tay/packages/claude-code.scm) | `2.1.233` | Proprietary agentic coding command-line interface | Defined |
| [`claude-desktop`](guix/tay/packages/claude-desktop.scm) | `1.30096.1` | Proprietary Electron client for Claude on Linux | Defined |
| [`dorxng-mcp`](guix/tay/packages/dorxng-mcp.scm) | `0.1.0` | MCP server and its packaged Python dependencies | Defined |
| [`eca`](guix/tay/packages/editor-code-assistant-eca.scm) | `0.154.0` | Editor Code Assistant JVM server and CLI | Verified |
| [`eca-emacs`](guix/tay/packages/eca-emacs.scm) | `0.0.1-0.f145505` | Emacs client for Editor Code Assistant | Verified |
| [`emacs-aidermacs`](guix/tay/packages/aidermacs.scm) | `1.11-0.2fc9939` | Emacs extension for a separately supplied Aider; Aider itself not packaged | Verified offline terminal prompt-file path, no Aider/model session; [limits](ACCOUNTING.md#aidermacs--verified-native-emacs-extension-path) |
| [`emigo`](guix/tay/packages/emigo.scm) | `0.5-0.91d122a` | Emacs coding assistant with local Python backend | Verified local backend; no provider/chat proof |
| [`hermes-agent`](guix/tay/packages/hermes-agent.scm) | `0.21.5` | Hermes CLI, JSON-RPC and WebSocket agent backend | Verified |
| [`hermes-desktop`](guix/tay/packages/hermes-desktop.scm) | `2026.9.24` | Hermes Electron desktop with the packaged local backend | Verified local desktop; no model calls |
| [`oh-my-opencode-slim`](guix/tay/packages/oh-my-opencode-slim.scm) | `2.2.13` | OpenCode multi-agent tools and skills plugin | Verified |
| [`oh-my-opencode-slim-companion`](guix/tay/packages/oh-my-opencode-slim-companion.scm) | `0.1.3` | Desktop visualization of local Slim agent state | Verified |
| [`opencode`](guix/tay/packages/opencode.scm) | `1.18.18` | Coding-agent command-line interface and terminal UI | Defined |
| [`opencode-desktop`](guix/tay/packages/opencode-desktop.scm) | `1.18.18` | Electron graphical client with a bundled local backend | Defined |
| [`pi-coding-agent`](guix/tay/packages/pi-coding-agent.scm) | `0.84.2` | Pi coding-agent CLI/TUI with sessions and RPC | Verified |
| [`sbcl-rplaca`](guix/tay/packages/rplaca.scm) | `0.1.0` | Lisp-native LLM chat interface | Defined |
| [`squad`](guix/tay/packages/squad.scm) | `0.13.0` | AI-team SDK and CLI | Verified |

### Editors and Emacs tools

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`emacs-cl`](guix/tay/packages/emacs-cl.scm) | `0-19e950e` | Common Lisp implemented in Emacs Lisp | Verified |
| [`emacs-eaf-emacs-application-framework`](guix/tay/packages/emacs-application-framework.scm) | `0-0.5fe1a6c` | Emacs Application Framework core and Qt demo | Verified |
| [`emacs-forth-mode`](guix/tay/packages/forth-mode.scm) | `0-4450a3a` | Programming language mode for Forth | Verified |
| [`emacs-mentor-pinned`](guix/tay/packages/mentor.scm) | `0.5-0.ed42ae8` | Distinct pinned Emacs rTorrent frontend with the post-0.5 tracker library | Verified |
| [`emacs-org-popup-posframe`](guix/tay/packages/org-popup-posframe.scm) | `0.0.1-0.d39cb7c` | Show Org popup buffers in posframes | Verified |
| [`emacs-pbui`](guix/tay/packages/pbui.scm) | `0.1-0.19a606d` | Presentation-based Emacs commands with Dired, Org, calendar, mail and inspector companions | Verified native Dired multi-file copy and edit/save/reopen; [limits](ACCOUNTING.md#pbui--verified-native-emacs-presentations) |
| [`emacs-treesit-sexp`](guix/tay/packages/treesit-sexp.scm) | `0-c9aafc4` | Tree-sitter-aware structural editing for Emacs | Defined |
| [`emacs-vim-region`](guix/tay/packages/vim-region.scm) | `0-7c4a99c` | GPL-3.0-or-later Vim-style region selection/editing with propagated expand-region | Verified |
| [`gened`](guix/tay/packages/gened.scm) | `0-0.0d847a3` | Original Common Lisp/McCLIM text editor | Verified native edit/save path |
| [`liquid`](guix/tay/packages/liquid.scm) | `2.1.2-0.045f587` | Modal terminal text editor written in Clojure | Verified |
| [`org-mind-map`](guix/tay/packages/org-mind-map.scm) | `0.4-0.95347b2` | GPL-3.0-or-later original Emacs Org graph exporter, propagated Dash and store-bound Graphviz | Verified |

### Audio, video, fonts and documents

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`dicom2mesh`](guix/tay/packages/dicom2mesh.scm) | `0.823-0.c552b4f` | Convert DICOM or PNG image volumes into 3D surface meshes | Verified |
| [`dipc`](guix/tay/packages/dipc.scm) | `1.2.0` | Offline-built image palette converter | Defined |
| [`ffglitch`](guix/tay/packages/ffglitch.scm) | `0.10.2` | Scriptable bitstream editing, glitch encoding and live SDL preview | Verified |
| [`fontra`](guix/tay/packages/fontra.scm) | `2026.9.0` | Browser-based font editor, local server, conversion and workflow commands | Verified |
| [`gpu-screen-recorder`](guix/tay/packages/caelestia-cli.scm) | `6.1.3` | VA-API/Vulkan screen recorder and `gsr-kms-server` | Defined |
| [`kraken`](guix/tay/packages/kraken.scm) | `7.1` | OCR command-line tools for historical and multilingual documents | Verified offline CPU OCR path |
| [`ludviglundgren-qbittorrent-cli`](guix/tay/packages/ludviglundgren-qbittorrent-cli.scm) | `2.3.0` | Go qBittorrent Web API client; commands `qbt` and `qbittorrent-cli` | Verified isolated daemon path |
| [`natron`](guix/tay/packages/natron.scm) | `2.6.0-0.20260724` | Core node-graph compositor and NatronRenderer; normal plugin collections/OCIO configs not bundled | Verified empty GUI and external OFX render; [limits](ACCOUNTING.md#natron--verified-core-host-path) |
| [`nrl-text-to-phoneme`](guix/tay/packages/nrl-text-to-phoneme.scm) | `0-f99c64a` | NRL text-to-phoneme command and rule tables | Defined |
| [`persephil`](guix/tay/packages/persephil.scm) | `1.0.0-0.1e10afb` | Export legacy PhiloLogic Latin HTML search results to dated XLSX workbooks | Verified native workbook; [receipt and open lint gate](ACCOUNTING.md#persephil--legacy-philologic-html-to-xlsx-2026-10-09) |
| [`praat`](guix/tay/packages/praat.scm) | `7.0.02` | GTK speech analysis/editor and batch scripting | Verified analysis and GTK path |
| [`pyrosimple`](guix/tay/packages/pyrosimple.scm) | `2.14.2-16.d24655a` | Command-line tools for rTorrent and BitTorrent metainfo files | Verified |
| [`sbcl-qbcl`](guix/tay/packages/qbcl.scm) | `0.1.0` | qBittorrent command-line controller | Defined |
| [`soundthread`](guix/tay/packages/soundthread.scm) | `0.0.0-0.a33198a` | Node-graph audio application; CDP host integration unverified | Verified Dummy-driver audio path |
| [`talmudifier`](guix/tay/packages/talmudifier.scm) | `1.1.0-1.1f23206` | Offline XeLaTeX rendering of the bundled Talmud-style example | Verified |
| [`terminaldrome`](guix/tay/packages/terminaldrome.scm) | `0.7.4` | Rust terminal client for Navidrome and Subsonic servers | Defined |
| [`you-can-datamosh-on-linux`](guix/tay/packages/you-can-datamosh-on-linux.scm) | `0-bc4df09` | Datamoshing and video-to-GIF commands with argv-safe FFmpeg calls | Defined |

### Fonts and keyboard layouts

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`amstelvar`](guix/tay/packages/amstelvar.scm) | `1.001` | Parametric variable serif font family | Verified |
| [`atarist-font`](guix/tay/packages/atarist-font.scm) | `0-52b91b2` | Atari ST 8x16 Unicode BDF and generated PCF font | Defined |
| [`cadr-fonts-latin`](guix/tay/packages/cadr-fonts-latin.scm) | `0.1.2` | Unicode BDF and OTB Latin fonts | Defined |
| [`cadr-fonts-symbols`](guix/tay/packages/cadr-fonts-symbols.scm) | `0.1.2` | Unicode BDF and OTB specialty fonts | Defined |
| [`dec-fonts`](guix/tay/packages/fonts.scm) | `0.1.0-alpha.2` | BDF, OTB, and Linux-console PSF fonts | Defined |
| [`font-material-symbols-rounded`](guix/tay/packages/caelestia-shell.scm) | `2.972` | Material Symbols Rounded variable icon font | Defined |
| [`font-nerd-caskaydia-cove`](guix/tay/packages/caelestia-shell.scm) | `3.5.1` | CaskaydiaCove Nerd Font | Defined |
| [`font-rubik`](guix/tay/packages/caelestia-shell.scm) | `2.300` | Rubik variable font | Defined |
| [`genera-fonts-latin`](guix/tay/packages/fonts.scm) | `0.1.3` | Unicode BDF and OTB Latin fonts | Build verified |
| [`genera-fonts-symbols`](guix/tay/packages/fonts.scm) | `0.1.3` | Unicode BDF and OTB specialty fonts | Build verified |
| [`manna-cadet`](guix/tay/packages/manna-cadet.scm) | `20260809-1.e5f7e81` | Space Cadet keyboard layouts and helper tools | Defined |
| [`sbcl-ivory-key`](guix/tay/packages/ivory-key.scm) | `0.1.0` | Declarative keyboard-layout compiler | Defined |

### Browsers

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`browsh`](guix/tay/packages/browsh.scm) | `1.8.2` | Source-built terminal web browser with locally generated fonts, embedded unsigned extension and packaged Firefox ESR | Verified ordinary offline URL/link navigation, text input, HTML form submission and zero-status quit; #96 OPEN (no-updater/source-archive lint gates; [receipt and limits](ACCOUNTING.md#browsh--ordinary-native-terminal-browsing-2026-10-09)) |

### MUD clients

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`axmud`](guix/tay/packages/axmud.scm) | `2.0.0` | Perl/GTK3 graphical MUD client with GMCP and configurable scripting | Defined |
| [`blightmud`](guix/tay/packages/blightmud.scm) | `5.7.1` | Rust terminal MUD client with Lua, TLS, MCCP2, GMCP, and MSDP | Defined |
| [`durthang`](guix/tay/packages/durthang.scm) | `0.2.0` | Rust TUI MUD client with TLS, GMCP, automapping, and encrypted Secret Service transport | Defined |
| [`frostbite`](guix/tay/packages/frostbite.scm) | `1.18.2` | Qt5 DragonRealms client with Ruby scripting, profiles, maps, sound, and XDG state | Defined |
| [`go-mud`](guix/tay/packages/go-mud.scm) | `0.6.6` | UTF-8 terminal MUD client with Lua scripting | Defined |
| [`godisc`](guix/tay/packages/godisc.scm) | `0-20180125-47a9163` | Discworld-oriented terminal MUD client with an optional tmux workspace | Defined |
| [`kbtin`](guix/tay/packages/kbtin.scm) | `0-20260801` | TinTin-compatible terminal MUD client with TLS and MCCP | Defined |
| [`kildclient`](guix/tay/packages/kildclient.scm) | `3.2.3` | GTK MUD client with Perl scripting, plugins, triggers, aliases, and multiple worlds | Defined |
| [`kmuddy`](guix/tay/packages/kmuddy.scm) | `1.1` | KDE MUD client with scripting, mapping, MCCP, MSP, and MXP | Defined |
| [`lyntin`](guix/tay/packages/lyntinv.scm) | `5.0.1` | Text-mode Python MUD client with aliases, triggers, scripting, and module support | Defined |
| [`mmapper`](guix/tay/packages/mmapper.scm) | `26.06.0` | Qt graphical MUME client, local TLS proxy, and empty-map editor | Defined |
| [`mudlet`](guix/tay/packages/mudlet.scm) | `4.22.0` | Qt6 graphical MUD client with Lua scripting, mapping, multimedia, MXP, and GMCP | Defined |
| [`mudpuppy`](guix/tay/packages/mudpuppy.scm) | `20251214-1.3199e83` | Rust terminal MUD client with embedded Python scripting and TLS | Defined |
| [`mushkin`](guix/tay/packages/mushkin.scm) | `0.5.1` | Qt MUSHclient-compatible MUD client with Lua, TLS, and MSP | Defined |
| [`mushtato`](guix/tay/packages/mushtato.scm) | `1.9.3` | Python/Qt MUSH client with sandboxed scripting, TLS, and SSH | Defined |
| [`potato`](guix/tay/packages/potato.scm) | `2.0.0b19` | Tcl/Tk graphical MUSH client | Defined |
| [`pycat`](guix/tay/packages/pycat.scm) | `20240731-1.55c0389` | Modular Python MUD proxy client with user-defined world modules | Defined |
| [`rune`](guix/tay/packages/rune.scm) | `0.10.1` | Pure-Go terminal MUD client with Lua, TLS, MCCP2, and GMCP | Defined |
| [`secretpathway`](guix/tay/packages/secretpathway.scm) | `1.0.0-0.2ea2e6b` | Java/Swing MUD client with an LPC source editor | Defined |
| [`tinyfugue`](guix/tay/packages/tinyfugue.scm) | `5.2.2` | Scriptable terminal MUD client with TLS, MCCP, GMCP, and IPv6 | Defined |
| [`trebuchet`](guix/tay/packages/trebuchet.scm) | `1082` | Tcl/Tk graphical MUD, MUCK, and MUSH client with MCP support | Defined |

### Historical computing and languages

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`aiwnios`](guix/tay/packages/aiwnios.scm) | `0.9.0-0.e155e87` | Source-built HolyC compiler and runtime environment | Verified |
| [`aiwnios-bytecode`](guix/tay/packages/aiwnios.scm) | `0.9.0-0.e155e87` | Aiwnios environment using upstream bytecode | Verified |
| [`apout`](guix/tay/packages/apout.scm) | `0-bd9af21` | PDP-11 Unix a.out user-mode emulator | Verified original V7 guest CPU/write/error/exit; [limits](ACCOUNTING.md#apout--verified-native-v7-guest-contract) |
| [`blincolnlights`](guix/tay/packages/blincolnlights.scm) | `0-932d2ce` | Virtual front panels and emulators for historic computers | Verified installed PDP-1 panel/PDP-5 deposit/examine/core restore; [limits](ACCOUNTING.md#blincolnlights--verified-native-pdp-1-panel-and-pdp-5-memory-path) |
| [`image-tape`](guix/tay/packages/image-tape.scm) | `0-0402e21` | Magnetic-tape image reader with safe output handling | Defined |
| [`interlisp-medley`](guix/tay/packages/interlisp-medley.scm) | `2026.08.10` | Graphical Interlisp/Common Lisp environment with source-built Maiko and pinned upstream boot images | Verified native evaluation/save/logout; [limits](ACCOUNTING.md#medley-and-maiko--verified-native-path) |
| [`itstar`](guix/tay/packages/itstar.scm) | `1.10-0.b709cd8` | Create, inspect, extract and append ITS DUMP tape images | Verified |
| [`klh10`](guix/tay/packages/klh10.scm) | `2.0l-guix-0.6d733f2` | KL10/KS10 host emulator with console and disk/tape-image converters | Verified |
| [`ks10-udis`](guix/tay/packages/ks10-udis.scm) | `0-c41bced` | KS10 microcode disassembler and offline fixture | Defined |
| [`lbforth`](guix/tay/packages/lbforth.scm) | `0-20230213` | Self-hosted portable Forth interpreter and standard wordsets | Verified |
| [`maiko`](guix/tay/packages/maiko.scm) | `2026.03.19` | Source-built X11 Lisp-machine VM for Medley, without Ethernet/Nethub | Verified through Medley |
| [`modus`](guix/tay/packages/modus.scm) | `0.2.0-0.501f2ee` | Self-hosting Common Lisp implementation with a hosted CLI | Verified |
| [`pdp10-gcc`](guix/tay/packages/pdp10-gcc.scm) | `3.2-20020416` | Assembler-free GCC C backend emitting PDP-10 TOPS-20 MACRO assembly | Verified native preprocessing/`-S` code generation only; outside default build inventory, no assembly/link/runtime; [limits](ACCOUNTING.md#pdp10-gcc--verified-assembler-free-c-code-generation) |
| [`pdp10-its-disassembler`](guix/tay/packages/pdp10-its-disassembler.scm) | `0-c745bb5` | Disassemble and manipulate PDP-10 ITS files | Verified |
| [`pdp10-suppty`](guix/tay/packages/suppty.scm) | `0-2da0135` | Original GTK 2 and CLI SUPDUP terminal clients | Verified |
| [`pdp10-xpl-pdp-10`](guix/tay/packages/pdp10-xpl.scm) | `0-0e57cbd` | PDP-10 XPL compiler port | Verified native compiler/REL object semantics, not PDP-10 execution; [limits](ACCOUNTING.md#pdp10-xpl--verified-native-compiler-object-semantics) |
| [`pdp11`](guix/tay/packages/pdp11.scm) | `0-5b5b734` | Host emulators for selected PDP-11 CPU models | Verified `pdp1145` native microcycle diagnostic only; [limits](ACCOUNTING.md#pdp11--verified-native-microcycle-diagnostic) |
| [`pdp6`](guix/tay/packages/pdp6.scm) | `0-2645ed9` | Local SDL console emulator for the PDP-6 | Verified native panel deposit/examine and clean quit; [limits](ACCOUNTING.md#pdp6--verified-native-panel-memory-path) |
| [`tapeutils`](guix/tay/packages/tapeutils.scm) | `0.6-0.84a3a78` | Read, write, and inspect magnetic-tape image files | Verified |
| [`uc-explorer`](guix/tay/packages/uc-explorer.scm) | `0.1.0` | Inspect local Lisp-machine microcode files | Verified native parser semantics and malformed-input detection; synthetic fixtures, not ROM/emulation; [limits](ACCOUNTING.md#uc-explorer--verified-native-microcode-parser) |
| [`vt05`](guix/tay/packages/vt05.scm) | `0.1-1.934fe88` | SDL emulators for six classic text terminals | Verified |

### Roguelikes and other games

#### NetHack, Hack and Rogue variants

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`acehack`](guix/tay/packages/acehack.scm) | `3.6.0-0.9a4c767` | Historical native tty NetHack variant with NGPL executable/data source and private XDG state | Verified native gameplay/save continuity; clean-lint gate pending, #266 open ([receipt](ACCOUNTING.md#acehack--verified-native-tty-gameplay-and-save-continuity)) |
| [`bell-labs-rogue7`](guix/tay/packages/bell-labs-rogue7.scm) | `7.7.1` | Historical terminal dungeon game with XDG-managed score and save state | Verified native gameplay/save continuity; clean-lint gate pending, #267 open ([receipt](ACCOUNTING.md#bell-labs-rogue7--standalone-native-gameplay-and-save-continuity)) |
| [`dhack`](guix/tay/packages/dhack.scm) | `0.2c` | Source-built DreamHack C++/ncurses roguelike; native inventory and player-centered movement, no save/load | Verified ordinary native gameplay and zero-status quit; #328 OPEN (archive lint gates; [receipt](ACCOUNTING.md#dhack--ordinary-native-terminal-gameplay-2026-10-09)) |
| [`dnethack`](guix/tay/packages/dnethack.scm) | `3.26.0` | Terminal dungeon exploration game based on NetHack | Defined |
| [`dynahack`](guix/tay/packages/dynahack.scm) | `0.6.0` | DynaHack curses NetHack variant | Verified |
| [`evilhack`](guix/tay/packages/evilhack.scm) | `0.9.3` | EvilHack terminal NetHack variant | Verified |
| [`fiqhack`](guix/tay/packages/fiqhack.scm) | `4.3.0` | FIQHack terminal NetHack variant | Verified |
| [`grunthack`](guix/tay/packages/grunthack.scm) | `0.2.4-0.51d75ee` | GruntHack terminal NetHack variant | Verified |
| [`hack`](guix/tay/packages/hack.scm) | `1.0.3` | Original BSD-3-Clause source-built terminal game/data/manual/notices, immutable store assets and XDG native mutable state | Verified |
| [`hackem`](guix/tay/packages/hackem.scm) | `1.2.2` | HACK’EM terminal NetHack variant | Verified |
| [`nitrohack`](guix/tay/packages/nitrohack.scm) | `4.0.4` | Wide-curses NetHack variant with native menus and saves | Verified |
| [`slashem`](guix/tay/packages/slashem.scm) | `0.0.8E0F2-0.aae9ef2` | Extended NetHack terminal dungeon game | Verified |
| [`splicehack-rewrite`](guix/tay/packages/splicehack-rewrite.scm) | `0.8.2-0.0cf23cb` | SpliceHack Rewrite terminal NetHack variant | Verified |
| [`sporkhack`](guix/tay/packages/sporkhack.scm) | `0.7.0-0.4ed114f` | Silent native Unix NetHack roguelike with NGPL source/data and private XDG state | Verified ([receipt](ACCOUNTING.md#sporkhack-silent-native-game-and-save-continuity)) |
| [`srogue`](guix/tay/packages/srogue.scm) | `9.0` | Robert Kindelberger's expanded version of the Rogue dungeon game | Verified |
| [`unnethack`](guix/tay/packages/unnethack.scm) | `6.0.4` | NGPL full native TTY game/data/recovery/docs | Verified |
| [`urogue`](guix/tay/packages/ultrarogue.scm) | `1.0.8` | Classic terminal dungeon crawl with an expanded bestiary | Verified |
| [`xnethack`](guix/tay/packages/xnethack.scm) | `10.0` | Variant of NetHack with gameplay and interface changes | Verified |
| [`xrogue`](guix/tay/packages/xrogue.scm) | `8.0.3` | Expeditions into the Dungeons of Doom, release 8.0.3 | Verified |

#### Crawl and Brogue variants

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`bcrawl`](guix/tay/packages/bcrawl.scm) | `1.42.1` | Terminal-only Dungeon Crawl Stone Soup fork with XDG-managed state | Verified |
| [`bloatcrawl2`](guix/tay/packages/bloatcrawl2.scm) | `2.2.0` | Terminal fork of Dungeon Crawl Stone Soup | Verified |
| [`brogue`](guix/tay/packages/brogue.scm) | `1.15.1` | Brogue CE with SDL tiles and ncurses frontends, XDG native state | Verified ([receipt](ACCOUNTING.md#brogue)) |
| [`brogue-lite`](guix/tay/packages/brogue-lite.scm) | `1.13-0.20240105` | Casual terminal roguelike dungeon game | Defined |
| [`hellcrawl`](guix/tay/packages/hellcrawl.scm) | `5.7` | Console Crawl variant with a streamlined dungeon | Verified |
| [`kimchi`](guix/tay/packages/kimchi.scm) | `1.3.2` | Korean-localized console Crawl variant | Verified |
| [`rapidbrogue`](guix/tay/packages/rapidbrogue.scm) | `1.4.0` | Ten-level rapid variant of the Brogue roguelike | Verified |
| [`stoat-soup`](guix/tay/packages/stoat-soup.scm) | `0.23-ish-aug26` | Complete original console-only Crawl variant with immutable data/docs and native XDG saves, scores, macros and caches | Verified |

#### Other terminal and graphical games

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`agduria`](guix/tay/packages/agduria.scm) | `0.0.1-0.92c20b1` | Early C++/ncurses dungeon-exploration roguelike; no save/load | Verified native terminal path |
| [`aquarium-arena`](guix/tay/packages/aquarium-arena.scm) | `0.4-0.6d494c` | Underwater pygame arena roguelike with XDG high scores | Verified native SDL gameplay; clean-lint gate pending ([receipt](ACCOUNTING.md#aquarium-arena--verified-native-sdl-gameplay)) |
| [`aquesttoofar`](guix/tay/packages/aquesttoofar.scm) | `1.3` | Source-built C++/SDL dungeon adventure starring an aging hero | Verified |
| [`atlas-warriors`](guix/tay/packages/atlas-warriors.scm) | `0.0.9` | Source-built Pygame fantasy roguelike with XDG tutorial state | Verified native SDL path; clean-lint gate pending ([receipt](ACCOUNTING.md#atlas-warriors--verified-native-sdl-gameplay)) |
| [`atrogue`](guix/tay/packages/atrogue.scm) | `0.3.0` | Terminal roguelike with configurable dungeon exploration | Verified |
| [`avanor`](guix/tay/packages/avanor.scm) | `0.5.8` | Historical terminal roguelike with XDG-managed saves and high scores | Verified |
| [`babel7drl`](guix/tay/packages/babel7drl.scm) | `2019-03-09` | Tower of Babel exploration game | Verified |
| [`bootrogue`](guix/tay/packages/bootrogue.scm) | `0-118e1cb` | Roguelike game that fits in a boot sector | Verified |
| [`calcrogue`](guix/tay/packages/calcrogue.scm) | `6a-sp1` | Full source-built i686 Linux/curses calculator roguelike with regenerated game data and private XDG native state | Verified ordinary native gameplay and gzip save/restore continuity; explicit `-s i686-linux`; #295 OPEN (own updater/archive lint gates; [receipt](ACCOUNTING.md#calcrogue--native-i686-gameplay-and-save-continuity-2026-10-09)) |
| [`chessrogue`](guix/tay/packages/chessrogue.scm) | `0.3.1` | Source-built Kaya/ncurses chess roguelike with XDG keymap, retry state and score reports | Verified ordinary native Practice gameplay, same-process retry and zero-status quit; #303 OPEN (own lint gate; [receipt](ACCOUNTING.md#chessrogue--ordinary-native-practice-gameplay-and-retry-2026-10-09)) |
| [`city-of-the-condemned`](guix/tay/packages/city-of-the-condemned.scm) | `1.0-0.e9a8989` | Original source-built C++/ncurses Angel/Imp roguelike with retained reflexivelos FOV; no save/load | Verified ordinary native movement, world turns and zero-status quit; #307 OPEN (literal own updater lint gate; [receipt](ACCOUNTING.md#city-of-the-condemned--original-source-and-ordinary-native-gameplay-2026-10-09)) |
| [`clojure-roguelike`](guix/tay/packages/clojure-roguelike.scm) | `0.1.0-0.16102d6` | Original Clojure one-shot 8×8 room-rendering prototype; no input, movement or persistent state | Verified native room render and natural zero-status exit, not gameplay; #101 OPEN (own updater/archive lint gates; [receipt](ACCOUNTING.md#clojure-roguelike--native-one-shot-prototype-render-2026-10-09)) |
| [`corerl`](guix/tay/packages/corerl.scm) | `1kib-20131024` | Source-built 1023-byte public-domain terminal roguelike | Verified ordinary native movement, enemy response and zero-status quit; #311 OPEN (own lint gates; [receipt](ACCOUNTING.md#corerl--ordinary-native-terminal-gameplay-2026-10-09)) |
| [`cotd`](guix/tay/packages/cotd.scm) | `2.0.2-0.b771e2e` | City of the Damned strategy roguelike | Verified campaign path |
| [`crashrun`](guix/tay/packages/crashrun.scm) | `0.5.0` | Original Python/SDL2 science-fiction roguelike | Verified |
| [`cryptrover`](guix/tay/packages/cryptrover.scm) | `1.1` | Source-built no-sound terminal dungeon survival game with XDG high scores | Verified ordinary native movement, flashlight/resource turns and normal exit; #318 OPEN (archive updater lint gate; [receipt](ACCOUNTING.md#cryptrover--ordinary-native-terminal-gameplay-2026-10-09)) |
| [`cutlassrl`](guix/tay/packages/cutlassrl.scm) | `0.05-0.304bb87` | Original Python 2 terminal roguelike with XDG native saves and logs | Verified ordinary native movement, automatic save/restore continuity and zero-status quit; #320 OPEN (own release-discovery lint gate; [receipt](ACCOUNTING.md#cutlassrl--ordinary-native-terminal-saverestore-2026-10-09)) |
| [`diabaig`](guix/tay/packages/diabaig.scm) | `1.0.1` | Terminal roguelike game | Verified |
| [`dragonslayer`](guix/tay/packages/dragonslayer.scm) | `3.5` | Terminal Dragonslayer game | Defined |
| [`dungeon-monkey-unlimited`](guix/tay/packages/dungeon-monkey-unlimited.scm) | `1.001` | Pascal/SDL fantasy dungeon adventure | Verified |
| [`freelarn`](guix/tay/packages/freelarn.scm) | `0-8cd18cb` | Original C++11 descendant of the Larn dungeon game | Verified |
| [`gearhead`](guix/tay/packages/gearhead.scm) | `1.310` | GearHead: Arena mecha role-playing game, ASCII interface | Verified |
| [`gearhead2`](guix/tay/packages/gearhead2.scm) | `0.701` | GearHead 2 mecha role-playing game, ASCII interface | Verified |
| [`grippy-socks`](guix/tay/packages/grippy-socks.scm) | `3.5` | Original Daedalus Unix console mental-health simulation; native rest/day evaluation, no graphical inside view | Verified ordinary console gameplay and normal exit; #383 CLOSED on [Forgejo](https://forge.nogroup.group/tay/guix-channel/issues/383#issuecomment-3256) and [GitHub](https://github.com/htayj/guix-channel/issues/383#issuecomment-6086865578); signed/authenticated implementation [`a770727680da9d7fc32ee376092c5214d8bdea59`](https://forge.nogroup.group/tay/guix-channel/commit/a770727680da9d7fc32ee376092c5214d8bdea59) published to origin/master ([receipt](ACCOUNTING.md#grippy-socks--ordinary-native-console-gameplay-2026-10-09)) |
| [`gruesome`](guix/tay/packages/gruesome.scm) | `0.0.3` | Original Free Pascal/CRT cave roguelike, ordinary terminal movement and turns | Verified native gameplay and normal quit; #384 OPEN (archive lint gate; [receipt](ACCOUNTING.md#gruesome--ordinary-native-terminal-gameplay-2026-10-07)) |
| [`hunger-games`](guix/tay/packages/hunger-games.scm) | `3.5` | Original Daedalus Unix console simulation, native movement/status and arena BMP exports; no graphical UI | Verified ordinary console gameplay and normal exit; #397 CLOSED on [Forgejo](https://forge.nogroup.group/tay/guix-channel/issues/397#issuecomment-3248) and [GitHub](https://github.com/htayj/guix-channel/issues/397#issuecomment-6085147907); signed/authenticated implementation [`68aa5d0e06ce8d22cba5577b658c671c309cb824`](https://forge.nogroup.group/tay/guix-channel/commit/68aa5d0e06ce8d22cba5577b658c671c309cb824) published to origin/master ([receipt](ACCOUNTING.md#hunger-games--ordinary-native-console-gameplay-2026-10-09)) |
| [`hydra-slayer`](guix/tay/packages/hydra-slayer.scm) | `18.3` | Console roguelike about cutting Hydra heads | Verified |
| [`ighalsk`](guix/tay/packages/ighalsk.scm) | `0.1.16` | Original Python 2/Tk dungeon adventure with XDG saves and editors | Verified |
| [`keeperrl`](guix/tay/packages/keeperrl.scm) | `1.3.0-1.95d2be4` | Dungeon-management roguelike with free ASCII assets, not paid media | Verified |
| [`lambdahack`](guix/tay/packages/lambdahack.scm) | `0.9.5.0` | SDL roguelike and game engine demonstration | Verified |
| [`legcord`](guix/tay/packages/legcord.scm) | `1.3.0` | Discord desktop client with Shelter plugins | Verified logged-out desktop |
| [`letter-hunt`](guix/tay/packages/letter-hunt.scm) | `002` | Seven Day Roguelike about spelling words with captured letters | Verified |
| [`linerogue`](guix/tay/packages/linerogue.scm) | `2` | Turn-based terminal bike roguelike | Verified |
| [`lispy-rogue`](guix/tay/packages/lispy-rogue.scm) | `0.0.2` | Common Lisp/Allegro graphical dungeon crawler; no save implementation | Verified selected GUI paths |
| [`liveonce`](guix/tay/packages/liveonce.scm) | `005` | Seven Day Roguelike about a village's successive heroes | Verified |
| [`martins-dungeon-bash`](guix/tay/packages/martins-dungeon-bash.scm) | `1.7` | Original BSD-2 C/ncurses roguelike with private XDG state and consuming native saves | Verified native gameplay/save continuity and clean-own-lint gate; #438 verified closed ([Forgejo](https://forge.nogroup.group/tay/guix-channel/issues/438#issuecomment-3243), [GitHub](https://github.com/htayj/guix-channel/issues/438#issuecomment-6045690326); [receipt](ACCOUNTING.md#martins-dungeon-bash--native-gameplay-and-save-continuity-2026-10-07)) |
| [`narwharl`](guix/tay/packages/narwharl.scm) | `0.0.1` | Full original source-built C++/ncurses roguelike with immutable definitions and XDG/HOME native saves | Verified |
| [`nlarn`](guix/tay/packages/nlarn.scm) | `0.8.0` | Original C/ncurses Larn rewrite, immutable console data/locales and native `~/.nlarn` configuration/saves | Verified |
| [`obumbrata`](guix/tay/packages/obumbrata.scm) | `1.0.0` | Obumbrata et Velata ncurses dungeon game | Verified |
| [`plomrogue`](guix/tay/packages/plomrogue.scm) | `0-1.20170821` | Please the Island God, a C-engine/Python-client roguelike | Verified |
| [`pyro`](guix/tay/packages/pyro.scm) | `0.04a` | Complete original Python 2/curses roguelike with XDG native log | Verified |
| [`revengate`](guix/tay/packages/revengate.scm) | `0.13.0` | Godot-based graphical roguelike | Verified |
| [`robotfindskitten`](guix/tay/packages/robotfindskitten.scm) | `3.0000000.726` | Terminal Zen simulation: help robot find kitten | Verified |
| [`rouge`](guix/tay/packages/rouge.scm) | `1.61` | Original curses Wikipedia-satire roguelike with XDG controls and high scores | Verified |
| [`savescummer`](guix/tay/packages/savescummer.scm) | `002` | Seven Day Roguelike played by rewinding and restoring saves | Verified |
| [`sewer-massacre`](guix/tay/packages/sewer-massacre.scm) | `1.0` | Original Common Lisp curses roguelike with ASDF FASLs and XDG save state | Verified |
| [`shadow-over-darkmoor`](guix/tay/packages/shadow-over-darkmoor.scm) | `0.2.0-0.fe7d296` | Text-based roguelike adventure game | Defined |
| [`shamogu`](guix/tay/packages/shamogu.scm) | `1.5.0` | Tactical terminal roguelike with totemic spirits | Verified |
| [`six-two-one`](guix/tay/packages/six-two-one.scm) | `2016-03-06` | Original source-built C++/SDL word-puzzle roguelike with libtcod and XDG configuration/saves | Verified |
| [`space-privateers`](guix/tay/packages/space-privateers.scm) | `0.1.0.0` | Haskell/Vty space-travel roguelike | Verified |
| [`tetraworld`](guix/tay/packages/tetraworld.scm) | `0-unstable-20210406` | Four-dimensional terminal exploration roguelike | Verified |
| [`the-smiths-hand`](guix/tay/packages/smiths-hand.scm) | `2014-03-16` | Village-smith roguelike with adventurer equipment trading | Verified |
| [`trial-by-combat`](guix/tay/packages/trial-by-combat.scm) | `0.1.0` | Tactical browser arena served over HTTP and WebSocket | Verified |
| [`umoria`](guix/tay/packages/umoria.scm) | `5.7.15` | Full original source-built C++/ncurses Moria with immutable data and XDG scores/default save | Verified |
| [`wanderers`](guix/tay/packages/wanderers.scm) | `0-054c1cd` | Open-world adventure and dungeon-crawling game | Verified ([receipt](ACCOUNTING.md#wanderers--verified-native-saverestore-path)) |
| [`wrogue`](guix/tay/packages/wrogue.scm) | `0.8.0` | Warp Rogue science-fiction SDL roguelike | Verified |

#### Official Guix game reuse

**Boohu 0.14.1** is reused from official Guix (`(@ (gnu packages games) boohu)`),
not duplicated as a channel package. Its source rebuild and terminal save/restore
path are [locally verified](ACCOUNTING.md#boohu--official-guix-reuse-and-native-terminal-saverestore)
on 2026-10-05. The proof covers normal `boohu` in a real terminal, not
`boohu-tk`; it adds neither a channel package nor a source-snapshot count.

### Programming libraries and developer tools

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`affect`](guix/tay/packages/affect.scm) | `0.0.0-0.780faa2` | OCaml structured async, cooperative Unix I/O, temporary networking and Cmdliner CLI libraries | Verified native API ([receipt and limits](ACCOUNTING.md#affect--native-libraries-and-isolated-ocaml-55-toolchain)) |
| [`astx`](guix/tay/packages/astx.scm) | `0.0.0-development-0.9f0ee21` | Structural JavaScript/TypeScript search-and-replace CLI | Verified native `.cts` loader, JS/TS rewrite and PTY decline/accept; #104 OPEN (own updater/archive lint gates; [receipt](ACCOUNTING.md#astx--native-cts-loader-and-confirmed-structural-rewrite-2026-10-09)) |
| [`bodge-nuklear`](guix/tay/packages/bodge-nuklear.scm) | `1.0.0-1.40adae4` | Common Lisp bindings and wrapper for source-built Nuklear immediate-mode GUI | Verified native API and X11 demo |
| [`dart-sass`](guix/tay/packages/caelestia-cli.scm) | `1.105.0` | Reference Sass compiler with the module system, run on Node.js | Defined |
| [`domainslib`](guix/tay/packages/domainslib.scm) | `0.5.2-1.2a88486` | OCaml multicore task pools, parallel algorithms and channels | Verified |
| [`litegraph`](guix/tay/packages/litegraph.scm) | `0.7.14-0.0555a2f` | JavaScript node-graph engine and HTML5 canvas editor | Verified engine and browser editor |
| [`meta-typing`](guix/tay/packages/meta-typing.scm) | `0.1.0` | MIT declaration-only algorithms and data structures computed by TypeScript's type system; no JavaScript runtime | Verified strict external type consumer ([receipt and limits](ACCOUNTING.md#meta-typing--verified-offline-type-level-library-and-external-consumer)) |
| [`minttea`](guix/tay/packages/minttea.scm) | `0.0.3-1.40ee449` | OCaml functional terminal UI framework with Leaves components and native examples | Verified native PTY ([receipt and limits](ACCOUNTING.md#minttea--native-terminal-ui-and-isolated-ocaml-52-closure)) |
| [`miou`](guix/tay/packages/miou.scm) | `0.8.0-1.5fcb7e6` | OCaml concurrency and synchronization libraries | Verified |
| [`node-ink`](guix/tay/packages/ink.scm) | `7.1.1` | React terminal renderer with source-built Yoga C++/embedded WebAssembly and shared React 19.2.4 | Verified upstream typecheck/XO/AVA, reproducible output and isolated native PTY counter ([receipt and limits](ACCOUNTING.md#ink--source-built-react-terminal-renderer-and-native-pty-consumer)) |
| [`notty`](guix/tay/packages/notty.scm) | `0.2.3` | OCaml composable terminal graphics and Unix/Lwt backends | Verified |
| [`ocaml-affect`](guix/tay/packages/ocaml-affect-toolchain.scm) | `5.5.0` | Isolated source-built compiler matching Affect's library ABI | Built; compiler tests exercised |
| [`ocaml-cmdliner-affect`](guix/tay/packages/ocaml-affect-toolchain.scm) | `2.1.1` | Compiler-matched Cmdliner library, tool and completions | Built; Affect CLI exercised |
| [`ocaml-findlib-affect`](guix/tay/packages/ocaml-affect-toolchain.scm) | `1.9.8-1.1faecd4` | Compiler-matched Findlib with pinned, unmerged OCaml 5.5 adaptation | Built; native consumer exercised |
| [`ocaml-irc-client`](guix/tay/packages/irc-client.scm) | `0.7.1-1.d6f8b2a` | IRC client library core | Defined |
| [`ocaml-irc-client-lwt`](guix/tay/packages/irc-client.scm) | `0.7.1-1.d6f8b2a` | Lwt backend for the OCaml IRC client | Defined |
| [`ocaml-irc-client-lwt-ssl`](guix/tay/packages/irc-client.scm) | `0.7.1-1.d6f8b2a` | Lwt OpenSSL backend for the OCaml IRC client | Defined |
| [`ocaml-irc-client-unix`](guix/tay/packages/irc-client.scm) | `0.7.1-1.d6f8b2a` | Unix blocking I/O backend for the OCaml IRC client | Defined |
| [`ocaml-lwt-ssl`](guix/tay/packages/irc-client.scm) | `1.2.0` | OpenSSL binding with concurrent Lwt I/O | Defined |
| [`ocaml-topkg-affect`](guix/tay/packages/ocaml-affect-toolchain.scm) | `1.1.1` | Compiler-matched Topkg package-building library | Built for Affect |
| [`ocamlbuild-affect`](guix/tay/packages/ocaml-affect-toolchain.scm) | `0.16.1` | Compiler-matched OCamlbuild with corrected Digest interface | Built for Affect |
| [`proiel`](guix/tay/packages/proiel.scm) | `1.3.3` | Corpus-free Ruby PROIEL XML treebank library | Verified |
| [`qiling`](guix/tay/packages/qiling.scm) | `1.4.10` | Multi-architecture binary emulation framework | Verified |
| [`react-blessed`](guix/tay/packages/react-blessed.scm) | `0.7.2` | React renderer for Blessed terminal interfaces | Defined |
| [`rot-js`](guix/tay/packages/rot-js.scm) | `2.2.1` | BSD-3 JavaScript roguelike toolkit: maps, FOV, pathfinding, schedulers, RNG and terminal/canvas displays, with API docs, manual and examples | Verified headless upstream suite and offline Node/TypeScript consumer ([receipt and limits](ACCOUNTING.md#rotjs--verified-source-built-toolkit-and-offline-consumer)) |
| [`ruby-memoist`](guix/tay/packages/proiel.scm) | `0.16.2` | MIT Ruby method-result caching library | Defined |
| [`ruby-sax-machine`](guix/tay/packages/proiel.scm) | `1.3.2` | MIT declarative SAX parsing library with Nokogiri backend | Defined |
| [`rust-computus`](guix/tay/packages/computus.scm) | `0.1.0` | Redistributable Rust simulation core | Defined |
| [`rust-effects`](guix/tay/packages/rust-effects.scm) | `0.1.0-0.d7fe96d` | Rust functional typeclasses, free-effect interpretation and shared async futures; installed source and offline Cargo closure | Verified native external consumer ([receipt and limits](ACCOUNTING.md#rust-effects--verified-offline-library-and-external-consumer)) |
| [`scala-ts`](guix/tay/packages/scala-ts.scm) | `0.1.8` | Scala-style collections, Option, Either and Try for TypeScript | Verified |
| [`sbcl-imago`](guix/tay/packages/imago.scm) | `0.11.0` | Common Lisp image manipulation with six ASDF systems, native JPEG/TIFF/HEIF backends and Jupyter PNG payloads | Verified bounded native consumer and reproducible build; #220 OPEN, literal clean lint unmet ([receipt and limits](ACCOUNTING.md#imago--six-system-image-library-and-native-consumer)) |
| [`shader-slang`](guix/tay/packages/shader-slang.scm) | `2026.14.1` | `slangc` Slang shader compiler and libraries | Defined |
| [`tui`](guix/tay/packages/tui.scm) | `0.2.0-0.e435b1b` | Clojure styled text rendering and cooked line input | Verified |
| [`wenyan`](guix/tay/packages/wenyan.scm) | `0.4.0` | Classical Chinese language compiler, CLI and JavaScript library | Verified compiler/CLI path |
| [`xq`](guix/tay/packages/xq.scm) | `0-e1abbb3` | Offline-built XML and HTML beautifier and extractor | Defined |

### Other utilities and game launchers

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`aptitude-custom-aliases`](guix/tay/packages/aptitude-custom-aliases.scm) | `20160824-1.c61c64e` | Zsh plugin and documentation | Defined |
| [`computer-builder`](guix/tay/packages/computer-builder.scm) | `0.1.0` | Offline-built PC component catalog web application | Defined |
| [`faugus-launcher`](guix/tay/packages/faugus-launcher.scm) | `2.1.0-0.5b2316c` | GTK game launcher with opt-in runtime downloads | Verified native GTK add/edit/reopen, no game run; [limits and lint caveat](ACCOUNTING.md#faugus-launcher--verified-native-gtk-path) |
| [`heroic-gogdl`](guix/tay/packages/heroic-gogdl.scm) | `1.3.0` | GOG downloader used by Heroic Games Launcher | Verified |
| [`tassh`](guix/tay/packages/drbeefsupreme/tassh.scm) | `20260228-1.672569a` | Source-built Tailscale/SSH PNG clipboard relay | Verified isolated X11/Wayland loopback transfers; outside default build; [integration limits](ACCOUNTING.md#tassh--verified-isolated-native-clipboard-relay) |
| [`weidu`](guix/tay/packages/weidu.scm) | `252.01` | Offline-built Infinity Engine modding command-line tool | Verified native/repro and game-free fixtures; [limits and lint caveat](ACCOUNTING.md#weidu--verified-offline-native-path) |

### Source-oriented collections

These installable outputs are deliberately data/source-oriented, not replacements
for native applications. Bell Museum's renderer needs an independently obtained
Inferno checkout; its submodule is not packaged.

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`bell-museum`](guix/tay/packages/bell-museum.scm) | `20260726-1.15f0093` | Museum documentation and Inferno specimen renderer | Source-oriented data |
| [`custom-nix-pkgs`](guix/tay/packages/custom-nix-pkgs.scm) | `20260102-1.f1a6694` | Preserved Nix expressions plus a snapshot validator | Source-oriented data |
| [`databases-team75`](guix/tay/packages/databases-team75.scm) | `20170423-1.8b8c624` | Preserved legacy client source and documentation | Source-oriented data |

### Desktop support libraries

These are useful desktop building blocks, shown separately so they do not obscure
programs. Private compiler, npm, Python, Java, Rust and Haskell dependencies stay
in their owning definitions and the detailed accounting rather than this catalog.

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`libcava`](guix/tay/packages/caelestia-dependencies.scm) | `1.0.0` | CAVA audio visualizer as a shared library | Defined |
| [`m3shapes`](guix/tay/packages/caelestia-dependencies.scm) | `1.0.0-1.32ad9ce` | Material 3 Expressive shape QML module | Defined |
| [`quickshell-for-caelestia`](guix/tay/packages/caelestia-dependencies.scm) | `0.3.1-1.2d3b3e9` | `qs`/`quickshell` at the commit pinned by Caelestia shell 2.5.0 | Defined |

### Local acceptance and restricted packages

**Allure and AloneRL passed final local acceptance.** Their publication state is
established by the signed channel commit history, not by inclusion in this table.
AloneRL's fresh-process Continue preserves terrain only—not character or inventory
state. SentinelOne needs authorized source and has no validated privileged runtime.

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`allure`](guix/tay/packages/allure.scm) | `0.11.0.0` | SDL party-based roguelike using LambdaHack | Verified locally |
| [`alone-rl`](guix/tay/packages/alone-rl.scm) | `0.3.1` | Java/Swing survival roguelike with source-built terrain generator | Verified locally; terrain-only Continue |
| [`sentinelone`](guix/tay/packages/sentinelone.scm) | `24.3.3.1` | Proprietary x86_64 agent | Blocked without authorized installer |

## Source snapshots and research

The dated [project inventory](PROJECTS.md) records **629 immutable source
packages**: 51 owned originals, 177 Lars Brinkhoff repositories, 68 PDP-10
repositories, and 333 starred repositories. This is preservation inventory,
not 629 runnable applications or a promise to finish every research issue.
Snapshots install beneath `share/ACCOUNT/projects/REPOSITORY`, preserving
submodule pointers without fetching their contents.

A `*-source` package, research ticket, runtime-contract entry, or available
package definition is not by itself proof of an installable native program.
Empty repositories have no snapshot; archived/reference and excluded server
projects retain the dispositions in [PROJECTS.md](PROJECTS.md). Missing licenses
and other blockers must be resolved before redistribution; a hash is not a
license grant. Research/pending definitions outside the normal build inventory
are listed separately below rather than presented as verified deliveries.

### Research and definitions outside the normal build inventory

These exported definitions are **not** in the normal top-level `make build`
inventory. Their presence (or an old smoke-contract entry) does not establish a
current verified native delivery. Consult Forgejo and the source definition for
research/blocker disposition before use; this guide does not promote them to the
verified program list.

| Package | Version | What it does | Status |
| --- | --- | --- | --- |
| [`cavechop`](guix/tay/packages/cavechop.scm) | `1.0` | Source-built terminal dungeon game | [Native save/restore verified; clean own lint pending, #299 OPEN](ACCOUNTING.md#cave-chop--ordinary-native-terminal-saverestore-2026-10-09); outside normal build inventory |
| [`drl`](guix/tay/packages/drl.scm) | `0.10.11` | DoomRL graphical/terminal roguelike definition | Research / definition only |
| [`flaghack`](guix/tay/packages/flaghack.scm) | `20260713-1.772c47e` | Flag-themed NetHack project definition | Research / definition only |
| [`flaghack-charm`](guix/tay/packages/flaghack.scm) | `20260713-1.772c47e` | FlagHack Go terminal launcher output | Research / definition only |
| [`gsplat-wasm`](guix/tay/packages/gsplat-wasm.scm) | `1.2.9` | Browser Gaussian-splatting viewer/toolkit | Research / definition only |
| [`herdr`](guix/tay/packages/herdr.scm) | `0.8.0` | Terminal workspace manager for AI coding agents | Research / definition only |
| [`nhfourk`](guix/tay/packages/nhfourk.scm) | `4.3.0.4` | NetHack 4 fork definition; module-load caveat recorded | Research / definition only |
| [`noctalia`](guix/tay/packages/noctalia.scm) | `5.0.0-0.ab2cfdf` | Desktop shell definition; outside normal build inventory | Research / definition only |
| [`raelives`](guix/tay/packages/raelives.scm) | `0.0.1-0.20140305` | Original RaeLives game definition | Research / definition only |

## Caveats

- **Provenance differs.** OpenCode, Claude, Halloy, ECA, Pi and the Slim desktop
  companion use upstream release binaries; some source applications rely on
  pinned prebuilt Electron, wheels, WASM or Godot. The [detailed record](ACCOUNTING.md)
  distinguishes source builds from binary-assisted ones and retains notices.
- **Desktop integration is manual.** Hy3 and Dualmaster match Hyprland 0.55.4;
  upgrade compositor and plugins together. Do not run Caelestia's Arch-oriented
  `install`/`update` commands on Guix configuration or launch competing shells/
  notification daemons together. PAM, capture privileges and backend services
  need separate setup. [Desktop details](ACCOUNTING.md#caelestia-shell).
- **Local state and credentials belong to the user.** Games and apps write to
  user HOME/XDG directories, not the store. Isolated smokes do not establish
  live service/provider use or physical hardware support. Caelestia panes retain
  sensitive plaintext local state; its documented SilverBullet endpoint uses
  LAN HTTP, and authenticated pane workflows remain operator-gated.
  [Pane privacy and setup](ACCOUNTING.md#persistent-native-service-panes-2026-10-03).
- **Historical software has limits.** Apout is not a sandbox; KLH10 supplies no
  guest operating system; SUPPTY's old SSH is not security-endorsed; tape-image
  proofs are not physical tape proofs. Potato deliberately disables insecure
  upstream TLS. Review the relevant receipt before connecting old clients.
- **Redistribution is package-specific.** Unknown-license snapshots and the
  authorized SentinelOne installer must not be published as substitutes without
  rights clearance. Never put installers, management tokens or credentials in
  Git; SentinelOne's `--with-source` also imports its artifact into the local
  store, and a non-substitutable flag alone does not protect `guix publish`.

## Documentation and contributing

- [ACCOUNTING.md](ACCOUNTING.md): complete source pins/hashes, licensing decisions,
  issue accounting, native proof receipts, package-specific usage and developer
  [validation commands](ACCOUNTING.md#validate).
- [PROJECTS.md](PROJECTS.md): source collection scope, inventories and exclusions.
- [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md): separate upstream notices.
- [Bell Museum report](reports/bell-museum.md) and [Rplaca report](reports/rplaca.md).
- [Desktop plugin guide](ACCOUNTING.md#hy3-layout-plugin),
  [Dualmaster guide](ACCOUNTING.md#dualmaster-layout-plugin),
  [Caelestia guide](ACCOUNTING.md#caelestia-shell),
  [FFglitch examples](ACCOUNTING.md#ffglitch-native-bitstream-editing-and-live-preview),
  [Praat examples](ACCOUNTING.md#praat-acoustic-analysis-native-files-and-the-gtk-editor).

**Contributor rule:** keep README an approachable guide. Put future receipts,
hashes, issue accounting, full proof details and developer checks in
`ACCOUNTING.md` or an existing focused report. Update program tables when
versions or deliveries change, retaining pending/blocked distinctions.
Forgejo is authoritative; GitHub `htayj/guix-channel` is the code push mirror.
After a verified Forgejo resolution, manually close its matched GitHub issue
counterpart—code mirroring does not synchronize issue closure.

## License

Channel-authored definitions, metadata, tests, reports and documentation are
**GPL-3.0-or-later**; see [LICENSE](LICENSE). This does not relicense upstream
applications, snapshots, fonts, data or other artifacts. Each retains its own
grants and required notices; see [licensing details](ACCOUNTING.md#license) and
[third-party notices](THIRD_PARTY_NOTICES.md).
