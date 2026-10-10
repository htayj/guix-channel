# Package accounting and detailed guides

This is the detailed record behind the [channel guide](README.md): source pins,
hashes, licensing analysis, issue dispositions, verification receipts, runtime
limitations, package-specific usage, and developer commands. It preserves the
previous README, including the unrelated Dualmaster and Caelestia panes work;
historical receipts are evidence for their dated output, not promises of current
publication or deployment.

## Keeping this record useful

Put future receipts, issue accounting, full native proof details, and developer
check commands here (or in an existing focused report), **not in README.md**.
Update the README's program tables when package versions or deliveries change.
Forgejo is authoritative. GitHub `htayj/guix-channel` is the code push mirror;
after verified Forgejo resolution, manually close the matched GitHub issue
counterpart. A mirrored code push does not close mirrored issues.

As of final local acceptance on 2026-10-04, **Allure and AloneRL are locally
verified**. Publication is established by the signed channel commit history,
not this receipt. The earlier AloneRL build gate below is retained as history
and superseded by [its final receipt](#alonerl-final-local-acceptance-2026-10-04).

## Finding details

- [Source collections and disposition](PROJECTS.md)
- [Package runtime receipts](#runtime-evidence-corrections)
- [Original channel setup](#add-the-channel)
- [Original package catalog and usage](#installable-packages)
- [FFglitch examples](#ffglitch-native-bitstream-editing-and-live-preview)
- [Praat examples](#praat-acoustic-analysis-native-files-and-the-gtk-editor)
- [Hyprland plugins](#hy3-layout-plugin)
- [Dualmaster layout and live evidence](#dualmaster-layout-plugin)
- [Caelestia desktop](#caelestia-shell)
- [Persistent native service panes](#persistent-native-service-panes-2026-10-03)
- [Historical Allure/AloneRL acceptance context](#alonerl-and-allure--allure-verified-alonerl-acceptance-pending) and [final AloneRL acceptance](#alonerl-final-local-acceptance-2026-10-04)
- [Developer validation commands](#validate)
- [License](#license) and [third-party notices](THIRD_PARTY_NOTICES.md)
- [Agduria, Wenyan and Ludvig Lundgren's qBittorrent CLI](#agduria-wenyan-and-ludvig-lundgrens-qbittorrent-cli--verified-native-paths)
- [Lispy Rogue, bodge-nuklear and LiteGraph](#lispy-rogue-bodge-nuklear-and-litegraph--verified-native-paths)
- [Medley and Maiko](#medley-and-maiko--verified-native-path)
- [Natron core host](#natron--verified-core-host-path)
- [Faugus Launcher GTK path](#faugus-launcher--verified-native-gtk-path)
- [Aidermacs Emacs extension path](#aidermacs--verified-native-emacs-extension-path)
- [Wanderers native save/restore path](#wanderers--verified-native-saverestore-path)
- [Affect libraries and isolated OCaml 5.5 toolchain](#affect--native-libraries-and-isolated-ocaml-55-toolchain)
- [Minttea terminal UI and isolated OCaml 5.2 closure](#minttea--native-terminal-ui-and-isolated-ocaml-52-closure)
- [Boohu official Guix reuse and native terminal save/restore](#boohu--official-guix-reuse-and-native-terminal-saverestore)
- [PDP11 native microcycle diagnostic](#pdp11--verified-native-microcycle-diagnostic)
- [PDP6 native panel memory path](#pdp6--verified-native-panel-memory-path)
- [Apout native V7 guest contract](#apout--verified-native-v7-guest-contract)
- [PDP10 XPL native compiler object semantics](#pdp10-xpl--verified-native-compiler-object-semantics)
- [PDP10 GCC assembler-free C code generation](#pdp10-gcc--verified-assembler-free-c-code-generation)
- [Tassh isolated native clipboard relay](#tassh--verified-isolated-native-clipboard-relay)
- [UC Explorer native microcode parser](#uc-explorer--verified-native-microcode-parser)
- [Blincolnlights native PDP-1 panel and PDP-5 memory path](#blincolnlights--verified-native-pdp-1-panel-and-pdp-5-memory-path)
- [Rust Effects offline library and external consumer](#rust-effects--verified-offline-library-and-external-consumer)
- [Meta Typing offline type-level library and external consumer](#meta-typing--verified-offline-type-level-library-and-external-consumer)
- [Rot.js source-built toolkit and offline consumer](#rotjs--verified-source-built-toolkit-and-offline-consumer)
- [Ink source-built React terminal renderer and native PTY consumer](#ink--source-built-react-terminal-renderer-and-native-pty-consumer)
- [Imago six-system image library and native consumer](#imago--six-system-image-library-and-native-consumer)
- [Bell Labs Rogue 7 standalone native gameplay/save continuity](#bell-labs-rogue7--standalone-native-gameplay-and-save-continuity)
- [Martin's Dungeon Bash native gameplay/save continuity](#martins-dungeon-bash--native-gameplay-and-save-continuity-2026-10-07)
- [Gruesome ordinary native terminal gameplay](#gruesome--ordinary-native-terminal-gameplay-2026-10-07)
- [Hunger Games ordinary native console gameplay](#hunger-games--ordinary-native-console-gameplay-2026-10-09)
- [Grippy Socks ordinary native console gameplay](#grippy-socks--ordinary-native-console-gameplay-2026-10-09)
- [CryptRover ordinary native terminal gameplay](#cryptrover--ordinary-native-terminal-gameplay-2026-10-09)
- [Dhack ordinary native terminal gameplay](#dhack--ordinary-native-terminal-gameplay-2026-10-09)
- [CoreRL ordinary native terminal gameplay](#corerl--ordinary-native-terminal-gameplay-2026-10-09)
- [CutlassRL ordinary native terminal save/restore](#cutlassrl--ordinary-native-terminal-saverestore-2026-10-09)
- [ChessRogue ordinary native Practice gameplay and retry](#chessrogue--ordinary-native-practice-gameplay-and-retry-2026-10-09)
- [Cave Chop ordinary native terminal save/restore](#cave-chop--ordinary-native-terminal-saverestore-2026-10-09)
- [Browsh ordinary native terminal browsing](#browsh--ordinary-native-terminal-browsing-2026-10-09)
- [Clojure-Roguelike native one-shot prototype render](#clojure-roguelike--native-one-shot-prototype-render-2026-10-09)
- [Astx native CTS loader and confirmed structural rewrite](#astx--native-cts-loader-and-confirmed-structural-rewrite-2026-10-09)
- [Persephil legacy PhiloLogic HTML to XLSX](#persephil--legacy-philologic-html-to-xlsx-2026-10-09)
- [CalcRogue native i686 gameplay and save continuity](#calcrogue--native-i686-gameplay-and-save-continuity-2026-10-09)
- [City of the Condemned original source and ordinary native gameplay](#city-of-the-condemned--original-source-and-ordinary-native-gameplay-2026-10-09)
- [Cracks and Crevices recovered source and native save/restore](#cracks-and-crevices--recovered-source-and-native-saverestore-2026-10-09)
- [dNetHack ordinary native gameplay and save continuity](#dnethack--ordinary-native-gameplay-and-save-continuity-2026-10-10)
- [DungeonMinder original source and ordinary native gameplay](#dungeonminder--original-source-and-ordinary-native-gameplay-2026-10-10)
- [Dwarftown original source and ordinary native gameplay](#dwarftown--original-source-and-ordinary-native-gameplay-2026-10-10)

## Relocation map (2026-10-04)

The previous README is retained below without dropping its substantive content.
Each previous README section anchor now lives at `ACCOUNTING.md#<same-anchor>`;
relative source, screenshot, test and report paths remain valid because this
file stays at the repository root. The small concurrent Caelestia pane UI update
was carried over before the README replacement.

| Previous README material | Current destination |
| --- | --- |
| Source collection overview and exclusions | Original overview below; maintained inventory in [PROJECTS.md](PROJECTS.md) |
| Source pins, hashes, licenses, issue dispositions and package runtime receipts | Corresponding unchanged heading below |
| Installable package table, full usage examples and dependency/build caveats | [Original catalog and details](#installable-packages); current categorized versions in [README.md](README.md#programs) |
| Hy3 and unrelated Dualmaster behavior, shortcuts and historical/live measurements | [Hy3](#hy3-layout-plugin), [Dualmaster](#dualmaster-layout-plugin) |
| Caelestia shell patches, setup, limitations and unrelated persistent service panes | [Caelestia shell](#caelestia-shell), [native service panes](#persistent-native-service-panes-2026-10-03) |
| Developer check/build commands and authentication note | [Validate](#validate) |

Older text intentionally records the state known at its stated date. The current
README supersedes its broad “installable” labels where build/publication gates
remain; especially, inclusion in the old table does not complete AloneRL.

## README inventory evidence (2026-10-04)

At the 2026-10-04 redesign, the README covered all **228** names declared by
`FONT_PACKAGES`, `PROJECT_PACKAGES` and the optional proprietary list in
`Makefile:29-67`, including entries missing from the old 156-row table. The
Tassh and PDP10 GCC acceptances on 2026-10-06 do not change that default
inventory. Of the **11** additional exported definitions originally listed
separately, **9** remain research-only: `noctalia`, `flaghack`, `flaghack-charm`,
`cavechop`, `raelives`, `herdr`, `drl`, `gsplat-wasm` and `nhfourk`. The other two,
`tassh` and `pdp10-gcc`, now appear under installable utilities and historical
computing respectively, with bounded native receipts. Neither joins the default
`make build` list; PDP10 GCC acceptance is assembler-free C code generation,
not assembly, linking or target execution.
UC Explorer's 2026-10-06 native acceptance promotes its existing “Defined” row
within historical computing, not a research-only entry: `uc-explorer` is already
in `PROJECT_PACKAGES` at `Makefile:42`. None of these inventory counts changes.
SporkHack's 2026-10-06 acceptance adds **one** new `PROJECT_PACKAGES` entry
and README program row, unlike those existing-entry promotions. The dated
228 redesign count is historical, not a recount of the current working tree.
The pre-SporkHack committed Makefile inventory contains **232** check names
(224 project + 7 font + 1 optional proprietary). This SporkHack-only change
raises that inventory to **233** (225 project + 7 font + 1 optional), without
including unrelated unpublished user additions.
The integrated working-tree inventory on 2026-10-06 contains **234** check
names (226 project + 7 font + 1 optional proprietary), versus 233 immediately
before adding SporkHack. This count includes unrelated unpublished user
changes, notably Dualmaster; it is **not** the published channel inventory
or evidence that those changes were accepted by the SporkHack task.
Rust Effects' 2026-10-06 acceptance adds exactly **one** `PROJECT_PACKAGES`
entry and one README library row. This is a separate +1 delta from the dated
SporkHack counts above, not a rewrite of that history. Its 35 private registry
crate sources are dependency closure, not 35 new top-level programs or source
snapshots. Unrelated unpublished changes, including Dualmaster and other
shared Makefile edits, remain outside the Rust Effects acceptance boundary.
The publisher verified the committed baseline at **`6275c4a`** as **233**
check names (225 project + 7 font + 1 optional proprietary). The Rust Effects-only
publication inventory is therefore **234** (226 project + 7 font + 1 optional).
The verified integrated working tree contains **235** (227 project + 7 font +
1 optional), with exactly two additions against that committed baseline:
Rust Effects and the unrelated unpublished Dualmaster entry. The 235 count
is not the Rust Effects publication inventory or acceptance of Dualmaster.
The earlier 234 integrated figure is the pre-Rust Effects snapshot, retained
as dated history.
Meta Typing's separate 2026-10-06 acceptance adds exactly **one**
`PROJECT_PACKAGES` entry and one README library row. Main's published baseline
`c7747f8` has **234** check names (226 project + 7 font + 1 optional
proprietary); the Meta-only candidate inventory is **235** (227 + 7 + 1).
The integrated working tree has **236**, including the unrelated unpublished
Dualmaster entry. That integrated count does not accept or publish Dualmaster,
and the candidate count is not itself evidence of Meta Typing publication.
Its 246 private npm test-tool archives are dependency closure, not top-level
programs or additions to the canonical 629 preservation snapshots.
Rot.js's separate 2026-10-06 acceptance adds exactly **one**
`PROJECT_PACKAGES` entry and one README library row. The committed baseline
`9029529` has **235** check names (227 project + 7 font + 1 optional
proprietary); the Rot-only candidate inventory is **236** (228 + 7 + 1).
The integrated working tree has **237**, including the unrelated unpublished
Dualmaster entry. That integrated count does not accept or publish Dualmaster,
and the candidate count is not itself evidence of Rot.js publication. Its 260
private npm build-tool archives and the private source-built Closure Compiler
closure are dependency closure, not top-level programs or additions to the
canonical 629 preservation snapshots; the existing `ondras-rot-js-source`
snapshot is unchanged.
Ink's separate 2026-10-07 delivery adds exactly **one** `PROJECT_PACKAGES`
entry (`node-ink`) and one README library row. The committed baseline
**`8b2aee2`** has **236** check names (228 project + 7 font + 1 optional
proprietary); the Ink-only candidate inventory is **237** (229 + 7 + 1).
The integrated working tree has **238** (230 + 7 + 1), including the unrelated
unpublished Dualmaster entry. The 238 count neither accepts nor publishes
Dualmaster, and the candidate count is not evidence of Ink publication.
Ink's npm/Cargo/compiler closures and source-built Yoga/SDK helpers are
dependencies, not extra top-level programs. The canonical **629** preservation
snapshots, including `vadimdemedes-ink-source`, remain unchanged.
PBUI's separate 2026-10-07 delivery adds exactly **one** `PROJECT_PACKAGES`
entry (`emacs-pbui`) and one README Emacs-tool row. The accepted baseline has
**237** check names (229 project + 7 font + 1 optional proprietary); the
PBUI-only candidate inventory is **238** (230 + 7 + 1). The integrated working
tree has **239** (231 + 7 + 1), including unrelated unpublished Dualmaster.
That count neither accepts nor publishes Dualmaster, and the candidate count
is not evidence of PBUI publication. PBUI reuses the existing
`mmontone-pbui-source` origin: its pin, hash and the canonical **629** source
snapshots remain unchanged, with only its license metadata corrected to
GPL-3.0-or-later. Propagated Emacs dependencies are not extra top-level programs.
Imago's separate 2026-10-07 candidate adds **one** `PROJECT_PACKAGES` library
entry (`sbcl-imago`) and one README library row, plus **five check-only SBCL
dependency recipes**, not five additional programs. The accepted baseline stays
**238** check names (230 project + 7 font + 1 optional proprietary) while #220
is OPEN. The source/ledger-derived Imago-only candidate is **244** check names
(231 project + 7 font + 1 optional + 5 dependencies); the integrated tree is
**245** (232 + 7 + 1 + 5), including unrelated unpublished Dualmaster.
Integrated installable names are **239** (232 project + 7 font), excluding
check-only dependencies and optional proprietary checks. These are definition
counts, not an executed inventory check or a new accepted/publication total.
The `libtiff/cl-libtiff` C variant is an exported dependency binding named
`libtiff`, deliberately excluded from explicit checks to avoid the stock-name
collision; it is not a private binding or another README program. The five
checked dependencies are `sbcl-zlib`, `sbcl-cl-jpeg-imago`,
`sbcl-common-lisp-jupyter-imago`, `sbcl-cl-libheif` and `sbcl-cl-libtiff`.
No dependency recipe changes the canonical **629** preservation snapshots.
Browsh's separate 2026-10-09 delivery adds exactly **one** `PROJECT_PACKAGES`
entry (`browsh`) and one README browser row. The scoped listed working-tree
inventory rises from **232 project + 7 font = 239 installable names** to
**233 project + 7 font = 240**. These text-list counts include preexisting
unpublished user entries such as Dualmaster: they are neither a new accepted
package total nor a claim that the complete inventory was built or checked.
Browsh's 36 private Go modules and 737 distinct npm source archives are
dependency closure, not extra applications. Its existing
`browsh-org-browsh-source` pin/hash and the canonical **629** preservation
snapshots remain unchanged.
Persephil's separate 2026-10-09 candidate adds exactly **one**
`PROJECT_PACKAGES` entry (`persephil`) and one README document-tool row.
The scoped textual inventory rises from **233 project + 7 font = 240**
installable names to **234 project + 7 font = 241**; including one optional
proprietary and five check-only dependencies gives **247** check names.
These are listed definition counts, not complete-inventory verification or
accepted/publication totals, and include preexisting unpublished user changes.
Its 214 npm installation paths and 204 distinct archives are private dependency
closure, not additional applications. The existing
`cookinrelaxin-persephil-source` pin/hash and canonical **629** preservation
snapshots remain unchanged.
CalcRogue's separate 2026-10-09 candidate adds exactly **one**
`PROJECT_PACKAGES` entry (`calcrogue`) and one README game row. The scoped
textual inventory rises from **234 project + 7 font = 241** installable names
to **235 project + 7 font = 242**; including one optional proprietary and five
check-only dependencies gives **248** check names. These counts describe the
lists, including preexisting unpublished user changes, not complete-inventory
verification, accepted-package totals or publication. CalcRogue does not add or
alter any of the canonical **629** preservation snapshots.
Architecture filtering does not remove CalcRogue from those textual inventories:
`I686_ONLY_PACKAGES` excludes it from default native `make build` and the
`make check` build dry-run, while preserving enumeration/lint coverage.
City of the Condemned's separate 2026-10-09 candidate adds exactly **one**
`PROJECT_PACKAGES` entry (`city-of-the-condemned`) and one README game row.
The scoped textual inventory rises from **235 project + 7 font = 242**
installable names to **236 project + 7 font = 243**; including one optional
proprietary and five check-only dependencies gives **249** check names.
These are listed definition counts, including preexisting unpublished user
changes, not complete-inventory verification, accepted-package totals or
publication. The canonical **629** preservation snapshots and CalcRogue's
`I686_ONLY_PACKAGES` filtering remain unchanged. The new source-built game is
not another preservation-ledger entry or a claim that all 249 names passed.
Cracks and Crevices' separate 2026-10-09 candidate adds exactly **one**
`PROJECT_PACKAGES` entry (`cracks-and-crevices`) and one README game row.
The scoped textual inventory rises from **236 project + 7 font = 243**
installable names to **237 project + 7 font = 244**; including one optional
proprietary and five check-only dependencies gives **250** check names.
These are listed definition counts, including preexisting unpublished user
changes, not complete-inventory verification, accepted-package totals or
publication. Recovery of the original 0.5 release does not add or alter any of
the canonical **629** preservation snapshots. CalcRogue's `I686_ONLY_PACKAGES`
filtering remains unchanged; neither the dependency closure nor the existing
source ledger becomes another end-user application or an all-250 pass claim.
DungeonMinder's separate 2026-10-10 candidate adds exactly **one**
`PROJECT_PACKAGES` entry (`dungeonminder`) and one README game row. File
inspection of the current Makefile lists gives **238 project + 7 font = 245**
installable names, up from **237 + 7 = 244** before this addition. Including
one optional proprietary package and five check-only Imago dependencies gives
**251** check names, up from 250. These are textual definition counts, not an
executed inventory check, accepted-package total or publication claim; unrelated
unpublished user entries remain included without being accepted by this task.
The private source-built libtcod dependency is not another application. The
canonical **629** preservation snapshots and CalcRogue's `I686_ONLY_PACKAGES`
default-native-build filtering remain unchanged.
Dwarftown's separate 2026-10-10 candidate adds exactly **one**
`PROJECT_PACKAGES` entry (`dwarftown`) and one README game row. Inspection and
textual counting of the actual Makefile lists gives **239 project + 7 font =
246** installable names, up from **238 + 7 = 245** after DungeonMinder. One
optional proprietary package and five check-only Imago dependencies give
**252** check names, up from 251. These are definition counts, not an executed
inventory check, accepted-package total, all-252 pass or publication claim;
unrelated unpublished user entries remain included without being accepted.
The private historical renderer and external Lua/SDL/zlib/Mesa dependencies
are closure, not more applications. The canonical **629** preservation
snapshots and CalcRogue's `I686_ONLY_PACKAGES` filtering remain unchanged.
Private dependency closures and the 629 source snapshots are not promoted to
end-user applications. The public library families intentionally in Makefile
remain covered, with desktop support libraries in their own small table.

Versions and descriptions were extracted from the linked `guix/tay/packages/`
definitions, resolving literal strings, constant `git-version` expressions and
inherited snapshot versions through `projects.scm`, `source-snapshot.scm` and
the existing collection modules. The inherited DankMaterialShell version is
0.5.1 in the selected installed Guix `gnu/packages/window-management.scm`
(`dank-material-shell` inherits `dank-material-shell-minimal`); selecting a
different Guix revision can change that inherited base. No guessed upstream
release versions or unresolved static metadata remain in the tables.

The conservative README “Verified” labels refer to dated receipts retained
below, not test filenames, a successful dry-run, a contract marker or a screenshot
alone. “Defined” avoids asserting native acceptance that is not established by
this guide. These labels do not establish publication or deployment. Allure and
AloneRL subsequently passed final local acceptance; see the dated receipt below.

This documentation-only reorganization ran **no commands, checks, tests, builds,
linters or formatters**. Rendered readability, inventory/link checks and final
package verification are owned by the integrating agent. No described host or
service changed, and no material network-catalog correction was established;
therefore no OKF page/log update applies to this repository-only guide rewrite.

## DungeonMinder — original source and ordinary native gameplay (2026-10-10)

The new [`dungeonminder`](guix/tay/packages/dungeonminder.scm) **0.8** recipe
builds Adam Gatt's original reverse roguelike and its historical renderer from
source. The player follows an autonomous hero and influences the dungeon with
spells; this is not a reconstructed engine, a copied release executable or an
installed proof hook. **#338 remains OPEN** because the package's literal own
release-discovery lint gate is unresolved. Local native evidence below does not
establish publication, deployment or a clean all-checker lint result.

### Exact source pins, positive grants and original font

The complete original single translation unit is
[`DungeonMinder.cpp`](https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/dungeonminder/DungeonMinder.cpp),
SHA-256 **`70674a831a67a4a7abe61174f5e0daefa9b3a0e85a67b5e427497dd395f42260`**,
Guix base32 **`0q12yjax6za94zjbarssx2hb7aggvbhgax0iwsmsg9373a1llrvh`**.
Its original **Copyright (c) 2009, Adam Gatt** notice permits redistribution
and modification subject to retaining the notice and disclaimer. The BSD-shaped
endorsement clause literally says the name **"may be used"**, not "may not be
used". The package preserves that wording as a **custom non-copyleft grant**;
it does not repair the text or mislabel the game as standard BSD-3-clause.
The exact notice is installed as `share/doc/dungeonminder/dungeonminder-license.txt`.

The private renderer is built from the primary
[`libtcod 1.4.0` source archive](https://codeload.github.com/libtcod/libtcod/tar.gz/refs/tags/1.4.0),
tag commit **`9ac2a3a526e7cefe8b7b330e37619bb1c4b6fb96`**, SHA-256
**`cbf7b636b8035b2ac686aa322d35d3b74cb5da8973bbd676796918395fb9d6cb`**,
Guix base32 **`1jynp5gkj639g5vddfvki7dbak5pscsjscmahv32lnq3p0vbdxyb`**.
Its global BSD-3-clause notice, credits, SDL README and font README are retained
under `share/doc/dungeonminder/`. Bundled `libSDL.so`, `SDL.dll` and `zlib1.dll`
are removed from the source input, not linked or installed as dependencies.

The installed `share/dungeonminder/terminal.png` is the unmodified primary
libtcod root font: **3150 bytes**, **128 × 128 pixels**, a **16 × 16** glyph grid
of **8 × 8** cells in column-major ASCII order; SHA-256
**`5e9e64246b857dc414bd0acde98820885274483580f751b9b3329b8ee86b82f4`**.
It is byte-identical to the font in the official
[`DungeonMinder v0.8 - Linux.tar.bz2`](https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/dungeonminder/DungeonMinder%20v0.8%20-%20Linux.tar.bz2)
release (archive SHA-256
**`d57e719d33b4dd34fd5e9d18f1d2220510033b2e2bbd09e0106d5e4fd6dc1242`**).
No game/library executable from that release is used. The primary font README
identifies the root asset as the non-antialiased terminal font carried forward
from libtcod 1.3.2. Distribution relies on the source tree's positive global
libtcod grant; no dedicated font author/license grant was found or invented,
and the unrelated Celtic Garamond credit is not attributed to this font.

The maintained local files have these SHA-256 hashes, obtained by file inspection
for this receipt, not by a build or test:

| Repository file | SHA-256 |
| --- | --- |
| [`files/dungeonminder-license.txt`](guix/tay/packages/files/dungeonminder-license.txt) | `32ef7a5f7a067ed6a0f2c0151b6d1ccc2379e59e47163810f2865b41795abacb` |
| [`files/dungeonminder-font-provenance.txt`](guix/tay/packages/files/dungeonminder-font-provenance.txt) | `84709fcd6bf1fb2dfe46e1a992e409aad42cba7c9792930efea4b929a6628bc7` |
| [`patches/dungeonminder-source-portability.patch`](guix/tay/packages/patches/dungeonminder-source-portability.patch) | `c87615348bd5e11d41f09c9ca6fa23240eccc30a4e83f5192ba5b43143b3f2ad` |
| [`patches/dungeonminder-libtcod-portability.patch`](guix/tay/packages/patches/dungeonminder-libtcod-portability.patch) | `63bfa1d1f7c4cfe2262511c163047d54b272d91546aff139e76b554c2cd372a2` |

### Source build and bounded native integration

The game is compiled with GNU C++98; libtcod's C/C++ shared libraries are built
from the pinned 1.4.0 source against Guix **sdl12-compat 1.2.68**, **libpng
1.6.39** and **zlib 1.3.1**. Game changes normalize archived CRLF endings,
provide direct standard declarations, fix the invalid qualified constructor,
and select the immutable original font using the historical
`setCustomFont(file, 8, 8, 0)` API. The renderer patch uses modern public libpng
accessors, pointer-sized `TCOD_list` heap slots with explicit offset/direction
conversions, and the existing SDL glyph mapper's explicit parameter prototype.
The original pathfinding algorithm remains; it is not replaced with a shortcut.
Build objects use a private build directory rather than shared `/tmp/libtcod`,
and the C++ library is linked with the C++ driver. Installed private libraries
live in `lib/dungeonminder/`, with store RUNPATHs, and `bin/dungeonminder` is the
ordinary native ELF game. No consumer helpers are installed in its output.

Main's source build **204 (14.31 s)**, retained in **artifact 16999**, produced
**`/gnu/store/3xl6h19rsfnzkjgz2ylw3fny3svhcac3-dungeonminder-0.8`**.
Reproducibility check **206 (12.56 s)**, **artifact 17002**, rebuilt the same
derivation/output successfully. Upstream supplies no test suite; the build log
explicitly says `test suite not run`, not an upstream test pass.

The external [`tests/dungeonminder-smoke.sh`](tests/dungeonminder-smoke.sh) and
[`tests/dungeonminder-native.py`](tests/dungeonminder-native.py) consume that
prebuilt output. Main's integrated `make check-dungeonminder` run **208
(37.38 s)** passed with evidence in **`/tmp/dungeonminder-native-3`**. The
separate standalone run **209 (20.50 s)** subsequently passed with evidence in
**`/tmp/dungeonminder-native-4`** and `DUNGEONMINDER_NATIVE_OK`. Both retained
`native-result.json` files report success, and `shell-result.json` records
`driver_status: 0` and `nar_unchanged: true`.

The installed game runs in the consumer's Xvfb display; ordinary focused XTEST
keyboard events drive its original menus and gameplay. Native captures, raw
XWD/RGB data and decoded original-font cells establish:

- Initial original **80 × 60** map/HUD, Level 1, hero health, power and welcome.
- `Tab` opens the original spell menu; `Escape` dismisses it without a turn or
  framebuffer change. `m` opens message history; dismissal also takes no turn.
- `Tab`, then `q`, casts **PACIFISM**, produces **"The hero appears calmer!"**
  and lowers visible hero-school power from five blips to four.
- Ordinary movement enters adjacent empty floor selected from the observed
  framebuffer, not a hard-coded seed or injected state.
- `Tab`, then `d`, casts **CLOUD**, produces **"A thick cloud of smoke appears
  around you!"**, lowers world-school power from five blips to two, and renders
  native green smoke around the player. Main also inspected the integrated PNG,
  seeing rooms/corridors, actors, smoke and the actual message rather than a
  blank/error surface.
- Eight ordinary `SPACE` turns advance the autonomous hero/world. Ordinary
  `Escape` then exits naturally with status **0**, not a timeout or forced kill.

The receipt records distinct user/mount/network/PID namespaces, current-user
UID/GID mapping (**1000/998**, not root identity), a route-free private network,
private HOME/XDG/tmp/CWD directories and read-only `/gnu/store` mounts. External
consumer tools are audited separately from the game's runtime closure. The
integrated output's before/after recursive NAR hash is identical:
**`1hr3wmqgncgr7a1w6qvxhw5l2c6ygxfcb65kvybgah1l08gbwgy8`**.
These are bounded isolation observations, not a general security certification.
Upstream has **no save/load implementation**; no invented save feature or
save-continuity claim is added. Acceptance covers early ordinary gameplay, not
all spells, all ten levels or a completed campaign.

### External consumer command and remaining lint gate

The integrated and standalone paths require a canonical already-built direct
store output and an absolute **fresh nonexistent** evidence directory (an
existing empty directory is not accepted):

```sh
make check-dungeonminder DUNGEONMINDER_OUTPUT=/gnu/store/3xl6h19rsfnzkjgz2ylw3fny3svhcac3-dungeonminder-0.8 DUNGEONMINDER_EVIDENCE=/tmp/dungeonminder-new-evidence
# Standalone external path, using another fresh nonexistent directory:
sh tests/dungeonminder-smoke.sh /gnu/store/3xl6h19rsfnzkjgz2ylw3fny3svhcac3-dungeonminder-0.8 /tmp/dungeonminder-standalone-new-evidence
```

Main exercised the missing-variable Makefile guard: the invocation was rejected
before consumer launch, outer make exit **2**. Only external consumer tools are
realized by the smoke; it does not silently build the game. These commands do
not use Goocastle executors, proof/contracts or an installed smoke hook.

Main's literal full own lint **202 (39.77 s)** did **not** establish a clean
result: DungeonMinder's generic-HTML release discovery attempts the Google
Storage download directory and fails with **HTTP 403**. The unrelated global
Flex warning is separate, not attributed to DungeonMinder or used to dismiss
its own failure. No checker was excluded and no updater success is inferred
from the successful fixed source download. **#338 stays OPEN**; no tracker
closure or deployment is claimed. Implementation publication is established
separately by the subsequent dated receipt below, not by native evidence.

Main owns all executed checks. This documentation worker inspected files and
existing evidence and ran no checks, builds, tests, linters or applications.
The independent **629** source ledger and unrelated changes are preserved.
No user profile, described host/service or material network-catalog fact changed;
no OKF page/log update applies to this repository-only packaging receipt.

### Subsequent signed implementation publication (2026-10-10)

After the local evidence above, the publisher delivered signed implementation
commit
[`4280ec889d85f32e1ed404805650fe1a880f93b9`](https://forge.nogroup.group/tay/guix-channel/commit/4280ec889d85f32e1ed404805650fe1a880f93b9),
parent **`5b3710d7b95a892077b60c51f1c4a9cbe21a10f1`**, with subject
**"feat: package original DungeonMinder and verify native spell gameplay"**.
The local signature status was **G**, fingerprint
**`6A27F433DC22B4DFA278E8F32F12E6A35F417606`**. Exact-OID Guix channel
authentication passed, and the normal pre-push hook independently authenticated
the same OID. The ordinary **`git push origin master`** published only to
authoritative Forgejo; no force push or direct GitHub push was performed.

The publisher observed the exact OID on SSH `master` and authenticated Forgejo
master/commit/signature API responses (**200**), with
**`verification.verified: true`**, signer **`tay / 2F12E6A35F417606`**. These
receipts establish publication of the implementation, separately from Main's
build/reproducibility/native observations. They do not establish installation
in a user profile, deployment, a clean lint result or tracker closure.
**#338 remains OPEN** for its actual own Google Storage directory **HTTP 403**
release-discovery gate. The tracker worker subsequently posted matching dated
evidence comments on [authoritative Forgejo](https://forge.nogroup.group/tay/guix-channel/issues/338#issuecomment-3316)
and the [GitHub tracker mirror](https://github.com/htayj/guix-channel/issues/338#issuecomment-6094310309).
Both comment POSTs returned **201** and exact-comment GETs **200**, with exact
matching bodies verified. Both issues remained **OPEN**; all prior labels,
including `state:blocked` and `state:research`, and original bodies/history
were preserved. The paired `browser-tracker-wave17-receipt.json` records these
actions and independently read the exact published authoritative master and
commit verification. This is a bounded published-evidence update, not issue
closure or acceptance of the unresolved lint gate.

## Dwarftown — original source and ordinary native gameplay (2026-10-10)

The new [`dwarftown`](guix/tay/packages/dwarftown.scm) **1.0** recipe preserves
hmp's original 2011 Lua roguelike, original fonts and native libtcod interface.
Its Lua binding and private historical renderer are source-built, not copied
release binaries or a reconstructed game. **#341 remains OPEN** for literal
own updater/archive lint findings. The local build, reproducibility and native
evidence below are separate from signed publication, tracker closure and
deployment. Subsequent implementation publication is established by the dated
publication receipt below, not by native acceptance.

### Exact source pins and positive license scopes

The source audit is retained in
`/home/tay/.cache/omp/audits/dwarftown-20261010/manifest.json` and
`audit-conclusions.json`, retrieved **2026-10-10**. It compares the original
[1.0 release](https://pwmarcz.pl/dwarftown/dwarftown-1.0.tgz) with the pinned
[game source](https://codeload.github.com/pwmarcz/dwarftown/tar.gz/9488ae4ec385459ed6c8d15a642e43c8a11607f7),
commit **`9488ae4ec385459ed6c8d15a642e43c8a11607f7`**, archive SHA-256
**`8676211b5b461de333393f6b93a870ea00a81b2391f1a85d9cc2b8327379588b`**,
Guix base32 **`12sqg5rk5f62kifsiwci4cdsh07af2l96srz74ry67a6bcdj2xl6`**.
All common files are byte-identical; the pin alone has `.hgignore`, and the
release alone has an example `character.txt`. The release archive SHA-256 is
**`c55277fe48289b7e7d79f4986892f000e6809e6846ff8ad99b769820d1dd6226`**.

`LICENSE.txt` grants project-owned material under **MIT**, **Copyright (c)
2011 hmp**, without limiting that grant to Lua code or excluding its own
wrapper adaptations/assets. Copied third-party portions retain their separate
grants. The private [official libtcod 1.5.1 source](https://codeload.github.com/libtcod/libtcod/tar.gz/a7cabfda0b0c770d4092f0dec02efbd2a3b6d990)
is pinned to **`a7cabfda0b0c770d4092f0dec02efbd2a3b6d990`**, SHA-256
**`90f2ade3e2651ae5f0fedeb6b9bae0ad57acfbf6e515a8b1dc85dc8663820827`**,
Guix base32 **`09q8h9iqdp45vjqsh5g5yvxsqmxdw2xbkdnyzvqfa6k5wbisvwlh`**.
Its 678 source-tree files match the official 1.5.1 tag byte-for-byte. The actual
global **BSD-3-clause** notice names **Copyright (c) 2008, 2009, 2010, 2012
Jice & Mingos**. That official distribution contains the SWIG interface and
`BackgroundHelperFunctions.hpp`; the latter is identical to the game copy.
Chris "donblas" Hamons's wrapper credit complements that positive global grant,
not a substitute for license evidence. Dwarftown's Lua-specific interface and
callback adaptations remain project-owned MIT material.

The embedded **LodePNG 20120729** source retains its **zlib-style** grant,
Copyright (c) 2005–2012 Lode Vandevenne. External SDL retains its LGPL scope;
external **Lua 5.1.5** retains its actual MIT notice, Copyright (C) 1994–2012
Lua.org, PUC-Rio. The package installs the game/wrapper notices, official
libtcod license/credits/SDL README, complete LodePNG source/header, Lua
`COPYRIGHT`, and [`dwarftown-provenance.txt`](guix/tay/packages/files/dwarftown-provenance.txt)
under `share/doc/dwarftown/`. It does not relicense the dependency closure as MIT.

### Original fonts, not a blanket public-domain claim

The active **10 × 18** font, `fonts/terminal10x18.png`, is **2337 bytes**,
**160 × 288 pixels**, SHA-256
**`12bcd54b30b2eab6fd85e87d78781ab8064ef792df0d23bba254cc407ad51fe7`**.
It is identical between the game pin and release. History records its addition
by hmp in commit **`39b34e3d2e8cd61540d4bab845014be24d74cd0b`** on **2011-03-05**,
without third-party credit. Distribution of project-owned font material rests
on the positive project MIT umbrella grant; history establishes inclusion,
**not independently proven pixel authorship**. No separate third-party author
or upstream provenance was established. The exact font is not byte-identical
to any PNG in official libtcod 1.5.1 or 1.5.0. The similarly sized official
`terminal10x18_gs_ro.png` differs in **11,450 pixels**; this is not a
transcoding-only match or evidence that the game's font is public domain.

The retained **8 × 8** copies, `fonts/terminal.png` and `wrapper/terminal.png`,
are **3150 bytes**, **128 × 128 pixels**, SHA-256
**`5e9e64246b857dc414bd0acde98820885274483580f751b9b3329b8ee86b82f4`**.
They exactly match official **1.5.1 `ascii-paint/terminal.png`**, and official
1.5.0's root font, with positive official global BSD-3-clause grant evidence.
They do **not** match 1.5.1's root font. The public-domain statement in official
`data/fonts/README.txt` applies to that directory, not every bitmap in the
archive or the distinct game 10×18 asset. No blanket public-domain designation
or replacement font is introduced.

### Source build and separately checked outputs

Archived interpreters, executable/library copies and pregenerated wrapper code
are removed. **SWIG 4.0.2** regenerates the original interface using
`-c++ -lua -squash-bases`, and GNU C++98 compiles `libtcodlua.so` against
external **Lua 5.1.5** and source-built **libtcod 1.5.1** C/C++ libraries.
The renderer uses **sdl12-compat 1.2.68**, **zlib 1.3.1**, **Mesa 26.0.2** and
its shipped LodePNG codec, not DungeonMinder's external-libpng path. Store
RUNPATHs retain the exact dependencies; private build objects replace shared
`/tmp`, and the C++ shared library is linked with the C++ driver.

The actual [`portability patch`](guix/tay/packages/patches/dwarftown-libtcod-portability.patch)
is applied after normalizing the two archived **CRLF** files, with
**`patch --fuzz=0`**. It declares the existing SDL glyph mapper's three `int`
parameters and provides **`uint32` storage** to the PNG file-read API, then
**widens the returned value to `size_t`** for LodePNG. It does not cast a
`size_t *` to `uint32 *`, mask a diagnostic, or alter gameplay/rendering logic.

Main's source build **214 (14.74 s)**, **artifact 17091**, produced
**`/gnu/store/4j8wpw6cb8l2bhn3az2j62hzxbpjdzvi-dwarftown-1.0`** and private
**`/gnu/store/vbn90w1imdqx3fj0qmzl2wcw6qsksz1i-dwarftown-libtcod-1.5.1`**.
Game reproducibility check **216 (6.74 s)**, **artifact 17094**, rebuilt and
checked the game output. Main separately checked the private renderer with
`guix build -L guix --no-grafts --no-offload --check -e '(@@ (tay packages dwarftown) dwarftown-libtcod)'`:
**229 (8.00 s)**, **artifact 17118**, passed for the same private renderer
output. These are two independent output checks, **not a rebuild/check of the
entire transitive dependency closure**. Neither package has an upstream
automated suite; `test suite not run` is not an upstream test pass.

The ordinary launcher executes store Lua and store game sources. Module and
font paths are immutable, while native `character.txt`, error `log.txt` and
F11 screenshots remain in the caller's writable working directory. No proof
helpers or special gameplay mode are installed. Upstream has **no save/load**:
the character dump is a text report, not a resumable game state.

### Ordinary native SDL gameplay and bounded dump oracle

The external [`tests/dwarftown-smoke.sh`](tests/dwarftown-smoke.sh) and
[`tests/dwarftown-native.py`](tests/dwarftown-native.py) consume the exact
prebuilt output. Main's integrated `make check-dwarftown` run **227 (19.42 s)**
passed with **`/tmp/dwarftown-native-10`** evidence. The separate standalone
run **228 (15.56 s)** passed with **`/tmp/dwarftown-native-11`** evidence and
**`DWARFTOWN_NATIVE_OK`**. Both retain successful `native-result.json` and
`shell-result.json` with **`driver_status: 0`**, **`nar_unchanged: true`**.

The genuine installed Lua process loads the source-built module/renderer in
the consumer's Xvfb display. Focused native **XTEST keyboard events** drive
the original interface, including held keys for help and modal cancellation.
Captures retain PNG/XWD/RGB and decode the actual original-font glyphs:

- The original **80 × 25**, **800 × 450** title/game surface shows a green
  forest, white `@`, legible HUD and **"Find Dwarftown!"** objective; Main's
  visual inspection found a real readable game rather than an error surface.
- A legal forest movement selected from observed terrain advances turn **0
  → 1**. The centered player is accompanied by exact terrain scrolling:
  integrated **206/206** overlapping cells and standalone **162/162** match.
- Ordinary period wait advances the world clock: integrated **1 → 5** and
  standalone **1 → 3**. Held-key SDL repeat means a wait event is not asserted
  to be exactly one world turn.
- `i` shows **torch** and **potion of health**; cancellation restores the
  gameplay view without advancing the turn. Help opens and dismisses without
  a world turn. `q` opens a quit prompt and cancellation resumes gameplay.
- Ordinary **Escape, then `y`** exits naturally with **status 0** and writes
  a character dump with **"Quit the game"**, final turn **5** (integrated) or
  **3** (standalone). Final map/HUD match the X11 capture exactly; inventory
  lines match the observed inventory.
- Dump messages match the **observed history prefix**, not an invented
  full-list equality. Both runs have **two additional original `Quit? [yn]`
  prompts** from SDL held-key repeat. Every glyph in the dump's rendered
  message pane matches the verified history; these extra text-history prompts
  do not justify a stronger complete-message-list claim.

Zero status alone is insufficient because upstream's error handler also exits
0. The consumer instead checks real rendering/actions, natural exit, logs and
dump content. Selecting consumer-side software Mesa/llvmpipe resolves the
observed GPU-device permission failure without suppressing errors or patching
the game. This does not verify physical GPU access or hardware acceleration.

Evidence records separate user/mount/network/PID namespaces, current-user
UID/GID mapping **1000/998**, private HOME/XDG/tmp/CWD, no external network
route, and read-only store mounts. External consumer tools are audited
separately from the runtime closure. The output's before/after recursive NAR
hash is unchanged:
**`1nvlg936gv79wvgyyghsbc0wjylh16qny1h5fdf2m9hacvs6fwl2`**.
These are bounded isolation observations, not a security certification or
all-gameplay/completed-campaign proof. No save-continuity claim is made.

### External consumer command and remaining lint gates

Use the canonical already-built direct store output and an absolute **fresh
nonexistent** evidence directory outside the store (an existing empty directory
is not accepted):

```sh
make check-dwarftown DWARFTOWN_OUTPUT=/gnu/store/4j8wpw6cb8l2bhn3az2j62hzxbpjdzvi-dwarftown-1.0 DWARFTOWN_EVIDENCE=/tmp/dwarftown-new-evidence
# Standalone external path, using another fresh nonexistent directory:
sh tests/dwarftown-smoke.sh /gnu/store/4j8wpw6cb8l2bhn3az2j62hzxbpjdzvi-dwarftown-1.0 /tmp/dwarftown-standalone-new-evidence
```

Main exercised the missing-variable guard: make exits **2 before launch**.
The smoke realizes only external consumer tools, never silently builds the
game, and uses no Goocastle executor, proof/contracts or installed hook.

Main's literal final full own lint **225 (98.42 s)** did **not** establish a
clean result: own **no-updater**, **Software Heritage** and **Disarchive**
findings remain. The package formatting finding was fixed; unrelated global
Flex warnings are separate, not attributed to Dwarftown or used to excuse its
own findings. No checker was omitted or warning suppressed. **#341 stays OPEN**;
native acceptance does not close the issue or establish signed publication.

Main owns all executed checks. This documentation worker inspected source and
existing evidence and counted textual definitions only; it ran no checks,
builds, tests, linters or applications. The independent **629** source ledger,
unrelated changes and i686 filtering are preserved. No user profile or
described host/service changed; no OKF page/log update applies to this
repository-only packaging receipt.

### Subsequent signed implementation publication (2026-10-10)

After the local evidence above, the publisher delivered signed implementation
commit
[`a4e41b43af85695441ab37a9050ab1ee70f2d1c3`](https://forge.nogroup.group/tay/guix-channel/commit/a4e41b43af85695441ab37a9050ab1ee70f2d1c3),
parent **`a76d8596dd57215f9511f70356b2b48a912a85ce`**, with subject
**"feat: package original Dwarftown and verify native forest gameplay"**.
The local signature status was **G**, fingerprint
**`6A27F433DC22B4DFA278E8F32F12E6A35F417606`**. Exact-OID Guix channel
authentication passed, and the normal pre-push hook independently authenticated
the same OID. The ordinary **`git push origin master`** published to
authoritative Forgejo; no force push, history rewrite or direct GitHub push was
performed.

The publisher observed the exact OID on SSH `master` and authenticated Forgejo
master/commit/signature API responses (**200**), with
**`verification.verified: true`**, signer **`tay / 2F12E6A35F417606`**. The
isolated publication index included only the eight owned implementation files
and Dwarftown hunks; unrelated work, the **629** preservation ledger and i686
filtering remained preserved. These receipts establish implementation
publication, separately from Main's build/native observations. They do not
establish installation in a user profile, deployment, a clean lint result,
tracker closure or reproducibility of the entire transitive dependency closure.
**#341 remains OPEN** for the actual own no-updater, Software Heritage and
Disarchive lint findings.


The tracker worker subsequently posted matching dated evidence comments on
[authoritative Forgejo](https://forge.nogroup.group/tay/guix-channel/issues/341#issuecomment-3319)
and the [GitHub tracker mirror](https://github.com/htayj/guix-channel/issues/341#issuecomment-6100739694).
Both comment POSTs returned **201** and individual authenticated exact-comment
GETs **200**, with matching bodies verified. Both issues remained **OPEN**;
their original bodies/history and all workflow/non-workflow labels, including
`state:blocked` and `state:research`, were preserved. The paired
`browser-tracker-dwarftown-receipt.json` independently records exact published
Forgejo master/commit identity and verified signature through API **200**.
This is a published-evidence correction, not issue closure, a lint waiver or
deployment. The tracker comments supersede the historical binary-only/no-wrapper
source conclusion while retaining the genuine remaining own lint gates.


## dNetHack — ordinary native gameplay and save continuity (2026-10-10)

Local acceptance covers the existing [`dnethack`](guix/tay/packages/dnethack.scm)
**3.26.0** package, not another application or preservation snapshot. It remains
in the existing `PROJECT_PACKAGES` inventory. The canonical **629** source
snapshots, source pin/hash, listed-package counts and CalcRogue's
`I686_ONLY_PACKAGES` default-native-build filtering are unchanged.
**#331 is CLOSED on both trackers after signed implementation publication**.
The actual publication and closure receipts below, not a README status alone,
establish that disposition; no deployment is claimed.

### Complete source, distribution notices and ordinary launcher

The recipe retains the complete
[`Chris-plus-alphanumericgibberish/dNAO` source](https://github.com/Chris-plus-alphanumericgibberish/dNAO/tree/a6f0a1c43e66f4fb1bcac34d7d9709706682ec19)
at **`a6f0a1c43e66f4fb1bcac34d7d9709706682ec19`**, Guix base32 SHA256
**`0lakz0czfkymnnb64q7yjvm3r3yfj3xqbylrha3cpc2ix07x0cvj`**.
Serial `make all CC=gcc` compiles the ordinary Unix tty game, yacc/flex
generators and generated dungeon/data archive; it does not install a substitute
engine or use a downloaded game binary. Version metadata and build timestamps
are fixed to the preserved revision and epoch **1779991412**. The standalone
server-admin-message hook is disabled, not the native game/save paths.

The output installs `bin/dnethack`, `libexec/dnethack-real`,
`share/dnethack/{nhdat,license}`, and upstream README/Guidebook/fixes documents
under `share/doc/dnethack`. The NetHack General Public License covers the game
and generated data. Its paragraphs **2(a)** and **3(a)** require dated
modification notices and complete accompanying machine-readable source.
`share/doc/dnethack/dnethack-source.tar.gz` contains the complete build source
before compilation, with retained upstream copyright/license notices and
prominent **2026-10-10** Guix modification notices in `GNUmakefile`,
`include/config.h` and `util/makedefs.c`. Sorted archive names, fixed timestamps,
numeric owner/group zero and Guix gzip timestamp normalization make this source
distribution deterministic. The included `util/MacroMagicMarker.py` retains its
full MIT/Expat permission and warranty grant; it is source, not an installed
runtime generator. The recipe records NGPL and Expat, and the build's
`verify-license-notices` phase checks the installed license/docs/source archive.

The normal launcher uses **`${XDG_DATA_HOME:-$HOME/.local/share}/dnethack`**
as the persistent native playground, with `umask 077` and mode-0700 state,
`save`, `dumplog` and `whereis` directories. Native saves, level/character locks,
bones, recovery state and score/log/mailbox files stay there; only `nhdat` and
`license` are symlinks into the immutable store. `MAIL` is private, and
`HACKDIR`/`NETHACKDIR` name the persistent playground. It uses store-bound shell
and coreutils paths and forwards normal arguments directly to the native game.
There is **no installed `--guix-smoke` mode or proof helper**. Python/pyte and
util-linux namespace tools belong only to the external test harness, not the
game's runtime closure.

### Main-owned build, reproducibility and lint gates

Main's final source build **bg189** passed in **121.44s** (build log
**artifact16864**) for derivation
`/gnu/store/1bcj3ksc0v3ra8yrxj3rf0cii1g6v23g-dnethack-3.26.0.drv`, producing:

```text
/gnu/store/2fcxcrcrp1sm6rfj6z2vhc7fy3jhrd1x-dnethack-3.26.0
```

The final **bg192 `--check` rebuild passed in 119.32s**, reproducing that exact
output (build log **artifact16868**). Both logs show actual source compilation,
data generation and installed notice verification. Main used:

```sh
guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 --keep-failed -e '(@ (tay packages dnethack) dnethack)'
# Reproducibility gate: the same invocation with --check.
```

Dependencies may be substituted; the target was actually built from source.
Final **full package lint bg190** exited **0** in **26.40s** with **no dNetHack
findings**. Main's short inline result retained only the unrelated global
deprecated-`flex` module warning (use `(gnu packages compiler-tools)` instead).
This is a **clean own-package lint** result, not a claim that every repository
package or global module warning is clean. No lint artifact ID is asserted.

### Ordinary gameplay and native save/restore evidence

Main's integrated **bg193** `make check-dnethack` passed in **21.76s**, retaining
`/tmp/dnethack-native-2`; the separate external **bg194** consumer passed in
**11.59s**, retaining `/tmp/dnethack-native-3`. Each `continuity.json` reports
`success: true`, exact full-map/HUD/inventory continuity, native save consumption
on restore and both games' natural zero-status exits. Raw `.pty`, redraw bytes,
`*.screen.txt`, input offsets, process metadata and the copied native save are
retained beside the structured receipt; the evidence save is **never reinjected**.

Both runs start the ordinary installed launcher as **NativeDNet**, a lawful
human female Valkyrie, with `-u NativeDNet -p Valkyrie -r human`, not `-X`,
explore/debug mode, a seeded world, fabricated save or injected state.
`/proc` identifies the real `libexec/dnethack-real` process and its persistent
XDG working directory. Inventory opens on the native tty; a legal movement
and two native searches advance **T:1 → T:4**. `S` and `y` create the game's
native `save/1000NativeDNet` and exit **0**. A genuinely independent second
process consumes that save through the ordinary restore path, preserving the
entire discovered 80×21 map, exact player coordinate, both HUD lines, statistics
and all eight inventory entries with equipment/quantity descriptions.

| Evidence | Initial → saved/restored coordinate | Saved/restored native HUD | Native save |
| --- | --- | --- | --- |
| `dnethack-native-2` | `(48,3) → (49,3)` | `Dlvl:1 $:0 HP:16(16) Pw:4(4) Br:4 AC:2 DR:1 Exp:1 T:4` | **274480 bytes**, SHA256 `8559ae4928a9c22827d99c373d83f912ae9b287a3833736675d449659fab6862` |
| `dnethack-native-3` | `(67,6) → (66,6)` | `Dlvl:1 $:0 HP:16(16) Pw:5(5) Br:4 AC:3 DR:1 Exp:1 T:4` | **274984 bytes**, SHA256 `6186d4a9c4309ea089a3eaa745ff68ee507f876774927c0d44e3256eaab1fd19` |

Coordinates are zero-based in the native map viewport, not terminal-row
coordinates. These independently generated worlds differ; continuity is exact
**within each run**, not asserted between runs. Both native saves have the
32-byte native-endian four-uint64 version header, incarnation `0x31a0000`,
features `0x3e0c86`, entities `0x15c36c483` and struct sizes `0x162085b50`.
The restored `whereis` record independently reports `Val/Hum/Fem/Law`, depth 1,
HP 16/16 and turns 4. Continued native movement and searches advance to **T:7**
before `#quit`, `y` and normal final disclosure acknowledgement exit **0**.
The save has been consumed and native character locks removed by the game,
not by killing it or fabricating cleanup success.

Each consumer starts with an empty inherited environment, private HOME/XDG/
TMPDIR, empty `PATH`, `LC_ALL=C` and `TERM=xterm-256color`, in private user,
mount, PID and network namespaces. All real/effective/saved/fs UID fields remain
**1000** and GID fields **998**, with matching same-ID namespace mappings, not
root mappings. Only `lo` is present, `/gnu/store` is recursively read-only and
host game paths are unchanged. Mutable state is retained only in each private
evidence tree. The output NAR is unchanged before/after **both** consumers:

```text
1daaialr4wm3rkxps0qj1p1zv6nx3hk8ax436kldwimj6d138dny
```

### External consumer command and remaining limits

The native consumer requires an already-built canonical store output and a
fresh, nonexistent absolute evidence directory outside the store. It does not
build or realize dNetHack/source. Main exercised the missing-variable guard:
it rejected the invocation before consumer execution (outer check exit **2**).

```sh
make check-dnethack DNETHACK_OUTPUT=/gnu/store/2fcxcrcrp1sm6rfj6z2vhc7fy3jhrd1x-dnethack-3.26.0 DNETHACK_EVIDENCE=/tmp/dnethack-new-evidence
# Standalone external path, using another fresh evidence directory:
sh tests/dnethack-smoke.sh /gnu/store/2fcxcrcrp1sm6rfj6z2vhc7fy3jhrd1x-dnethack-3.26.0 /tmp/dnethack-standalone-new-evidence
```

Upstream provides no non-interactive test target; build logs explicitly say
`test suite not run`. No upstream-suite test count is invented. Acceptance
covers ordinary early tty gameplay, native save/restore and continued play,
not every role/race/branch, a completed campaign or long-running server play.
The obsolete installed-proof contract tracked by **#679** is retired without
a replacement contract; its historical PNG is retained as historical evidence,
not substituted for the actual native game/continuity records above. Main owns
all executed checks; this documentation worker read the evidence and ran none.
No user profile, described host/service or material network-catalog fact changed;
no OKF page/log update applies to this repository-only packaging receipt.

### Signed implementation publication and actual tracker closure

On **2026-10-10**, signed implementation commit
[`d544aa4a8af2ad11dd26b9a980f67fc08bb6decd`](https://forge.nogroup.group/tay/guix-channel/commit/d544aa4a8af2ad11dd26b9a980f67fc08bb6decd),
parent `bc38e90d197ef51f3a5250e8186ca7cf35c95c65`, was published to authoritative
`origin master` by normal authenticated push. The publisher verified exact-OID
Guix authorization, local signature and remote OID. The tracker worker
independently read the exact published master OID and commit API signature
`verification.verified: true`, signer `tay/2F12E6A35F417606`. This establishes
publication of the accepted implementation, not installation in a user profile
or deployment of a described service.

The tracker worker then posted the exact acceptance evidence and closed #331
on [authoritative Forgejo](https://forge.nogroup.group/tay/guix-channel/issues/331#issuecomment-3309)
and the [GitHub tracker mirror](https://github.com/htayj/guix-channel/issues/331#issuecomment-6094024114).
Both comment POSTs returned **201**, exact-comment GETs **200**, and subsequent
issue GETs **200** with state **closed**; closure returned **201** on Forgejo
and **200** on GitHub. Only obsolete `state:blocked`/`state:research` labels were
removed; nonworkflow labels and original issue bodies/history were retained.
Historical #679 remains closed and untouched. The retained
`browser-tracker-dnethack-closure-receipt.json` records these separate actions
against the published implementation and the Main-owned native/build/repro/lint
evidence above. Neither tracker nor documentation workers reran acceptance
checks or applications. This dated documentation correction records the actual
closure after publication; it does not retroactively claim closure in the
earlier prepublication receipt.

## Cracks and Crevices — recovered source and native save/restore (2026-10-09)

The new [`cracks-and-crevices`](guix/tay/packages/cracks-and-crevices.scm)
**0.5** package compiles Stu George's complete original C/SDL 1.2 game,
reporting **v0.05/0757**, not a reconstructed engine or copied executable.
The [original attachment 32](https://redmine.bloodycactus.com/attachments/download/32/cracks_and_crevices-0.5.tar.bz2)
was recovered from its [2015-08-04 Wayback snapshot](https://web.archive.org/web/20150804175538if_/https://redmine.bloodycactus.com/attachments/download/32/cracks_and_crevices-0.5.tar.bz2):
**121192 bytes**, SHA-256
**`a00cf6ab0a189673fe152f9325b14c1a6b6a531a8510d1cc321c44ccdeb9fb66`**,
Guix base32 **`0rpvp7gcqi0w6b6d2445399nlsqs9jqjb4rg2pz775hq1amzc350`**.
MD5 **`dd6e27a5bfea81549c94d52c12b9682e`** agrees with the
[archived primary release-files page](https://web.archive.org/web/20160417095515id_/https://redmine.bloodycactus.com/projects/sdlrl/files)
and the [historical AUR recipe](https://raw.githubusercontent.com/aur-archive/cracks_and_crevices/277ff4450e3dcdeb255fc1edd1ec4099a18cabfc/PKGBUILD).
This is the **latest recoverable release established by this investigation**,
not an assertion about the latest release available today. The primary files
page dates it September 18, 2010; the [release announcement](https://web.archive.org/web/20190719113254id_/https://redmine.bloodycactus.com/news/11)
says 0.5 20100915, while the included Changelog retains 0.5 20091213.
These differing historical dates are not silently harmonized. Source facts
were recovered in this 2026-10-09 task; the search receipt's UTC timestamp is
2026-10-10T01:38:40Z, not an upstream publication date.

### Positive grants, retained fonts and recovered FOV notice

`docs/readme.txt:4-5` explicitly releases **the project under GNU GPL version
2**, with the complete text in `docs/COPYING`; it is not an explicit project
GPL-2.0-or-later grant. All original embedded fonts are retained:
`font_8x16.inc` (**4494 bytes**), `font_12x16.inc` (**7584 bytes**) and
`font_14x24.inc` (**9945 bytes**), each an embedded PCX payload. No conflicting
third-party font notice or separate font provenance was found in the project.
The positive project-wide grant supports distribution of its project contents;
it does **not** prove outside origin or that these were author-drawn. Missing
per-file font notices were not treated as an automatic reason to drop or
replace the fonts. The original maps, rumors and other embedded game data
likewise remain compiled in, without replacement artwork or data.

The bundled `random_mt.c:10-38` carries Matsumoto/Nishimura's **1997–2002
BSD-3-clause** redistribution grant; `memwatch.c:3-26` and `memwatch.h`
carry Johan Lindh's **GPL-2.0-or-later** grant. The installed
`share/doc/cracks-and-crevices/licenses/` preserves these complete source
notices, including MT19937's binary-redistribution terms. MEMWATCH debug mode
is not activated in the release build. These grants are not inferred from the
game's GPL COPYING.

The original `fov.c`/`fov.h` refer to Greg McIntyre's separate COPYING, which
was missing from the game tarball. The [primary libfov source archive](https://storage.googleapis.com/google-code-archive-source/v2/code.google.com/libfov/source-archive.zip),
supported by its [original project metadata](https://storage.googleapis.com/google-code-archive/v2/code.google.com/libfov/project.json),
was recovered with SHA-256
**`7dfc0ff6b53ef6002e5ff072807e1f26e72f39a5bef2ef9ed6ee7651881d3586`**.
Its `libfov/trunk/COPYING` is the complete **MIT grant, Copyright (c) 2006
Greg McIntyre**, SHA-256
**`52aff126c6c7d33284e2e8fb9ff29e05eb03aff8ded0cd7f0914086b6fb513ca`**.
The archive ChangeLog dates the BSD-to-MIT change September 3, 2007. Source
comparison finds the same copyright, API and FOV algorithm with local game
edits, not byte-identical files. The notice patch imports that exact grant as
`COPYING.libfov` and corrects the source references; the algorithm is **not
replaced**. The full grant and `PROVENANCE.txt` are installed alongside the
game's GPL text. Primary-source research used Brave and complementary Serper
searches, then read the original Google Code metadata, archive, COPYING and
ChangeLog; a later mirror is not the licensing authority.

### Actual build fixes and native state

The release uses GNU make and GNU C99, with Guix's **sdl12-compat 1.2.68**
supplying the SDL 1.2 API. The installed game is source-built; this does not
assert that every dependency was rebuilt from source without substitutes.
No SDL_image, Ruby/Rant generator, Lua interpreter or missing debug-only Lua
headers are release dependencies. There is **no upstream test suite** in this
release; `test suite not run` in the build log is not an upstream test pass.

The build patch honors compiler/linker flags and links `libm` explicitly.
It retains **`-Wshadow -Wall -Werror -std=gnu99 -pedantic`**, removes upstream's
`-D_FORTIFY_SOURCE=0`, and fixes actual compiler defects rather than disabling
warnings: misleading indentation, terminated item names, a MEMWATCH format
type, checked `dlist_remove` failure, and MEMWATCH neighbor checksums using
the actual neighboring block. Unused bindings are removed while retaining
their calls and side effects; the unused shopping allocation is freed and
the extra format argument removed. Unstable `__DATE__`/`__TIME__` reporting
is replaced consistently in startup, version accessors and character dumps
with explicit **not recorded/omitted for reproducibility** text, not a false
historical build timestamp.

The package bypasses upstream's privileged setgid `/usr/games` install.
`bin/cracks-and-crevices` is a symlink to the compiled
`libexec/cracks-and-crevices/cnc`, not a game-modifying wrapper. Native code
sets `umask 077` and uses an absolute `XDG_STATE_HOME`, falling back to
`$HOME/.local/state` for an unset or nonabsolute value, with the subdirectory
`cracks-and-crevices` checked for caller ownership and made **0700**. `HOME`
itself is not changed. Ordinary basenames `config`, `save.bin`, `scores` and
`chardump.txt` are retained there; shared `/var/games` score fallback is removed.
Configuration still checks the native state `config` then cwd `config.ini`.
Only **ENOENT** means optional configuration is absent and built-in defaults
are appropriate: other open/read/close failures remain reported failures.
No synthetic configuration was injected for the accepted first launch.

### Final ordinary SDL gameplay and save lineage

Final integrated evidence **`/tmp/cracks-native-5`** and independent standalone
evidence **`/tmp/cracks-native-6`** each retain four actual installed game
processes, three native saves with read-only JSON decodes, raw PNG captures,
input receipts, stdout/stderr, namespace/mount receipts and final character
dump. In each fresh easy game, ordinary `e` starts character creation and the
shop; `l` exits the shop. The first process moves **Left**, rests with `.`,
saves with **Shift+S**, then acknowledges the saved prompt with Space. A fresh
second process consumes that unchanged native save, resumes without the menu,
moves Left, rests and resaves. The third consumes the second save, moves **Up**,
rests and resaves; the fourth consumes the third, moves **Down**, rests, then
uses **Shift+Q** and Space for natural quit and native character dump.
All four game processes in each final run exited **0 naturally**, before
teardown. Neither forced process termination nor zero exit with a native
error is accepted as a successful quit.

Decoded save positions (row, column) are **(21,16) → (21,15) → (20,15)**,
with move counts **3 → 6 → 9** and clocks **9:20AM → 9:40AM → 10:00AM**;
both final dumps advance to **10:20AM**. Saves retain the player handle, map,
date, difficulty, gold, level, experience, base stats, skills, inventory payload
hash and both level terrain hashes within their own lineage. Existing native
save journal entries are preserved and grow from one to two to three, with
the same **3/6/9** history in the final dump. Integrated gold stays **34**;
standalone gold stays **42**, with independently generated stats and dungeon
terrain: the runs were not seeded or forced into identical character fixtures.
The reader targets the recovered **LP64 native-endian 0.5 save ABI** (220-byte
Item, 3652-byte Actor). This is selected-field/terrain/inventory/journal
continuity plus native save consumption and further play, not a claim of
cross-architecture save portability or complete hidden-state equivalence.

The actual integrated `third-restored.png` has legible **Life 10, Armour 0,
Mana 40**, HUD text `21. 15  9:40AM`, the player `@`, floors/walls and no error
overlay. This raw restored frame precedes the next input; it is not substituted
for the decoded third-save clock. Map glyphs are small, not claimed pixel-perfect
against an invented reference. Native stdout is empty; stderr carries the
normal version/SDL/defaults/save/load messages, without native LogError,
assertion or save failure in either accepted run. The proof is bounded **town
movement/rest/save/restore/quit**, not dungeon combat, quest completion or victory.

Both runs use an empty PATH and private HOME/XDG/work directories, user,
mount, PID and network namespaces with unchanged nonroot **UID 1000/GID 998**,
only loopback and no external route, private `/tmp` and `/run`, and a recursively
read-only `/gnu/store`. Xvfb provides the real X11 display; SDL audio is dummy.
Explicit private unavailable D-Bus addresses prevent host-session autoactivation,
not a skipped filesystem-isolation assertion. Final HOME remains empty; the
only retained game-state file after consumed saves and quit is `chardump.txt`.
Both runs preserve the output NAR hash
**`1q65qg0fm3p7if66j3igwml3p4799s5hg45x6jqy50fhkans8q9a`** before/after.
Cleanup receipts show the game processes already stopped naturally; only
task-owned Xvfb required teardown. Failed native evidence is retained separately.

### Exercised final gates and honest failure history

Main's final build used `/home/tay/.config/guix/current/bin/guix build -L guix
--no-grafts --no-offload --cores=1 --max-jobs=1 --keep-failed -e '(@ (tay
packages cracks-and-crevices) cracks-and-crevices)'`: **PASS, 7.93 s**, artifact
**16612**, derivation
`/gnu/store/d1k2gv2clqf9l4ja47cwqqidv9fw62za-cracks-and-crevices-0.5.drv`, output
**`/gnu/store/lx12n7l2m8w2xjfbf696g2qmdnzf3g9m-cracks-and-crevices-0.5`**.
The same command with **`--check`** added before `-e` passed **6.24 s**, artifact
**16614**, for this final output. Earlier builds of a different output are not
substituted for these final receipts.

`make check-cracks-and-crevices GUIX=/home/tay/.config/guix/current/bin/guix
CRACKS_OUTPUT=/gnu/store/lx12n7l2m8w2xjfbf696g2qmdnzf3g9m-cracks-and-crevices-0.5
CRACKS_EVIDENCE=/tmp/cracks-native-5` passed **20.47 s** using Guix make 4.4.1.
The independent invocation `env GUIX=/home/tay/.config/guix/current/bin/guix sh
tests/cracks-and-crevices-smoke.sh
/gnu/store/lx12n7l2m8w2xjfbf696g2qmdnzf3g9m-cracks-and-crevices-0.5
/tmp/cracks-native-6` passed **16.83 s**. The smoke entrypoint consumes an
already-realized canonical direct store output and a fresh canonical absolute
evidence path outside the store, realizing only generic proof tools. Main's
missing-variable target invocation correctly rejected with **exit 2, 1.74 s**;
it did not build the game implicitly or invent an evidence directory.

Earlier attempts are failures, not acceptance: `cracks-native-1` failed the
evidence bind-mount setup (**13.43 s**); `cracks-native-2` rejected the first-run
`options.c(133) : No ini file found` LogError even though the game saved and
exited zero (**16.37 s**, artifact **16608**). The optional-ENOENT semantics
above fix that real mismatch without accepting runtime errors.
`cracks-native-3` failed the decoder's incorrect Actor-size assumption
(**16.56 s**), corrected from the actual recovered struct ABI, not by editing
game saves. `cracks-native-4` completed play but failed the empty-HOME assertion
because D-Bus autoactivation created `.dbus` (**21.54 s**); private unavailable
bus addresses fixed isolation while retaining the assertion. Initial compiler
and patch-application failures likewise precede the final corrected build.
Task-owned source/scratch workspaces were removed after their evidence was
retained; failed/native evidence and store outputs were preserved.

The full unfiltered command `/home/tay/.config/guix/current/bin/guix lint -L
guix cracks-and-crevices` completed **23.50 s**, but was **not clean**: own
generic HTML release discovery failed to find upstream releases (the archived
directory request returned 404), and Software Heritage/Disarchive source
archiving reported missing coverage. The unrelated Guix `flex` warning is
separate; it does not erase the own-package warnings. No updater is disabled,
archive evidence fabricated or clean-lint waiver claimed. **Forgejo #313 remains
OPEN**, with its GitHub counterpart not closed. Build, reproducibility,
integrated/standalone native behavior and the target guard have final receipts;
the remaining gates are external **release discovery/source archive coverage**,
not pending local gameplay verification. Publication/deployment is not asserted.

This documentation worker ran no builds, tests, linters or execution checks;
the receipts above are Main's observed gates. No documented host/service or
network-catalog fact changed, so **no OKF page or log update applies** to this
repository-only package receipt.

### Publication and tracker synchronization (2026-10-09)

The pre-publication statement above is superseded **for channel publication
only** by signed commit
**[`90ad2a2dd57118a26b53bd0fbb2e3f3660d9cab5`](https://forge.nogroup.group/tay/guix-channel/commit/90ad2a2dd57118a26b53bd0fbb2e3f3660d9cab5)**,
parent **`8c8b8ab148f827599119ea51f106a996a95e1f8e`**. The publisher performed
exact-OID channel authentication and a normal push to authoritative `origin`
master. Its SSH/master/API identity matched; the tracker independently read
the exact matching commit/master API values and **`signature_verified: true`**.
This establishes that publication, not a GitHub code push, profile installation
or deployment, occurred. It does not waive the unresolved clean-own-lint gate.

Cracks and Crevices **#313 remains OPEN** on
[Forgejo, comment 3297](https://forge.nogroup.group/tay/guix-channel/issues/313#issuecomment-3297)
and [GitHub, comment 6093107334](https://github.com/htayj/guix-channel/issues/313#issuecomment-6093107334).
The synchronized evidence records recovered original source, positive grants,
retained fonts/FOV, final Main-owned build/repro/native receipts and publication,
while retaining the own release-discovery/source-archive lint findings as
**UNMET**, without suppression or waiver. Original labels, including
`state:blocked`, `state:research` and the workflow label, remain unchanged.

The same tracker wave corrected the distinct **#316 CryptoRl** target on
[Forgejo, comment 3298](https://forge.nogroup.group/tay/guix-channel/issues/316#issuecomment-3298)
and [GitHub, comment 6093107537](https://github.com/htayj/guix-channel/issues/316#issuecomment-6093107537),
both still **OPEN** with all original labels preserved. This is Gornova's
original **CryptoRl 1.0**, not CoreRL/corerl #311 and not CryptoRl2. Its authentic
[author release post](https://randomtower.blogspot.com/2015/08/cryptorl-release-10_28.html)
was read through the [original Blogger post feed](https://randomtower.blogspot.com/feeds/posts/default/2017182703995718619?alt=json):
publication **2015-08-28T23:10:00.005+02:00**, Java 1.8 and the original
`cryptoRl-1.0.zip` download link. That identifies the release; it is not
recovered buildable source or an actual immutable source/asset grant.
The tracker observed **HTTP 404** for each exact
[GitHub repository API lookup](https://api.github.com/repos/Gornova/CryptoRl),
[original Orangedox ZIP](https://dl.orangedox.com/TRfo3gOrLyslL8ZfA2/cryptoRl-1.0.zip)
and [Software Heritage origin lookup](https://archive.softwareheritage.org/api/1/origin/https://github.com/Gornova/CryptoRl/get/).
These bounded route results do not establish exhaustive absence, “never
archived,” no possible mirror or author republication as the only recovery
route. Authentic original-1.0 immutable source and its actual notices remain
missing; neither the unrelated CoreRL package nor a sequel satisfies that gate.

All four evidence-comment POSTs returned **201**; individual authenticated
GETs returned **200** with exact paired identical bodies, both issues OPEN
and every original label retained. The complete wave-11 inventory covered
**755 Forgejo issues** (387 open/368 closed) and **725 GitHub issues**
(385 open/340 closed): **725 shared pairs**, **722 unique shared titles**,
**zero title, open/closed or `state:*` workflow drift**. The **30 Forgejo-only
issues 728–757** remain accounted for; there are no GitHub-only issues.
This is a tracker comparison, not an all-issues acceptance claim. Durable
task evidence is `local://browser-tracker-wave11-receipt.json`; no issue-state
or label edits, repository checks, applications or Goocastle reruns accompanied
the synchronization. This repository/tracker-only publication establishes no
changed deployed-system fact, so no OKF page or log update applies.

## City of the Condemned — original source and ordinary native gameplay (2026-10-09)

The new [`city-of-the-condemned`](guix/tay/packages/city-of-the-condemned.scm)
**1.0-0.e9a8989** package builds Tapio Vierros's original C++/ncurses game
from [tapio/cotc](https://github.com/tapio/cotc), exact commit
**`e9a8989d34c9d3e0c68e7e42b526e1bee923ac7c`**, recursive Guix source NAR
hash **`0wrjwsiy5vg27hz0mzdja2v3nyclpicajnl5xidkhxn5sjx0ldvk`**.
This is City of the Condemned, not the separately packaged City of the Damned.
The origin snippet removes upstream `bin/` (`CotC-1.0.exe`, `CotC-1.0.x86`
and `pdcurses.dll`); the installed `libexec/cotc` is compiled from the complete
game sources, not copied from those prebuilts. The CMake patch supplies a
deterministic package version instead of build-time Git discovery and adapts
the existing Boost/header/C++ build. It does not replace the game engine,
town generation, field of view, ncurses interface or ordinary input handling.
Upstream defines no automated test suite; no upstream test count is claimed.

### Primary source grants and retained notices

The [pinned root LICENSE](https://github.com/tapio/cotc/blob/e9a8989d34c9d3e0c68e7e42b526e1bee923ac7c/LICENSE)
is the full MIT permission/disclaimer with **Copyright (c) 2010-2013 Tapio
Vierros**, retained verbatim with the upstream README in
`share/doc/city-of-the-condemned`. The author's own Knight of Faith town
generator is already included in this source grant: `generator.cc` identifies
its CoolBasic port. A missing external Knight of Faith download URL is not
evidence that this included author-owned code lacks permission.

The original [Google Code project metadata](https://storage.googleapis.com/google-code-archive/v2/code.google.com/reflexivelos/project.json)
declares **`license: "mit"`** and explicitly invites reuse: “This is a
roguelike engine I've been developing in my spare time. I'm putting it online
so I don't lose it when my computer explodes, but please, reuse the code.”
The fetched JSON is a pinned build input, installed as
`share/doc/city-of-the-condemned/reflexivelos-project.json`: SHA-256
**`6c5cc39ab5d737c28ff57857cb989e10aa966038711f31706eaed185b6b162e8`**,
Guix base32 **`1s32n6v8bldfdrq327vi71h9dahhksccnmvqyn7w4dypnndc6p3c`**.
This is primary project licensing evidence, not an inference from a mirror.

The fetched [original source archive](https://storage.googleapis.com/google-code-archive-source/v2/code.google.com/reflexivelos/source-archive.zip)
has SHA-256
**`8f7ca7e8f8f149f313753c483ba0ec4d1e920200064c95c1f6d43ee91a03919e`**.
Comparison of its `trunk/los2.cpp` `showdir` with the pinned game's
`world.cc` `fov_dir` finds the same `q/p`, `eps/ad2/s` digital-line loops,
direction transformations and obstruction interval updates, adapted to game
tile access and visibility. The original algorithm and upstream reflexivelos
MIT attribution are retained, not dropped or replaced. The archive's SVN
metadata gives the alias **notzeb**; the source investigation found no separate
license notice, copyright year or legal holder name in its 39 non-SVN files.
The original MIT declaration and reuse invitation correct the prior missing-
permission blocker, but do not identify a missing legal name/year. Neither is
fabricated. Installed `THIRD-PARTY-NOTICES` preserves the attribution, primary
URLs and hashes, and explicitly labels the canonical MIT permission/disclaimer
as a **terms reference**, not a newly authored grant or invented copyright
notice. The later RealityWarper mirror is supplemental, not the authority.
Separate Guix Boost, ncurses, Bash and Coreutils dependencies retain their own
notices; the package records MIT/Expat and Boost Software License 1.0.

Primary temporary reads were captured from
`/tmp/cotc-package-upstream-20261009`, `/tmp/cotc-package-hash-20261009`,
`/tmp/cotc-reflexivelos-source-20261009.zip` and
`/tmp/cotc-reflexivelos-project-20261009.json`. These are task-owned fetch/hash
workspaces, not installed runtime state or native evidence. Their primary
facts are retained above and in the installed notices. After the native worker
released its source reads and those facts were saved, Main removed exactly
these four temporary paths (0.01 s). Native and failed-build receipts, user
files and store outputs were preserved.

### Ordinary native behavior and persistence boundary

The launcher sets `umask 077`, preserves `HOME`, creates and enters
`${XDG_STATE_HOME:-$HOME/.local/state}/city-of-the-condemned`, then execs
`libexec/cotc` with store ncurses terminfo available. Upstream has **no save/load
facility**. Its cwd-relative `log.log` is diagnostic, not a session save;
logging was dormant and no log file was produced in either accepted run.
The only observed private-state change was creation of the game state
directory (0700, caller UID/GID). This is not save, resume or persistence proof.

The integrated receipt `/tmp/cotc-native-1` and independent standalone receipt
`/tmp/cotc-native-2` each retain **two ordinary native PTY processes**, Angel
and Imp (namespace PIDs 2 and 4 in the integrated receipt), through the actual
installed launcher. Each role has its real HUD, role-specific abilities and
generated terrain; three successful movements are established by matching
terrain/camera translations rather than merely finding a player glyph.
Angel moved west three times (`g`); Imp moved west/east/west (`g`, `j`, `g`).
Ordinary `5` waits advance actors and visible world state without forcing RNG,
injecting fixtures or adding game hooks. Integrated Blessed counts changed
**0 → 3** (Angel) and **0 → 5** (Imp), with Imp-world Demons **60 → 59**;
standalone Blessed counts changed **0 → 2** for both roles. Angel/Imp health
bars were retained at **16/9**, not falsely reported as HP damage.
Both result files report adjacent combat **unavailable and unobserved**,
with no attempted combat keys; world changes do not prove player combat.
Each process used natural `q` to return to the title and `q` there to exit
**0**. Namespace teardown is not accepted as a successful quit.

The driver and games preserve caller UID/GID in isolated user, mount, network
and PID namespaces, use an empty PATH during gameplay, and have no external
network route. `/gnu/store` is recursively read-only. Before/after output NAR
hashes match in both runs:
**`1j40yq9gbch1qs4y95v80bmzadagv4l8fmyv5l94zbhvhy8kbig9`**.
Raw PTY streams, inputs, parsed screens, process/namespace proofs, private-state
inventories and cleanup receipts remain in the evidence directories; their
temporary `private/` runtime trees were removed. This proves the exercised
movement/wait/quit paths, not every ability, combat outcome or whole game.

### Main-owned verification and remaining literal lint gate

The final source build and `--check` rebuild realized the same output:
**`/gnu/store/yacj68wbrjarj40apnsfilzr3rjg4xqc-city-of-the-condemned-1.0-0.e9a8989`**,
derivation **`6vv6rxdbdr7dbw2h5wdn5zlxvml2sy7w-city-of-the-condemned-1.0-0.e9a8989.drv`**.

| Gate | Main receipt |
| --- | --- |
| Final source build | PASS, 10.49 s; attempt 150, artifact 16447 |
| `--check` reproducibility rebuild | PASS, 8.79 s; attempt 152, artifact 16449; identical output |
| Full lint | Literal clean gate UNMET, 47.89 s; attempt 151, Main's retained result: only own warning is “can be upgraded to 7drl”; deprecated Flex dependency warning is separate |
| Integrated `make check-city-of-the-condemned` native consumer | PASS, 15.51 s; attempt 154, `/tmp/cotc-native-1` |
| Independent standalone native consumer | PASS, 9.95 s; attempt 155, `/tmp/cotc-native-2`; same final output |
| Missing-variable Makefile guard | Expected rejection, make exit 2, 1.74 s; requires canonical prebuilt store output and fresh absolute evidence directory |

Earlier malformed-patch, patch-name/synopsis and archive `BadHeader`/EOF
failures were repaired before these final receipts. The final full lint run
reported no archive warning. The remaining `7drl` updater suggestion points
to a historically older tag; the actual pinned commit/version remains intact,
without a fake version, updater suppression or waiver. **#307 remains OPEN**:
source-grant, build, reproducibility and native proofs do not satisfy the
literal clean-own-lint acceptance requirement.

To exercise the consumer again, use the existing canonical output and a
**new, nonexistent absolute evidence directory outside the store**:

```sh
COTC_OUTPUT=/gnu/store/yacj68wbrjarj40apnsfilzr3rjg4xqc-city-of-the-condemned-1.0-0.e9a8989 \
COTC_EVIDENCE=/tmp/cotc-new-evidence make check-city-of-the-condemned
# Or call the same native consumer directly:
sh tests/city-of-the-condemned-smoke.sh \
  /gnu/store/yacj68wbrjarj40apnsfilzr3rjg4xqc-city-of-the-condemned-1.0-0.e9a8989 \
  /tmp/cotc-another-new-evidence
```

The consumer never builds the target game; it may realize its own tools before
offline gameplay. `GUIX`, if supplied, must be an absolute executable path.
This repository-only delivery does not establish publication, profile
installation, deployment or issue closure. No described host/service changed
and no material OKF correction was established, so no OKF page/log update
applies. Documentation workers ran no commands, checks, builds, tests, linters
or formatters; the exercised gate results above belong to Main.

### Publication and mirrored tracker readback (2026-10-09)

The local-delivery boundary above describes the pre-publication receipt.
Main subsequently reports signed/authenticated implementation commit
**[`9c24801efae418a7b99c4209b23c5671b0981426`](https://forge.nogroup.group/tay/guix-channel/commit/9c24801efae418a7b99c4209b23c5671b0981426)**,
parent **`c6b17d4e08bdbfabedee2def998a23e255102eee`**, published by a normal
push to authoritative `origin/master`. The publisher recorded exact-OID
channel authentication, matching SSH/master/API values and a verified
signature; the tracker worker independently read the same exact master/commit
OID and verified signature from the Forgejo API. This is publication evidence,
not profile installation or deployment, and no GitHub code push is claimed.

Mirrored #307 evidence comments
[Forgejo **3292**](https://forge.nogroup.group/tay/guix-channel/issues/307#issuecomment-3292)
and [GitHub **6092058902**](https://github.com/htayj/guix-channel/issues/307#issuecomment-6092058902)
retain the primary-grant correction and the exercised build/reproducibility/
ordinary-native receipts above. Both issues remain **OPEN**, with existing
`state:blocked` and `state:research` labels unchanged: the literal older
`7drl` updater lint warning is still unmet, not suppressed or waived.

The same bounded tracker wave added #306 Cinders comments
[Forgejo **3293**](https://forge.nogroup.group/tay/guix-channel/issues/306#issuecomment-3293)
and [GitHub **6092059174**](https://github.com/htayj/guix-channel/issues/306#issuecomment-6092059174).
Its exact Bitbucket repository API and Software Heritage origin lookup
returned **404**; the independent current Wayback availability request returned
**429**, not a freshly verified empty result. An earlier worker-reported empty
Wayback result is explicitly historical/bounded. These observations establish
no recovered source through the checked routes, not exhaustive absence,
nonexistence of mirrors or proof the project was never public. No opaque demo,
replacement source or new runtime execution is accepted; #306 remains OPEN.

The worker's retained `local://browser-tracker-wave9-receipt.json` records four
comment POST responses **201** and individual authenticated readbacks **200**,
with identical mirrored bodies and no state/label changes. Its complete
tracker audit counted **755 Forgejo issues (387 open / 368 closed)** and
**725 GitHub issues (385 open / 340 closed)**: **725 shared pairs**, **722 unique
titles**, zero title/open-closed/`state:*` drift, **30 Forgejo-only issues
728–757** and no GitHub-only issues. These are tracker inventory/readback
counts, not package acceptance totals. This follow-up is append-only receipt
documentation: no recipe, source pin, canonical 629 ledger, application state,
build/test/lint or deployment changed, and no OKF update applies.

## CalcRogue — native i686 gameplay and save continuity (2026-10-09)

The new [`calcrogue`](guix/tay/packages/calcrogue.scm) **6a-sp1** package
builds the complete recovered Linux/curses game and generated game data from
the pinned [ticalc.org archive](https://www.ticalc.org/pub/89/asm/games/rpg/crogue.zip).
`CHANGELOG` identifies Beta 6a SP1; the title still says Beta 6a. This is the
recoverable source release, **not** a claim to have recovered historical 6c or
established the latest upstream release. The URL is mutable; the recipe pins
the actual archive bytes with SHA-256
**`6338d8d5460d7b7d270601aed9f76289a759b6d8602e5f48bd6e133fa3962c90`**,
Guix base32 **`141cjsiky4vfpm45ybk0v2v5k9w9cbvxkbh10qkpsyqd8vaxhf33`**.

### Source, notices and architecture boundary

The game/data grant in the original `crogue.c` header is **GPL-2.0-or-later**,
not merely GPL-2.0 inferred from `COPYING`. The `sgt` helper retains its original
GPL terms. The `mibic` source banner grants the LGPL **without specifying a
version**: this package selects **LGPL-2.1** under its version-selection terms
(sections 0 and 13), rather than claiming the author explicitly chose 2.1.
The original banner remains installed as `mibic/main.c`; unmodified canonical
GNU LGPL 2.1 terms are supplied from the
[GCC mirror's immutable `COPYING.LIB` revision](https://raw.githubusercontent.com/gcc-mirror/gcc/d0ca130aa5d50cdaeea8e5c343d65250cdf51955/COPYING.LIB)
**`d0ca130aa5d50cdaeea8e5c343d65250cdf51955`**, SHA-256
**`a9bdde5616ecdd1e980b44f360600ee8783b1f99b8cc83a2beb163a0a390e861`**.
Original `COPYING`, `README`, `CHANGELOG`, distribution `readme.txt`,
`crogue.c`, `sgt/COPYING` and the selected LGPL text are retained under
`share/doc/calcrogue`, with a dated `SOURCE` provenance/modification notice.
Both native receipts hash-check these notices; `license-closure.json` records
the exact retained hashes.

All upstream `bin*` distribution directories are excluded, including Linux and
Windows executables/data, calculator and Palm binaries, and Kevin Kofler's
nonfree HW3Patch ZIP. `src/sys/palm` is also excluded, including its third-party
fonts: no blanket GPL claim is made for these excluded materials. The legacy
committed scanner/parser skeletons are removed; Flex/Bison regenerate them from
`compile.l` and `compile.y`. `sgt`, `mibic`, `fixedmap`, automatic headers,
tiles and `crogdat.dat` are built/generated from source before the original
game objects and curses frontend. No distributed executable or precompiled
game-data file is used as the installed game. Guix dependencies may be
substituted; these receipts do not claim a source rebuild of the entire closure.

The VM, C structure overlays and variadic bridges assume the native **32-bit
i386 ABI**. The recipe supports **`i686-linux` only**, preserving that ABI
instead of introducing a partial LP64 port. Select `-s i686-linux` explicitly
for build/install on x86_64. The observed native executable is ELF32,
little-endian i386, with four-byte pointers in the decoded saves. Its three
ordinary processes ran directly on the acceptance host, establishing that
host's Linux IA32 execution support, not portability to every x86_64 kernel.

`make build-calcrogue` explicitly uses `--system=i686-linux`. The default native
`make build` and `make check` build dry-run filter out `I686_ONLY_PACKAGES`;
CalcRogue remains in `PROJECT_PACKAGES`, `INSTALLABLE_PACKAGES` and lint lists.
This is a build-system selection boundary, not a reduction in the installable
or source-snapshot inventories.

### Native state and ordinary save/restore proof

The launcher sets `umask 077`, enters
`$XDG_STATE_HOME/calcrogue` (fallback `$HOME/.local/state/calcrogue`) and execs
`libexec/calcrogue/calcrogue`. Native saves, saved levels, options and scores
use that private cwd; the game reads immutable
`share/calcrogue/crogdat.dat` via its installed store path. The source patch
uses direct fork/exec of store gzip, checks for an absent compressed save and
cleans up compressed private state without `/bin/sh` or PATH lookup. The
modern-C patch replaces the obsolete RLE cast-lvalue pointer increment with
an explicit byte read and cursor assignment; it does not change the format.

The integrated run retained `/tmp/calcrogue-native-1`; the independent
standalone run retained `/tmp/calcrogue-native-2`. Each exercises **three
independent ordinary native processes** through the real launcher and PTY:

1. Start a new **Fighter**, take a visible movement and ordinary `5` wait,
   then use native `S` save-and-quit, producing `rgsave.gz`.
2. Restart normally, restore automatically, then save-and-quit without any
   gameplay action. Compare the complete decoded non-pointer semantic state
   and block hashes against the first save.
3. Restart again, continue with another visible movement and wait, then
   save-and-quit. Check turn progression, level/descriptor/player continuity,
   carried equipment identity and item shuffle/identification state, allowing
   only ordinary equipped torch-fuel consumption.

Both result files report `CALCROGUE_NATIVE_OK`, distinct PIDs **5, 8, 13**,
turn counters **2 → 2 → 4**, exact semantic restore/checkpoint equality and
natural exit statuses **0, 0, 0**. The integrated movement was
**(57,18) → (56,18) → (55,18)**; the standalone movement was
**(43,16) → (42,16) → (41,16)**. The independent save decoder reads the native
gzip/checksum/Huffman/RLE/byte-transpose format; it discards only relocated
raw pointers, C padding and UI `messagevis`/`interrupt`, not gameplay state.
Raw saves, decoded blocks, semantic JSON, process/namespace proofs and PTY
screens/inputs are retained in those evidence directories. There is no RNG
control, injected save or engine hook.

The driver and games run in isolated user/mount/network/PID namespaces while
preserving the caller's UID/GID, with an empty PATH and no external network.
`/gnu/store` is read-only in the game namespace. Before/after output NAR hashes
are identical, including standalone hash
**`0xiwdg0dvpjwz7jcqcjkr01rpa5j0c9dxa90sc21pjslcj2a2laa`**.
This proves the exercised native movement/wait/save/restore path, not every
class, level transition, option or scoring outcome. Upstream has no check
target; the package does not invent an upstream test suite.

### Main-owned verification and remaining gate

Main's source-build invocation was:

```sh
/home/tay/.config/guix/current/bin/guix build -L guix -s i686-linux \
  --no-grafts --no-offload --cores=1 --max-jobs=1 --keep-failed \
  -e '(@ (tay packages calcrogue) calcrogue)'
```

The same command with `--check` added rebuilt the target to the identical output
**`/gnu/store/yc6d7w5s34k7jvm950gxx37shqai19ch-calcrogue-6a-sp1`**,
derivation **`yh49qwfxpm2f681b8g5n033gdm0wdn0v-calcrogue-6a-sp1.drv`**.

| Gate | Main receipt |
| --- | --- |
| Final i686 source build | PASS, 9.95 s; attempt 139, artifact 16328 |
| `--check` rebuild, same output | PASS, 7.48 s; attempt 142, artifact 16331 |
| `make build-calcrogue` architecture target | PASS, 15.86 s; attempt 144, artifact 16335; `guix build -L guix --system=i686-linux calcrogue` realized the same existing output (not a fresh target rebuild); dependency documentation substitutes observed |
| Integrated `make check-calcrogue` native consumer | PASS, 11.49 s; attempt 141, `/tmp/calcrogue-native-1` |
| Standalone native consumer | PASS, 6.89 s; attempt 143, `/tmp/calcrogue-native-2` |
| Missing-variable Makefile guard | Expected rejection, `make` exit 2, 1.63 s; requires canonical prebuilt output and fresh nonexistent absolute evidence directory outside the store |
| Full own lint | OPEN, 5.60 s; attempt 140, Main's retained inline result: `generic-html` failed to find upstream releases; source absent from Software Heritage and missing Disarchive data |

To rerun the native consumer, use the canonical prebuilt output and a **new,
nonexistent absolute evidence directory outside the store**:

```sh
CALCROGUE_OUTPUT=/gnu/store/yc6d7w5s34k7jvm950gxx37shqai19ch-calcrogue-6a-sp1 \
CALCROGUE_EVIDENCE=/tmp/calcrogue-new-evidence make check-calcrogue
# Or call the same native consumer directly:
sh tests/calcrogue-smoke.sh \
  /gnu/store/yc6d7w5s34k7jvm950gxx37shqai19ch-calcrogue-6a-sp1 \
  /tmp/calcrogue-another-new-evidence
```

The consumer never builds the target game; it may realize its own tools before
offline gameplay. `GUIX`, if supplied, must be an absolute executable path.
Full lint additionally reported the dependency's deprecated Flex package;
that is distinct from CalcRogue's own release-discovery/archive failures.
**#295 remains OPEN**: those literal external own-lint gates are not waived by
the source build, reproducibility or native receipts. This local repository
delivery does not establish commit/publication, profile installation or
deployment. No described host/service changed and no material OKF correction
was established, so no OKF page/log update applies.

### Publication and tracker readback (2026-10-09)

The preceding local-delivery boundary is superseded **only for channel
publication** by signed commit
[`44cb0ac3e3d25d459765b2ee2d55d3de9834ce3d`](https://forge.nogroup.group/tay/guix-channel/commit/44cb0ac3e3d25d459765b2ee2d55d3de9834ce3d),
parent **`bf0cad62229c76790d5b0b902cbf1e685975b72c`**, published by normal
authoritative Forgejo `origin/master` push. Publisher/tracker receipts establish
exact-OID channel authentication, matching SSH/master/API readback and Forgejo
signature verification **true**. No GitHub code push, profile installation or
deployment is established; publication does not waive the remaining gates.

The identical evidence comments were posted and individually authenticated
read back for **#295** on
[Forgejo (3285)](https://forge.nogroup.group/tay/guix-channel/issues/295#issuecomment-3285)
and [GitHub (6091357496)](https://github.com/htayj/guix-channel/issues/295#issuecomment-6091357496),
and for **#304** on
[Forgejo (3286)](https://forge.nogroup.group/tay/guix-channel/issues/304#issuecomment-3286)
and [GitHub (6091359420)](https://github.com/htayj/guix-channel/issues/304#issuecomment-6091359420).
All four POSTs returned **201** and readbacks **200**, with exact intended
bodies. Both issues remain **OPEN**, retaining `state:blocked`, `state:research`
and all other original labels; #295's literal full acceptance gate is unmet.

The bounded #304 primary-source correction retains genuine upstream **MIT
metadata evidence**, rather than treating missing license text as automatically
“no grant.” The archive records `hasSource=false` and no source entries; the
actual 1.1.2 ZIP contains only `readme.txt` and the compiled C64 D64 image.
Whole-image component rights remain unverified and authentic reproducible
source/build inputs absent. No opaque disk-image/emulator package, automatic
whole-image rights clearance or substitute acceptance was delivered.

The full wave-6 tracker audit counted **755 Forgejo issues (387 open, 368
closed)** and **725 GitHub issues (385 open, 340 closed)**, with **725 shared
pairs / 722 unique shared titles**, **30 Forgejo-only issues (728–757)** and
zero GitHub-only issues. Shared-pair title, open/closed and workflow drift was
**zero**. Retained receipt: `local://browser-tracker-wave6-receipt.json`.
These are tracker reconciliation counts, not package acceptance totals. The
tracker work performed no repository edits or build/test/lint/app/Goocastle
reruns, changed no issue state/labels and preserved the **629** source ledger.
No described deployed system changed; no OKF page/log update applies.

## Persephil — legacy PhiloLogic HTML to XLSX (2026-10-09)

The new [`persephil`](guix/tay/packages/persephil.scm)
**1.0.0-0.1e10afb** package reuses the complete
`cookinrelaxin-persephil-source` origin at
**`1e10afbbcb8c6f56d2cc22db0c915a9d64ecd8d6`**, source hash
**`10jpc44cnlfph1h9zzy01xlvird0ay0a5x84la5fjk7s2wd7xf6h`**.
It installs the original Node.js converter and all locked dependency sources,
not a rewritten JSON API client. The wrapper passes URL arguments unchanged
and does not change directories: upstream parses legacy PhiloLogic Latin HTML
and writes its naturally dated XLSX workbook in the caller's directory.
The only program edit corrects `require('excelJS')` to `require('exceljs')`
for case-sensitive hosts. The authored upstream license is **GPL-3.0**;
`package.json`'s ISC value is an untouched npm-init template, not the project's
license grant. This repository-only delivery does not establish publication,
profile installation or deployment, and no OKF page/log update applies.

### Retained source-download and license audit

The pinned lockfileVersion 1 `package-lock.json` has SHA-256
**`cf7ce56f055fa00f038e4f4aca16e138ea42c387dc0fbe9a965ef647d7c4f677`**.
The source worker fetched **204 distinct archives, 10,913,095 bytes**, covering
**214 exact installation paths: 196 top-level and 18 nested**. No locked
dependency, including the optional source-map entry, was omitted or substituted.
Every installation-path lock SRI and every distinct archive's registry SRI
and SHA-1 were verified; SHA-256 was computed from downloaded bytes with
`guix hash` and independently converted to Nix base32. Archive manifest names,
versions and required dependency declarations matched the lock. Inspection
found no native-addon/platform-binary artifacts or install lifecycle hooks.
These are fetching and source-audit receipts, not runtime/build/lint passes.
The compact receipt retains the source worker's `download-receipts.json`
SHA-256 **`13207a7bd9b24533cab60b177dd28a715414bf6d8eca4620d8a5b17a8b162897`**;
the large JSON/download scratch is not part of the package or documentation.

[`persephil-npm-sources.scm`](guix/tay/packages/persephil-npm-sources.scm)
retains actual grant coverage rather than relying only on manifest metadata:
196 archives had named notice files; assert-plus and isarray carry complete
MIT notices in READMEs; six other archives required **eight supplemental
notice origins**. Full archives and embedded/source-header notices remain
installed. Notable license distinctions are:

- **buffers 0.1.1:** every published file byte-matches parent commit
  `51ac8d0324008b0d0ed5759b1466402a77ff8dc8`. The
  [primary upstream README grant](https://raw.githubusercontent.com/bitpay/node-buffers/1b745ee35d33eb166e15ef1866073a07c6d7de87/README.markdown)
  at `1b745ee35d33eb166e15ef1866073a07c6d7de87` changes license statements,
  not code, and explicitly designates MIT/X11 without supplying the full text.
  It is installed as `LICENSE-GRANT-MIT-X11`, hash
  `140c1hnp3k7j8lap5mif97bpnphfmlrabibmzv77iraf8hd9fhrx`.
  The separate [Debian 0.1.1-2 full notice](https://sources.debian.org/data/main/n/node-buffers/0.1.1-2/debian/copyright)
  is installed as `LICENSE-MIT`, hash
  `0mm0a9pxrd27yz5v79vnv8wg7csmzzpsfgxzwa6sjxj4ph1klhlp`.
  Its **2015** copyright metadata is Debian-authored, not an invented upstream
  2012 notice or a newly substituted dependency version.
- **binary 0.3.0:** the original README explicitly declares MIT and its
  manifest identifies James Halliday; both remain unchanged. No full
  upstream-authored copyright notice was recoverable. The immutable
  [SPDX MIT terms](https://raw.githubusercontent.com/spdx/license-list-data/d46e94e2c78ceede1cfc63cfa0396472d2798d4c/text/MIT.txt)
  are retained verbatim as `LICENSE-MIT-TERMS`, hash
  `1dcjqlpj028h85q5nn92l91rjfsiahab291lnsx1crwfy7wqamxh`, solely as a
  terms reference, **not an authored grant**. Template markers are not filled
  with a fabricated holder/year; this notice limitation remains explicit.
- **json-schema 0.2.3:** BSD-3-Clause is selected from the README's AFL/BSD
  dual grant. The [full notice](https://raw.githubusercontent.com/kriszyp/json-schema/4f3db68fb98d9444850fec0ef5ed981c8beacfb6/LICENSE)
  is recovered at immutable `4f3db68fb98d9444850fec0ef5ed981c8beacfb6`, hash
  `13lnjn2irjw16p9d29nlq492n37qxg54hpvl57g9fqqfyx3cjdwh`.
  Source equivalence holds after CRLF/LF normalization, not raw-byte identity;
  stale MIT headers are not treated as overriding the documented dual grant.
- **chainsaw:** its full X11-variant notice is retained, rather than relabeled
  as exactly Expat. **saxes** retains its pinned full LICENSE and AUTHORS;
  **set-immediate-shim** retains its pinned upstream full MIT notice.
- **bcrypt-pbkdf** combines BSD-3-Clause and ISC; **fs.realpath** combines ISC
  and bundled Node.js MIT. **pako**, plus retained ExcelJS/JSZip browser
  distributions, combines MIT and Zlib headers. JSZip selects MIT from its
  MIT/GPL dual grant while retaining both. **jsbn** uses Tom Wu's custom
  permissive intact-notice condition, also bundled alongside MIT in ecc-jsbn.

### Local gates and boundaries

**[Forgejo #107](https://forge.nogroup.group/tay/guix-channel/issues/107)
remains OPEN: literal clean own lint is unmet.** Main exercised the original
converter end to end; this does not waive the independent full-lint gate.

| Gate | Main receipt |
| --- | --- |
| Initial source build | bg126 passed in **28.44 s**, artifact **16213**, output `/gnu/store/np0bhv0594mp167kgr1lhnsx05v436cf-persephil-1.0.0-0.1e10afb`. Superseded by the formatting-corrected output below. |
| Initial full lint | bg127 completed in **10.43 s**: own 99-character line-length finding at line 67, no-updater and source-archive findings. This was not clean lint; the long line was subsequently corrected. |
| Initial native consumer | bg128 failed in **7.30 s before application launch** because the harness looked under `bin/ip` instead of actual `sbin/ip`. Not converter failure or native acceptance; the corrected harness is exercised below. |
| Final source build | bg129 passed in **6.35 s**, artifact **16216**, output `/gnu/store/cx8b74sd96chjdxyg36sl2412j1xzlx9-persephil-1.0.0-0.1e10afb`, derivation `/gnu/store/r9jkrj3whvy9i06myy08mhkjhswpdssk-persephil-1.0.0-0.1e10afb.drv`. Its syntax and offline module-load/exact installed-manifest check phases passed. |
| Final reproducibility | bg130 `--check` passed in **4.80 s**, artifact **16217**, for that same final output and derivation. |
| Final integrated consumer | bg131 passed in **8.94 s**; `/tmp/persephil-native-2` retains actual HTTP, decoded XLSX XML/rich-text cells, natural CLI exit **0**, caller-file preservation, read-only store and unchanged NAR proof. |
| Final full lint | bg132 completed in **7.29 s**: own **no updater** and **source-archive** findings at `tay/packages/persephil.scm:17:2` remain. The global flex deprecation warning is separate. Formatting is corrected, but literal clean own lint remains **unmet**, with no waiver or selected-checker substitution. |
| Final independent standalone consumer | bg133 passed in **4.34 s**; `/tmp/persephil-native-3` independently retains the same final output's real HTTP-to-XLSX behavior, natural exit **0**, unchanged NAR and cleanup. |
| Missing-variable guard | bg134 rejected with make exit **2** in **1.53 s**, requesting a canonical prebuilt output and fresh absolute evidence directory instead of implicitly building or launching Persephil. |

### Actual native workbook evidence

The integrated and independent consumers invoked the installed
`bin/persephil` with ordinary URL argv, serving original-shaped legacy KWIC
HTML over loopback HTTP in isolated user/mount/network/PID namespaces.
The process kept UID **1000**, GID **998**, with only `lo` and a read-only
`/gnu/store`; no clock hook or injected runtime module replaced the converter.
The integrated HTTP receipt records a real **GET** of
`/legacy/Latin/kwic?kwic=omnis&fixture=persephil`, not synthetic JSON input.
The fixture HTML SHA-256 is
**`a9310e74f8a0a25a5392f82f34a1bd46ae0b684131a66221f1a95638be7a7e82`**.
Decoded workbook XML verifies the **Data** sheet and exact headers
**Text / Extract / Work / Passage**, with three nonempty result rows:

| Text | Extract | Work | Passage |
| --- | --- | --- | --- |
| Gallia est omnis divisa in partes tres. | omnis | Caesar, De bello Gallico | 1.1 |
| Arma virumque cano, Troiae qui primus ab oris. | virumque cano | Vergil, Aeneid | 1.1 |
| Nihil & virtūs sine labore. | virtūs | Seneca, Epistulae morales | 67.4 |

The `omnis`, `virumque`, `cano` and `virtūs` runs are bold in the Text and
Extract cells; intervening spaces and surrounding context remain nonbold,
in **Times New Roman**. The entity-decoded ampersand and Unicode macron
survive the original HTML parser and actual XLSX serialization.
Integrated output is **`Latin corpus search 10-09-26 23 01 46.xlsx`**,
SHA-256 **`8519b6aadb61fbfc46899b87d326170624875b7f01c4dbc8663a37f8a79e741f`**;
independent output is **`Latin corpus search 10-09-26 23 01 58.xlsx`**,
SHA-256 **`d4979163ef1526fb03d4523d15d9679d090a657f2127b095f34d13808bd7fb08`**.
Both filenames fall within the separately recorded real start/end clock
intervals. Each caller directory gained only the expected dated workbook;
its preexisting files were preserved. Both CLI processes exited naturally
with **0**, without forced cleanup. Servers/threads closed, namespace processes
exited and transient consumer scratch was removed while evidence was retained.
The final output NAR before and after each run is
**`1v2j2bvs7xyn01f9vfx5cvwyc62zg3cfjpc6r4ka69fj8snp377r`**.

Acceptance is bounded to this **legacy HTML URL-to-workbook path**. Current
PhiloLogic JSON API compatibility and a live remote corpus were not exercised.
No upstream test-suite pass is asserted: upstream's npm test is a placeholder
that exits 1; the real offline closure checks and native consumer are separately
identified above. The full source-download scratch
`/tmp/persephil-sources-_s0xjr57` was removed by Main after this compact source
audit was saved; native evidence directories are retained, not cleanup targets.
This documentation worker ran no builds, linters, tests or executable checks.

### Publication and mirrored tracker readback (2026-10-09)

Signed channel commit
**`e9eae477eb73b4fc9bb07473f6b5749f283eae79`**, parent
**`fd99d9e62a9a9d14c8493280ec7493a1570d28f8`**, was published by a normal
authoritative Forgejo `master` push. Publisher receipts record successful
exact-OID channel authentication and matching SSH/master/API readbacks;
Forgejo reports **signature verified=true**. This establishes that bounded
publication, not a GitHub code push, profile installation or deployment.

The tracker worker posted matching #107 evidence comments
[Forgejo 3278](https://forge.nogroup.group/tay/guix-channel/issues/107#issuecomment-3278)
and [GitHub 6090785863](https://github.com/htayj/guix-channel/issues/107#issuecomment-6090785863).
Each POST returned **201** and authenticated GET **200**, with exact intended
bodies read back; **#107 remains OPEN in both trackers**, with the literal
clean-own-lint gate unmet. The workbook exports' naturally differing bytes
are not a claim of byte-identical export reproducibility; the native assertions
compare decoded cell/style semantics, while `--check` covers package output.

The complete paginated fourth-wave audit covered **755 Forgejo issues
(387 open / 368 closed)** and **725 GitHub issues (385 open / 340 closed)**,
with **725 shared pairs / 722 unique titles** and **zero title, open/closed or
`state:*` workflow drift**. Thirty Forgejo-only issues (#728–757), no GitHub-only
issues, and no required reconciliation were recorded; no states/labels changed.

The same bounded wave updated still-OPEN #221 via
[Forgejo 3279](https://forge.nogroup.group/tay/guix-channel/issues/221#issuecomment-3279)
and [GitHub 6090786123](https://github.com/htayj/guix-channel/issues/221#issuecomment-6090786123),
also POST **201** / exact authenticated GET **200**. Its primary
[MIT CADR source LICENSE](http://www.unlambda.com/mit/LICENSE) actually states
**Copyright (c) 1980, Massachusetts Institute of Technology**, with
three-clause BSD-style retention/nonendorsement terms, **not standard
MIT/Expat**. This recovered system-source release's grant does not establish
coverage of Parker's separate emulator C sources, unya modifications or
arbitrary PROM/microcode/load-band/disk images; explicit emulator and exact-image
rights remain unverified, and #221 remains blocked. No emulator/image delivery
or legal waiver is inferred from this tracker correction. The tracker wave
reran no builds/tests/lint/apps/Goocastle and changed no repository files;
the canonical **629** snapshots remain unchanged. No described deployed system
changed, so no OKF page/log update applies to this publication/tracker receipt.

## Astx — native CTS loader and confirmed structural rewrite (2026-10-09)

Local evidence covers the existing [`astx`](guix/tay/packages/astx.scm)
**0.0.0-development-0.9f0ee21** structural JavaScript/TypeScript CLI, not a
help-only launch. It reuses `codemodsquad-astx-source` at
**`9f0ee21ce3b1e34a0122a50a5e604a109fa9a09a`**, source hash
**`0bhwhf118z6w7li7g732ndlhw4qg7wmxmmsczfqbyx1xxbzyjzs7`**.
The existing source pin/hash and `PROJECT_PACKAGES` entry are unchanged;
no application is added, all package counts stay unchanged, and the canonical
**629** preservation snapshots are untouched. Private npm inputs and the
source-built esbuild helper are dependency closure, not extra applications.
**[Forgejo #104](https://forge.nogroup.group/tay/guix-channel/issues/104)
remains OPEN: literal clean own lint is unmet.** Native acceptance does not
waive lint or establish signed publication, profile installation or deployment.

| Gate | Main receipt |
| --- | --- |
| Original source build | Main bg112 passed in **435.75 s**; artifact **16058** records `/gnu/store/0vv48k3qb93pafgl0dr9khg5jfsrcsd9-astx-0.0.0-development-0.9f0ee21`. No upstream test count is asserted from the unsaved middle of the large build output. |
| Original reproducibility | Main bg114 `--check` **failed** in **268.35 s**; artifact **16070** records an output mismatch. Main's comparison found only pnpm `.modules.yaml` `prunedAt` wall-clock differences in the installed runtime and copied notices; all other bytes were identical. This is not a reproducibility pass. |
| Final source build, normalized recipe | Main bg119 passed in **272.40 s**; artifact **16094** records `/gnu/store/jdisc1z7kwwmmgn6afqxwzv8hdl9rglz-astx-0.0.0-development-0.9f0ee21`, derivation `/gnu/store/sybqfglpvvfhfrywp04smqb24hi7v7xx-astx-0.0.0-development-0.9f0ee21.drv`. |
| Final reproducibility, normalized recipe | Main bg121 `--check` passed in **276.04 s**; artifact **16103** records the exact same final `jdisc1z7kwwmmgn6afqxwzv8hdl9rglz` output and `sybqfglpvvfhfrywp04smqb24hi7v7xx` derivation. This supersedes the original bg114 mismatch, not its retained failure record. |
| Full lint | Main bg113's inline result completed in **22.43 s**: own **no updater for astx** and **source not archived in Software Heritage / missing Disarchive** findings at `tay/packages/astx.scm:45:12` leave literal clean own lint **unmet**. The separate global flex deprecation and flexible-SQLite `database is locked` warnings are not astx native-runtime failures. No selected-checker pass or warning suppression substitutes for this full result. |
| Final full lint, normalized recipe | Main bg120's inline result completed in **10.32 s**: own **no updater** and **Software Heritage / missing Disarchive** findings at `tay/packages/astx.scm:42:2` still leave literal clean own lint **unmet**. The global flex deprecation warning is separate; #104 stays OPEN without a waiver. |
| Initial integrated consumer | Main bg115 failed in **12.00 s**; `/tmp/astx-native-1` retains the JS parser error `Cannot combine flow and typescript plugins` and failed match/change counts. It is not native acceptance. |
| Corrected integrated target, original output | Main bg116 `make check-astx` passed in **13.09 s**; `/tmp/astx-native-2` records the actual installed CLI, real `.cts` loader, PTY decline/accept, JS/TS rewrite, equal JS semantics and natural exits **0, 0**. |
| Independent standalone consumer, original output | Main bg117 passed in **9.49 s**; `/tmp/astx-native-3` independently records the same behavior and unchanged original output. These two receipts are historical evidence for the original build, not acceptance of a later package correction. |
| Final integrated target, normalized output | Main bg122 `make check-astx` passed in **13.12 s**; `/tmp/astx-native-4` records the final `jdisc1z7…` output, actual `.cts` loader, unchanged decline, exact JS/TS rewrite on accept, equal JS semantics and natural exits **0, 0**. |
| Final independent standalone consumer, normalized output | Main bg123 passed in **10.13 s**; `/tmp/astx-native-5` independently records the same final output, loader/consent/rewrite/JS-semantics behavior, natural exits **0, 0**, unchanged NAR and cleanup. |
| Missing-variable guard | Main's invocation of `make check-astx` without its required variables rejected with make exit **2** in **1.89 s**, requesting a prebuilt output and fresh evidence directory instead of implicitly launching or building astx. |

The package correction normalizes only the top-level `prunedAt` scalar in
`node_modules/.modules.yaml` immediately after `pnpm prune --prod` and before
both the runtime and dependency-notices copies. Guile formats
`SOURCE_DATE_EPOCH` using `gmtime` and `%a, %d %b %Y %H:%M:%S GMT`, retaining
the dependency graph metadata and all licenses instead of deleting metadata
or reserializing YAML. Source/dependency pins and the native wrapper are
unchanged. Final bg119/bg121 now establish successful rebuild and
reproducibility of that correction; the failed bg114 remains historical evidence.

### Actual public CLI, loader and consent path

[`tests/astx-smoke.sh`](tests/astx-smoke.sh) and
[`tests/astx-native.py`](tests/astx-native.py) consume a supplied realized
direct store output and a fresh absolute evidence directory outside the store.
The Makefile requires both `ASTX_OUTPUT` and `ASTX_EVIDENCE`. The shell may
realize generic harness tools before isolation, but never builds astx itself.
The ordinary installed `bin/astx` wrapper executes its store-bound Node
**24.18.0**, defaults `ASTX_WORKERS` to **1**, and supplies its source-built
**astx-esbuild 0.25.0** via `ESBUILD_BINARY_PATH`.

The consumer supplies `--transform has-own.cts` with actual typed exports:
`export const find: string = \`$a.hasOwnProperty($b)\`` and
`export const replace: string = \`Object.hasOwn($a, $b)\``. This exercises
the installed TypeScript/esbuild loader, not plain JavaScript `require`, a
mock executor or a replacement implementation. Public local configuration
uses `parser: "babel/auto"`, `prettier: false` and
`preferSimpleReplacement: true`; the auto parser chooses syntax per file.
The initial consumer incorrectly forced the TypeScript plugin onto JS that
already selected Flow. Its retained failure is corrected in the consumer
configuration, not hidden or bypassed in the application.

On a **40×140** PTY, the actual CLI previews **2 files changed / 1 file
unchanged** and displays its ordinary `Apply changes (y/N)` prompt. Answer
`n` leaves every fixture, transform and config byte unchanged. A fresh actual
CLI invocation receives `y` only after that prompt; it rewrites two JS calls
and the annotated TS call to `Object.hasOwn`, exactly matching expected bytes.
Comments, string literals, TS annotations, the unrelated file, transform and
config are preserved. Installed Node evaluates the JS fixture before and after
with zero-status exits and identical JSON:
`{"found":true,"absent":false,"unrelated":"data.hasOwnProperty(key)","value":7}`.
This semantic assertion is for the JS fixture; TS preservation is byte-exact,
not a separately executed TypeScript semantic test.

### Same-UID, read-only isolation and retained cleanup

The successful original-output receipts and both final normalized-output
receipts (`native-4` / `native-5`) retain owner UID **1000** / GID **998**
in distinct user/mount/network/PID namespaces, with only loopback
present. `/gnu/store` is recursively private and **read-only**, and installed
output modes and license/notices are checked before and after. The CLI uses
private HOME/XDG/TMP/work directories, `TERM=xterm-256color`, `LC_ALL=C` and
the harness's store-bound coreutils-only PATH, not a host Node on PATH.
The runtime closure is retained. The original-output before/after
`guix hash -S nar` values are
**`108lysxrkl80wc3qyc6nqp5fmmbrfhjy355rjas8bhqq9bpv9bm6`**; the final
normalized-output native-4 and native-5 before/after values are
**`1dxgaahjsqzmzr70vn712zmm47123gg8xq0mkpkwpjs40a8vma1y`**.
Consumer and after-output-check statuses are **0**, and each supplied output
is unchanged. Both CLI runs in each receipt exit naturally **0**, are reaped
and close their PTYs without
forced cleanup. The esbuild descendant is naturally reaped at status **0**;
no child PIDs remain. Scratch is removed and the namespace process exits;
raw/decoded PTY, input, before/declined/accepted byte snapshots, semantics,
isolation/mount, launcher/tool/closure, NAR and cleanup evidence is retained
outside that scratch. No runtime execution or verification was performed by
this documentation worker. This is repository-only work; no described deployed
host/service changed, so no OKF page or log update applies.

### Published cutover and bounded tracker readback

Signed channel commit **`b392179753c7a284a3fabefe367858c7e33dcd5a`**, parent
**`fa2f7123b273bad80302e3676f320d97e3430ea0`**, was published by a normal
push to authoritative Forgejo `master`. Retained publisher/tracker receipts
record exact-commit channel authentication, matching authoritative master/API
readbacks and Forgejo signature **`verified=true`**. This records repository
publication, not a GitHub code push, profile installation or host deployment.
The paired evidence comments are
[Forgejo **3273**](https://forge.nogroup.group/tay/guix-channel/issues/104#issuecomment-3273)
and [GitHub **6090343301**](https://github.com/htayj/guix-channel/issues/104#issuecomment-6090343301).
Both retain **#104 OPEN**, with `state:blocked` / `state:research`; final
build/reproducibility/native receipts do not waive the own updater/archive
lint gate. The old #638 execution contract is retired; its existing PNG is
preserved, not replaced by a new screenshot or a Goocastle execution claim.

The same bounded tracker wave records two rights-evidence corrections without
inventing grants or changing packages/assets. **#228** remains OPEN with
`state:blocked` / `state:deferred`: its explicit Cabal BSD3 and genuine author
metadata are not automatically invalid merely because a full license file is
absent. The complete nine-file pinned tree nevertheless lacks the full notice,
and the actual holder notice remains unresolved; derivative `pandoc-minted`
provenance requires separate rights/notices. Current ncaq HEAD
**`a46d2aae`** has a GPLv2 license and GPL-2.0-or-later / Copyright 2015 ncaq
notice, **not** an asserted grant covering the historical derivative revision.
The paired correction receipts are
[Forgejo **3275**](https://forge.nogroup.group/tay/guix-channel/issues/228#issuecomment-3275)
and [GitHub **6090343527**](https://github.com/htayj/guix-channel/issues/228#issuecomment-6090343527).
**#219** also remains OPEN with `state:blocked` / `state:deferred`: its pinned
README MIT use/modify/distribute grant is affirmed, while the five fonts,
two photos and Preview/PDF asset paths/blobs remain uncleared. No prohibition
is inferred from filenames, and no asset removal/replacement, scope change or
license-field edit is claimed. Its paired receipts are
[Forgejo **3276**](https://forge.nogroup.group/tay/guix-channel/issues/219#issuecomment-3276)
and [GitHub **6090343766**](https://github.com/htayj/guix-channel/issues/219#issuecomment-6090343766).

`BrowserTrackerSync` retains all six comment POST statuses **201**, individual
GET readbacks **200** with exact intended bodies, identical paired comments
and preserved issue labels. Its full post-wave audit records **755** Forgejo
issues (**387 open / 368 closed**) and **725** GitHub issues
(**385 open / 340 closed**), **725** shared pairs, **30** Forgejo-only and
**0** GitHub-only issues, with zero title/open-closed/workflow drift and no
reconciliation mutations. These tracker counts do not alter package inventory
or the canonical **629** preservation snapshots. This addition records
retained Main/publisher/tracker evidence only; no build/test/lint/app/Goocastle
execution, gate waiver or rbw session change occurred in this documentation
update. No described deployed system changed, so no OKF page/log update applies.

## Clojure-Roguelike — native one-shot prototype render (2026-10-09)

Local evidence covers the existing
[`clojure-roguelike`](guix/tay/packages/clojure-roguelike.scm)
**0.1.0-0.16102d6** package and its actual upstream prototype, **not gameplay**.
The package definition, source pin/hash and existing `PROJECT_PACKAGES` entry
are unchanged; no program is added and all inventory counts, including the
canonical **629** preservation snapshots, remain unchanged.
**[Forgejo #101](https://forge.nogroup.group/tay/guix-channel/issues/101)
remains OPEN: literal clean own lint is unmet.** Build, reproducibility and
native rendering do not waive the updater/archive gates. Signed publication
is separately recorded below; no profile installation or deployment is claimed.

| Gate | Main receipt |
| --- | --- |
| Source build | Main bg106 passed in **34.36 s**; artifact **16032** records `/gnu/store/9ar87r9kngkm7kxmfnqrwgzdv3ri6k2k-clojure-roguelike-0.1.0-0.16102d6`. |
| Reproducibility | Main bg108 `--check` passed in **8.02 s**; artifact **16037** records the same output. |
| Full lint | Main bg107 completed in **13.05 s**: own **no updater** and **missing Disarchive/Software Heritage archival** findings at `tay/packages/clojure-roguelike.scm:76:5` leave literal clean own lint **unmet**. This is the full lint result, not a selected-checker pass or suppressed warning. |
| Initial integrated consumer | Main bg109 failed in **4.64 s**, before the application launched; `/tmp/clojure-roguelike-native-1/runtime.json` and `driver.stderr` retain the route-parser assertion failure. It is not native application acceptance. |
| Corrected integrated target | Main bg110 `make check-clojure-roguelike` passed in **4.95 s**; `/tmp/clojure-roguelike-native-2` records the actual installed launcher, PTY room output, zero input bytes, natural application exit **0**, immutable output and cleanup. |
| Independent standalone consumer | Main bg111 passed in **0.86 s**; `/tmp/clojure-roguelike-native-3` independently records that same one-shot native behavior and unchanged output. |
| Missing-variable guard | Main's invocation of `make check-clojure-roguelike` without the two required variables rejected with make exit **2** in **1.70 s**, requesting a prebuilt output and fresh evidence directory rather than building or launching implicitly. |

### Faithful upstream scope, not an invented game loop

At the existing pin **`16102d6123a19dbac03f457a13e8b9f1e181f577`**, upstream
[`src/roguelike/core.clj`](https://github.com/charlesrosenbauer/Clojure-Roguelike/blob/16102d6123a19dbac03f457a13e8b9f1e181f577/src/roguelike/core.clj)
has `-main` call `(println (showblock (roomBlock 8 8 3 8 0 0)))` once and
return. The installed JAR retains this source. Run `clojure-roguelike` without
special arguments: it prints the following room and naturally exits **0**.

```text
########
#......#
#......#
.......#
#......#
#......#
#......#
########
```

There is no input loop, player movement, turn processing or persistent
save/restore state in this upstream entry point. Those are absent **by design
at this pin**, not skipped acceptance scenarios. The native consumer sends
**zero input bytes**, requires the exact eight decoded rows and normal exit,
and explicitly records `gameplay: false`; it does not add a game engine,
inject state, wrap an imitation renderer or claim interactive gameplay.

### Same-UID, read-only native consumer and retained evidence

[`tests/clojure-roguelike-smoke.sh`](tests/clojure-roguelike-smoke.sh) and
[`tests/clojure-roguelike-native.py`](tests/clojure-roguelike-native.py)
consume only a supplied already-realized direct `/gnu/store` output and a
fresh absolute evidence directory outside the store. They resolve existing
tools without building the application or generic tools. The Makefile requires
both `CLOJURE_ROGUELIKE_OUTPUT` and `CLOJURE_ROGUELIKE_EVIDENCE`.
The ordinary installed launcher was observed executing packaged Java with
`-jar` and the installed `share/java/clojure-roguelike.jar`, with
`roguelike.core` as its main class, on a **24×80** PTY. It used private empty
HOME/XDG/TMP/caller directories, `TERM=xterm-256color`, `LC_ALL=C.UTF-8` and
`PATH=/nonexistent`.

Both successful receipts retain owner UID **1000** / GID **998**, including
the actual Java process, in separate user/mount/network/PID namespaces.
Only down loopback exists, with no IPv4 routes; `/gnu/store` is recursively
private and **read-only**, and installed output modes are checked before and
after. Runtime closure and before/after NAR checks all return **0**. The exact
unchanged output NAR (`guix hash -S nar`) is
**`17fdzqhz8pnbkbwas3dpkrgl3vc6zwv6k66xzn9rjy22b7m64jn1`**.
The mutable-directory inspection is empty. Both `cleanup.json` receipts
record `clean: true` for their task-created scratch directories; terminal,
launcher/process, namespace/mount, closure and NAR evidence remains outside
the removed scratch.

The initial bg109 checker wrongly required exactly one IPv4 route-table
header line; an empty route table triggered `namespace has IPv4 routes`
before application launch. The correction captures the table once, accepts
an empty table or the optional `Iface Destination` header, and still rejects
every actual nonblank route row. The failed native-1 evidence is retained
honestly; only native-2 and native-3 establish the corrected native render.
Same-UID, namespace, interface/loopback and recursive read-only store gates
remain intact. No runtime execution or verification was performed by this
documentation worker. This is repository-only work; no described deployed
host/service changed, so no OKF page or log update applies.

### Published cutover and tracker readback

The earlier local-only receipt above is supplemented by signed channel commit
**`fa2f7123b273bad80302e3676f320d97e3430ea0`**, parent
**`34fa8ccc0feb392cf6238708b13a71afb94c6b1f`**, normally pushed to authoritative
Forgejo `master`. Retained publisher evidence records exact-OID channel
authentication, matching SSH/master/API readbacks and Forgejo signature
**`verified=true`**. The publication contains only the five owned acceptance
files: `tests/clojure-roguelike-native.py`, `tests/clojure-roguelike-smoke.sh`,
`Makefile`, `README.md` and `ACCOUNTING.md`; no recipe/source replacement or
629-ledger change. No GitHub code push or deployed host/profile state is claimed.

The retained paired tracker receipts are Forgejo comment **3270** and
[GitHub comment **6089922035**](https://github.com/htayj/guix-channel/issues/101#issuecomment-6089922035);
**#101 remains OPEN in both trackers** because the own updater/archive lint
gates remain unmet. The bounded accompanying **#97** update is Forgejo comment
**3271** and [GitHub comment **6089922221**](https://github.com/htayj/guix-channel/issues/97#issuecomment-6089922221):
it retains OPEN / blocked status and identifies the actual pinned Linux
LispWorks/CAPI build/delivery requirement, not an accepted free-source runtime.
Main's full post-wave tracker readback records **755** Forgejo issues
(**387 open / 368 closed**) and **725** GitHub issues (**385 open / 340 closed**),
with **725** shared pairs and zero workflow/state/title drift. Those are tracker
counts, not package counts or additions to the canonical **629** snapshots.
The publication and tracker facts are retained Main/publisher evidence;
this documentation addition ran no build/test/lint/app/Goocastle checks and
did not alter rbw session state or tracker dispositions.

## Browsh — ordinary native terminal browsing (2026-10-09)

Local evidence covers the new [`browsh`](guix/tay/packages/browsh.scm)
**1.8.2** terminal browser, not just its preserved source snapshot. The
ordinary installed program rendered documents, followed a real HTML link,
edited an HTML input, submitted the native GET form and quit cleanly using
packaged **Firefox ESR 140.13.0esr**. This is repository-local acceptance of
the exercised path; signed code publication is recorded below, but this is not
profile installation, deployment or proof of arbitrary external websites.
**[Forgejo #96](https://forge.nogroup.group/tay/guix-channel/issues/96)
remains OPEN:** literal clean own lint is unmet because no updater recognizes
the canonical codeload SHA archive and the required external source archival
is absent. Successful native behavior and reproducible builds do not waive
that gate.

### Signed publication and authoritative tracker readback

The implementation is published as signed commit
[`34fa8ccc0feb392cf6238708b13a71afb94c6b1f`](https://forge.nogroup.group/tay/guix-channel/commit/34fa8ccc0feb392cf6238708b13a71afb94c6b1f).
Authenticated Forgejo master/exact-commit API readback matched that commit and
reported signature `verified: true`. This establishes code publication, not
profile installation or deployment, and does not close the unmet lint gate.
Identical bounded publication/acceptance comments were posted and read back
on [Forgejo #96, comment 3266](https://forge.nogroup.group/tay/guix-channel/issues/96#issuecomment-3266)
and [GitHub #96, comment 6089813948](https://github.com/htayj/guix-channel/issues/96#issuecomment-6089813948).
Both issues remain **OPEN**, with `state:blocked` and `state:research`.

The same dated full paginated tracker audit found **755 Forgejo issues
(387 open / 368 closed)** and **725 GitHub issues (385 open / 340 closed)**.
All **725 shared issue pairs** had zero title or open/closed-state drift;
the 30 Forgejo-only issues **#728–757** were untouched. **89** mirror workflow
label differences were reconciled to authoritative Forgejo labels; final
full readback found **zero title, open/closed-state or workflow-label drift**.
Authoritative records, non-state labels and mirror open/closed states were
preserved; this metadata alignment did not relax research or paused gates.

Related bounded rights corrections also remain research, not asset clearance:
[Darkmoor #99, Forgejo comment 3268](https://forge.nogroup.group/tay/guix-channel/issues/99#issuecomment-3268)
and [its mirror comment 6089831451](https://github.com/htayj/guix-channel/issues/99#issuecomment-6089831451),
and [FastFlix #100, Forgejo comment 3267](https://forge.nogroup.group/tay/guix-channel/issues/100#issuecomment-3267)
and [its mirror comment 6089814160](https://github.com/htayj/guix-channel/issues/100#issuecomment-6089814160).
Those authenticated, identical comment readbacks keep both pairs **OPEN** and
`state:blocked` / `state:research`; they are not redistribution permission,
all-art clearance, package substitutions or source-pin/hash changes.

| Gate | Main receipt |
| --- | --- |
| Full source build | Latest Main bg99 passed in **75.17 s**; artifact **15998** records `/gnu/store/2rbl4hawgig4nrkhj9amy48cahmg6z0i-browsh-1.8.2` after the lint/input fixes. Earlier canonical-XPI bg93 passed in **71.05 s** (artifact **15984**, output `6jvf3hiwfvzxy8igwqq80cxqvpc5wn4m`); bg90 passed in **68.58 s** (artifact **15976**, output `jdwbzib5wq3m61yshmk705as393i9n50`) before archive encoding was canonicalized. All builds include generated fonts, release JavaScript, unsigned embedded XPI and Go executable. |
| Build-time tests | Artifacts **15976**, **15984** and latest **15998** record `TestFrameBuilder`, `TestMultiLineTextBuilder`, `TestRawTextServer` and `TestBrowshUnits` passing; the latter ran **33 of 33 Ginkgo specs**, 0 failed/pending/skipped. The JavaScript graphics/text suites passed **7 tests**. Full check builds rerun these suites. |
| Ordinary native PTY | Latest Main bg102 integrated `make check-browsh` passed in **14.41 s**, with evidence **`/tmp/browsh-make-final-2`** on final output `2rbl4hawgig4nrkhj9amy48cahmg6z0i`; separate bg103 passed in **10.20 s**, evidence **`/tmp/browsh-native-9`**, on that same output. Earlier bg91 (**9.60 s**, native7) and bg96 (**14.06 s**, make-final) remain historical real-consumer evidence on their dated outputs. |
| Output integrity | Both latest native consumers record before/after file-mode/output checks and closure status **0**, with unchanged `guix hash -S nar` **`09xrkj7nqli7ka6bihs7z8aqjvsldi3wd8gphr76sk242i3hwyaf`**. Earlier `6jvf…` NAR is `0xyp8i9c2yn95f6v0z5172kikjq6sl8vdiy7qf9ry1z8j88pmy4w`; native7's is `05qpc2dlk3308h5yriiggqkkaxqzmh3c8jjv82jp7j32xac07nsg`. These integrity checks remain separate from reproducibility. |
| Reproducibility | Final Main bg101 `--check` passed in **70.87 s**; artifact **16001** records exact final output `/gnu/store/2rbl4hawgig4nrkhj9amy48cahmg6z0i-browsh-1.8.2`. Earlier bg94 passed in **69.05 s** (artifact **15986**) on `6jvf…`; bg92 failed in **66.49 s** (artifact **15979**) on `jdwb…`: XPI member payloads were identical but ZIP order/wall-clock timestamps and the embedded executable differed. Canonical archive encoding resolves that observed cause; the earlier failure is not represented as a pass. |
| Full lint | Final Main bg100 completed in **52.98 s**: only own **no updater** and **missing Disarchive/Software Heritage archival** findings remain at `browsh.scm:29:2`; literal clean own lint is **unmet**. Earlier bg97 (**82.28 s**) also reported missing `bash-minimal`, patch representation and a 97-character line; the input/searched-path/line fixes remove those first three in the actual final run. The global deprecated `flex` warning and `libcamera-minimal` import ambiguity are separate, not Browsh findings. No suppression is used. |

### Canonical source, complete build and redistribution notices

The package inherits the existing `browsh-org-browsh-source` origin at
**`499ef386d45cd1e2b5457dd04887c017f77b7e27`**, Guix archive hash
**`1322fy3b7b6yqlcw86hfj75k80kxzgqmd5qykdfy81mqmph06ahh`**.
The [pinned source](https://github.com/browsh-org/browsh/tree/499ef386d45cd1e2b5457dd04887c017f77b7e27)
provides the Go interfacer, web extension and font-generation script. Existing
XPI, generated TTF files, `node_modules` and `dist` are discarded before
building. FontForge executes upstream `font_maker.py` to generate
**BlockCharMono** and **BlankMono** from the project's own outlines;
Webpack builds both release JavaScript entry points. `web-ext build` produces
the unsigned ZIP. The final package then uses the
[canonical XPI helper](guix/tay/packages/files/browsh-xpi.py) to sort entry
names, fix ZIP timestamps from `SOURCE_DATE_EPOCH` within the DOS timestamp
range, and normalize archive metadata/permissions before embedding
`browsh.xpi` in the Go executable. It asserts that every source-built member,
including directories and empty icons, retains identical bytes; only archive
encoding changes. The earlier bg90 output copied web-ext's archive directly:
bg92 exposed its nondeterministic member order/timestamps, not differing font
or JavaScript payloads. No upstream release binary, committed bundle/font,
AMO download, Mozilla account or signing credential supplies this build.

[`browsh-go-sources.scm`](guix/tay/packages/browsh-go-sources.scm) pins
**36 Go modules**, covering the imports of the interfacer's source, upstream
tests and platform-tagged files. The private recipes install their source
without building separate programs; Browsh compiles the selected libraries
in its Go build. `GOPROXY=off`, `GOSUMDB=off`, `GOTOOLCHAIN=local` and
`GOTELEMETRY=off` keep that build offline. The pinned npm v2 lock is replayed
for **871 Linux locations from 737 distinct tarballs**, including development
tools and runtime dependencies. Only the explicitly optional Darwin-only
`fsevents@2.3.2` location is omitted. The
[helper](guix/tay/packages/files/browsh-npm.py) verifies the lock hash, exact
location coverage, tarball SHA512 integrity, package identity and license
declaration; it runs no npm lifecycle scripts and fetches nothing at build time.
The acquisition receipts distinguish the broader **114-module** selected Go
graph/archive audit from the **36-module** package-import closure: the import
receipt reports **no unresolved external imports**. Only the 36 reachable
modules are delivered as private package inputs; unused downloaded graph
archives are scratch, not extra installed dependencies. The npm receipt
records **872** lock locations before the one Darwin exclusion, **871** emitted
locations, **737** unique archives and **26,783,569 archive bytes**. Its exact
lock SHA256 is `427063e0e6d60355d57a552821fba42e660a34a02a3c765ac49e49435dca02b9`,
git blob `a78f20d06021c885eb8c1e1b643b17fb7f3e0e67`. These acquisition/hash/
metadata audits are not additional executed build/test acceptance; the
source manifests and helper retain the package inputs and integrity checks.


Browsh and its generated project fonts retain upstream **LGPL-2.1** licensing;
the package also records MIT/Expat, Apache-2.0, BSD-2-Clause, BSD-3-Clause and
MPL-2.0 for the linked/retained dependency sources. The output's
`share/doc/browsh` retains upstream `LICENSE`, `README.md`, `go.mod` and
`go.sum`, npm archive inventory and original root/nested notices under
`licenses/npm`, the private Go module notices, and Go compiler/standard-library
notices. `sources/` retains the MPL-covered Hashicorp HCL and x/net sources;
x/net additionally preserves the exact MPL public-suffix-list source and
license identified by its generated table. The copied BSD Go-tools code in
Ginkgo has its separate upstream license retained rather than being treated
as covered solely by Ginkgo's MIT root grant. The bundled lodash notice and
Webpack-emitted license sidecars are retained. Firefox remains the separate
packaged browser dependency, not a redistributed signed Browsh add-on.

### Actual runtime fixes and native evidence

The [Firefox ESR patch](guix/tay/packages/patches/browsh-firefox-esr.patch)
addresses the actual startup failures: the extracted embedded archive now
has an **`.xpi` suffix**, so Firefox classifies it as an archive rather than
an unpacked directory; `Addon:Install` uses **`temporary: true`** to load that
unsigned extension for the session. Firefox receives
**`--remote-allow-system-access`**, and preference setup imports
**`Preferences.sys.mjs`** through `ChromeUtils.importESModule`, with a declared
`prefs` binding. Marionette consumes the greeting and complete length-framed,
matching replies synchronously before dependent commands proceed, instead
of racing fire-and-forget reads against session/add-on/preference operations.
The runtime uses the packaged Firefox path in both its CLI default and sample
configuration; `procps` is supplied for upstream process detection and
`bash-minimal` supplies the actual wrapper interpreter. Guix patch paths use
the existing searched-path string convention, not `local-file` values that
the patch linter rejects. No temporary startup diagnostics remain in the
package patch.

The protocol regression patch registers in the existing Ginkgo suite. Its
scripted `net.Pipe` peer tests fragmented headers/UTF-8 payloads, coalesced
frames, malformed/oversized/truncated frames, the 16 MiB boundary, full-reply
ordering before `Addon:Install`, and invalid/mismatched/error responses.
Those unit peers are not browser-runtime proof. The JavaScript suite uses the
Node loader for upstream graphics/text tests. The separate upstream Go
`test/` integration tree was **not** run: it needs its external web-ext test
environment. Native acceptance below exercises the ordinary installed TUI
with real Firefox, not that integration harness or a fake browser.

Native7 used a private HOME/XDG/profile/work directory, private network/PID/
mount/user namespaces, UID 1000/GID 998, loopback as the sole network
interface, and read-only `/gnu/store`. The process snapshots identify Browsh's
actual `bin/.browsh-real` on a PTY and child
`/gnu/store/k83frhx0f31q12s2gqga6l371wdrmvlp-firefox-esr-140.13.0esr/lib/firefox/.firefox-real`
with `--marionette --remote-allow-system-access --headless --profile …`.
The same identities persist after navigation; fixture requests carry Firefox
140's user agent. The ordinary debug log records successful `NewSession`
with `browserVersion: 140.13.0`, `Addon:Install` on the extracted `.xpi` with
`temporary: true`, the returned `@temporary-addon` identity, and the real
extension's websocket connection. Ordinary `Marionette:Quit` returns
`forced: false` / `in_app: true`. The consumer serves original static HTML,
with **no scripts**, and drives normal terminal key/mouse input:

1. **Ctrl-L**, typed `/doc` loopback URL and **Enter** rendered
   `NATIVE DOCUMENT ONE` and `Follow offline link`.
2. Clicking that rendered link reached `/next` and `NATIVE DOCUMENT TWO`.
3. Clicking the native field and typing **`OFFLINE_INPUT`** displayed that value
   beneath `Offline entry` in `typed-input.document.txt`.
4. Clicking **Submit entry** made Firefox request
   `/submitted?word=OFFLINE_INPUT`; the rendered result contains
   `NATIVE FORM RECEIVED` and `Submitted text: OFFLINE_INPUT`.
5. **Ctrl-Q** returned status **0**, with no remaining browser descendants and
   no forced-cleanup PIDs. The owned private scratch directory's cleanup
   receipt returned 0 and `clean: true`.

`terminal.raw`, `terminal-inputs.json`, `terminal-frames.jsonl`, each
`*.screen.txt`/`*.document.txt`/`*.frame.json`, `http-requests.json`, process
snapshots, isolation records and NAR checks are retained under
**`/tmp/browsh-native-7`**. Text decoding normalizes only Browsh's U+2584
transparent-space rendering; raw terminal bytes and cell attributes remain
available. Ordinary `--debug` produced the retained private debug/profile
diagnostics, not a synthetic render path or instrumentation added to the
application.
The final integrated consumer independently repeats these same key/mouse,
HTTP and real-process assertions under **`/tmp/browsh-make-final`** on output
**`6jvf3hiwfvzxy8igwqq80cxqvpc5wn4m-browsh-1.8.2`**. Its final form screen
contains `NATIVE FORM RECEIVED` / `Submitted text: OFFLINE_INPUT`; its debug
log again records actual Firefox **140.13.0**, successful temporary installation
and unforced in-application quit. Exit status is **0**, browser descendants
are gone, forced cleanup is empty, and the private scratch
`/tmp/browsh-native.xs6s9tjO` cleanup records `clean: true` / status **0**.
The acceptance evidence directories are retained. Main bg95 removed the two
owned acquisition scratch trees after their material facts were recorded,
and removed the obsolete comparison script; no temporary runtime
instrumentation remains.
Main bg98's separate ordinary consumer also passed in **9.71 s** on output
`6jvf3hiwfvzxy8igwqq80cxqvpc5wn4m`; **`/tmp/browsh-native-8`** records status
0 and the same unchanged NAR hash `0xyp8i9c2yn95f6v0z5172kikjq6sl8vdiy7qf9ry1z8j88pmy4w`.
After the wrapper-input/patch corrections, Main bg102/bg103 repeated the
integrated and standalone consumers on **`2rbl4hawgig4nrkhj9amy48cahmg6z0i`**.
**`/tmp/browsh-make-final-2`** and **`/tmp/browsh-native-9`** retain actual
real-Browsh/Firefox identities, screens, HTTP/form results and status-zero
ordinary quits. The final form screen again shows `OFFLINE_INPUT`; Firefox is
the same packaged ESR **140.13.0esr** child, not a substitute process.
Both record unchanged NAR `09xrkj7nqli7ka6bihs7z8aqjvsldi3wd8gphr76sk242i3hwyaf`.
The respective owned scratch paths `/tmp/browsh-native.1je214z5` and
`/tmp/browsh-native.kfGwi2Sp` both have cleanup `clean: true` / status **0**.



### Usage and limits

```sh
guix shell -L guix browsh -- browsh --startup-url https://example.org
out=$(guix build -L guix --no-grafts browsh)
make check-browsh BROWSH_OUTPUT="$out" BROWSH_EVIDENCE=/tmp/browsh-proof-new
```

The standalone Makefile target requires an explicit prebuilt output and a
**new, nonexistent** evidence path outside `/gnu/store`; it is not appended
to the aggregate `make check`. Main actually invoked `make check-browsh`
without the required variables: it rejected with status **2** in **1.75 s**,
diagnosing the required prebuilt store output and fresh evidence path. That
guard rejection is not a browser-consumer run. The first command is a user usage example,
not an external-site verification receipt. The exercised consumer is limited
to offline loopback HTML navigation/input and a native GET form using headless
Firefox. It does not establish external TLS/sites, video/audio, downloads,
graphical-browser-window behavior, every web feature, saved-session continuity
or live profile deployment. Source rebuild reproducibility and both integrated
and standalone ordinary consumers passed on final output **`2rbl4hawgig4nrkhj9amy48cahmg6z0i`**.
Literal clean own lint is **unmet**, and #96 stays OPEN for the remaining
no-updater and source-archive findings; no implemented build/runtime gate is
left pending or waived by those findings.

## Cave Chop — ordinary native terminal save/restore (2026-10-09)

Local evidence covers the existing [`cavechop`](guix/tay/packages/cavechop.scm)
**1.0** definition, not a new application or source snapshot. It remains in
the README's research/outside-normal-build table and outside `PROJECT_PACKAGES`;
the research inventory and canonical **629** preservation snapshots are
unchanged. **[Forgejo #299](https://forge.nogroup.group/tay/guix-channel/issues/299)
remains OPEN: literal clean own lint is unmet.** Successful build and native
continuity do not waive that gate or establish signed publication, profile
installation or deployment.

| Gate | Main receipt |
| --- | --- |
| Source build | Main bg70 passed in **3.98 s**; artifact 15824 records `/gnu/store/417kx53h49k576d4akxmmwv3x0lp6b6j-cavechop-1.0`. |
| Reproducibility | Main bg71 `--check` passed in **1.37 s**; artifact 15826 records the same output. |
| Ordinary native PTY consumer | Main bg73 passed in **8.71 s**; `/tmp/cavechop-native-1` retains three independent ordinary game processes, actual decoded screens, inputs and read-only native-save inspection. |
| Full lint | Main bg72 completed in **6.64 s**: own `generic-html` updater failed to find upstream releases, and source archival reported missing Disarchive information / no Software Heritage archive. Literal clean own lint remains unmet; the unrelated deprecated `flex` warning is not attributed to Cave Chop. |
| Final integrated target | Main bg74 `make check-cavechop` passed in **12.51 s**; `/tmp/cavechop-make-final` records a fresh three-process ordinary consumer on the same output, with `CAVECHOP_NATIVE_OK` in `driver.stdout`. |

### Canonical source and complete redistribution notices

The package compiles the complete canonical
[upstream snapshot](http://git.blackswordsonics.com/?p=cavechop-7drl;a=snapshot;h=ecc8bcfd56b96b71a2521f9b2a005f9cc89f0692;sf=tgz)
at **`ecc8bcfd56b96b71a2521f9b2a005f9cc89f0692`**, upstream master and
`bugfix-release-1` dated **2012-03-19**. Its Makefile declares version **1.0**.
The archive fetched in memory on 2026-10-09 is **40,568 bytes**, SHA256
**`6c16c18125ebd6b3fd56402c0dd2094abfd716b7515700da2050be4a908aef97`**,
Guix base32 **`15zgia84mgjh43d00msinwbdggsa1790sb20avyv7mpb4n0w25kc`**.
The upstream endpoint is HTTP, not authenticated HTTPS; the exact content hash
pins the bytes. Its **23 regular files** comprise **19 C/H files**, Makefile,
MANIFEST, notes.txt and .gitignore: no bundled external assets, binaries or
submodules. This is Martin Read's separate seven-day game, not a runtime
assembled from its Dungeon Bash progenitor.

All 19 C/H prologues carry Martin Read's **2005–2012** copyright and the
two-clause BSD grant; notes.txt carries **2012** and the full same grant.
Source and binary redistribution, with or without modification, are permitted
provided the copyright, conditions and disclaimer are retained. The output
installs the actual unmodified
[notes.txt](http://git.blackswordsonics.com/?p=cavechop-7drl;a=blob_plain;f=notes.txt;hb=ecc8bcfd56b96b71a2521f9b2a005f9cc89f0692)
and [cavechop.h](http://git.blackswordsonics.com/?p=cavechop-7drl;a=blob_plain;f=cavechop.h;hb=ecc8bcfd56b96b71a2521f9b2a005f9cc89f0692)
under `share/doc/cavechop`, preserving both copyright periods, conditions and
disclaimers rather than substituting a generated notice. Installed notes are
**3,346 bytes**, SHA256
**`25e1e232b0a01c0ea193e8eb37a7b672511472f71045f882215b10cc6a77ce3f`**;
the header is **13,557 bytes**, SHA256
**`c954101c8e373d0d85d60cb4a6011f6d0fbaa69cbcd49717b2bc820c159a44eb`**.

### Ordinary launcher and scalar-preserving native restore

Run `cavechop` in a terminal without special arguments. Its installed launcher
execs the source-built `libexec/cavechop` with packaged terminfo, using
`${XDG_STATE_HOME:-$HOME/.local/state}/cavechop` as writable CWD. Native save,
log and character-dump paths therefore stay out of the caller's CWD and the
store. Compressor paths are explicit Guix inputs; the native `gunzip` call
uses the actual `cavechop.sav.gz` suffix. No build-time dependency download or
runtime download is required; the source fetch is the ordinary pinned origin.

The existing bounded save layout writes **39** raw `struct permobj` records
(`NUM_OF_PERMOBJS`), not upstream's out-of-bounds **100**. Restore now reads
each record into a local struct and copies all six scalar fields—`poclass`,
`rarity`, `sym`, `power`, `used`, `depth`—while retaining the current process's
static names/plurals and description pointers. Merely seeking past those
records avoided stale pointers but lost saved scalar state, including the
randomized potion/scroll/ring flavour powers; this fix restores that state.
It preserves the existing **39-record raw layout**, not a new portable format.
The receipt makes **no compatibility claim for original 100-record saves**,
different host ABIs or arbitrary older binaries.

### Three independent ordinary processes, not injected state

[`tests/cavechop-smoke.sh`](tests/cavechop-smoke.sh) and
[`tests/cavechop-native.py`](tests/cavechop-native.py) consume a supplied
prebuilt store output and a fresh evidence directory. Native-1 used empty
`PATH`, `LC_ALL=C`, `TERM=xterm-256color`, a **24×80** PTY and fresh private
HOME/XDG directories. Consumer and game remained at the owner's non-root
UID **1000** / GID **998** in separate user/mount/network/PID namespaces,
with only loopback and recursively read-only `/gnu/store`. Process receipts
identify the installed binary, private state CWD and TTY. Output NAR hashes
before and after are identical:
**`0gyw3sq9bkr6vpaf3nhiimsbm4pjbr77cg3nxb794z0dllkp7jgd`**.

1. Process **2** entered the ordinary name **Native1**, moved with native `y`,
   showed inventory with `i`, and inspected the dagger with `I` then `a`.
   Native `S` plus the ordinary acknowledgement saved and exited **0**.
2. Process **5**, launched without arguments in the same private state CWD,
   automatically loaded and consumed that native save. Its full visible
   **21×21 player-centred map** and HUD matched the pre-save screen. Native
   `I`/`a` again displayed **“A long knife, designed for stabbing.”**, exercising
   the new process's description pointer. Native `S` saved again and exited **0**.
3. Process **9** automatically restored the second native save, reproduced
   the same map/HUD and item description, then continued ordinary `y` movement.
   Food decreased **1999→1998** and wall-scroll witnesses recorded world delta
   **(-1,-1)**; the player-centred viewport stays at **(10,10)**, not a claimed
   fixed world coordinate. Native `X`, confirmation `Y` and acknowledgement
   quit cleanly with exit **0**.

At the continuity boundary the HUD records Native1, **HP 20/20**, **XL 1**,
**Body 10/10**, **Defence 5**, **Food 1999**, **Depth 1**, **Agility 10/10**
and **XP 0**. `continuity.json` records exact visible map/HUD equality and
exact decoded nonblank/HUD styles; only blank map-cell colours are normalized.
Raw map cells, decoded screens, cursor records, PTY transcripts and recorded
inputs are retained rather than replaced by markers.

The consumer only reads/copies the game's native saves; evidence copies are
**never reinjected**. `session-{1,2}-native-save.json` independently parse all
**39 records × six scalars** and establish equality across the ordinary
restore/re-save. On this host the raw record is **128 bytes**, starting at
offset **7076**, in **21,076** uncompressed save bytes. All **12** randomized
flavour powers match: potions **[4,10,5,9]**, scrolls **[5,2,16]**, rings
**[2,6,1,18,5]**. Both uncompressed saves have SHA256
**`d79b9a507d66d0b8bc389cad1107e92564b555163970944fba722dcd20c4225b`**;
gzip metadata need not match. This is observed randomized gameplay, without
seed control, fabricated saves, memory writes, wizard commands, custom runtime
modes or markers emitted by the game. Host game state remained unchanged;
the private save was consumed and no game files remained after clean quit.

The final integrated target is a **separate fresh randomized run**, not a
replay of native-1. Its observed processes **2, 5 and 9** again saved,
automatically restored/re-saved, then independently restored/continued/quit,
all with exit **0**, UID **1000** / GID **998**, private state, loopback-only
network and read-only store. Actual restored screens again show native
`I`/`a` and **“A long knife, designed for stabbing.”**; map/HUD and all
**39 × six scalars** match across restore/re-save. This run's distinct
flavour powers are potions **[6,19,4,15]**, scrolls **[8,9,5]**, rings
**[3,5,7,16,11]**, equal in both parsed native saves. Both uncompressed
save hashes are
**`2422b29f6229165387eb9a2f7d9761197d6f5e7e918b7621fc1a67378a1cd8ac`**.
The third process's ordinary `u` movement lowers Food **1999→1998** before
normal confirmed quit; no save copy was injected, host game state remained
unchanged and private game files were absent afterward. Both final NAR
hashes equal the native-1 value above. The consumer's success marker is
external proof-runner output, not a custom game runtime mode.

The obsolete Goocastle issue-666 `--smoke`/marker contract was removed without
a replacement runtime contract or Goocastle execution. `make check-cavechop`
is a standalone guarded target requiring explicit `CAVECHOP_OUTPUT` and
`CAVECHOP_EVIDENCE`; it does not join the aggregate build/check inventory or
silently build a package. These repository-only changes establish no material
host/service catalog correction, so no OKF page or log update applies. No
temporary files were created by the documentation worker; actual native proof
directories are retained as evidence.

```sh
make check-cavechop \
  CAVECHOP_OUTPUT=/gnu/store/417kx53h49k576d4akxmmwv3x0lp6b6j-cavechop-1.0 \
  CAVECHOP_EVIDENCE=/absolute/nonexistent/evidence-directory
```

The supplied output must be the canonical prebuilt store output, and the
absolute evidence directory must not already exist (including as a symlink).
The command is a developer invocation, not a profile installation or a
default `make build` member.

## ChessRogue — ordinary native Practice gameplay and retry (2026-10-09)

Local evidence covers the existing [`chessrogue`](guix/tay/packages/chessrogue.scm)
**0.3.1** package, built from the complete canonical
[SourceForge source release](https://sourceforge.net/projects/chessrogue/files/chessrogue/0.3.1/chessrogue0.3.1-src.tgz/download).
Its source SHA256 in Guix base32 is
**`15qbvlyamnqjq5lkmbwba68l0n4yl2fxhawxb27xf5djvzfkfyf9`**. This is native
acceptance for an existing package, not an additional inventory entry: package
counts and the canonical **629-source preservation ledger remain unchanged**.
**[Forgejo #303](https://forge.nogroup.group/tay/guix-channel/issues/303) remains
OPEN: literal clean own lint is unmet.** These local receipts do not establish
issue closure, signed publication, profile installation or deployment.

| Gate | Main receipt |
| --- | --- |
| Source build | Main bg58 passed in **119.26 s**; artifact 15732 records `/gnu/store/wkaaw09lcsqvind2hi4ll4vas868i2xc-chessrogue-0.3.1`. |
| Reproducibility | Main bg59 `--check` passed in **19.71 s**; artifact 15735 records the same output. |
| Ordinary native PTY consumer | Main bg68 passed in **22.24 s** on that output; `/tmp/chessrogue-native-7` retains actual native screens, inputs, runtime, report and read-only save inspection. |
| Full lint | Main bg60 completed in **10.00 s**: own release discovery failed with a generic HTML response. Literal clean own lint remains unmet; the unrelated `flex` warning is not attributed to ChessRogue. |
| Final integrated target | Main bg69 `make check-chessrogue` passed in **34.01 s**, emitting `CHESSROGUE_NATIVE_OK`; `/tmp/chessrogue-make-final` records a fresh ordinary consumer on the same output. Main's JSON-validity check passed in **0.01 s**. |

Successful build, reproducibility and native gameplay do not suppress or waive
the own release-discovery lint failure. No honest metadata-only fix was
established for that SourceForge HTML response: the `/download` URL basename
does not establish a supported release updater. The fixed, hashed source
release remains explicit, with no metadata warning-suppression workaround.

### Ordinary launcher, fresh menus and same-process retry

Run `chessrogue` in a terminal. The launcher directly execs the source-built
`libexec/chessrogue`, supplying packaged terminfo and using
`${XDG_DATA_HOME:-$HOME/.local/share}/chessrogue` for its writable CWD and the
game's `HOME`. It copies the original `crkeymap.txt` there only if absent, so
players may edit their own keymap without modifying the immutable default.
It performs no runtime download and does not require the player's `PATH` to
resolve its shell or file utilities.

Native-7 launched the ordinary installed command **without arguments**, with
an empty `PATH`, `TERM=xterm`, `LC_ALL=C`, a **30×100** PTY and fresh private
HOME/XDG directories. Recorded process evidence identifies the installed game
executable, private writable CWD, controlling-terminal file descriptors and
foreground process group. The consumer and game ran at non-root UID **1000**
in separate user/mount/network/PID namespaces, with only loopback and no
external route; `/gnu/store` was read-only. The before/after output NAR hashes
are identical:
**`192f8z5nsivizvfdb14ny45ik84cwvmxsvyvzm1r1p80ssznfivk`**.

The actual `new-game/intro.screen.txt` describes the white survivor and opposing
pieces. `difficulty-menu.screen.txt` offers **1) Practice, 2) Normal,
3) Expert, 4) Master**; `challenge-menu.screen.txt` offers **0) No special
challenges** and **1) Classic pieces**. The recorded inputs dismiss the intro,
select **`1` then `0`**, and inspect the ordinary F6 capture and F5 movement
panels. This is a fresh native menu path, **not a fabricated save used to skip
startup**.

The first `l` input moves `@` from row/column **(0,0) to (0,1)** on level 1;
the recorded board also shows opposing pawns moving. Subsequent ordinary
movement leads to **“The pawn captures you. Checkmate!”**, followed by
**“Press any key for the score (or 's' to try this level again)”**. The consumer
presses native **`s`** at that prompt. In Practice this writes `.crsave` and
continues in the **same process**, regenerating level 1 at its starting square.
The regenerated board differs from the original; a second `l` again moves
from **(0,0) to (0,1)** with opposing-piece response, followed by further
ordinary movement and another native pawn capture of the player.

This **is not save-and-exit or an independent restored process**, and it does
not demonstrate persistent map or mid-level position continuity. Upstream
`main.k:playGame/nextLevel` explains the behavior: a Practice loss followed by
`s` resets the result, decrements the level, writes native state and loops into
a new `makeMap` call. `State.k:saveState/loadState` stores captures, bonus,
difficulty, level, longrun, challenges and equipment, not the generated map
or player coordinates. The consumer reads those bytes without writing them.
The recorded native retry save is **42 bytes**, SHA256
**`fc5279d63e4f3b8fb879fb85a7b0e95b3b59ebfa2ff5316d7cb57401ad6087d8`**:

```text
0|0|0|0|0|0|0|0|0|0|0|0
0|0|0|0
0
-1|-1|-1
```

After the second capture, the consumer requests the native score report,
answers **`y`** to **“Save score report to 'score.TIME.txt'? [y/N]”**, then
**`n`** to **“Again? [Y/c/n] (c=change difficulty)”**. The game exits **0**.
The completed-run path clears `.crsave`; retained writable files are the
ordinary keymap, `.crscore` and `score.20261009152118.txt`. The report records
Practice, level 1, capture at **2026-10-09 15:21:18**, no enemy pieces captured
by the player and **0 points**. Practice games are not high-score eligible;
the `.crscore` initialization is not evidence of a scored high-score entry.

The final integrated run is a **separate fresh random gameplay receipt**, not
a replay of native-7's board. Its actual decoded screens and `runtime.json`
again show native Practice/no-special-challenges menus, two observed `l`
moves from **(0,0) to (0,1)** before and after same-process retry, regenerated
level-1 terrain, ordinary opposing-piece turns and two **“The pawn captures
you. Checkmate!”** prompts. Its read-only native-save inspection records the
same 42-byte save hash above; the final report is instead
`score.20261009152330.txt`, recording **2026-10-09 15:23:30**, Practice,
level 1, no player captures and **0 points**. It exits **0**, retains only
keymap/score/report files and explicitly records no independent restore,
RNG control or state injection. The output NAR hash remains the same above.

**Upstream version discrepancy:** the canonical archive and package are
**0.3.1**, but the unmodified report header says **“ChessRogue 0.3.0 game
score”**. The receipt preserves that embedded upstream string rather than
rewriting the report or claiming a different release was tested.

### Complete curses source, compiler grants and proof boundaries

The package compiles upstream `buildCurses.sh` with the private source-built
**Kaya 0.4.4** compiler. Kaya's fixed build-time `-seedkey chessrogue-0.3.1`
avoids nondeterministic embedded compiler secrets; it is **not gameplay RNG
control**. The native game still seeds its own RNG from time. Native-7 records
`rng_control: null`, `state_injection: null` and
`independent_restore_exercised: false`; no private map/state/seed is injected.
The old compiler's private GHC/random/splitmix dependencies are build closure,
not additional public games or preservation snapshots. Acceptance concerns
the already authorized **curses frontend only**, not SDL execution or assets.

`share/doc/chessrogue` retains the complete original `COPYING.txt`,
`COPYING.pcre.txt`, `COPYING.sdl.txt`, `README.txt`, `INSTALL.txt`,
`CHANGELOG.txt`, `HINTS.txt` and keymap. `license-closure.json` records exact
canonical archive-member byte counts and SHA256 values, not just keyword
matches. The game grant is **GPL-2.0-or-later**, with the full GPL text and
Chris Morris's **2005–2007** source notices retained. PCRE's complete
**BSD-3-Clause** copyright, conditions and disclaimer are retained; the
upstream SDL LGPL notice is preserved as documentation even though SDL is
not built or installed for this runtime. The copied whole Kaya license
umbrella covers runtime/standard libraries and their documentation under
**LGPL-2.1-or-later**, and compiler/other files under **GPL-2.0-or-later**;
both LGPL versions, both GPL versions and `compiler/COPYING` are retained.

Decoded terminal text/cells/JSON are native terminal evidence, **not graphical
screenshots**. This proof establishes menus, ordinary movement/opponent turns,
the player's capture, native same-process Practice retry, report writing and
normal quit. It does not establish independent restore, level completion,
victory, endgame, all difficulties/challenges or a deterministic solver.
Task-owned redundant downloaded game/compiler archives were removed by Main;
immutable Guix source/store material and installed documentation were retained.
This documentation worker ran no commands or checks and created no temporary
files. No described host/service configuration changed or material OKF catalog
correction was established; no OKF page/log update applies to this
repository-only receipt.

## CutlassRL — ordinary native terminal save/restore (2026-10-09)

Local evidence covers the existing [`cutlassrl`](guix/tay/packages/cutlassrl.scm)
**0.05-0.304bb87** package from the canonical
[`stenno/CutlassRL` Git repository](https://github.com/stenno/CutlassRL), pinned
to **`304bb87fc185726f3f7afb08c69564687003d093`**. Its `git-fetch` checkout's
recursive NAR hash is
**`1d2dz0c2xlp5xlkn136apbyc1cgfdypfr2k9kds30yy2gv13jk8h`**. The final recipe
does not use an autogenerated GitHub archive URI. This is native acceptance for
an existing package, not a new inventory entry: the canonical **629-source
preservation ledger and package counts remain unchanged**.
**[Forgejo #320](https://forge.nogroup.group/tay/guix-channel/issues/320) remains
OPEN: literal clean own lint is unmet.** Local evidence does not establish
issue closure, signed publication, profile installation or deployment.

| Gate | Main receipt |
| --- | --- |
| Source build | Main bg48 passed in **2.78 s**; artifact 15682 records `/gnu/store/ydffy1pnvhw7r472r974z6yxj5l1jvzg-cutlassrl-0.05-0.304bb87`. |
| Reproducibility | Main bg50 `--check` passed in **0.95 s**; artifact 15685 records the same output. |
| Final recipe output | Main bg53 returned the same output in **0.89 s**. |
| Ordinary native PTY consumer | Main bg54 passed in **6.47 s** on that output; `/tmp/cutlass-native-4` retains the actual proof and decoded terminal screens. |
| Full lint | Main bg55 completed in **5.49 s**: own `no tags found for cutlassrl` and `updater 'github' failed to find upstream releases` findings remain. No lint artifact ID was supplied. |
| Final integrated target | Main bg56 `make check-cutlassrl` passed in **10.51 s**, emitting `CUTLASSRL_NATIVE_OK`; `/tmp/cutlass-make-final` retains current canonical-Git metadata and ordinary native continuity evidence on the same package output. |

The final full lint has no autogenerated-URI, redirect or archive findings.
The remaining no-tags/GitHub release-discovery findings are not suppressed or
waived by successful build, reproducibility and gameplay. The unrelated `flex`
deprecated-input warning is not attributed to CutlassRL.

The retained native-4 JSON records still carry the earlier autogenerated archive
`source_url` as historical metadata; they do not describe the final source-fetch
method. The final package's canonical Git pin and NAR hash above supersede that
metadata. The final integrated receipt at `/tmp/cutlass-make-final` records
the canonical Git URL, `source_revision` matching the full pin above,
`source_method: git-fetch`, and the matching source NAR hash.

### Ordinary launcher, isolation and observed native continuity

Run `cutlassrl NativeCutlass` in a terminal (or omit the name for the native
name prompt); use `h/j/k/l` or arrow keys to move, `s` to save and exit, then
launch again with the same name for automatic restore. Ordinary `q` followed
by `!` confirms quit. The store-safe shell launcher directly execs the declared
**Python 2.7.18** interpreter and installed `main.py`, disables bytecode writes
and uses `${XDG_DATA_HOME:-$HOME/.local/share}/cutlassrl` as its writable CWD.
There is no runtime download or installed Windows `pdcurses.dll`, developer
`cpf.sh` or `rldev.pl` helper. The complete Git checkout is retained separately
in the immutable store; removing a redundant local archive does not remove it
or immutable archive/store material.

The native proof ran **`NativeCutlass` in ordinary `Player` mode**, not
`Wizard`, in a **120-column, 40-row real controlling PTY**. Both game processes
directly ran the installed Python 2 entrypoint with `PATH` empty, `TERM=xterm`,
`LC_ALL=C`, fresh private HOME/XDG/temp/work directories, and the same UID
**1000** in private user/mount/PID/network namespaces. Each had all three
terminal descriptors on its PTY and its own foreground process group (PIDs
**5** and **7**). Only loopback and no IPv4 routes were recorded;
`/gnu/store` was read-only. The Python 3 external observer only drove PTY input
and decoded output: it did not import game modules, fabricate state, unpickle
the save, modify game data or control the RNG.

In `/tmp/cutlass-native-4/new-game/initial.screen.txt`, the naturally generated
level-1 birth has one `@` at zero-based **(x, y) = (47, 16)**, full **HP 33/33**,
**T:0**, **Score:0**, and **Level:1**. One ordinary `l` input moved the player
onto the adjacent visible floor at **(48, 16)**, redrawing the vacated starting
tile as `<` and the expanded field of view; **T:1**, HP, score and level are
captured in `movement-before-save.screen.txt` and `runtime.json`.

Ordinary `s` produced the raw **`Saved...`** message, a nonempty native gzip
save and exit status **0**, without a quit/death log. The retained opaque-byte
receipt records **31736 bytes**, SHA-256
**`4e86d03e26bbd106b73d22290c82a1fff2206931756853ccdadc4cb6cf71185b`**.
This is one game's save provenance, not save-byte equality across processes.
An independent second launcher exec with a new PID/PTY and the same name
automatically loaded that native save via `mainLoop`, without a wizard-only
`r` command. The raw PTY stream contains **`Loaded...`**; the decoded message
row retains a transient `L`, not a terrain difference. The native load
consumed `NativeCutlass.sav`, as the ordinary non-wizard source path specifies.

Restore continuity compares **every cell of the stable displayed map rectangle
(22 rows × 62 columns)**, the unique player position and all visible stable HUD
fields: name, Player mode, HP/max HP, turns, score and level. These match exactly
between the completed pre-save turn and the restored screen, including
**(48, 16), HP 33/33, T:1, Score:0, Level:1**. The transient message row
(zero-based row 22, owned by `addMsg`) is deliberately excluded. This is full
stable **visible** map/HUD continuity, not proof of hidden map cells, internal
objects, RNG state or unexercised future gameplay.

A further ordinary `l` after restore moved `@` to **(49, 16)** with **T:2** and
another native redraw, proving continued action rather than a frozen restored
screen. Ordinary `q` displayed **`PRESS '!' TO QUIT:`** and left the process
running for confirmation; `!` then exited **0** through native `endwin()` and
`sys.exit()`. The only remaining private file is `data/cutlassrl/mainlog.log`,
containing exactly:

```text
version=0.05:name=NativeCutlass:score=0:hp=33:maxhp=33:killer=Quit:gold=0:kills=0:maxdlvl=1:dlvl=1
```

The consumed save was not reinstated. Before/after output NAR hashes match
**`0psjh4pchq2aw7fnbks53iv12s7ifa8h11a2sc22im2d0fvlgfkp`**. Evidence includes
raw PTY streams, inputs, process records, namespace/mount proof, `.screen.txt`
and `.screen.json` observations and `runtime.json`—not PNG screenshots.

The final integrated run has its own naturally random birth, not native-4's
coordinates or HP. Its decoded initial screen shows **(47, 12), HP 26/26,
T:0, Score:0, Level:1**; ordinary `l` moves to **(48, 12), T:1**. Automatic
restore in a new process consumes its save and exactly preserves every stable
visible map/HUD field; a subsequent `l` reaches **(49, 12), T:2** before normal
`q`/`!` confirmation and exit. Both native processes again exit **0**. Its
opaque gzip save receipt records **31147 bytes**, SHA-256
**`f9fa099862bc6b1fed2719ceeb4d7e2eaf3bdd7014cf8d89ca606593d1d0983c`**;
no equality with the earlier run's save bytes is claimed. The sole surviving
file is the normal quit log:

```text
version=0.05:name=NativeCutlass:score=0:hp=26:maxhp=26:killer=Quit:gold=0:kills=0:maxdlvl=1:dlvl=1
```

Its before/after output NAR hashes also match the hash above. The integrated
screens and parsed runtime receipt were read for this dated account; both
evidence directories and all immutable source/store material were untouched.

### Retained source rights and bounded resource-path fix

The installed `main.py`, `Game.py` and Modules retain their upstream encoding
and complete GPL-3.0-or-later headers and copyright notices. The full **35147-byte**
GPLv3 `COPYING` under `libexec/cutlassrl` matches pinned Git blob
**`94a9ed024d3859793618152ea559a168bbcbb5e2`**; the complete **751-byte** upstream
README under `share/doc/cutlassrl` matches blob
**`a9ae93dfd66c2b56b3f647c2508135900bfc84af`**. `Modules/Unicurses.py` retains
Michael Kamensky's **2010** copyright and independent GPL3+ grant, including
its warranty disclaimer. `Modules/Fov.py` retains Aaron MacDonald's
**June 14, 2007** notice in full, including **“You are free to use or modify
this code as long as this notice is included”** and its no-warranty statement.
`upstream-notices.json` records these grants and checked source headers;
no notice is replaced by generic package metadata. `Modules/__init__.py` and
`Levels/last.lvl` have no separate upstream notices.

The sole gameplay-source packaging adaptation is the bundled last-level path:
`Game.py` resolves `Levels/last.lvl` beside installed `Game.py` using
`os.path.dirname(__file__)`, rather than in the writable save/log CWD. Its
original header is retained, followed by a **2026-10-09** modified-source notice
describing that resource-path change. The level data is installed in the
immutable runtime tree. This fixes resource location structurally; the proof
stays on level 1 and **does not verify the final level, endgame, victory, death,
combat, inventory or stairs traversal**. No Python 3 gameplay port, fake pickle
compatibility layer or alternative save format was introduced.

The guarded external `make check-cutlassrl` consumer requires explicit
`CUTLASSRL_OUTPUT` (the canonical prebuilt store output), `CUTLASSRL_EVIDENCE`
(a fresh nonexistent absolute directory outside the store), and `GUIX` (the
Guix executable). For example:
`make check-cutlassrl CUTLASSRL_OUTPUT=/gnu/store/ydffy1pnvhw7r472r974z6yxj5l1jvzg-cutlassrl-0.05-0.304bb87 CUTLASSRL_EVIDENCE=/tmp/cutlass-fresh-proof GUIX=guix`.
It does not build CutlassRL and belongs outside the unguarded aggregate
`make check` dependencies; consumer-tool prerequisites are realized serially
before offline gameplay. Obsolete issue-672 marker-contract retirement does
not create a replacement acceptance contract or establish Goocastle execution.

This repository-only receipt changes no documented host/service and establishes
no material network-catalog correction, so no OKF page/log update applies. The
documentation worker ran no commands/checks and created no temporary files.

## CoreRL — ordinary native terminal gameplay (2026-10-09)

Local evidence covers the existing [`corerl`](guix/tay/packages/corerl.scm)
**1kib-20131024** package, compiled from Studio Tectorum's complete canonical
[`1kcore.c`](https://www.roguelikeeducation.org/vault/core/1kcore.c), not an
upstream binary or the earlier 4 KiB version. The source is **1023 bytes**,
SHA-256 **`05d55844b30fbfae72bd87ab9e26539cfb8232e540bc0d0ce50b04d6d1369e24`**,
Guix Nix-base32 **`094y6v8xc10bwl60vg20wlr85ywwack9xaw7pmraxgqgnd25im85`**.
This is native acceptance for an existing package, not a new inventory entry:
package counts and the canonical **629-source preservation ledger remain
unchanged**. **[Forgejo #311](https://forge.nogroup.group/tay/guix-channel/issues/311)
remains OPEN: literal clean own lint is unmet.** These local receipts do not
establish issue closure, signed channel publication, profile installation or
deployment.

| Gate | Main receipt |
| --- | --- |
| Source build | Main bg32 passed in **3.48 s**; artifact 15586 records `/gnu/store/zkvv04c1z2p1l4hr3p92s4vwg5dhnaki-corerl-1kib-20131024`. |
| Reproducibility | Main bg33 `--check` passed in **0.99 s**; artifact 15587 records the same output. |
| Full lint | Main bg34 completed in **6.75 s**: generic directory discovery returned **HTTP 403**, `updater 'generic-html' failed to find upstream releases`, and the source is not archived in Software Heritage with a missing Disarchive entry. These own findings leave the clean-own-lint gate unmet. |
| Ordinary native PTY consumer | Main bg36 passed in **4.47 s**; actual native proof and terminal-decoded screens are retained at `/tmp/corerl-native-2`. |
| Final integrated target | Main bg37 `make check-corerl` passed in **8.48 s**, emitting `CORERL_NATIVE_OK`; `/tmp/corerl-make-final` retains the final ordinary native consumer evidence. Runtime JSON parsing with `jq` passed in **0.01 s**. |

The failed release-discovery fetch is
`https://www.roguelikeeducation.org/vault/core/`, with **403 (Forbidden)**,
followed by
`corerl@1kib-20131024: updater 'generic-html' failed to find upstream releases`.
The pinned `1kcore.c` itself was fetched and built successfully. Generic
directory discovery and Software Heritage/Disarchive findings are separate
from those observed builds; build, reproducibility and gameplay do not waive
the literal clean-own-lint requirement. The unrelated `flex` deprecated-input
finding is not attributed to CoreRL.

The package compiles the unmodified source using GNU89 and Guix ncurses. There
is no upstream configure script or test target. Ordinary `bin/corerl` supplies
packaged terminfo and directly executes `libexec/corerl` in the player's
terminal, without changing the working directory. No downloaded binary,
runtime asset, updater or telemetry path is introduced. Install `corerl` and
run `corerl` in a terminal; use arrow keys to move and `q` to quit.

The guarded external consumer requires explicit `CORERL_OUTPUT` (a canonical
prebuilt `/gnu/store` package output), `CORERL_EVIDENCE` (a fresh nonexistent
absolute evidence directory outside the store) and `GUIX` (the Guix executable):
`make check-corerl CORERL_OUTPUT=/gnu/store/zkvv04c1z2p1l4hr3p92s4vwg5dhnaki-corerl-1kib-20131024 CORERL_EVIDENCE=/tmp/corerl-fresh-proof GUIX=guix`.
Do not reuse a retained evidence directory. This target is outside the
unguarded aggregate `make check` dependencies. Obsolete issue-668 and
issue-669 marker contracts are retired without a replacement acceptance
contract or any Goocastle execution claim.

### Observed native movement, enemy response and exit

The zero-argument ordinary launcher ran in an **80-column, 25-row PTY** with
`PATH` empty, `TERM=xterm`, `LC_ALL=C`, and fresh private HOME, XDG, temporary
and work directories. The native executable retained the same UID **1000** in
the consumer's user/mount/PID/network namespaces, with all three terminal
descriptors attached to the PTY. `/gnu/store` was read-only; only loopback and
no IPv4 routes were recorded. Retained evidence includes raw PTY bytes,
`pty-inputs.json`, decoded `.screen.txt`/`.screen.json` observations,
`runtime.json`, namespace/mount proof and before/after private-state
inventories—not PNG screenshots.

On the actual initial level-1 screen, zero-based **(x, y)** positions are
player `@` **(11, 7)**, enemy `e` **(7, 13)** and stairs `<` **(2, 13)**.
The tile immediately above the player is visible floor `.`. One ordinary
Up-arrow input (`1b4f41`) moved `@` to **(11, 6)**, vacating the original tile,
while `e` responded by moving to **(7, 12)**. The static walls and stairs
remain unchanged; both screens contain one player, one enemy and one stairs
glyph. This establishes one traversable player displacement and one native
enemy response, consistent with the source's row-first movement toward the
player. No enemy bump, combat, level advancement, victory or death was observed
or claimed. No RNG seed, retry, restart, synthetic argument or state injection
was used.

The final integrated run has its own random map, not the same coordinates:
`/tmp/corerl-make-final/initial.screen.txt` shows `@` **(10, 4)**, `e`
**(13, 5)** and `<` **(2, 13)**. Its one ordinary Up-arrow input moved the
player to **(10, 3)** and the enemy responded to **(13, 4)**, as captured in
`moved.screen.txt` and `runtime.json`; walls and stairs again remained
unchanged. It likewise recorded no enemy bump, RNG control or injected state.
The normal `q` input produced **“Quit on level 1.”**, exit status **0**, empty
private directories and the same unchanged output NAR hash below.

Pressing ordinary `q` follows the source's `endwin()`, message and `exit(0)`
path. The captured final screen displays **“Quit on level 1.”** and the process
exited normally with status **0**. Every fresh HOME/XDG/temp/work directory
remained empty, with matching before/after inventories. The package output's
before/after NAR hash also matches
**`0ysrg4zd378yh9q1235kni58q86hh2d5lcfhz83zin6hi5p7scpg`**. The complete source
has no save/restore or configuration interface; observed absence of writes is
not a save, resume or persistence claim.

### Public-domain grant and retained complete source

Studio Tectorum's [“coreRL in 1kib” article](https://www.roguelikeeducation.org/2.html),
dated **2013-10-24**, directly links the selected `1kcore.c` with the grant
**“This version of the source is also released into the public domain”**.
The article's footer identifies Studio Tectorum. That author's explicit grant,
not merely an absent copyright header, supports `license:public-domain`.
The complete unmodified **1023-byte** source is installed as
`share/doc/corerl/1kcore.c` with the SHA-256 above. Its companion
`share/doc/corerl/NOTICE` retains the source URL, author, article date and URL,
the exact grant and source hash: **572 bytes**, SHA-256
**`61d0bff934fbb5993b432fe3ad7a31e7cc6ad949d3ca7b29970e394408921f15`**,
recorded in `/tmp/corerl-native-2/upstream-files.json`. No upstream binary or
other asset is included. The article and installed source/notice were read
for this dated receipt; retained store source and native evidence were left
untouched.

This repository-only receipt changes no documented host or service and
establishes no material network-catalog correction, so no OKF page/log update
applies. The documentation worker ran no commands or checks and created no
temporary files.

## Dhack — ordinary native terminal gameplay (2026-10-09)

Local evidence covers the existing [`dhack`](guix/tay/packages/dhack.scm)
**0.2c** package, built from the complete canonical Google Code
[`dreamhack/source-archive.zip`](https://storage.googleapis.com/google-code-archive-source/v2/code.google.com/dreamhack/source-archive.zip).
The archive is at SVN revision **47**; the selected trunk's final code revision
is **45** (the later revisions change wiki files only). The pinned SHA-256 is
**`42c44d93343bb4b204ae08b3938c6718cfc3d5de48d7698d1705d8d9934ba9cc`**,
Guix Nix-base32 **`1k599f9xkn052y6nkms8vvaw7kqqcy697cq8mq2b5d1v6j9lvi22`**.
This is native acceptance for an existing package, not a new inventory entry:
package counts and the canonical **629-source preservation ledger remain
unchanged**. **[Forgejo #328](https://forge.nogroup.group/tay/guix-channel/issues/328)
remains OPEN: literal clean own lint is unmet.** Local build and gameplay
receipts do not establish issue closure, signed channel publication, profile
installation or deployment.

| Gate | Main receipt |
| --- | --- |
| Source build | Main bg25 passed in **6.17 s**; artifact 15547 records `/gnu/store/a4j6vbjywcpfsxkqidwglf134hm2w12b-dhack-0.2c`. |
| Reproducibility | Main bg26 `--check` passed in **2.82 s**; artifact 15549 records the same output. |
| Full lint | Main bg27 completed in **6.13 s**: Google Storage **HTTP 403** during generic release discovery, `updater 'generic-html' failed to find upstream releases`, and source not archived in Software Heritage with a missing Disarchive entry. These own findings leave the clean-own-lint gate unmet. |
| Ordinary native PTY consumer | Main bg30 passed in **5.63 s**; actual native proof and terminal-decoded screens are retained at `/tmp/dhack-native-3`. |
| Final integrated target | Main bg31 `make check-dhack` passed in **9.45 s**, emitting `DHACK_NATIVE_OK`; `/tmp/dhack-make-final` retains the final ordinary native consumer evidence. Contract JSON parsing with `jq` passed in **0.01 s**. |

The failed release-discovery fetch is
`https://storage.googleapis.com/google-code-archive-source/v2/code.google.com/dreamhack/`
with **403 (Forbidden)**, followed by
`dhack@0.2c: updater 'generic-html' failed to find upstream releases`.
The pinned archive itself was fetched and built successfully. Release discovery
and Software Heritage archival diagnostics do not invalidate those observed
builds, but successful build, reproducibility, native gameplay and the final
integrated target do not waive the literal clean-own-lint requirement.

The package compiles upstream's four C++ translation units (`main.cpp`,
`global.cpp`, `CGame.cpp`, `CEngine.cpp`) using C++14 and Guix ncurses. It does
not build the archive's old trunk, wiki material or prebuilt Windows executable.
There is no upstream test target. The rebuilt executable is private at
`libexec/dhack-real`; ordinary `bin/dhack` configures packaged terminfo and
directly executes it in the player's terminal, without changing the working
directory. No runtime assets, network download, updater or telemetry path is
introduced. The game offers **no save/load or resume interface**.

For ordinary play, install `dhack` and run `dhack` in a terminal. Space or Enter
dismisses the title and sleep prompt; enter a name at the native prompt and
acknowledge the dream introduction. Arrow keys or numeric directions move the
player, `i` opens native inventory and waits for an acknowledgement key, and
`q` quits without a confirmation prompt. The guarded acceptance target requires
explicit `DHACK_OUTPUT` (a prebuilt `/gnu/store` package output),
`DHACK_EVIDENCE` (a fresh nonexistent absolute evidence directory) and `GUIX`
(the Guix executable):
`make check-dhack DHACK_OUTPUT=/gnu/store/a4j6vbjywcpfsxkqidwglf134hm2w12b-dhack-0.2c DHACK_EVIDENCE=/tmp/dhack-fresh-proof GUIX=guix`.
Do not reuse a retained evidence directory. This external consumer is outside
the unguarded aggregate `make check` dependencies. The obsolete issue-673
`--smoke`/`DHACK_RUNTIME_OK` marker contract is retired, without a replacement
acceptance contract or any Goocastle execution claim.

### Observed native inventory, centered movement and exit

The zero-argument ordinary launcher ran with fresh private HOME, XDG and work
directories in user/mount/PID/network namespaces. Evidence records the real
`libexec/dhack-real` process with all three terminal descriptors attached to
the PTY, read-only `/gnu/store` mounts, and a network namespace with only
loopback and no IPv4 routes. Retained files include raw PTY bytes, input
records, decoded `.screen.txt`/`.screen.json` observations, namespace/mount
records, native proof and before/after private-state inventories—not PNG
screenshots.

The native name entered was **`NativeDream`**, shown in
**“You are feeling very sleepy, NativeDream... [press space]”**. The selected
upstream code uses this input only in that sleep message; it offers no class
selection and does not establish a persistent named character. After the
native introduction, the new-game screen shows **HP 100/100, XP 0/20**, a
visible room, and the player `@` at zero-based terminal **(20, 7)**. Pressing
`i` displayed the native **Inventory** heading; Space acknowledged it and
returned to the game. No pickup or inventory increase is asserted.

Movement evidence is the **player-centered viewport**, not a changed screen
coordinate for `@`. The consumer selected `6` from the actual visible floor
tile `.` immediately right of the player. `@` remained at **(20, 7)** while
static room landmarks shifted one column left: the top wall's leftmost `-`
moved **(17, 5) → (16, 5)**, the left door `+` moved
**(17, 8) → (16, 8)**, and the room boundary and visible object tiles shifted
consistently. Pressing `4` returned the room landmarks and decoded map to the
initial arrangement. Both movement screens retain **HP 100/100, XP 0/20**.
This correlates native directional input, a visible traversable target,
translated static landmarks and the return move; it makes no claim about
hidden state, RNG determinism, combat, victory or completion of the game.

Pressing ordinary `q` follows upstream's `m_On = false` path, with the final
native run/draw and `Exit()`/`endwin()`, without a quit acknowledgement prompt.
The process exited normally with status **0**. The fresh HOME/XDG/work tree
remained empty except for the same initial private directories: before/after
inventories are identical, with no save, score, configuration or other native
file created. Before/after package output NAR hashes also match
**`1agg3cmcipl91mjdhizpf0wnl93fccv0bcgq1nhy2nib8xagk4qi`**. These are
observations of no filesystem mutation in this run, not a persistence or
save/resume claim.

### Selected trunk licensing and retained notice

The selected trunk's `main.cpp` retains Bryan Strait's **2008** copyright and
explicit **GPL-2.0-or-later** grant (version 2 or any later version), compatible
with the trunk's supplied GPLv3 `COPYING` and the package's GPL-3.0-or-later
license selection. The installed `share/doc/dhack/COPYING` is the complete
upstream **GNU GPL version 3, 29 June 2007**, not a summary or reconstructed
notice: **35,147 bytes**, SHA-256
**`8ceb4b9ee5adedde47b31e975c1d90c73ad27b6b165a1dcd80c7c545eb65b903`**,
recorded in `/tmp/dhack-native-3/upstream-notices.json`. The immutable source
archive retains the source header and historical material; the installed
program and notice come only from the selected trunk.

This repository-only receipt changes no documented host or service and
establishes no material network-catalog correction, so no OKF page/log update
applies. The documentation worker ran no commands or checks, created no
temporary files, and left retained native evidence and the immutable source
archive untouched.

## CryptRover — ordinary native terminal gameplay (2026-10-09)

Local evidence covers the existing [`cryptrover`](guix/tay/packages/cryptrover.scm)
**1.1** package, built from the canonical Google Code release
[`cryptrover_1.1_nosound.tar.gz`](https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/cryptrover/cryptrover_1.1_nosound.tar.gz).
The fixed archive SHA-256 is
**`4c8fdb89c21e3302b81afcb7fb974e02533685c461a1e395e869c58e1ea51494`**,
Guix Nix-base32 **`150lllg8xib9x2ay78b1qj2kclq29sbzpdzw3aw04cqyqa4xp3sc`**.
Upstream's archived release listing describes this exact file as “Cryptrover
1.1 source without sound.” This is native acceptance work for an existing
`PROJECT_PACKAGES` member, not a new inventory entry: package counts and the
canonical **629-source preservation ledger remain unchanged**.
**[Forgejo #318](https://forge.nogroup.group/tay/guix-channel/issues/318) remains
OPEN: literal clean own lint is unmet.** These local receipts do not establish
issue closure, signed channel publication, profile installation or deployment.

| Gate | Main receipt |
| --- | --- |
| Source build | Main bg16 passed in **3.84 s**; artifact 15506 records `/gnu/store/8clz772fxmrmyz06yg4czz4yhcv4ms9m-cryptrover-1.1`. |
| Reproducibility | Main bg17 `--check` passed in **1.27 s**; artifact 15507 records the same output. |
| Full lint | Final Main bg21 completed in **4.25 s**. CryptRover's generic HTML release updater cannot fetch the Google Storage directory listing (**HTTP 403**), so its own failed-release finding remains. The canonical archive homepage correction removed the earlier homepage finding; the only other diagnostic is unrelated deprecated Flex usage. This does **not** pass the clean-own-lint gate. |
| Ordinary native PTY consumer | Main bg20 passed in **6.43 s**; actual proof and terminal-decoded screens are retained at `/tmp/cryptrover-native-2`. |
| Final integrated target | Main bg22 `make check-cryptrover` passed in **10.81 s**, emitting `CRYPTROVER_NATIVE_OK`; `/tmp/cryptrover-make-final` records the same ordinary launcher/resource/score/exit behavior against the same immutable output. Contract JSON parsing also passed. |

The remaining own diagnostic is exactly
`cryptrover@1.1: updater 'generic-html' failed to find upstream releases`,
preceded by the failed fetch of
`https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/cryptrover/`
with **403 (Forbidden)**. This is a release-discovery failure, not a failure to
fetch the pinned no-sound source archive used by the successful build.

The final homepage-only metadata correction does not change the built
derivation. Successful build, reproducibility and real native gameplay do not
waive the archive updater lint failure. The package builds the seven original
C files using GCC and `make CC=gcc SDL=0`, linked to Guix ncurses/panel and libm.
It removes the archive's opaque prebuilt `cr`; it never executes upstream's
network-fetching `configure` bootstrap. The ncurses panel cleanup fix destroys
each panel before its window, enabling ordinary dismissal of native help and
highscore panels. There is no upstream test target.

The rebuilt executable is private at `libexec/cryptrover`. The ordinary
`bin/cryptrover` launcher supplies ncurses terminfo, creates and enters
`${XDG_STATE_HOME:-$HOME/.local/state}/cryptrover`, and directly runs the native
game in the player's terminal. Only native `scores.dat` user state is written
there; it is **not a saved game or a resume format**. No `--smoke` adapter,
Goocastle execution or replacement acceptance contract is claimed. The obsolete
marker contract is retired, and the guarded external consumer is intentionally
outside the unguarded aggregate `make check` dependencies.

For ordinary play, install `cryptrover` and run `cryptrover` in a terminal:
Space dismisses help, `?` reopens it, movement uses wasd/vi/numpad keys, `f`
toggles the flashlight, and Escape follows the native loss/highscore exit path.
The external acceptance target requires explicit `CRYPTROVER_OUTPUT` (a
prebuilt `/gnu/store` package output), `CRYPTROVER_EVIDENCE` (a fresh nonexistent
absolute evidence directory) and `GUIX` (the Guix executable):
`make check-cryptrover CRYPTROVER_OUTPUT=/gnu/store/8clz772fxmrmyz06yg4czz4yhcv4ms9m-cryptrover-1.1 CRYPTROVER_EVIDENCE=/tmp/cryptrover-fresh-proof GUIX=guix`.
Do not reuse a retained evidence directory for another run.

### Observed native turns and highscore correlation

The zero-argument launcher was exercised in fresh private HOME and XDG
directories inside user/mount/PID/network namespaces. The game executable and
all three terminal descriptors were observed directly; `/gnu/store` was
read-only, and the network namespace had only loopback and no IPv4 routes.
Evidence consists of raw PTY bytes, the exact input sequence, terminal-decoded
`.screen.txt`/`.screen.json` observations, parsed native proof, namespace/mount
records and before/after private-state inventories—not PNG screenshots.

In `/tmp/cryptrover-native-2`, the native startup help was dismissed with Space,
reopened with `?`, then dismissed normally. On the **48×24** dungeon map, the
player `@` began at zero-based **(21, 7)** with HP/Air/Battery **100/100/100**,
zero gold and level **1/12**. The consumer selected `w` from the actual visible
floor tile `.` above the player; the next native screen moved `@` to **(21, 6)**,
with HP unchanged and Air/Battery **99/99**. Pressing `f` turned the flashlight
off: Air became **98**, while Battery stayed **99**. Pressing `f` again restored
it: Air became **97**, Battery **98**, and the player position remained fixed.
Thus observed turns show air consumption, battery conservation while the light
is off, and battery drain while it is on. HP **100**, zero gold and level **1**
remained unchanged; these observations do not claim combat, pickups or victory.

Ordinary Escape invoked upstream's **“YOU HAVE LOST! :(”** quit path. Space
acknowledged the loss, the native highscore panel displayed
`Gold: 0    Level: 1  HP:100%  Air: 97%  Battery: 98%`, and another Space closed
the panel with process exit status **0**. The real 53-byte
`state/cryptrover/scores.dat` contains precisely that same record, with SHA-256
**`2834b5587643203d9e14b731e8c9aed2bee283c5f9df4ef0ab60d3b69c3a0efa`**;
it was created by the game, not seeded by the consumer. It correlates the final
HUD, native highscore screen and XDG file. Before/after output NAR hashes match
**`0zh18zcb47y8m97mwas5i30z578nvaz9vfsrqpv2i37f3psylq56`**, with read-only
store mounts and no output mutation. The integrated run's randomized dungeon
instead moved **(33, 8) → (33, 7)**, independently recording the same resource
transitions, genuine score record and normal exit. No save/resume or completed
twelve-level run is asserted.

### Selected release licensing and retained notices

The reviewed archive contains **GPL-3.0-or-later** grants in
`src/main.c`, `src/entities.c`, `src/io.c`, `src/items.c`, `src/map.c` and
`src/utils.c`: each explicitly permits version 3 or any later version.
`src/mdport.c` separately carries Nicholas J. Kisseberth's complete **2005
BSD-3-Clause** notice, including all three conditions and the full disclaimer.
The package's license list is therefore GPL-3.0-or-later plus BSD-3-Clause.
The bundled unused `lib/curses.h` and `lib/panel.h` identify PDCurses as public
domain; the normal Linux build uses Guix ncurses instead and does not install
those headers. The complete upstream GPLv3 `COPYING`, original `README`, and
the complete `mdport.c` BSD notice copied to `BSD-3-Clause.txt` are installed in
`share/doc/cryptrover`. Native evidence records their bytes and hashes in
`upstream-notices.json`.

The selected **upstream no-sound release itself contains no media, audio or
asset/data directory**: its root consists of `config`, `configure`, `COPYING`,
`cr`, `Makefile`, `README`, `lib/` and `src/`. Guix did not strip media from
this release; it deleted only the prebuilt executable. No missing-media grant,
sound capability, externally downloaded runtime assets or proprietary content
is implied. This repository-only package receipt changes no documented host
or service and establishes no material network-catalog correction, so no OKF
page/log update applies. The documentation worker ran no commands or checks
and created no temporary files.

## Grippy Socks — ordinary native console gameplay (2026-10-09)

Local evidence covers the existing [`grippy-socks`](guix/tay/packages/grippy-socks.scm)
**3.5** package, built from CruiserOne/Daedalus commit
**`32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8`**, recursive Guix source hash
**`0fdzx2zzqbd3p99yljksmbh0s3mbzzmq2dq42a9yz5rfkn9gjy2r`**.
The pinned upstream README identifies the official **2024-10-31** Daedalus 3.5
release copied from `dae35zip.zip`; this receipt does not claim a newer release
survey. Grippy Socks is the distinct original `gripsox.ds` script, not the
Hunger Games or Dragonslayer sibling game. This accepts an existing
`PROJECT_PACKAGES` member: **no inventory count increases**, and the canonical
**629-source preservation ledger remains unchanged**.
**#383 is verified CLOSED on [Forgejo](https://forge.nogroup.group/tay/guix-channel/issues/383#issuecomment-3256)
and [GitHub](https://github.com/htayj/guix-channel/issues/383#issuecomment-6086865578), with matching complete acceptance comments and signed/authenticated implementation [`a770727680da9d7fc32ee376092c5214d8bdea59`](https://forge.nogroup.group/tay/guix-channel/commit/a770727680da9d7fc32ee376092c5214d8bdea59) published to origin/master.** Local acceptance is not evidence
of publication, profile installation or system deployment. Historical #689's
marker-style contract is not ordinary native gameplay evidence.

| Gate | Main receipt |
| --- | --- |
| Source build | Main bg38 passed in **13.81 s**; artifact 15624 records `/gnu/store/laly01jn760vn5w7ld9553am5s9msspg-grippy-socks-3.5`. |
| Reproducibility | Main bg39 `--check` passed in **11.08 s**; artifact 15625 records the same output. |
| Full lint | Main bg40 passed in **6.00 s**, with **no Grippy Socks finding**. The sole diagnostic is unrelated deprecated Flex usage. |
| Ordinary native PTY consumer | Main bg41 passed in **2.27 s**; actual evidence is retained at `/tmp/grippy-native-1`. |
| Final integrated target | Main bg42 `make check-grippy-socks` passed in **6.06 s** at `/tmp/grippy-make-final`, emitting `GRIPPY_SOCKS_NATIVE_OK`. Its actual raw transcript and result record the same six ordinary rest actions, native wellness **3 → 1**, crisis consequence and normal zero-status exit against the same output. Main's JSON validation passed in **0.01 s**. |

The recipe builds upstream's Unix `make daedalus` target with GCC, installs the
source-built engine privately at `libexec/grippy-socks-real`, and installs only
the unchanged `gripsox.ds` as game data. Upstream has **no test target**; native
acceptance is a separate external consumer, not a skipped upstream suite
replaced by a marker. GCC/patchelf are native build inputs, Bash/coreutils are
launcher dependencies, and no registry dependency closure or opaque Windows
executable is used. The source origin fetches the pinned checkout; the build
and ordinary runtime require no additional downloads.

The ordinary zero-argument `grippy-socks` launcher creates
`${XDG_STATE_HOME:-$HOME/.local/state}/grippy-socks` with a private umask, links
the immutable script there, and execs the engine with this exact native string:

```text
OpenScript 'gripsox.ds' fNoExit 1 fSkipMessageDisplay 0
```

`OpenScript` loads the original script; the grammar requires separate value
tokens, not equals assignments. `fNoExit 1` keeps the ordinary command prompt
alive, and `fSkipMessageDisplay 0` permits native `Message` dialogs. These are
documented lifecycle/display settings only. No seed, wellness, clock,
coordinates, medication, patient state or other gameplay variable is forced.
There is no public `--smoke` interface or embedded/patched engine in this proof.

At `Enter Command Line:`, the retained `pty-inputs.json` records exactly **six**
ordinary `Macro7` commands followed by `fNoExit 0 Exit`. Upstream's
[F1–F7 command table](https://github.com/CruiserOne/Daedalus/blob/32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8/command.cpp#L286-L292)
and [native macro dispatch](https://github.com/CruiserOne/Daedalus/blob/32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8/command.cpp#L5982-L5996)
map `Macro7` to the script's user-facing F7 rest action, described in
[the original help](https://github.com/CruiserOne/Daedalus/blob/32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8/gripsox.ds#L52-L56)
as “Rest for an hour.” The
[rest implementation](https://github.com/CruiserOne/Daedalus/blob/32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8/gripsox.ds#L121-L129)
runs up to 60 native `Wait` steps, bounded at the next day evaluation. The first
five rest commands emitted no ordinary dialog; the sixth emitted this actual
game consequence in `terminal.raw` and `rest-6.console.txt`:

```text
Daedalus: You made it through another day on the psych ward! Here's a summary of your actions the previous day:

Negative: Didn't eat anything all day. [-1]
Negative: Never showered. [-1]
Negative: Skipped all daily therapy groups.
Negative: Didn't check in with your psychiatrist.

As a result of your actions yesterday, your wellness level has decreased from 3 to 1. :-(

Your wellness has fallen enough that you are in crisis! For your safety you have been placed on a one-on-one continual observation. :-(
```

This is the native game's reported wellness transition **3 → 1** and
**one-on-one continual observation** consequence, not an injected expected
message, hidden-state query, visible HUD reading or victory. The source path is
[initial wellness](https://github.com/CruiserOne/Daedalus/blob/32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8/gripsox.ds#L58-L81),
[Wait/day evaluation](https://github.com/CruiserOne/Daedalus/blob/32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8/gripsox.ds#L184-L246)
and [wellness adjustment](https://github.com/CruiserOne/Daedalus/blob/32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8/gripsox.ds#L249-L264).
`daily-consequence.json` records all six observed responses. The session ended
normally with `fNoExit 0 Exit`, **status 0**, without EOF or signals. The exit
command changes only console lifecycle, not a game outcome.

**Unix console boundary:** this is a native command-line simulation, not the
graphical inside view or a full-screen terminal map. Upstream's
[console graphics callback](https://github.com/CruiserOne/Daedalus/blob/32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8/daedalus.cpp#L3224-L3229)
and [operation callback](https://github.com/CruiserOne/Daedalus/blob/32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8/daedalus.cpp#L3341-L3343)
are no-ops. The script's
[inside-view event](https://github.com/CruiserOne/Daedalus/blob/32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8/gripsox.ds#L142-L164)
computes clock presentation and sends the status line and interaction text to
`MessageInside`; those are **not displayed** by this Unix frontend. The nominal
F7 help label does not establish a displayed six-hour clock transition. Ordinary
`Message` output, including the evaluated day summary, is available. No
graphical UI, player coordinates, displayed status line, save/restore
continuity, hospital discharge, victory or complete game acceptance is claimed.

The external consumer and actual game ran as caller UID **1000**, GID **998**
in private user, mount, network and PID/proc namespaces. The network contained
only loopback with no external routes; `/gnu/store` was recursively read-only.
`game-entry.json` records all standard descriptors on **`/dev/pts/50`**, the
exact ordinary engine arguments, fresh private HOME/XDG/TMPDIR and empty `PATH`.
Before/after output NAR hashes both equal
**`0vvywyncwjv9d493d9g0ip5j3wf85v9nj62fmgh8fxygihkxa7ss`**.
The final footprint contains only private directories and the immutable
`state/grippy-socks/gripsox.ds` symlink. This establishes state isolation and
unchanged output, **not a savegame**; no save file was created or tested.

**Rights, embedded assets and notices:** Walter D. Pullen's complete original
author grant and warranty disclaimer state **GPL-2.0-or-later**. Full original
`README.md`, `license.htm` (GPLv2), `changes.htm`, `changes.doc`, `daedalus.htm`,
`daedalus.doc`, `script.htm` and `script.doc` are installed under
`share/doc/grippy-socks`; `NOTICE` preserves the complete author grant and
disclaimer from `util.h` and adds the dated **2026-10-09** packaging notice.
`util.h` carries dated Unix-selection and LP64 32-bit bitmap-word changes;
`util.cpp` carries the sized-delete ABI adaptation. Runpath shrinking avoids
retaining the build toolchain. None rewrites gameplay or the script.
The script itself carries Pullen's attribution and contains its original
[procedural textures](https://github.com/CruiserOne/Daedalus/blob/32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8/gripsox.ds#L1090-L1368)
and [embedded bitmap data](https://github.com/CruiserOne/Daedalus/blob/32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8/gripsox.ds#L1370-L1419).
No separate external bitmap or asset download is required. `upstream-files.json`
records the complete pinned documentation and **82,848-byte** unchanged script,
SHA-256 **`37b06691d67261c16e8de1504fe70506a57d9e8a2fc6eef2dbc13c31fc6928b7`**.
These retain the original rights and asset source, not abbreviated licenses or
replacement content.

The external consumer is [tests/grippy-socks-smoke.sh](tests/grippy-socks-smoke.sh)
with [tests/grippy-socks-native.py](tests/grippy-socks-native.py). The explicit
`make check-grippy-socks` target requires `GRIPPY_SOCKS_OUTPUT` (prebuilt store
output), `GRIPPY_SOCKS_EVIDENCE` (fresh nonexistent absolute evidence directory)
and `GUIX` (Guix executable); it does not build implicitly or belong to the
aggregate check. This documentation worker ran no commands or checks and
created no temporary files. No host/service changed or material network-catalog
correction was established, so no OKF page/log update applies to this
repository-only receipt.


## Hunger Games — ordinary native console gameplay (2026-10-09)

Local evidence covers the existing [`hunger-games`](guix/tay/packages/hunger-games.scm)
**3.5** package, source-built from CruiserOne/Daedalus commit
**`32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8`**, recursive Guix source hash
**`0fdzx2zzqbd3p99yljksmbh0s3mbzzmq2dq42a9yz5rfkn9gjy2r`**.
This is acceptance work for an existing `PROJECT_PACKAGES` member, not a new
inventory entry: no inventory count increases, and the canonical **629-source
preservation ledger remains unchanged**. **#397 is verified CLOSED on
[Forgejo](https://forge.nogroup.group/tay/guix-channel/issues/397#issuecomment-3248)
and [GitHub](https://github.com/htayj/guix-channel/issues/397#issuecomment-6085147907)**,
with matching complete acceptance comments; GitHub records completion. Implementation
[`68aa5d0e06ce8d22cba5577b658c671c309cb824`](https://forge.nogroup.group/tay/guix-channel/commit/68aa5d0e06ce8d22cba5577b658c671c309cb824)
was signed, Guix-authenticated and normally pushed to origin/master; remote
HEAD/master matched the exact OID, and Forgejo reported its signature verified.
Historical #695 is not current native acceptance. This receipt does not establish
profile installation or system deployment.

The authoritative [issue #397](https://forge.nogroup.group/tay/guix-channel/issues/397)
asks for meaningful native gameplay **or** save/load behavior in fresh HOME/XDG,
with no store writes. The Food/status transition and immutable-output proof
below satisfy the gameplay branch only. Its
[2026-09-08 research comment](https://forge.nogroup.group/tay/guix-channel/issues/397#issuecomment-1690)
identified canonical tag `v3.5` and this same commit/hash, with no submodules or
registry closure. The installed upstream README identifies the official
**2024-10-31** release copied from `dae35zip.zip`; this receipt does not assert a
newer release survey. Dragonslayer and Grippy Socks are distinct sibling scripts
at that revision, not separate Hunger Games code or dependencies. The old
comment's proposed `--smoke` marker and Goocastle screenshot were research-era
contracts, **not** evidence of this ordinary native session. The current public
launcher takes no arguments; no `--smoke` adapter, marker-only proof or Goocastle
execution is part of this acceptance.

| Gate | Main receipt |
| --- | --- |
| Source build | Main bg8 passed in **12.69 s**; artifact 15454 records `/gnu/store/nh3ydvi6r7634zllaa29w8ha61zfh2sp-hunger-games-3.5`. |
| Reproducibility | Main bg10 `--check` passed in **10.44 s**; artifact 15459 records the same output. |
| Full lint | Main bg12 passed in **5.64 s**, with **no Hunger Games finding**. The sole diagnostic is unrelated deprecated Flex usage. The final description-only map-legend correction does not change the derivation. |
| Ordinary native PTY consumer | Main bg9 passed in **2.70 s**; actual evidence is retained at `/tmp/hunger-native-3`. Earlier failed command-grammar attempts are not accepted evidence. |
| Final integrated target | Main bg13 `make check-hunger-games` passed in **7.36 s** at `/tmp/hunger-make-final`, emitting `HUNGER_GAMES_NATIVE_OK`; the actual proof records the same ordinary command/status/export/exit behavior against the same immutable output. |

The package uses upstream's Unix `make daedalus` target and the GCC toolchain;
it does not fetch a prebuilt game executable. The native executable is private
at `libexec/hunger-games-real`. Installed runtime data consists of the original
`hunger.ds` and `hunger.bmp`; opaque Windows executables and audio are excluded.
The ordinary zero-argument launcher creates
`${XDG_STATE_HOME:-$HOME/.local/state}/hunger-games`, links those immutable assets
there and execs the native engine. Relative user exports go into that directory,
not the installed output.
The fixed upstream Makefile has only build/clean targets and **no test target**;
no upstream test suite is silently skipped in favor of a marker. The recipe's
GCC toolchain is a native input; Bash/coreutils are launcher dependencies from
Guix, not new bundled asset grants or registry downloads.

The exact engine command-line string is
`OpenScript 'hunger.ds' fNoExit 1 fSkipMessageDisplay 0`.
`OpenScript` explicitly loads the unmodified script; the native grammar takes
each setting's value as a separate token, **not** an equals assignment.
`fNoExit 1` is the documented console-prompt lifecycle setting, and
`fSkipMessageDisplay 0` enables the documented presentation of messages that
the GUI-oriented script otherwise suppresses. These are lifecycle/display
settings only: no seed, tribute selection, arena, food, health or other gameplay
parameters are forced. The observed session ended with `fNoExit 0 Exit`, status
**0**, without EOF or signal termination.

Run `hunger-games` and enter native commands at `Enter Command Line:`:

```text
*FHelp
*FTable
MoveForward
*FTable
*FMap
SaveBitmap "arena.bmp"
fNoExit 0 Exit
```

The retained `terminal.raw` and `pty-inputs.json` show real user commands through
one genuine PTY, not an embedded engine, patched test interface or direct state
inspection. `*FHelp` identified the player as **District 9 Female**; `*FTable`
reported that same **D9 Female** row at health **10**, Food **500**, kills **0**.
After ordinary `MoveForward`, Food became **499**, with health and kills
unchanged, and other tribute rows also changed. A status observation between
the first `*FMap`/export and movement still showed Food **500**; the second
map/export left the post-movement Food **499** intact. This is native
player-correlated gameplay/status evidence, not a player-coordinate claim.
The source path is [engine movement](https://github.com/CruiserOne/Daedalus/blob/32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8/command.cpp#L4433-L4444)
through [the script's movement event](https://github.com/CruiserOne/Daedalus/blob/32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8/hunger.ds#L1358-L1387)
and [Food consumption](https://github.com/CruiserOne/Daedalus/blob/32af46ddf22e53c9bfd7bd7eacca1e249c60a5e8/hunger.ds#L1880-L1885).

**Display/export boundary:** `*FMap` prints the native arena-map legend
(Gold: Cornucopia; Gray/maroon: mountains/walls; Dark cyan: water; Other:
tributes). The Unix frontend does **not** display a graphical arena or a
full-screen terminal map; its graphical callbacks are no-ops. Native
`SaveBitmap` exports the active arena after `FMap` restores it, not the tinted
map, a savegame or player-coordinate proof. The retained raw
`arena-before.bmp` and `arena-after.bmp` are each **200 × 200**, uncompressed
**24-bit** BMPs of **120,054 bytes**, with **2,777** distinct colors. Their SHA-256
hashes are respectively
`1f891a8307f935880e72a480a2a67c307a5731ce53a8862a474f9fe78fb8584d` and
`a76b96799a43ef89377c7e76c02523b202f4529087c3f95e71fa57ab2b9bdb7d`.
Changed exported pixels corroborate changing native arena state but do not
locate the player. No graphical-UI, save/restore continuity, completed match or
Windows/audio acceptance is claimed.

The installed consumer and native game ran as the caller's UID **1000** and GID
**998** in private user, mount, network and PID/proc namespaces. The network had
only loopback and no external routes; `/gnu/store` was recursively read-only.
`game-entry.json` records all three standard descriptors on `/dev/pts/49`, the
exact ordinary launcher arguments and private HOME/XDG/TMPDIR paths with an
empty `PATH`. Before/after output NAR hashes both equal
**`1bl0vxpf03qa33p0padkcd577p6fay4y8ffvsifi8s4q4fw5pann`**.
The state footprint contains only the private directories, two immutable asset
symlinks and the requested arena exports; this establishes export isolation,
not a savegame format.

**Rights and modifications:** the package records **GPL-2.0-or-later**, matching
Walter D. Pullen's explicit grant and warranty disclaimer in upstream
`changes.htm` and `daedalus.htm`. Complete original `README.md`, `license.htm`
(the GPLv2 text), `changes.htm`, `changes.doc`, `daedalus.htm`, `daedalus.doc`,
`script.htm` and `script.doc` are installed under `share/doc/hunger-games`.
`upstream-files.json` verifies their complete pinned bytes plus the original
script/bitmap bytes, including the script's author attribution; no abbreviated
license or rewritten upstream notices substitute for them. The build recipe
adds dated **2026-10-09** modified-source notices to `util.h` for Unix selection
and 32-bit bitmap words on LP64, and to `util.cpp` for the sized-delete ABI
adaptation. These are engine portability changes, not gameplay rewrites; the
installed script and bitmap remain byte-identical to the pinned originals.

The external consumer is [tests/hunger-games-smoke.sh](tests/hunger-games-smoke.sh)
with [tests/hunger-games-native.py](tests/hunger-games-native.py); the integrated
entry point is `make check-hunger-games`, requiring a prebuilt store output,
fresh absolute evidence directory and explicit `GUIX` executable. This
documentation worker ran no checks and created no temporary files. No host or
service changed and no network-catalog correction was established, so no OKF
page/log update applies to this repository-only receipt.

## Gruesome — ordinary native terminal gameplay (2026-10-07)

Local evidence covers the existing [`gruesome`](guix/tay/packages/gruesome.scm)
**0.0.3** package, built from the official
[`gruesome0.0.3.zip`](http://www.gamesofgrey.com/games/gruesome/gruesome0.0.3.zip),
base32 **`1w482gxkvh8ln3d9hyyq7b9akhzr3s3mi6d37a4s79jlb7afxm1g`**.
This is native acceptance of an existing inventory member, not a new package;
no inventory count increases and the canonical **629-source preservation
ledger remains unchanged**. **Forgejo #384 remains OPEN:** the literal
clean-own-lint archive gate is unmet. These receipts do not establish signed
publication, issue closure, profile installation or system deployment.

| Gate | Main receipt |
| --- | --- |
| Source build | Main491 passed in **7.88 s**; artifact 15355 records `/gnu/store/wsbvbgwl89276ndi3mzn98wdg847x4ci-gruesome-0.0.3`. |
| Reproducibility | Main493 `--check` passed in **1.32 s**; artifact 15357 records the same output. |
| Lint — archive gate pending | Main494 ran in **8.42 s**; the package's own source is not archived in Software Heritage and lacks a Disarchive entry. These findings remain unresolved; no archive diagnostic is suppressed. The canonical release regexp now finds upstream and there is no own updater finding. An unrelated Flex diagnostic is not a Gruesome finding. |
| Ordinary native PTY consumer | Main497 passed in **6.42 s**, with actual evidence at `/tmp/gruesome-native-4`. |
| Final integrated target | Main498 `make check-gruesome` passed in **11.42 s** at `/tmp/gruesome-make-final`, emitting `GRUESOME_NATIVE_OK`. |

### Original source and installed notices

Free Pascal **3.2.2** compiles the complete, unpatched **1,902-line** upstream
`source.pas` using `-O2 -g- -FUbuild/units -FEbuild
-obuild/gruesome-real source.pas`. The only imported Pascal unit is standard
**CRT**. No prebuilt Windows executable is installed. The normal
`bin/gruesome` launcher is a Bash `set -eu` / `exec` of
`libexec/gruesome-real`, forwarding arguments directly; the synthetic installed
`--smoke` branch and its Expect dependency have been removed. The proof starts
this launcher with **no arguments**, not a special test entry point.

Installed `share/doc/gruesome/{source.pas,license.txt,readme.txt,history.txt}`
preserves the **complete byte-identical upstream files**, including Darren
Grey's 2009 attribution, source notice and full GNU GPL version 3 text through
`END OF TERMS AND CONDITIONS`, with warranty/liability disclaimers intact.
The source header refers to `license.txt` without specifying a version; the
package retains **GPL-3.0-or-later** metadata. Native evidence
`upstream-files.json` records byte lengths **65,695 / 33,077 / 1,096 / 4,199**
and SHA-256 identities for those four files. The complete upstream program is
installed as source, while the exact build/install/launcher-control recipe is
the tracked [`gruesome.scm`](guix/tay/packages/gruesome.scm); that recipe is
**not installed** in the output. Both source and recipe are needed when
providing corresponding source for this channel build; the license text alone
is not corresponding source. No game source changes require downstream
modification notices.

Both build receipts retain Free Pascal's actual warnings that **`lurkcount`,
`retreatcount` and `shadowturns` do not seem to be initialized**, plus unused
local-variable notes for `q`, `r` and `j`. They are uncorrected upstream
compiler diagnostics, not observed runtime errors in the bounded native run;
successful compilation and one turn do not prove the affected paths safe.

### Observed ordinary gameplay and limits

The external consumer supplies an **80 × 25 PTY**, fresh private HOME/XDG,
temporary and working directories, **UID 1000/GID 998**, separate user/mount/
network/PID namespaces, loopback-only networking and recursively read-only
`/gnu/store`. It uses `TERM=xterm`, `LC_ALL=C` and an empty game `PATH`.
This isolation belongs to the harness, not the game. Inputs are real terminal
bytes: `NativeGrue` plus Return, Space to start, **`l`** for east movement,
**`Q`** to quit and Space for the upstream final `ReadKey` acknowledgement.
No RNG seed/control, game-memory access or expected-state injection is used.

In Main497, natural birth produced a **nonblank cave map**, the message
`It is pitch black.  You are likely to eat someone.`, and the named HUD
**LP 2/2, SP 2/2, Meals 0, Turns 0, D 20**. One ordinary `l` moved the
source-defined player cursor from **(12, 7) to (13, 7)** in one-based terminal
coordinates, redrew the map and advanced **Turns 0 → 1**, with LP, SP, Meals
and depth unchanged. The final integrated Main498 run independently observed
the same HUD change and east movement from **(16, 19) to (17, 19)**. Decoded
screen JSON stores these cursors zero-based. This is **not an `@`-glyph
claim**: upstream `DrawTile` draws the grue as a black-on-black space and
`GoToXY(gruex,gruey)` / `cursoron` identifies its position. The text/JSON
terminal captures and raw terminal bytes are actual observations, not graphical
screenshots or reconstructed game state.

Normal `Q` revealed the map and displayed **`Till next lurking....`**; Space
acknowledged the final prompt and the game exited **0**. Both runs recorded
**no private filesystem-state entries** and identical pre/post output NAR
hash **`1xci6bnklyqmpy6vyrxs6pzd5mriixfx5pjjdq067bpvdcsjniz7`**. The upstream
CRT-only program has **no save/load API or persistent-state implementation**;
history lists high-score/configuration files only as future targets. This is
one movement/turn and clean-quit proof, **not** save continuity, combat, spell,
stairs, death or victory acceptance.

The standalone guarded developer target requires a prebuilt store item and a
fresh, nonexistent absolute evidence directory, and honors `GUIX`:

```sh
make check-gruesome GUIX=/path/to/guix \
  GRUESOME_OUTPUT=/gnu/store/wsbvbgwl89276ndi3mzn98wdg847x4ci-gruesome-0.0.3 \
  GRUESOME_EVIDENCE=/tmp/gruesome-new-evidence
```

The consumer realizes its Guix tooling serially before offline gameplay; it
does **not build Gruesome**. The guarded target is outside the unguarded
aggregate `check`, and the obsolete Goocastle installed-`--smoke` contract is
removed rather than treated as proof. No described host/service changed and
no material OKF correction was established, so no OKF page/log update applies.
This documentation worker ran no commands, applications or checks; verification
above is Main's exercised evidence.

## Imago — six-system image library and native consumer

Local evidence on **2026-10-07** covers [`sbcl-imago`](guix/tay/packages/imago.scm)
**0.11.0**, built from the original [`tokenrove/imago`](https://github.com/tokenrove/imago/tree/b1f50c1192f78dacbaaf60923d341f7c2ee38e92)
commit **`b1f50c1192f78dacbaaf60923d341f7c2ee38e92`**, reusing the existing
`tokenrove-imago-source` origin with base32
**`1jd796grp4aa8vyjp29pjk9im89yfahqnjhkv5jninqblrivzkh6`**. The pristine
snapshot's pin, hash and canonical **629-source ledger** remain unchanged.
**Forgejo #220 remains OPEN: literal clean lint is unmet.** Successful build,
reproducibility and native API evidence do not waive that gate, establish issue
closure or prove signed publication, profile installation or deployment.

### Licensing and delivered systems

The code grant is the **Lisp Lesser GNU Public License (LLGPL)**, not a guessed
blanket license for the repository. `imago.asd` explicitly grants distribution
and use under LLGPL, as do source notices such as `src/image.lisp`; the notebook
method file does not itself carry a license header. The source snapshot retains
mixed assets: upstream documentation and test images have **no repository
license grant**, so snapshot metadata remains `(llgpl no-permission)`, not an
all-FOSS claim. The build runs the original suite with those fixtures available,
then removes installed `docs/` and every non-Lisp test fixture. This does not
delete or relicense the preservation snapshot. The external consumer uses only
caller-created synthetic images, not upstream sample assets.

The realized output is
**`/gnu/store/xvznhm3jgz808mbbzwffmnzywzcna5yq-sbcl-imago-0.11.0`**.
It delivers source, compiled SBCL FASLs and ASDF source/output configuration for
all **six** systems: `imago`, `imago/bit-io`, `imago/jpeg-turbo`, `imago/libheif`,
`imago/libtiff` and `imago/jupyter`. The test system is built for checking, not
installed as another consumer system. The library supports PNG, classic and
turbo JPEG, HEIF/HEIC, TIFF, PNM and TGA; this is not six separate applications.

### Dependency and runtime root-cause repairs

[`imago-dependencies.scm`](guix/tay/packages/imago-dependencies.scm) defines
five public SBCL dependency recipes: `sbcl-zlib`, `sbcl-cl-jpeg-imago`,
`sbcl-common-lisp-jupyter-imago`, `sbcl-cl-libheif` and `sbcl-cl-libtiff`.
The separate `libtiff/cl-libtiff` **4.7.2** C-library variant remains a dependency
implementation, not a new program-inventory entry. It supplies the >=4.5
per-caller API required by cl-libtiff, absent from the selected stock 4.4.0,
as well as soname 6. The HEIF and TIFF CFFI wrappers use absolute store library
paths, independent of a host linker cache; the HEIF struct-return C shim is
compiled at build time. The newer cl-jpeg pin exports the encoder required by
Imago. These dependencies and existing propagated libraries are not additional
end-user programs or preservation snapshots.

The notebook patch replaces the removed `imago-pngio` API with
`imago:write-png-to-stream`. The format-registry patch prevents a core reload
from resetting optional backend/caller registrations: built-in defaults fill
only missing handlers, while explicit registration still replaces a handler.
The Jupyter dependency models its lab extension as ASDF static resources and
installs them under `share/jupyter/labextensions/debugger-restarts-clj`, rather
than creating newer user-HOME compilation outputs which invalidate installed
FASLs. The upstream suite's runner is invoked directly and fails the build on
NIL; it exercises the full suite rather than only an early ASDF suite chain.

### Main's exercised gates and actual native limits

| Gate | Main receipt |
| --- | --- |
| Source build | Main463 passed in **34.47 s**, producing the six-system output above; retained log `artifact://15191`. |
| Full upstream suite | **96 checks**, all passed, **0 skipped / 0 failed**: I/O 48, conversions 21, processing 20, contrast 1 and binary images 6. |
| Reproducibility | Main465 `--check` passed in **25.18 s**, reproducing the same output and full 96-check suite; retained log `artifact://15194`. |
| Corrected native consumer | Main464 passed in **8.85 s** at `/tmp/imago-native-11`; `driver.stdout` and `proof.json` record **34,704 assertions** and all six systems loaded. |
| Final lint | Main466 completed in **65.62 s** with remaining package-owned updater/tag/release and Software Heritage/Disarchive diagnostics; **not clean**. Earlier formatting/patch-prefix findings are gone. |
| Integrated target | Main467 `make check-imago` passed in **18.15 s** at `/tmp/imago-make-final`, consuming the same prebuilt output; final `driver.stdout` / `proof.json` repeat all **34,704 assertions**, codec metrics and six systems, with unchanged NAR. |

The corrected standalone and final integrated receipts verify exact synthetic RGB and grayscale
PNG and RGB PPM roundtrips. Generic `.jpg` and `.jpeg` dispatch both remain
**JPEG-TURBO** after loading all six systems, with no consumer re-registration.
JPEG RGB uses quality **100**, **4:4:4** sampling; each channel must have
**RMSE <=2 LSB** and **PSNR >=42 dB** (or zero-error infinity). Actual output:

| Channel | Maximum error (LSB) | RMSE (LSB) | PSNR (dB) |
| --- | --- | --- | --- |
| Red | 3 | 0.652878 | 51.834160 |
| Green | 2 | 0.485841 | 54.400917 |
| Blue | 4 | 0.789778 | 50.180698 |
| Grayscale | 0 | 0.000000 | infinity |

Dimensions, image classes and generic-reader agreement are asserted; this is
bounded JPEG quality evidence, **not lossless RGB JPEG**. TIFF's 40x30 RGB
roundtrip allows **1 LSB per channel**. HEVC HEIF's 64x48 RGB roundtrip at
quality 100 allows **12 LSB per channel**; it is likewise not a lossless claim.
Transforms exercise exact selected inversion channels, crop dimensions/corner
pixels, flip dimensions/corner pixels and grayscale conversion. Rotation tests
dimensions and channel ranges, and resizing tests dimensions: the receipt's
`transforms_exact` flag does **not** establish exact interpolated rotation or
resize pixels. Unknown read/write formats signal `unknown-format`; `:errorp nil`
returns NIL; corrupt PNG raises an `imago-error`; out-of-bounds crop raises
`operation-error`.

`imago/jupyter:show-image` produces a real MIME bundle without a kernel or mock:
the RGB payload's base64 PNG is decoded, checked for signature/dimensions and
exact pixels; binary-image display is checked as a grayscale PNG. Shared-data
extension discovery and its files are checked in the store, with no copy into
the private user extension directory. **No running notebook, browser, kernel
message delivery or full JupyterLab interaction was exercised.**

The final proof corrects the earlier harness HOME leak: a pure Guix shell alone
retains HOME, so the harness now sets private HOME/config/cache/data directories
under the fresh evidence directory before loading Lisp dependencies. It unsets
host ASDF and dynamic-library overrides and uses delivered ASDF configuration,
precompiled FASLs and `--no-userinit`, not Quicklisp. The launch configures
same-user user/network/mount/IPC/PID namespaces. Namespace identity, UID mapping
and mount flags are **not independently measured in the receipt**, so launch
configuration is not presented as an asserted isolation audit.
Before/after output NAR hashes both equal
**`1xrbrjg3sd03rsazmd5q05la8rnrl03n28d62dzil0s9zwfpzg0g`**, and the shell checks
installed files remain unwritable. Upstream parse-float/pzmq ASDF naming warnings
remain in `driver.stderr`; this is not a warning-free native-load claim.
The integrated dependency-shell launch also reports missing Nonguix module
warnings from unrelated channel definitions; these were not Imago failures,
and successful integration does not imply a warning-free or clean channel.

The guarded standalone target honors `GUIX`, consumes a prebuilt canonical
output and requires fresh empty evidence outside the store. Its external
[`tests/imago-smoke.sh`](tests/imago-smoke.sh) and
[`tests/imago-native.lisp`](tests/imago-native.lisp) are not installed proof hooks:

```sh
make check-imago IMAGO_OUTPUT=/gnu/store/xvznhm3jgz808mbbzwffmnzywzcna5yq-sbcl-imago-0.11.0 IMAGO_EVIDENCE=/tmp/imago-native-new
```

The final lint leaves Imago's no-updater/archive diagnostics, zlib's missing
tag/release diagnostics, cl-jpeg-imago's no-valid-tag/release diagnostics and
common-lisp-jupyter-imago's missing tag/release diagnostics; HEIF/TIFF archival
requests are scheduled rather than verified archived. **#220 stays OPEN** until
the literal clean-lint requirement is actually observed, not redefined or waived.
No OKF update applies to this repository-only package work: no documented host
or service changed. This documentation worker ran no commands or checks.

## AceHack — verified native tty gameplay and save continuity

Local evidence on **2026-10-07** covers the existing
[`acehack`](guix/tay/packages/acehack.scm) **3.6.0-0.9a4c767** definition,
pinned to **`9a4c7671a8d8de6c0a7ab4718382b49cf5ec61f5`**, with source NAR
base32 **`19avxbxhwl7wy3j6g1h41d0d37rhhq45j8z71zfdbynfrv1cbg78`**.
[`deepy/acehack`](https://github.com/deepy/acehack/tree/9a4c7671a8d8de6c0a7ab4718382b49cf5ec61f5)
is the historical source mirror; the original AceHack author is **Alex Smith
(ais523)**, as retained in the upstream README. This is not a claim that the
mirror is a maintained canonical upstream; the unavailable CopperWater URL
does not establish current maintenance.

This is native acceptance of an **existing inventory member**, not a new
package: accepted inventory remains **238** (230 project + 7 font + 1 optional
proprietary), while the integrated working tree is **239** (231 + 7 + 1)
including unrelated unpublished Dualmaster. Dualmaster is excluded from this
acceptance and is neither accepted nor published by that count. The canonical
**629-source preservation ledger is retained unchanged**.

| Gate | Main receipt |
| --- | --- |
| Source build | Main384 passed in **19.76 s**; artifact 14483 records `/gnu/store/3hm6534az3ns9b2yfxkalswgw36j64pp-acehack-3.6.0-0.9a4c767`. |
| Reproducibility | Main388 `--check` passed in **17.95 s**; artifact 14488 records the reproduced output. |
| Lint — clean gate pending | Main389 ran in **10.48 s**; AceHack's own GitHub updater reports no valid tags/releases. That diagnostic is not waived or concealed, and the literal clean-own-lint gate remains unmet. |
| Native tty consumer | Main387 passed in **7.23 s** at `/tmp/acehack-native-3`, using the normal launcher and real native PTY gameplay. |
| Final integrated target | Main390 `make check-acehack` passed in **9.69 s** at `/tmp/acehack-make-final`, with exact native full-map/HUD save/restore continuity and continued action. |

**Native gameplay/save continuity is verified; #266 remains OPEN with the
clean-lint gate pending.** Successful builds and native proof are not an
all-checks-complete or issue-closure claim. The older #650 score-only proof is
historical, not the current gameplay acceptance; its obsolete score contract
has been replaced by the external native consumer.

The package builds the original Unix tty executable and complete `nhdat` from
source, rather than installing a prebuilt game or synthetic smoke mode.
Immutable game/data assets stay in the store; the ordinary launcher creates
temporary playgrounds and keeps saves, scores, logs and locks in private XDG
state. Downstream changes disable `CHDIR`, shell and mail operations, preserve
mail-scroll indices, use ncurses' `tparm` declaration, fix the native internal
compression extension and pin the build timestamp. They do not replace game
rules or inject gameplay to satisfy the consumer.

The executable and generated game/map/text data use the
[NetHack General Public License](https://nethack.org/common/license.html)
(NGPL), recorded with its actual grant rather than a guessed GPL substitution.
The output accompanies them with the **complete selected patched executable
and `nhdat` source** under `share/doc/acehack/source`, using NGPL paragraph
**3(a)** and the source definition in `dat/license` lines 77–79. Original
copyright, license and warranty notices remain intact. Changed C/header and
build-helper files carry prominent **2026-10-07** downstream modification
notices under paragraph **2(a)**. Installed
`share/doc/acehack/{license,README,fixes36.0,Guidebook.txt,SOURCE,acehack.scm,install-sh-notice}`
retain the license, attribution, changes and exact package/launcher recipe.

The pre-build selected-source review covers **310 upstream text files**,
including all **39 `dat` files**, with generated build inputs retained in
addition: source, headers, utilities, tty/Unix support, configure/autoconf
templates, documentation text and the mandatory `win32api.h` configure input.
Original literary attributions in `dat/data.base`, the LibTomCrypt public-domain
notice in `src/rnd.c`, Trolltech's unlimited grant in `include/qttableview.h`,
and the configure/Autoconf/install-sh grants and exceptions are preserved.
Separate Guix runtime/build inputs retain their own license boundaries.
Optional unselected ports, graphical/encoded-sound payloads and unused graphics
headers are not installed; neither are the grantless MAXON `bitmfile.h` or
restricted legacy formatter. This is a bounded selected-source compliance
receipt, not legal certification or an all-upstream-FOSS claim.

**Documentation formatter limitation:** upstream build-only `doc/tmac.n`
restricts sale and redistribution of modifications and is **not installed**.
The full formatted `Guidebook.txt` and original `Guidebook.mn`/`Guidebook.tex`
text are retained. Rebuilding the historical Guidebook formatting requires
that macro from the pinned upstream build input: installed `source/` is
complete for the selected executable and `nhdat`, **not a self-contained
documentation formatter distribution**. `SOURCE` states this limitation
explicitly; the full upstream origin is not claimed wholly free.

The final `/tmp/acehack-make-final/continuity.json` records `success: true`,
`full_map_and_hud_exact: true`, `native_save_consumed: true` and unchanged host
game state. The normal launcher runs a real ELF child on a PTY with ordinary
game arguments. Native splash/birth selections enter a lawful human female
Valkyrie, then movement and two searches advance the naturally generated game.
`S`/`y` saves and exits **0**; an independent launch's native `c` continuation
restores and consumes that original save. Evidence-only copies of save files
are never reinjected, and no save binary, random seed or game state is patched.

The full **80 × 21** displayed map, both HUD rows, player coordinate, HP, Pw,
AC, experience level, depth, gold, score and turn exactly match the pre-save
state after restore. In the final run, movement takes the avatar from
zero-based **(61, 8)** at turn **1** to **(62, 8)** at turn **4** after two
searches; restore preserves that full state. Continued movement reaches
**(63, 8)**, and two more searches reach turn **7** before another normal save
and clean exit **0**. HP stays **16/16**, Pw **2/2**, AC **6**, experience
level **1**, dungeon depth **1**, gold **0** and score **0** throughout these
bounded actions. Native rendered screen/PTY, input and process records
accompany the structured continuity evidence; a screenshot alone is not proof.

The external consumer supplies fresh HOME/XDG paths, **UID 1000/GID 998**,
private user/mount/network/PID namespaces, loopback-only networking and
recursively read-only `/gnu/store`; these are testing isolation, not features
claimed of the game. Before/after output NAR hashes both equal
**`1r66niij3lynsq3i6yyj5w96xvv4yhhcxn37nkdrbdcrdrnws4my`**. Evidence includes
`continuity.json`, `session-{1,2}.pty`, session input/process/screen records,
native-save copies, namespace/mount records, `nar-before.txt`, `nar-after.txt`
and `consumer-exit-status.txt` (**0**).

```sh
make check-acehack ACEHACK_OUTPUT=/gnu/store/3hm6534az3ns9b2yfxkalswgw36j64pp-acehack-3.6.0-0.9a4c767 ACEHACK_EVIDENCE=/tmp/acehack-native-new
```

This standalone guarded target requires a prebuilt ordinary store output and
a **fresh nonexistent** evidence directory, honors `GUIX`, and invokes
[tests/acehack-smoke.sh](tests/acehack-smoke.sh) with
[tests/acehack-native.py](tests/acehack-native.py). It realizes the consumer's
tool closure before offline isolation but neither builds nor modifies the
supplied game output. It is not part of the aggregate `make check` target.
Limits: ordinary birth, native movement/search, save/restore display/HUD
continuity, continued action and clean save/quit only; no combat, winning,
audio or independently decoded inventory/save-binary claim. Local evidence
does not establish signed channel publication, profile installation, system
deployment or issue closure. No described host/service changed and no material
OKF correction was established, so no OKF page/log update applies. This
documentation worker ran no commands, checks, builds, linters or formatters.

## Atlas Warriors — verified native SDL gameplay

Local evidence on **2026-10-07** covers the existing
[`atlas-warriors`](guix/tay/packages/atlas-warriors.scm) **0.0.9** definition,
the final **alpha-009** snapshot of
[`lkingsford/AtlasWarriors`](https://github.com/lkingsford/AtlasWarriors/tree/d5354adbe29884016aec2867c9ded52d15f9fcd1),
pinned to **`d5354adbe29884016aec2867c9ded52d15f9fcd1`**, with source NAR base32
**`1c2m4i74d0iz7f9xx678k0m0ns0wnbxh1y9m0rsyzd0vygnp5mbq`**. This is an
existing package's native acceptance, not a new inventory member: the accepted
inventory stays **238** (230 project + 7 font + 1 optional proprietary); the
unrelated unpublished Dualmaster entry makes the integrated tree **239**
(231 + 7 + 1), without accepting or publishing Dualmaster. The canonical
**629-source preservation ledger is unchanged**.

The copy build prepares and syntax-checks original Python sources and verifies
the runtime assets; it does not fetch a prebuilt game executable. The normal
launcher uses Guix Python/Pygame, immutable XML/background/font assets and
private XDG tutorial/log state, independently of its working directory.
Project code/data is **Expat**, bundled `pygcurse.py` is **BSD-2-Clause**, the
four modified Dark Paper Pack backgrounds are **CC-BY-3.0**, and the installed
DejaVu 2.37 fonts carry their **X11-style** notice. Upstream unnotified font
copies are replaced by exact Guix DejaVu files; `LICENSE`, `README.md` attribution,
`CHANGELOG.md` and `DejaVu-LICENSE` are installed under `share/doc/atlas-warriors`.
The installed menu performs no browser, updater or runtime-download action.
There is no installed synthetic smoke mode or compatibility shim.

| Gate | Main receipt |
| --- | --- |
| Source build | Main370 passed in **11.82 s**; artifact 14434 records `/gnu/store/vqxnf7ivdd0s4gzl2ahcjpxy9nqrrxhh-atlas-warriors-0.0.9`. |
| Reproducibility | Main371 `--check` passed in **3.53 s**; artifact 14435 records the reproduced output. |
| Lint — clean gate unmet | Main372 exited **0** in **33.02 s**, but Atlas's own GitHub updater reports no valid tags/releases. Unrelated deprecated `flex`, Fourk, excluded WinRM and duplicate `libcamera-minimal` warnings also remain. Exit 0 is not clean-lint acceptance. |
| Native SDL consumer | Main381 passed in **13.69 s** at `/tmp/atlas-native-9`, using the normal launcher and real SDL event loop. |
| Final integrated target | Main382 `make check-atlas-warriors` passed in **15.53 s** at `/tmp/atlas-make-final`, preserving the full native menu/tutorial/new-game/movement/quit contract. |

**Native acceptance is verified; full issue #281 closure is not established.**
The literal clean-own-lint gate remains unmet, so #281 is reopened rather than
treated as fully complete. Installed Guix
`share/guile/site/3.0/guix/import/github.scm:280-306` uses a fixed
`release->version` parser: it strips a matching upstream package-name prefix,
`version` or `v`, or accepts a digit-leading tag; otherwise it returns `#f`.
The real **`alpha-009`** tag does not match those rules for Atlas Warriors,
and that parser provides no honest package-metadata mapping from
`alpha-009` to **`0.0.9`**. Setting a fake `upstream-name` of `alpha` is
rejected: it misidentifies the project and would yield `009`, not the game's
actual version. No updater suppression, fake metadata or unsupported mapping
has been added to conceal this diagnostic. The successful native proof and
final integrated gameplay receipt remain valid, with no inventory-count delta.

The source build/check also emits the upstream `pygcurse.py` invalid-escape
`SyntaxWarning`; the package explicitly installs its notices despite the
generic license-discovery phase's `failed to find license files` message.
Syntax/asset checks are not an upstream gameplay test suite. The final guarded
Makefile-target receipt above exercises the same normal SDL path, not an
installed synthetic acceptance mode.

The passed `/tmp/atlas-make-final/evidence.json` and `runtime.json` record a
fresh HOME/XDG environment, **UID 1000/GID 998**, separate user/mount/network/PID
namespaces, loopback-only networking and recursively read-only `/gnu/store`.
The external consumer supplies this isolation, not the game. Under Xvfb
**520 × 648**, XTest Return/Space keys enter the real menu and dismiss all
**six first-run tutorial dialogs** before a normal **Easiest** new game.
No game module is imported or evaluated by the consumer, no state or random
seed is injected, and no Python Pygame event is posted. Menu glyph alpha
support, solid foreground and zero-background channels are exact source-backed
checks, not OCR; tutorial text, HUD and game glyphs use full RGB raster checks
with the source's two-stage shadow rendering.

The naturally generated map places the player at **(21, 11)** in the final run.
A native **Right** key moves the silver avatar to **(22, 11)** on an exactly
matched adjacent gray floor (source grayscale **63**); the old avatar is
absent and the HUD still exactly reads
`HP 10 (10)  Level 1 XP  0 (10)  Hit 3  Def 3`.
A `WM_DELETE_WINDOW` request reaches SDL and exits **0**, persisting real
`tutorial.json` first-run state with an empty `error.log` and no exception.
Pre/post output NAR hashes both equal
**`18sjljhfxp85a46ldiqnsf1r508sg0699zpcb52ic1y0bmmrzfbv`**.
Screenshots are `01-main-menu.png`, `02-tutorial-1.png` through
`02-tutorial-6.png`, `03-initialized-game.png` and `04-native-movement.png` in
that final evidence directory; namespace/mount records and game/Xvfb logs
accompany them. The retained repository screenshot is
`.goocastle/evidence/atlas-warriors-native.png`, copied by Main from the final
`04-native-movement.png`. A screenshot alone is not the acceptance proof.

```sh
make check-atlas-warriors ATLAS_WARRIORS_OUTPUT=/gnu/store/vqxnf7ivdd0s4gzl2ahcjpxy9nqrrxhh-atlas-warriors-0.0.9 ATLAS_WARRIORS_EVIDENCE=/tmp/atlas-native-new
```

This standalone guarded target requires both variables, honors `GUIX` and
calls [the external smoke consumer](tests/atlas-warriors-smoke.sh) with a
pre-realized ordinary output and a new or empty evidence directory outside
the store. It realizes its test-tool closures before entering offline
namespaces but never builds or modifies the supplied game output.
Limits: menu/tutorial/new-game initialization, **one natural-map movement**,
HUD, clean SDL quit and tutorial persistence only. There is no upstream
save/load API and no save/load, audio, combat or winning claim. Local acceptance
does not establish signed channel publication, issue closure or user-profile/
system deployment. No described host/service changed and no applicable OKF
correction was established, so no OKF page/log update applies. This
documentation worker ran no commands or checks.

## Aquarium Arena — verified native SDL gameplay

Local evidence on **2026-10-07** covers the existing
[`aquarium-arena`](guix/tay/packages/aquarium-arena.scm) **0.4-0.6d494c**
definition, pinned to
[`valrak/AquariumRL`](https://github.com/valrak/AquariumRL/tree/6d494cee8d45f734eaecd56237f33aaec37a0ed8)
revision `6d494cee8d45f734eaecd56237f33aaec37a0ed8`. This is native
acceptance of an **existing inventory member**, not a new package: the
accepted inventory remains **238** (230 project + 7 font + 1 optional
proprietary), while the integrated working tree is **239** (231 + 7 + 1)
including the unrelated unpublished Dualmaster entry, which is neither
accepted nor published by this receipt. The canonical **629-source
preservation ledger is unchanged**.

| Gate | Main receipt |
| --- | --- |
| Source build | Main394 passed in **5.44 s**; output `/gnu/store/sf0bagkb7iwg7xvz46x0z3bdj3bn4gb2-aquarium-arena-0.4-0.6d494c`. |
| Reproducibility | Main396 `--check` passed in **3.62 s**. |
| Lint — clean gate unmet | Main397 exited **0** with its own `archive-missing` origin and no-valid-updater findings unresolved; exit 0 is not clean-lint acceptance. |
| Native SDL consumer | Main409 passed in **49.62 s** at `/tmp/aquarium-native-9`, using the normal launcher and real SDL event loop. |
| Final integrated target | Main414 `make check-aquarium-arena` passed in **33.57 s** at `/tmp/aquarium-make-final-4` (an earlier Main411 run failed gate 12 in 61.91 s; superseded after the speculative survival/help branches were removed). |

**Native SDL gameplay is verified; all issue #275 gates are not.** The
literal clean-own-lint gate remains open, and issue **#275 remains OPEN**.

The native run exercises the installed
`share/aquarium-arena/AquariumArena.py` under Guix Python 3.12.12 inside
fresh HOME/XDG state, **UID 1000/GID 998**, separate user/mount/network/PID
namespaces, loopback-only networking and a recursively read-only
`/gnu/store` (`ro`, `noatime`); the external harness supplies this
isolation, not the game. The SDL window is **1024 × 660** under Xvfb with
`SDL_AUDIODRIVER=dummy` and software rendering. Every input is a real XTest
key event; **no game module is imported, no PRNG is seeded, no pygame event
is posted, and no game state is accessed or mutated** — every observation is
an XGetImage capture of the native window. Pre/post output NAR hashes both
equal **`1sdsy0mjl9rbqj58n0sj72jxc4mx4caqd5pfymvbyv1f75nvgmax`**: the store
output stayed read-only, with no mutable files after quit and a clean
**exit 0** (the only log line is pygame's AVX2 build warning).

Observed gameplay, from the JSON records only. The earlier Main409 native
run at `/tmp/aquarium-native-9` additionally exercised 40 bounded
stand-in-place turns; its 11/12 help screenshots were exploratory and are
**not** verification (see below). The **final integrated Main414 run** at
`/tmp/aquarium-make-final-4` removed the speculative survival/help/
death/hiscore branches that were never a user requirement and exercised
meaningful gameplay only: the first-run board reconstructed exactly
(welcome log `Welcome to Aquarium Arena!` / `Top gladiator score is 0
points!`, exact-watch HUD `S 0`), the natural arena placed the diver at
**(19, 13)**, a native **`l`** vi-key moved it to **(20, 13)** with exact
tinted diver pixels, exact restoration of the old tile and an unchanged
HUD, and a native **Left** arrow returned it to **(19, 13)**, confirming
normal turn advancement. Examine mode showed `Looking` with the cursor
over the player, moved the cursor to **(20, 13)** and restored the diver
on exit. Fire mode showed `Firing` with **five range-pointer cells**;
firing the harpoon right was observed as a fired state with score still
`S 0` — the harpoon-item cells are **not individually resolvable** in the
capture, so no hit, miss or trajectory claim is made. A normal
`WM_DELETE_WINDOW` quit then exited **0**, traceback-free, with no mutable
files; pre/post output NAR hashes both equal
**`1sdsy0mjl9rbqj58n0sj72jxc4mx4caqd5pfymvbyv1f75nvgmax`** (immutable
output), identical to the Main409 run. Tile and glyph checks are exact
source-glyph pixel comparisons against the pinned upstream sources, not
OCR. Screenshots `01`–`09` with SHA-256 hashes, namespace/mount records
and game/Xvfb logs accompany `runtime.json`/`evidence.json`. The retained
repository screenshot is
`.goocastle/evidence/aquarium-arena-native.png`, copied by Main from the
Main409 `04-arrow-movement.png` and visually inspected; a screenshot
alone is not the acceptance proof.

Bounded limits, recorded explicitly by the harness: **no death, help-screen,
hiscore or persistence claim — those scenarios are not exercised**. The
Main409 exploratory help-panel capture (`11-help-screen-failed.png`,
`exact_pixels: false`) confirmed help is not verifiable this way and is no
gate; no help verification is claimed. The consumer imports no game
modules, seeds no PRNG, posts no pygame events and never accesses or
mutates game state; the store output stays read-only throughout. Local
acceptance does not establish signed channel publication, #275 closure, or
user-profile or system deployment. No described host/service changed and no
applicable OKF correction was established, so no OKF page/log update
applies. This documentation worker ran no commands or checks beyond
reading the evidence.

## PBUI — verified native Emacs presentations

Local evidence on **2026-10-07** covers [`emacs-pbui`](guix/tay/packages/pbui.scm)
**0.1-0.19a606d**, the original [`mmontone/pbui`](https://github.com/mmontone/pbui/tree/19a606d95cc63ed388e8b1e3459f68eaf8c4659e)
at commit **`19a606d95cc63ed388e8b1e3459f68eaf8c4659e`**. The package reuses
the existing [`mmontone-pbui-source`](guix/tay/packages/starred-i-m.scm) origin,
base32 **`0fzwy6crlhiq67am8x1lwawfi072m6jsyzh7afdbv69p6zqqwcv3`**, rather than
renaming its preservation snapshot into an application. The source pin,
archive hash and **629-source ledger** are retained; the snapshot's license
metadata is corrected from GPL-3.0-only to **GPL-3.0-or-later**. Five explicit
notices occur in `pbui.el`, `pbui-standard-commands.el`, `pbui-dired.el`,
`pbui-calendar.el` and `pbui-contacts-app.el`; the three short companions
`pbui-email.el`, `pbui-org.el` and `pbui-util.el` have no individual notice.
This does not claim that all eight headers contain license text. Upstream has
no separate LICENSE file; the installed source notices remain intact.

### Installed package and bounded repairs

The realized output is
**`/gnu/store/k14gxfcm8hf9ag8kxmikz7p5m209r0l9-emacs-pbui-0.1-0.19a606d`**.
It installs source and bytecode for all **eight** libraries beneath
`share/emacs/site-lisp/pbui-0.1-0.19a606d`: `pbui`, `pbui-util`,
`pbui-standard-commands`, `pbui-dired`, `pbui-org`, `pbui-calendar`,
`pbui-email` and `pbui-contacts-app`, plus generated autoloads/package metadata
and upstream `README.org` under `share/doc/emacs-pbui`. Propagated dependencies
are **Dash, s, request and inspector**; request's deferred dependency is part
of their closure, not another application. Upstream ships **no test suite**;
`#:tests? #f` records that absence, not a passing upstream suite.

The recipe adds missing requires for Emacs's `eieio`, `subr-x`,
`text-property-search` and `json`, and for `s`, `pbui` and `inspector` where
used; it provides the missing `pbui-util` feature and fixes the selected-item
navigation command's mismatched parameter name. It changes `/usr/bin/xdg-open`
and `/usr/bin/thunderbird` into **user exec-path lookups**, not store-bound or
automatically installed helpers. These remain optional desktop integrations
supplied by the user. Byte compilation succeeds with upstream warnings for
unused/free variables, docstrings, missing lexical-binding directives and
functions not known to the compiler; these are **warnings, not build errors**.
This is not a warning-free build claim or acceptance of those unexercised paths.

### Main's actual gates and native evidence

| Gate | Main receipt |
| --- | --- |
| Source build | Main362 passed in **10.96 s**, producing the output above; retained build log `artifact://14369` includes all eight library compilations and the skipped upstream check phase. |
| Reproducibility | Main363 `--check` passed in **1.62 s**, reproducing the same output; retained log `artifact://14370`. |
| Lint | Main364 exited **0** in **10.52 s**, with PBUI no-updater and Software Heritage/Disarchive diagnostics and unrelated deprecated `flex`, Fourk and excluded WinRM diagnostics. This is not a warning-free lint claim. |
| Native terminal | Main367 passed in **26.12 s** at `/tmp/pbui-native-3`, exercising real Dired presentations, two-file copy, selection reset and open/edit/save/reopen; native Emacs quit exited **0**. |
| Final integrated target | Main368 `make check-pbui` passed in **27.88 s** at `/tmp/pbui-make-final`, retaining the same full native flow and unchanged output NAR; command output `artifact://14395`. |

The authoritative final receipt `/tmp/pbui-make-final/evidence.json` has status
`passed`; Main367's earlier `/tmp/pbui-native-3` also retains the same flow.
Ordinary **Emacs 30.2 `-nw`**, with the installed PBUI and propagated closure,
presents two real files and one directory in Dired. Native selection and
command completion copy both files into `archive/`; actual copied contents
are retained separately as `archive-alpha.txt` and `archive-beta.txt`.
Selections reset, then the PBUI open command opens `alpha.txt`; native editing
and saving persist the exact line `Edited and saved through native Emacs.`,
and reopening proves the saved contents. The final 76-byte `alpha.txt` has
SHA-256 **`3352a3aa698d09bef0bf77c63e5b0a145cbe29d85ea4997550367f521558f968`**.
`session.raw`, `input-events.json`, numbered terminal `.raw`/`.txt`/frame JSON
captures, `driver.stdout`/`driver.stderr`, original/copied files and five pairs
of source/installed license-header observations retain the actual proof.
The observed `08-reopened-edit.txt` shows the exact edited line in native
`(Text PBUI)` with no visible error. These are **PTY cell captures**, not a
graphical screenshot claim. Earlier Main365/366 attempts failed on a missing
`cmp` proof dependency and Emacs initialization ordering in the harness;
those harness fixes did not weaken product acceptance, and Main367/368 are
the successful corrected runs.

The external consumer runs at caller **UID 1000/GID 998** in private user,
mount, network and PID namespaces, with only `lo` and read-only `/gnu/store`.
`isolation.json` and mount records retain the boundary. Before/after output
NAR hashes both equal **`0d54nmn0c0kmg3m5rkhwy247pv9lns8dv41zp5vmb9cbrxf1vsx8`**.
The external harness supplies isolation; PBUI itself is not a security sandbox.
No replacement renderer, mocked UI or installed test entry provides this path.

The standalone guarded target requires a prebuilt canonical output and a
fresh, empty absolute evidence directory outside the store, honors `GUIX`,
and invokes [`tests/pbui-smoke.sh`](tests/pbui-smoke.sh) with
[`tests/pbui-native.py`](tests/pbui-native.py); it is not an aggregate consumer:

```sh
make check-pbui PBUI_OUTPUT=/gnu/store/k14gxfcm8hf9ag8kxmikz7p5m209r0l9-emacs-pbui-0.1-0.19a606d PBUI_EVIDENCE=/tmp/pbui-native-new
```

Limits: this proves the local Dired selection/copy and file edit/save/reopen
path, not every PBUI command or companion. Calendar, Org, inspector, mail,
`xdg-open`, Thunderbird and the **contacts network demo were not exercised**.
No signed channel publication, issue closure, profile installation or desktop
deployment is established. No OKF update applies to this repository-only
acceptance. This documentation worker ran no commands or checks.

## Ink — source-built React terminal renderer and native PTY consumer

Local evidence on **2026-10-07** covers [`node-ink`](guix/tay/packages/ink.scm)
**7.1.1**, the original [`vadimdemedes/ink`](https://github.com/vadimdemedes/ink/tree/ad9e3ea430acd3411be1c7578a2859f810a848ec)
at canonical commit **`ad9e3ea430acd3411be1c7578a2859f810a848ec`**,
not merely the earlier v7.1.1 tag. The manifest still declares 7.1.1.
Its source is the existing `vadimdemedes-ink-source` archive origin, base32
**`0wc7dn9z3gc9rwvksbf9cy6rnw10nxmw80jid5isqfqbsyrr2l5b`**.
This delivers a usable ESM React terminal-rendering library, not a renamed
preservation snapshot, CLI wrapper or copied npm Ink distribution. Support is
bounded to **x86_64-linux**; local acceptance does not establish signed channel
publication, issue closure, profile installation or deployment.

### Fixed source closure and actual installed layout

Upstream has no lockfile. The channel-owned
[`ink-package-lock.json`](guix/tay/packages/ink-package-lock.json) was generated
with **npm 11.16.0**, `--package-lock-only --ignore-scripts` and
**`--before=2026-08-12T00:04:13Z`**, against that commit's manifest. This is a
dated channel resolution, not an upstream-authored lock or a claim that every
dependency existed when Ink's Git commit was authored.
[`ink-npm-sources.scm`](guix/tay/packages/ink-npm-sources.scm) records **611
Linux-independent installation paths from 580 distinct registry archives**,
with locked SHA-512 SRI, version and SPDX metadata. Its provenance records
archive-byte/SRI inspection on 2026-10-06. These pinned npm archives may carry
upstream-generated JavaScript; **not every npm dependency is rebuilt from its
authoring source**. The native/Wasm tools named below are source-built
exceptions, while Ink itself is compiled from the canonical Git-commit archive.
SRI pinning alone is not source-build evidence. Only the unused Electron
`react-devtools` GUI is omitted from the lock root; `react-devtools-core` stays
in the test closure. Original typecheck/lint scripts, AVA file globs and genuine
PTY fixtures are unchanged. After the failed first reproduction, the package
changes only the full-board snake fixture's process-start deadline from
**1000 ms to 10000 ms**; its exit/won/score/length assertions remain unchanged.
This is not a removed test, skip or new expected failure. The initial Main348
suite ran before that change; Main352-358 provide the corrected-package
source, native, reproducibility, integrated, identity and lint receipts.

The compiler runs the original `npm run build`; the installed manifest exports
`types: ./build/index.d.ts` and `default: ./build/index.js`, requires Node
**>=22**, and has no development dependencies or scripts. Main352's corrected
source-built output is
**`/gnu/store/2ak416rk6hxc21ff9qcq0lgp819nw20s-node-ink-7.1.1`**.
Read-only inspection and Main353's `/tmp/ink-native-final/evidence.json` confirm:

- Built JavaScript, source maps and TypeScript declarations beneath
  `lib/node_modules/ink/build`; entry SHA-256
  **`f74b11e2a66d5c2873a29646dc180484b45d61a107fb09abfda101948571f664`**.
- **React 19.2.4** at sibling `lib/node_modules/react`, satisfying Ink's
  **>=19.2.0** peer range, alongside `@types/react 19.2.18` and `csstype 3.2.3`.
  The consumer and Ink resolve the same React instance, not a second private copy.
- **37 private runtime package paths** under `ink/node_modules`, including
  source-built **Yoga 3.2.1**, `react-reconciler 0.33.0`, `scheduler 0.27.0`
  and the explicitly nested `stack-utils/node_modules/escape-string-regexp`.
  This is a path count, not 37 added channel programs. The installer dereferences
  selected modules and excludes unselected nested development trees.
- Ink's license/readme beside the library, plus
  `share/doc/node-ink/{license,readme.md,channel-package-lock.json}`.
  Runtime package license texts remain beside their modules; declared runtime
  licensing is MIT/Expat and ISC (MIT chosen for MIT OR CC0-1.0).
  Build-only tool closures are not installed as Ink runtime dependencies.

No npm Yoga archive or optional platform binary supplies the native build.
Source-built **esbuild 0.25.12** matches tsx 4.21.0's JS adapter; its npm
distribution subtree is removed from the Go source. **node-pty
1.2.0-beta.12** is genuinely rebuilt using packaged Node **24.18.0**'s
node-gyp and headers with `--build-from-source --offline`; foreign prebuilds
and Windows ConPTY assets are removed. No header downloader, lifecycle script,
prebuilt fallback or fake PTY substitutes for it.

The private [`node-unrs-resolver`](guix/tay/packages/unrs-resolver.scm)
**1.12.2** is compiled from tag commit
`ccb26d205e2938b16069c64a28996b48ee97ff94`, source base32
`02g39s74cszha0lgizp7pmkd04wfklrcxixhlf72b94hzdapliw8`, with Rust **1.94**,
the locked `unrs_resolver_napi` workspace member and `allocator` feature.
Its [Cargo closure](guix/tay/packages/unrs-resolver-cargo-sources.scm)
contains **181 locked registry entries** for offline workspace resolution;
the x86_64-linux addon builds 101 of them. The delivered
`resolver.linux-x64-gnu.node` replaces `@unrs/resolver-binding-*` binaries.
Its bounded installed-loader check exercises `./a` -> `a.js` and builtin
`node:fs`; **the full upstream Rust/Vitest fixture suites are not run**.
The unsupported browser/Wasm binding is not supplied. Crate licenses and
four source-pinned missing-license supplements are retained under its doc tree.
The four missing-license supplements are **fast-glob 1.0.1, napi 3.9.0,
napi-sys 3.2.1 and nodejs-built-in-modules 1.0.0**, fetched from upstream
commits recorded in the crates' `.cargo_vcs_info.json`, not generic replacement
license texts.

### Genuine Yoga C++ and exact source-built SDK

[`node-yoga-layout`](guix/tay/packages/yoga-ink.scm) **3.2.1** uses Yoga
commit **`042f5013152eb81c1552dec945b88f7b95ca350f`**, not its tree object
`119ccd5d49460bf6a0e94b5b5e27f7d379b082ff`; Git-origin recursive base32 is
**`09g2kispng520mcaky87lkpj7k1lscsz2jyv05cjxzfrwwf4pfyb`**.
Generated `javascript/binaries`, `dist` and `.emsdk` directories are removed
before building. Upstream `javascript/CMakeLists.txt`, C++20/embind/emmalloc,
growable-memory, modular ES-module and single-file web flags remain intact.
The resulting **WebAssembly is embedded in
`dist/binaries/yoga-wasm-base64-esm.js`**, not absent because no standalone
`.wasm` is installed. Realized files include eager `dist/src/index.js`,
asynchronous `load.js`, `wrapAssembly.js`, generated `YGEnums.js`, all matching
declarations/maps, original `src` and MIT license. Wrapper compilation uses
upstream Babel dist configuration and **TypeScript 5.0.4**; its separate
[compiler closure](guix/tay/packages/yoga-ink-npm-sources.scm) has **142
archives**, selected from upstream's pinned yarn.lock, not a second live
package-manager resolution. Yoga's complete standalone output is
**`/gnu/store/5snwz6scvbwz2qggjaihjp78dq4zylv4-node-yoga-layout-3.2.1`**;
its source-provenance text explicitly records no prebuilt Yoga WebAssembly input.

[`emscripten-yoga`](guix/tay/packages/emscripten-yoga.scm) **3.1.28** is a
source-built driver/sysroot, not an SDK binary download. emsdk 3.1.28 selects
emscripten-releases `30b9e46ddcea66e91530559379089002d8b692cf`, whose DEPS
pins are honored exactly:

| Component | Exact source pin and role |
| --- | --- |
| Emscripten | 3.1.28, revision `f11d6196dd4e8748a726f19895c859b40ff6a4f3`; source base32 `00crqf3wi2qda53vn97n1gwivpcaj4mzlnswlh3m19djqp52b2qg` |
| LLVM/Clang/LLD | `ea4be70cea8509520db8638bb17bcd7b5d8d60ac`, **16.0.0git**, not Guix LLVM 16.0.6; source base32 `1smad7sdbwjfl9ndpf2xwv8b47idmkfz1865xvlkdpphca5j9b7y` |
| Binaryen | `2cb5cefb6392619d908ce2ab683815d7e22ac9a5`, **111** snapshot; source base32 `0kisi81cybb72kgy8aw8gk2vvvadfrnsqznbz6kc3f5ajq7njhn6` |
| Closure Compiler | [`emscripten-yoga-closure-compiler`](guix/tay/packages/emscripten-yoga-closure.scm), source-built **v20220502**, not a release jar; source base32 `1y4q4b871d7nvi5dlmk8hxpvvshj9g9d8w5id9mv1cz6gkgwkdpd`; reuses the source-only Rot.js Java builder/dependency pattern with source-built protobuf **3.19.3** |

The SDK builds the full upstream **`embuilder build SYSTEM`** and
**`embuilder --lto build SYSTEM`** caches from source. Normal libraries serve
CMake probes; full-LTO libraries serve Yoga. Its installed configuration sets
**`FROZEN_CACHE = True`**, points at the exact source-built LLVM/Binaryen/Closure
outputs, and fails if an undeclared sysroot artifact is missing rather than
mutating the store or fetching a port. Accepted SDK output:
**`/gnu/store/pm1kcnxf6608szz3y5rccyjqnn872y6s-emscripten-yoga-3.1.28`**.
Downloadable ports and unrelated HTML/wasm2c conversion tools are not provisioned.
**SDK, LLVM, Binaryen and Closure exhaustive upstream test suites are not claimed**;
source compilation/cache construction and the genuine Yoga/Ink path are the
bounded evidence. Yoga's package check phase is omitted; the Ink suite and
installed PTY consumer exercise its delivered engine, not the full Yoga suite.

### Main source-build and native receipts

| Gate | Main receipt |
| --- | --- |
| SDK source build | Main343 passed in **11637.37 s**; artifact **14181** is a sample, with full Guix derivation logs retained separately. It builds exact LLVM/Binaryen, the source Closure compiler and normal/full-LTO system caches, not their exhaustive test suites. |
| Yoga source build | Main346 passed in **56.61 s**, artifact **14185**, producing the `5snw…` output above. |
| Native lint resolver source build | Main347 passed in **151.25 s**, artifact **14187**, output `/gnu/store/q1f8mwpaqna6inbhdzgqhi7jbnzvmlbd-node-unrs-resolver-1.12.2`; bounded installed-loader checks only. |
| Ink source build | Main348 passed in **487.44 s**, artifact **14189**, producing the `1ck5…` output above. Original `npm test` ran `tsc --noEmit`, XO and serial AVA 7: **1062 tests passed, 4 known failures, 1 test todo**. |
| Installed-package native proof | Main349 passed in **8.88 s**, `/tmp/ink-native-1`: `INK_PTY_COUNTER_OK counts=0,1,2 exit=0 geometry=100x34` and `INK_CONSUMER_OK`. Its actual `evidence.json` records `status: passed`, `exit_status: 0`, the `1ck5…` output and unchanged output NAR. |
| First reproducibility attempt | Main350 **failed** in **433.27 s**, artifact **14192**: the original `alternate-screen-example › snake ends with a win when it fills the board` fixture timed out at `test/alternate-screen-example.tsx:85`. Yoga and Unrs rebuilds passed; Ink's check failed with 1 new failure, alongside 4 original known failures and 1 original todo. This attempt does not establish a reproducible Ink output. Main348/Main349 remain evidence for their dated output, not final all-gates acceptance. |
| Recompiled auxiliary-path attempt | Main351 **failed** in **6.29 s** before building: `canonicalize-path` could not find `ink-closure.mjs` because a module-relative bare `local-file` was resolved relative to the recompilation working directory. The definition now resolves the lock and closure helper through the existing `search-tay-package-file` auxiliary pattern; no source origin changed. |
| Corrected Ink source build | Main352 passed in **202.79 s**, artifact **14211**, producing `/gnu/store/2ak416rk6hxc21ff9qcq0lgp819nw20s-node-ink-7.1.1`, drv `/gnu/store/l9z99yxg45m3klwwjr2i3ldzlhzy7ppc-node-ink-7.1.1.drv`. The original typecheck/XO/AVA suite, with only the disclosed process deadline amendment, again reports **1062 passed, 4 original known failures, 1 original todo**. |
| Corrected installed-package native proof | Main353 passed in **9.97 s**, `/tmp/ink-native-final`, on the `2ak4…` output: count 0/1/2, exit 0, geometry 100×34, complete termios restoration and unchanged output NAR. It supersedes Main349 as the corrected-output consumer receipt. |
| Corrected reproducibility | Main354 `--check` passed in **225.54 s**, artifact **14214**, rebuilding the same `/gnu/store/l9z99yxg45m3klwwjr2i3ldzlhzy7ppc-node-ink-7.1.1.drv` and identical `2ak4…` output. The complete original typecheck/XO/AVA path again reported **1062 passed, 4 original known failures, 1 original todo**. This is the corrected-output reproducibility receipt, not a rerun to conceal Main350. |
| Integrated Makefile consumer | Main356 `make check-ink` passed in **10.00 s**, `/tmp/ink-make-final`, on the same `2ak4…` output. Actual JSON/PTY/text-cell receipts again record count **0,1,2**, exit **0**, **100×34** geometry, original termios restored and unchanged NAR **`13br5g72cxvhbwlnaa3chqmmaffpcjbn964q9gdd7i71m5cz4k6q`**. |
| Final formatted-definition identity | Main357 passed in **2.77 s**, selecting the same accepted `2ak4…` output after behavior-preserving line wrapping; it reused the same derivation and is **not another rebuild**. |
| Final lint | Main358 exited **0** in **8.31 s** (direct output, no artifact). Ink-owned findings remain, not suppressed: `guix/tay/packages/ink.scm:48:2` reports **no updater for `node-ink`**, and its source is **not archived on Software Heritage and missing from Disarchive**. The other diagnostics are unrelated: deprecated `flex` and `nhfourk` `171:86` unexpected `)`, plus `winrm-java-dependencies` `325:1` unexpected EOF while searching. Exit 0 is **not** a warning-free claim. |

The four AVA failures are **original expected-failure cases**, not regressions
hidden by the package: row and column space-around alignment of two text nodes,
percentage min width and percentage max width. The original todo is
`useStderr - write to stderr`. None was removed, rewritten or converted to a
new skip. Artifact 14189 also retains upstream `act(...)` environment warnings;
the successful suite is **not** a claim of warning-free output.
The failed Main350 reproduction is retained as a distinct gate result; it is not
folded into the four original known failures or concealed as a skip. Main352-358
are the final acceptance receipts for the corrected `2ak4…` output: source suite,
native consumer, reproducibility, integrated target, formatted identity and lint.
This is local repository acceptance, not signed publication or deployment.

Retained full source-build logs (distinct from the artifact sample) include
`/var/log/guix/drvs/v2/3s51ch7ph4pd7cqas33r4cpcimbba5-llvm-for-emscripten-yoga-16.0.0-emscripten-3.1.28.drv.gz`,
`/var/log/guix/drvs/fc/b8s83m1ks93j7i65098sgyfwhx3m14-emscripten-yoga-closure-compiler-20220502.drv.gz`
and `/var/log/guix/drvs/af/3vv316k4lbhsnycdgrscvshsmhc8f9-emscripten-yoga-3.1.28.drv.gz`.

[`tests/ink-smoke.sh`](tests/ink-smoke.sh) consumes an already-realized canonical
direct store output and a fresh nonexistent absolute evidence directory outside
the store; it never realizes or builds Ink. Generic proof tools are realized
before isolation. The independently authored
[`counter.mjs`](tests/ink-consumer/counter.mjs) uses ordinary public React/Ink
APIs, `useState`, `useInput`, `useApp().exit()` and `waitUntilExit()`, not a test
renderer or manually updated fake screen. Main353's final JSON records private same-UID
user/mount/network/PID namespaces, only loopback `lo`, recursively read-only
`/gnu/store`, a failed store-write probe **EROFS**, fresh HOME/TMP/XDG roots,
and packaged Node **24.18.0**. Its resolution trace loads **545 installed
module files**, one sibling React resolution and the actual embedded-Wasm Yoga
module/wrapper/enums; neither checkout modules nor consumer-local replacements
provide the runtime.

The real **100×34 PTY** receives `a`, `a`, `q`: count **0 -> 1 -> 2**, then
clean exit **0** and `INK_COUNTER_EXIT count=2`. Text and complete cell-grid
receipts in `/tmp/ink-native-final` (`screen-01-initial.txt` through
`screen-05-final.txt`, matching `cells-*.json`) record the exact round cyan border,
green bold Japanese title
`Ink カウンター ✓`, yellow bold count and magenta help line. Assertions compare
all cells, including Unicode width/continuation cells and styles. The cursor is
hidden at `[0,5]` while running and visible at `[0,6]` after exit; raw/no-echo
mode is exercised and **the full original termios state is restored**.
Synchronized-output brackets are balanced, with no alternate-screen switch.
Before/after output NAR is identically
**`13br5g72cxvhbwlnaa3chqmmaffpcjbn964q9gdd7i71m5cz4k6q`**.

Native proof limits: pyte models the PTY byte stream; **no physical terminal
emulator or GUI screenshot is rendered**. This external consumer exercises
ordinary single-byte `a`/`q` keys only, not external resize, paste, Ctrl+C,
React DevTools, every Ink API or other Node/React/platform versions. The build's
original upstream tests have broader coverage but are separate evidence.
`make check-ink` requires `INK_OUTPUT` and `INK_EVIDENCE`, propagates `GUIX`,
and remains a standalone target outside aggregate checks. `node-ink` joins
default build/dry-run/lint inventory; private Yoga/LLVM/Binaryen/SDK helpers do
not add default top-level package entries.

Unauthorized workers' full-npm fixture runs, prototype/native consumer probes
and Guix store/GC cleanup are **disclosed and excluded from acceptance
evidence**. Only Main's current source-built outputs and named receipts support
this delivery; no npm-fixture/prototype success substitutes for them. This
documentation worker ran **no commands, shell listings, builds, tests, linters,
formatters, applications or probes**; it only read existing files/receipts and
edited the Ink documentation. No described host/service changed and no material
network-catalog correction was established, so **no OKF page/log update applies**
to this repository-only delivery.

## Rot.js — verified source-built toolkit and offline consumer

Local acceptance on **2026-10-06** covers
[`rot-js`](guix/tay/packages/rot-js.scm) **2.2.1**, built from
[`ondras/rot.js`](https://github.com/ondras/rot.js/tree/46782e248c2db9d379a5e4f13bb8323f18dff04b)
commit `46782e248c2db9d379a5e4f13bb8323f18dff04b` ("#223 link+version"),
Git origin base32 `0vd530vgkzg80bcwlcr8zcv5h2ywb8c1ij0cc4nfwigklrwrlrxk`.
Upstream `package.json` says 2.2.1; the committed lockfile root still says
2.2.0, and only the package version is claimed. The package license field is
BSD-3-Clause for rot.js itself, Expat for Babel/lunr helpers emitted into the
bundles and docs, and Apache-2.0 for TypeDoc-generated docs and any Closure
runtime helpers in `dist/rot.min.js`. The unchanged preservation snapshot
[`ondras-rot-js-source`](guix/tay/packages/starred-n-r.scm) pins the same
commit (snapshot hash `0j8x32cadpwcn9niv7ka502pzkiknr54lch496zw5sbqp6kmkqis`,
BSD-3); this acceptance adds no snapshot. Unrelated work in the tree, including
Dualmaster, remains outside this receipt.

### Source, toolchain and build boundary

The configure phase deletes every committed generated artifact (`lib`, `dist`,
`doc`, `.ts.flag` and `examples/bundled-modules/example.bundle.js`), so all
installed JavaScript, declarations, bundles and API docs are rebuilt here.
[`rot-js-npm.py`](guix/tay/packages/files/rot-js-npm.py) replays the fixed
npm lock locations with no resolution and no lifecycle scripts; every archive
is checked against its upstream lock SHA512 and name/version before use.
[`rot-js-npm-sources.scm`](guix/tay/packages/rot-js-npm-sources.scm) pins
**260** npm tarballs by SHA256 and replays every lock location except five:
`fsevents` (macOS-only), `google-closure-compiler-java` (prebuilt
`compiler.jar`) and the `google-closure-compiler-{linux,osx,windows}` native
images. The google-closure-compiler JavaScript wrapper remains. The build then
runs upstream `make all` (tsc → rollup → Babel → Closure Compiler → TypeDoc)
and `examples/bundled-modules/run.sh`, and fails unless `dist/rot.js`,
`dist/rot.min.js`, `lib/index.js`, `lib/index.d.ts`, `doc/index.html` and the
rebuilt `example.bundle.js` exist and are non-empty.

`node_modules/google-closure-compiler-java/compiler.jar` is a symlink to the
private source-built
[`rot-js-closure-compiler`](guix/tay/packages/rot-js-compiler.scm)
**20211201.0.0**: `google/closure-compiler` tag `v20211201`, commit
`0c03641ae285b528d00cf7770c94b07759a28f12`, base32
`0w88bkzsjs9byhhshrz3zihk778b9bwaj6j3749020304lgkmvif`. It is compiled with
javac, protoc (protobuf 3.11.4) and Ant 1.10.11 on IcedTea 8 against
source-built Guava 31.0.1, failureaccess 1.0.1, Gson 2.7, RE2/J 1.3,
protobuf-java 3.11.4, Error Prone annotations 2.3.2/2.7.1, Checker Qual
3.12.0, J2ObjC annotations 1.3, JSR-305 3.0.2, JSR-250 1.0, AutoValue 1.6
(with auto-common 1.1.2, AutoService 1.0 and JavaPoet 1.13.0) and args4j; no
Maven resolution, downloaded bytecode or Bazel is used. Its
`runtime_libs.typedast` is generated in two stages. Licenses are Apache-2.0,
MPL-1.1, GPL-2.0-or-later, Expat, BSD-3-Clause and CDDL-1.0; upstream
`COPYING`, `LICENSE.external`, `MPL-1.1.txt`, the Rhino source, copyright
sources and dependency notices are installed under
`share/doc/rot-js-closure-compiler`. The compiler package has
**`#:tests? #f`**; its build log states that the test suite was not run. The
**exhaustive upstream Closure Compiler JUnit suite was not run**, and no claim
rests on it. The bounded compiler claim is only that this source-built jar
produced the real `dist/rot.min.js`, which then passed the same upstream suite
and runtime checks as `dist/rot.js`. Main's lint reports that this compiler
could be upgraded to `20261005`; the exact upstream build pin is deliberate.

**WASM is build-only.** TypeDoc's Node syntax highlighter loads
`vscode-oniguruma@1.7.0` `release/onig.wasm`, SHA256
`fd885c2d12e5951e59d761ebd4a006e06254b1491fd6f530c92b69fb4d8d77d9`; its
`NOTICES.txt` identifies Oniguruma 6.9.5_rev1 (BSD-2-Clause) with Microsoft's
MIT wrapper. That object is pinned from the npm archive, **not compiled from
source by this channel and not installed** in rot-js. The separate unused
browser WASM in `shiki@0.9.15` is deleted before the build, so only the
attributed vscode-oniguruma object enters the docs build. A documentation-worker
read-only `find` listed no `.wasm` file in the installed output; that
observation is excluded from acceptance evidence.

Build-tool legal notices are preserved, not relicensed: for each of the 260
archives, its license/copying/notice/authors files, README and `package.json`
are copied to `share/doc/rot-js/build-tools/npm/<package@version>/`, with an
`inventory.json` of license, resolved URL, lock integrity and notices.
[`rot-js-build-notices.txt`](guix/tay/packages/files/rot-js-build-notices.txt)
is installed there as `SUPPLEMENTAL-NOTICES`. It supplies license texts missing
from three pinned archives — entries for tr46@0.0.3 (MIT, Sebastian Mayr),
vinyl-sourcemaps-apply@0.2.1 (ISC, Florian Reiterer) and
`@nicolo-ribaudo/chokidar-2@2.1.8-no-fsevents.3` (MIT) — plus notices for the
latter's bundled JavaScript, including webpack 5.53.0. These are build-time
notices, not runtime dependencies of rot-js.

### Installed artifact

Main's accepted output is
`/gnu/store/zf6i70g0anjdjg43bp4jqmbkzd6zfm4z-rot-js-2.2.1`, built with compiler
output `/gnu/store/iyxmrwxhb2djxds33b5bbjcx2c090xg5-rot-js-closure-compiler-20211201.0.0`.
`lib/node_modules/rot-js` contains upstream's published `files` set — `lib`
(ESM plus 49 `.d.ts` declarations), `dist` (UMD `rot.js` and `rot.min.js`),
`doc` (TypeDoc API), `examples`, `addons` and `manual` — with `package.json`,
`license.txt` and `README.md`. `share/doc/rot-js` holds `license.txt`,
`README.md`, an `api` link to the generated docs, the build-tool notices above
and the build-time consumer script. Recorded runtime SHA256s are
`lib/index.js` `c642974a9e2a6777d0c90a4ebcc46ba1270c0a24b9d48170085732299be0bef2`
(854 B), `dist/rot.js` `31b61b69904b9a118bae795892e20b78792558e842caae6f23f84c1fb886f892`
(184376 B) and `dist/rot.min.js`
`08bb45765ea9a8d07ee741254ddcff898178e0836d0ceb63f3a85be7bb396cf9` (68729 B).

The check phase runs upstream `make test` through
[`rot-js-browser.cjs`](guix/tay/packages/files/rot-js-browser.cjs): Jasmine
3.10.1 driven by puppeteer-core 13 in headless ungoogled-Chromium, with local
files only (the upstream unpkg Jasmine URL is rewritten to local assets, and
any non-local request fails the run) and a DejaVu fontconfig. It requires all
**11** original spec files to load and every defined spec either to pass or to
match a literal upstream `xit` declaration: **183 specs defined and reported,
180 passed, 3 upstream-disabled `xit` specs**, `overallStatus=passed`. The
three disabled specs, all in `fov.js`, are "FOV Precise Shadowcasting
8-topology should compute single partially visible target / single visible
target / single invisible target"; they did not run and are not claimed. The
build-time [consumer](guix/tay/packages/files/rot-js-consumer.cjs) then
reported `dist/rot.js` Digger 179 floor cells, AStar 31 steps, FOV 51 and a
passing scheduler, with the same results for `dist/rot.min.js`. TypeDoc printed
about 31 "not included in the documentation" warnings and a
`listInvalidSymbolLinks` deprecation warning; generated docs are checked only
for existence.

### Main build and integrated receipts

| Gate | Main receipt |
| --- | --- |
| Source build | Main312 passed in **46.50 s**, producing the accepted runtime and compiler outputs above; artifact `13847`. The browser suite printed `Original suite: 11/11 spec files loaded; 183 specs defined, 183 reported, 180 passed, 3 upstream-disabled; overallStatus=passed`. |
| Reproducibility | Main314 `--check` of both packages passed in **32.77 s**, reproducing the same `iyx…` compiler and `zf6…` runtime outputs and the same suite line; artifact `13850`. |
| Full lint | Main315 exited **0** in **27.93 s** with no `rot-js` findings. The only Rot-scope diagnostic was `rot-js-compiler.scm:62:2: rot-js-closure-compiler@20211201.0.0: can be upgraded to 20261005`, a deliberate exact upstream build pin; known unrelated `flex`, NHFourk, WinRM and libcamera diagnostics remain. This is bounded no-new-errors acceptance, **not warning-free lint**. |
| Native installed-package proof | Main313 passed in **6.98 s** at `/tmp/rot-js-native-1`, printing `ROT_JS_RUNTIME_OK builds=3 seed=151 connectivity=all-floors shortest-paths=all-floors fov=exact schedulers=exact` and `ROT_JS_CONSUMER_OK`. |
| Final integrated target | Main317 `make check-rot-js` passed in **9.22 s** at `/tmp/rot-js-check-1`, printing the same two lines. Its `evidence.json` records `status: passed`, `exit_status: 0`, the same `zf6…` output and both exact rejections. A documentation-worker `cmp` found its `runtime-semantics.json` byte-identical to Main313's; that comparison is disclosed but excluded from acceptance evidence. |

The [smoke harness](tests/rot-js-smoke.sh) requires a canonical,
already-realized direct store output and a fresh nonexistent absolute evidence
directory outside the store; it never builds or realizes rot-js. Generic proof
tools (Python, coreutils, util-linux, Node) and the lock-pinned TypeScript
4.5.4 archive (the same `typescript@4.5.4` npm source used by the upstream
build, SHA256 `5b2b014c4d6f9ad4615d7ced8cc32f882a4a96df8213722577b42277afb03cba`)
are realized before
[`native.py`](tests/rot-js-consumer/native.py) enters private user, mount,
network and PID namespaces. Inside, only `lo` exists, `/gnu/store` is
read-only (a write probe fails with EROFS), HOME, TMPDIR and every XDG root
are fresh, and PATH supplies Node 24.18.0 only. Compiler trace resolution
shows `import ... from 'rot-js'` resolving to the installed
`lib/node_modules/rot-js/lib/index.d.ts`, with all 49 package declarations
loaded under `strict`, `noImplicitReturns` and unused-local/parameter checks.
Both receipts record before/after output NAR
**`1ywf2ghik344sp6v1axpnfrsfpnrc0wppb3fhkgjym1q0yzrzypm`** and
`output_unchanged: true`.

The independently authored [accepted consumer](tests/rot-js-consumer/accepted.ts)
compiles and runs, printing
`{"arenaFloors":9,"path":[[1,1],[2,1],[3,1]],"visible":9,"actor":"typed-hero","time":0.5,"seed":151}`.
Each rejection independently exits **2** with exactly its expected diagnostic:

- Non-numeric speed: a Speed-scheduler actor whose `getSpeed` returns
  `'fast'`, `rejected/actor.ts` 3:49, **TS2322** "Type 'string' is not
  assignable to type 'number'."
- Invalid topology: `topology: 5`, `rejected/topology.ts` 3:46, **TS2322**
  "Type '5' is not assignable to type '4 | 6 | 8 | undefined'."

[`runtime.cjs`](tests/rot-js-consumer/runtime.cjs) loads all three installed
builds — `lib/index.js` (ESM), `dist/rot.js` and `dist/rot.min.js` (UMD) — and
requires each to export exactly 18 names; `require.resolve('rot-js')` selects
`dist/rot.js`. Digger at seed 151 on 40×25 (`timeLimit: Infinity`) yields 179
floors, all connected by an independent BFS, 6 rooms, 9 corridors and maximum
distance 36; resetting the seed reproduces the map. AStar and Dijkstra return
shortest 4-topology routes to every floor, and a wall origin is unreachable.
Precise shadowcasting FOV matches exact expectations for open radius 3, an
enclosed origin, an opaque origin and radius 0. Simple, Speed
(`[['fast',0.5],['slow',1],['fast',1],['fast',1.5],['slow',2],['fast',2]]`),
Action and EventQueue orderings and an Engine run are exact. All semantics are
identical across the three builds.

Limits: this proves the headless upstream suite at build time and the
installed Node/TypeScript API paths above. There is **no Display, canvas,
terminal-backend, GUI, screenshot or interactive browser proof** beyond that
build-time headless Chromium Jasmine run. The installed examples, manual and
addons are shipped but not exercised (apart from rebuilding the bundled-module
example), and API docs are checked only for presence. No claim is made for
other TypeScript versions, other seeds or every generator/algorithm, the three
`xit` specs, or the exhaustive Closure Compiler test suite.

The standalone `make check-rot-js` accepts `ROT_JS_OUTPUT` and
`ROT_JS_EVIDENCE`, propagates `GUIX`, and does not join aggregate smoke
checks. Workers' unauthorized compiler release-jar probes, generic npm build
probes, `unshare` Node/source probes and fontconfig build probes are **not
Main verification evidence**; no success or check claim rests on them. This
documentation worker ran no checks, builds, tests, linters or formatters. It
did run read-only inspection commands on existing receipts and outputs:
reading `evidence.json` fields, `ls`/`find` listings of the realized store
outputs (including the `.wasm` absence and 260 notice directories), and `cmp`
comparisons of consumer templates and of the two receipts'
`runtime-semantics.json`. These are disclosed and excluded from acceptance
evidence; no acceptance claim rests on them. No described host/service or
material network-catalog correction changed, so no OKF page/log update applies
to this repository-only delivery.

## Meta Typing — verified offline type-level library and external consumer

Local acceptance on **2026-10-06** covers
[`meta-typing`](guix/tay/packages/meta-typing.scm) **0.1.0**, the original
declaration-only library from
[`ronami/meta-typing`](https://github.com/ronami/meta-typing/tree/03a4927933e3a6e6439d42f29d656353512fe308),
pinned at **`03a4927933e3a6e6439d42f29d656353512fe308`**. The buildable Git
origin's Guix base32 SHA-256 is
`0g6vwiih3hvlsypvcvqkv6xv8ysn4139gm2zqj4yw21awf5kybdl`.
The installed MIT/Expat license names **Ronen Amiel, copyright 2020**;
upstream metadata retains author Ronen Amiel, version `0.1.0` and
`types: ./src/index.d.ts`.

This is a usable TypeScript declaration package, not a renamed source snapshot,
CLI, compiler or JavaScript runtime. The unchanged preservation definition
[`ronami-meta-typing-source`](guix/tay/packages/starred-n-r.scm) retains the
same commit, its separate snapshot-origin hash
`183hbcpz3343rgrh0xckdwfg9v0lk2np8hz5aqcdivcf4mz5n7i2` and Expat license.
That source-only ledger and the canonical **629** source snapshots remain
unchanged. Local acceptance does not establish signed channel publication,
issue closure, profile installation or deployment; unrelated dirty work,
including Dualmaster, remains outside this receipt.

### Installed artifact and distinct compiler paths

The accepted output is
`/gnu/store/vbc5d1fdflz8cdbnfxadhy4552d22d86-meta-typing-0.1.0`.
It installs the complete public declaration tree under
`lib/node_modules/meta-typing/src`, preserving relative imports and the actual
root entry point. Upstream `package.json`, `LICENSE`, `README.md` and illustrated
assets are retained, with documentation links under `share/doc/meta-typing`.
Development `.test-d.ts` files and compiler/test-tool dependencies are not
installed into the public library. There is no runtime `main`, generated
JavaScript, executable wrapper or fake runtime module.

[`meta-typing-npm-sources.scm`](guix/tay/packages/meta-typing-npm-sources.scm)
pins **246** npm archives for the Yarn-lock-selected **tsd 0.11.0** transitive
runtime closure and standalone **TypeScript 3.7.4**. Fixed extraction locations
provide Node resolution without npm/Yarn installation, lifecycle scripts,
registry queries or current semver resolution during the build. This is the
test-tool closure, not the entire unrelated lint/watch development graph.

The build checks the complete original source tree with upstream's strict,
`noEmit` `tsconfig.json` using standalone **TypeScript 3.7.4**. The check phase
runs the actual **tsd 0.11.0 CLI and complete unmodified upstream assertion
suite**; tsd carries and uses its own **TypeScript 3.7.2**, unchanged. The
external installed-package consumer separately uses **TypeScript 3.7.4**.
These compiler paths are deliberately distinct: no claim that tsd's assertions
ran on 3.7.4, or that current TypeScript releases are supported, is made.

### Main build and integrated receipts

| Gate | Main receipt |
| --- | --- |
| Source build | Main288 passed in **6.63 s**, producing the accepted output above; artifact `13593`. Strict build and original tsd check phases ran. |
| Reproducibility | Main289 `--check` passed in **4.49 s**, reproducing that same output with both phases; artifact `13594`. |
| Full lint | Main290 exited **0** in **7.11 s**. Package diagnostics were `warning: no tags were found for meta-typing` at `meta-typing.scm:15:2`, and `meta-typing@0.1.0: updater 'github' failed to find upstream releases`, plus known unrelated deprecated `flex`, `nhfourk.scm:171:86` and `winrm.scm:325:1` diagnostics. This is bounded no-new-errors acceptance, **not warning-free lint**. |
| Native installed-package proof | Main292 passed in **7.94 s** at `/tmp/meta-typing-native-1`; actual compiler acceptance, seven exact expected rejection cases, offline isolation and unchanged output are recorded in `evidence.json`. |
| Final integrated target | Main293 `make check-meta-typing` passed in **9.82 s** at `/tmp/meta-typing-check-1`, printing **`META_TYPING_CONSUMER_OK`**. Its `evidence.json` records `status: passed`, `exit_status: 0`, the same output and all seven exact rejection cases. |

The [smoke harness](tests/meta-typing-smoke.sh) requires a canonical,
already-realized store output and a fresh nonexistent absolute evidence
directory outside the store. It does not build or realize Meta Typing. Generic
proof tools and the fixed compiler archive are realized before private user,
mount, network and PID namespaces are entered. The consumer has fresh HOME,
TMPDIR and all XDG roots, only loopback networking, and recursively read-only
`/gnu/store`. Compiler trace resolution and program-file records show that
`import ... from 'meta-typing'` uses the installed store root and declaration
tree, not a checkout, copied declaration tree or consumer-local implementation.
Compilation is strict and `noEmit`, with no `skipLibCheck` exemption.

The independently authored [accepted consumer](tests/meta-typing-consumer/accepted.ts)
checks exact bidirectional type equality and real typed assignments. Arithmetic
proves `Add<2,5> = 7`, `Subtract<8,5> = 3`, `Multiply<2,3> = 6`, integer
`Divide<9,4> = 2`, `Remainder<9,4> = 1` and `Sum<[2,1,4]> = 7`.
MergeSort and QuickSort both produce `[0,2,4,4]`, retaining duplicates;
Uniq produces `[4,0,2]`, retaining first-occurrence order. Membership, first
index and missing index (`-1`), exclusive `Range<2,5> = [2,3,4]`, a partial
final chunk and zipped tuples are asserted. A client-defined unequal-depth
tree distinguishes depth-first `['root','left','twig','right']` from breadth-first
`['root','left','right','twig']`; an empty tree yields `[]`. Two-disc Hanoi
uses named pegs and asserts exactly the three source/spare/target moves.
Empty Head and unsupported `Add<9,2>` both produce `never`.

Each negative case independently exits **1** with only its expected diagnostics,
captured in `rejections.json` and per-case stdout/stderr logs:

- Wrong sum: assigning `8` to the computed `7`, **TS2322**.
- Unsorted result: `[4,0,2]` against computed `[0,2,4]`, three **TS2322** errors.
- Retained duplicate: an extra `4` where Uniq requires `2`, **TS2322**.
- Depth-first ordering supplied for BreadthFirst: swapped `twig`/`right`, two
  **TS2322** errors.
- String in a numeric list: `["2",1]` violates `number[]`, **TS2344**.
- Rounded-up quotient: asserting `Divide<9,4>` equals `3` fails the exact
  equality constraint, **TS2344**. Division itself is accepted and truncates;
  this is not a claim that non-exact division inputs are rejected.
- Unsupported overflow: assigning `11` to `Add<9,2>` (`never`), **TS2322**.

Both Main proof receipts record the identical before/after output NAR hash
**`1pzjji6lgj3yafafadhj7p7j57y5nj2b4cjv84fgbk0ydr6wg5ld`** and
`output_unchanged: true`. The compiler archive's SHA-256 is
`e4f1543efc8d69ed0856b57a909b1786d63dfc3daaaa8056d4f601d98f35daad`.
This proves those installed-root compile-time semantics, not runtime execution,
every algorithm/input, arbitrary recursion depth, unbounded arithmetic or other
compiler versions. Upstream calls the project a learning experiment, not a
practical general-purpose library.

The standalone `make check-meta-typing` accepts `META_TYPING_OUTPUT` and
`META_TYPING_EVIDENCE`, propagates `GUIX`, and does not join aggregate smoke
checks. The consumer worker's unauthorized `guix shell python` probe is **not
Main verification evidence**; no success or check claim rests on that probe.
This documentation worker ran no commands, checks, builds, tests, linters or
formatters. No described host/service or material network-catalog correction
changed, so no OKF page/log update applies to this repository-only delivery.


## Rust Effects — verified offline library and external consumer

Local acceptance on **2026-10-06** covers
[`rust-effects`](guix/tay/packages/rust-effects.scm) **0.1.0-0.d7fe96d**,
the source-built MIT/Expat Rust library from
[kitsuneninetails/rust-effects](https://github.com/kitsuneninetails/rust-effects/tree/d7fe96deb196fed0a222d0d3b796145f78420f39),
revision `d7fe96deb196fed0a222d0d3b796145f78420f39`, with Guix base32 source
SHA-256 `1z3a1g3wvqja9b5gsih5k6z88cx9jnnan96rqyy705x3vxf1lclb`.
The installed license is Michael Micucci's 2019 MIT license. This is a usable
library delivery, not a renamed preservation snapshot, CLI or prebuilt `rlib`
tied to one compiler. The canonical **629** source snapshots and their dated
preservation inventory remain unchanged; local acceptance does not establish
signed channel publication, issue closure or deployment.
The unchanged preservation definition
[`kitsuneninetails-rust-effects-source`](guix/tay/packages/starred-i-m.scm)
pins the same commit, with its separate snapshot-origin hash
`1mxxs22da4jzhhkhmsgk3gqbckq5as091zpqmz4zqwlzbnrl11da` and Expat license.
The buildable package's Git-origin hash above is not substituted into that
canonical source ledger.

### Installed library and offline graph

The accepted output is
`/gnu/store/q68f2gh4pibix1nsid31s1g2p6nnzg19-rust-effects-0.1.0-0.d7fe96d`.
It installs the actual crate source and pinned lockfile under
`share/cargo/src/rust-effects-0.1.0`, the packaged archive at
`share/cargo/registry/rust-effects-0.1.0.crate`, the complete vendored graph
under `share/rust-effects/vendor`, and an absolute-path, offline-only Cargo
source replacement at `share/rust-effects/cargo-config.toml`. A copy of that
configuration lives in the installed source's `.cargo/config.toml`.
Upstream `LICENSE` and `README.md` are retained in `share/doc/rust-effects`.
External consumers need the installed Cargo configuration explicitly when
their working directory is outside that source tree; the proof uses a separate
`[patch.crates-io]` configuration pointing at the installed source.

Upstream supplied wildcard dependencies and no lockfile. Packaging replaces
them with exact constraints: **`futures = "=0.3.32"`**, **`futures-util =
"=0.3.32"`**, and **`tokio = "=1.52.3"`**, preserving Futures' `std` and
Tokio's `full` features. The manifest records Rust **1.86** as the minimum;
the exercised toolchain is the full **Rust 1.93.0**, with explicitly selected
matching **rustdoc 1.93.0** (both report `254b59607`, 2026-01-19), not the
bootstrap-only 1.86 compiler that lacks rustdoc. This receipt does not prove
a build with the declared minimum compiler.

[`rust-effects-cargo-sources.scm`](guix/tay/packages/rust-effects-cargo-sources.scm)
pins **35** registry archives for the full lock graph, including non-host
target dependencies. The installed closure retains these versions:

- `bitflags 2.13.1`, `bytes 1.11.1`, `cfg-if 1.0.4`, `errno 0.3.14`;
- `futures`, `futures-channel`, `futures-core`, `futures-executor`,
  `futures-io`, `futures-macro`, `futures-sink`, `futures-task`, and
  `futures-util`, all **0.3.32**;
- `libc 0.2.189`, `lock_api 0.4.14`, `memchr 2.8.3`, `mio 1.2.1`,
  `parking_lot 0.12.5`, `parking_lot_core 0.9.12`, `pin-project-lite 0.2.17`;
- `proc-macro2 1.0.107`, `quote 1.0.47`, `redox_syscall 0.5.18`,
  `scopeguard 1.2.0`, `signal-hook-registry 1.4.8`, `slab 0.4.12`,
  `smallvec 1.15.2`, `socket2 0.6.4`, `syn 2.0.119`;
- `tokio 1.52.3`, `tokio-macros 2.7.0`, `unicode-ident 1.0.24`,
  `wasi 0.11.1+wasi-snapshot-preview1`, `windows-link 0.2.1`,
  `windows-sys 0.61.2`.

The package installs its retained lockfile after Cargo configure removes the
upstream lock; registry checksum fields are removed under Guix's standard
vendor policy. Build, tests and crate packaging use `--locked`, and the
configured Cargo operation is offline. Cross-target graph completeness is
not cross-compilation or target-runtime acceptance.

### Build and native receipts

| Gate | Main receipt |
| --- | --- |
| Final source build | Main278 passed in 63 s, producing the accepted `q68f…` output above; artifact `13525`. Upstream tests and doctests ran. |
| Reproducibility | Main280 `--check` passed in 56.62 s, reproducing the same output with **63 unit tests and 19 doctests**; artifact `13531`. |
| Full lint | Main281 exited 0 in 7.80 s. Package diagnostics were `warning: no tags were found for rust-effects` at `rust-effects.scm:13:2`, and `rust-effects@0.1.0-0.d7fe96d: updater 'github' failed to find upstream releases`, plus the known unrelated deprecated `flex`, Fourk and WinRM diagnostics. This passes the issue's no-new-errors criterion, **not** warning-free lint. |
| Native installed-source proof | Main279 passed in 61.42 s; `/tmp/rust-effects-native-1/evidence.json` records exit 0, **63 unit tests and 19 doctests**, external metadata/build/runtime success and unchanged output. |
| Final integrated target | Main282 `make check-rust-effects` passed in 50.16 s at `/tmp/rust-effects-check-1`, printing `RUST_EFFECTS_NATIVE_RUNTIME_OK`; the receipt records the same output, **63 unit tests and 19 doctests**, all four runtime observations and unchanged NAR. |

[`tests/rust-effects-smoke.sh`](tests/rust-effects-smoke.sh) requires a canonical,
already-realized output and a fresh absolute evidence directory outside the
store. It does not build or realize the target library: generic proof tools
are realized before entering private user, mount, network and PID namespaces.
The consumer runs with fresh HOME, TMPDIR, Cargo and all XDG roots, an explicit
compiler/linker environment, only loopback networking, and recursively
read-only `/gnu/store`. Metadata proves the dependency manifest is the
installed store source, not the checkout or a consumer-local substitute.
`cargo test --offline --locked` runs the installed upstream unit tests and
doctests; a separate consumer is then compiled with `cargo build --offline
--locked`, without changing its retained lockfile.

The independently compiled
[`consumer`](tests/rust-effects-consumer/src/main.rs) exercises an externally
implemented `FreeEffect`, not merely a built-in map. Composition causes no
dispatch; interpretation logs add/multiply/add, then bind and map in the
expected order, producing **`[6, 5]`**. The Option rejection returns `None`
without executing the following map, and empty Option input bypasses the
closures. A map-only Vec program returns **`[4, 6]`**. The custom async effect
uses a real Tokio timer and yielded bind; `CFuture` stays lazy until awaited,
completes with **26**, and a cloned shared future returns **26** without
re-running the effect trace. The runtime log and observations are retained
alongside copied manifests, lockfiles, compiler versions and namespace/mount
evidence under `/tmp/rust-effects-native-1`.

The output's before/after NAR hash is identical:
`1wvc4aii42m7jbhnncd3aw8nj2jx2hckiibwnjvpc6l0wlr6r0c3`.
The receipt's crate archive SHA-256 is
`1340397ce4fc51a9f31a45eb7c784a3fed8759373bb419384671e52fd4fd4d2d`.
These receipts prove the installed-source offline path and those asserted
effect/future semantics, not every feature, arbitrary consumer dependency
graph, minimum-version build, other target or production workload.

The standalone `make check-rust-effects` accepts `RUST_EFFECTS_OUTPUT` and
`RUST_EFFECTS_EVIDENCE`, propagates `GUIX`, and adds no aggregate smoke-test
dependency. Documentation workers ran no commands or checks. No host/service
state or material network-catalog correction changed, so no OKF page/log update
applies to this repository-only library delivery.


## Blincolnlights — verified native PDP-1 panel and PDP-5 memory path

Local acceptance on **2026-10-06** covers
[`blincolnlights`](guix/tay/packages/blincolnlights.scm) **0-932d2ce**, pinned
to [aap/blincolnlights](https://github.com/aap/blincolnlights/tree/932d2cedfaec3368d6e1890b15645decc4815429)
revision `932d2cedfaec3368d6e1890b15645decc4815429` (no upstream releases),
Guix base32 source SHA-256 `1dq8h2y8hc7avszsb36b5war8cahkiyyig3z1fx7f1fhxb6246s9`.
The non-recursive fetch omits the unused Lua gitlink. The package declares
**MIT/Expat** and installs upstream `LICENSE`, `README.md` and a `README.guix`
state/collision note under `share/doc/blincolnlights`. Only the host SDL
B18/PDP-1/Whirlwind panels, PDP-1/PDP-1-B18/PDP-5/TX-0/Whirlwind emulators and
`mkptyfl`/`mkptyfio` are built; the root Makefile's GPIO, Raspberry Pi,
peripheral and Lua targets are excluded. The original 629 source snapshots and
preservation accounting are unchanged.

| Gate | Main receipt |
| --- | --- |
| Source build | Main223 passed in 14.29 s for `/gnu/store/a6rzkcfvlvhzcia9c5agsv11255z89v9-blincolnlights-0-932d2ce`. |
| Reproducibility | Main224 `--check` passed in 9.65 s, reproducing that output. |
| Lint | Main226 completed with exit 0 in 187.35 s. Its only package diagnostics were no tags/no updater, as upstream has no releases, plus the known unrelated deprecated `flex` symbol, Fourk and WinRM diagnostics. This is not a warning-free whole-channel lint claim. |
| Native panel/emulator | Main225 passed in 45.76 s at `/tmp/blincolnlights-native-1`. |
| Final integrated target | Main227 `make check-blincolnlights` passed in 49.78 s at `/tmp/blincolnlights-check-1`, printing `BLINCOLNLIGHTS_NATIVE_PANEL_MEMORY_OK`. |

The primary final receipt `/tmp/blincolnlights-check-1/evidence.json` has status
`passed`, `exit_status` 0 and driver marker
`deposit/examine/zero/restore/visible-lamps/native-exit`, with empty driver
stderr. Nine actual 800 × 448 `PDP-1 console` window captures, X11 window
records, both `coremem` dumps, emulator/panel/Xvfb logs and mount records
retain the proof. The [external consumer](tests/blincolnlights-native.py)
records the pinned source files behind every control mapping.

The installed `blincolnlights-panel-pdp1` SDL window and normal
`blincolnlights-pdp5` launcher ran under Xvfb with software rendering. Real
X11 mouse clicks on the panel, not shared-memory writes, operated POWER, the
TA switches (PDP-5 switch register), LOAD ADDRESS, DEPOSIT and EXAMINE. The
harness only read the 15-word `/tmp/pdp1_panel` file; it supplied no memory
fixture, injected state or alternate renderer. POWER lit, address octal
`0100` was loaded and word octal **`5252`** deposited. After loading untouched
adjacent address `0102`, EXAMINE showed zero; reloading `0100` with the
switch register **cleared** then examined `5252`. Lamp-image analysis of the
actual window pixels decoded the 18 memory-buffer lamps as the exact
alternating pattern for `5252`, ruling out switch or DEPOSIT residue.

The PDP-5 has no quit command. Upstream's SIGTERM handler calls `exit(0)`,
whose cleanup writes `coremem` and extinguishes lamps; the signal alone is not
the success criterion. Both emulator processes exited **0** and their lamps went
out. The first `coremem` dump in
`$XDG_STATE_HOME/blincolnlights/blincolnlights-pdp5` records `000100: 005252`
and no nonzero `0102`; the launcher's `maindec`/`tapes` links resolve to the
installed data. A second installed-launcher process restored that memory:
`0102` again examined zero, and `0100` with a cleared switch register
displayed exact `5252` lamp bits. The panel closed through
WM_DELETE_WINDOW → SDL_QUIT with exit 0.

The run used same-UID/GID private user, mount, network and PID namespaces with
only loopback, a read-only `/gnu/store`, an empty `PATH` and fresh, initially
empty HOME/XDG directories under a private `/tmp`. The before/after output NAR
hashes match `1cj6v2c3442swjp748115qyph5rx6bvfzxh9a2z4v5vksywkv1db`.
The [genuine final capture](.goocastle/evidence/blincolnlights-native.png) is
the final run's `08-restarted-word-restored.png` (SHA-256
`009f5bcd0a3125f6aa1d8230f65ff91ef52fe6cb10abd7b6ec5b08ae4794af1c`). Main
inspected the legible actual panel: POWER on, the memory-buffer lamps lit and
no visible error. The exact bits come from `panel_memory.visible_mb_bits` and
pixel analysis in the receipt, not inferred from the image.

Limits: only the installed PDP-1 SDL panel with the PDP-5 emulator's power,
switch-register, LOAD ADDRESS, DEPOSIT, EXAMINE and `coremem` restore path is
operated. Other installed panels and emulators are only scope/ELF checked.
No program execution, tape, peripheral, audio, guest TTY, host/tailnet TCP,
GPIO, Raspberry Pi, physical panel or Lua hardware path is established. The
panels use fixed shared files `/tmp/b18_panel`, `/tmp/pdp1_panel` and
`/tmp/whirlwind_panel`, and the emulators listen on fixed TCP ports; these
collide across users or sessions outside isolation, so run one compatible
session per panel and port. The proof confined those paths and the listener
to its private namespaces; the package itself provides no isolation. Normal
use keeps `coremem`/`punch.out` in
`$XDG_STATE_HOME/blincolnlights/blincolnlights-<emulator>` (default
`~/.local/state`). Publication, issue closure and user-profile/system
deployment are not established. No OKF update applies to this
repository-only work.

```sh
out=$(guix build -L guix --no-grafts blincolnlights)
make check-blincolnlights BLINCOLNLIGHTS_OUTPUT="$out" \
  BLINCOLNLIGHTS_EVIDENCE=/tmp/blincolnlights-native-new
```

Both variables are required. The output must be one canonical realized store
item, and the absolute evidence directory must not yet exist and must be
outside the store. The guarded target honors `GUIX` and invokes
[the external smoke consumer](tests/blincolnlights-smoke.sh). This
documentation worker ran no commands or checks and created no capture.

## UC Explorer — verified native microcode parser

### Package and source boundary (2026-10-06)

[`uc-explorer`](guix/tay/packages/uc-explorer.scm) **0.1.0** is a source-built
native CLI for inspecting local Lisp-machine microcode files, with bounded
parser acceptance rather than an emulator or an authentic-ROM claim. Its
upstream pin is
[`larsbrinkhoff/uc-explorer`](https://github.com/larsbrinkhoff/uc-explorer/tree/fc4f9f3324d3497f553512b661ad37cbdde89ccb),
commit `fc4f9f3324d3497f553512b661ad37cbdde89ccb`, with Guix base32 source SHA-256
`1f167p0200283aflm831gvbyzahiwdbsss470cq263dgrinbjqj6`.
The executable package declares **GPL-3.0-or-later** and installs the GNU GPL
text at `share/doc/uc-explorer-0.1.0/COPYING`. The separate, unchanged
`larsbrinkhoff-uc-explorer-source` preservation definition records GPL-3.0.
Its source pin and the **629-source snapshot ledger remain unchanged**.

All **15** registry crate versions in the reviewed upstream `Cargo.lock` are
fixed, hashed source inputs, including its target-specific Windows/Redox graph.
The [exact-version license audit](https://forge.nogroup.group/tay/guix-channel/issues/55#issuecomment-1343)
records MIT for `ansi_term`, `atty`, `clap`, `redox_syscall`, `redox_termios`,
`strsim`, `termion` and `textwrap`; MIT/Apache-2.0 alternatives for `bitflags`,
`libc`, `unicode-width`, `vec_map`, `winapi` and both Windows GNU crates.
The package restores the original lockfile after the generic Cargo configure
phase and supplies each verified archive checksum in the vendored manifest;
build, test and installation use the same graph offline and locked, without
dependency re-resolution. Origin snippets remove the unused prebuilt Windows
GNU `.a` import libraries from `winapi-i686-pc-windows-gnu` and
`winapi-x86_64-pc-windows-gnu` after archive verification, retaining their
manifests/build scripts for locked resolution. This is source removal, not
suppression of the pre-generated-file checker. No prebuilt UC Explorer binary
is used.

UC Explorer was already in the default `PROJECT_PACKAGES` inventory. Acceptance
adds no application definition, research-only promotion count or source
snapshot. The installed-consumer proof is external to the store:
[tests/uc-explorer-smoke.sh](tests/uc-explorer-smoke.sh),
[tests/uc-explorer-native.py](tests/uc-explorer-native.py) and
`make check-uc-explorer` consume a prebuilt output and a fresh evidence path.

### Source build and reproducibility receipt

The integrating agent ran:

```sh
/home/tay/.config/guix/current/bin/guix build -L guix \
  --no-grafts --no-offload --cores=1 --max-jobs=1 --keep-failed \
  -e '(@ (tay packages uc-explorer) uc-explorer)'
```

The final locked source build passed in **471.29 s**. The same invocation with
`--check` added passed in **22.75 s**, identifying the same accepted output:
`/gnu/store/4rs4mcxfwp0pqvqvg8qxcp961iw3f7px-uc-explorer-0.1.0`.
Neither final build reported lock regeneration or pre-generated-file checker
diagnostics. The upstream Cargo test run contains **0 tests**; it is not
represented as parser coverage. Native coverage comes from the external
installed-consumer proof below.

The full lint attempt failed after **42.67 s** (exit **1**) on
`connect*: 141.80.181.40: Connection timed out`; it is **not** a clean lint
receipt. Before that timeout it reported no updater for UC Explorer, alongside
known unrelated repository warnings. The integrating agent's explicitly scoped
non-network lint passed in **7.21 s** with no UC Explorer findings and only
known unrelated warnings, using:

```sh
/home/tay/.config/guix/current/bin/guix lint -L guix \
  --checkers=name,tests-true,compiler-for-target,description,inputs-should-be-native,inputs-should-not-be-input,inputs-should-be-minimal,input-labels,wrapper-inputs,license,optional-tests,mirror-url,source-file-name,source-unstable-tarball,misplaced-flags,derivation,profile-collisions,patch-file-names,patch-headers,formatting,synopsis \
  uc-explorer
```

That bounded checker result does not establish completion of the timed-out
network-dependent lint checks.

### Actual installed native evidence

The initial native run passed in **3.06 s**, with retained evidence at the
actual path `/tmp/uc-explorer-native-1`. The final integrated
`make check-uc-explorer` passed in **8.23 s** at `/tmp/uc-explorer-check-1`.
Both emitted:

```text
UC_EXPLORER_NATIVE_OK minimal=version:0x0001,lengths:0 populated=a3,b1,c1@00102,type3,pico255 malformed=18 deterministic=true
```

The `evidence.json`, `runtime.json`, `runs.json`, per-invocation stdout/stderr
and NAR records—not the marker alone—establish these semantics:

- The minimal format fixture decoded version **0x0001**, an empty comment and
  zero A-memory, B-memory, C-memory, type-map and pico-store lengths.
- The populated fixture decoded version **0x1234**, comment **UCXé**, A-memory
  **3**, B-memory **1**, C-memory **1**, type-map **3** and pico-store **255**.
  Its C-memory address was **00102** (octal). The 112-bit control word decoded
  `A Mem Read Address` **801**, `U COND FUNC` **0**, `U ALU` **10**, `U NAF`
  **828** and `U AU OP` **166** (decimal field values), covering both halves of
  the little-endian word and its byte-8 split.
- **18 malformed/truncated format fixtures** produced detected parse failures
  on stdout, with section reasons or read errors. Upstream deliberately exits
  **0** on these parse failures; the harness checks the failure text and absence
  of successful decoded state rather than falsely requiring a nonzero status.
  A missing file named its path on stderr and exited **1**; a missing required
  argument produced stderr and a nonzero status.
- Repeated valid invocations produced deterministic output. The installed ELF
  ran as the caller's **UID 1000/GID 998** in separate user/mount/network/PID
  namespaces, with only loopback and a read-only `/gnu/store`; it did not run
  as namespace root. Output scope/mode checks remained successful.
- Before and after both native runs, the output NAR hash was
  `1jiwfvi7wmy7x20r4mpvvdh0rqhghmkni1acqjqjyr7s1kjl4k9c`.
  The output was unchanged, and both the proof and its final output check
  exited **0**.

### Acceptance limits

The fixtures are original synthetic inputs conforming to the pinned parser
format, not authentic Symbolics microcode, copyrighted ROM redistribution,
machine execution or emulation evidence. Only A/B/type-map/pico-store counts
are observable in upstream's display; their contents are not printed. The
parser does not check bytes following section 8. This receipt establishes the
installed native parser's stated semantics and errors, not broader ROM
compatibility. No host/service deployment or material OKF network-catalog
correction occurred, so no OKF page or log update applies.

## Tassh — verified isolated native clipboard relay

### Package and source boundary (2026-10-06)

[`tassh`](guix/tay/packages/drbeefsupreme/tassh.scm) **20260228-1.672569a** is an
installable, source-built Rust CLI/daemon for `x86_64-linux`, not just a research
definition or preservation snapshot. Its MIT-licensed upstream is
[`drbeefsupreme/tassh`](https://github.com/drbeefsupreme/tassh/tree/672569a55e6f2a0ae4274103a99b8b9abac87f4d),
commit `672569a55e6f2a0ae4274103a99b8b9abac87f4d`, with Guix base32 source SHA-256
`1r14hx37jz04cvjljc8vy063qy10sy8lmlaxsn2ckmxafl6qhw7y`. The package supplies
all 181 external registry records from the upstream Cargo.lock as hashed source
inputs, retains the locked dependency graph and builds/installs offline. The
installed `share/doc/tassh/LICENSE` and `third-party-licenses/` retain upstream
and statically linked dependency notices. No prebuilt Tassh executable is used.

The independent `drbeefsupreme-tassh-source` output continues to preserve source
under `share/drbeefsupreme/projects/tassh`; it does not provide a CLI. The
**629-source snapshot ledger is unchanged**. Native acceptance does not add
Tassh to `PROJECT_PACKAGES` or the default `make build` inventory. Its external
installed-consumer entry point is [tests/tassh-smoke.sh](tests/tassh-smoke.sh),
with [tests/tassh-native.py](tests/tassh-native.py) and `make check-tassh`.

### Build and reproducibility receipt

The integrating agent ran the following source build, then the same invocation
with `--check` added (not a substitute-only realization):

```sh
/home/tay/.config/guix/current/bin/guix build -L guix \
  --no-grafts --no-offload --cores=1 --max-jobs=1 --keep-failed \
  -e '(@ (tay packages drbeefsupreme tassh) tassh)'
```

The build passed in **499.98 s**; the `--check` rebuild passed in **435.89 s**.
Both identify the accepted output:
`/gnu/store/yam5xcyjzf3ny2xr2qwz3bnxcrqpqk6q-tassh-20260228-1.672569a`.
The recorded lint invocation exited zero in **5.56 s**, but this is not a
warning-free lint claim: Tassh's reported warnings concern missing tags/upstream
releases, with unrelated existing repository warnings also reported.

### Actual installed native evidence

The initial successful consumer run is retained at `/tmp/tassh-native-2`
(**14.48 s**). The final integrated `make check-tassh` run passed in **12.16 s**
at `/tmp/tassh-native-3`. Both emitted:

```text
TASSH_NATIVE_LOOPBACK_CLIPBOARD_OK x11=true inject=true wayland=true fixture_backed=true
```

The final `evidence.json`, `isolation.json`, `*.process.json`, `commands.json`,
`transfers.json` and captured PNGs—not the marker alone—establish these results:

- The installed output's CLI and daemons used separate temporary HOME/XDG trees,
  with source and receiving endpoints at `127.0.0.1` and `127.0.0.2`, port 19987.
  Source daemon PIDs 195 (X11) and 352 (Wayland), and receiver PID 167, ran in the
  recorded user/mount/network/PID namespaces as UID 1000/GID 998. The only network
  interface was loopback, there were no routes, `/tmp` and `/run` were private,
  and `/gnu/store` was mounted read-only.
- Real Unix-socket `notify`, `status` and `inject` IPC registered peers and
  relayed images over real loopback TCP. X11 clipboard observation used
  Xvfb/xclip. Wayland clipboard observation used real Sway 1.12 (PID 347), a
  headless backend with the pixman renderer and a seat, plus wl-copy/wl-paste;
  received PNGs were read from the receiving daemon's X11 clipboard with xclip.
- Three distinct generated 1×1 RGBA PNGs each arrived as exactly **70 bytes**,
  with equal expected/received SHA-256 and successful clipboard reads:

| Native transfer | Expected and received SHA-256 |
| --- | --- |
| X11 clipboard watch | `4ff6ab670a58c14270e034e2090d9a432caa263a14e0a25785386b0c12f880b5` |
| CLI inject | `619b0e8b0c8741604b8628c64323444df334846a0dfe13963662586a3603f14c` |
| Wayland clipboard watch | `6a34118ba2e0bf5da5ab14cb63b121e2e8b2987a876668a9b2f9c30e1357470b` |

- The monitored lifetime PIDs 221 and 378 were real `sleep` processes, not SSH
  sessions. Their exits triggered peer cleanup; final status returned
  `daemon running, no active connections`. Cleanup reaped the daemon/compositor
  processes, and `remaining-processes.json` was `[]`.
- The output NAR hash was identical before and after both successful runs:
  `155vqz4nqcf8mxrc143i3rqxw6hmhw2x3n964xqf1j34vn0q95p5`. Post-run checks of
  installed license/notices and read-only output modes exited zero. The consumer
  did not modify or rebuild the accepted package output.

### Fixture and operational limits

The Tailscale resolver was an explicit fixture supporting only `tailscale ip -4`
and returning the selected loopback address. `systemctl`/`loginctl` fixtures
recorded setup requests and returned success without running a service manager.
`setup daemon --yes --port 19987` wrote a unit pointing to the installed wrapper,
an SSH LocalCommand stanza and shell display hooks **only in a temporary HOME**.
This proves generated setup material, not systemd-user activation or linger.

**No live Tailscale, authenticated SSH, systemd-user, physical desktop-session
or cross-host integration was established.** The upstream relay is PNG-image
only; native loopback acceptance must not be read as an authenticated-network
security review. The wrapper supplies Xvfb, xclip, wl-clipboard and other package
tools while preserving the caller PATH for host commands. Real use requires
operator-provided Tailscale/OpenSSH configuration and a suitable clipboard
session. `tassh setup daemon` mutates user configuration and invokes host
service-manager commands; it is a systemd-user convenience, **not a Guix
service**, and installation/building does not activate it.

These are repository/package receipts, not publication or deployment claims.
No described host/service changed, so no OKF page or catalog log update applies.
The documentation worker ran no commands or checks; the reported verification
was performed by the integrating agent.

## Affect — native libraries and isolated OCaml 5.5 toolchain

[`affect`](guix/tay/packages/affect.scm) **0.0.0-0.780faa2** is the full
source-built library package, not a renamed preservation snapshot. It reuses
the ISC-licensed [`dbuenzli/affect`](https://github.com/dbuenzli/affect/tree/780faa266d62f9567fd9d23f84bddc77f77087c0)
revision `780faa266d62f9567fd9d23f84bddc77f77087c0` and the exact origin of
`dbuenzli-affect-source`, with Guix base32 SHA-256
`1ngs4g3si1nf2jknh5jwz146gw8hy7g1fkjz623r5nvgr56pc9bi`.
The existing source-snapshot package and 629-source preservation ledger are
unchanged. Version watermarking is confined to the private build's `pkg/META`;
the installed external quick-start/CLI example sources retain the original
snapshot bytes.

The installed findlib surface contains **all four libraries**: `affect`
(structured async functions, actions, parallel execution and cancellation),
`affect.unix` (cooperative Unix I/O and native time stubs), `affect.tmp`
(upstream temporary networking API), and `affect.cli` (Cmdliner integration).
Bytecode archives, native archives and native dynlink plugins are installed,
alongside interfaces and sources. Cmdliner is propagated; the optional CLI
component is enabled rather than omitted. `doc/affect` retains the README,
changelog, ISC notice and odoc source pages. `share/affect` records the source
commit and exact consumer compiler/Findlib/Cmdliner outputs and supplies the
unmodified quick-start and CLI examples. This is a library package, not a
standalone `affect` command; the CLI proof runs upstream's example consumer.

### Compiler-matched source closure

[`ocaml-affect-toolchain.scm`](guix/tay/packages/ocaml-affect-toolchain.scm)
exports five isolated definitions. They do **not** replace the channel's
default OCaml compiler or change the ABI of Notty, Miou, Domainslib or other
existing OCaml packages. Affect requires OCaml **at least 5.5.0** and Cmdliner
**at least 2.0.0**; consumers must use the recorded matching compiler, not the
distribution's default compiler.

| Definition | Version and source | Guix base32 SHA-256 |
| --- | --- | --- |
| `ocaml-affect` | `5.5.0`, [complete official INRIA distribution](https://caml.inria.fr/pub/distrib/ocaml-5.5/ocaml-5.5.0.tar.gz) | `0xx4fc2xi6mxx1y8sc38vfk8iddsfp2xp3mgs1f36hysmg13g58s` |
| `ocaml-findlib-affect` | `1.9.8-1.1faecd4`, [exact upstream revision](https://github.com/ocaml/ocamlfind/tree/1faecd4016c615e1d8806643c8e4eb3d08dcdf97) `1faecd4016c615e1d8806643c8e4eb3d08dcdf97` | `124dkqsqdvsymvlzbqgidlrq0grhb6w6bnnrwb59c1dw0f08pzbz` |
| `ocamlbuild-affect` | `0.16.1`, [exact upstream revision](https://github.com/ocaml/ocamlbuild/tree/131ba63a1b96d00f3986c8187677c8af61d20a08) `131ba63a1b96d00f3986c8187677c8af61d20a08` | `1jhrga6v51pfyyli4z3hcrvr3hk0mkxbdp3y22f4dcks09jcahjy` |
| `ocaml-topkg-affect` | `1.1.1`, [official release archive](https://erratique.ch/software/topkg/releases/topkg-1.1.1.tbz) | `1z7n2abmabc018b60ck41qqmfg9yxn3cj8lgf9f1p8nfr4nhdni0` |
| `ocaml-cmdliner-affect` | `2.1.1`, [official release archive](https://erratique.ch/software/cmdliner/releases/cmdliner-2.1.1.tbz) | `1dnn42hhmndlgk32m3yr3r1i0ic348l9iwbqh53lrxglvv8kif85` |

The compiler uses stable OCaml 5.5.0, not a development snapshot. The source
selection was corrected from a GitHub archive to the complete official tarball:
GitHub export archives omit the compiler testsuite and manual, so they cannot
satisfy the inherited compiler check phase. The definition preserves Guix's
source bootstrap, compiler tests and search paths, explicitly enables zstd
compressed compilation artefacts, and records the release's LGPL-2.1 license
with its OCaml linking exception rather than obsolete inherited QPL metadata.
The actual build126 compiler log ran `make -C testsuite parallel`: **1,501
passed, 55 skipped, zero failed, zero unexpected errors**, out of 1,556 tests
considered; the check phase succeeded in 109.2 s. This is not a claim that
every compiler test ran without inherited exclusions or upstream skips.

Released Findlib 1.9.8's opam constraint excludes OCaml 5.5. The exact pinned
adaptation in upstream [PR #122](https://github.com/ocaml/ocamlfind/pull/122)
was **unmerged at this task's source review**. It updates topfind generation
and relative `ld.conf` handling; this is an explicit source dependency, not
a claim that released 1.9.8 supports this compiler or a suppression of loader
warnings. OCamlbuild 0.16.1 includes the
[PR #325](https://github.com/ocaml/ocamlbuild/pull/325) Digest interface fix:
`Digest.channel` is a value, not the obsolete `caml_md5_chan` external.
Topkg 1.1.1 is the build library only, not the separate `topkg-care` package;
its obsolete Result dependency is removed. Cmdliner 2.1.1 builds with its own
source bootstrap Makefile and installs the library, tool, completions and
documentation; its release license is ISC, not the older BSD metadata.
The toolchain's inherited per-package test policies are not evidence that
Findlib/OCamlbuild/Cmdliner's full development suites ran.
Topkg's native `test/test.native` was actually compiled and run in build126;
its check phase printed `The test is ok` and passed in 1.0 s.

### Dated native evidence and scope

On **2026-10-05**, Main's final build130 passed for derivation
`/gnu/store/411g1r7d3d41j1wazs939y60ks5g77s2-affect-0.0.0-0.780faa2.drv`,
output `/gnu/store/6cpafq23pxb79kiazck90ccf8k5n9wgv-affect-0.0.0-0.780faa2`.
This supersedes the earlier build126/native127/check128 output identity after
the toolchain's input labels and package metadata were corrected. The Affect
build check compiles and runs the
four standalone offline upstream programs `quick_start`, `blueprint_minimal`,
`blueprint_minimal_unix` and `blueprint_cli`. The separate **B0_testing and
full stress suites were not run**, and no such coverage is claimed.

Main's serial all-six `guix build --check`132 passed in **423.46 s**. Affect
and each of its five isolated toolchain packages were rebuilt and matched
their existing outputs; this is bit-identical local rebuild evidence, not
substitute/publication or deployment evidence. In addition to Affect and the
three recorded consumer dependencies below, the matching build-only outputs
are `/gnu/store/q5rcf8b0q2jkyjwb0pswy13qaf1ppj5p-ocamlbuild-affect-0.16.1`
and `/gnu/store/1xwhvslk9rnyw7y7rsz8ahms8yl4nw2s-ocaml-topkg-affect-1.1.1`.

Main's final six-package lint133 command completed successfully in **24.04 s**,
but **was not warning-free**. Remaining scoped diagnostics concern Software
Heritage archival status for all six sources and automatic-refresh metadata:
the compiler's generic-HTML updater found no releases, Findlib has no updater,
and the renamed OCamlbuild/Topkg/Cmdliner package names are not found in opam.
Actionable input-label, long-line, redundant `#:tests? #t` and description
spacing findings were corrected, not suppressed. The run also reported
unrelated repository load/deprecation warnings (deprecated `flex`, Fourk and
the excluded WinRM module); these are not Affect/toolchain acceptance claims
or changes owned by this addition.

Main's integrated `make check-affect` profile-native136 passed in **10.25 s**
with `AFFECT_NATIVE_RUNTIME_OK`, evidence `/tmp/affect-profile-native-3`,
superseding native131's manually constructed consumer environment. The harness
actually installs Affect, its recorded compiler/Findlib/Cmdliner and GCC 14.3.0
in an evidence-owned temporary Guix profile using the real package objects in
[`tests/affect-profile-manifest.scm`](tests/affect-profile-manifest.scm).
Package objects preserve native search-path metadata; raw store-item installs
do not. The generated `etc/profile` is sourced in an empty inherited environment,
with **no manual OCAMLPATH, OCAMLLIB or stub-path workaround**. Profile exports
provide `PATH`, `OCAMLPATH` and `CAML_LD_LIBRARY_PATH`; `OCAMLLIB` remains unset.
The installed manifest and public executable/library discovery are checked
against the exact prebuilt store identities, including all four Affect findlib
libraries and Cmdliner 2.1.1. Compiler and Findlib both select OCaml 5.5.0;
the harness compiles three genuine native ELF consumers outside the build tree:
the original quick-start (result `3`), original CLI blueprint (plain help and
`-P 2`), and an actual API consumer. At both **one and two domains**, that
consumer exercises 100 yielding async jobs (sum 5,050), child-exception
propagation, cooperative pipe read/write and EOF, cancellation of a genuinely
blocked pipe read, execution of its protected finalizer, and `EBADF` from both
readable and writable watchers on a closed descriptor.

The final output records these exact compiler-matched consumer dependencies:

- OCaml: `/gnu/store/z4nnc6wbcp1ihmwcf0lq5wkhnp6igvnz-ocaml-affect-5.5.0`.
- Findlib: `/gnu/store/s8p96bwigx7kiy95dwb600c7szvzjl4h-ocaml-findlib-affect-1.9.8-1.1faecd4`.
- Cmdliner: `/gnu/store/vpwxzv76nrmxqfv8j8frpyd104pq2icz-ocaml-cmdliner-affect-2.1.1`.
- GCC: `/gnu/store/5sh58d0kdqc8kbq4i3bzvd8zbph2jfnc-gcc-toolchain-14.3.0`.

The actual temporary profile resolves to
`/gnu/store/vxwi0aq2ygmind3zy5qsgi0cc8lihw6v-profile`; retained
`profile-installed.txt`, `profile-environment.sh`, `profile-discovery.json`
and `evidence.json` record installation, generated exports and observed native
execution. This changes no user profile or profile generation.

The run uses private network/PID namespaces, only loopback, temporary
HOME/XDG paths and a read-only store while preserving UID/GID. Before/after
output NAR hashes match
`0v87ag5k15ygggydvh2d7bz6i508whl3f30h3njq6b2ppz0ahg5x`.
`affect.tmp` is installed, resolved and included in native consumer linking;
this evidence does **not** establish external networking interoperability or
full temporary-networking runtime coverage. No user-profile/system deployment,
host/service change or material network-catalog correction is established;
no OKF page/log update applies to this repository-only addition.

### Local build and consumer checks

Use the isolated definitions together; mixing another OCaml ABI with the
installed Affect interfaces is not supported. For an application `app.ml`:

```sh
guix build -L guix --no-grafts affect
guix shell -L guix -m tests/affect-profile-manifest.scm -- \
  ocamlfind ocamlopt -thread -package affect.unix,affect.tmp,affect.cli \
  -linkpkg -o app app.ml
./app
```

`make check-affect` consumes a prebuilt output and requires an absolute, fresh
nonexistent evidence directory. It installs an evidence-owned temporary profile
from the package-object manifest, verifies its contents against the exact
store-backed toolchain recorded by that output, and sources Guix's generated
environment before offline native compilation and execution. It neither
changes the user's profile nor hand-assembles compiler/library search paths.

```sh
out=$(guix build -L guix --no-grafts affect)
make check-affect AFFECT_OUTPUT="$out" AFFECT_EVIDENCE=/tmp/affect-native-new
```

These commands document the existing build/harness interfaces; this
documentation worker ran no commands, checks, cleanup or signals.

## PDP10 XPL — verified native compiler object semantics

Local acceptance on **2026-10-05** covers
[`pdp10-xpl-pdp-10`](guix/tay/packages/pdp10-xpl.scm) **0-0e57cbd** at
[PDP-10/xpl-pdp-10](https://github.com/PDP-10/xpl-pdp-10/tree/0e57cbd9e2e2997134332f6784dccc262a069d99)
revision `0e57cbd9e2e2997134332f6784dccc262a069d99`. Its private XPL-to-C
bootstrap **1.4** comes from
[SourceForge](https://sourceforge.net/p/xpl-compiler/code/ci/643907731538b4e2256f11c48e3166bf5bb2609c/tree/)
revision `643907731538b4e2256f11c48e3166bf5bb2609c`, source NAR SHA-256
`10pf9s43wrhv7xb7ajagwkgdxnbayllzvlf53lzq48yv8m6k2c0a`. Both upstream
trees carry **Free Public License 1.0.0**; the compiler/bootstrap are
source-built, not fetched executable compilers. The original 629 source
snapshots and preservation accounting are unchanged.

| Gate | Main receipt |
| --- | --- |
| Source build | Main200 passed in 5.61 s, including the source-only bootstrap, for `/gnu/store/4n66bbvgfin0f4qhnsllanzcc2ynaqpp-pdp10-xpl-pdp-10-0-0e57cbd`. |
| Reproducibility | Main201 paired Apout/XPL `--check` passed in 3.68 s, reproducing both outputs. |
| Lint | Main202 completed in 8.34 s with no-updater and Software Heritage/Disarchive notes plus known unrelated deprecated `flex` symbol, Fourk and excluded WinRM diagnostics. This is not a clean-lint claim. |
| Integrated native compiler | Main205 `make check-pdp10-xpl-pdp-10` passed in 6.04 s at `/tmp/pdp10-xpl-native-2`, printing `PDP10_XPL_NATIVE_OBJECT_OK`. |

The primary `/tmp/pdp10-xpl-native-2/evidence.json` has status `passed` and
explicit scope **installed-compiler REL semantics, not PDP-10 execution**.
The supplied normal installed compiler ran
`xpl -K -o hello.rel /gnu/store/4n66bbvgfin0f4qhnsllanzcc2ynaqpp-pdp10-xpl-pdp-10-0-0e57cbd/share/pdp10-xpl/hello.xpl`
and exited 0 with empty stderr. Its input is the exact pinned, installed
upstream source `output = 'Hello world!';` followed by `eof;`, not a substituted
frontend or driver-generated object. The actual compiler log says no errors
were detected. Its wall-clock listing header is not used as a reproducibility
oracle.

The source-backed [REL observer](tests/pdp10-xpl-native.py) decoded the actual
**2,565-byte / 570-word** object, SHA-256
`887a3d63815a24a4914cce45a93186c6d2204e39fad973f402f687075cf95b5c`.
It validates packed pairs of **36-bit words**, block tags/lengths and
relocation bitmaps, the `HELLO` module name, high-segment definition, START
and END records, internal relocation requests and the external **`XPLLIB`**
symbol reference. Object observations retain **353 code words, 73 emitted
data words and 34 internal requests**; these are decoded emitted words, not a
claim that the compiler's larger allocated-data statistic is an emitted REL
payload count. Entry is octal `400163`, code end `400541`, data end `1131`.

The observer finds a length/address descriptor for the exact **9-bit
`Hello world!`** string, checks that generated code loads it into register 1
for `.outp.` at octal `400537` (descriptor `1130`), and that the final emitted
instruction is `.exit.`. `rel-observation.json`, `hello.rel`, copied exact
input and actual compiler stdout/stderr retain the evidence. This is object
structure/semantics inspection, **not executing those instructions or
resolving `XPLLIB` through a linker**.

The native host compiler ran in private same-UID/GID user, mount, network and
PID namespaces, loopback only and `/gnu/store` read-only. Before/after output
NAR hashes match
`1v3fmnw5wz4y6p2i7iqqb67pcc4wlfm7yin5aigka2c2wkzkwbm9`.
No PDP-10 executor, guest runtime, alternate compiler or mocked object was
used. Limits: no PDP-10 program execution, linked runtime, guest operating
system or GUI behavior is established. Publication, issue closure and
user-profile/system deployment are not established here. No OKF update
applies to this repository-only work.

```sh
out=$(guix build -L guix --no-grafts pdp10-xpl-pdp-10)
make check-pdp10-xpl-pdp-10 PDP10_XPL_OUTPUT="$out" PDP10_XPL_EVIDENCE=/tmp/pdp10-xpl-native-new
```

The guarded target requires both variables and honors `GUIX`; its external
smoke consumer requires a **fresh nonexistent evidence directory** outside
the store/output and uses the pre-realized supplied compiler. This
documentation worker ran no commands or checks.

## PDP10 GCC — verified assembler-free C code generation

Local acceptance on **2026-10-06** covers
[`pdp10-gcc`](guix/tay/packages/pdp10-gcc.scm) **3.2-20020416**, built from
[`larsbrinkhoff/pdp10-gcc`](https://github.com/larsbrinkhoff/pdp10-gcc/tree/3c67a2b56b8a02041bdfca00d012bcccbe4168e5)
commit `3c67a2b56b8a02041bdfca00d012bcccbe4168e5`. It reuses the immutable
`larsbrinkhoff-pdp10-gcc-source` origin, source SHA-256
`1ll89jjpfxfxr4fvxmx5yrjyxhp1zscrj0w2dbirgzr5rm3r9p8c` (Guix base32),
without repinning or altering that preservation definition. The **629-source
snapshot ledger is unchanged**. This promotes an existing research definition
to a bounded native compiler delivery, not a new default inventory member:
`pdp10-gcc` remains outside `PROJECT_PACKAGES` and the default `make build` list.

The supported host is **`x86_64-linux`** and target is
**`pdp10-unknown-tops20`**. The source-built native GCC driver, standalone
preprocessor, private `cc1` and specs can preprocess freestanding C and emit
TOPS-20 **MACRO assembly text with `-S`**. The package contains no target
assembler, linker, headers, C library, `libgcc` target archive, guest operating
system or executable runtime. Host GCC/binutils are build inputs for the native
compiler programs, not target-tool fallbacks in the installed consumer.

The pinned-tree license audit records `COPYING`/`gcc/COPYING` **GPL-2.0**,
`COPYING.LIB`/`gcc/COPYING.LIB` **LGPL-2.1**, `libffi/LICENSE` **Expat/MIT**, the
**zlib** notice in `zlib/zlib.h`, and the **Boehm GC permissive notice** in
`boehm-gc/doc/README` (including copyright/notice retention and modified-code
disclosure). The package license list reflects these notices instead of
treating the whole bundled tree as GPL alone. The historical libgcj GPL linking
exception is retained as `libjava/LIBGCJ_LICENSE`; retaining its notice does
not install Java or a target runtime. Installed notices under
`share/doc/pdp10-gcc-3.2-20020416/` are `COPYING`, `COPYING.LIB`, `README`,
`LICENSE`, `zlib.h` and `LIBGCJ_LICENSE`, all checked by the native consumer.
This is the bundled-notice audit, not a claim that every bundled library is
built or linked into the installed compiler.

The recipe fixes actual legacy-source/build causes rather than suppressing
diagnostics: GNU89 is used for the K&R-era configure probes; obsolete cast
post-increment in `obstack.h` is replaced by explicit pointer advancement;
`CONFIG_SHELL` supplies the store shell; and **all generated `tmpmultilib`
shebangs** inside `gcc/genmultilib` are patched, not merely the generator's own
shebang. The preserved GNU-as backend branch lacks helpers needed by this
revision, so `--with-as=macro` selects the self-contained MACRO dialect. The
recursive `all-gcc` goal is constrained to `start.encap`, avoiding target
`libgcc.a` and its assembler dependency; installation keeps only the compiler
components rather than invoking legacy target-header `fixincludes`.

Crucially, selecting the MACRO dialect formerly also emitted
`DEFAULT_ASSEMBLER="macro"`. GCC's driver tried that relative executable in
the working directory before restricted PATH lookup. The earlier native-1
probe caught a deliberately successful cwd `macro` trap. The fix removes the
`DEFAULT_ASSEMBLER` **definition emitter in `gcc/configure` before configure**,
while preserving `gcc_cv_as` for dialect selection, so `config.status` cannot
regenerate the unsafe default. The prior end-anchored replacement had been a
no-op because Guix `substitute*` retains the line's terminating newline;
`[^\n]*` now matches the definition without relying on `$`. The installed
wrapper restricts `PATH` to this output's `bin` and `GCC_EXEC_PREFIX` to its
private `lib/gcc-lib`, preventing normal host `as`/`ld` fallback too.

| Gate | Main receipt |
| --- | --- |
| Source build | Main244 final source build passed in 35.41 s for `/gnu/store/qsg5lrp6mwapr8y8390qjwv26p6m7d4q-pdp10-gcc-3.2-20020416`. |
| Reproducibility | Main247 final serial `--check` passed in 33.35 s, reproducing the same `qsg5lrp…` output. |
| Full lint | Main246 exited 0 in 4.94 s with no recipe line-length findings. It reports no updater, source not archived on Software Heritage and missing from Disarchive; known unrelated deprecated `flex`, `nhfourk` unexpected `)` and excluded WinRM unexpected EOF diagnostics remain. This is not a clean-lint claim. |
| Actual installed consumer (pre-formatting identity) | Main240 passed in 3.32 s at `/tmp/pdp10-gcc-native-2` for `/gnu/store/l2sg1fc4cgrpkksqz1fj3fqz5rf6mckg-pdp10-gcc-3.2-20020416`, printing the bounded code-generation marker. |
| Final guarded Makefile/native integration | Main245 `make check-pdp10-gcc` passed in 4.79 s at `/tmp/pdp10-gcc-check-final` with the final `qsg5lrp…` output and `PDP10_GCC_NATIVE_CODEGEN_OK (not assembly/link/runtime)`. |

Wrapping the recipe's long expression for lint changed its derivation/output
identity despite leaving the patched source expression's value unchanged. The
earlier `/tmp/pdp10-gcc-native-2/evidence.json` remains an actual native receipt,
not the final output identity. Final integrated evidence is
`/tmp/pdp10-gcc-check-final/evidence.json`, with status `passed` and explicit
scope **real native cross-GCC preprocessing and `-S` code generation only**.
Both runs' assembly observations have the same SHA-256 below. On the final
output, the normal installed `pdp10-unknown-tops20-cpp -P codegen.c codegen.i`
and `pdp10-unknown-tops20-gcc -S -O0 -ffreestanding -fno-builtin -mregparm=7
codegen.c -o codegen.s` both exited 0 with empty stdout/stderr. The C input
contains a compile-time `sizeof(int) == 4` target-byte check, arithmetic
`(a+b)*c-b`, and a signed countdown loop adding `n` below 4 and subtracting it
otherwise. This is real compiler output, not observer-generated assembly.

The source-backed [assembly observer](tests/pdp10-gcc-native.py) checks complete
MACRO `TITLE codegen`/`END`, both exported function bodies, `ADD`/`IMUL`/`SUB`,
signed `JUMPG`/`CAILE`, the loop's `ADDM`/`SUB`/`SOS`, resolved local labels and
a backward `JRST %3`, and `POPJ 17,` returns. The retained actual `codegen.s`
SHA-256 is `9cb577fd93712d69fa6a2281bf913a008877fd8314b8c5b481de1349bc08bde6`.
`assembly-observation.json`, exact `codegen.c`/`codegen.i`, compiler
stdout/stderr and command records preserve the structural evidence. This is
**not assembling the text, interpreting instructions or proving executed
arithmetic/control-flow semantics**.

The negative probes use self-tested, deliberately successful trap executables
named `as`, `ld`, `collect2`, `pdp10-unknown-tops20-as` and
`pdp10-unknown-tops20-ld` on hostile PATH, plus `macro` in the compiler cwd.
Their setup invocations establish the marker mechanism; they are **not real
target tools or replacement compilers**. None was invoked by successful `-S`
or either unsupported operation. `-c codegen.i -o codegen.o` exited **1** with
`installation problem, cannot exec 'as': No such file or directory`;
`-nostdlib -nostartfiles opaque.o -o codegen` exited **1** with the analogous
missing `ld` diagnostic. The retained `.stderr` files use GCC's original
backtick/apostrophe quoting. Neither operation produced its output or a trap
marker, and neither failed by a compiler crash. `opaque.o` is explicitly
**opaque lookup-fixture bytes, not an assembled PDP-10 object**: it bypasses
compilation solely to reach unavailable linker lookup, not to claim linking.

The consumer runs with caller **UID 1000/GID 998**, private user/mount/network/
PID namespaces, only `lo`, fresh HOME/TMPDIR/XDG directories, no inherited
compiler environment and recursively read-only `/gnu/store`. Before/after
final output NAR hashes both equal
`05dgyzzla52zmq1z0awyfc97pc6pasj3rhxjqbzaaa3kdd3w308s`.
The earlier native-2 output was also unchanged before/after its consumer run,
with its distinct NAR hash
`0c4mwjgdy55vdjf7ahxfb5g97fj1yha0lrypbdslq0gp3ny4466r`.
The external [smoke entry point](tests/pdp10-gcc-smoke.sh) consumes a supplied
pre-realized output; it never builds or repairs that compiler in place.

```sh
make check-pdp10-gcc PDP10_GCC_OUTPUT=/gnu/store/qsg5lrp6mwapr8y8390qjwv26p6m7d4q-pdp10-gcc-3.2-20020416 PDP10_GCC_EVIDENCE=/tmp/pdp10-gcc-native-new
```

The guarded target honors `GUIX` and requires both variables; the evidence
path must be fresh, nonexistent, absolute and canonical outside the store.
No upstream suite, target assembly/linking/PDP-10 execution, publication,
issue closure or user-profile/system deployment is established. No OKF page
update applies to this repository-only acceptance. This documentation worker
ran no commands or checks.

## Apout — verified native V7 guest contract

Local acceptance on **2026-10-05** covers [`apout`](guix/tay/packages/apout.scm)
**0-bd9af21**, pinned to [DoctorWkt/Apout](https://github.com/DoctorWkt/Apout/tree/bd9af21bd8bb2fa956dcda5db0b0aeec2cffc8f7)
revision `bd9af21bd8bb2fa956dcda5db0b0aeec2cffc8f7`. The original 629 source
snapshots and preservation accounting are unchanged. The normal installed
native emulator runs original, locally assembled lawful V7 PDP-11 programs;
no historical executable, firmware or guest filesystem is obtained or
redistributed for the proof. The source-backed guest generator and octal
listings are retained by [the native consumer](tests/apout-native.py).

| Gate | Main receipt |
| --- | --- |
| Source build | Main199 passed in 4.38 s for `/gnu/store/vsnpxnqkydvldxsilw78l3iz9j1vxic5-apout-0-bd9af21`. |
| Reproducibility | Main201 paired Apout/XPL `--check` passed in 3.68 s, reproducing both outputs. This does not establish XPL runtime behavior. |
| Lint | Main202 completed in 8.34 s with no-updater and Software Heritage/Disarchive diagnostics, plus known unrelated deprecated `flex` symbol, Fourk and excluded WinRM diagnostics. This is not a warning-free lint claim. |
| Native guest | Main203 passed in 3.40 s at `/tmp/apout-native-1`: two deterministic repetitions of the V7 guest CPU/syscall and unset-root contract. |
| Final integrated target | Main206 `make check-apout` passed in 4.13 s at `/tmp/apout-native-final`, preserving the same two-run CPU/write/EBADF/exit/unset-root contract and output NAR. |

The primary final receipt `/tmp/apout-native-final/evidence.json` has status `passed`; `runs.json`, original
`v7-exit-{0,37}.aout` files and octal listings, exact expected output, actual
stdout/stderr and runtime/isolation records retain the proof. Each repetition
runs both exit variants and the unset-root case. Actual guest instructions
compute **3 + 4 − 2 = 5**, branch on the result and execute MOVB to replace
the data-segment `?` digit with `5`; the driver does not synthesize the result.
An invalid V7 write to fd −1 must return **carry set and r0 = EBADF = 9**.
A successful write must return **carry clear and the exact byte count**, and
emits `APOUT_NATIVE cpu=5 write=ok ebadf=9`. The two variants exit with exactly
**0 and 37**, with empty stderr. With `APOUT_ROOT` unset, native Apout exits
**1**, with empty stdout and the exact diagnostic
`APOUT_ROOT env variable not set before running apout`.

Both 126-byte, original V7 0407 images are repeatable: exit-0 SHA-256
`31cf5e71a2a6813d549f1e13284ac00d748e4a47cba0a35f05730c3bfdde0aa2`;
exit-37 SHA-256
`3b6a95eccc73753239fd84da81bc2cb9407212474c2bbb70b7b8b458215ccffd`.
The supplied normal emulator runs under private same-UID/GID user, mount,
network and PID namespaces, loopback only and `/gnu/store` read-only.
Isolation belongs to the external harness, **not Apout**. The pre/post output
NAR hashes match
`0x4043lpchfkxbnymmf1nrfkbxr7v8qg07hakhdv3q46dfzjpi8c`; the after-run output
check also exited 0. No alternate executor, emulator patch or historical
binary fixture is used.

Limits: only this **V7 0407 CPU/write/error/exit** path is exercised; other
Unix ABIs, `NATIVES` host-binary dispatch, sockets and historical guest images
remain untested. `APOUT_ROOT` is a **pathname prefix, not a security sandbox**;
upstream host filesystem, process and socket APIs make running untrusted
guests unsafe without independent isolation. Publication, issue closure and
user-profile/system deployment are not established by this local receipt.
No OKF update applies to this repository-only work.

```sh
out=$(guix build -L guix --no-grafts apout)
make check-apout APOUT_OUTPUT="$out" APOUT_EVIDENCE=/tmp/apout-native-new
```

The guarded target requires both variables, honors `GUIX`, and invokes
[the external smoke consumer](tests/apout-smoke.sh). Evidence must be new or
empty and outside the store/output; no external guest fixture or provenance
environment variables are needed. This documentation worker ran no commands
or checks.

## PDP6 — verified native panel memory path

Local acceptance on **2026-10-05** covers [`pdp6`](guix/tay/packages/pdp6.scm)
**0-2645ed9**, pinned to [aap/pdp6](https://github.com/aap/pdp6/tree/2645ed907d0267710866fd8228863ce8867f4dc6)
revision `2645ed907d0267710866fd8228863ce8867f4dc6`. The normal installed
launcher uses the store-bound upstream emulator and its local-device
`init.ini`; it excludes network, serial, FPGA and hardware-panel paths. The
original 629 source snapshots and preservation accounting are unchanged.

| Gate | Main receipt |
| --- | --- |
| Source build | Main190 passed in 10.73 s for `/gnu/store/1cnyi42srsm5na8s8icrnc57b2ykpl9i-pdp6-0-2645ed9`. |
| Reproducibility | Main191 paired PDP11/PDP6 `--check` passed in 9.86 s, reproducing both outputs. |
| Lint | Main192 paired lint completed in 52.43 s, retaining no-updater and Software Heritage/Disarchive diagnostics for both packages, plus known unrelated deprecated `flex` symbol, Fourk and excluded WinRM diagnostics. This is not a warning-free lint claim. |
| Native console | Main196 passed in 20.02 s at `/tmp/pdp6-native-1`, printing `PDP6_NATIVE_PANEL_OK`. |
| Final integrated target | Main198 `make check-pdp6` passed in 22.62 s at `/tmp/pdp6-native-final`, printing `PDP6_NATIVE_PANEL_OK`. |

The primary final receipt `/tmp/pdp6-native-final/evidence.json` has status `passed`; `console.raw`, seven
genuine panel screenshots, window records and `network.strace` retain the
actual proof. The real **PDP-6 console**, 1399 × 740, was powered on through
its native control. CLI examination first showed address octal `000100`
contained `000000000000`. Native keyboard controls set address `000100` and
the 36-bit data-switch word octal **`525252525252`**; a real DEPOSIT click
wrote the word, independently verified by the native CLI. The harness then
cleared the data switches, selected untouched address `000101` and clicked
EXAMINE: both CLI and memory lamps showed zero. Finally, selecting `000100`
and clicking EXAMINE restored exactly the expected alternating 36 lamp bits,
independently confirmed again by the CLI. The intervening zero examine rules
out merely observing stale lamps left by DEPOSIT.

The [genuine final capture](.goocastle/evidence/pdp6-native.png), from
`07-native-memory-examined.png`, shows the actual console's MEMORY BUFFER,
ARITHMETIC REGISTER, MEMORY and MEMORY ADDRESS labels and yellow lamp rows,
with POWER lit and no visible error. The exact bit result comes from
`panel_memory.examined_lamp_bits` in the receipt, not inferred OCR. No init
file, memory fixture, injected emulator state, alternate executor or patched
renderer was supplied by the harness.

The normal installed emulator ran with private same-UID/GID user, mount,
network and PID namespaces, loopback only and `/gnu/store` read-only.
`network.strace` recorded **zero INET syscalls** during this measured path;
the local Unix connection to Xvfb was observed. This is a scoped network
observation, not a claim that every upstream code path has been audited.
Native CLI `quit` exited 0, stderr was empty and no state files were created.
The before/after output NAR hashes match
`1yh5wx55jrnfssy1m91vjxff46v4yykpmaxrvs6pvb9ah1x95w02`.

Limits: this proves local panel power, data/address controls, DEPOSIT,
EXAMINE and clean quit. It does **not** establish firmware/guest boot,
instruction execution, persistent emulator saves, external devices or any
network/serial/FPGA/hardware-panel operation. Publication, issue closure and
user-profile/system deployment are not established here. No OKF update
applies to this repository-only work.

```sh
out=$(guix build -L guix --no-grafts pdp6)
make check-pdp6 PDP6_OUTPUT="$out" PDP6_EVIDENCE=/tmp/pdp6-native-new
```

`PDP6_OUTPUT` and `PDP6_EVIDENCE` are required; use a new or empty evidence
directory outside the store/output. The guarded target honors `GUIX` and
invokes [the external smoke consumer](tests/pdp6-smoke.sh) with both arguments.
This documentation worker ran no commands or checks and created no capture.

## PDP11 — verified native microcycle diagnostic

Local acceptance on **2026-10-05** covers [`pdp11`](guix/tay/packages/pdp11.scm)
**0-5b5b734**, pinned to [aap/pdp11](https://github.com/aap/pdp11/tree/5b5b734f9b574cc3257670595eee6be084f2c8aa)
revision `5b5b734f9b574cc3257670595eee6be084f2c8aa`. The four installed native
programs build, but the exercised execution path is only **`pdp1145`'s built-in
microcycle diagnostic**, not a general firmware or operating-system boot.
The original 629 source snapshots and preservation accounting are unchanged.

| Gate | Main receipt |
| --- | --- |
| Source build | Main189 passed in 5.86 s, producing `/gnu/store/v4kn87i8hwxns9nymp8ph8vkns26d2cl-pdp11-0-5b5b734`; upstream compiler warnings remain, so this is not a warning-free build claim. |
| Reproducibility | Main191 `--check` rebuilt PDP11 and PDP6 successfully in 9.86 s; PDP11 reproduced the same output. This does not establish PDP6 native runtime behavior. |
| Lint | Main192 completed the paired lint in 52.43 s, retaining no-updater and Software Heritage/Disarchive diagnostics for both packages, plus known unrelated deprecated `flex` symbol, Fourk and excluded WinRM diagnostics. This is not a clean-lint claim. |
| Native diagnostic | Main195 passed in 2.35 s: `PDP11_NATIVE_MICROCYCLE_OK runs=2 exact_states_per_run=16 deterministic=true`. |
| Final integrated target | Main197 `make check-pdp11` passed in 3.84 s at `/tmp/pdp11-native-final`: `PDP11_NATIVE_MICROCYCLE_OK runs=2 exact_states_per_run=16 deterministic=true`. |

The primary final receipt `/tmp/pdp11-native-final/evidence.json` has status `passed`; `runs.json`,
`expected.stdout`, both run stdout/stderr files, `runtime.json` and isolation
records retain the actual evidence. Two fresh invocations of the supplied
normal `bin/pdp1145`, without arguments, each exited 0 with empty stderr.
Each produced **2,279 bytes** exactly matching the pinned-source oracle,
SHA-256 `5a854c78f1ab14b8c3938963bf11083085fa77d823916d1e9db245c363ceb7d6`.
The oracle covers **16 register states per run**: three built-in microcycles
and their final T1, with ROM addresses octal `200`, `352`, `170`, `70`.
No package-specific executable patch, alternate executor or injected state
was used. The upstream trace's `BEND (TODO)` and `BRQ STROBE (TODO)` messages
are preserved observations, **not evidence of implemented bus behavior**.

The diagnostic ran under private same-UID/GID user, mount, network and PID
namespaces, with loopback only and `/gnu/store` read-only. The pre/post output
NAR hashes both equal
`0067b4p0wawsgn32dpgkcxbd7jg17pqz8nn6lv9k050gsazkxdyk`; the after-run output
check also exited 0. This establishes no mutation of the measured output.

Limits: `pdp1105`, `pdp1120` and `pdp1140` are checked only as installed ELF
files, **not executed by this receipt**. No macroinstruction execution,
firmware, guest operating system, peripherals or GUI interaction is proved.
The native proof is a diagnostic stdout trace, not a screenshot or frontend
claim. Publication, issue closure and user-profile/system deployment are not
established here. No OKF update applies to this repository-only work.

```sh
out=$(guix build -L guix --no-grafts pdp11)
make check-pdp11 PDP11_OUTPUT="$out" PDP11_EVIDENCE=/tmp/pdp11-native-new
```

`PDP11_OUTPUT` and `PDP11_EVIDENCE` are required; provide a new or empty
evidence directory outside the store/output. The guarded target honors `GUIX`
and invokes [the external smoke consumer](tests/pdp11-smoke.sh) with both
arguments. This documentation worker ran no commands or checks.

## Boohu — official Guix reuse and native terminal save/restore

Local acceptance on **2026-10-05** reuses official Guix's
`(@ (gnu packages games) boohu)` **0.14.1**, without a duplicate channel recipe,
`PROJECT_PACKAGES` addition or aggregate-check dependency. The original 629
source snapshots and their preservation accounting are unchanged. The source
is the unchanged [upstream revision](https://github.com/anaseto/boohu/tree/686c990bf30e8f8e57d8ef561641079d3a75b6a5)
`686c990bf30e8f8e57d8ef561641079d3a75b6a5`, realized at
`/gnu/store/mmk78hyxkvqdwwcf1ln21i9jmmdypicb-boohu-0.14.1-checkout`.
Its embedded game/save version is `v0.14`; that is not a different package pin.

### Dated evidence

| Gate | Main receipt |
| --- | --- |
| Initial realization | Main181 realized the official output using substitutes; this alone is not a source-build claim. |
| Source rebuild and upstream tests | Main182 `--check` performed the actual source build, passed all eight upstream tests, and reproduced `/gnu/store/abc9m9kcr9x3mlyi86whak5lsyln1idf-boohu-0.14.1`, wall 69.26 s. |
| Lint | Main184 completed in 8.64 s; the official description retains a period diagnostic. Unrelated deprecated `flex` symbol, Fourk and excluded WinRM diagnostics also appeared. This is not a warning-free lint claim. |
| Integrated native terminal | Main188 `make check-boohu` passed in 21.56 s, printing `BOOHU_NATIVE_SAVE_RESTORE_OK evidence=/tmp/boohu-native-2`. |

The authoritative evidence is `/tmp/boohu-native-2/receipt.json` and
`proof.json`, with four native saves, decoded states, input records and real
xterm/Xvfb screenshots. The supplied normal `bin/boohu` ran in private
same-UID/GID user, mount, network and PID namespaces, with `/gnu/store`
read-only; prerequisites were realized serially before gameplay. The
before/after output NAR hashes both equal
`11ij4511ml3g5r31m2d97cpi59svlc6hhd3i3qxwqbcra1xil25n`.
No game-state injection, alternate renderer, smoke frontend or patched game
was used.

Four fresh native sessions exercised wait (`.`), normal save/exit, default
no-argument restore, continued wait and a second no-action restore. Decoded
event ranks were **10, 10, 20, 20**, with native action counters **1, 1, 2, 2**.
Both restore pairs exactly preserved authoritative player/world/event/stat
state, including the player FOV payload, dungeon generation/cells, event queue
and current event. The player position remained unchanged by waiting. Only
`$XDG_DATA_HOME/boohu/save` was written; isolated home, work, config, cache,
state, runtime and temporary directories remained free of game files.

The comparison is deliberately source-backed, not byte-identical saves or
whole-screen identity. At the pinned source, `events.go:105-119` recomputes
noise and log/automation state on a resumed player event, and
`draw.go:368-383` stores wall-clock draw timestamps. Derived
UI/path/noise/log/automation fields are outside the authoritative comparison;
complete decoded saves remain evidence. Exact map/HUD cell attributes compare
outside only the union of the two saved native `Noise` coordinate maps, not
heuristic glyph or OCR masks. Message/log rows are outside that map/HUD
comparison. Upstream gob does not serialize unexported UI/runtime/RNG state;
neither save-byte identity nor restoration of that unexported state is claimed.

The genuine [terminal capture](.goocastle/evidence/boohu-native.png) is session
three's `screen-3.png`: a cyan `@` in the dungeon, robe and dagger, **HP 42,
MP 3, Depth 1, Turns 2.0**, with no visible error. This is terminal gameplay
evidence, **not `boohu-tk` or another game GUI**. Combat, deeper exploration,
completion and GUI behavior are not established by this bounded wait/save/
restore proof. Publication, issue closure and user-profile/system deployment
are separate from this local receipt. No host/service change or OKF update
applies to this repository-only work.

```sh
out=$(guix build --no-grafts -e '(@ (gnu packages games) boohu)')
make check-boohu BOOHU_OUTPUT="$out" BOOHU_EVIDENCE=/tmp/boohu-native-new
```

`BOOHU_OUTPUT` and `BOOHU_EVIDENCE` are required; evidence must be a new or
empty directory outside the store/output. The guarded target passes `GUIX`
through to [the external smoke consumer](tests/boohu-smoke.sh).

## Minttea — native terminal UI and isolated OCaml 5.2 closure

[`minttea`](guix/tay/packages/minttea.scm) **0.0.3-1.40ee449** builds the
complete MIT/Expat [`leostera/minttea`](https://github.com/leostera/minttea/tree/40ee44920bda53bd2838065374c9b188c06f8cba)
revision `40ee44920bda53bd2838065374c9b188c06f8cba` from the exact unchanged
origin of `leostera-minttea-source` (Guix base32 SHA-256
`00vp2j275d9f81vsr36fdls62397pvwa9jsmsrngdmzxwi1rvc0p`). The 629-source
preservation ledger is unchanged; no snippet prunes the source.

| Decision | Recipe behavior |
| --- | --- |
| Sole Spices provider | `ocaml-spices-minttea` builds Spices from the same origin. `minttea` installs only `minttea` and `leaves`, propagates that one provider and records its store path in `share/minttea/spices-provider`. |
| Original examples | Upstream `examples/` are archived before any edit and installed byte-exact under `share/minttea`. Only the built basic example receives four local `Event.KeyDown` rewrites to the documented `(key, modifier)` tuple; native `minttea-basic` and `minttea-counter` are installed. |
| Libc archive collision | `ocaml-libc-minttea` names its Dune library `ocaml_libc`, keeping public `libc`, so no `libc.a` shadows GCC's implicit `-lc`; helper modules keep the original `Libc__` namespace. |
| Riot exit race | `ocaml-riot-minttea` 0.0.9 reads and CASes one atomic state snapshot in `mark_as_running`, so a cross-domain exit cannot resurrect a terminal process or crash the scheduler. |
| Pinned compiler | [`ocaml-minttea`](guix/tay/packages/ocaml-minttea-toolchain.scm) is official INRIA OCaml **5.2.1** (Riot needs ≥ 5.1, < 5.3) with upstream `e3919fef`'s OSEC-2026-01 / CVE-2026-28364 Marshal bounds fix backported. It does not replace the channel's default OCaml. |

### Dated evidence (2026-10-05)

| Gate | Main receipt |
| --- | --- |
| Compiler | Main174 passed for the security-backported 5.2.1 compiler. |
| Build and upstream tests | Main177: full upstream MDX/check suites and native examples passed. |
| Native PTY | Main178 passed: `MINTTEA_BASIC_PTY_OK states=16 keys=14`. |
| Reproducibility | Main179 `--check` passed for the same output, `/gnu/store/7bh37dm20dj1vrgvzip1zgc2ly2n9swj-minttea-0.0.3-1.40ee449`, wall 6.65 s. |
| Lint | Main180 `guix lint -L guix minttea` exited 0 in 24.15 s but was not warning-free: its only Minttea diagnostic is that the source is not archived by Software Heritage/Disarchive. SQLite-busy and unrelated deprecated `flex` symbol, Fourk and excluded WinRM warnings appeared; neither is counted as a Minttea cleanliness result. |
| Publication | Signed commit `747f74874bb5e7ab161997e37b7684be86081209` is on `origin/master`, verified through the normal authenticated pre-push path. |

Main178's evidence (`/tmp/minttea-native-3/evidence.json`, status `passed`)
installed a temporary profile containing that output,
`/gnu/store/xn1hh59in8fh7fvj82yq40q8k74d1xv9-ocaml-minttea-5.2.1`,
`/gnu/store/1dc3jlpi7lhmw4w0092g163jz7xfy41x-ocaml-findlib-minttea-1.9.8`
and GCC toolchain 14.3.0. It resolved Spices from
`/gnu/store/kicf8ibl0p3wy75dqc37qrh2kmlmz7zk-ocaml-spices-minttea-0.0.3-1.40ee449`
and ran `ocamlfind ocamlopt -thread -package minttea,spices,leaves -linkpkg`
on the upstream basic example (git blob
`40b4891184ca911e5e367cf1c6e9abc275fa2d87`) after the same four tuple rewrites,
consumer SHA-256
`5291c7b43a7f650b08b855a60eafb7ba65a271c6f90918fd2b982c241fecae87`.
On a PTY, 14 keys yielded 16 rendered cursor/selection states; `q` exited with
status 0, and termios matched before and after the raw-mode run. The run used
private network/PID namespaces, loopback only, a read-only store and preserved
UID/GID. Before/after output NAR hashes match
`16rdw24z5lz40a31gh96x3rwl763vvgn5sks1skblgf1k1liryx8`.

Limits: upstream Dune/MDX suites run in the package build, not the native
harness, and only the basic example is driven on a PTY. Repository publication
is not user-profile/system deployment. No host/service change or material
network-catalog correction is established; no OKF update applies.

```sh
out=$(guix build -L guix --no-grafts minttea)
make check-minttea MINTTEA_OUTPUT="$out" MINTTEA_EVIDENCE=/tmp/minttea-native-new
```

This documentation worker ran no commands, checks, cleanup or signals.


## Wanderers — verified native save/restore path

Local acceptance on **2026-10-05** covers the installed seeded game, cardinal
movement, timed Rest, normal save/quit, default restore and continued movement.
Main reports build115 passed for
`/gnu/store/dy8v6h8y6i75dczlrxbdams5wkk23c34-wanderers-0-054c1cd`,
derivation `7l68sfj685jj1lwraxchyz2z4alzfqba`, and the bit-identical `--check`
rebuild (check117) passed. Integrated `make check-wanderers` (native122) passed
in **35.29s**, printing `WANDERERS_NATIVE_SAVE_RESTORE_OK`; the authoritative
decoded proof is `/tmp/wanderers-native-3/proof.json`, with individual saves,
states, input records and captures in its `gameplay/` directory.
Lint119 retains Wanderers refresh/updater and source-archive informational
notes; known unrelated deprecated `flex` symbol, Fourk and excluded WinRM
diagnostics remain. **This is not a clean-lint claim.** Publication, issue
closure and deployment are not established by this local receipt.

### Source pin, build and licensing

[`wanderers`](guix/tay/packages/wanderers.scm) **0-054c1cd** uses the fixed
[`a-nikolaev/wanderers`](https://github.com/a-nikolaev/wanderers) commit
`054c1cdc6dd833d8938357e6d898def510531d67` (2019-01-05), fetched from
`https://codeload.github.com/a-nikolaev/wanderers/tar.gz/054c1cdc6dd833d8938357e6d898def510531d67`.
The recipe's Guix base32 SHA256 is
`0wivxq23h149c6s26j1ql52aqr2sc2k10xcp00hhabxz2cjaxcq0`;
archive SHA256 is
`00b3ae2413bf2f052100977510a6605a64ac44a1384823b46189043804ee3b72`.
The existing recipe builds the upstream native OCaml target with OCaml 4.07,
SDL 1.2 compatibility and Mesa; upstream has no test target. The game/assets
are **GPL-3.0-or-later**, GLCaml **BSD-2-Clause**, bundled SDL binding
**LGPL-2.0-only**, and OCamlMakefile **LGPL-2.1**. Installed documentation
preserves `COPYING`, `README.markdown`, `OCamlMakefile` and the binding sources
with their notices. No production recipe change was warranted.

### Exercised native behavior and limits

The installed wrapper starts a normal `wanderers guix-smoke` game, not debug
mode, under fresh HOME/XDG directories. Later launches have no arguments and
restore the saved seed, region 374, controller 0 and player 24. The launcher
keeps writable `game.save` below `${XDG_DATA_HOME}/wanderers` (default
`~/.local/share/wanderers`) and links immutable packaged data there. The native
run has isolated user/mount/PID/network namespaces, only loopback networking,
an empty PATH and recursively read-only `/gnu/store`.

- Decoded baseline location **(4,6)** and simulation clock **0.693** advance
  through a real Right key to **(5,6)** and **2.7279999999999993**; both old and
  new source-derived map cells change visibly.
- Normal `t` Rest requests **10 simulation units**. The decoded clock reaches
  **14.035999999999998**, elapsed **11.307999999999998**, satisfying
  `10 + previous reaction <= elapsed < 10 + previous reaction + 2` for the
  native timed-action and Wait phase. Acceptance does not freeze the world
  or require unchanged HP/location: real combat displacement/damage is allowed,
  and continued movement is chosen from the actual restored state. This run's
  Rest retained **(5,6)** and HP **101.38512817468151**, with no damage
  notifications; it does **not** claim combat occurred.
- Normal Ctrl+Q save/quit and no-action default restore/save preserve the
  **entire 948,808-byte native save byte-for-byte**, SHA256
  `55374280cfd09da5060694be47d0f5de685ac316fa3bef7f7bd19e7a3ca7340b`.
  Continued Right movement then reaches **(6,6)**, clock
  **16.653999999999996**, followed by another normal save/quit. All sessions
  exit normally.
- Clock glyphs and the player sprite are checked against the installed source
  tileset, not visually estimated. Sprite checks respect source opacity and
  exclude only source-derived opaque notification texels, retaining exact
  visible evidence for every source-occupied row, column and palette color.
  Numeric clocks above come from decoded saves; rendered HUD clock text rounds
  them and is not numeric proof.
- Before/after output NAR hashes are identical:
  `0r7q4f5ia01gikni23r8slgfllryfhraqr2chs977wbcnk0wj5x3`.
  [Retained native screenshot](.goocastle/evidence/wanderers-native.png) is the
  actual `continued-before-save.png` capture. Main inspected the real
  map/player/HUD with no visible errors; the screenshot supplements, rather
  than replaces, decoded state and pixel evidence.

Coverage uses software OpenGL on private 24-bit Xvfb and dummy audio; physical
GPU, audible output, desktop integration and all gameplay features are not
established. Main owns all executed checks; this documentation worker only
read the authoritative recipe and evidence, without running checks. The
629-source snapshot ledger and unrelated work are unchanged. No described
host/service or user profile changed; no OKF page/log update applies to this
repository-only receipt.

## WeiDU — verified offline native path

Local evidence on **2026-10-05** establishes a source-built native executable,
a bit-identical rebuild and the exercised game-free operations below, **not
acceptance on a real Infinity Engine game**. Main reports the final build
(bg66) passed for `/gnu/store/0nf080qr7ggfk6wdc2d31b7ivcz9q5xc-weidu-252.01`,
derivation `w75v53wckxqpscp1pq0f33gszqnglqkz`, and the `--check` rebuild
(bg67) passed for the same output. The final integrated `make check-weidu`
(bg72) passed in **6.65s**, printing `WEIDU_OFFLINE_TP2_OK`; its authoritative
evidence is `/tmp/weidu-native-final-2/proof.json`. Scoped lint (bg68) retains
two WeiDU informational limitations: no Guix refresh updater for the snapshot
origin, and source not archived in Software Heritage/Disarchive. Unrelated
Flex Launcher/Fourk and excluded WinRM module diagnostics also remain;
**this is not a clean-lint claim**. Publication, issue closure and deployment
are not established by this receipt. No described host or service changed;
no OKF page/log update applies to this repository-only change.

### Source-built toolchain and licensing

[`weidu`](guix/tay/packages/weidu.scm) **252.01** compiles the preserved
[`WeiDUorg/weidu`](https://github.com/WeiDUorg/weidu) snapshot at
`13f207b12833ce9bbbb119625a9b43b287738c52`, Guix base32 SHA256
`0wpdg49dzcrr98a2izdg938l81nab83r6vy4zx6n7f1wa4ggvcsn`.
`src/version.ml` identifies this fixed development revision as 252.01.
The unchanged recipe privately rebuilds Guix's OCaml 4.14.3 source with
`--disable-force-safe-string`; the pinned WeiDU Makefile supplies
`-unsafe-string` for its historical mutable-string code. Its private
source-built Elkhound GLR generator uses revision
`b8f5589de119c89b36b1fc21d2f51c4a942ee3a8`, Guix base32 SHA256
`04hypc95nnvab8nzxy76vvsbf7061wajn3rh6kn5rvwq24m2sjgj` (BSD-3 root and
public-domain smbase), rather than upstream CI's moving prebuilt archive.
Builds run serially because a generated-parser dependency omits a tlexer edge.

The output installs only `bin/weidu`, not updater aliases or game data.
`share/doc/weidu` contains GPL `COPYING`, `README.md` and
`README-WeiDU-Changes.txt`; its `third-party-notices` directory preserves
Elkhound's `license.txt`, `fcase.c`, `zlib.h`, `xinclude.h`, `batList.ml`,
`myhashtbl.ml`, `parsing.ml` and `myarg.ml`. The recipe records
GPL2/BSD-3/Expat/LGPL2.1. Native `--licence` also retains the GPL notice with
upstream's additional permission for unmodified binaries, plus Keith Bauer's
fcaseopen permission notice.

### Native offline evidence

The final proof runs the normal installed binary with an empty inherited
environment, fresh HOME/XDG/TMPDIR and empty `PATH`, in private user, mount,
PID and network namespaces. Only `lo` is present; Uid 1000 and Gid 998 are
unchanged across all four identity fields with matching same-ID mappings,
not a root mapping. `/gnu/store` is recursively bind-mounted private and
read-only. All five calls — `--help`, `--licence`, TP2 installation,
game-free dialog compilation and traify — exit 0 **and contain no
line-anchored `ERROR:`/`FATAL ERROR:` diagnostics**. The help pager receives
32 newlines and completes normally; a zero exit status alone is insufficient
because WeiDU can emit native failures while exiting 0.

- `weidu --nogame --noautoupdate --no-exit-pause --yes --force-install 0
  fixture.tp2` installs a real TP2 `COPY ~input.txt~ ~output.txt~` operation,
  reporting `SUCCESSFULLY INSTALLED offline copy`. Its output equals all
  26 input bytes, `Guix offline copy fixture\n`, SHA256
  `d29d13e94de5d4fe638edee9be25084a1f6c7c2fa06c43e7f89869ecbfaff6dd`.
- Pinned upstream `test/no-game/make-foozle.d` compiles with `--nogame` to
  the exact source-derived **180-byte `FOOZLE.dlg`**, SHA256
  `5cf89d8667db8a7c136e8b1aa87996839168019923f8d58a3f990b1caff31f3a`.
- The documented game-free `--nogame --traify test.tp2` fixture matches
  both expected output MD5s pinned by `test/traify/run_tests.pl`:
  `b9d17b468280c1b15d95a4ee091e033b` (TP2) and
  `7eb0fdcc7f221e4f7437b7b14e692a46` (TRA). These receipts and exclusions
  are retained in `/tmp/weidu-native-final-2/upstream-tests.json`.

Fresh HOME/XDG state stays empty, installed files are non-writable, and the
output NAR hash before/after is unchanged:
`1db44h6035qqscblq3b26az4s7q009vn4qwcic6s480dlqp03psp`.

### Limits and developer command

The package build skips upstream tests; the external installed-output smoke
exercises **only the documented game-free subsets**, not the entire upstream
suite. No real game installation, proprietary-game dialog roundtrip, full TP2
regression mod, Quitch rollback case, or game-dependent traify/old-TRA path was
tested. See the pinned `test/README` and retained upstream-test exclusions.
The lint refresh-updater note concerns Guix packaging metadata, not WeiDU's
runtime mod-update options; archival availability remains a separate limit.

```sh
make check-weidu WEIDU_OUTPUT=/gnu/store/0nf080qr7ggfk6wdc2d31b7ivcz9q5xc-weidu-252.01 WEIDU_EVIDENCE=/tmp/weidu-new-evidence
```

The target consumes a prebuilt output and a new/empty evidence directory;
it does not build WeiDU or touch a user's game installation.

## Faugus Launcher — verified native GTK path

Local evidence on **2026-10-05** establishes the normal installed GTK launcher,
a bit-identical rebuild and native add/edit/persist/reopen of a Linux entry,
**not execution of any game, Proton, UMU or Windows title**. Main reports the
final build (bg103) passed for
`/gnu/store/vhy3nfn8s5fcnjz9bpcviw553nk5p8q9-faugus-launcher-2.1.0-0.5b2316c`,
derivation `v2f4gb0whbd8d49ywb43y8vsfxax4yl0`, and the `--check` rebuild
(bg105) passed in 3.81s. The integrated `make check-faugus-launcher` (bg104)
passed in **37.37s**; `/tmp/faugus-native-final/evidence.json` records status
`passed`, exit status 0 and the unchanged output NAR hash
`0lmcq16nj7jxk66vc9yql0kjkw8753wql0irlf8vnq2kk34i6wqc`. Final scoped lint
(bg106) retains three Faugus notes: the `gobject-introspection` input "should
probably be native", which is intentionally kept because the launcher loads
its DBus/cairo/fontconfig/freetype/xlib typelibs at run time; no Guix refresh
updater for the snapshot origin; and source not archived in Software
Heritage/Disarchive. Unrelated deprecated `flex` symbol, Fourk, WinRM and
libcamera duplicate-package diagnostics also remain; **this is not a
clean-lint claim**.
Publication, issue closure and deployment are not established by this receipt.
No described host or service changed; no OKF page/log update applies.

### Source pin, recipe and licensing

[`faugus-launcher`](guix/tay/packages/faugus-launcher.scm) **2.1.0-0.5b2316c**
builds the preserved
[`Faugus/faugus-launcher`](https://github.com/Faugus/faugus-launcher) snapshot
at `5b2316c3a977359092392635b608ab497fd01cfd`, Guix base32 SHA256
`0p7v0l49y3h2rnxjx3k5xwanlcmh1vvn23h72009rqigkskj2imy`, with Meson. The
recipe keeps upstream's own `faugus-launcher` shell dispatcher (shortcut,
game, run and tray bootstrap) rather than a replacement entrypoint or invented
help mode, binding its interpreter and `SCRIPT_DIR` to the store. The wrapper
supplies the complete Python transitive closure through `PYTHONPATH`, the
private source-built `icoextract` 0.3.0 (Expat) on `PATH` for shortcut icons,
GTK/libadwaita/libmanette/graphene/Pango/GdkPixbuf/GLib/cairo/HarfBuzz
typelibs, the build-generated GdkPixbuf loader cache and `shared-mime-info`
data. The last two fix an actual crash when adding an entry image: GdkPixbuf
relies on GIO MIME sniffing even for its built-in PNG/JPEG decoders.

The output installs upstream `LICENSE` (MIT/Expat) and `ASSETS-LICENSE`
(CC BY 4.0 icons and notification sound) under
`share/licenses/faugus-launcher`; upstream metainfo declares CC0-1.0 metadata.
The recipe's license field lists Expat, CC BY 4.0, zlib and CC0. The installed
`share/faugus-launcher/gamecontrollerdb.txt` SDL controller mappings carry no
in-file notice, but are the unmodified Git blob
`4f5607a1d29260368b37604962f309651aca9395` (599249 bytes; locally confirmed
with `git hash-object` on the pinned source) of
[`mdqinc/SDL_GameControllerDB` revision `513c72e34569e0f471dde7aa26eecb23946c3ef7`](https://github.com/mdqinc/SDL_GameControllerDB/tree/513c72e34569e0f471dde7aa26eecb23946c3ef7)
(26 June 2026, before Faugus added the asset in `17afd9f` on 12 July 2026).
Its [LICENSE at that revision](https://github.com/mdqinc/SDL_GameControllerDB/blob/513c72e34569e0f471dde7aa26eecb23946c3ef7/LICENSE)
is zlib, Copyright (C) 1997-2025 Sam Lantinga. The recipe preserves that
notice verbatim, and the final output installs it as
`share/licenses/faugus-launcher/SDL_GameControllerDB-LICENSE`. No separate CC0
notice file is installed for the metadata.

Faugus can manage Proton, UMU and related runtimes, but **none are bundled**.
The recipe removes upstream's unattended runtime fetch when no local
components exist, and the wrapper defaults `FAUGUS_DISABLE_UPDATES=1` and
`UMU_RUNTIME_UPDATE=0` while leaving explicit user overrides possible. Any
runtime a user later chooses to download is mutable third-party software
outside this package's pins, licenses and verification.

### Native GTK evidence

The external `tests/faugus-native-driver.py` consumer starts the normal
installed launcher with no test mode, imported application module or
pre-created configuration. It runs in private user, mount, PID and network
namespaces (only `lo`; Uid 1000/Gid 998 same-ID mappings, not root), with
`/gnu/store` read-only, a fresh HOME/XDG tree, Xvfb, a session bus and
read-only AT-SPI observation driven by real X11 input:

- The toolbar Add dialog creates **Linux Game** `Offline Native Entry` for the
  store `coreutils` `true` executable with **Disable UMU** checked, then saves.
- Edit → Tools sets the supported **Game Arguments** field to
  `--offline-native-proof`; the saved library (`library-edited.json`) records
  runner `Linux-Native`, `disable_umu: true` and those game arguments.
- After a normal Alt+F4 close (exit 0, log free of tracebacks/errors) and
  relaunch, the persisted library is identical, and reopening Edit and Tools
  shows the exact title, path, Disable UMU state and arguments.

The [reopened Tools screenshot](.goocastle/evidence/faugus-launcher-native.png),
copied from the final run's `reopened-tools-1.png`, shows the legible
persisted argument.
The entry is never played, so no game, Wine/Proton, UMU, controller, Steam or
SteamGridDB path is exercised; no network access is available in the proof.

```sh
make check-faugus-launcher FAUGUS_OUTPUT=/gnu/store/vhy3nfn8s5fcnjz9bpcviw553nk5p8q9-faugus-launcher-2.1.0-0.5b2316c FAUGUS_EVIDENCE=/tmp/faugus-new-evidence
```

The target consumes a prebuilt output and a new/empty evidence directory.

## Aidermacs — verified native Emacs extension path

Local evidence on **2026-10-05** establishes the installed Emacs extension in a
real terminal Emacs, a bit-identical rebuild and upstream's prompt-file
workflow, **not an Aider session, LLM session, model call or network use**.
Aider is deliberately not packaged; the missing-Aider failure below is the
expected outcome, not a stubbed one. Main reports the final build (bg107)
passed for
`/gnu/store/7b59c0d2asjjm838r9gq1kgq7jzcg3dv-emacs-aidermacs-1.11-0.2fc9939`,
derivation `i5yphgy38210yx9w2cnc65344g5736q8`, and the `--check` rebuild
(bg108) passed. The integrated `make check-emacs-aidermacs` (bg113) passed in
**17.67s**, printing `AIDERMACS_NATIVE_PROMPT_OK (no Aider or LLM session)`;
`/tmp/aidermacs-native-3/evidence.json` records status `passed`, exit status 0,
`aider_session`, `llm_session` and `model_calls` all false, and the unchanged
output NAR hash `0z8cap1m1iwrr0s9d329hn67d5xhg7c9rps90ry7k6ndp62hk7j4`.
Scoped lint (bg109) retains only two Aidermacs informational notes: no Guix
refresh updater for the snapshot origin, and source not archived in Software
Heritage/Disarchive. Unrelated deprecated `flex` symbol, Fourk and excluded WinRM
diagnostics also remain; **this is not a clean-lint claim**. Publication,
issue closure and deployment are not established by this receipt. No
described host or service changed; no OKF page/log update applies.

### Source pin, scope and licensing

[`emacs-aidermacs`](guix/tay/packages/aidermacs.scm) **1.11-0.2fc9939**
builds the preserved
[`MatthewZMD/aidermacs` revision `2fc993932d2df9270c3f85f8215f73600b78145c`](https://github.com/MatthewZMD/aidermacs/tree/2fc993932d2df9270c3f85f8215f73600b78145c),
Guix base32 SHA256 `1x2v8i2kzbnlvx7b55fc9b47bg46xf669kghfhyiw6jdc5vpxvl4`.
Every library declares version 1.11, but the revision is not a release tag,
so the commit suffix is kept. The intended scope is **the extension only**:
the output installs exactly the six runtime libraries (`aidermacs`,
`-backend-comint`, `-backend-vterm`, `-backends`, `-models`, `-output`) and
their byte-compiled `.elc` files, without README images, workflows or other
development material. It does not package `aider`/`aider-ce`, Vterm, API keys
or provider configuration; users supply an Aider program on `PATH` or through
`aidermacs-program`.

Aidermacs propagates `emacs-compat`, `emacs-markdown-mode` and
`emacs-transient`; Transient in turn propagates `emacs-llama` and
`emacs-cond-let`. The proof loads this **complete transitive propagated
closure** from the package definition (compat 31.0.0.1, markdown-mode 2.8,
transient 0.13.5, llama 1.0.5, cond-let 1.1.3) rather than only direct inputs.

All six libraries carry upstream's `SPDX-License-Identifier: Apache-2.0`
header, retained in the installed `.el` files, and the recipe's license is
`asl2.0`. Upstream's Apache License 2.0 `LICENSE` is installed as
`share/doc/emacs-aidermacs/LICENSE`. The pinned tree has no `NOTICE` file,
so no additional Apache notice text applies.

### Native terminal evidence

The external `tests/emacs-aidermacs-native.py` consumer runs the normal
`emacs-minimal` 30.2 binary as `emacs -nw` with no site files, loading only
the installed output and its propagated closure, in private user, mount, PID
and network namespaces (only `lo`; Uid 1000/Gid 998 same-ID mappings, not
root) with `/gnu/store` read-only. It types real keystrokes into a PTY; each
step is retained as raw terminal output, a parsed text frame and frame JSON:

- Emacs opens a real `sample.py` source buffer in Python mode.
- `M-x aidermacs-transient-menu` draws the native transient menu, truthfully
  showing `a Start Session (NOT RUNNING)`; `C-g` quits it without an action.
- `M-x aidermacs-setup-minor-mode`, then `M-x aidermacs-open-prompt-file`,
  creates upstream's `.aider.prompt.org` template in Org mode with the
  `aidermacs` minor-mode lighter. A source-specific `/ask` line is typed and
  saved with `C-x C-s`, the buffer is killed, and reopening shows the exact
  persisted 325-byte file. The source file's SHA256
  `5f4d30e86d2e94a1e4b2d5f9aaaf352cbad0f122fc873e082ffd865a54493d19` is
  unchanged.
- The minor mode's `C-c C-n` (`aidermacs-send-line-or-region`) on that task
  line reaches the genuine upstream error `Aider executable not found.
  Checked: (aider-ce aider)`, also recorded in `*Messages*`. A batch
  preflight first asserts this exact message with an empty `exec-path`, plus
  upstream's multi-line message wrapping.

The visual evidence is these terminal text frames in
`/tmp/aidermacs-native-3`, not an image screenshot. Emacs exits normally with
`C-x C-c`.

### Limits and developer command

No Aider or `aider-ce` program, Comint or Vterm session, prompt delivery,
file add/drop, code change, Ediff review, model selection or provider model
list fetch, voice or web-content command was exercised; those require a
separately supplied Aider and, usually, provider credentials and network
access. The package build's own check is limited to byte compilation, feature
and command availability, multi-line wrapping and the missing-Aider error,
with `url-retrieve-synchronously` made to fail.

```sh
make check-emacs-aidermacs AIDERMACS_OUTPUT=/gnu/store/7b59c0d2asjjm838r9gq1kgq7jzcg3dv-emacs-aidermacs-1.11-0.2fc9939 AIDERMACS_EVIDENCE=/tmp/aidermacs-new-evidence
```

The target consumes a prebuilt output and a new/empty evidence directory; it
does not build the package or start Aider.

## Natron — verified core host path

Local evidence on **2026-10-04** establishes a source-built **core host**, an
empty native GUI and one external OpenFX render, not a complete plugin-equipped
compositing application. Main reports the final build (bg40) passed for
`/gnu/store/5vix1plx3csv0yqbxx2vcvxgphgxbzx8-natron-2.6.0-0.20260724`
after lint-driven recipe fixes. The integrated `make check-natron` run (bg41)
passed; its authoritative native proof is
`/tmp/natron-make-final-1/proof.json`. Main reports the final `--check` rebuild
(bg42) passed bit-identically for the same output, with all 23 selected tests
passing again. Final scoped lint (bg43) exited 0 with no Natron findings;
remaining unrelated Flex Launcher/Fourk and excluded WinRM module diagnostics
are outside this receipt, **not a whole-channel clean-lint claim**. Earlier
bg36/bg38/bg37 receipts describe an intermediate output, not this final one.
Publication, issue closure and deployment are not established. This worker
read recipes and receipts only, running no commands/checks. No user profile,
described host or service changed; no OKF page/log update applies.

### Source pins and redistribution notices

[`natron`](guix/tay/packages/natron.scm) **2.6.0-0.20260724** recursively fetches
the original [`NatronGitHub/Natron`](https://github.com/NatronGitHub/Natron)
source at `3763d805d7d277d10af10025ae41af677682b3e6`, Guix base32 SHA256
`0jmjjpk8lzw574q50iad36igdiy67sd3x426k7y2whiz1r30vg83`.
The recipe records these exact source gitlinks:

| Component | Revision |
| --- | --- |
| google-mock | `17945db42c0b42496b2f3c6530307979f2e2a5ce` |
| google-test | `50d6fc317c843a2e40dbf08c2efd3f068801ae6d` |
| OpenFX | `2303ff811bee3ffe085287602f684fe5fe5357e0` |
| SequenceParsing | `3c93fcc488632b0bdfeee3181586809932357598` |
| tinydir | `64fb1d4376d7580aa1013fdbacddbbeba67bb085` |
| google-breakpad | `9474c3f7f9939391f281d46c42bfe20cc0f0abd9` |

The host is built with Qt 6, embedded Python and the selected Qt-for-Python
modules. Local Qt API/regular-expression/signal and Python-runtime patches
are listed in the recipe; installed launchers bind their Python, fontconfig
and Qt plugin paths to store inputs. The OpenFX gitlink supplies the host/API
source, **not** the separately maintained normal effect and I/O plugins.
`openfx-io`, `openfx-misc`, `openfx-arena`, FFmpeg, OpenImageIO readers/writers
and OCIO configurations are not bundled. Explicit external plugins may be
composed through `OFX_PLUGIN_PATH`; the proof fixture does not supply a normal
application plugin collection or establish OCIO workflows.

The installed `share/doc/natron/licenses/` retains the full upstream
`tools/license` inventory and source LICENSE/COPYING/COPYRIGHT/NOTICE files,
plus specific embedded-code notices and the patched `Global/QtCompat.h`.
Natron's main grant is GPL-2.0-or-later; the recipe also records the Qt
wildcard-port GPL-2.0-only alternative, BSD-3-Clause, MPL-2.0, Expat,
SGI Free Software License B 2.0 and Disney SeExpr-derived Noise's modified
Apache-2.0 trademark clause (retained in `source/Engine/Noise.h`). The retained
upstream component inventory describes broader historical binaries, including
optional plugin dependencies and older Python/Qt grants; it is **not** proof
that every listed library/plugin is installed in this core-only output.

### Build tests and integrated native receipt

The build compiles the complete upstream `Tests` target but runs only
**23 plugin-independent tests in 11 test cases**, using
`--gtest_filter=-BaseTest.*:OSGLContext.*:GPUContextPool.*`.
`BaseTest` needs separately supplied SeNoise/ReadOIIO/WriteOIIO plugins, and
the GPU/OpenGL-context tests are excluded. This is **not an entire upstream
suite pass** or a GPU-acceleration acceptance claim.

The integrated proof uses the actual installed `Natron` and `NatronRenderer`
under Xvfb/XCB with software GL, fresh HOME/XDG state, UID 1000 and private
user/mount/network/PID namespaces. Only loopback is present; the store is
read-only, and the only explicit host-writable bind is the evidence directory.
`natron-empty-project.png` captures the real 1190×952 empty GUI with zero nodes
and File/Edit/Layout/Display/Render/Cache/Help menus. The 31×23 File-menu crop
matches the independently rendered Droid Sans 11 reference exactly (131 glyph
pixels, both RGBA SHA256
`10356c96c128e96b96f16d13cafc8ae2645723c3ec44272263a129e1290f07eb`).
Capture uses `QScreen.grabWindow` on the live X framebuffer, not a synthetic
screenshot or OCR. `app.closeProject()` closes the GUI cleanly; exit status is 0.

A temporary **external** `NatronProof.ofx` fixture is compiled against the
pinned OpenFX headers outside the store (exit 0). Actual `NatronRenderer`
hosts `org.guix.NatronProofGenerator` connected to `org.guix.NatronProofWriter`
and renders **frame 1, 2×2 pixels** to `frame.ppm` (exit 0). Expected and actual
P6 bytes match exactly:
`50360a3220320a3235350aff000000ff000000ffffffff`, SHA256
`69d84c9c40bbfe1bfa0519120af54a299af34be4eebb31bb6a34b67aaae22f00`.
This proves the selected host/plugin/render path, not normal media decoding,
video encoding, a full creative workflow or the usual upstream plugin set.
`nar-before.txt` and `nar-after.txt` both contain
`02wx53j6vxl974ydwr3gcv5d3v8sagcs7k0v6h1azwk29rqhwl2f`, establishing
unchanged delivered output across the native proof.

To repeat the integrated proof, use the prebuilt output and a new/empty
evidence directory:

```sh
make check-natron NATRON_OUTPUT="$natron_out" NATRON_EVIDENCE=/tmp/natron-FRESH
```

## Medley and Maiko — verified native path

Final local acceptance on **2026-10-04** covers the source-built Maiko VM,
pinned Medley runtime and an external native consumer. Main owns all source
builds, bit-identical `--check` rebuilds, lint and standalone/integrated proof
runs; this documentation worker only read their receipts and authoritative
recipes, without running checks. Publication and issue closure are not
established by this local receipt. No user profile, deployed host or service
changed; no OKF page/log update applies. The 629-source snapshot ledger remains
unchanged.

### Source, boot images and licensed scope

[`interlisp-medley`](guix/tay/packages/interlisp-medley.scm) **2026.08.10** uses
the recursive original [`Interlisp/medley`](https://github.com/Interlisp/medley)
source at `634d092ed802314ada447878418686fbfeeb3048`, Guix base32 SHA256
`1d3dmhwcbwqi060679a9dsxsw45r37ppjskfn3a6n8d61h83bl95`.
[`maiko`](guix/tay/packages/maiko.scm) **2026.03.19** compiles the recursive
original [`Interlisp/maiko`](https://github.com/Interlisp/maiko) C source at
`9259716e9a797fefcdb59b6418b00f434c48dc40`, base32 SHA256
`1sd8w4rfjmc485qkg8jm0qv7hfcfy6nvxaa240sin03fjb1w7992`.
The source recipes are authoritative for these pins, not historical ticket
metadata or updater tag formatting. Maiko builds `lde`, X11 `ldex` and
`ldeinit` with deterministic revision/date metadata; SDL is disabled.
Both deliveries support **x86_64-linux only**.

The separate upstream [loadups archive](https://github.com/Interlisp/medley/releases/download/medley-260810-634d092e_260319-9259716e/medley-260810-634d092e-loadups.tgz)
is `medley-260810-634d092e-loadups.tgz`, release
`medley-260810-634d092e_260319-9259716e`, base32 SHA256
`0b6pnpckdsfxlxf2m7i9w6aj6s5618yhlvdqpz3ldm2aq1zqdw19`
(hex `29f0867fc04ad446c7bfb86d0a3d0aa6682395e1299e2a5ca7dde936d9b5d72c`).
Only `full.sysout` and `lisp.sysout` are extracted. These are **upstream-built
boot images, not images bootstrapped from source by Guix**; compiling Maiko
does not change that provenance. The proof boots `full.sysout`, SHA256
`cafd4c726ca338a6f6e7dab110f6e189482e8f55a593940817bebba6730d0ff5`.

The narrow installed scope retains Medley sources, CLTL2, library/lispusers,
CLOS, rooms, greetfiles, launcher/doctools/dinfo, internal runtime files,
Medley display fonts, PostScript c0 fonts and Xerox Unicode text tables.
Full Medley MIT and Maiko MIT LICENSE/NOTICE, historical file-level notices
and installed `share/doc/interlisp-medley/PROVENANCE` remain available.
Excluded are `apps.sysout`, Notecards, LOOPS, vendor/eastasia/iso8859 Unicode,
XCCStoUni binary, Xerox PDF and unaudited font trees; Maiko legacy build
metadata is not installed. Ethernet/Nethub support is disabled, **not native
Lisp sockets**. The acceptance consumer's offline namespace, not the program,
enforces network isolation.

### Final build and native evidence

Main's final source builds and bit-identical `--check` rebuilds passed for:

- `/gnu/store/ljgkdd2rig5y49qh8xygs57x1w5ynq25-interlisp-medley-2026.08.10`
- `/gnu/store/jfi95n7az8cplijqg2bx11yiff545v7f-maiko-2026.03.19`

Final scoped lint (bg16) exited 0 after initial actionable recipe warnings
were fixed. Its remaining updater suggestions are Maiko `260319-9259716e`
(the same pin) and Medley `260608.82054b35` (older June than the August pin),
not demonstrated upgrades. This does **not** claim whole-channel lint is clean;
unrelated Flex Launcher/Fourk and excluded unfinished WinRM diagnostics remain
outside this receipt.

Standalone proof `/tmp/medley-native-final-1/evidence.json` passed. Integrated
`make check-interlisp-medley` also passed (bg17,
`/tmp/medley-make-final-1/evidence.json`). The actual installed `ldex` process
resolved to the delivered Maiko closure. A real mouse click selected Exec;
real keyboard input evaluated `(IL:PLUS 273819 640572)` to **914391**, then
entered `(IL:SAVEVM)` and `(IL:LOGOUT T 0)`, exiting 0 without a forced kill.
Native screenshot recognition uses exact installed source-font bitmaps:
Helvetica10-MRR for the Exec title, Helvetica10-BRR for input echoes and
Gacha10-MRR for the arithmetic result, absent before evaluation. It does not
substitute OCR, fuzzy text or synthetic screenshots. Actual evaluated/saved
frames and `lisp.virtualmem` are retained in each evidence directory.
The saved virtual memory was 11,361,792 bytes and unchanged by logout; this
establishes SAVEVM output, **not verified restoration/resume**.

Fresh HOME/XDG/private temporary state, same UID 1000, private user/mount/net/
PID namespaces, only loopback and a read-only store isolated the external
consumer. Medley before/after NAR matched
`1674jzxjnbqjay0zkngiw3qf2w9r82zgv0r2bfh13xp8wlhnpw11` in both proofs.
Upstream supplies no full automated test suite (Maiko has no CTest suite);
disabled in-package tests are not a suite-pass claim. Selected boot/Exec/
arithmetic/save/logout paths do not establish every editor, library, optional
application, networking primitive or restored session.

### Usage and developer command

`guix shell -L guix interlisp-medley -- medley` starts the upstream graphical
environment with the full image by default. The installed `medley` launcher
binds its Maiko directory and runtime tools to store inputs while respecting
the user's HOME/LOGINDIR. `medley --continue` requests saved virtual memory
instead; this supported launcher option was not exercised by the acceptance
scenario.

Use a prebuilt output and a new empty evidence directory; `GUIX` resolves proof
dependencies before isolation:

```sh
make check-interlisp-medley INTERLISP_MEDLEY_OUTPUT="$medley_out" INTERLISP_MEDLEY_EVIDENCE=/tmp/medley-FRESH
```

## Lispy Rogue, bodge-nuklear and LiteGraph — verified native paths

Final local acceptance on **2026-10-04** uses source-built deliveries and
external native consumers. Main owns all build/check/lint/proof runs; the
documentation worker read the actual final JSON, NAR files and owner source
reports without executing checks. Publication follows signed channel history,
not a table label. No user profile, deployed host or live service changed;
no OKF service page/log update applies. The source ledger stays at 629 snapshots.

### Lispy Rogue

`lispy-rogue` **0.0.2** uses the original [`lockie/lispy-rogue`](https://github.com/lockie/lispy-rogue)
source revision `b2249bf7fe05e4ae53468d0f8855fcf4f4057337`, source base32 SHA256
`1f0n7smll05hgn2syqvzqnyybcvcfbjdq7227vkq8zb4g11lmb4x`, reusing the
reviewed snapshot origin. This graphical Common Lisp/Allegro Autumn Lisp Game
Jam dungeon crawler installs original game assets, full MIT/CC0/OFL notices
and Fantasque/Inconsolata font grants. Installer icons/cover, Tango artwork
and unused Roboto are omitted, not substituted into the game surface.

The compatible source closure includes MIT cl-astar
`00d37d04187ce42211b2029402ee46a6813a5bce`
(`1hx68wk2r290v1l5g4gp02rj33kc1zf7xbn5c5kmys83f9dq8j9f`), full zlib
cl-liballegro 0.2.28 revision `f788b9245bc1391c82fdc3d0c6ba1f08ce7eb63d`
(`0ap9gz6gvdprxrcbqvnkmk3jksrcddl58l5mmd6b58fxy73ds2vd`), MIT/public-domain
cl-liballegro-nuklear `eb45ded76be495c59c82bc743850db275119cb2a`
(`1nk9fxq170zf28c0rflgaffy7565jqvq9j7c8b0dpnjnmq0gk49n`), and zlib cl-tiled
`80332bfbf18734f342c9c2c7b6228560f64a3d54`
(`1wmh9df35sl4wd4n4nd050p9489zk4vwg32a5hsj2qqyrh2qvi8b`). Native Nuklear
library/offsets are rebuilt; Allegro retains Guix's absolute library loader.
Actual deploy revision `c9b869d` carries the zlib/Yukari Hafner 2017 grant,
not the inherited Artistic-2.0 metadata; its actual license is retained.
Actual Alexandria is `009b7e532071d9777bdbd63b82d776555da95916`, not the
historical ticket's `49e82add` pin.

The deterministic FASL launcher calls upstream
`deploy::call-entry-prepared` with `lispy-rogue:main`, using explicit
store ASDF source/output `conf.d` registries and `ignore-inherited-configuration`.
The rejected nondeterministic core dump is not delivered. Final source build
(bg1054), bit-identical rebuild (bg1058) and offline lint (bg1057) accepted
`/gnu/store/72znkzks8a1jy34zxqx08rdkvhkx1fl0-lispy-rogue-0.0.2`.
Native/integrated `make check-lispy-rogue` passed
(bg1059, `/tmp/lispy-make-exact-final`, `evidence.json` status passed/exit 0).
Actual input closed startup help, entered the dungeon, used `r` to produce
“You stand still.”, opened Inventory, reopened CONTROLS with F1 and closed
cleanly through `WM_PROTOCOLS/WM_DELETE_WINDOW`. A real Pulse stream was present.
Final screenshots are verified by exact RGB matching against the actual
source-font glyph coverage, not OCR, fuzzy recognition or replaced captures;
the older OCR-based receipts are superseded. The decoder applies Allegro's
exact integer blend `(175*c+127)//255` and exits before Xvfb teardown.
The [actual native game frame](.goocastle/evidence/lispy-rogue-native.png)
comes from this final run. Same-UID fresh-state private user/mount/net/PID
isolation exposed only loopback and read-only store. Before/after NAR matched
`0i9ja6xkbcqmkdkcza3p35zacy1syvq4x7dhifksb1lcsiizpd83`.
Main inspected the actual native frame: dungeon/player HUD HP 100/120,
MP 20/40, LVL 1 and the messages “You stand still.” / “You enter the dungeon.”
are visible without an error surface; this does not broaden scenario coverage.
Pinned upstream has **no save implementation**; selected help/dungeon/wait/
inventory/close paths do not establish combat, campaign, persistence or every
input control. Delivery is supported on x86_64-linux only.

### bodge-nuklear

`bodge-nuklear` **1.0.0-1.40adae4** builds the original
[`borodust/bodge-nuklear`](https://github.com/borodust/bodge-nuklear) parent
`40adae40e144143a4c3e12a9f4b96d5e2bb25155` with recursive Nuklear submodule
`3e13d3667878747dcddc3fe970cf33e6fdae204e`, recursive source NAR hash
`1qg3m1b1b43gbrqwpy9ryc8pnwz92wpxsfrkqqp85lghcnpj3sza`.
Core ASDF systems `bodge-nuklear-bindings` and `bodge-nuklear` depend on the
automatic source-built `nuklear-blob` adapter, delivered as `sbcl-nuklear-blob`.
The original native Makefile compiles the library, not a downloaded blob.
Optional generator/example systems are removed from the installed ASDF tree;
**this is not acceptance of `bodge-nuklear/example`**. Supported system is
x86_64-linux. The real `command-type` defect is corrected by returning CFFI's
already-translated enum keyword rather than decoding it a second time.

Wrapper MIT, generated bindings public domain, Nuklear MIT OR Unlicense,
embedded stb public domain and ProggyClean MIT grants are retained in full,
including parent/Nuklear/blob-ASD/font notices and submodule README. Exact
blob-ASD notice is from `39eb9e8fff1105a7a745279eea363f09193869d4`; font
author LICENSE is pinned at `139ec08a38096161291792313ef5803fc4f0e37b`.
Final wrapper `/gnu/store/rb7sfdvkvdy9ylx2daashz12pcxr2ylc-bodge-nuklear-1.0.0-1.40adae4`
and native adapter `/gnu/store/ariwyvf28lp5f2q2kx4d9grn6qicx67d-sbcl-nuklear-blob-1.0.0-1.40adae4`
passed builds and bit-identical checks (wrapper bg1030, blob bg1018), final
offline lint (bg1028), native proof (bg1029) and independent integrated proof
(bg1036, `/tmp/bodge-nuklear-make-final/proof.json`). The external ordinary
Lisp consumer registered/loaded the delivered library through
bodge-blobs-support/CFFI, created native font/context, observed real button
frames `[0,0,1]`, three label commands, 30 traversed draw commands and 21
font-width callbacks. Clearing emptied the commands and font/context
destruction completed. The unmodified original X11 demo source (with one
external-ABI include adaptation) was linked to the **same** delivered library;
native button release printed `button pressed` and WM_DELETE_WINDOW exited 0.
The [actual X11 demo frame](.goocastle/evidence/bodge-nuklear-native.png)
shows that native consumer, not the removed optional Lisp example.
Main inspected the actual Demo panel with button, easy/hard radio controls and
Compression 20; this is selected native demo-surface proof.
Fresh HOME/XDG/private tmp, UID/EUID 1000, private user/net/mount/PID/IPC
namespaces, loopback-only networking and read-only store left installed files
unchanged. Wrapper NAR before/after was
`1i2qjjikx34q69gch27zllw5crf22h6n3p7m10fx53qrnvxi4744`; blob NAR was
`144zwjq9bbq9px85ia917r5p0asxw3k0gaqihiyl2pfs6djw3x94`.

### LiteGraph

`litegraph` **0.7.14-0.0555a2f** uses original
[`jagenjo/litegraph.js`](https://github.com/jagenjo/litegraph.js) revision
`0555a2f2a3df5d4657593c6d45eb192359888195`, source SHA256
`2ed6280bc227a2676af01ff1061045ab1bf5343c047d16bb09760c20e3a270cb`
(base32 `1jvhlbij033n16xicz847hsga6xb8l80dw8zy1m6g8i7q85jimif`).
The original Grunt readable and minified bundles are regenerated using the
114-archive fixed-hash closure with every lock SRI SHA512 verified: Grunt 1.5.3,
CLI 1.4.3, concat 1.0.1, closure-tools 1.0.0 and task-closure-tools 0.1.10.
Exact locked Closure Compiler **v20171112**, not the newer package.json range,
is source-built; source hash is
`0gz1w6p3yiahz155xcrkzz7k9rwih58njl97kh3da9xcg0b9pvim`.
Its source-built Java closure includes protobuf C++/Java 3.0.2, jsinterop
annotations 1.0.0, error-prone annotations 2.0.18, Gson 2.7, Guava 20.0,
JavaPoet 1.7.0, AutoCommon 0.8, AutoService 1.0-rc2 annotations and AutoValue
1.4.1, plus Guix args4j 2.33/jsr305 3.0.1 and IcedTea 8 javac. Java annotation
processors, matching-protoc replacements for checked-in generated sources,
polyfill tables, externs ZIP and fixed release ParserConfig are generated from
source; no Maven/binary shade, npx or npm executable fetch replaces compilation.
The jar merges runtime source-built dependencies unrelocated/unminimized and
retains refactoring classes required by Linter. Guava's annotation-only
Objective-C/Android dependencies are removed following the Guix pattern.
Exact pins/hashes and retained copyright sources live in
`guix/tay/packages/litegraph-compiler.scm`; full Apache/MPL texts, source
copyright archives and dependency documentation remain under
`share/doc/litegraph-closure-compiler`. Compiler grants include Apache-2.0,
Rhino's alternative MPL-1.1/GPL-2+, args4j MIT and protobuf BSD-3.
Matching Esprima 4.0.1 source is compiled from TypeScript (source hash
`1dw4f6hp49xk0l2b9ldjr3lmy0bgsnwk13628zgr8d87g0jy8xa9`); async uses
readable individual modules instead of prebuilt Rollup distribution.

Only the inactive unlicensed Voxagon/Tuxedo Labs DOF **comment** is removed
before concatenation; no executable graph code changes. Installed bundles,
Editor, CSS, declarations and MIT interface images omit demo libraries/media.
Full third-party notices cover original GPUImage BSD-3 Kuwahara (predating
Shadertoy), webgl-meincraft BSD-3 FXAA, Raymond McGuire MIT XDoG, Wagner MIT
lens and Catlike MIT-0 bloom, all build-tool notices and compiler copyright
sources. Runtime bundle grants are MIT/BSD-3/Apache-2.0. Older outputs before
the final FXAA notice are superseded, not final acceptance.

Final licensed source build (bg1052), bit-identical check (bg1053) and offline
lint (bg1057) accepted
`/gnu/store/a2c02sg1l5bid5xr0h993vimjr507nvw-litegraph-0.7.14-0.0555a2f`;
its source-built compiler output `/gnu/store/3y1n6rljby6bvyzbqw05yyv290wq1mjc-litegraph-closure-compiler-20171112`
also passed `--check` (bg1049). Native/integrated proof passed
(bg1056, `/tmp/litegraph-make-final/evidence.json`, status passed/exit 0).
Independent Node processes executed both readable/minified engines: 7+5=12,
serialize/import/rerun=12, then mutate 11+5=16. The original upstream browser
Editor used trusted Chromium mouse/key/input events to drag a canvas node,
edit its number prompt, obtain 16 and import/rerun the graph. Both bundle
variants have genuine screenshots, including the
[actual native browser editor](.goocastle/evidence/litegraph-native.png).
Main inspected the actual Editor frame with connected A 11.000, B 5.000,
plus and watch 16.000 nodes and the Play/Step/Live toolbar, without an error.
Same-UID fresh-state isolated namespaces exposed only loopback/read-only store;
only local file/data resources were requested and failures were empty.
Before/after NAR matched
`14rz94ipbk6r61f8mv9m979h3sw3q66924v54vvcsmk2h5f839bv`.
Selected engine/serialization/editor interaction proof is not acceptance of
every audio, WebGL, remote-network or demo-media node.

### Wave 16 developer commands

Use prebuilt outputs and new empty evidence directories; `GUIX` resolves proof
dependencies before isolation:

```sh
make check-lispy-rogue LISPY_ROGUE_OUTPUT="$lispy_out" LISPY_ROGUE_EVIDENCE=/tmp/lispy-FRESH
make check-bodge-nuklear BODGE_NUKLEAR_OUTPUT="$nuklear_out" BODGE_NUKLEAR_EVIDENCE=/tmp/nuklear-FRESH
make check-litegraph LITEGRAPH_OUTPUT="$litegraph_out" LITEGRAPH_EVIDENCE=/tmp/litegraph-FRESH
```

The integration owner found no exact legacy registry objects 644/634/641;
absence is not represented as deleting unrelated contracts. Shared Makefile
and registry edits are outside this documentation change.

## Agduria, Wenyan and Ludvig Lundgren's qBittorrent CLI — verified native paths

Final local acceptance on **2026-10-04** used source-built programs and external
native consumers, not installed synthetic smoke modes. Main ran the serial
source builds, bit-identical `--check` rebuilds, scoped offline lint and the
standalone/integrated proofs described below. Publication is established by
signed channel history; no live service, deployed host or user profile change
is claimed. The known unrelated Flex Launcher/NHFourk lint findings remain
separate. The source collection stays at 629 snapshots.

### Agduria

`agduria` **0.0.1-0.92c20b1** compiles the original MIT/Expat C++20/ncurses
game at [`paulpekkarinen/Agduria` revision
`92c20b10724dcd7ba6ca3ccbf794600d8df01b7c`](https://github.com/paulpekkarinen/Agduria/tree/92c20b10724dcd7ba6ca3ccbf794600d8df01b7c).
The fixed codeload source has Guix base32 SHA256
`0y7w5r575ppdf466xlb8pc1w95jz1641hs9fvqzksmwa3d45h0mh`.
The historical research hash was invalid Guix base32; it is not reused as
verified provenance. The package preserves the original game, license and
documentation with a native launcher and pinned ncurses terminfo; it needs an
80×24 terminal with changeable color support.
Upstream has **no automated test suite**; disabling its nonexistent check
target is not a passing-suite claim. The interactive `T` command is exercised
by the external native consumer instead.

Final source build and reproducibility (bg985/bg986) produced
`/gnu/store/k7acy6vn33vzhiaairi1vh09wma5pp5c-agduria-0.0.1-0.92c20b1`.
Offline lint had no Agduria findings (bg991). The genuine native terminal run
(bg987, `/tmp/agduria-native-final-v2`) passed `AGDURIA_RUNTIME_OK`, native
exit 0 and external consumer exit 0. Actual arrow events moved the native
player from (38,9) to (39,9) and back to (38,9), with camera (0,0); screen
cells were (38,10), (39,10), (38,10), reflecting the header row.
`R` preserved the gameplay map: upstream `Remake_Current_Level()` is an empty
stub and performs only redraw, **not regeneration**. The `T` creature display
showed “Insect: ant”, then returned without altering gameplay. The actual
terminal/menu quit paths completed cleanly; no user-state files were created.
Before/after output NAR hashes matched
`0lfc9rwnhsvryhb7zn54gvflwicp4xbji0kqgzh0n6vajk6k02r9`.
The independent integrated `make check-agduria` also passed exit 0
(bg990, `/tmp/agduria-make-final`). Its integrated `evidence.json` also records
exit 0, preserved redraw/creature gameplay, no user-state files and the same
unchanged output NAR. Main inspected the
[genuine native dungeon screenshot](.goocastle/evidence/agduria-native.png):
magenta/white walls and the white `@` render, without a blank/error surface.
Proof used fresh HOME/XDG, same UID 1000, loopback-only private networking and
a read-only store. **Pinned upstream has no save/load**; no persistence,
regeneration, full campaign or physical-terminal acceptance is claimed.

### Wenyan

`wenyan` **0.4.0** builds the original compiler at
[`wenyan-lang/wenyan` revision
`97f0a4b8c5a815467c5c2cac08215d722efde208`](https://github.com/wenyan-lang/wenyan/tree/97f0a4b8c5a815467c5c2cac08215d722efde208),
reusing the reviewed source snapshot origin. Its Guix base32 SHA256 is
`0ks2krir22n8jlpfazy8ifw26xvfz797cqx5mlgpmiyd3xam1pbi`
(hex `71dd50551fcdc77a1fada56376d2f96e7723b88bc87fe52e95c80a91639e424f`).
Upstream is MIT; installed compiler/dependency grants include MIT, ISC,
Apache-2.0 and BSD-3-Clause. Its curated closure has 416 fixed npm archives and
501 contextual locations with locked integrity/hashes. Thirty-four external
`sync-request` runtime paths retain the real `sync-rpc` worker's `__dirname`.
Twenty-seven missing full-notice supplements use archived explicit grants or
exact upstream texts with provenance; original notices and TypeScript's
CopyrightNotice/ThirdPartyNoticeText remain under `share/doc/wenyan/npm`.
No curated native/WASM/font blobs are included; optional fsevents and unused
PNG test/coverage assets are excluded.

Upstream TypeScript declarations and Webpack CLI/core/render/browser-runtime
bundles compile from source, development/unminified despite retaining upstream
`index.min.js` filenames. Native `wenyan` provides JavaScript/Python/Ruby
compilation, JavaScript execution, standard library and examples; the installed
`require('wenyanlang')` library is available. The build check compiles the
bundled recursive `factorial.wy` and captures exact `[[120]]` through
`evalCompiled`: **this is a focused check, not the full upstream Jest suite**.
Original Jest/lint/wiki/site development tools are outside this package closure.

Final build/reproducibility (bg978/bg981) produced
`/gnu/store/7qcd57z6zsv05f5al85k8a111i16xicp-wenyan-0.4.0`; final offline
lint had no Wenyan findings (bg984). The integrated native consumer passed
(bg988, `/tmp/wenyan-make-final`): bundled hello emitted `問天地好在。`;
separate native CLI compile plus Node execution and direct CLI execution each
emitted `120`, `40320`, `7` for factorial 5, factorial 8 and embedded 算經
absolute-value of -7. Ordinary installed library import returned exact
`[[120],[40320],[7]]`; every exercised process exited 0. Compiler API diagnostic
records remain separate. The fresh-HOME/XDG, same-UID private user/mount/net/PID
proof exposed only loopback and a read-only store; before/after output NAR was
`1bsvvrvgnrh8h80fxvv31wlxzhv6jqwgs3xp2rl2i7k0hgj4qj0n`.
No full Jest-suite, browser visual surface or remote-HTTP behavior is claimed.

### Ludvig Lundgren's qBittorrent CLI

`ludviglundgren-qbittorrent-cli` **2.3.0** is the canonical Go client at
[`ludviglundgren/qbittorrent-cli` revision
`7b5f87de149d699c0bd955867fe5d57418b6ec68`](https://github.com/ludviglundgren/qbittorrent-cli/tree/7b5f87de149d699c0bd955867fe5d57418b6ec68),
with reviewed source origin base32 SHA256
`19d52qki17mkq7x0g0y2fdmvyc1mpnnm0rdgmkfh2143qjscr3wy`.
It is distinct from the separate project tracked by issue #119, which is
untouched. Commands are native `qbt` and its `qbittorrent-cli` symlink. The
client manages torrent, category, tag, transfer and application Web API calls;
it **does not install a daemon or create/replace client configuration**. Its
explicit updater is not exercised by acceptance.

The offline Go 1.25.12 GOPATH closure uses 67 immutable Go ZIP source nodes,
208 module notices plus compiler/stdlib notices and four retained full MPL
source groups (torrent, generics, Hashicorp LRU, x/net). The client is MIT;
compiled inputs retain MPL-2.0, Apache-2.0, BSD, public-domain, CC-BY-4.0 and
CC0 grants. Exact x/net publicsuffix data and MPL license are pinned at
`d6c92f1bbb7433e5db7b8405c25d4035fb8ff376`, with data hash
`1gp79v8x2v57lqrl2lhixvr4n0idxbwpclvs28mr133y2n0q4qx5` and license hash
`0wji1lq3xnj4b3zd0pa6747fvcnc8wharsjknym5i86nb9yi18v6`.

Final source build/reproducibility (bg973/bg981) produced
`/gnu/store/91arv85x4kr00d779kwcczz0l7gbk9ym-ludviglundgren-qbittorrent-cli-2.3.0`;
offline lint had no package findings (bg984). Native acceptance passed
(bg982, `/tmp/qbt-native-final-v2`) and independent integrated
`make check-ludviglundgren-qbittorrent-cli` passed
(bg989, `/tmp/qbt-make-final`). Help/version and alias-version created no
configuration. The real scratch qBittorrent 5.1.4 daemon started empty at
loopback Web UI, accepted a trackerless 74,000-byte generated torrent, and
native CLI add/list/category-create/tag-create/category-assign/list/remove
calls were checked independently through its real API. The torrent had hash
`76a1443d91f47d5cc5c2e6cfada62154fee2c1f3`, category `native-proof` and tag
`native-offline`; removal retained payload SHA256
`774e816c41f53d0b40804114e96afaab73b6dc19dc01f53b8a0b067b4f9edf23` exactly.
The daemon ended with no torrents and shutdown exit 0. Same-UID fresh
HOME/XDG/user/mount/net/PID isolation exposed only loopback and a read-only
store; output NAR was unchanged at
`0rjzlzhdzd6mdyp0avv0dsdpjgi3nn0hsqls8lrvf3a47ygqhw5s`.
This is genuine isolated local-daemon proof, **not** a live seedbox/service,
tracker, peer-transfer or remote-network verification.

### Wave 15 developer commands

Use prebuilt outputs and fresh empty evidence directories; proof-only tools
are resolved through `GUIX` before offline isolation:

```sh
make check-agduria AGDURIA_OUTPUT="$agduria_out" AGDURIA_EVIDENCE=/tmp/agduria-FRESH
make check-wenyan WENYAN_OUTPUT="$wenyan_out" WENYAN_EVIDENCE=/tmp/wenyan-FRESH
make check-ludviglundgren-qbittorrent-cli QBT_CLI_OUTPUT="$qbt_out" QBT_CLI_EVIDENCE=/tmp/qbt-FRESH
```

Exact synthetic contracts are accounted for by the integration owner; native
acceptance does not imply any Goocastle executor or live deployment. No OKF
service page/log update applies to these repository-only additions.


## Martin's Dungeon Bash — native gameplay and save continuity (2026-10-07)

The existing `martins-dungeon-bash` **1.7** entry now delivers the original
C/ncurses game through ordinary `bin/dungeonbash`, which execs
`libexec/dungeonbash` without a test mode or gameplay replacement. The source
is the upstream [1.7 archive](https://www.chiark.greenend.org.uk/~mpread/dungeonbash/archive-1.7/dungeonbash-1.7.tar.gz),
SHA256 `790bde04ff869ba2817ad1f07d062d75f7f15af4a2c99669dd60a4b98fdf1380`
(Guix base32 `100kvy7vk930vmlrdjd2yidg3xvm5l37vw6iga0s56w6zw2dw2vr`).
This is an existing-package promotion, **not an inventory increase**; the
629-source ledger and unrelated work remain unchanged.

The code is **BSD-2-Clause**: `notes.txt` contains the full copyright, two
redistribution conditions and disclaimer, and all **19 C/header members**
repeat the full terms. The complete **19,827-byte** notes file is installed at
`share/doc/martins-dungeon-bash/notes.txt`, SHA256
`b20fe51930fbc81e44900ec5806e9286ba58edad9c975891b18f9c344e6e4d93`.
There are no separately loaded game assets. Archive HTML spoilers are not
installed because their separate documentation rights were not verified;
they are not replaced with invented content. Upstream has no automated test
target. The build retains warning checks but does not promote historical GCC
warnings to errors; a successful build is not a warning-free-source claim.

The launcher places upstream relative saves, character dumps and death log
in `$XDG_STATE_HOME/martins-dungeon-bash`, falling back to
`$HOME/.local/state/martins-dungeon-bash` when `XDG_STATE_HOME` is unset,
empty or relative. Store-resolved gzip/gunzip and terminfo avoid dependence
on caller `PATH`. Native `S` saves and exits; the next ordinary launch
automatically restores **and consumes** `dunbash.sav.gz`. No runtime download,
shared playground, setuid or setgid installation is introduced.

Main's source build **bg481** (5.49 seconds, artifact 15285) and reproducibility
rebuild **bg482** (2.25 seconds, artifact 15286) produced the same output:
`/gnu/store/f2w2iggpxbi3i2issyz4blnq1vlmrd4m-martins-dungeon-bash-1.7`.
Native acceptance **bg485** passed (5.62 seconds), with actual evidence at
`/tmp/dungeonbash-native-2`: raw PTYs, input/process records, decoded screens,
raw map cells and `continuity.json`, not an installed smoke helper.
Independent integrated `make check-martins-dungeon-bash` **bg486** passed
(10.40 seconds) against that same prebuilt output, using fresh evidence at
`/tmp/dungeonbash-make-final`; its actual driver marker is
`MARTINS_DUNGEON_BASH_NATIVE_OK`. Its continuity record separately establishes
the full visible map/HUD restore with the same blank-color boundary, consumed
save, independent process and unchanged caller state. Main also checked the
JSON contracts with `jq` (exit 0, 0.02 seconds). Main inspected the native-2
restored screen: **Native1**, HP **20/20**, food **1999**, depth **1**, body
**10/10**, agility **10/10**, real `@`, newt/rat glyphs and room walls, not a
blank or error surface. The integrated run generated a different real dungeon;
its own restored map is compared to its own pre-save state, not to native-2.

The first real 80×24 PTY entered the normal name prompt as **Native1**, moved
with native input (food **2000 → 1999**), opened inventory and saved/exited
**0**. A separately launched process, PID **5** rather than **2** in the private
PID namespace, restored the original **2,517-byte** compressed save without
reinjection of its evidence copy. The full **21×21 visible map** and complete
two-line HUD restored exactly: **HP 20/20, XL 1, Body 10/10, Gold 0, Defence 2,
Food 1999, Depth 1, Agility 10/10, XP 0**. Every nonblank map cell's decoded
style and every HUD cell's style matched. Only foreground/background colors
of attribute-free map spaces were canonicalized: upstream emits spaces for
unexplored/outside-map cells, which curses may paint white-on-black or erase
using terminal defaults. Raw cells remain available; this is **not** an
unqualified byte-for-byte terminal-stream or raw-blank-color equality claim.

The resumed game accepted native `h`: wall scrolling witnessed a westward
world step while the player stayed at viewport `(10,10)`, and food advanced
**1999 → 1998**. Native `i` displayed the dagger **100/100 (in hand)** and
**1 iron ration** without taking a turn. Native `X`, capital `Y`, then RETURN
quit normally with exit **0**, leaving no save. Viewport coordinates are not
world coordinates, and this proof does not decode all hidden serialized state,
establish RNG continuity, exercise combat/deeper levels or demonstrate wins
(upstream describes an endless dungeon with no victory condition).

Fresh HOME/XDG/work directories, same ordinary UID **1000**, private
user/mount/net/PID namespaces, loopback-only networking and a recursively
read-only store bounded the proof. Caller game state was unchanged; after save
consumption/quit only the empty private `state/martins-dungeon-bash` directory
remained. Before/after output NAR was identical:
`10hp82409bnd5zb3k5klhj3xi2p8w6k3yirq9pk9x3cf3pwxwrwx`.
This is local repository/runtime evidence, not profile installation or
deployment. Implementation verification is complete; the signed publication
receipt is tracked separately after commit authentication and normal-origin
publication. No network OKF service page/log update applies.

**Clean-own-lint acceptance and signed publication are verified; issue #438 is verified closed on [Forgejo](https://forge.nogroup.group/tay/guix-channel/issues/438#issuecomment-3243) and [GitHub](https://github.com/htayj/guix-channel/issues/438#issuecomment-6045690326).** After adding honest `upstream-name` and
`release-monitoring-url` metadata, full lint **bg488** passed in **6.72
seconds** with no package-specific findings; only the unrelated deprecated
`flex` diagnostic remained. The generic HTML updater now uses the
canonical homepage and upstream tarball name `dungeonbash`, rather than
the fixed-version archive directory. The earlier offline lint attempt
**bg483** failed in that updater and is superseded by this full-lint receipt.
Final build-identity selection **bg489** passed in **0.90 seconds**, returning
the same `/gnu/store/f2w2iggpxbi3i2issyz4blnq1vlmrd4m-martins-dungeon-bash-1.7`
output. Source pin and runtime are unchanged, so the earlier **bg481**,
**bg482**, **bg485** and **bg486** receipts still apply to that immutable
output; this metadata correction did not rerun native gameplay.
This is not a warning-free whole-channel lint claim or authorization to claim
issue closure before signed publication.


---

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

## KLH10 host-only emulator runtime proof

`klh10` builds the original KL10 and KS10 host emulator from
[`PDP-10/klh10` revision `6d733f2a47644964492fd864454cbe1331655e53`](https://github.com/PDP-10/klh10/tree/6d733f2a47644964492fd864454cbe1331655e53)
as `2.0l-guix-0.6d733f2`.  The fixed source archive has Guix SHA256 base32
`1kg68m8yyd3za3y4yjfi5lrbf1hipvamqqv3dq7m5kgb61x19br8`.
It installs `kn10-kl`, `kn10-ks` and `kn10-ks-its`, with `klh10` pointing to
the KL model; `wfconv`, `tapedd`, `vdkfmt`, `wxtest`, `udlconv` and `uexbconv`
are available in `bin`, and disk/tape helpers `dprpxx` and `dptm03` in
`libexec/klh10`.  The emulator uses absolute store paths for those helpers.
The origin removes `run`, `contrib`, installation/guest guides and the
Auxiliary Distribution metadata before building.  No guest operating systems,
boot images, network-interface processes or services are included.

The host grant is the custom **KLH10 Free-Fork (eight clauses)**
[`LICENSE`](https://raw.githubusercontent.com/PDP-10/klh10/6d733f2a47644964492fd864454cbe1331655e53/LICENSE),
not the later nine-clause UW variant with an export restriction.
The pinned [`README`](https://raw.githubusercontent.com/PDP-10/klh10/6d733f2a47644964492fd864454cbe1331655e53/README)
states that use is unrestricted and explicitly excludes `run` and `contrib`
from that host grant.  Its source-sharing, origin-label, notice-retention,
no-endorsement and warranty terms are the basis of this channel's host-only
free-software assessment; they do not prohibit commercial use.
The clause-equivalent UW Free-Fork grant in
[`uw-imap` in Debian sarge/main](https://sources.debian.org/src/uw-imap/7%3A2002edebian1-11sarge1/debian/copyright)
is historical distribution precedent, **not formal GNU Guix acceptance,
named FSF approval or a legal opinion**.  License sources were read on
2026-10-02.  Modified binaries are distributed together with the corresponding
complete sanitized, modified source under `share/klh10/source`, and the license,
README and console/developer documentation under `share/doc/klh10`.
Modified version banners carry the `-guix` origin tag.  Source transformations
use Latin-1 decoding/re-encoding to preserve original copyright notice bytes.

```sh
guix build -L guix --no-grafts klh10
make check-klh10
klh10                 # guest-free interactive console; type help
```

On 2026-10-02, local source build, reproducibility rebuild (`--check`), offline
lint and isolated runtime smoke passed for
`/gnu/store/lvb2kkazajacmzh6fkh6dz4glncyh841-klh10-2.0l-guix-0.6d733f2`
using OMP tooling.  `tests/klh10-smoke.sh` and `tests/klh10-smoke.py` use fresh
HOME/XDG state and isolated user, mount, network, IPC and PID namespaces.
Three actual console PTYs deposit `MOVEI AC1,123` at octal `100` and `HALT`
at `101`, execute them, and verify AC1 changes from zero to octal `123`,
PC is `101` and the CPU is `STOPPED`.  Each also deposits the maximum 36-bit
word and verifies native memory zeroing.  `wfconv` preserves every bit of the
chosen 36-bit patterns (including zero, maximum and instruction words) through
core/high-density/core conversion.  `vdkfmt` verifies exact nonzero disk-word
serialization and inverse conversion between DLW8 and DBD9.  `tapedd` verifies
exact TPS/TPE/TPS records, including odd-length padding and tape marks.
Actual tape-image conversion exposed an upstream defect: successful copies
retained a failure return status, and the no-skip path read an uninitialized
error variable.  The recipe fixes the return status and initializes that
variable rather than ignoring a failing converter exit.

Set `KLH10_SMOKE_ARTIFACTS=/absolute/path` to retain logs, the summary and all
three complete raw console streams.  Final local evidence is in
`/tmp/omp-klh10-final`; before/after output NAR hashes match.
`.goocastle/evidence/issue-57.png` is the inspected 100×40 xterm rendering of
the unmodified `kn10-kl-terminal.raw` stream, showing `01/ 123`, the stopped
CPU at PC `101` and `Program Halt`.  It is OMP-produced terminal evidence,
not a Goocastle execution.  This proves only the exercised host CPU, console
and synthetic image-conversion paths: **no physical tape, guest OS or network
device operation was verified**.  No profile or deployed system changed;
no network OKF update applies to this repository-only addition.

## SUPPTY original host-client runtime proof

`pdp10-suppty` builds the original GTK 2 terminal client and command-line
frontend from
[`PDP-10/SUPPTY` revision `2da0135f2f3069db4b692155887d4076e67d6fac`](https://github.com/PDP-10/SUPPTY/tree/2da0135f2f3069db4b692155887d4076e67d6fac)
as `0-2da0135`.  Its source snapshot has Guix recursive NAR SHA256 base32
`18mzn29b1pkngp1zxsc7vhaxf8vvyykagrqk8qvy85yhrg5p78a5`.
The pinned root
[`LICENCE`](https://raw.githubusercontent.com/PDP-10/SUPPTY/2da0135f2f3069db4b692155887d4076e67d6fac/LICENCE)
grants **MIT/Expat** permission, including modification, redistribution and
commercial use; the source snapshot's license metadata now reflects that
grant.  The earlier missing-license blocker does not apply to this revision.
The original license and README are installed under
`share/doc/pdp10-suppty-0-2da0135`.

The package installs only `suppty` (GTK 2) and `suppty-plink` (CLI), with
matching namespaced manual pages, so it can coexist with PuTTY without command
or manual-page collisions.  The original SUPDUP, SSH, Telnet, rlogin, raw TCP,
serial, session configuration, proxy and terminal functionality is retained;
**only SUPDUP was exercised here**.  This preservation package is not a security
endorsement of its old SSH implementation.  No guest software or public
service is included.  Plink forwards SUPDUP display bytes without terminal
emulation; use the graphical client for its original SUPDUP terminal renderer.

The recipe adds the missing SUPDUP backend to upstream's `Recipe` before
regenerating object lists.  `perl -I. mkfiles.pl` allows the charset generator
to load `sbcsgen.pl` with modern Perl and prevents its swallowed load failure
from leaving source scanning in the wrong working directory.  Line-discipline
and ITS/WAITS charset translation now use their actual terminal contexts,
including the CLI's absent terminal, rather than an out-of-scope `term`.

```sh
guix build -L guix --no-grafts pdp10-suppty
make check-suppty
suppty-plink supdup,HOST   # or load an original saved SUPDUP session
suppty                    # original graphical session configuration
```

On 2026-10-02, local source build, reproducibility rebuild (`--check`), offline
lint and isolated actual CLI/GTK runtime smoke passed for
`/gnu/store/lc6drsyahfmpipim6gl5q7q9m1zmlwfn-pdp10-suppty-0-2da0135`
using OMP tooling.  `tests/suppty-smoke.sh` and `tests/suppty-smoke.py` use fresh
HOME/XDG/session state, private user, mount, network and PID namespaces, and
private Xvfb.  The only network interface is loopback.  An original local
SUPDUP fixture verifies both clients' actual RFC 734 36-byte six-bit handshake
(six 36-bit words), geometry/options and location negotiation.  The CLI
receives the exact original fixture stream and sends `CLI_INPUT_60` back on
the socket.  The live GTK terminal receives protocol display commands;
`xdotool` types `ROUNDTRIP60` into its actual window, the fixture verifies the
exact keyboard bytes and sends them back for rendering.  Both clients exit
zero on clean remote EOF.  CLI `--help` and `--version` retain upstream's
exit status 1; those transcripts are recorded, not normalized into success.

Set `SUPPTY_SMOKE_ARTIFACTS=/absolute/path` to retain command provenance,
handshakes, location/input bytes, session configuration, result JSON and actual
GTK window/desktop captures.  Final local evidence is in
`/tmp/omp-suppty-font-fixed`; the before/after output NAR hashes match.
`.goocastle/evidence/issue-60.png` is the inspected actual GTK terminal capture,
showing `SUPPTY LIVE HOST CLIENT`, `Original local SUPDUP protocol fixture`,
`ROUNDTRIP60` and `KEYBOARD ROUND TRIP VERIFIED`.  It is OMP-produced runtime
evidence, not a Goocastle execution or a connection to a remote PDP-10 host.
This proves the exercised local SUPDUP client paths, not remote historical
host interoperability or other protocols.  No profile or deployed system
changed; no network OKF update applies to this repository-only addition.

## Hermes Desktop and packaged backend

`hermes-desktop` **2026.9.24** and `hermes-agent` **0.21.5** share
[`NousResearch/hermes-agent` revision `f97608f178d1ffeca59860195ab7da295f7c8e5f`](https://github.com/NousResearch/hermes-agent/tree/f97608f178d1ffeca59860195ab7da295f7c8e5f),
with Git-tree NAR base32 hash
`1wfgjy7a8jpk90pmn5y5kn3girqms5x0av0lhw7y62c7dyh5m8yb`.
These are the actual upstream desktop renderer, preload/main process and
headless JSON-RPC/WebSocket backend, not a browser-only substitute or a
wrapper around an independently installed backend.  The desktop binds its
packaged backend; `hermes`, `hermes-agent`, `hermes-acp` and `hermes-python`
provide the backend's ordinary CLI/runtime interfaces.  The desktop output
includes a `hermes-desktop` launcher, `hermes.desktop` application entry and
icon.  Both recipes currently target **x86_64-linux**.

**This is explicitly binary-assisted, not fully source-built or an all-free
closure.**  Application code and CPython come from source, but the desktop
uses the fixed upstream Electron **40.10.2** Linux executable through Nonguix,
with Chromium redistribution notices retained.  npm archives are pinned to
the source lockfile, including vendor native build-tool bindings; the terminal
addon is rebuilt against the exact Electron headers.  Python 3.11 dependencies
include fixed upstream wheels from `uv.lock` (the missing `sherpa-onnx-core`
dependency is separately pinned to its official PyPI release).  That closure
includes Intel/NVIDIA binary redistribution terms alongside free licenses.
Original manifests, notices and required corresponding-source materials are
retained rather than implying that every aggregate is MIT-licensed.
Native **PyAV 17.0.0, Pillow 12.3.0 and pillow-heif 1.5.0** replace their
vendor wheels with source builds and Guix codecs; HEIF support is not reduced
to a decoder-only substitute.

Restricted/unverified bundled UI fonts are removed from the npm UI origin.
Redistributable IBM Plex and GNU Unifont replace those faces while retaining
CSS typography roles; unchanged JetBrains Mono terminal faces and their OFL
notice remain.  Font bytes/internal names are not renamed or altered, and
the installed font notices describe the substitutions.

```sh
guix build -L guix --no-grafts hermes-agent hermes-desktop
hermes-desktop        # desktop launcher after installation/profile setup
hermes serve         # ordinary backend server interface
make check-hermes-desktop
# Backend-only proof, without building/launching Electron:
GUIX=guix sh tests/hermes-desktop-smoke.sh --backend-only \
  --evidence /absolute/empty-evidence-directory
```

Package code/data stay immutable in `/gnu/store`; normal user configuration
and state remain writable under `${HERMES_HOME:-$HOME/.hermes}` and desktop
user-data paths.  Guix installation detection **does not enable
`HERMES_MANAGED`**, which would incorrectly disable configuration writes.
The packaged code blocks in-place self-updates and lazy dependency installs;
desktop update/repair actions give Guix instructions rather than downloading
another checkout/backend into the user's home.  Upgrade through the channel
and Guix profile/Home/System workflow (for example, `guix pull` followed by
`guix upgrade hermes-agent hermes-desktop`), not Hermes's git/pip updater.
Chromium sandboxing and renderer isolation remain part of the desktop recipe;
the acceptance does not fall back to `--no-sandbox`.

### Remote HTTPS and constrained private CAs

Gateway discovery, authenticated REST requests and streaming downloads use
Electron's native Chromium network stack, matching the renderer's HTTPS and
WebSocket certificate verifier.  Main-process connection tests also perform a
genuine WebSocket upgrade in a short-lived sandboxed Chromium renderer, rather
than accepting HTTP reachability as proof of WebSocket connectivity.  This
deliberately replaces the gateway helpers' Node `https` and WebSocket probes:
Electron 40.10.2 links Node against BoringSSL's legacy X.509 verifier, whose
name-constraint matcher does not implement IP constraints.  Adding a CA through
`NODE_EXTRA_CA_CERTS` cannot repair that unsupported constraint type.  Chromium's
modern PKI verifier supports IP address/netmask constraints and enforces
constraints on NSS trust anchors.

Certificate-chain, validity, hostname/IP and critical name-constraint checks
remain enabled; there is no certificate-error override, verification bypass,
certificate rewriting or local proxy.  The migrated token/public/download
helpers do not follow redirects and omit ambient cookies from token/bearer
requests; native OAuth's existing dedicated cookie-session flow is unchanged.
Private CAs must be trusted
through Chromium's platform trust store (on Linux, NSS), not Node's extra-CA
environment variable.  The package neither ships a site-specific CA nor edits
the user's trust store, connection registry or credentials.  A trust change
requires restarting Desktop so both network contexts load the same trust.

Implementation references (retrieved 2026-10-03):
[Electron 40.10.2 ClientRequest](https://github.com/electron/electron/blob/v40.10.2/docs/api/client-request.md),
[its Chromium/Node pins](https://github.com/electron/electron/blob/v40.10.2/DEPS),
[the pinned legacy matcher](https://github.com/google/boringssl/blob/b94d71f87ff943a617d77f3ff029f9a01a1ec6bc/crypto/x509/v3_ncons.cc),
[modern IP constraint matching](https://github.com/google/boringssl/blob/b94d71f87ff943a617d77f3ff029f9a01a1ec6bc/pki/name_constraints.cc),
and [Chromium 144 NSS trust-anchor enforcement](https://github.com/chromium/chromium/blob/144.0.7559.236/net/cert/internal/trust_store_nss.cc).

TLS cutover verification (2026-10-03): pinned source anchors applied and the
targeted retry, failure-atomic download and native WebSocket lifecycle suites
passed (3 files, 56 tests).  Review found and corrected Electron's early
Writable `close` lifecycle hazard; a generated-helper simulation verifies that
early upload completion does not abort delayed JSON/download responses.
Neither the unit tests nor that simulation prove certificate verification.
The serial package build subsequently passed after the user freed RAM; its
accepted output is
`/gnu/store/5nhbmc1lmcyxsmqwzfkx6z3qybn9xbl8-hermes-desktop-2026.9.24`.
A build-only 2048 MiB V8 heap bound is retained; host protections and runtime
settings are unchanged.  Actual built-app `tests/hermes-desktop-tls.sh`
acceptance passed using only disposable HOME/XDG/NSS trust.  Negative-first
wrong-hostname, untrusted-chain, constrained-IP and additional-outside-SAN
fixtures rejected both HTTP and genuine renderer WSS before any HTTP/upgrade
request; the permitted IP fixture passed supported discovery/Test IPC and
separate main/renderer WebSocket upgrades.  Four separate bad-certificate
switches after successful HTTP status also rejected the main WSS leg without
an upgrade.  Chromium redacts renderer WSS diagnostic text: negative evidence
is an actual network error, no open/status/request, and the positive control,
not an invented certificate-error string.  The real remote's discovery and
renderer HTTPS returned 200; a linked native Chromium NetLog WebSocket
handshake refusal returned 403, proving TLS but not authentication.  Raw
NetLog remains disposable; exported evidence contains only status/source
facts.  Sandbox seccomp/no-new-privileges and unchanged output NARs were
checked.  TLS evidence is `/tmp/hermes-desktop-tls-passed-20261003`.
The separate native/backend/Electron smoke also passed, including actual
local `gateway.ready`, in `/tmp/hermes-native-cutover-smoke-20261003`.
Neither suite accessed credentials or called a model.  Authenticated
real-remote `gateway.ready` and user-profile cutover remain separately owned
deployment checks, not verified by these credential-free tests.

Wake engine Python interfaces are retained, but **licensed wake assets must
be supplied by the user**; no engine/model asset is silently downloaded.
openWakeWord's keyword and feature models use local paths and
`HERMES_WAKE_MODEL_DIR` (default `$HERMES_HOME/wakewords`).  Sherpa KWS needs
`wake_word.sherpa.model_dir` containing tokens, BPE and encoder/decoder/joiner
ONNX files.  Porcupine requires its separately licensed local `.ppn`, native
library and model paths (`wake_word.porcupine.keyword`, `library_path`,
`model_path`, or the corresponding `HERMES_PORCUPINE_LIBRARY` /
`HERMES_PORCUPINE_MODEL` overrides), plus the user's access key.  Provider
credentials and inference models likewise remain user-supplied; none are
needed or accessed by the repository smoke.

**Baseline verification (2026-10-03, before the native TLS transport cutover):
backend and desktop builds, `guix build --check` reproducibility rebuilds,
offline lint and actual native/backend/Electron acceptance passed.** The
baseline checked outputs are
`/gnu/store/5ngz28ls6p1hx25fp9im0dilpq4v5zqx-hermes-agent-0.21.5` and
`/gnu/store/r5jwrqdlkwlzbwlpyrif5yz1gsd43q4b-hermes-desktop-2026.9.24`.
Import-generated timestamp bytecode caches were normalized to checked-hash
`.pyc` files; npm archive-layout handling retains redistribution notices.
Offline lint reported no Hermes findings (existing flex/Fourk warnings remain).
Final evidence is under `/tmp/hermes-desktop-acceptance-sandbox`.

The actual `hermes serve /api/ws` proof covers health/identity,
`gateway.ready`, persisted theme configuration roundtrip and explicit
`guix_update_unsupported` refusal.  Native imports and PNG/HEIF/PyAV
color-conversion roundtrips passed; missing wake assets produce explicit
errors.  The installed Electron app ran on private Xvfb/D-Bus with its own
packaged local backend, real preload bridge, `backend.ready` (not fake mode)
and visible no-provider onboarding.  Main-process update IPC returned manual
`guix upgrade hermes-desktop` instructions.  Renderer Node isolation passed;
the actual renderer identity from browser CDP had seccomp mode 2 and
`NoNewPrivs=1`.  Final cleanup and before/after NAR checks passed: backend
`0bz3qj9jrgik1hd2hvd8qd7rx21a5152s577gshw9jlnnyjjn8w6`, desktop
`01r7z085q9d2mpwh9w1l7rsgjbv86x6rqc6xqjh8daqb4lqv4g8s`.

Actual desktop interaction chose “I'll choose a provider later”, opened the
**Settings → Model → Main model** panel, closed settings and entered an
**unsent** `Guix desktop acceptance — unsent draft`.  Durable screenshots
are [the native composer](.goocastle/evidence/hermes-desktop.png) and
[native settings](.goocastle/evidence/hermes-desktop-settings.png).  The
inspected composer shows that draft with no response/error; the settings
show Provider/Model controls, Reasoning, context-window override and the
Appearance and other categories.  Empty provider/model selections and
“Gateway needs setup” are expected in this credential-free proof, not
evidence of a configured provider.  These are copied actual Electron
captures, not Goocastle execution or an artificial success buffer.

`tests/hermes-desktop-smoke.sh` realizes its own pure test tools even with
prebuilt `--backend` / `--desktop` outputs and retains reports, a screenshot
and before/after NAR hashes in an empty absolute `--evidence` directory.
The integrated `make check-hermes-desktop` target also passed, with evidence
under `/tmp/hermes-desktop-evidence.WRYpbG5H`; Guix's explicit store `make`
was used because the host had no `make`, without changing the recipe.
The report records **zero model calls**, **no live wake verification** and
no credential source (fresh HOME with an explicit environment allowlist).
The passive update-notification cache is synthetic for offline startup;
it is not proof of the latest upstream version.  Acceptance disables GPU
use: real provider/model inference, GPU acceleration, microphone and live
voice/wake recognition remain unverified.  No upstream service/browser
test-suite completion or deployed/profile installation is claimed.  This
repository integration makes no deployed-system correction, so no network
OKF update applies; deployment belongs to the separate installation session.

## NitroHack original curses game and save continuity

`nitrohack` builds the original **NitroHack 4.0.4** wide-curses game from
[`DanielT/NitroHack` revision `21b9774b24efbdafdd20e152f9b1e5ed2a7b4150`](https://github.com/DanielT/NitroHack/tree/21b9774b24efbdafdd20e152f9b1e5ed2a7b4150).
The immutable Git-tree NAR base32 hash is
`0s36b2wy5fm30lfpmsa9f00n4ykr4d2cak7rmrirf35ss5vxapgn`.
Code, maps, generated `nhdat` and documentation come from that same tree.
Its full **NitroHack General Public License** is the NetHack license renamed
in December 2011, represented by Guix's `fsdg-compatible` constructor with
the [canonical NGPL URL](https://nethack.org/common/license.html).
The installed `share/nitrohack/license` retains that grant; README,
Guidebook and Debian copyright notice credit Daniel Thaler and the NetHack
Devteam under `share/doc/nitrohack`.  No bundled fonts, tiles or sound assets
are installed, and the Windows icon is outside this curses output.

The full original curses client's **network capability is retained** with
`ENABLE_NETCLIENT=ON`; only the optional PostgreSQL server is disabled with
`ENABLE_SERVER=OFF`, as explicitly requested in the original issue-456
delivery brief.  This is not a reduced dummy game.  The offline acceptance
below proves local gameplay, not a network-client connection or server runtime.
The launcher supplies Guix library/terminfo paths and forwards ordinary
arguments to `libexec/nitrohack-real`; generated resources stay immutable in
`share/nitrohack`.  Native configuration, saves and logs use
`${XDG_CONFIG_HOME:-$HOME/.config}/NitroHack`.  Dated source-change notices
identify the ncurses header and fixed build-clock adjustments.

```sh
guix build -L guix --no-grafts nitrohack
make check-nitrohack
nitrohack            # original interactive curses main menu
```

Choose the native new-game menu to begin; use ordinary movement/search
commands and `i` for inventory.  `S` and confirmation save back to the main
menu, then `q` exits; a later invocation's load-game menu reopens the native
save.  The shipped `--guix-smoke` branch and production Python/helper command
were removed, and the obsolete issue-709 contract retired.  No profile,
configuration in the user's home or running service is changed by installation.

On 2026-10-02, source build, `--check` reproducibility rebuild, offline lint
and actual installed-game acceptance passed for
`/gnu/store/8ykai2wy24ragc7x2k5qw3l2zymfn0qq-nitrohack-4.0.4`.
**No upstream test target exists**; disabling that unavailable phase is not
a claim that an upstream suite passed.  Standalone
`tests/nitrohack-smoke.sh` / `tests/nitrohack-smoke.py` run three real 100×30
curses processes, native new/load/save menus and complete inventory pages
with private HOME/XDG/work state, empty PATH, isolated network/mount namespaces
and a read-only store bind mount.  Python/pyte and namespace tools are
test-only even when an existing output is supplied.

The lawful human female Valkyrie OmpProof performs one real floor move and
three search turns in each process: observed turns **1 → 5 → 9 → 13**.
Both subsequent native loads match the preceding HUD, stats, HP, every native
80×21 map cell, player position, turn and inventory letters/descriptions
exactly before further play.  The inventory contains a +1 long sword in
hand, a +0 dagger, an uncursed +3 small shield being worn and an uncursed
food ration, including the native weight/symbol descriptions.  Continued
world turns reduce HP from **16/16** at the first save to **15/16**; later
resaves update the same `.nhgame` file rather than inventing a new game or
comparing a frozen fixture.  Each native menu quit exits zero.

Final receipt, unchanged raw curses streams, full-screen pre-save prefixes
and native save copies are under `/tmp/omp-nitrohack-final`; `continuity.json`
records both exact restore comparisons and confined private writes.
Pass `--output /absolute/fresh-directory` to `tests/nitrohack-smoke.sh`
to retain another run.  The installed read-only output NAR remains
`06fb6wmwfcjnibjari0565aj1j6hjzz166h9r4v0hk2zvapdi1nj`.
`.goocastle/evidence/issue-456.png` is the inspected actual 100×30 xterm
replay of the unchanged second-session advanced full-screen prefix, showing
OmpProof the Stripling, HP 15/16, turn 9 and the legible colored native map.
The sidebar is not shown; no sidebar-runtime claim is made.  This is
OMP-produced actual game evidence, not Goocastle execution or a success-caption
buffer.  The proof covers exercised local gameplay and save continuity, not a
complete campaign or network-server/client interaction.  No deployed system
changed; no network OKF update applies to this repository-only addition.

## Legcord source application and native desktop

`legcord` **1.3.0** builds the stable
[`Legcord/Legcord` revision `c8d91f61296019bb0c45f375535de8c93cf26ee1`](https://github.com/Legcord/Legcord/tree/c8d91f61296019bb0c45f375535de8c93cf26ee1),
not the moving `notdev` branch.  The pinned source archive base32 SHA-256 is
`09gqn9l82zl8xcji38w3p51a65wxga7d0i5l61i0gjzq2fvrhn4d`.
The actual main process, preloads, renderer and Shelter plugins compile
offline from source.  The **OSL-3.0** license, original attribution,
conspicuous `GUIX-MODIFICATIONS.txt`, complete modified application source
and fixed npm archives/notices are retained under `share/doc/legcord`.
The ancillary GPL-3.0-or-later AppImage helper is retained in source but not
executed or bundled as the installed application's updater.  The source
closure includes actual npm manifests/notices and a separate upstream
Codicons font-license supplement rather than invented copyright notices.
The installed runtime omits 17 unused foreign Koffi binaries from its
Windows-only import path; their original fixed archives and notices remain
retained.  Build-tool/source shebang rewriting no longer adds host tools to
the output closure: the final direct-reference check found nine store
references and no Node or Python host-tool references.

This **x86_64-linux** package is explicitly **binary-assisted**, under the
user-approved pinned-component policy: Electron **43.2.0**, official Node
**26.10.0** host tool and native npm build-tool bindings are vendor binaries,
not claimed source builds.  Full Electron/Chromium notices and Node's
corresponding source release accompany them.  By contrast, **Venmic 7.1.0**
is genuinely compiled from C++ source against exact Electron headers and
pinned local C++ dependencies; published native prebuilds are removed.
Its MPL-2.0 corresponding modified source and MIT/BSD/zlib dependency notices
are retained with the addon.  This preserves the native PipeWire audio API,
not a no-op feature replacement; live audio acceptance remains unperformed.

```sh
guix build -L guix --no-grafts legcord
legcord                      # native desktop after installation/profile setup
legcord --guix-update-info    # instructions only; performs no upgrade
make check-legcord
# Retain proof for an existing output (test tools are still realized):
GUIX=guix sh tests/legcord-smoke.sh \
  --legcord /gnu/store/vbhjrpzfcg300dy06d9k4gllcdj8nil1-legcord-1.3.0 \
  --evidence /absolute/empty-evidence-directory
```

The output installs `bin/legcord`, application resources, icon and
`legcord.desktop`, including native mute/deafen/leave/settings actions.
Guix owns application updates: run `guix pull`, then `guix upgrade legcord`,
or update/reconfigure the profile's channel workflow.  In-place AppImage/dpkg
updater code and its dependency are removed; onboarding/settings/update
guidance identifies the package-managed installation.  Normal settings,
themes and runtime mod caches stay writable in upstream's user-data
directory (observed `${XDG_CONFIG_HOME}/legcord/storage/settings.json`).
**Upstream mod selection and runtime downloads remain unchanged**: Guix
immutability applies to the packaged app, not a promise that optional remote
mods are pinned or never downloaded into the user cache.  Chromium sandboxing
and context isolation remain enabled; no `--no-sandbox` fallback is used.

**Verification status (2026-10-03): source application build, `--check`
reproducibility rebuild, offline lint, integrated `make check-legcord` and
final native onboarding/save/cold-relaunch/sandbox acceptance passed.**
The final exercised output is
`/gnu/store/vbhjrpzfcg300dy06d9k4gllcdj8nil1-legcord-1.3.0`.
Runtime evidence at `/tmp/legcord-evidence.CLplj9X1` records real native
onboarding option-card interaction and setup-saveSettings IPC persistence:
native window style, disabled tray and no selected mods.  Both first launch
and an independently cold-relaunched browser reached the actual
`https://discord.com/login` surface with empty email/password controls; no
login was performed.  The cold renderer read back the same persisted
settings plus the inherited `automaticUpdates=true` preference.  Actual
renderer identities had seccomp mode 2 and `NoNewPrivs=1`, and Node isolation
passed on both launches.  The earlier CDP timeout was an observation race:
the old browser's CDP port could answer before restart completed.  The helper
now verifies the new browser generation and follows navigation contexts;
the final run passed without changing or bypassing application sandboxing.
The inherited update preference showed the owned native window titled
“Legcord updates are managed by Guix”, dismissed with Return; its dialog
body is outside CDP and was not independently verified.  Launcher/onboarding
guidance was verified separately.  The unchanged before/after output NAR is
`1dhg32fmlsf9m1wgacf1sw0gwp8d49zxkv9p44c1bfpcydmbkxwz`.

The real, visually inspected onboarding screen is retained as
[`.goocastle/evidence/legcord-onboarding.png`](.goocastle/evidence/legcord-onboarding.png).
It contains no credentials, account information or QR challenge.  Actual
first/cold-login screenshots remain in the local evidence directory rather
than publishing their ephemeral login QR challenges.

Standalone `tests/legcord-smoke.sh` / `tests/legcord-smoke.py` realize pure
Python/Xvfb/D-Bus tools, use fresh HOME/XDG and an explicit environment
allowlist, and retain screenshots, receipts and before/after output NAR
hashes even on failure.  The passed full target covers real onboarding,
setting persistence, first logged-out render, cold relaunch, package-managed
update guidance, renderer sandbox/isolation and unchanged installed output.
It uses live Discord network content, not an offline fixture, but never
accesses a host Discord profile or credentials.  No credentials/login,
messages, calls, post-login settings, microphone/live audio, GPU or optional
mod-download acceptance was performed.  No upstream full suite or
deployed/profile installation is claimed.  The initial nondeterministic
rebuild was corrected by retaining Monaco's runtime module layout and
deterministic CSS exports; the corrected source build and `--check` rebuild
passed before the integrated native target was re-exercised.  Final offline
lint reported no findings for Legcord, its Electron/Node tools or Venmic;
unrelated existing channel warnings remain.  The final output was again
exercised through the full native helper after these corrections.  No
network OKF update applies to this repository-only addition.

## lbForth self-hosted native interpreter

`lbforth` **0-20230213** builds Lars Brinkhoff's original
[`lbForth` revision `912433b150b64252070116a5fd5c1a29ff29b26d`](https://github.com/larsbrinkhoff/lbForth/tree/912433b150b64252070116a5fd5c1a29ff29b26d)
with the pinned recursive
[`forth-metacompiler` revision `40b99c09628f616d94649009ba9894340088d77c`](https://github.com/larsbrinkhoff/forth-metacompiler/tree/40b99c09628f616d94649009ba9894340088d77c).
The measured recursive Git-tree NAR hash is
`0g7jzaw3yijnm8rkgqsrhhx63r3v45700mp1ycyh50hs5awqh7in`, independently
matched by recursive fetch and archive reconstruction; the earlier accepted
issue-609 hash does not match this exact recursive source.  The package uses
the parent project's **GPL-3.0-only** grant (not “or later”), retaining
LICENSE, README and INSTALL.  Same-author bootstrap copyright headers are
preserved; the metacompiler submodule has no separate LICENSE.  The bundled
Hayes test programs explicitly carry a public-domain grant.

This is the original self-hosted **subset of Forth94**, not a renamed system
Forth.  Native SBCL bootstraps the portable C target offline, then the Forth
self-hosting stage regenerates the installed interpreter.  `bin/forth` loads
required system/library/target wordsets from immutable `share/lbForth`, with
no runtime checkout or compiler dependency.  The source patch opens the
full absolute system directory directly: using it as a dictionary search-path
name would truncate it to 15 bytes on this target.  The relative `src/`
fallback and bootstrap git-fetch recipe are removed; no cwd-changing launcher
or runtime store write is needed.  Other upstream cross targets are retained
as source wordsets, not claimed built or runtime-verified executables.

```sh
guix build -L guix --no-grafts lbforth
forth                 # native interactive text interpreter; use bye to exit
printf ': square dup * ; 6 square 7 + . cr bye\n' | forth
make check-lbforth     # needs python3 for the standalone acceptance helper
```

On 2026-10-03, source build, `--check` reproducibility rebuild and offline
lint passed for
`/gnu/store/nwv0y2gcmqy6zdh0y71kpj6liab2szak-lbforth-0-20230213`.
The recipe runs actual upstream **test-standard, test-image and test-lib**
after installation against the native C host.  Their upstream success oracle
includes `Test-OK` and **exactly 53 known standard-suite errors**, `Image-OK`
and the library check; this is not a claim of complete Forth94 conformance or
an error-free standard suite.  Offline lint had no lbForth findings; existing
flex/Fourk warnings remain unrelated.

The separate installed consumer `tests/lbforth-smoke.sh` /
`tests/lbforth-smoke.py` passed from an empty private cwd with fresh HOME/XDG
and `PATH=/nonexistent`, without checkout/build tools.  Native arithmetic
returns **43**; the two IF branches return **10/8**; DO/LOOP summation returns
**45**; recursive factorial returns **120**; BEGIN/WHILE countdown returns
**0**, with a clean stack.  Undefined-word and `ABORT"` diagnostics reset the
stack and allow subsequent **42** results; a missing include reports its
error and subsequent computation returns **81**.  The working directory
stays empty and installed contents, modes, sizes and mtimes are unchanged.
This exercises real language/control-flow/error-recovery behavior, not a
mock interpreter, Goocastle executor or metadata-only contract.  No deployed
profile/system changed; no network OKF update applies to this repository-only
addition.

## Hack 1.0.3 original native save continuity

`hack` packages Andries Brouwer's final **Hack 1.0.3**, distributed on
23 July 1985, from the original
[CWI historical release](https://homepages.cwi.nl/~aeb/games/hack/hack.html).
The fixed [`hack-1.0.3.tar.gz`](https://homepages.cwi.nl/~aeb/games/hack/hack-1.0.3.tar.gz)
archive SHA-256 is
`688534e776acfe620ea9e24822bea8b0b4bbe8ec2c2f3c74c8db89b51c7bcc30`;
there is no upstream VCS revision to invent.  CWI's page records separate
**BSD-3-Clause** grants for Jay Fenlason's code and CWI's 1985 code.  Both
complete notices are retained as `COPYRIGHT-JF` and `COPYRIGHT`, with
`READ_ME` under `share/doc/hack` and the original `hack.6` manual.

This is the original source-built K&R C terminal game, not a modern NetHack
substitute or artificial frontend.  Compiler/linker/termio compatibility
changes retain its native gameplay and regenerate `hack.onames.h` with the
source `makedefs`.  The historical mailbox and shell-escape features are
disabled.  Original `data`, `help`, `hh` and `rumors` stay immutable under
`share/hack`; the launcher creates checked read-only store links in
`${XDG_DATA_HOME:-$HOME/.local/share}/hack`, alongside native mutable saves,
records, locks, bones and levels.  It rejects unexpected data/state symlinks
and forwards ordinary arguments to the native `libexec/hack`.

```sh
guix build -L guix --no-grafts hack
hack                 # original interactive game
make check-hack
HACK_KEEP_PROOF=1 GUIX=guix sh tests/hack-smoke.sh # retain a fresh native proof
```

Use ordinary movement and `i` for inventory; native `S` saves and exits.
A later ordinary invocation restores and consumes that save.  No production
test mode or dependency on a Goocastle executor is installed.  The obsolete
issue-692 contract/registry removal is intentional; native gameplay evidence
replaces fake contract assertions.

On 2026-10-03, the source build, `--check` reproducibility rebuild and offline
lint passed for `/gnu/store/x16fh3kj668qp9ldxfyns49mymnjgdzj-hack-1.0.3`.
Upstream ships **no automated test target**; the disabled build-system test
phase is not a claim of a passing upstream suite.  Standalone
`tests/hack-smoke.sh` / `tests/hack-smoke.py` exercise three actual native
80×24 PTYs as the ordinary Fighter OmpProof, with private HOME/XDG/work,
empty PATH, separate network/mount/PID namespaces and a read-only store
bind mount.  Test-only Python/pyte and namespace tools are realized before
entering isolation, even when an existing output is supplied.

The first process makes a genuine floor/stair-neighbor move, reads the
inventory and saves/exits zero.  The second independently restores exact
HUD, map, position, turn and inventory, proves save consumption, makes a
further real move and resaves.  The third independently restores that
continued state exactly and saves/exits again.  Observed turns are
**2 → 3 → 4**, with Level 1, HP **14/14**, AC **7**, Str **17**, Exp **1**;
inventory contains a +0 two handed sword in hand and +0 ring mail being worn.
This is exact continuity in the actual unseeded run, not frozen world state:
the continued save differs after its further movement/turn.

Final native receipt/save copies/transcript and the genuine pre-exit frame
are under `/tmp/hack-native-proof.UnCLqo/proof`.  `pre-exit.txt` shows the
live room, `@`, monsters, stairs/items and turn-4 native HUD before `S` or
terminal teardown.  Set `HACK_RAW_CAPTURE`, `HACK_TEXT_CAPTURE` and
`HACK_TRANSCRIPT` to external paths for another retained capture; no game
writes escaped private XDG data.  Before/after read-only output NAR is
`09xqg14w7ghyv8kz90vz6765cf803hkg9ll8ljdrhz6w4rlnhzcb`.
The proof covers exercised movement/inventory/save/restore/resave paths, not
a full campaign.  No deployed/profile installation is claimed and no
network OKF update applies to this repository-only change.

## GruntHack native game and save continuity

`grunthack` builds the original **GruntHack 0.2.4** NetHack derivative from
[`NHTangles/GruntHack` revision `51d75eebbcf8ab0ce31ddab9581d266db0a691c5`](https://github.com/NHTangles/GruntHack/tree/51d75eebbcf8ab0ce31ddab9581d266db0a691c5)
as `0.2.4-0.51d75ee`.  The fixed Git-tree NAR base32 hash is
`0a2il12ap9lkdmys74vj90vv1dn18ypm7gn73yic8hdqh1j3kg5m`.
The actual game/data grant is the **NetHack General Public License**,
recorded with Guix's `fsdg-compatible` constructor and
[canonical license URL](https://nethack.org/common/license.html).
The native origin removes eleven unused Macintosh instrument `.uu` payloads
whose README only speculates about Roland sample-library copyright, not a
redistribution grant.  That README is retained as `sounds-README`; no TTY
game feature depends on those samples.

The original native executable compiles both TTY and curses interfaces; the
default interactive TTY acceptance does not replace the game with a dummy or
reduced frontend.  `make all` generates `ghdat` and the native game resources.
The Guidebook, curses README, release changes, Unix README, license and
`SOURCE` provenance/downstream-change notice are installed under
`share/doc/grunthack`.  Native mutable saves, scores, locks and logs use
`${XDG_DATA_HOME:-$HOME/.local/share}/grunthack`; immutable game data remains
in `share/grunthack`.  Dated source notices identify the native build, XDG
path and reproducible data-generation changes.

```sh
guix build -L guix --no-grafts grunthack
make check-grunthack
grunthack             # original interactive game
```

The launcher forwards ordinary game arguments to `libexec/grunthack-real`.
Use native movement/search commands to play, `i` for inventory and `S` then
`y` to save and exit.  An ordinary later invocation restores and consumes the
native save.  No shipped test branch, Python dependency or production smoke
command remains; the obsolete issue-691 contract was removed.  Installation
does not edit the user's configuration or launch a service.

On 2026-10-02, local source build, `--check` reproducibility rebuild, offline
lint and real installed-game smoke passed for
`/gnu/store/0slz1787l8j6mbdfdahxv2lgxzgvc0wq-grunthack-0.2.4-0.51d75ee`.
**Upstream has no non-interactive test target**; the recipe disables that
unavailable phase rather than claiming an upstream suite passed.  The separate
`tests/grunthack-smoke.sh` / `tests/grunthack-smoke.py` acceptance runs three
real 100×24 TTY processes with a lawful human female Valkyrie named OmpProof,
private HOME/XDG/work state, empty PATH, isolated network/mount namespaces and
a read-only store bind mount.  Python/pyte and namespace tools are test-only.

Each process makes one genuine floor move and five native search turns,
reads the complete inventory and saves/exits zero.  The observed turn sequence
is **1 → 7 → 13 → 19**.  Each new process proves actual native restore and
save consumption, matching the preceding HUD, every native 80×21 map cell,
position, stats, HP, turn and all inventory letters/descriptions exactly
before further play/resave.  The carried items are a +1 long sword in hand,
a +0 dagger, an uncursed +3 small shield being worn and an uncursed food
ration.  This pin has **no native seed option**: the oracle compares exact
continuity within the observed run, not a fabricated seeded fixture.
HP advances naturally from **16/16** at the first save to **14/16** and
**11/16** after further world turns; the proof does not freeze gameplay or
claim byte-identical saves after advancing it.

Final receipt, raw TTY sessions, native save copies and the confined private
footprint are under `/tmp/omp-grunthack-published`; `continuity.json` records
both exact restore comparisons.  For another retained run, pass
`--output /absolute/fresh-directory` to `tests/grunthack-smoke.sh`.
The installed read-only output NAR remains
`1inwh39gy38gw4lqqip4nvv3ggkl5510193qm8dxwsww9w4lc4vl`.
`.goocastle/evidence/issue-385.png` is the inspected actual 100×24 xterm
replay of the unchanged second-session pre-exit prefix, showing OmpProof the
Stripling, St 18/01, Dx 14, Co 18, In 9, Wi 9, Ch 8, Lawful, HP 14/16,
Pw 2/2, AC 6, Exp 1, turn 13 and the native small-room `@` map.  It is
OMP-produced evidence of the genuine continued game, not Goocastle execution
or a success-caption buffer.
This proves the exercised native TTY gameplay/save/restore/resave paths, not
a full campaign or curses-interface runtime.  No profile or deployed system
changed; no network OKF update applies to this repository-only addition.

## UnNetHack native TTY and save continuity

`unnethack` builds the original **UnNetHack 6.0.4** native terminal game from
[`1f061e93b44d93e509f35dbfa3c853f758712558`](https://github.com/UnNetHack/UnNetHack/tree/1f061e93b44d93e509f35dbfa3c853f758712558),
with Guix Git-tree base32 hash
`1s08lc1jjv4nyrj4dg0d4rrlg84m6v46dw8xca6gz0sp636pdvqb`.
The game and native data use the actual **NetHack General Public License**,
recorded with Guix's `fsdg-compatible` license constructor and the
[canonical license URL](https://nethack.org/common/license.html).
`dat/license` is installed verbatim.  The incomplete upstream Debian
copyright entry for Benjamin Rubin is not a GPL grant and does not justify
inventing one; the optional Lisp-window BSD notice and other original source
notices remain in the installed documentation/source record.

The package retains all native TTY game rules, levels, monsters, objects,
UTF-8/color rendering, internal compression, help, Guidebook, dump support,
`nhdat` and recovery utility.  `make all`, not the executable-only default
target, builds the complete resources.  Optional tilesets and bundled TTFs
without accompanying per-file permission at this pin are filtered from the
native origin; their exact tileset attribution README is retained.  They are
not required for any TTY feature, and this package makes no graphical-port
claim.  The relevant native source and notices are retained under
`share/doc/unnethack/tty-source`, with dated package modifications documented
in `TTY-SOURCE-NOTICE`.

The recipe removes the two legacy macros that redefine compiler-owned
`__warn_unused_result__` / `warn_unused_result` attributes and break glibc's
`__has_attribute` query, restoring native attribute/diagnostic behavior rather
than suppressing warnings.  Environment `CC=gcc` preserves the upstream
`-DAUTOCONF` compiler flag, and the C tests receive Check's pkg-config header
flags as well as library flags.

```sh
guix build -L guix --no-grafts unnethack
make check-unnethack
unnethack             # original native TTY game
```

The launcher puts mutable saves, bones, levels, scores/logs and dumps under
`${XDG_DATA_HOME:-$HOME/.local/share}/unnethack`, with private permissions and
no setuid/setgid installation or ownership changes.  Immutable data stays in
`share/unnethack`.  The playground must be absolute and at most **128 bytes**;
longer paths fail before writes rather than falling back to the store.
Configure the original game with `~/.unnethackrc` or `NETHACKOPTIONS`.
Use `i` for inventory, ordinary movement/search commands to play and `S` then
`y` to save; the next ordinary invocation restores and consumes the save.
Installation does not edit the user's configuration.

On 2026-10-02, local source build, `--check` reproducibility rebuild, offline
lint and standalone installed-game smoke passed for
`/gnu/store/9pxmmdmh71wa35sgjlq8k98qm3ym57sv-unnethack-6.0.4`.
All **five upstream C suites** (base32, hacklib, options, unicode and wishing)
passed with zero failures/errors.  The separate legacy Ruby/RSpec-1 task
requires `windowtype:dummy` and is not upstream's `make check` target; it is
not claimed as native-TTY verification.  No dummy frontend, Python test
interpreter or production smoke command is shipped; the obsolete issue-733
contract was removed.

`tests/unnethack-smoke.sh` and `tests/unnethack-smoke.py` run three real
100×24 TTY processes with seed **424242**, a lawful human female Valkyrie
named OmpProof, private HOME/XDG/work state, empty PATH, separate network/mount
namespaces and a read-only store bind mount.  Each process makes one genuine
floor move and five native search turns, inspects every inventory page, then
saves and exits zero.  The observed turn sequence is **1 → 7 → 13 → 19**,
with player coordinates `(54, 5) → (53, 5) → (52, 5) → (51, 5)` in the native
80×21 zero-based map viewport.  Both restores exactly match the preceding
saved HUD, every map cell, position, stats, HP, turn and every inventory
letter/description, then consume the native save before continued play and
resave.  HP remains **16/16**, with an uncursed +1 long sword in hand and an
uncursed +0 dagger.  This proves actual native save continuity, not identical
whole save bytes after advancing the world.

Final receipts, raw TTY sessions and copied native saves are under
`/tmp/omp-unnethack-final`; `continuity.json` records both exact restore
comparisons and confined private writes.  To retain another run, pass
`--output /absolute/fresh-directory` to `tests/unnethack-smoke.sh`.
The installed read-only output NAR remains
`1dw5v0x57jsyamj33kkqml1ajnag72jwr5c7iiic28wpbbzn1ll6`.
`.goocastle/evidence/issue-733.png` is the inspected xterm replay of the
unchanged restored TTY stream, showing OmpProof the Stripling, St 15/Dx 14/
Co 18/In 14/Wi 8/Ch 8, Lawful, Dlvl 1, HP 16/16, Pw 2/2, AC 6, Exp 1,
turn 7 and the native `@`/`f` map.  The welcome-back text has been cleared by
the ordinary redraw; restore is established by the native continuity receipt,
not a visible caption.  Terminal ECHO is disabled during replay to prevent
DSR-response echo without modifying raw game bytes.  This is OMP-produced
evidence of the real game, not Goocastle execution or an artificial frontend.
The proof covers the exercised gameplay/save/restore paths, not a full
campaign or the optional graphical ports.  No profile or deployed system
changed; no network OKF update applies to this repository-only addition.

## SporkHack silent native game and save continuity

Local acceptance on **2026-10-06** covers [`sporkhack`](guix/tay/packages/sporkhack.scm)
**0.7.0-0.4ed114f**, the original native Unix game from
[`k21971/SporkHack` revision `4ed114fc29b9d03f9b2857c730afd9563513ddad`](https://github.com/k21971/SporkHack/tree/4ed114fc29b9d03f9b2857c730afd9563513ddad).
The current origin uses Guix `git-fetch` for that exact commit with NAR hash
`0l6h5znm3l14v4dzb8zghv3c5xbf9rs9ca3mbjcc090v76wgdg7a`; the same source
filters and private-state patch still apply. The earlier codeload archive for
this tree had SHA-256
`26ff9a80a8309f3c471506e5c9bdf2688dfd9ced48cebca1ea483ee7f88cc79a` and Guix
base32 hash `16n7ikwffgj8xahvrkj8xnfgv3b8yaywkr862m3kr7rhm209mzr6`.
This is a silent terminal roguelike, not a replacement frontend or an audio
package. Both native tty and curses interfaces are built; acceptance below
exercises tty. No sound sample, proprietary Macintosh sound payload, audio
backend or bring-your-own playback capability is included or claimed.

### Source rights and distribution boundary

The retained README directs recipients of the source distribution to
`dat/license`, the **NetHack General Public License** (NGPL). Its paragraph
2(b) grants distribution of derivative works under the same terms; missing
repetition in an individual source/header/map/text file is not a different
license. Guix records the actual grant with `license:fsdg-compatible` and the
[canonical NGPL URL](https://nethack.org/common/license.html), not a guessed
GPL/SPDX substitution. The selected source review covers **314 upstream
files**: root 5, dat 39, doc 30, include 90, src 107, util 10, sys/unix 11,
sys/share 3 (including sounds/README), tty 4 and curses 15. The public-domain
LibTomCrypt RNG notice in `src/rnd.c` and the NGPL header/literary attributions
in `dat/data.base` remain intact. This is a bounded source-rights review,
not legal certification or a claim to have established rights in every
unselected historical port or asset.

Filtering occurs in the **source origin**, not merely the installed output.
The Roland instrument `.uu` samples have no redistribution grant: their
README's speculation about absent copyright marks does not supply one.
Unused ports/tiles/encoded or binary resources, `sys/mac/NHsound.hqx`,
`sys/unix/cpp*.shr` and `snd86unx.shr` are excluded. `doc/tmac.n` prohibits
sale and redistribution of modifications; unused `include/bitmfile.h` has
a MAXON copyright without a grant. Unused graphics headers `gem_rsc.h`,
`load_img.h` and `qt_xpms.h` are also excluded. The original sound README is
retained as `share/doc/sporkhack/sounds-README`, not as permission to ship its
samples. Flex/Bison regenerate the parsers from native source inputs instead
of distributing historical generated skeletons.

The executable is accompanied by the **complete selected, patched source**
under `share/doc/sporkhack/source`, satisfying the source-accompanying route
in NGPL paragraph 3(a), not its noncommercial-only archive-URL alternative.
Original notices and verbatim `license` are retained; modified files carry
dated downstream notices. Installed `SOURCE`, `sporkhack.scm` and
`sporkhack-private-state.patch` document the pin, filtering and changes.
The full native game rules, level sources and locally generated `nhdat`
remain, with help and the shipped plain-text Guidebook. Build changes select
native internal compression, pinned build/version timestamps and immutable
data; the private-state patch routes mutable native files to the launcher
state rather than changing gameplay to satisfy the consumer.

### Native state and use

The normal `bin/sporkhack` launcher runs `libexec/sporkhack-real`. Immutable
data lives in `share/sporkhack`; saves, bones, levels, scores, locks, logs,
whereis/extrainfo and dumps use
`${XDG_STATE_HOME:-$HOME/.local/state}/sporkhack` with private permissions,
without setuid/setgid or ownership changes. `XDG_STATE_HOME` must be absolute.
Native configuration is `~/.sporkrc` (fallback `~/.nethackrc`) or
`NETHACKOPTIONS`; installation does not edit it. Confirm the ordinary
character selector with `.` (play), use movement and `s` (search), inspect
inventory with `i`, then use `S` and `y` to save. An ordinary subsequent
invocation restores and consumes that native save before continued play.

```sh
guix build -L guix --no-grafts sporkhack
guix build -L guix --source sporkhack
sporkhack
# Supply the already-realized output and a fresh, nonexistent evidence path:
make check-sporkhack GUIX=guix SPORKHACK_OUTPUT=/gnu/store/3r67msrx90g8q5q2rg75zvdp1chbaikr-sporkhack-0.7.0-0.4ed114f SPORKHACK_EVIDENCE=/tmp/new-sporkhack-proof
```

### Exercised receipt and harness corrections

The current `git-fetch` source build passed in **47.71 s**, producing
`/gnu/store/3r67msrx90g8q5q2rg75zvdp1chbaikr-sporkhack-0.7.0-0.4ed114f`.
There is no upstream noninteractive test target; build timing does not claim
an upstream unit-test suite. Current offline lint exited zero in **5.48 s**
with no SporkHack archival or no-updater finding. It still reports that no
upstream tags were found and that GitHub failed to find upstream releases,
plus known unrelated channel findings; this is not a warning-free
whole-channel claim. The source-origin change is not a complete
release-tracking or archival-gate claim.

The current standalone `make check-sporkhack` passed in **12.99 s** with
evidence in `/tmp/sporkhack-vcs-check-2`. It is not part of aggregate
`make check`; both `SPORKHACK_OUTPUT` and `SPORKHACK_EVIDENCE` are required,
with no defaults, and evidence must not already exist. It invokes
`tests/sporkhack-smoke.sh` on an already-realized output and never builds the
game. Generic Python/pyte/namespace tools are test-only, not game runtime
dependencies.

Two genuine 100×24 PTY processes run the normal launcher/native ELF with
private HOME/XDG state, empty PATH, separate user, mount, network and PID
namespaces (only loopback), and a recursively read-only store. Both save
normally and exit **0**; the consumer exit status is 0. `continuity.json`, raw
`session-*.pty`, screen/HUD/inventory snapshots, input/process receipts and
native save copies retain the observations; copies are evidence only and are
never injected into the game.

The selected character is OmpProof, lawful human **Female Valkyrie**. The
observed turn sequence is **1 → 4 → 7**, with native 80×21 zero-based map
coordinates **(38, 15) → (39, 15) → (40, 15)**: each process makes a real floor
move and two search turns before saving. The second process's restore
exactly matches the first saved **entire map, HUD, position, stats, HP,
turn and every inventory letter/description**, consumes the native save,
then advances and resaves. The corrected parser records the actual menu
column separately from native map text; all five inventory items in JSON
match the retained native inventory screens at startup, save, restore and
continued play. St 16, Dx 16, Co 18, In 9, Wi 8, Ch 8,
HP 16/16, Pw 2/2, AC 6 and Exp 1 persist. Inventory retains `a` +1 long sword
(weapon in hand), `b` +0 dagger, `c` uncursed +3 small shield (being worn),
`d` 2 uncursed food rations and `e` uncursed oil lamp. Saved `whereis`
records turns 4 and 7 and HP 16/16, matching the pre-exit HUD. The host game
state is unchanged, and the
before/after read-only output NAR is
`0nn0bfxfy8gd4frxqz837z8may9w8szlm48wiz11bhbf8jlf0vhy`.

The earlier same-output `/tmp/sporkhack-vcs-check-1` run exited zero in
**13.15 s**, but its JSON inventory parser missed item `d` when native map
text preceded the inventory column on that row. Its retained screens show
the item; that earlier run alone did not establish complete inventory-parser
coverage. The corrected `/tmp/sporkhack-vcs-check-2` receipt above supersedes
that limitation without altering the game or reinjecting native save files.

Historical pre-`git-fetch` receipts remain distinct: the codeload-source
output `/gnu/store/h8cpgw057hznn1vdvrizvzivwxarqw64-sporkhack-0.7.0-0.4ed114f`
built in **45.36 s**, passed `--check` in **42.89 s**, passed integrated
`make check-sporkhack` in **12.90 s** (`/tmp/sporkhack-check-1`) and had output
NAR `0zhahjhc3vb424vin93zgzqsrq04655yf4yxhx3fix1x8dzgwanb`. Its earlier lint
passed in **6.48 s** with SporkHack no-updater/archive findings.

Earlier retained attempts are **not passes**: `/tmp/sporkhack-native-1`
timed out at the ordinary character selector because the harness omitted
`.`; `/tmp/sporkhack-native-2` saved successfully but failed an incorrect
`whereis` gender expectation. At this upstream pin `whereis` reads
`u.mfemale`, the pre-polymorph field initialized to zero, rather than the
selected `flags.female`; a never-polymorphed Female therefore reports
`gender=Mal`. The selector's `F + Female` proves the selection independently.
`whereis` updates at startup, level change and save, not every turn. The
consumer now uses normal selector confirmation and the actual saved-field
semantics; **no game patch masks these harness errors or changes the
character's gender**. This metadata limitation is not a save-continuity
failure. The receipt covers exercised tty gameplay/save/restore/resave,
not a full campaign, curses runtime or audio playback. The 629 preservation
snapshots are unchanged; no profile or deployed system changed, so no
network OKF update applies to this repository-only addition.

## NLarn original-game save continuity

`nlarn` packages the original **NLarn 0.8.0** C/ncurses rewrite of Larn from
the release commit
[`1873599a5682e4645e2801f7de6bd11ce54c2dfd`](https://github.com/nlarn/nlarn/tree/1873599a5682e4645e2801f7de6bd11ce54c2dfd),
not a replacement game or UI.  The fixed Git tree has Guix base32 hash
`0jcd5j2k23zx6ikwzkir47b9s57ign1hh82his1j1hs62nl8m34q`.
The native executable retains the original game features and reads its
immutable fortune, maze, help/message files and locale catalogs from
`share/nlarn`.  The optional PDCurses submodule, Windows/SDL icon and bundled
Fira Mono font are not part of this console package.  README, changelog,
GPL-3.0 license, maze documentation and the cJSON MIT/Expat and enumFactory
CC-BY-SA-3.0 notices are retained under `share/doc/nlarn`.  The recipe's
license metadata is GPL-3.0-only plus those third-party licenses, not a claim
of a GPL-3.0-or-later grant.

```sh
guix build -L guix --no-grafts nlarn
make check-nlarn
nlarn                 # original interactive menus and game
nlarn --highscores    # native Hall of Fame display
```

Use the main menu to start or continue a game.  `i` opens the original
inventory; `?` or F1 opens help, and Ctrl-S saves and quits.  Configuration
and native saves remain in the game's ordinary `~/.nlarn` directory
(`nlarn.ini` and `nlarn.sav`), not a new XDG adapter.  Installation does not
alter the user's configuration or start a service.

On 2026-10-02, local source build, `--check` reproducibility rebuild and offline
lint passed for
`/gnu/store/xb53638fq31in9dsdwb3v507kf8mjb5b-nlarn-0.8.0`.
**Upstream has no test target**; the recipe disables that unavailable phase,
and the independent installed-game proof is not presented as an upstream
suite.  `tests/nlarn-smoke.sh` and `tests/nlarn-pty-runner.py` drive two real
100×30 PTYs in isolated user/network/mount namespaces with private HOME/XDG
state, empty PATH and a read-only store bind mount.  Python and pyte are
test-only dependencies.  The former Goocastle bounded-runtime/Node dependency
and obsolete issue-710 contract were removed; no Goocastle execution is used.

The first process creates the native strong male OmpProof character with
STR/DEX/CON/INT/WIS **20/15/16/12/12**, HP **21/21**, MP **17/17**, level 1 and
experience 0.  It inspects the actual equipped **uncursed leather armour +1**
and **uncursed dagger +0**, moves from Town map position `(52, 13)` at turn 1
to `(52, 12)` at turn 2 (zero-based rendered coordinates), then saves using
the ordinary Ctrl-S command.  A separate process restores exactly the
HUD, position, turn and inventory, moves to `(53, 12)` at turn 3, and saves
again.  The proof reads the actual gzip-JSON save streams, verifies HUD
against native fields, compares carried item identities/contents and equipped
slots, and proves the second save contains the further position/time advance.
It does not claim byte-identical whole saves: native time and position must
change.  The test parser handles ncurses' ECMA-48 CSI REP command so repeated
cells are decoded accurately; the original raw output is not altered.

The receipt and native save evidence are retained at
`/tmp/nlarn-smoke-dakrYZ/proof/receipt.json`.  Only the private `~/.nlarn`
state is written; the Hall of Fame query creates no user state, and the
read-only installed output NAR remains
`1l4v2sannym0gwcpp8f3r83i70vfqb8vd8rv5q4f4ychpjqajr9d`.
Set `NLARN_RAW_CAPTURE`, `NLARN_TEXT_CAPTURE` and `NLARN_TRANSCRIPT` to
absolute destinations to retain the genuine resumed live frame, decoded text
and complete PTY transcript; the final raw frame is `/tmp/omp-nlarn-final.raw`.
`.goocastle/evidence/issue-457.png` is the inspected actual 100×30 xterm replay,
showing OmpProof, STR 20, DEX 15, CON 16, HP 21/21, turn 3, the Town map/player
and the welcome-back message.  This is OMP-produced evidence of the real
resumed game, not Goocastle execution or a success-caption buffer.  The proof
covers the exercised native gameplay/save/restore/resave paths, not a full
campaign.  No profile or deployed system changed; no network OKF update
applies to this repository-only runtime correction.

## robotfindskitten original-game runtime proof

`robotfindskitten` packages the original **3.0000000.726** C/ncurses Zen
simulation from
[`Codeberg revision 471872786ca3a40db5b53f7baf96233a3793c45d`](https://codeberg.org/robotfindskitten/robotfindskitten/src/commit/471872786ca3a40db5b53f7baf96233a3793c45d).
The pinned source archive has SHA256
`6be0c9bab746e8484e29b2033bb915a59880cc1205c9f4ec3a377c62ca6cd5e7`
(Guix base32 `1rymdk564z1p7bng9j852b6816552nwkn0xj5574is26nyxckq3b`).
Autoreconf regenerates the archive's missing build machinery; the native
executable is installed directly as `bin/robotfindskitten`, with no production
wrapper, `--guix-smoke` option, Python dependency or substitute game.

The complete original non-kitten item (NKI) collection, man/info documentation,
desktop/AppStream metadata and PNG/SVG icons are installed.  Native colored
items, eight-direction movement, deterministic seeds and custom NKI
collections are retained.  Source and data are **GPL-2.0-or-later**, with
upstream's full license and REUSE information retained under
`share/doc/robotfindskitten`.  The AppStream file explicitly declares
`<metadata_license>CC-BY-SA-4.0</metadata_license>` despite its SPDX header
saying GPL-2.0-or-later.  Both declarations are preserved and the package
metadata lists both licenses; this does not resolve that upstream discrepancy
by silently discarding either statement.

```sh
guix build -L guix --no-grafts robotfindskitten
make check-robotfindskitten
robotfindskitten              # original interactive game
robotfindskitten -n 1 -s 0    # one NKI plus kitten, reproducible native seed
```

Press a key at the introduction, then move robot (`#`) with arrow keys or the
native movement bindings.  Touching a non-kitten item displays its description;
touching kitten runs the original animation and ends the simulation.

On 2026-10-02, local source build, `--check` reproducibility rebuild and offline
lint passed for
`/gnu/store/fp0f82gi50pis0cmfvxbgdyl6yfsjbjz-robotfindskitten-3.0000000.726`.
There are **no upstream test programs**; Guix's enabled check phase exercises
the supplied Automake `make check` target, not a claimed gameplay suite.
The independent test-only smoke launches the actual installed ELF in an
80×24 PTY, with fresh HOME/XDG/work directories, empty PATH and a network
namespace whose only interface is down loopback.  It observes the native
playfield and uses breadth-first routes through empty cells, sending genuine
`h/j/k/l` keyboard moves and checking each rendered robot position.  It checks
a description against the installed `vanilla.nki`, unchanged robot/object
positions on NKI contact, the original kitten win and exit status zero.  If
kitten is touched first, the helper replays the same native seed with reversed
target order and verifies the same initial field rather than inventing a game.
The final run observed 62 moves, NKI interaction and the kitten win.  No private
user state was written; the read-only output NAR remained
`0vl4amqjjndf0zzsb3h7a5m1cni264gyqqfphz5ra2ns7mj8mm0d`.

The former issue-717 artificial robot contract was removed, not replaced with
another production smoke implementation.  Runtime helpers remain only in
`tests/robotfindskitten-smoke.sh` and `tests/robotfindskitten-smoke.py`.
Set `ROBOTFINDSKITTEN_RAW_CAPTURE=/absolute/path` to retain genuine terminal
bytes.  `/tmp/omp-robot-kitten-final.raw` is the final pre-exit capture;
`.goocastle/evidence/issue-487.png` is the inspected actual 80×24 xterm replay
of those unchanged bytes, showing `You found kitten! Way to go, robot!` and
the original playfield with `#` adjacent to `n` and the `0` object.  This is
OMP-produced terminal evidence, not Goocastle execution or an artificial UI.
The proof covers the exercised native movement/NKI/win paths, not every
movement key or custom collection.  No profile or deployed system changed;
no network OKF update applies to this repository-only correction.

## Stoat Soup original-console runtime proof

`stoat-soup` packages the independently playable **Stoat Soup
0.23-ish-aug26** variant from the original C++ source, not a replacement UI or
prebuilt executable.  The original research [issue #529](https://github.com/htayj/guix-channel/issues/529)
explicitly specifies a **console-only** delivery: this is neither the distinct
upstream Guix `crawl`/`crawl-tiles` package nor the channel's `bcrawl` fork.
The reviewed [release tag](https://github.com/damerell/crawl/releases/tag/0.23-ish-aug26)
(published 2026-08-02) resolves to commit
`5df72bd44e7113642e311008665fafda6c7baa8c`.  Its pinned
[official source archive](https://codeload.github.com/damerell/crawl/tar.gz/refs/tags/0.23-ish-aug26)
has SHA256
`50a0fd6a8836d522ef84c3789df85981b703cc441ae2552457332e5a1ade133e`
(Guix base32 `0ghkvqd5lbikawj5bqhs8k607dw1b7w9sy63hkpj5m9ni1mgv82h`).

The package builds the complete native console game against Guix Lua 5.1,
ncurses, SQLite and zlib, without fetching bundled submodules or enabling
graphical SDL, tiles, fonts or optional PCRE.  It fixes the release metadata
for the archive without `.git` and changes only the exact upstream HOST
`cc -dumpmachine` probe to use the available `gcc`, not substrings of existing
`gcc` commands.  Immutable maps, Lua scripts, databases, defaults,
descriptions, settings, generated manual and aptitudes are installed under
`share/stoat-soup`; the game uses that compiled-in data path, without a
source-tree/load-path fallback.  Complete upstream and Stoat documentation,
`LICENCE`, credits, original third-party notices and the full Apache 2.0 text
are retained under `share/doc/stoat-soup`.  The console code closure includes
GPL-2.0-or-later, BSD-2-Clause, MIT, public-domain/CC0 and Apache-2.0 terms;
retained historical graphical-component license texts do not imply those
components are built or shipped as dependencies.

The launcher places native saves, scores, macros and compiled caches below
`${XDG_STATE_HOME:-$HOME/.local/state}/stoat-soup` and forwards ordinary game
options.  It adds no installed `--smoke` mode, helper UI, updater or runtime
download.  Verification helpers live only in `tests/`; upstream's
`util/fake_pty`, built for its stress tests, is not installed.

```sh
guix build -L guix --no-grafts stoat-soup
make check-stoat-soup
stoat-soup
```

On 2026-10-02, the final local source build, upstream `make nondebugtest`,
reproducibility rebuild (`--check`) and real-console runtime smoke passed for
`/gnu/store/pvl49rih6smq8fffzlxsv3h733ibfiff-stoat-soup-0.23-ish-aug26`
using OMP tooling.  `tests/stoat-soup-smoke.sh` and
`tests/stoat-soup-pty-runner.py` use fresh HOME/XDG state, an empty inherited
environment and isolated user, network and PID namespaces with only loopback.
Two actual 80×30 PTY game processes select OmpProof, a Human Fighter, using
literal `-seed 285` (the native parser treats it as hexadecimal, numeric 645).
The first makes the ordinary weapon choice, performs three genuine advancing
waits, writes a native character dump and saves with native `S`/`y`.  The
independent second process restores the welcome-back map and exactly the saved
game clock, console viewport coordinates, HP, stats and meaningful native dump
fields.  One further ordinary wait advances the native turn count once before
another native save.  Read-only `--edit-save` inspection retains actual `chr`,
`you` and internal `D:1` chunks from both saves; the user-facing native place
is **`Dungeon:1`**, not that internal chunk name.  The before/after installed
output NAR hashes match.

Final native evidence is at `/tmp/stoat-soup-smoke.wvQXyqvH` (temporary, not a
durable fixture).  `.goocastle/evidence/issue-724.png` is the inspected xterm
rendering of the exact restored 80×30 PTY prefix, showing OmpProof the Human
Fighter, Health 18/18, Time 3.0, Place Dungeon:1 and the welcome-back dungeon
map.  It is OMP-produced terminal evidence, not a graphical game frontend or
a Goocastle execution.  This proves the exercised native gameplay/save/restore
paths, not a full campaign or graphical frontend.  No profile or deployed
system changed; no network OKF update applies to this repository-only addition.

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

## Brogue

`brogue` 1.15.1 builds Brogue Community Edition from the pinned upstream
`tmewett/BrogueCE` commit `1ba4240b7a928ddf0ffb772717bf1d433cd63804` (tag
v1.15.1), Guix base32 source hash
`031qj38vnsjgc9qjkkqa8z6z3vkfm5zx2djk25hdrash31l37s3b`.  One binary carries
the original SDL2 frontend with the licensed graphical tiles and the
ncurses frontend (`brogue -t`); the web frontend is not built.  Engine code
is AGPL-3.0-or-later, platform code GPL-3.0-or-later, and `tiles.png` with
its derived `tiles.bin` cache is CC BY-SA 4.0.  Upstream `README.md`,
`CHANGELOG.md`, `LICENSE.txt` and the asset `LICENSE.txt` are installed
under `share/doc/brogue`.  Upstream `icon.png` carries no license, so it is
not installed and its mandatory load is removed from `src/platform/tiles.c`;
SDL keeps its default window icon, while the licensed tiles and native
renderer remain intact.  The launcher runs the immutable `libexec/brogue`
from `$XDG_STATE_HOME/brogue` (fallback `~/.local/state/brogue`), copies the
editable keymap there once and always appends the packaged `--data-dir`.
No installed smoke runner or test mode exists; the former one is removed.

On 2026-10-05, the source build and a reproducibility rebuild (`guix build
--check`) passed for derivation
`xaxfpqlcapq9y3yr7b95dr6rk4v5q527`, output
`/gnu/store/hxhhj08irn0ai5q8j12dhxkx1q55jip7-brogue-1.15.1`.  Its
`check-seed-catalogs` phase runs upstream `test/compare_seed_catalog.py`
against the shipped catalogs and both match identically: 25 seeds to depth
40 for standard Brogue and 25 seeds to depth 10 for Rapid Brogue
(`--variant rapid_brogue`).  The upstream recording regression harness stays
disabled because this release omits the recording directories it references.
The final lint, run with its network check enabled, reported no Brogue
findings; its only findings are the known unrelated deprecated `flex` symbol,
NHFourk and WinRM ones.

`make check-brogue BROGUE_OUTPUT=OUTPUT BROGUE_EVIDENCE=DIR` runs
`tests/brogue-smoke.sh OUTPUT EVIDENCE_DIR` on an already-built output and a
new or empty evidence directory outside the store.  It runs
`tests/brogue-smoke.py` in private user (current UID, not root), mount,
network (loopback only) and PID namespaces with a recursively read-only
`/gnu/store`, fresh HOME/XDG state, a private TCP-disabled Xvfb display and
SDL's `--no-gpu` software renderer, and records the output NAR hash before
and after.

On 2026-10-05, `make check-brogue` passed (`BROGUE_NATIVE_SAVE_RESTORE_OK`,
64.13 s) for the final `hxhhj08irn0ai5q8j12dhxkx1q55jip7` output, evidence
`/tmp/brogue-make-final-1`.  Both the ncurses (`-t`) and SDL frontends started
seed 1 at depth 1 through the launcher's packaged keymap and data directory,
made a real `h` move with the exact player delta (59,29)→(58,29), saved, were
restored from the native `.broguesave` by a second `-o` process and took one
continued turn.  The decoded native recordings carry the CE 1.15.1 header in
normal (non-wizard) play, grow from turn 1 (43 bytes) to turn 2 (49 bytes),
preserve the saved event prefix, include the saved-game-loaded event and
match between the two frontends.  The package output NAR stayed
`17w99p2mj4m280ci9m3abh32awdw07581gfd00v4j1bwl19yjqlm`; the installed files
match the declared scope with no icon and no smoke helper or mode.

`.goocastle/evidence/brogue-native.png` is the game's own SDL PrintScreen
capture `restored-after-movement.png` (1024×640, SHA-256
`a69e2321149813323d1ece0240869eb8ce41cf9f3f8a7835ee92fc6b0332d21f`).  It
shows the restored depth-1 game with the welcome messages, `Str: 12  Armor:
3` and the explored map in the default text glyph mode.  The screenshot is
for inspection only; the recordings are what prove the save and restore.
The SDL save dialogs are driven by paced XTest inputs derived from the
source.  GPU acceleration, desktop window-manager integration, a capture in
tiles mode and full-campaign play were not verified.  This is
repository/store verification, not a profile or OKF deployment, and the
source collection remains 629 snapshots.

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

## Bell Labs Rogue 7 — standalone native gameplay and save continuity

Local evidence on **2026-10-07** covers the existing
[`bell-labs-rogue7`](guix/tay/packages/bell-labs-rogue7.scm) **7.7.1** package,
not a new inventory entry or replacement game. The original **629** source
snapshots and preservation accounting are unchanged. The package builds the
`arogue7/` tree from the pinned
[`early-roguelike-rel2021.03-src.tgz`](https://rlgallery.org/files/early-roguelike-rel2021.03-src.tgz)
collection, source base32 SHA256
`09myhrn19s33bsdyavi15nq20811l0sxrz8nc2d8qcmx7aysl9jn`.
The actual `arogue7/vers.c` identifies the Bell Labs 7.7 lineage and release
`7.7.1`; the collection release is not the game's version.

The actual source and installed `LICENSE.TXT` grant source and binary
redistribution, with or without modification, subject to retention of notices,
conditions and disclaimers and the non-endorsement conditions. They preserve
the notices for Michael Morgan, Ken Dalka and AT&T; Robert D. Kindelberger;
Michael Toy, Ken Arnold and Glenn Wichman; Nicholas J. Kisseberth's
`state.c`/`mdport.c` portions; and David Burren's FreeSec `xcrypt.c` portion.
The additional reserved-name conditions prohibit using **Advanced Rogue**,
**ARogue** or **Super-Rogue** for endorsement or derived product names without
prior written permission. The package's `bell-labs-rogue7` name avoids those
reserved names; its custom non-copyleft license record is intentionally not
unqualified BSD-3-Clause. The full 9,331-byte license and the source guides
`aguide.mm` and `arogue77.html` are installed under
`share/doc/bell-labs-rogue7/`; the native executable is under `libexec/` and the
normal launcher is under `bin/`. Save and score state use
`$XDG_DATA_HOME/bell-labs-rogue7`, falling back to
`$HOME/.local/share/bell-labs-rogue7` when XDG_DATA_HOME is unset. The package
disables host-wide log, score and save directories and supplies `ROGUEHOME` for
both saves and scores; it does not replace the original game engine.

Main's source build (run 469, **9.75 s**, log artifact `15219`) and
reproducibility rebuild (run 470, **5.71 s**, log artifact `15220`) passed for
the same output:
`/gnu/store/pam82bkghvc5hlxs0iwwwzwvs2kxj142-bell-labs-rogue7-7.7.1`.
The standalone native proof (run 473, **21.22 s**) passed with
`BELL_LABS_ROGUE7_RUNTIME_OK`; its receipt is
`/tmp/rogue7-native-2/continuity.json`, accompanied by real PTY transcripts,
input records, decoded screens and an evidence-only copy of the native save.

Two independent processes entered through the normal installed launcher in
fresh private HOME/XDG directories, with empty PATH, `TERM=xterm-256color`,
same-UID mapping (**1000**, not namespace root), network/PID/mount/user
isolation, only loopback networking and a recursively read-only `/gnu/store`.
The first real PTY selected fighter class `1`, accepted the native attribute
allocation with Escape and `y`, navigated the starting equipment post without
claiming a purchase, reached its `%` entrance and used `>` to enter dungeon
level 1. A native `h` move changed the player from screen coordinate `(17,3)`
to `(16,3)`. Native `S` then `y` wrote the 49,472-byte `arogue77.sav` and
exited normally with status **0**. The copied evidence save was never
re-injected. A new process launched with `-r`, consumed the actual native save
and restored the **entire displayed map and both HUD lines exactly**, including
player `(16,3)`, `Lvl:1`, `Hp:24(24)`, `Ac:11`, `Carry:0(200)`, `Exp:1/0`,
attributes and `Veteran` rank. A further native `l` move reached `(17,3)`;
`Q`, the exact `yes` confirmation and pack/score acknowledgements exited with
status **0**. Main read the restored screen containing the player `@`, nearby
`R` and those HUD values. This proves visible save/restore continuity and
continued movement, not equality of every hidden game-state field, combat,
equipment purchase, deeper-level progression or a win.

The output NAR before and after the standalone proof was identical:
`1za12qhpm0vyaza4fx5cchnynn7q83ximrlskj1xwdnmmy04848m`.
The receipt also records unchanged host game state; after save consumption and
normal quit, the only private game footprint was the personal score file.
**Clean lint remains pending:** Main's run 471 (**7.59 s**) reported the
`generic-html` updater failing to find upstream releases and a source not
archived in Software Heritage with missing Disarchive data. An unrelated
deprecated Flex warning is not a Rogue defect. No clean-lint claim is made.
Main then completed the guarded Makefile integration and exercised
`make check-bell-labs-rogue7` (run 474, **27.56 s**):
`BELL_LABS_ROGUE7_RUNTIME_OK`, with retained evidence at
`/tmp/rogue7-make-final`. The standalone target requires an explicit prebuilt
output and fresh evidence directory; it is not an unguarded aggregate check.
Published on **2026-10-07** in signed, Guix-authenticated commit
`eb0a503e8a4c1e0ecc344887601e5e97dcb43208`
(`fix: prove native Rogue seven save and restore`) through a normal
`git push origin master` to `git@192.168.7.121:tay/guix-channel.git`;
authenticated remote `HEAD` and `refs/heads/master` matched that exact commit.
Publication does not close the clean-lint gate: **#267 remains OPEN** for the
updater/archive findings above. This receipt does not claim deployment or issue
closure.

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

## Notty terminal graphics library

`notty` 0.2.3 builds the ISC-licensed `pqwy/notty` revision
[`e035d069370da436f1fc53525c1e16bff3ed687e`](https://github.com/pqwy/notty/tree/e035d069370da436f1fc53525c1e16bff3ed687e),
exactly upstream tag `v0.2.3`.  It reuses the archive and hash of
`pqwy-notty-source`; version stamping occurs only in the private build tree,
not the immutable source snapshot.  The package installs the pure `notty`
core, `notty.unix`, `notty.lwt` and `notty.top` findlib libraries.  This
revision has **no Async backend**.  All 18 upstream example executables are
retained under `libexec/notty`, with example sources, README, changelog and
license under `share/doc/notty`.

Notty is a library, not a `notty` command or an automatically activated UI.
Use OCaml 4.14, matching the installed library's compiler ABI.  For an
application source file `app.ml` using the Unix backend:

```sh
guix build -L guix --no-grafts notty
guix shell -L guix notty ocaml@4.14.3 ocaml-findlib gcc-toolchain -- \
  ocamlfind ocamlopt -package notty,notty.unix -linkpkg -o app app.ml
./app
make check-notty
```

For a Lwt application, compile with `-thread -package notty,notty.lwt`
instead.  `notty.top` supplies OCaml toplevel support; it is not another
terminal I/O backend.  Uutf and Lwt are propagated dependencies.  See the
[upstream interfaces and examples](https://pqwy.github.io/notty/doc) for
image composition and terminal lifecycle APIs.

On 2026-10-02, the local source build, `--check` reproducibility rebuild and
offline lint passed.  The standard Dune `runtest` phase remains enabled,
but upstream has **no test stanzas at this revision**: this is not a claim
that an upstream unit suite ran.  The recipe compiles `@ex`; runtime proof
comes from a separate native consumer compiled against the installed core,
Unix and Lwt libraries, not from a replacement renderer or a build-tree link.

The network-isolated, read-only-store smoke exercised both backends' actual
geometry, overlay/crop composition, aligned Unicode (`界é`), ANSI colors and
attributes, all four arrows and ASCII input, and resize from 40×12 to 52×16.
Both sessions restored termios, cursor visibility and the alternate screen.
The output, snapshot tree and complete snapshot output NAR hashes remained
unchanged.  The pyte screen model corrects `ESC E` (NEL) to index plus carriage
return; it does not edit the raw terminal capture.  Evidence is retained in
`/tmp/omp-notty-final`.  `.goocastle/evidence/issue-156.png` shows the exact
live Lwt capture prefix replayed in xterm, visually inspected with `SIZE 52x16`,
`EVENTS UP DOWN LEFT RIGHT x`, input state, red/cube/truecolor/gray and aligned
Unicode.  The proof uses a temporary dependency profile, not the user's
profile; no profile deployment or host configuration change is claimed.

## ITSTAR local ITS DUMP tape images

`itstar` builds upstream V1.10 from
[`PDP-10/itstar` revision `b709cd82ebcfa2cc78f79da8ca9e81c31f53a7c3`](https://github.com/PDP-10/itstar/tree/b709cd82ebcfa2cc78f79da8ca9e81c31f53a7c3)
as `1.10-0.b709cd8`, reusing the immutable `pdp10-itstar-source` origin.
The original C implementation creates, lists, extracts and appends ITS DUMP
tape images, translating ITS filenames and evacuated 36-bit words.  The
GPL-3.0-or-later declaration and copyright-holder relicensing permission
are installed with README and `itstar.doc` under
`share/doc/itstar-1.10-0.b709cd8`; the permission document was verified.

```sh
guix build -L guix --no-grafts itstar
make check-itstar
itstar -c -f local.tap src/hello.txt src/words.bin src/empty.txt
itstar -t -f local.tap
mkdir extracted
itstar -x -C extracted -f local.tap
itstar -r -f local.tap src/extra.txt
```

Operate only on files you own.  Upstream compressed-input behavior is
**destructive in place**: a `.Z` input is expanded to the unsuffixed filename
and the `.Z` file is deleted.  The stream may be UNIX `compress` or gzip;
format detection comes from gzip, not the suffix.  Keep an independent copy
when preservation matters.  The package invokes its declared gzip executable
by absolute store path, including with an empty PATH, rather than a
PATH-dependent `zcat` wrapper.

Historical issue #58 explicitly authorizes removing the legacy `host:device`
remote-rmt path with its unavailable `rexec` dependency.  Such paths fail
locally before hostname lookup.  This restriction does not remove physical
tape support; **physical tape hardware was not tested**.  The acceptance
proof covers local images only.  Upstream provides no automated test suite;
the separate installed-CLI smoke is the runtime proof.

On 2026-10-02, local build, `--check` reproducibility rebuild and offline lint
completed successfully.  The native smoke ran with private HOME/XDG state,
separate user/mount/network/IPC/PID namespaces, no host network interfaces and
a read-only store.  It exercised actual create/list/extract/append operations
with exact ITS listings and byte-identical evacuated text, binary and empty
files spanning record boundaries.  Both UNIX-compress and gzip `.Z` inputs
were expanded and deleted exactly as upstream specifies.  An independently
constructed SIMH-framed/TM03-word DUMP fixture, not an ITSTAR-created oracle,
listed and extracted exactly `ABCDE`.  Evidence is retained in
`/tmp/omp-itstar-proof`; the installed output NAR remained unchanged:
`1bpkyhrffrprpbfsvc77dmkd2m56lbc9yv2ip96pkishpr0f85lh`.
No user profile, host configuration or physical tape was changed.
`.goocastle/evidence/issue-58.png` captures the unchanged
`/tmp/omp-itstar-proof/list-appended.stdout` in a real xterm.  It was visually
inspected with the original `Tape 1, reel 0` random-tape header and the five
`SRC;HELLO TXT`, `SRC;WORDS BIN`, `SRC;EMPTY TXT`, `SRC;LZW TXT` and
`SRC;EXTRA TXT` entries, without errors.

## Miou OCaml concurrency library

`miou` packages the MIT-licensed `robur-coop/miou` revision
[`5fcb7e65b648f5c3d22d01d0ebe70c321042f09d`](https://github.com/robur-coop/miou/tree/5fcb7e65b648f5c3d22d01d0ebe70c321042f09d)
as `0.8.0-1.5fcb7e6`.  This is four commits after upstream `v0.8.0`, not the
release tag itself.  It reuses the immutable `robur-coop-miou-source` origin
and installs all six public findlib libraries: `miou`, `miou.backoff`,
`miou.sync`, `miou.bitv`, `miou.unix` and `miou.runtime_events`, including
the native Unix and bit-vector C stubs.  README, changelog and MIT notice are
installed under `share/doc/miou`.  This is a library, not a `miou` command.

The pin requires OCaml >= 5.1 and Dune >= 3.13.  This recipe uses Guix's
OCaml **5.4.1** and Dune **3.19.1**, rewriting the complete dependency graph,
including implicit build-system inputs, to one compiler ABI.  Do not mix it
with the default OCaml 4.14/findlib or the channel's OCaml-4.14 Notty build.
The compiler and findlib variants remain private to this package; the
consumer manifest supplies the matching toolchain without changing the
user's profile.  For an application source file `app.ml`:

```sh
guix build -L guix --no-grafts miou
guix shell -L guix --no-grafts --pure -m tests/miou-manifest.scm -- \
  ocamlfind ocamlopt -package miou.unix -linkpkg -o app app.ml
./app
make check-miou
```

Use `-package miou` for core-only consumers and add the relevant sublibraries
for synchronization, bit vectors, backoff or runtime-event tracing.  The
manifest is a development/consumer environment, not a profile deployment.

The toolchain closure uses OCamlbuild 0.16.1 for its OCaml-5-compatible Digest
handling, an upstream Alcotest normalizer fix for multiline source spans,
and Guile 3.0.11 only for the affected Astring builder.  All build phases
remain enabled; behavioral expected results are not weakened.  Dscheck 0.6.0
satisfies upstream's >= 0.4 requirement using the OCaml standard library,
without the obsolete containers/oseq/tsort dependency chain.

On 2026-10-02, local source build, `--check` reproducibility rebuild and
offline lint completed successfully.  The unfiltered upstream Dune tests
passed all 48 core groups, five Unix groups (with three worker domains) and
three synchronization groups; Dscheck and Alcotest dependency checks were
also retained.  The isolated installed-library consumer compiled natively
against all six installed libraries in a fresh Guix container without host
network interfaces or inherited profile/search paths.  It verified deferred
`async` versus `yield` ordering, result payloads, exception identity and
`await_all` argument order, real Unix sleep/resume, Bitv partial-byte and native
stub behavior, synchronization transitions and backoff reset, and a runtime
event reporter/reader roundtrip for Spawn, Yield and Await.  Store files stayed
read-only and the output NAR remained unchanged:
`0v3kzqy0dhc7fg8acqhkrq13pln61jci5fz839j7hyi6cg1awflv`.
Findlib's duplicate definitions of compiler-supplied `unix`, `threads` and
`runtime_events` remain visible warnings; no incompatible compiler ABI was
used.  Installation activates nothing and no user profile was deployed.
`.goocastle/evidence/issue-160.png` captures the actual xterm replay of
`/tmp/omp-miou-final.raw`, visually inspected with the successful consumer
result and immutable-NAR report.  The duplicate-META warnings remain visible
in that evidence; they are not errors or hidden by the proof.

## Tui styled Clojure text and line input

`tui` packages the EPL-2.0 `pmatiello/tui` revision
[`e435b1b60dbcc86b91060ccff70fe765b3285224`](https://github.com/pmatiello/tui/tree/e435b1b60dbcc86b91060ccff70fe765b3285224)
as `0.2.0-0.e435b1b`, reusing the exact `pmatiello-tui-source` origin.
The complete upstream library is AOT-compiled into `share/java/tui.jar`;
unchanged upstream tests remain under `share/tui/tests`, and the README,
changelog, EPL license and build metadata under `share/doc/tui`.

This is a library for styled text/page rendering, flushing and cooked,
line-oriented input, not a full-screen terminal framework.  It has **no raw
key-input or cursor-addressing API**.  The `tui-clojure` launcher supplies
the installed jar and Guix's source-built Clojure 1.12.4 runtime, including
spec.alpha/core.specs.alpha, using IcedTea 3.19.0 (Java 8).  It uses fixed
store classpaths, optionally appending `CLASSPATH` for local consumer code;
no Maven, Clojars, deps.edn Git test runner or dependency download is needed.

```sh
guix build -L guix --no-grafts tui
make check-tui
tui-clojure -e '(require (quote [me.pmatiello.tui.core :as tui]))
  (tui/println {:style [:bold :fg-green] :body "Hello, café λ!"})
  (tui/flush)'
tui-clojure app.clj
```

Use `tui/render` for strings composed from text and styled segments,
`tui/print`/`tui/println` for output, and `tui/read-line`/`tui/read-lines`
for cooked input and EOF.  Bold, underline, reset, foreground/background
colors and their dispatched reset forms are available.  **Pinned upstream
limitations are preserved**, not patched into new features: the style spec
advertises `:faint`, `:italic`, `:slow-blink`, `:fast-blink`, `:reverse-video`,
`:conceal`, `:strike`, `:weight-off`, `:italic-off`, `:reverse-video-off`,
`:conceal-off` and `:strike-off`, but the rendering dispatch does not implement
them.  Conversely its `:blink` and `:bold-off` dispatch keys are absent from
the accepted spec.  These are not usable public style promises at this pin.
Consumer layout geometry belongs to the application, not a Tui layout engine.

On 2026-10-02, source build, `--check` reproducibility rebuild and offline lint
completed successfully.  The installed-jar proof reran all unchanged upstream
tests: **41 tests, 59 assertions, zero failures/errors**.  A real PTY consumer
loaded the installed store jar and verified empty-page/println boundaries,
plain/styled separators, ordered bold/foreground/background output and reset
boundaries, invalid-style rejection, Unicode `café λ`, and actual cooked input
`Alice` followed by `first`/`second` lines and EOF.  Terminal attributes remained
unchanged.  Execution used private HOME/XDG state, an isolated network namespace
and a read-only store; package, snapshot tree and snapshot-output NARs stayed
unchanged.  Evidence is retained in `/tmp/omp-tui-final`.
`.goocastle/evidence/issue-155.png` is the unchanged `tui-live.raw` replayed
in a real 40×16 xterm, visually inspected with the cyan installed-consumer
heading, red-on-blue text, green underline, Unicode and `Name>` prompt,
without errors.  This live-prefix image proves display, not later input/EOF;
those are established by the actual completed PTY session/report.  No user
profile deployment or host configuration change occurred.

## PROIEL Ruby treebank library

`proiel` 1.3.3 builds the `syntacticus/proiel` code at
[`8b74767f3c9acf978117afe7db18cfd67675ba7b`](https://github.com/syntacticus/proiel/tree/8b74767f3c9acf978117afe7db18cfd67675ba7b)
from the recorded snapshot origin, with a **corpus-free native source
sanitization**.  It provides PROIEL XML reading/validation, sentence and token
objects, dependency resolution, annotation schemas, dictionaries and valency
analysis.  It is a library loaded with `require 'proiel'`, not a `proiel` CLI.
An independently authored MIT example is installed at
`share/proiel/examples/minimal.xml`.

The original `syntacticus-proiel-source` preservation snapshot is **not
MIT-only or wholly free**: its annotated test corpora include CC-BY-NC-SA 3.0
and dictionary metadata labelled CC-BY-NC-SA 4.0.  Its mixed-license metadata
is corrected without altering archive or installed snapshot bytes.  The native
package removes all corpus-derived XML and inline valency graphs before
building, regenerating 14 XML fixtures and independent valency graphs rather
than relabelling corpus data.  All 154 PROIEL examples remain exercised, with
data-specific assertions migrated to the new fixtures; no noncommercial corpus
is retained in the native source or installed gem.

Native licensing is MIT for code and synthetic fixtures, GPL-3.0-or-later for
the historical TEI Lite schema (selected under the contemporary TEI P5 1.1.0
grant's later-version option), and W3C for the XML namespace schema.  This is
not an inferred retroactive TEI BSD relicense.  The gem includes schema notices,
the original TEI grant and selected GPL text alongside the MIT license.

Use the canonical `(gnu packages ruby)` binding, verified here as **Ruby
3.3.9**, not a bare `ruby` package lookup that may select Ruby 4.0.  Preserve
the interpreter's bundled gems as well as the profile's propagated runtime gems:

```sh
guix build -L guix --no-grafts proiel ruby-memoist ruby-sax-machine
make check-proiel
ruby_out=$(guix build --no-grafts -e '(@ (gnu packages ruby) ruby)')
guix shell -L guix --pure -e '(@ (gnu packages ruby) ruby)' proiel -- \
  sh -c 'export GEM_PATH="$GEM_PATH:$("$1/bin/ruby" -rrubygems -e "print Gem.default_dir")";
         exec "$1/bin/ruby" "$2"' sh "$ruby_out" app.rb
```

Runtime dependency constraints remain intact, using private Builder 3.2.4 and
JSON 2.3.1 variants rather than incompatible newer versions.  Builder's
BlankSlate accounts for modern Ruby's late Kernel includes; SAX Machine's
constructor calls zero-argument `super` and handles forwarded nil attributes.
These compatibility fixes preserve the tested behavior.  `ruby-memoist` 0.16.2
and `ruby-sax-machine` 1.3.2 are also exported as installable MIT libraries.

On 2026-10-02, source builds, `--check` reproducibility rebuilds and offline
lint completed successfully.  PROIEL's complete 154-example corpus-free suite
passed; Memoist passed 31 runs/140 assertions and SAX Machine passed 135
examples.  JSON's pure and native-extension checks were retained and passed.
The final installed consumer ran outside the checkout in a pure,
network-isolated Guix container with fresh HOME/XDG state and only the declared
runtime gems plus the canonical interpreter's bundled gem directory.  It
verified XML entity decoding, metadata, schema/integrity validation, exact
sentence/token IDs and attributes, dependency edges, citation reconstruction
and valency extraction.  The exact result was
`{"status":"ok","version":"1.3.3","sources":1,"sentences":2,"tokens":5,"dependency_edges":3,"fixture":"minimal.xml"}`.
The example remained byte-identical and the installed output NAR unchanged.
No user profile deployment or host configuration change occurred.
`.goocastle/evidence/issue-170.png` captures the actual
`/tmp/omp-proiel-final.raw` replay in xterm, visually inspected with the exact
successful JSON result and unchanged-NAR smoke report.  The unrelated
`nhfourk` module-load warning remains visible, not suppressed.

## Domainslib native OCaml task pools

`domainslib` packages the ISC-licensed `ocaml-multicore/domainslib` revision
[`2a884868ff69c13ecef8efecca9ba1102ff11a7f`](https://github.com/ocaml-multicore/domainslib/tree/2a884868ff69c13ecef8efecca9ba1102ff11a7f)
as `0.5.2-1.2a88486`, reusing the immutable snapshot origin.  The installed
findlib library provides native multicore task pools, promises, parallel loops,
reductions, scans/searches and bounded/unbounded channels.  The upstream README,
changelog and ISC notice are installed under `share/doc/domainslib`.

This is a library, not a `domainslib` command.  It reuses Miou's complete
OCaml **5.4.1** compiler/findlib dependency closure, including implicit build
inputs, rather than building a second ABI graph.  Use the matching consumer
manifest, not default OCaml 4.14 or a profile containing incompatible OCaml
libraries:

```sh
guix build -L guix --no-grafts domainslib
make check-domainslib
guix shell -L guix --no-grafts --pure -m tests/domainslib-manifest.scm -- \
  ocamlfind ocamlopt -thread -package domainslib -linkpkg -o app app.ml
./app
```

The recipe runs Domainslib's **unfiltered native Dune test alias**, including
integration, clock, randomized model/property tests, byte/native backtraces and
debug runtime.  Dependency test coverage is package-specific, not a claim of
entire-monorepo or JavaScript coverage: QCheck's four selected public packages
exclude the unrelated PPX extension; Yojson's core package excludes JSON5 and
bench packages; multicoretests supplies STM and utility packages, not LIN or
the separate umbrella package; both `kcas` and `kcas_data` are retained.
Multicore-magic's optional JavaScript test is gated on `js_of_ocaml` availability;
both native tests remain enabled.  Kcas's compiler-dependent opaque location
constructor renderings are removed from MDX expectations via wildcards, not
repinned to new incidental strings.  Every semantic example and operation
result remains exercised.

On 2026-10-02, local build, `--check` reproducibility rebuild and offline lint
completed successfully; the full native Domainslib suite passed.  A separate
consumer compiled against the installed library in a fresh, network-isolated
Guix container with private HOME/XDG state.  A barrier and distinct domain IDs
proved simultaneous execution rather than serial computation of correct sums.
The consumer verified parallel Fibonacci, exactly-once per-index coverage with
default/unit chunks, reduction and empty-range identity, integer and
noncommutative scans including empty/singleton boundaries, found/missing search,
exception identity and pool reuse after failure, zero-worker fallback, invalid
pool/channel bounds, zero-buffer rendezvous, bounded capacity and unbounded FIFO.
Its transcript matched independent exact oracles:
`fib=317811 reduction=500500 channel=358438400` followed by
`domainslib consumer passed`.  Store files stayed read-only and the output NAR
remained unchanged:
`1nmjs721cjsfc7vakpibvq22s02ampryh9ligikzw7baszgcm0hz`.
Findlib's duplicate compiler `unix`/`threads` META warnings remain visible;
they are not compiler ABI errors.  No user profile deployment or host
configuration change occurred.
`.goocastle/evidence/issue-149.png` is the actual xterm replay of
`/tmp/omp-domainslib-final.raw`, visually inspected with the exact Fibonacci,
reduction and channel results, successful consumer and unchanged-NAR report.
The duplicate findlib warnings remain visible, with no runtime errors.

## Vim-style Emacs region editing

`emacs-vim-region` builds `ongaeshi/emacs-vim-region` revision
[`7c4a99ce3678fee40c83ab88e8ad075d2a935fdf`](https://github.com/ongaeshi/emacs-vim-region/tree/7c4a99ce3678fee40c83ab88e8ad075d2a935fdf)
as `0-7c4a99c`, reusing the immutable source origin.  The installed source
and bytecode provide Vim-style region motion and editing via the global
`vim-region-mode`, with `emacs-expand-region` propagated.  README and HISTORY
are installed under `share/doc/emacs-vim-region`.

There is no standalone LICENSE upstream.  The 2013 ongaeshi copyright and
complete **GPL-3.0-or-later** grant are present in `vim-region.el` itself,
retained byte-for-byte in the installed header.  This resolves the earlier
licensing uncertainty; it does not invent a separate license file or alter
the preservation archive.  The native package adds the missing
`(require 'expand-region)` so the existing `+` binding works immediately
after loading the library; commands and bindings otherwise remain upstream.

```sh
guix build -L guix --no-grafts emacs-vim-region
make check-emacs-vim-region
```

In an Emacs session with the package on its load path, explicitly load and
enable it:

```elisp
(require 'vim-region)
(vim-region-mode 1)
```

Ordinary editing commands exit the mode automatically unless the upstream
persistent-selection option is enabled.  Installation does not enable the
mode or edit the user's Emacs configuration.  This is a region-selection
extension, not a replacement Emacs or a full Vim implementation.

On 2026-10-02, source build, `--check` reproducibility rebuild and offline lint
passed.  **Upstream has no test suite**; the independent installed-package
smoke proved behavior in both batch Emacs and real `emacs -nw`.  It drove
keyboard macros through the actual keymaps and pre/post-command hooks for
region motion, kill/copy/yank, automatic exit, persistent (`eternal`) selection,
character searches, symbol selection and expand-region.  Starting from
`alpha beta gamma\nkeep this line\n`, the final edited buffer was exactly
`alpha gammabeta \nkeep this line\n`, including the trailing space before the
first newline.  It left `alpha` actively selected with point 6 and mark 1,
both global/local modes on and the buffer modified.

The proof used a private HOME/XDG state, empty PATH and a separate network
namespace; installed package and expand-region files stayed read-only and
byte-identical.  An open FIFO prevents util-linux `script` from synthesizing
an editing NUL from `/dev/null` EOF.  The raw final display prefix is retained
in `/tmp/omp-vim-region-final.raw`, before alternate-screen restoration.
No user profile deployment or host configuration change occurred.
`.goocastle/evidence/issue-215.png` is the actual raw-display replay in xterm,
visually inspected with `alpha gammabeta ` and `keep this line`, highlighted
`alpha`, and the modified-buffer `**`/`Fundamental vim-region` mode line.
The screenshot shows the genuine edited buffer, not a success-caption buffer.

## Org mind maps with store-bound Graphviz

`org-mind-map` builds the original Emacs Lisp library from
[`the-ted/org-mind-map` revision `95347b2f9291f5c5eb6ebac8e726c03634c61de3`](https://github.com/the-ted/org-mind-map/tree/95347b2f9291f5c5eb6ebac8e726c03634c61de3)
as `0.4-0.95347b2`.  It inherits GNU Guix's `emacs-org-mind-map` recipe and
propagated Dash dependency, but deliberately replaces its older 0.4 pin
(`477701b`) with the channel's reviewed post-release snapshot.  The newer
revision adds `org-mind-map-include-images`; `org-mind-map-include-text` was
already present and is not a new feature of this pin.  The installed source,
bytecode and autoloads retain upstream's whole-buffer, branch and current-tree
exports, headings, tags, text, local images and optional inter-heading links.
README and LICENSE are installed under `share/doc/org-mind-map`.

The Lisp code is **GPL-3.0-or-later**.  The native origin removes all bundled
example PNGs (including `Lena.png` and its `example-8.png` derivative) and the
root `org-mind-map.el.pdf`; redistribution permission for Lena is absent or
unknown.  The raw `the-ted-org-mind-map-source` preservation snapshot remains
unchanged, with mixed `license:gpl3+` / `%no-permission-license` metadata rather
than a claim that every archived asset is freely redistributable.

Graphviz's `dot` and `unflatten` defaults point to absolute store paths, so
export does not require Graphviz in the user's PATH or profile.  Actual SVG
rendering exposed clipping with Graphviz 7's non-72-DPI transform: the recipe
adds `-Gdpi=72 -Gresolution=72` **only for SVG** to keep graph content inside
the viewport.  Bitmap resolution settings and upstream layout selection are
unchanged.

```sh
guix build -L guix --no-grafts org-mind-map
make check-org-mind-map
```

In an Emacs session with the package on its load path, load Org's export
backend before the library:

```elisp
(require 'ox-org)
(require 'org-mind-map)
(setq org-mind-map-dot-output '("svg"))
```

Open an Org file and use `M-x org-mind-map-write-with-prompt` to export it,
or the upstream `org-mind-map-write-current-branch` /
`org-mind-map-write-current-tree` commands for narrower exports.  Installation
does not edit the user's Emacs configuration or enable a service.

On 2026-10-02, local source build, `--check` reproducibility rebuild and offline
lint passed for
`/gnu/store/1sgq3rvb554bcqix0nhnsc11xrm48y5r-org-mind-map-0.4-0.95347b2`.
**Upstream has no test suite**; the independent installed-package smoke runs
real batch Emacs and asynchronous Graphviz with fresh HOME/XDG state, empty
PATH/`exec-path` and a separate network namespace.  It verifies exact SVG
node labels, directed edges, paragraph text, tags and viewport bounds: the
whole fixture has eight nodes/six edges, the narrowed Build subtree three/two,
and the image-enabled/disabled fixtures each two/one with exactly one/zero
images.  The original local blue-and-yellow checkerboard is attached to Tile;
no upstream demonstration image is reused.  The image fixture disables text
separately because upstream assumes paragraph content can be converted to a
string; this proof does not claim combined image/text paragraphs are fixed.

Set `ORG_MIND_MAP_SMOKE_ARTIFACT_DIR=/absolute/path` to retain Org, DOT, SVG,
PNG and diagnostic artifacts.  The final local run is retained under
`/tmp/omp-org-mind-map-unclipped/org-mind-map.vE95kD`.
`.goocastle/evidence/issue-171.png` is the Chromium-inspected complete graph:
Plan → Design → Sketch, Plan → Build → {Assemble, Check}, and Other → Later.
`.goocastle/evidence/issue-171-image.png` shows Picture → Tile with the original
checkerboard.  These are OMP-produced visual evidence, not Goocastle execution.
The proof covers the exercised exports, not every layout, format or optional
link feature.  No user profile or deployed system changed; no network OKF
update applies to this repository-only addition.

## Native backlog integrations — observed verification

On 2026-10-03, source builds, reproducibility `--check` rebuilds and
installed-output smokes passed for `hackem`, `hellcrawl`, `wired` and
`scala-ts`; scala-ts's build passed all 22 upstream tests.  The four
integrated Make targets passed, and offline lint reported no package-specific
findings.  The final Hack'EM/Wired outputs and Scala's supplemented origins
passed fresh native/exact-consumer checks with unchanged immutable outputs.

- **Hack'EM 1.2.2** (`elunna/hackem` revision `6e99cff`): the launcher now
  forwards ordinary game arguments with private XDG configuration/state,
  installs the required native symbol definitions and keeps dump logs under
  private state.  The production `--guix-smoke` branch is removed; NGPL
  modification notices and the bundled ISAAC64 CC0/public-domain notice are
  retained.  `tests/hackem-smoke.sh` / `tests/hackem-smoke.py` at
  `/tmp/hackem-native-movement` passed three ordinary TTY sessions with full
  map/HUD/inventory continuity, one actual floor move away from visible
  hostiles and native compressed save per session, two exact independent
  restores, consumed saves and unchanged read-only output NAR.  The proof
  performs genuine movement rather than stationary searches; it does not
  claim a fixed five-search-turn sequence.
- **Hellcrawl 5.7** (`Hellmonk/hellcrawl` revision `8abd877`): the original
  console game/data/notices and XDG-managed saves remain, without the
  production `--smoke` branch or installed smoke PTY helper.  The standalone
  `tests/hellcrawl-smoke.sh` / `tests/hellcrawl-smoke.py` passed at
  `/tmp/hellcrawl-native-dumpfix`: native menus/dungeon entry, turn
  0 → 1, save/exit, independent restoration of persistent character state
  at turn 1, then turn 2 and resave.  Raw PTYs, interpreted screens, native
  dumps and the report are retained; the output NAR remained unchanged.
- **Wired 0.10.7** (`Toqozz/wired-notify` revision `6b6f3c1`): the recipe
  retains the locked Cargo graph's manifests and nested license notices.
  `tests/wired-smoke.sh` at `/var/tmp/wired-native-fixed` passed
  real D-Bus `Notify`, mapped-window/rendered-pixel checks,
  `CloseNotification`, and ordinary `--kill`, with unchanged store-tree
  digest.  The private D-Bus/Xvfb/fontconfig and namespace proof retained
  PNGs/logs.  Screenshot inspection found a truncated title but readable
  notification body; it is not evidence of untruncated title rendering.
  The inspected native screenshot is
  [wired-native.png](.goocastle/evidence/wired-native.png).
- **scala-ts 0.1.8** (`codingismy11to7/scala-ts` revision `9342030`): package
  metadata now selects source-built `dist/scala-ts.js` with its matching
  declarations rather than the obsolete legacy bundle.  The standalone
  `tests/scala-ts-smoke.sh` passed the strict compiled installed-consumer
  scenario: populated scores totaled 52, empty/error cases and Try recovery
  matched the exact JSON oracle, and the output NAR stayed unchanged.  The
  build passed all 22 upstream tests.  The dated audit at
  `/tmp/scala-license-closure-20261003/audit-report.json` verifies all 698
  pinned archive hashes and 990 lockfile integrity records; it records
  sanitized node-notifier payloads and retained TypeScript helper notices.
  Follow-up primary-source review resolves the 19 full-text omissions as
  notice-retention gaps rather than installed-output grant blockers:
  json-schema's AFL-or-BSD metadata and same-owner MIT file headers are
  complementary, with the linked historical Dojo terms recovered.  Eighteen
  build-origin full-text supplements are implemented with eight shared notice
  texts and exact package/version mappings, preserving original attribution;
  the CC0 spdx-license-ids entry requires no notice.  The receipt is
  `/tmp/scala-license-followup-20261003/followup-report.json`.  The final
  derived-origin build, reproducibility rebuild and exact installed-consumer
  smoke passed with unchanged NAR.  All 18 realized source archives were
  inspected: their 20 supplement texts matched the full notice contract
  byte-for-byte, recorded in
  `/tmp/scala-license-followup-20261003/main-realized-verification.json`.
  Raw notifier archives retain
  Apple/LGPL payload redistribution caveats although the derived origin
  excludes those payloads; no blanket raw-tarball redistribution claim applies.

Build/smoke commands for reproducing the verified paths, run serially from
the checkout with fresh evidence (the Hack'EM and Hellcrawl helpers require
empty destinations):

```sh
guix lint -L guix --no-network --exclude=cve,refresh,archival hackem hellcrawl wired scala-ts
hackem_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 hackem)
hellcrawl_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 hellcrawl)
wired_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 wired)
scala_ts_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 scala-ts)
guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 --check hackem hellcrawl wired scala-ts
GUIX=guix sh tests/hackem-smoke.sh "$hackem_out" --output /tmp/hackem-native-evidence-FRESH
HELLCRAWL_SMOKE_ARTIFACTS=/tmp/hellcrawl-native-evidence-FRESH GUIX=guix sh tests/hellcrawl-smoke.sh "$hellcrawl_out"
WIRED_SMOKE_ARTIFACTS=/var/tmp/wired-native-evidence-FRESH GUIX=guix sh tests/wired-smoke.sh "$wired_out"
GUIX=guix sh tests/scala-ts-smoke.sh "$scala_ts_out"
```

The four `make check-*` targets invoke these standalone helpers, are included
in `make check`, and passed on 2026-10-03.  Offline lint also passed without
package-specific findings; unrelated diagnostics are not acceptance evidence.
Only obsolete executable-mode contracts for Hack'EM #693 and Hellcrawl #694
were removed from `.goocastle/runtime-evidence-contracts.json`.  Historical
screenshots and other contract records remain untouched and do not establish
current acceptance.  This is repository-only work, not a deployed-system
change; no network OKF page update applies.

## CrashRun, Dungeon Monkey Unlimited and Emigo — verified native paths

On 2026-10-03, final source builds, reproducibility rebuilds, installed-runtime
smokes and offline lint passed for these three packages.  Emigo's proof covers
local backend/IPC/parser/tokenizer operations and fail-closed TLS trust, **not
provider calls or the interactive chat UI**.  Legacy Cargo-input deprecation
warnings remain; no package-specific lint findings were reported.

- **CrashRun #314** packages DanaL's Python 3/SDL2 `v0.5.0` branch snapshot
  at `9b95cc7dd2b8227a219769a95fcaee48e3371bec`, not a tagged stable release.
  The canonical [crashrun.org](http://crashrun.org/) links that repository;
  its advertised stable release is 0.4.1 (2010-03-23), while the pinned
  branch revision dates to 2018-12-05.  The source NAR was rechecked as
  `1mmznn1ly3dh9yd4hh6yfk7gysxwjn8q804b65zm6zxg0085kky8`.
  Code/texts retain GPL-3.0-or-later notices, and the unmodified VeraMono
  font retains its Bitstream Vera permission notice.  The production
  `--smoke` branch and bundled synthetic Python executor are removed.
  `tests/crashrun-smoke.sh` / `tests/crashrun-smoke.py` passed at
  `/tmp/crashrun-native-confined`: original SDL/X11 name/character/skill
  creation, inventory, pass turns, native save/exit, independent load and
  resave, isolated state and unchanged output.  Screenshot inspection showed
  the actual ASCII/player map, character `guix-smoke`, AC 15, HP 18(18) and
  Outside location.  Xvfb/xdotool/OCR/screenshots and actual archive turn
  counters replace game monkeypatching; `CRASHRUN_SMOKE_EVIDENCE` retains
  gameplay/screen PNGs and game/Xserver logs.  Offline lint and final
  reproducibility rebuild passed.
  The inspected native screenshot is
  [crashrun-native.png](.goocastle/evidence/crashrun-native.png).
- **Dungeon Monkey Unlimited #336** packages source release 1.001; its
  independently rechecked archive hash remains
  `1p796097xgyykvax2piv8k04g9asdr2wnfd9aigzayjpfh6yswpp`.  Source headers grant
  LGPL-2.1-or-later; Gervais tiles retain CC-BY-3.0 attribution, RLTiles
  retain public-domain credits, and VeraBd is the only installed font with
  its Bitstream Vera notice.  The production `--smoke` branch/binary and
  synthetic Pascal helper are removed.
  `tests/dungeon-monkey-unlimited-smoke.sh` /
  `tests/dungeon-monkey-unlimited-x11-runner.py` passed at
  `/tmp/dmu-native-input-diagnostic`: actual NativeHero/NativeCampaign GUI
  creation, movement, native save, independent restore, further movement
  and unchanged output NAR.  Screenshot inspection showed NativeHero in an
  isometric forest/hut scene.  Private namespaces/Xvfb keep the host session
  separate; `DMU_SMOKE_ARTIFACTS` retains PNG/XWD windows, native save
  snapshots, inputs and a report.  The final post-format build,
  reproducibility rebuild, fresh native run at `/tmp/dmu-native-final`,
  unchanged NAR and offline lint passed.
  The inspected native screenshot is
  [dmu-native.png](.goocastle/evidence/dmu-native.png).
- **Emigo #76** packages MatthewZMD/emigo revision `91d122a` as
  `0.5-0.91d122a`, with installed Emacs Lisp, a store-bound Python launcher,
  parser queries, local cl100k tokenizer vocabulary and dependency/notices
  closure.  `tests/emigo-smoke.sh`, `tests/emigo-smoke.el` and
  `tests/emigo-local-smoke.py` passed real two-way EPC transport,
  file context/token-header/add/reject/remove/cleanup, installed parser
  definitions/repomap, tokenizer and path-error cases.  The clean
  user/network namespace enables only loopback for EPC; no provider request,
  credentials, model response or end-to-end LLM capability is claimed.
  No synthetic production mode existed or was added.  The helper returns
  77 when the required unprivileged namespaces are unavailable.
  The source combines explicit GPL-3.0-or-later `utils.py`/`emigo-epc.el`,
  Apache-2.0 root/`emigo.el`, and MIT/Apache query notices.  The packaged
  tree-sitter-language-pack 0.5.0 retains upstream README/LICENSE parser
  credits, but its sdist lacks individual parser license files: those
  permissive-license credits are upstream's coverage assertion, **not
  per-file legal provenance verification**.  LiteLLM's enterprise directory
  is excluded; tokenizer MIT notice and the fixed vocabulary are retained.
  Optional provider SDK integrations outside the core closure are not installed.
  The Python/LiteLLM closure supplies its own default trust data rather than
  depending on a host Certifi path.  The
  python-litellm recipe now installs an immutable Mozilla/NSS-derived CA
  bundle as its default fallback, without disabling TLS verification.
  Explicit `SSL_CERT_FILE`, `REQUESTS_CA_BUNDLE`, `ssl_verify` paths and
  `SSL_CERT_DIR` remain honored, including invalid-file errors.  The runner's
  `tests/emigo-ca-smoke.py` passed real SSLContext root loading,
  `CERT_REQUIRED`/hostname checking and valid/invalid explicit CA precedence
  without HTTP.  The final build and reproducibility output is
  `/gnu/store/w2fn8c60689k4aiazfi0358kzhaw556q-emigo-0.5-0.91d122a`.

Build/smoke commands, run serially from the checkout with fresh evidence:

```sh
guix lint -L guix --no-network --exclude=cve,refresh,archival crashrun dungeon-monkey-unlimited emigo
crashrun_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 crashrun)
dmu_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 dungeon-monkey-unlimited)
emigo_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 emigo)
guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 --check crashrun dungeon-monkey-unlimited emigo
CRASHRUN_SMOKE_EVIDENCE=/tmp/crashrun-native-evidence-FRESH GUIX=guix sh tests/crashrun-smoke.sh "$crashrun_out"
DMU_SMOKE_ARTIFACTS=/tmp/dmu-native-evidence-FRESH GUIX=guix sh tests/dungeon-monkey-unlimited-smoke.sh "$dmu_out"
GUIX=guix sh tests/emigo-smoke.sh "$emigo_out"
```

Only the obsolete `--smoke` executable contracts for CrashRun #670 and
Dungeon Monkey Unlimited #683 were removed from
`.goocastle/runtime-evidence-contracts.json`; their historical evidence files
remain untouched.  The current backlog issue numbers above are different
from those historical contract IDs.  No Emigo contract was removed.
No deployed host/service changed, so no network OKF update applies.

## Kraken, GenEd and SoundThread — verified native paths

These integrations provide native applications and standalone safe-proof
helpers.  Kraken passed final build/reproducibility/lint and integrated
offline text/hOCR proof, including 30 upstream tests with 51 subtests.
SoundThread passed final build/reproducibility/lint and real WAV import,
graph save/reload/render and mixed Master-bus PCM proof.  GenEd passed final
build/reproducibility/lint and real native scene open/text edit/save/reopen
proof.  All three integrated Make targets also passed.  No deployment is
established.

- **Kraken #143** packages mittagessen/kraken 7.1 at revision `eff0571e`
  with the original `kraken` and `ketos` entry points.  Kraken itself is
  source-built; `kraken-python-runtime` installs pinned official CPython 3.12
  dependency wheels, including CPU PyTorch 2.9.1/torchvision 0.24.1, without
  rebuilding their native extensions.  This binary-assisted closure is
  `x86_64-linux` only and retains bundled license/third-party notice trees and
  a provenance inventory.  The canonical Apache-2.0 tree supplies the
  `tests/resources` image, exact ground truth and overfit model; the earlier
  research path `kraken/tests/resources` was incorrect.  The standalone
  `tests/kraken-smoke.sh` passed real offline CPU recognition at
  `/tmp/kraken-native-final` in plain-text and hOCR modes,
  independently checking exact normalized output
  against upstream `tests/test_rpred.py:test_mm_rpred_bbox_nobidi` for the
  same model/image/full bounding box with `--no-reorder --pad 16`, export
  consistency and pinned asset hashes.  This checks logical codepoint order,
  not the different padding implied by the older simple-bbox test.  Installed
  `share/kraken/fixtures/provenance.json` records license/asset hashes and the
  exact oracle settings.
  The canonical reference matched exactly (similarity 1.0); independently
  normalized ground-truth similarity was 0.9315068.  These fixture-specific
  results do not establish production OCR accuracy.  `ketos --help` covers command discovery/import
  only, not training.  Production recognition needs a suitable separate local
  model; no automatic model fetch is part of the proof or build.
  The final provenance-bearing output
  `/gnu/store/xsn6hj9w3g8cppq5y1xz02q7azi6vhmi-kraken-7.1` passed its
  reproducibility rebuild, offline lint and integrated `make check-kraken`;
  all checked immutable assets remained unchanged.
- **GenEd #138** packages lambdamikel/GenEd revision `0d847a3b` as the
  GPL-3.0-only Common Lisp/McCLIM visual editor with a complete ordered ASDF
  system.  Ordinary `gened` launches the real editor; no production `--smoke`
  or frame-probe switch is installed.  Writable assets are copied once under
  `$XDG_DATA_HOME/gened`; upstream's disabled CLASSIC functionality remains
  unavailable.  The Allegro-only Print Scene menu is omitted; portable Save
  Scene As Postscript remains.  McCLIM compatibility repairs preserve command
  registration while separating the dynamic Undo label, and supply the
  required positional object to the blank-area creator translator.
  Property-pane queries resynchronize frame state on each pass; completion
  display names use `princ-to-string` while retaining their original typed
  values, so G-TEXT selects the actual class rather than an invalid string.
  Text creation uses the standard textual dialog view instead of the
  incompatible text-field gadget callback/output-record path.
  `tests/gened-smoke.sh` passed actual native X events under private Xvfb at
  `/tmp/gened-native-roundtrip`: original scene load, G-TEXT selection,
  creation of exact text `GenEd native exact text 750`, save, clear, reopen
  and resave with exact serialized-text/scene continuity checks.  Screenshot
  inspection of the reopened scene showed the original circle (ID 14) and
  new text (ID 15), not a synthetic frame.  The final output
  `/gnu/store/s27lvrf4ak6npph52dmkb5h0ixayf00q-gened-0-0.0d847a3` passed
  its reproducibility rebuild and offline lint.  The inspected native
  screenshot is [gened-native.png](.goocastle/evidence/gened-native.png).
  Integrated `make check-gened` also passed at `/tmp/gened-artifacts-ffBnb4`.
- **SoundThread #128** packages the canonical GDScript source at revision
  `a33198a`, launched with a pinned official prebuilt Godot 4.4.1 engine.
  The upstream engine ELF bytes remain unchanged; a wrapper selects the
  pinned Guix glibc loader and library path instead of patching the ELF.
  The recipe validates its exact six required shared-library sonames,
  dependency closure, byte identity and loader compatibility.
  Installed source under `share/soundthread` is imported on a disposable
  writable copy per launch, rather than modifying the immutable store tree.
  This is a source-run application, **not a source-built engine** or a claim
  that this engine is current or security-audited.  The application is MIT;
  Work Sans and Bravura fonts are OFL.  The bundled modified Bravura font
  retained its reserved font name, so the package replaces it at the existing
  resource path with pristine Guix Bravura 1.393 and retains both font
  licenses.  Engine copyright/license and third-party notices are retained.
  Automatic startup GitHub release requests are disabled because Guix owns
  version selection; explicit user-initiated browser/help/upstream links remain.
  Offline acceptance remains enforced by a private network namespace.
  Optional CDP is not installed or stubbed: users may configure the directory
  containing their `distort` executable in `user://settings.ini`, section
  `[cdpprogs]`, key `location`.  The standalone helper passed at
  `/var/tmp/soundthread-native-roundtripfix`: the original main scene imported
  a generated two-second WAV through its existing Input File node, connected
  the graph through Misc Gain set to 0.625 into Output File and saved/reloaded
  that state.  Actual input-preview playback—not gain-processed CDP output—
  produced Master-bus PCM captured by `AudioEffectCapture` on Godot's Dummy
  driver: 94,208 frames at 44,100 Hz, no discarded frames, and both channels
  measured 439.975 Hz with 1.99975 seconds of active signal.  The rendered
  waveform/graph was inspected.  Roundtrip comparison normalizes only numeric
  suffixes of anonymous `@Type@number` slider-path components and optionbutton
  keys; types, path/control order and values remain intact, and every other
  graph field is compared exactly.  Gain state is preserved but not executed:
  CDP is absent, and the processed-file field remains empty as expected.
  This does not prove host-speaker playback or optional CDP integration.
  The final output is
  `/gnu/store/8xm1qh308mhjpizcqshs9sfcmyk9f9g7-soundthread-0.0.0-0.a33198a`.
  Its external consumer script is not an installed application hook or
  production smoke mode.
  Integrated `make check-soundthread` also passed at
  `/var/tmp/soundthread-native-integrated`.  The inspected native screenshot is
  [soundthread-native.png](.goocastle/evidence/soundthread-native.png).

Build/smoke commands, run serially with fresh evidence directories:

```sh
guix lint -L guix --no-network --exclude=cve,refresh,archival kraken gened soundthread
kraken_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 kraken)
gened_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 gened)
soundthread_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 soundthread)
guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 --check kraken gened soundthread
KRAKEN_SMOKE_ARTIFACT_DIR=/tmp/kraken-native-FRESH GUIX=guix sh tests/kraken-smoke.sh "$kraken_out"
GUIX=guix sh tests/gened-smoke.sh --package "$gened_out" --artifacts /tmp/gened-native-FRESH
SOUNDTHREAD_SMOKE_ARTIFACTS=/tmp/soundthread-native-FRESH GUIX=guix sh tests/soundthread-smoke.sh "$soundthread_out"
```

The obsolete synthetic production-mode contracts #748 (SoundThread) and
#750 (GenEd) were removed from `.goocastle/runtime-evidence-contracts.json`.
Kraken's #751 contract was also retired: its `--serializer` option does not
exist in this pinned source (the real option is `--template`/`-t`), and its
marker-only proof is superseded by independent recognition/output checks.
Historical screenshots and unrelated contracts remain preserved.


## CotD, Emacs Application Framework and ECA — verified native paths

CotD passed final build/reproducibility/lint and native strategy save/advance/
restore proof.  ECA passed final label-bearing build/reproducibility/lint and
integrated real local JSON-RPC/`eca-emacs` proof, including a fresh exact
ungrafted-output run.  EAF passed final build/reproducibility/lint and genuine
GUI/demo/EPC/theme/resize/shutdown proof.  All three integrated Make targets
also passed.  No deployment is established.

- **CotD #122** packages gwathlobal/CotD revision `b771e2e` as
  `2.0.2-0.b771e2e` (the ASDF version is stale).  The original GPL-3.0-only
  SBCL/SDL game launches through `cotd` with no arguments or installed smoke
  switch.  Immutable assets are under `share/cotd`; native state is under
  `$XDG_STATE_HOME/cotd` or `$HOME/.local/state/cotd`.  Guix supplies
  lispbuilder-sdl/bordeaux-threads/cl-store/log4cl; pinned defenum retains its
  actual custom permissive COPYING terms rather than the misleading ASDF
  BSD metadata, and the SDL font notices remain retained.  The required
  `font_large.bmp` and source artwork `font_large_src.png` lack separate
  per-file licenses; their GPL-3.0 project-wide coverage is an inference from
  the root grant, not independent font-license verification.  There are no
  TTF/audio payloads or submodules.  The standalone
  `tests/cotd-smoke.sh` passed at `/tmp/cotd-native-loadfix`: a real Chrome
  angel campaign, baseline save/restart/load, native Next day advancing
  13 → 14 April 1915, followed by save/restart/restore/resave with exact
  time/faction/world-map continuity.  Checkpointed native X events/OCR and
  private namespaces/Xvfb/HOME/XDG replace a production readiness marker.
  Inspection showed the populated map, Angels and Wait & see state; the
  actual restored screenshot is
  [cotd-native.png](.goocastle/evidence/cotd-native.png).
  Integrated `make check-cotd` also passed at `/tmp/cotd-native-integrated`.
  Tactical combat is outside that proof.
- **Emacs Application Framework #116** packages the GPL-3.0-or-later core
  at `5fe1a6c` and the real upstream GPL-3.0-or-later `eaf-demo` at
  `d210ef3`.  Consumers load `eaf`/`eaf-demo` in Emacs and invoke
  `eaf-open-demo`; there is no invented `eaf-emacs-application-framework`
  launcher or installed `--goocastle-smoke` branch.  The store-bound
  `eaf-python` wrapper supplies Qt6/Python/EPC and supporting libraries.
  Installed `core/js/caret_browsing.js` also retains its Chromium BSD-3-Clause
  notice; the package is not GPL-only.  Python Requests supports the core's
  lazy pyaria2 import without bundling the optional browser app.
  Private `python-eaf-tld` selects LGPL-2.1-or-later code terms and retains
  MPL-2.0 suffix data without a network updater.  No imperative installer,
  optional browser/media/provider app or missing-app stub is packaged.
  `tests/emacs-application-framework-smoke.sh` passed at
  `/tmp/eaf-native-cachefix` with actual GUI Emacs/upstream Qt demo and
  two-way EPC under private Xvfb/loopback-only networking: native app identity,
  pixel-visible theme transition, Python callback rename, resize from 1472
  to 736 pixels and restoration, ordinary missing-source `FileNotFoundError`,
  and close/stop lifecycle, with unchanged immutable output.  Artifacts include
  root-before/root-resized PNGs and demo-before/themed/normal/resized/restored
  JPEGs.  Resize proof clears Emacs's stale image cache; its earlier stale
  screenshot mismatch did not establish a Qt resize defect.  Actual screenshot
  inspection showed the renamed demo and working greeting, but oversized
  button text is clipped at the left edge, not fully fitted.  The inspected
  native screenshot is [eaf-native.png](.goocastle/evidence/eaf-native.png).
  The store-bound Python default-declaration compatibility correction passed
  final build/runtime.  A helper-only marker is not an application feature or
  optional-app proof.
  Integrated `make check-emacs-application-framework` also passed at
  `/tmp/eaf-native-integrated`.
- **ECA #113** packages the official `eca.jar` **0.154.0** release at
  `52b6f015`, with a Guix OpenJDK 24 runtime.  This is a hash-pinned upstream
  JVM artifact, **not a Guix source rebuild** or an Oracle/GraalVM native
  executable.  Exact source, dependency lock/build workflow, bundled
  third-party LICENSE/NOTICE contents, exposed Maven POMs and release provenance
  are retained;
  no embedded native `.so`, Maven resolution or runtime server download is
  part of this installation.  The server is Apache-2.0; bundled dependencies
  retain their EPL/Apache/MIT/BSD/CDDL terms rather than being relicensed.
  `tests/eca-server-smoke.py` passed real framed JSON-RPC and actual
  `eca-emacs` at `/tmp/eca-server-smoke.8hlyt2hw`: initialize's
  `chatWelcomeMessage`, `config/updated` advertised agents, local `/doctor`,
  missing-history top-level `chat_not_found`, JSON-RPC unknown method
  `-32601`, shutdown/exit, and client welcome/doctor rendering.
  `ECA_SMOKE_KEEP_SCRATCH=1` retains `protocol.json`, `emacs-chat.txt` and
  `server.stderr`.  The companion's fake-server fixture remains a protocol
  unit fixture, not actual ECA server proof.  No provider/model request,
  credentials or model-assisted chat behavior is claimed.
  Final label-bearing build/reproducibility/lint and integrated `make check-eca`
  passed.  Both the integrated grafted output and a fresh exact final
  ungrafted-output run at `/tmp/eca-server-smoke.kn2hqsyk` passed.
  Provider-catalog/plugin fetching is explicitly disabled in the helper, but
  upstream initialization still attempts a `models.dev` catalog request.
  The offline namespace denies that external access (and the server logs the
  error), after which local zero-provider operations continue.  This proof
  establishes blocked external networking, not absence of attempted requests;
  the no-Maven/no-server-downloader installation boundary is separate.

Build/smoke commands for the verified paths, run serially with fresh evidence:

```sh
guix lint -L guix --no-network --exclude=cve,refresh,archival cotd emacs-eaf-emacs-application-framework eca
cotd_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 cotd)
eaf_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 emacs-eaf-emacs-application-framework)
eca_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 eca)
guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 --check cotd emacs-eaf-emacs-application-framework eca
GUIX=guix sh tests/cotd-smoke.sh --package "$cotd_out" --artifacts /tmp/cotd-native-FRESH
EAF_SMOKE_ARTIFACTS=/tmp/eaf-native-FRESH GUIX=guix sh tests/emacs-application-framework-smoke.sh "$eaf_out"
ECA_SMOKE_KEEP_SCRATCH=1 GUIX=guix python3 tests/eca-server-smoke.py "$eca_out"
```

The obsolete synthetic CotD #746 and EAF #744 executable contracts were
removed from `.goocastle/runtime-evidence-contracts.json`: ordinary native
consumers replace their invented smoke switches/missing-app stub.  ECA's #742
row was also retired: ordinary `eca server` remains valid, but its historical
`chat-welcome-message` marker is not the current wire field
`chatWelcomeMessage`.  This is not removal of a fake production mode.
Unrelated records and historical screenshots remain preserved.


## Pi, Squad and Oh My OpenCode Slim — verified native paths

These four package outputs cover Pi, Squad, the Slim plugin and its desktop
companion.  Pi's final build/reproducibility/lint and standalone/exact-ungrafted/
integrated native acceptance passed.  Squad passed final permission/native/
integrated/build/reproducibility/lint proof.  Bun and the companion passed all
final gates.  Slim's latest real plugin-host proof, final reproducibility/lint
and integrated rerun also passed.  Both Slim components are covered, and no
deployment is established.

- **Pi #112** packages the official earendil-works **0.84.2** executable
  (`x86_64-linux` only), with matching source at release tag `914cf147`.
  This approved pin correction selects the release ancestor four commits
  behind research revision `b1efcf7`; the old starred snapshot is preserved.
  It is the real upstream `pi` CLI/TUI, not an omp fork, and is a hash-pinned
  prebuilt executable **not rebuilt by Guix**.  Pi's MIT sources and 140
  dependency notices are retained from verified npm archives: 133 lockfile
  SHA512 records plus seven explicitly pinned registry integrity values for
  entries omitted by the lock.  Bundled Bun 1.3.14/JSC and linked notices have
  separate grants including LGPL; this is not a MIT-only executable claim.
  Bun's release ZIP contains only its executable, not a third-party notice
  bundle or relinking objects; retained source `LICENSE.md` links patched
  `oven-sh/webkit` and relinking instructions.  Source-notice preservation is
  not a complete independently audited static-link closure claim, for Pi's
  bundled runtime or Slim's separately selected Bun.
  After general ELF relocation exposed a child-execution SIGSEGV, the final
  Bun repair changes only its fixed-layout interpreter span without moving
  load/dynamic segment addresses.  Actual raw child re-execution and the
  plugin's `bun run` build and final Bun build/reproducibility/lint passed,
  as did the actual plugin-host proof.  Its glibc-only
  `LD_LIBRARY_PATH` is inherited by children and can affect owner-supplied
  native programs; no universal compatibility guarantee applies.
  Installed assets/themes/photon WASM/HTML export and clipboard support are
  retained; example extension dependency graphs are not installed.  Guix
  supplies Bash/coreutils/git/fd/ripgrep and Node LTS for optional npm extension
  installation, not as the Pi CLI runtime.  `PI_PACKAGE_DIR` points to the
  read-only installed assets; writable `PI_CODING_AGENT_DIR` defaults under
  XDG state.  Startup offline/version-check/telemetry defaults are disabled
  network features, not a sandbox: explicit `PI_OFFLINE=0/false/no`,
  `PI_SKIP_VERSION_CHECK=0/false/no` and `PI_TELEMETRY=1` opt in as appropriate,
  and normal provider calls still require owner-controlled credentials/network.
  The external `tests/pi-smoke.py` passed genuine local RPC Bash file/sum-42
  operations with configured shell prefix, session name/reset/switch/restart/
  history and decoded native HTML-export payload, plus actual PTY `/session`,
  `/hotkeys` and Ctrl-D exit under network-disabled isolation.
  No mock model or production proof switch is used; model listing alone is
  not that acceptance.  `PI_SMOKE_ARTIFACTS` selects a parent directory and
  each run retains a fresh child.
  The local catalog entry is metadata pointed at unreachable localhost, not
  a fake provider/server.  Provider inference, OAuth/network integrations,
  live-display clipboard and image resizing remain unexercised by this proof;
  retained runtime resources alone do not establish those capabilities.
  The final output
  `/gnu/store/gd6gxdg8n1gvlx9qlf2ddqgp1289c18p-pi-coding-agent-0.84.2`
  passed build/reproducibility/lint and the exact ungrafted native run at
  `/tmp/pi-native-ungrafted/pi-smoke-s6u9yq92`; integrated grafted proof passed
  at `/tmp/pi-native-final/pi-smoke-pl6t1ofi`.
- **Squad #95** packages the source-built MIT SDK/CLI **0.13.0** at
  `92ff24ef`, with native node-pty/Koffi compilation and official bundled
  sql.js SQLite WASM and Yoga WASM (the latter embedded as base64).
  The retained npm graph comprises 225 runtime and four build-only paths,
  217 unique archives, and 129 missing-origin records recovered from exact
  version metadata—not the research claim of 647 complete origins.  Original
  MIT/Apache/ISC/BSD and selected MIT-or-CC0 notices plus SQLite public-domain
  terms remain retained; exact upstream origins supplement omitted SDK/Yoga
  MIT texts.  `squad` preserves normal features/auth; `squad-node` exposes the
  packaged Node for SDK consumers.  `SQUAD_STANDALONE_HOME` selects installed
  `bin/squad`, so local initialization creates its state-MCP launcher without
  npm registry probes or npx runtime downloads.  Proprietary GitHub Copilot
  packages are excluded; real Copilot sessions require an explicitly supplied
  external `COPILOT_CLI_PATH`, user credentials and network access.
  `tests/squad-smoke.sh` passed standalone and integrated native proof:
  disposable real git initialization twice preserves user team/lead/routing
  changes, durable SDK SQLite changes survive fresh processes, and actual
  node-pty/Koffi local children run successfully.
  A real repeated-init failure traced to `fs.copyFile` propagating immutable
  store template mode 0444 into writable user `routing.md`, not a missing
  preset.  The source repair adds owner-write permission only to newly copied
  destinations.  Existing destination mode is captured before copying and
  restored afterward, since `fs.copyFile` itself otherwise overwrites it;
  authentication behavior is unchanged.  Final revised package/runtime proof
  passed; errors are not suppressed or replaced with synthetic results.
  The external consumer checks public asynchronous/synchronous copy APIs from
  a 0444 source: new destinations accept genuine append/read, overwriting an
  existing 0640 destination preserves its mode, and the source stays 0444.
  Native initialization also requires owner-writable `routing.md` and preserves
  an actual user comment through the second init.
  The final copy-mode, complete routing/casting, SQLite-WASM/PTY/FFI proof
  passed at `/tmp/squad-native-integrated`.  The recipe excludes nondeterministic
  Koffi CMake worktree logs while retaining the finished native addon; the
  final build/reproducibility/lint output is
  `/gnu/store/s1rp8ag2d382vy5xl5g3hxs981nxazxs-squad-0.13.0`.
  First init must assign every default agent to its role in the Work Type →
  Agent table and record all five active `preset:default` identities/full-team
  universe usage.  Repeat init must retain those identities and all prior
  assignment/usage history, rather than accepting only partially written team
  rows after an earlier hidden scaffold failure.
  The helper runs CLI/SDK/native children in an actual rootless private
  user/network namespace, compares host/child namespace identities and retains
  `network-isolation.json`; it fails if required namespaces are unavailable,
  without a provider fake or non-isolated fallback.  Native error output also
  fails the proof even if the CLI exits zero.  This is not proof of Copilot or
  model sessions.
  `SQUAD_EVIDENCE_DIR` retains bounded logs/reports in a fresh child; on
  failure it also preserves only the generated project and scratch-home
  presets under `failed-project`, never the host HOME, credentials or an
  environment dump.
- **Oh My OpenCode Slim #89** packages the MIT plugin **2.2.13** at
  `6faaed2`, with retained verified npm/native dependency notices and a
  separately pinned Bun runtime.  The npm closure has 341 source keys for
  326 versions; retained terms include MIT/MIT-0, Apache-2.0, ISC, BSD-2/3,
  CC-BY-4.0 (`caniuse-lite`), BlueOak-1.0.0, CC0 and MIT/Zlib (`pako`),
  selecting BSD-3 from AFL-2.1-or-BSD-3 where offered.  Official pinned native
  `.so`/AST artifacts are relocated against Guix libc/GCC; unsupported optional
  ARM-musl msgpackr code falls back to upstream's real JavaScript implementation,
  not a fabricated stub.  ast-grep CLI/Linux platform and msgpackr-extract
  Linux-x64 archives declare MIT but contain no separate license/notice text;
  supplied OpenTUI/Linux/WebGPU license files are retained.  Preservation of
  all supplied legal/README/package files is not independent verification of
  those native artifacts' complete third-party static-link legal closure.
  Ordinary `install` registers the immutable
  local store package, configuration, skills and TUI assets; ordinary
  `doctor --json` is real upstream behavior, not a fabricated smoke command.
  The actual installer passed creation of eight skills and selection of the
  immutable store companion, not a user-cache downloaded executable.
  `tests/oh-my-opencode-slim.sh` passed at
  `/tmp/slim-native-host-whichfix` against the **actual OpenCode host**:
  six agents, five tools, eight skills, default orchestrator, project-local
  override and real plugin-produced idle companion state, with zero prompts
  sent.  This is not a mock host/provider result.  The production `which`
  dependency now supports actual executable lookup in the pure host environment.
  Final reproducibility/lint and integrated `make check-oh-my-opencode-slim`
  also passed at `/tmp/slim-native-host-integrated`.
  The no-argument helper resolves the plugin, actual OpenCode and the actual
  companion store output; it does not substitute a user-cache installation.
  The helper requires actual OpenCode 1.18.18 `/agent`, tool-ID and `/config`
  APIs plus a created local session whose messages stay empty; no prompt is
  sent.  Plugin-generated idle state is required in the headless host helper;
  `DISPLAY`/`XAUTHORITY` are not propagated, and GUI proof is separate.
  After actual writable CLI installation, the helper bind-mounts only its own
  config/project `.opencode` directories read-only in private user/mount/net/
  IPC namespaces with loopback enabled.  The host's supported nonwritable
  path skips npm bootstrap; mounts thaw for restarts/project overrides/cleanup.
  Ordinary writable OpenCode directories may bootstrap `@opencode-ai/plugin`
  from the registry despite default plugins being disabled.  This is an
  offline read-only-host-config consumer mode, **not a general offline
  writable-config promise**, fake lock/cache or production behavior change.
  Normal filesystem/process/network authority remains;
  owner-controlled provider credentials/MCP services are not supplied.
  The separately installable **oh-my-opencode-slim-companion 0.1.3** is the
  official prebuilt GUI for `x86_64-linux`/`aarch64-linux`, not a Guix-rebuilt
  Rust closure.  Its binary workflow
  [27580998354](https://github.com/alvinunreal/oh-my-opencode-slim/actions/runs/27580998354)
  built source `5a4a81a`; release tag `04cdef5` changes CLI-only files and keeps
  the same companion source, while plugin `6faaed2` selects those artifacts.
  Exact build source/Cargo.lock/animations/workflow and MIT license are kept;
  the upstream executable-only archive lacks a separate third-party notice
  bundle, so preservation is **not an independently audited Rust license or
  reproducibility claim**.  Guix supplies its ELF loader/library closure.
  `tests/oh-my-opencode-slim-companion.sh` is intended to exercise the real GUI
  with disposable local state under private Xvfb/namespaces: actual native
  title, embedded JPG sprite-sheet animation pixels, Size S/M/L/XL menu
  choosing L geometry, config reload/project-label pixels and Close.  This
  GUI fixture explicitly simulates busy state; it is distinct from the host
  helper's real plugin-produced idle `intro` state, not proof of model work.
  Both the initial actual GUI proof at `/tmp/slim-companion-native-main` and
  the latest integrated proof at `/tmp/slim-companion-native-final` passed,
  along with final wrapper build/reproducibility/lint.  Inspection showed
  DESIGNER/EXPLORER and LOCAL-A rendered.  The actual screenshot is
  [slim-companion-native.png](.goocastle/evidence/slim-companion-native.png).
  This independent simulated-busy fixture remains distinct from the verified
  actual plugin-produced idle state; no theme/provider behavior is claimed.
  Its artifact directory must be absolute and empty.

Build/smoke commands for the verified paths, run serially with fresh evidence:

```sh
guix lint -L guix --no-network --exclude=cve,refresh,archival pi-coding-agent squad oh-my-opencode-slim oh-my-opencode-slim-companion
pi_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 pi-coding-agent)
squad_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 squad)
slim_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 oh-my-opencode-slim)
companion_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 oh-my-opencode-slim-companion)
guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 --check pi-coding-agent squad oh-my-opencode-slim oh-my-opencode-slim-companion
PI_SMOKE_ARTIFACTS=/tmp/pi-native-FRESH GUIX=guix python3 tests/pi-smoke.py "$pi_out"
SQUAD_EVIDENCE_DIR=/tmp/squad-native-FRESH GUIX=guix sh tests/squad-smoke.sh "$squad_out"
SLIM_ARTIFACTS=/tmp/slim-native-FRESH GUIX=guix bash tests/oh-my-opencode-slim.sh
OH_MY_OPENCODE_SLIM_COMPANION_SMOKE_ARTIFACTS=/tmp/slim-companion-FRESH GUIX=guix sh tests/oh-my-opencode-slim-companion.sh "$companion_out"
```

Historical ordinary contracts #739 (`doctor --json`), #740 (`init --preset
default`) and #741 (`--list-models`) remain because their invocations are valid.
Their markers/metadata alone do not establish the richer current acceptance.
No synthetic production contract was invented or retired for this batch.

## Aiwnios, Warp Rogue and Tower of Babel — verified native paths

These are source-built native compiler/game deliverables, not installed proof
hooks.  All four final outputs passed build, `--check` reproducibility, offline
lint without package diagnostics and genuine native/integrated acceptance.
Implementation and historical launch markers alone are not that proof; no
profile installation or deployed host change is established.

- **Aiwnios #86** exports `aiwnios` and `aiwnios-bytecode` version
  **0.9.0-0.e155e87** from canonical `aiwnios/Aiwnios` revision
  `e155e87a4a4ddae4cd7f25685d9db8869fd45a40`.  CMake builds the actual host
  compiler, then its compiler generates HCRT in a private writable boot drive.
  The output retains DolDoc desktop/editor/help/apps/demo resources with their
  original paths, and BSD-3/MIT/BSD-2/Tcl notices for Aiwnios, isocline and
  argtable3.  `aiwnios-bytecode` uses upstream `USE_BYTECODE=ON` instead of
  machine-code HolyC compilation; it is the same full host environment, not an
  independent bootable kernel, ISO or Emscripten/WebAssembly deliverable.
  The recipe zero-initializes AOT allocations and extends the patch-table tail
  clearing from 16 to 31 bytes, removing 15 uninitialized heap bytes from the
  generated binary.  Debug-map allocation also uses `CAlloc`, giving missing
  bytecode instruction lines deterministic zero values.  HolyC AOT copies
  rounded 64-bit words, but upstream bytecode allocation reserved only logical
  length; the source fix zero-allocates `(len+7)&~7` bytes without changing
  reported logical size or relaxing repeated-bootstrap equality assertions.
  Final build/`--check`/lint/native/integrated acceptance passed for
  `/gnu/store/dsikyxzszrd7sk2w252rl5na1xi3mzqm-aiwnios-0.9.0-0.e155e87` and
  `/gnu/store/apzj0v2zhf6fdiypxfzda02sxha8mxy5-aiwnios-bytecode-0.9.0-0.e155e87`.
  Explicit `HOME` is respected, while
  `-t` still selects an explicit writable boot drive.  Resources in
  `share/aiwnios` are an immutable template, not writable runtime state.
  `-c` consumes HolyC file paths through that drive's virtual filesystem;
  arbitrary host `/tmp` paths are not implicitly staged into it.
  Untrusted HolyC has the user's host authority: the application is not a
  sandbox.  Main attempted serial no-graft cross builds for
  `aarch64-linux-gnu` and `riscv64-linux-gnu`; both stopped before compiler build
  at `gnu/packages/python-build.scm:678:2`: `python-setuptools@80.9.0` uses a
  pyproject build system without cross-build support.  Thus neither target
  build nor runtime is verified.  The package's later HCRT bootstrap also
  executes the target compiler, so cross support is not established by the
  retained native aarch64/riscv64 assembly paths.
  `tests/aiwnios-smoke.sh` passed both final backends at
  `/tmp/aiwnios-native-final` and `/tmp/aiwnios-bytecode-final`: actual HolyC
  arithmetic (42), loop (55), branch (-7/3/42), recursion (720), exact exit
  status 23 and repeated bootstrap equal HCRT binary digests.  Both SDL
  desktop consumers typed a real function/loop computing 42 and called native
  `FileWrite` for `/GUI_RESULT.TXT`; Main visually read both final computation
  PNGs with no errors.  Panels overlap/slightly clip at the edge, but result
  42 remains legible.  Clean exit status 0 and unchanged output NAR passed.
  Before/computation screenshots and result/NAR logs are retained.
  It accepts no arguments or one realized package output, honors `GUIX`, and
  retains evidence under `AIWNIOS_SMOKE_ARTIFACTS`.
- **Warp Rogue #583** exports `wrogue` **0.8.0** from recovered original source
  `anthonycicc/warp_rogue` revision
  `675bb5db48434469582367c420b907b129bd6543`, not the later Mac-only SDL2 port.
  Its actual C game is built from source with the channel's SDL 1.2 compatibility
  backend.  The complete original scenario, scripts, bitmap font, graphics,
  help and credits remain immutable in `share/wrogue/data`; the launcher sets
  the resource working directory, and upstream writes saves/settings only to
  `$HOME/.wrogue`.  Root GPLv3 terms cover code/media; the separate bundled
  MT19937 BSD-3 notice is retained as `share/doc/wrogue/third-party/tt.c`.
  [LibreGameWiki](https://libregamewiki.org/Warp_Rogue), retrieved 2026-10-03,
  identifies this recovery of the 0.8.0 source and GPL code/media, not a live
  original maintainer.  No separately fetched assets/submodules are used.
  Main's build and `--check` reproducibility passed for
  `/gnu/store/laqal2zgj44r4h216ig9nwvjbvsbzrsj-wrogue-0.8.0`; offline lint
  reported no package diagnostics.  Standalone/integrated native acceptance passed.  No platform
  prebuilt or synthetic `wrogue-smoke` executable is installed.  Upstream is
  defunct and provides no automated test target.
  `tests/wrogue-smoke.sh` passed actual GUI character creation, save,
  fresh-process Continue restoration, movement and repeated save/load at
  `/tmp/wrogue-proof-headerfix`: player `NativeConsumer`, Hive Cruor world
  `(7,6,34)`/local `(30,104)` restored exactly; key `6` moved to `(30,105)`,
  and a second save/restore preserved that location.  The native named-gameplay
  screenshot was visually inspected; clean exit status 0 and unchanged NAR passed.
  It decodes the game's bitmap font and asserts actual native C-record player
  identity, world and location, with before/after output NAR and stage PNGs/
  `evidence.json`.  Fresh HOME/XDG/private tmp/network/PID isolation is external;
  no installed proof hook or fake OCR replaces the game.  The integrated
  `make check-wrogue` passed at `/tmp/wrogue-native-integrated`.
  It takes no arguments, honors `GUIX`,
  accepts `WROGUE_OUTPUT` as a realized game override and
  `WROGUE_EVIDENCE_DIR` for retained screenshots/JSON.  Its disposable HOME/XDG
  setup does not change upstream's HOME-based state convention.
- **Tower of Babel #561** exports `babel7drl` **2019-03-09** from Jeff Lait's
  fixed `http://www.zincland.com/7drl/babel/babel7drl.zip` source release,
  SHA-256 `ce482e9f9b04efbff95e395a745366cc962ca71536d5bc5d9bd23f6b049424e1`.
  Both game and private libtcod 1.5 C/C++ archive are built from source; Python 2
  runs only the build-time enum generator.  Bundled platform executables/shared
  libraries, demos and music are not installed.  SDL12-compat is the current
  backend, not an assertion that historical bundled SDL libraries are used.
  Game/libtcod/MT19937 BSD-3 notices, public-domain map terms, names/text source
  acknowledgements and Oxygen Mono SIL OFL 1.1 are retained.  The launcher uses
  `$XDG_DATA_HOME/babel7drl` or `$HOME/.local/share/babel7drl` for writable config
  and runtime layout; maps/names/text/font remain immutable links.
  The released source disables the normal shutdown save producer and definition
  persistence.  Loader code exists, but **no supported save/resume claim applies**.
  Its fictional terminal/servers are local UI, not remote services.  Upstream
  provides no automated test target.
  Main's build, `--check` reproducibility and offline lint passed without
  package diagnostics.  `tests/babel7drl-smoke.sh` passed at
  `/tmp/babel7drl-native-healthfix`: default native login/help, real key `l`
  movement delta `[1,0]`, actual action reducing health from 50 to 2, then
  native death/reconnect to `Restarted` at depth 1.  Supported caller
  `easymode=true` provides deterministic controls, not a replacement game.
  Main visually verified the restart-initial PNG; clean exit, state and
  unchanged NAR passed.  Climb-attempt feedback is covered, but floor
  descent/advancement, combat and boss victory are not exercised.
  Restart verifies new-game UI, not save persistence.
  The helper requires actual user/mount/net/PID isolation, Xvfb and a
  before/after immutable NAR match, not a terminal mock.
  It takes no arguments and honors `GUIX`; `BABEL7DRL_NATIVE_STORE` skips game
  realization, and absolute `BABEL7DRL_NATIVE_OUTPUT` retains screenshots/logs/
  decoded surfaces/proof JSON.  Integrated `make check-babel7drl` also passed
  at `/tmp/babel7drl-native-integrated`.

Commands for the verified paths, run serially with fresh evidence directories:

```sh
guix lint -L guix --no-network --exclude=cve,refresh,archival aiwnios aiwnios-bytecode wrogue babel7drl
aiwnios_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 aiwnios)
aiwnios_bytecode_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 aiwnios-bytecode)
wrogue_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 wrogue)
babel_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 babel7drl)
guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 --check aiwnios aiwnios-bytecode wrogue babel7drl
AIWNIOS_SMOKE_ARTIFACTS=/tmp/aiwnios-native-FRESH GUIX=guix sh tests/aiwnios-smoke.sh "$aiwnios_out"
AIWNIOS_SMOKE_ARTIFACTS=/tmp/aiwnios-bytecode-native-FRESH GUIX=guix sh tests/aiwnios-smoke.sh "$aiwnios_bytecode_out"
WROGUE_EVIDENCE_DIR=/tmp/wrogue-native-FRESH WROGUE_OUTPUT="$wrogue_out" GUIX=guix sh tests/wrogue-smoke.sh
BABEL7DRL_NATIVE_OUTPUT=/tmp/babel-native-FRESH BABEL7DRL_NATIVE_STORE="$babel_out" GUIX=guix sh tests/babel7drl-smoke.sh
```

Historical #731 native no-argument launch and #738 ordinary `-c` invocation
remain; their title/fixture markers do not prove current gameplay/desktop proof,
and the static Aiwnios `/tmp` fixture requires proper virtual-drive staging.
The exact #734 contract was retired because it named the wrong upstream module
and a nonexistent installed `wrogue-smoke`; no fake replacement was added.

## The Smith's Hand, Tetraworld and SpliceHack Rewrite — verified native paths

These three packages implement actual independently playable games from pinned
source, not synthetic smoke launchers.  All three passed final build,
reproducibility, offline lint and genuine native/integrated consumer proof;
Tetraworld also passed 27-module upstream unit tests.  No deployment or
installation in a user profile is established.

- **The Smith's Hand #553** exports `the-smiths-hand` **2014-03-16** in
  `(tay packages smiths-hand)`, from canonical
  `http://www.zincland.com/7drl/smith/smith7drl.zip`, SHA-256
  `a245e26b305d1ff9ec25bcc87635d4e8000f167e2563b5e269a3ed0c19e2adee`.
  The real `bin/smith` no-argument SDL GUI and private libtcod 1.5.0 archive
  are compiled from source; SDL12-compat/PNG/zlib are Guix runtime dependencies.
  Original game/libtcod/MT19937 BSD-3 terms and public-domain map/terminal font
  notices are retained.  No platform binary, demo assets or music is installed.
  Upstream disables `USE_AUDIO`, so inactive SDL_mixer calls do not require a
  mixer dependency.  Defaults are windowed with music off; original text/maps/
  font remain store assets.  Writable config and actual `linux/smith.sav` live
  under `$XDG_DATA_HOME/the-smiths-hand` or
  `$HOME/.local/share/the-smiths-hand`; the launcher selects the native Linux
  working directory, not a substitute game.  Upstream has no test target.
  Main's build/`--check`/offline lint passed for
  `/gnu/store/i9g31ljams71dkx1d0w3y52cl9vzsmpm-the-smiths-hand-2014-03-16`;
  `tests/smiths-hand-smoke.sh` passed actual X11 gameplay, `Q` save and a fresh
  consumed-save reload at `/tmp/smiths-hand-native-parserfix`: genuine wait
  time 2, orcs 51, whole-save byte equality, exact avatar inventory/topology,
  unchanged state and output NAR.  Main visually read restored.png's native
  map and Smith inventory (Hammer, Clothes, Copper knife, Copper ringmail,
  3 Iron ingots).  This is external isolation/native state, not a proof hook.
  The retained actual surface is
  [smiths-hand-native.png](.goocastle/evidence/smiths-hand-native.png).
  Integrated `make check-smiths-hand` also passed at
  `/tmp/smiths-hand-native-integrated`.  It honors `GUIX`, accepts
  an optional realized output, and retains evidence in absolute
  `SMITHS_HAND_SMOKE_ARTIFACTS`.
- **Tetraworld #543** exports `tetraworld` **0-unstable-20210406** from
  `blargdag/tetraworld` commit `14f5ca8265db8be91266922ea1718579d1481d68`, plus
  independently pinned `adamdruppe/arsd` commit
  `d5c35392931925ca75fe3a399de6c254b57673b0`, matching the parent's exact
  mode-160000 gitlink.  LDC/SCons compile both native
  console and software-rendered graphical backends.  Game/prefab data are
  embedded; upstream release binaries and upload/SCP utilities are excluded.
  Parent GPL-2-or-later and arsd Boost 1.0 notices are installed under
  `share/doc/tetraworld`, including `arsd/LICENSE`, `NOTICE` and complete Boost
  license.  There are no separately fetched runtime media.  Actual upstream
  options and `USER.save` remain under `$HOME/.tetraworld`, with no runtime
  wrapper or special proof flag.  The recipe uses LDC runtime's actual
  test-only mode for upstream D unit tests.  Final repaired build, `--check`,
  offline lint and 27-module tests passed for
  `/gnu/store/vbzx7735m0p1lagnglkw47a8nk4xwamy-tetraworld-0-unstable-20210406`.
  Dynamic X library names resolve to Guix paths rather than ambient
  `LD_LIBRARY_PATH`.  Strict native-state equality exposed an upstream
  restored-agent defect: early `return` in special-agent registration skipped
  clearing newly pending agents.  Changing that unique return to `continue`
  preserves new agents and the clear list, without normalizing saved data or
  relaxing equality.  `tests/tetraworld-smoke.sh` passed at
  `/tmp/tetraworld-native-restorefix`: four actual console sessions, complete
  native saves 1=2 and 3=4 byte/hash-equal, player 1056 at `[0 0 0 0]`, turns
  1/1/2/2, actual `p` turn/`q` exit and consumed saves with `Welcome back`.
  Main observed the real loaded map screenshot; HUD health 5/5 and air 8/8
  matched the native record.  Integrated `make check-tetraworld` also passed
  at `/tmp/tetraworld-native-integrated`; the final helper rerun also passed
  at `/tmp/tetraworld-native-final`, retaining post-exit `proof/options.native`
  with actual `options { smoothscrollMsec 0 }` content.
  The retained real loaded-game surface is
  [tetraworld-native.png](.goocastle/evidence/tetraworld-native.png).
  Restored HUD health/air must match native player `mortal.curStats`, not
  just a screenshot; the actual player glyph is `&`, distinct from portal `@`.
  A real Xvfb/xterm/ImageMagick loaded-game screenshot is not a fabricated renderer.
  External user/network/PID isolation and unchanged NAR are required.  The
  helper honors `GUIX`, accepts one optional realized output, and requires
  `TETRAWORLD_EVIDENCE_DIR` to be new/empty; receipt/screens/native saves/raw
  session evidence and actual `options.native` are retained.
- **SpliceHack Rewrite #524** exports `splicehack-rewrite` **0.8.2-0.0cf23cb**
  from `RojjaCebolla/SpliceHack-Rewrite` commit
  `0cf23cb19eedd6b985502b1b8fdc86fd249a8172`.  Its tty-only NetHack 3.7 rewrite
  embeds separately fixed official Lua **5.4.2**, SHA-256
  `11570d97e9d7303c0a59567ed1ac7c648340cd0db10d5fd594c09223ef2f524f`;
  upstream fetch targets are disabled for offline build.  NGPL game/data,
  Lua MIT and ISAAC64 CC0 notices are retained with actual `nhdat`, `license`,
  symbols, README, Guidebook, `isaac64.c`, Lua README, `spl-sources.txt` and
  `spl-changelog.txt`.  No tiles, sounds, PDCurses or optional Windows port is
  installed.  Immutable store `HACKDIR` is separate from patched
  `VAR_PLAYGROUND`: saves/bones/scores/locks/logs use
  `$XDG_DATA_HOME/splicehack-rewrite`, while config HOME uses
  `$XDG_CONFIG_HOME/splicehack-rewrite` (normal HOME defaults apply).
  No installed `--guix-smoke` mode exists.  Upstream Lua tests require game
  bindings, and its pinned libnh renderer callbacks are unfinished rather than
  a runnable harness; **no upstream suite pass is claimed**.
  Ten stale bundled symbol rows absent from the actual game vocabulary are
  removed; unknown-keyword diagnostics remain intact rather than suppressed.
  The recipe includes 11 missing rewrite dungeon Lua entries in
  `SPEC_LEVS` rather than relying on generic-maze fallback, installs the actual
  generated Guidebook, and guards native HOME's 128-byte limit.  Final
  build/`--check`/offline lint and integrated native acceptance passed at
  `/gnu/store/15b62h1570mlll5phb6hzqk78gvm17pa-splicehack-rewrite-0.8.2-0.0cf23cb`.
  Final `make check-splicehack-rewrite` passed at
  `/tmp/splicehack-rewrite-native-final`: three native games, safe real movement,
  two strict exact HUD/map/cursor/stats/HP/turn/inventory restores and consumed
  native saves.  Read-only store, unchanged host state and unchanged NAR
  `1r9lk8mapz02aifnxg4b5ifpa4gl4dqmys9jjflh9s0cs5zf80x1` passed.  Main
  visually read the final restored.png map: OmpProof Stripling, HP16/16,
  Dlvl1, T3, no errors or gameplay clipping.  Native saves/raw evidence and
  the actual live xterm/Xvfb PNG remain external artifacts; Python/pyte/X11
  tools are not production inputs.  Namespaces fail closed.  The retained
  final actual surface is
  [splicehack-rewrite-native.png](.goocastle/evidence/splicehack-rewrite-native.png).
  It honors `GUIX`, accepts an optional realized output plus
  `--output fresh-directory`, or
  `SPLICEHACK_REWRITE_EVIDENCE_DIRECTORY`.

Commands for the verified paths, run serially with fresh evidence directories:

```sh
guix lint -L guix --no-network --exclude=cve,refresh,archival the-smiths-hand tetraworld splicehack-rewrite
smith_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 the-smiths-hand)
tetra_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 tetraworld)
splice_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 splicehack-rewrite)
guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 --check the-smiths-hand tetraworld splicehack-rewrite
SMITHS_HAND_SMOKE_ARTIFACTS=/tmp/smiths-hand-native-FRESH GUIX=guix sh tests/smiths-hand-smoke.sh "$smith_out"
TETRAWORLD_EVIDENCE_DIR=/tmp/tetraworld-native-FRESH GUIX=guix sh tests/tetraworld-smoke.sh "$tetra_out"
GUIX=guix sh tests/splicehack-rewrite-smoke.sh "$splice_out" --output /tmp/splicehack-rewrite-native-FRESH
```

Only the exact synthetic production contracts #730 (`--goocastle-smoke`),
#727/#723 (`--guix-smoke`) were retired.  Genuine external native consumers
supersede them; no Goocastle executor, installed hook or fake replacement was
created or executed.

## Space Privateers, SLASH'EM and Shamogu — verified native paths

These deliveries use source-built games and external `tests/*` native consumers,
not installed proof modes.  All three passed final build/reproducibility,
offline lint and genuine native/integrated acceptance, including their stated
upstream test scopes.  No deployed host/profile change is established.

- **Space Privateers #521** exports `space-privateers` **0.1.0.0** in
  `(tay packages space-privateers)`, using the exact Hackage release archive
  `SpacePrivateers-0.1.0.0.tar.gz`, SHA-256
  `70e6061caa2b7eed8be2d120ba165365e008c37a510290c8f89b926d6702473e`,
  not the later canonical master revision `fbe2ecec`.  GHC 8.0 builds a private
  pinned Hackage closure with LambdaHack **0.2.14** and original Vty **4.7.5**;
  no GTK frontend, game-side test adapter or registry resolution is installed.
  Original BSD-3 game/engine LICENSE/CREDITS and every statically linked
  private-library notice accompany the executable (BSD-3, BSD-2 `text`, and
  Expat `pretty-show`/`haskell-lexer`/`base-orphans`), together with original
  license files from the pinned GHC 8.0 compiler/boot-library source.  Narrow
  compiler metadata compatibility repairs retain original deepseq 1.3 Config
  `rnf` semantics.  Cabal 1.24.2.0 uses its supported `--enable-library-vanilla`
  configure flag rather than modern Guix's unsupported `--enable-static`,
  retaining shared libraries/static executable linking and other standard
  configure semantics.  `miniutter`'s duplicate `Binary Text` orphan and unused
  import are removed in favor of `text`'s equivalent valid UTF-8 ByteString
  encoding; save wire format is unchanged (malformed UTF-8 fails decoding).
  The removed vector `Fusion.Stream` API migrates to `Fusion.Bundle` with
  `indexed`/`foldl1'`, retaining strict left-fold/last-equal tie selection
  without materializing another vector.
  Explicit `Data.Vector.Binary ()` imports the existing pinned serializer for
  Overlay's unboxed vector, preserving its size/ordered-element wire format;
  no custom serialization instance is introduced.
  Item weight phrases use the native `miniutter` no-space `MU.:>` constructor
  instead of a nonexistent `Part` Monoid, retaining intended `10g`/`1.5kg` display.
  No gameplay/save instrumentation is added.  The launcher only
  executes upstream `SpacePrivateers`, preserving native `~/.SpacePrivateers`
  configuration, scores and compressed campaign saves.  Engine offline
  `frontendNull` tests are enabled; the game has no Cabal test stanza.
  `tests/space-privateers-smoke.sh [output]` honors `GUIX` and absolute
  `SPACE_PRIVATEERS_SMOKE_ARTIFACTS`.  Its ordinary Vty/xterm consumer runs
  inside offline user/mount/network/PID isolation.  Final build/reproducibility/
  offline lint passed at
  `/gnu/store/74rxy84i4dn3fv9r2b0fk7cfzp45xxk4-space-privateers-0.1.0.0`,
  with the engine's upstream suite passing 1/1.  Standalone native proof passed
  at `/tmp/space-privateers-native-clockfix`; integrated `make check-space-privateers`
  passed at `/tmp/space-privateers-native-final`.  Genuine wait and bounded
  adjacent moves strictly advanced native global/local time; two restores
  exactly matched leader/map/arena/status/target/diary/equipment/inventory.
  Processes exited 0 and output NAR remained
  `08244j3vp4ax21g0ijccy3j0m6kizpy2gk34kzrsd8gnvs7l0rkc`.  Native server/UI
  compressed saves are retained and checked for complete zlib streams, but
  **hidden Haskell state is not fully decoded**: continuity proof is the exact
  native visible fields/diary, not an assertion about all RNG or hidden state.
  Main visually read the actual continued map: General quarters 1, 8% seen,
  HP20/40, Calm60/60, no errors.  The final retained surface is
  [space-privateers-native.png](.goocastle/evidence/space-privateers-native.png).
- **SLASH'EM #515** exports `slashem` **0.0.8E0F2-0.aae9ef2** in
  `(tay packages slashem)`, from the Hardfought `k21971/SlashEM` revision
  `aae9ef2e4c2e5b591a3bc5ded888bab1e157b20b` (2024-02-10; no release tags).
  The fixed archive SHA-256 is
  `e48961ee54ad8b02b0e9859d17a4c895fad75bb5a0b3558d3b88b14f18279907`;
  its actual Guix base32 is
  `01wr4wc4zcc87f6mbcx0nmdxgylmr2j1g7c5x6q052xdakp632g4`, correcting the
  research ticket's erroneous encoding.  NGPL notices, corresponding native
  tty source, dated changes and Guidebook accompany complete native `nhshare`
  and `nhushare` archives.  Optional sounds/fonts/tiles/GUI ports are absent.
  Exact-count, dated source repairs fix missing declarations/terminal-color
  arity, dump glyph blank-byte fallback, vanquished-list return semantics,
  artifact output storage width, technique parameter type and parser anonymous
  typedef.  Native ncurses/tinfo probes and link order use real `-ltinfo`;
  compression uses absolute store gzip, not the configure fallback `:`.
  `make all` generates complete archives with all native `dat/*.lev`; build
  time is pinned to epoch 1707587348 UTC.  GNU C11/`-fcommon` adds no warning
  suppression.  Corresponding tty source/generated headers and original notices
  accompany the dated change record.
  Immutable data is separate from private
  `${XDG_DATA_HOME:-$HOME/.local/share}/slashem` saves/bones/locks/scores/logs/
  dumps; `${XDG_CONFIG_HOME:-$HOME/.config}/slashem` provides configuration
  through private HOME, validating the native 128-byte environment-path limit.
  No upstream runnable suite/check target exists.
  `tests/slashem-smoke.sh` honors `GUIX`, accepts an optional store output and
  `--output fresh-directory` or `SLASHEM_EVIDENCE_DIRECTORY`.  Its external
  consumer targets ordinary Valkyrie games, real safe floor movement, two
  exact native save restores and live xterm screenshots with fail-closed
  current-user/keep-caps user/mount/network/PID isolation and unchanged NAR.
  Main's final build/reproducibility/offline lint passed at
  `/gnu/store/sscy6f42b3ga9bx9vgb8y9x3ncvdhzj7-slashem-0.0.8E0F2-0.aae9ef2`.
  Final `make check-slashem` passed at `/tmp/slashem-native-final`: three actual
  sessions, two exact restores, read-only output and unchanged NAR.  Main
  visually read HP16/16, Dlvl1, T3 on the actual map without errors.
  The final retained surface is
  [slashem-native.png](.goocastle/evidence/slashem-native.png).
- **Shamogu #508** exports `shamogu` **1.5.0** in `(tay packages shamogu)`,
  a material update over official Guix's 1.4.1 observed by its owner on
  2026-10-03.  Canonical `codeberg.org/anaseto/shamogu` revision
  `fcd439d4d7949dfa4b9d7e513caacc0a82360384` agrees with stable v1.5.0;
  archive SHA-256 is
  `ae08d808fab9c02e97805467c5ee34fac7f6fe6bb8836f36859b95c374e96a5f`.
  Go 1.25 builds the actual ASCII terminal game offline with twelve exact
  `go.mod` module versions, no CGO/SDL/browser frontend.  ISC game and closure
  ISC/Apache-2.0/Expat/BSD-3 notices, nested SDL-driver notices and Go PATENTS
  are retained.  The JS/SDL-only `images.go` is excluded: generated Source
  Code Pro letters/fonts/PNG assets are not linked or installed in this
  terminal build; tile LICENSE/README remain as notices, not runtime media.
  Native saves/config/replays/logs/dump use `XDG_DATA_HOME/shamogu`.
  `tests/shamogu-smoke.sh [output]` honors `GUIX` and new/empty
  `SHAMOGU_EVIDENCE_DIR`;
  its external PTY consumer requires native turns/save/exact restore, a real
  xterm PNG, offline namespaces and unchanged output NAR before success.
  The stdlib-only external Go decoder compares exported native Game state,
  including terrain/FOV/path payloads and stats/logs; native unexported UI,
  RNG/runtime state and separate configuration are not serialized proof.
  Terminal characters and rendition are compared independently.
  Main's final build, upstream `TestGame`, reproducibility and offline lint
  passed at `/gnu/store/5v2c3b2manka9df0i8vvx556p6iwibw7-shamogu-1.5.0`.
  Final `make check-shamogu` passed at `/tmp/shamogu-native-final`: five save
  sessions with turns 0/1/1/2/2, two full exported Gob-state and map/HUD-
  rendition restores, followed by native Q/Y deleting its save.  Main visually
  read the actual populated live map at L1, T2, HP9/9, without errors.
  The retained final surface is
  [shamogu-native.png](.goocastle/evidence/shamogu-native.png).

The invalid production `--guix-smoke` contracts #719/#721/#722 were retired rather
than replacing ordinary game executables with synthetic proof hooks.  No
Goocastle executor runs as part of these external consumers.

Serial commands for the verified paths (evidence directories must be fresh):

```sh
guix lint -L guix --no-network --exclude=cve,refresh,archival space-privateers slashem shamogu
privateers_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 space-privateers)
slashem_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 slashem)
shamogu_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 shamogu)
guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 --check space-privateers slashem shamogu
SPACE_PRIVATEERS_SMOKE_ARTIFACTS=/tmp/space-privateers-native-FRESH GUIX=guix sh tests/space-privateers-smoke.sh "$privateers_out"
GUIX=guix sh tests/slashem-smoke.sh "$slashem_out" --output /tmp/slashem-native-FRESH
SHAMOGU_EVIDENCE_DIR=/tmp/shamogu-native-FRESH GUIX=guix sh tests/shamogu-smoke.sh "$shamogu_out"
```

## Revengate, Please the Island God and Obumbrata — verified native paths

These recipes install actual source-built games, not synthetic smoke modes.
All three passed final build/reproducibility/offline lint and genuine native/
integrated acceptance.  Plomrogue passed its unchanged original oracle and exact
continuation; Revengate passed the real combat simulations and clean native
lifecycle.  No deployed host/profile change is established.

- **Revengate #486** exports `revengate` **0.13.0** in `(tay packages revengate)`,
  official GitLab `ygingras/revengate` stable pin
  `21b0cb49a84a1fada7e171064b68f1183818c32c`, recursive source hash
  `0yqjav3ihbqhva1zf5qw16577khhys8b927v0bbysm8zqskn7cj7`.
  Guix Godot 4.6 imports the project with the actual editor translation-parser
  4.3-to-4.6 API adaptation.  Initial import avoids a theme referencing fonts
  not yet imported, then restores the theme for validated normal import.
  Import and actual combat-scene checks reject `ERROR`/`SCRIPT ERROR` even when
  Godot exits 0; editor updater/plugin output is disabled.  The launcher uses
  immutable `share/revengate` via ordinary
  `--path` and forwards native Godot arguments.  Native `user://` state uses
  `XDG_DATA_HOME/Revengate`, saves under `saves/current`.  Full source, CREDITS,
  COPYING and vendor/legal docs retain GPL-3+ code/fonts, Expat, CC0/public
  domain, CC-BY-3/4 and artists' CC-BY/CC-BY-SA grants with unspecified versions
  where upstream does not specify them; no invented CC version is assigned.
  `docs/legal` contains verbatim artist email grants, not CC legalcode texts.
  Symbola's actual free-use/modification/redistribution grant is retained.
  `tests/revengate-smoke.sh [absolute-output]` honors `GUIX` and absolute
  `REVENGATE_SMOKE_ARTIFACTS`; its external X11 consumer requires actual game
  play, save and restart/resume with live screenshots.  The legitimate upstream
  `combat_sim.tscn` remains historical scene data, not full native proof.
  `revengate-node-ownership.patch` attaches the default deck builder and Main's
  limbo to their owning tree, frees detached HUD buttons and frees highlight
  template nodes after `PackedScene.pack` while retaining rendered TileMap
  instances/resources.  These actual ownership fixes remove the 21 leaked
  Area2D and 11 orphan highlight templates; no error gate is weakened or hidden.
  Main's final build/import/reproducibility/offline lint passed at
  `/gnu/store/97fsb3r50jlhj7np21h9rr7zqlccka2d-revengate-0.13.0`, including
  the actual three 1000-game upstream combat simulations.  Final integrated
  native proof passed at `/tmp/revengate-native-final-owned`: ordinary NewGame,
  real movement/save/process restart/Resume/continued movement, both native
  ExitGame processes exiting 0, no engine errors/leaks, and unchanged NAR
  `0aryx5n60jsk2ccakjlq5a2n775c05n94njf93ncz5zwkmhimmnr`.
  Restore proof compares saved queue turn, active/start board IDs, terrain and
  Hero position; returning to the menu completes the interrupted native turn.
  It does **not** establish full RNG/all-hidden-state equality.  Main visually
  read the actual map with Health50 and no errors; original debug buttons were
  visible but not used.  The final retained surface is
  [revengate-native.png](.goocastle/evidence/revengate-native.png).
- **Please the Island God #471** exports `plomrogue` **0-1.20170821** in
  `(tay packages plomrogue)`, canonical `plomlompom/plomrogue` PtIG tag pin
  `32c8b0d55c091b10ba683621d7881ef57ce8a88a`, recursive source hash
  `0inw5ddi33gb4pm26bygnnjd22xbbjjpv291l957xjl6hxdr7aw5`.
  GPL-3+ source/data and NOTICE/GPLv3 accompany the C11 source-built engine
  library and original Python client/server.  The launcher forwards native
  arguments, symlinks immutable resources into writable
  `${XDG_STATE_HOME:-$HOME/.local/state}/plomrogue`; native saves, record, log
  and `server_run` stay local.  `tests/plomrogue-smoke.sh [output]` honors
  `GUIX` and new/empty `PLOMROGUE_EVIDENCE_DIR`, requiring real ordinary client/
  server turns, native saves/exact restarts, live screenshot and offline/NAR
  isolation.  Main reproduced implicit mutable Thing-iteration order causing
  both the original oracle mismatch and native uninterrupted90 versus
  45/native QUIT-save/restart/45 serialized-state/RNG divergence.  Canonical
  sorted Thing-ID iteration across simulation/same-cell/memory/metamap now
  matches native save serialization while retaining the turn-start snapshot.
  Main's final build/reproducibility/offline lint passed at
  `/gnu/store/qmcl142galgpc1sznh49fr0glqhx5218-plomrogue-0-1.20170821`,
  including byte-exact `cmp` against the original immutable `testing/ref_end`.
  The strict oracle remains unchanged: no fixture regeneration, stale-fixture
  waiver or behavior reversion.  Final `make check-plomrogue` passed at
  `/tmp/plomrogue-native-final`: original oracle and uninterrupted90 versus
  45/native-save/reload/45 full save/RNG matched exactly, together with two
  exact full-save/UI restores after real movement and later wait.  Main
  visually read the actual map at T4, H30, inventory none, without errors.
  The final surface is [plomrogue-native.png](.goocastle/evidence/plomrogue-native.png).
- **Obumbrata et Velata #463** exports `obumbrata` **1.0.0** in
  `(tay packages obumbrata)`, official HTTP `obumbrata_1.0.0.tar.gz`, SHA-256
  `253d6250d2378fe91f15ea92ef9c9ad5c7f967bada7778ee8955bb2c8eacac47`, stable
  tag `c2f5361f63deeed1c7415f742dfa83f90d0ce699`, not the unreleased bugfix tip.
  Native ncurses/panelw/libxdg and Perl-generated project data retain BSD-2
  COPYING/notes/manual, with no separate font/tile/audio assets.  Build repairs
  add a missing flag separator/owning standard headers and use real Guix wide
  curses headers; control-character classification rejects negative/special
  curses keys outside ASCII.  No game prompt behavior patch is introduced.
  Native S/name/D saving returns to the menu; R loads and unlinks the successful
  save at `${XDG_DATA_HOME:-$HOME/.local/share}/com.blackswordsonics/obumbrata/obumbrata.sav`.
  Configuration directories follow XDG but upstream implements no configuration
  content.  Native `@` dumps to cwd, so the consumer isolates cwd too.  The
  TERMINFO-only launcher executes the ordinary game, not a proof dispatcher.
  `tests/obumbrata-smoke.sh [output] [--output fresh-directory]` honors `GUIX`
  and `OBUMBRATA_EVIDENCE_DIRECTORY`; the screen-driven consumer requires actual
  moves, native saving, two exact restores/live screenshots and unchanged NAR.
  Persisted native bytes/state and live screens are compared, but upstream does
  not serialize RNG: no complete runtime RNG continuity is claimed.
  Main's final build/reproducibility/offline lint passed at
  `/gnu/store/dijgr9ia31x7279ry1n1kdz0qyy3wqkq-obumbrata-1.0.0`.
  Final `make check-obumbrata` passed at `/tmp/obumbrata-native-final` with
  two exact native restores and unchanged NAR.  Main's retained actual
  restored surface shows OmpProof, HP20/20, Food1998, Depth1, Exp1/0 and
  “Game successfully restored”, without errors:
  [obumbrata-native.png](.goocastle/evidence/obumbrata-native.png).

Only exact installed custom `--smoke` contracts #712/#711 were retired.
Legitimate #716 upstream headless combat-scene invocation remains historical;
no Goocastle executor or fake replacement is run.

Serial commands for the verified paths (fresh evidence directories):

```sh
guix lint -L guix --no-network --exclude=cve,refresh,archival revengate plomrogue obumbrata
revengate_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 revengate)
plomrogue_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 plomrogue)
obumbrata_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 obumbrata)
guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 --check revengate plomrogue obumbrata
REVENGATE_SMOKE_ARTIFACTS=/tmp/revengate-native-FRESH GUIX=guix sh tests/revengate-smoke.sh "$revengate_out"
PLOMROGUE_EVIDENCE_DIR=/tmp/plomrogue-native-FRESH GUIX=guix sh tests/plomrogue-smoke.sh "$plomrogue_out"
GUIX=guix sh tests/obumbrata-smoke.sh "$obumbrata_out" --output /tmp/obumbrata-native-FRESH
```

## LambdaHack, Kimchi and KeeperRL — verified native paths

These ordinary source-built games passed final serial build/reproducibility/
offline lint/upstream/native/integrated gates.  Proof stays in external
`tests/*` consumers; repository packaging establishes no deployed host/profile change.

- **LambdaHack #419** exports `lambdahack` **0.9.5.0** in
  `(tay packages lambdahack)`, canonical `LambdaHack/LambdaHack` stable pin
  `aa894089399abe1a564a1ae6160a4751b6c61004`, recursive source hash
  `06dx7qm0m9d3k39swrz2mwjmxcipqf15x86kfpsl9ffx88nm07xh`.
  Upstream-tested GHC 8.6.5 uses a private 43-archive lts-13.18 library closure
  (the snapshot compiler was 8.6.4, same ABI), preserving native default SDL.
  Authentic snapshot Cabal revisions for async/hashable/primitive/cabal-doctest/
  parsec are pinned rather than assuming unmodified archive metadata compatibility;
  parsec r2 permits the compiler's base version.  Native transformers-base
  dependency edges include both stm and transformers-compat.
  The pinned enummapset 0.6.0.1 archive has a 42-byte multipart trailer;
  exact size/trailer checks retain the complete CRC-validated gzip member
  before ordinary tar extraction, without changing its origin/hash or ignoring
  decompression errors.
  Internal game-content/definition RUNPATHs relocate to their installed shared-
  library directories, retaining real dependency paths/static/shared semantics
  and enabled RUNPATH validation rather than suppressing warnings.
  Original tests run post-install for the embedded font datadir: a 50-frame
  null crawl and SDL battle initialization.  BSD-3 code, GPL-2-only font
  modifications and OFL-1.1 font retain original COPYLEFT/CREDITS/font notices:
  COPYLEFT grants GPL-2+, but CREDITS restricts these modifications to GPL-2;
  no later-version grant is inferred for them.  Static dependency/compiler legal
  files are also installed.  `tests/lambdahack-smoke.sh [output]` honors `GUIX` and absolute
  `LAMBDAHACK_SMOKE_ARTIFACTS`.  Original uppercase `LambdaHack` basename keeps
  native `~/.LambdaHack` state; saves are `saves/LambdaHack.server.sav` and
  `LambdaHack.human_1.sav` (native solo-raid human faction 1) with atomic native
  temporary-file rename.  The GUI starts
  upstream insert-coin autoplay by default; external human input takes control
  and starts the actual solo raid, waits/moves, then Ctrl-x/Space saves and
  cleanly exits for ordinary process restart.  Exact map/HUD pixels, leader,
  clocks and equipment/pack surfaces are compared, excluding messages.  Native
  menu/equipment/pack/HUD ASCII text is decoded from exact pinned 16x16 BDF
  glyph masks rather than OCR; global/local numeric clocks remain strict.
  Unknown map graphics are kept outside decoded text regions.
  Raw native saves are retained, but hidden serializer/RNG fields are not
  decoded or claimed fully equal.  A separate
  `tests/lambdahack-benchmark.sh [output]` honors `GUIX` and absolute
  `LAMBDAHACK_BENCHMARK_ARTIFACTS` with the original upstream 50-frame null-
  frontend deterministic crawl flags; it requires actual session frames/exit0
  from the native `~/.LambdaHack/stdout.txt`/`stderr.txt` logs (non-TTY
  redirection), not the consumer launcher's `benchmark.log`,
  and no saves, not GUI acceptance or a changed default frontend.  Neither
  consumer is an installed custom proof mode.
  Final build/reproducibility/offline lint/original upstream suite, original
  50-frame benchmark and native/integrated GUI passed for
  `/gnu/store/b2vr0nkzzv4rlljshk6sp1apq2y0df8d-lambdahack-0.9.5.0`.
  `/tmp/lambdahack-native-final` records two exact selected-state restores,
  strict native clocks and continued moves, native save/clean exits and
  unchanged NAR `06fq18vx3z89xrn72islh9pr1h453794xknq3csf15in24qm3d75`;
  `/tmp/lambdahack-benchmark` retains the independent native benchmark receipt.
  The [actual native SDL screen](.goocastle/evidence/lambdahack-native.png)
  shows leader Haskell Alvin, HP 40/80, Calm 70/70 and Typing den 2 with 7%
  seen; hidden serialized state/RNG remain outside the proof.
- **Kimchi #416** exports `kimchi` **1.3.2** in `(tay packages kimchi)`,
  canonical `kimjoy2002/crawl` tag kimchi-1.3.2 at
  `8f533dcfe5fe76833cb636531bae56e3bf106556`.  Fixed archive SHA-256 is
  `0aa72c8d85467374435f69bfa59e2f02787f452a24b49cc3075b18ad43906b47`,
  actual Guix base32
  `0ivbj11ss62v0z1rrd14592pyy025ygabgv9bx1p8ws6hn6jr9qa`.
  GPL-2+ console source uses system Lua 5.1/ncursesw/SQLite/zlib, without
  submodule fetches/tiles/fonts/sounds/web assets.  BSD-2/Expat/public-domain/
  CC0/Apache-2 source notices and full upstream license docs are retained.
  Ordinary `bin/kimchi` sets native data/state below `XDG_DATA_HOME/kimchi`
  (HOME fallback), terminfo and macro/default `-dir` options; no installed
  Python proof dispatcher exists.  `tests/kimchi-smoke.sh [output]` honors
  `GUIX` and absolute new/empty `KIMCHI_EVIDENCE_DIR`.  Its real xterm/Xvfb
  consumer requires ordinary waits/save/restore/native abandon-confirmed quit,
  clock/coordinates/HP/stats/dump comparison and actual Hangul shield inspection
  using test-only Noto CJK fonts.  Upstream has no restore welcome-back message;
  proof does not depend on one or claim exhaustive future RNG continuation.
  Final build/reproducibility/offline lint/original stress suite and integrated
  native consumer passed for
  `/gnu/store/grkkmx3xr9zn7yqxsi67aqm1ggy4w4pn-kimchi-1.3.2`.
  `/tmp/kimchi-native-final` records three ordinary waits, same-character restore,
  one further turn, re-save and confirmed abandon/quit, with clock/coordinates/
  HP/stats/character dumps compared.  NAR stayed
  `1aj48f0k0bn9rlwy32yk97pas6gilfjkhs95g8b6iqlkldaxg0vc` in private namespaces
  with read-only store/private tmp.  Actual Korean shield text is legible without
  missing-glyph boxes, with wide spacing/wrapping in the native console.
  [Restored native screen](.goocastle/evidence/kimchi-native.png) and
  [Korean shield inspection](.goocastle/evidence/kimchi-korean.png) are retained.
- **KeeperRL #412** exports `keeperrl` **1.3.0-1.95d2be4** in
  `(tay packages keeperrl)`, canonical `miki151/keeperrl` post-v1.3 pin
  `95d2be4e97db2243210a71918e36a533ad94dcd1`, archive SHA-256
  `40a70fcd1d4f6962bed475ddc8404bd8cb0865661760da23f660d3d85e8629db`.
  The free graphical ASCII `data_free` scope excludes paid `data`/`data_contrib`,
  fonts/music/tiles and Steam SDK; Guix DejaVu replaces fonts.  File headers
  establish GPL-2+ code, with
  CC-BY-SA-2.0 `data_free`, including Lorc icons.  ProgramOptions' original MIT
  Josua Rieder 2017 grant is verified from Fytch/ProgramOptions.hxx.  Comparison
  against upstream `70d1c8eb81e068da71e3c4494995357acab3c5cc` establishes the
  implementation's local argument-name/debug/count/warning adaptations, not
  byte-identical vendoring.  Original
  library attribution files, LGPL-2.1 text and fontstash/stb/gzstream/minizip/
  THEORAPLAY/video source notices accompany the package.  Standard iomanip
  replaces the old bundled header copy.  Writable native cwd is
  `${XDG_DATA_HOME:-$HOME/.local/share}/KeeperRL` for saves/settings/highscores/
  keybindings/installId/mods/worldgen/stacktraces.  ONLINE/GAME_EVENTS default
  off, unsolicited personal messages are removed and `--no_crash_reports`
  is respected; online exchange remains a settings opt-in game capability.
  `keeperrl-equipment-value.patch` fixes harmful bow modifiers incorrectly
  scoring as upgrades by consistently initializing the melee baseline before
  summing modifiers; its original upstream regression test remains unchanged.
  The obsolete numeric dungeon-balance snapshot test/call is removed, not
  re-pinned, after upstream `6d905cc29f5e10a96ff4e4205d4d0cf86ddd3d0a`
  intentionally changed rewards in 2022.  Production rewards are unchanged.
  External
  `tests/keeperrl-smoke.sh [output]` honors `GUIX` and absolute
  `KEEPERRL_SMOKE_ARTIFACTS`, requiring genuine fresh-campaign menus/actions/
  saving/full-process reload/screenshots; no installed `--smoke-test` dispatcher
  or generated-save fixture is used.  Pristine `data_free` lacks `tutorial.kep`
  required by native tutorial loading, so tutorial acceptance is not claimed.
  The native `campaign_base` worldgen diagnostic records 20 one-shot proposal
  samples for each alignment/biome and preserves actual accepted/rejected counts;
  it measures generation probability, not all-attempt success or gameplay proof.
  The ordinary campaign uses upstream retry logic, and graphical campaign
  actions/save/reload remain mandatory acceptance independent of this diagnostic.
  Final build/reproducibility/offline lint/repaired genuine upstream suite and
  native/integrated campaign consumer passed for
  `/gnu/store/a3cvw4nw8s5ip8mb226nac0j2b5vzlz3-keeperrl-1.3.0-1.95d2be4`.
  `/tmp/keeperrl-native-final` records controlled-creature native waits advancing
  GlobalTime 6 → 7 → 8, full-process restores at exactly 7 and 8, the same native
  save filename/display-name/version after continuation, changed decompressed
  save content, native quits and a second fresh HOME/XDG with no primary save.
  This proves controlled mode, save identity and exact clocks, not equality of
  every hidden serialized field or future RNG.  Private namespaces/read-only
  store preserved NAR `0c2nm6jpy41w23z2mnnan9mfripxi66qk8ianq1n769kf0s1adqs`.
  The [actual graphical ASCII campaign](.goocastle/evidence/keeperrl-native.png)
  shows Arnald the keeper, T:8 and native “Exit control mode [U]” without errors.

Only exact synthetic installed proof contracts #700 (`--smoke-test`) and
#701/#702 (`--smoke`) were retired.  No fake replacement or Goocastle executor
is installed or run.

Serial validation commands (use fresh evidence directories):

```sh
guix lint -L guix --no-network --exclude=cve,refresh,archival lambdahack kimchi keeperrl
lambda_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 lambdahack)
kimchi_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 kimchi)
keeper_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 keeperrl)
guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 --check lambdahack kimchi keeperrl
LAMBDAHACK_SMOKE_ARTIFACTS=/tmp/lambdahack-native-FRESH GUIX=guix sh tests/lambdahack-smoke.sh "$lambda_out"
KIMCHI_EVIDENCE_DIR=/tmp/kimchi-native-FRESH GUIX=guix sh tests/kimchi-smoke.sh "$kimchi_out"
KEEPERRL_SMOKE_ARTIFACTS=/tmp/keeperrl-native-FRESH GUIX=guix sh tests/keeperrl-smoke.sh "$keeper_out"
```

## GearHead 2, GearHead: Arena and FIQHack — verified native paths

These separate source-built ASCII games retain ordinary native entrypoints;
external `tests/*` consumers, not installed custom smoke modes, own evidence.
All three passed final build/reproducibility/offline lint/native/integrated
gates; FIQHack's unchanged 1000-case upstream TAP suite also passed.
Repository packaging establishes no deployed profile change.

- **GearHead 2 #376** exports `gearhead2` **0.701**, canonical
  `jwvhewitt/gearhead-2` v0.701 peeled commit
  `415dee8d8730ef1ed8adfd741b1a2b2fa201c2e7`, fixed Git NAR hash
  `1h4aab0wl3s971s0h69wgk4amsyfga9gzpmq9l59ji3kh1457cm9`.
  Free Pascal `-dASCII` builds LGPL-2.1+ source with text-only GameData/Design/
  Series/docs; PNG/fonts/images/meshes/SDL assets are excluded.  Linked FPC RTL
  retains full Library-GPL-2 and COPYING.FPC linking-exception notices from the
  exact compiler source; bash/coreutils notices also cover the launcher closure.
  Native writable
  saves are under `XDG_STATE_HOME/gearhead2/savegame`, configuration under
  `XDG_CONFIG_HOME/gearhead2/gearhead2.cfg`.  External
  `tests/gearhead2-smoke.sh [output]` honors `GUIX` and new/empty
  `GEARHEAD2_EVIDENCE_DIR`.  Its source-informed decoder preserves native
  campaign dimensions/time/scale, complete active terrain/visibility, scene,
  actor/inventory/subcomponent gear trees, named frozen maps and SOURCE gears.
  Only keyed numeric/string attributes and frozen-map name ordering are
  canonicalized; actor/gear/SOURCE ordering and all serialized fields remain,
  including full raw string-attribute Info alongside interpreted values.
  `gearhead2-native-restore.patch` preserves paused native turns and raw saved
  attributes: true resume skips duplicate STARTGAME/UPDATE initialization and
  continues the pending player input before clock advancement, preserving initial
  deployment initialization and ordinary remaining turn processing.
  Final build/reproducibility/offline lint/native/integrated consumer passed for
  `/gnu/store/vy3bdyiyz3xww77l9al2px8a12mbh475-gearhead2-0.701`.
  `/tmp/gearhead2-native-final` records two native pilots/campaigns and two
  explicit Alpha selections from the two-file native menu, both exact full
  canonical serialized-state restores including clock/raw attributes/maps/gears.
  Exact rendered map/HUD glyphs, effective configured white/black colors and
  rendition flags match; raw terminal cells remain separate, not a claim of
  CSI-encoding equality.  Native movement advances [13,5] → [14,5], time 1 → 60;
  native Quit Game exits zero.  Offline UID-preserving namespaces/read-only store
  preserve NAR `1586nb2ab9v9m547kzx5s7vyar8r1dpw3989dgzanqf4c9x7p3c4`.
  [The actual final live xterm](.goocastle/evidence/gearhead2-native.png) is not
  a transcript renderer; unserialized RNG/UI/runtime-cache equality is excluded.
- **GearHead: Arena #374** exports `gearhead` **1.310**, not GearHead 2 or
  Caramel, canonical `jwvhewitt/gearhead-1` v1.310 peeled commit
  `4314041f9e703e356807a9d17e613aae09289df4`.  Fixed archive SHA-256 is
  `a2f120f006d72eef9408e558dd0a569f0a04c06cbf0a447063a934943a419af6`,
  Guix base32 `1xls84x98d59cdq482mzdk0082lzaq5dsn7512afybnp0vq21wd2`.
  LGPL-2.1+ ASCII source/text Design/GameData/Series/docs excludes image/font/
  SDL/optional boxdrawing assets.  Linked Free Pascal RTL original COPYING/
  COPYING.FPC/provenance notices retain its Library-GPL-2+ independent-module
  linking exception without adding a compiled FPC source runtime dependency.
  Ordinary `bin/gearhead [CONFIG-DIRECTORY]`
  retains native first-argument configuration; no args uses absolute
  `XDG_STATE_HOME/gearhead` or `HOME/.local/state/gearhead`.  Native
  `gharena.cfg`, `SaveGame` and map-editor user maps stay outside the store.
  External `tests/gearhead-smoke.sh OUTPUT EVIDENCE-DIRECTORY` requires a
  prebuilt output and new/empty evidence directory, honoring `GUIX`; it triggers
  no build and does not resolve host proof tools automatically.  Use the explicit
  Guix shell below for native and integrated invocation.
  `gearhead-resume.patch` preserves native combat resume:
  saved scene-start state prevents duplicate entry/update/restock, resumes pending
  player input before clock advancement and retains full raw saved attributes;
  fresh/legacy scene entry and tactics behavior remain unchanged.
  Final build/reproducibility/offline lint and native/integrated consumer passed
  for `/gnu/store/xmzffynksszp1w9ffa39kfhfdajynj8r-gearhead-1.310`.
  `/tmp/gearhead-native-final` records native creation/selection, map movement,
  X save/Q/native quit, restart with explicit Config_Directory and exact selected
  character, position, scene index/type/name, map dimensions/terrain, scale and
  clock restore.  Final saved/restored clock is 18, position [29,37], scene index
  319, map 50x50.  Namespace denial is failure, never a skipped pass; read-only
  store preserved NAR `1rbmsvcly7fwx34vlabbzsbp7bfvp1d78q9w1xg4xn6k01hnz835`.
  [The actual restored xterm](.goocastle/evidence/gearhead-native.png) shows
  OmpProof, HP 16/16 and clock 0:00:18/day 0; full hidden state/RNG equality is
  not claimed.  No upstream automated suite is substituted by these native checks.
- **FIQHack #362** exports `fiqhack` **4.3.0**, canonical `FredrIQ/fiqhack`
  stable tag commit `6292ea1d04b5cabac2865a93e3ac0d6fa6adcb84` (not unfinished
  development branch).  Fixed tag archive SHA-256 is
  `d00f714988f1207f5684ebd5d512840eba1429621e0403f48ba490720a5f56dc`,
  Guix base32 `1p2nbw575454igs0610yc8li9fhfhh9dbmgbhib7y87ii14p23yh`.
  Native GNUmakefile builds local tty `bin/fiqhack` with zlib and static
  libuncursed; Jansson is not used by this build.  NGPL game/text and NGPL/GPL-2+
  libuncursed retain full original notices, guidebook/changelog/text tile
  sources and modified source/package provenance.  Full `nhdat` and ASCII/
  Unicode text tiles ship, not SDL/fonts/art/server/network-client assets.
  Native anti-magic traps clamp a level-zero monster's random-range argument
  to one, avoiding invalid `rnd(0)` while preserving positive-level behavior
  and RNG assertions.  The unchanged upstream 1000-case TAP suite exposed the
  source defect; dated NGPL modification notice and modified source are retained.
  Writable/config state uses `XDG_DATA_HOME/FIQHack` with
  `HOME/.local/share/FIQHack` fallback; native `--userdir` overrides remain.
  External `tests/fiqhack-smoke.sh OUTPUT EVIDENCE-DIRECTORY` requires a
  prebuilt output and new/empty evidence directory and honors `GUIX`.  Final
  build/reproducibility/offline lint and the unchanged 1000-case upstream TAP
  suite passed for
  `/gnu/store/cm0nd4rhw8cgk282n1yb75nqn22xpqsp-fiqhack-4.3.0`.
  `/tmp/fiqhack-native-fixed` records actual native movement from turn 1/[6,14]
  to turn 2/[7,14], first exact restore then continuation to turn 3/[6,14],
  second exact restore and native quits: Fiqproof, Valkyrie/human/female/neutral,
  HP 16/16, depth 1.  Immutable identity and committed native gamestate record
  bytes match both restores; whole save files differ normally through native
  log/bookkeeping records, so full-file equality is explicitly not claimed.
  Actual game PNG status uses exact independently calibrated xterm ASCII glyph
  masks, not OCR guesses; the font-reference calibration remains separate from
  [the retained genuine game screenshot](.goocastle/evidence/fiqhack-native.png).
  UID-preserving offline namespaces exposed only lo/read-only store, and NAR
  stayed `1fsrsdk39wy94m88j9yl59mp4xskg4qzglk62viksa7d4mj1m3sj`.
  The final integrated target also passed with an independent native campaign
  under `/tmp/fiqhack-native-integrated`.

Exact installed synthetic contracts #686/#687/#688 (`--guix-smoke`) are retired,
without fake replacement registry entries or running Goocastle.

Serial validation commands (fresh evidence directories):

```sh
guix lint -L guix --no-network --exclude=cve,refresh,archival gearhead2 gearhead fiqhack
gearhead2_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 gearhead2)
gearhead_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 gearhead)
fiqhack_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 fiqhack)
guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 --check gearhead2 gearhead fiqhack
GEARHEAD2_EVIDENCE_DIR=/tmp/gearhead2-native-FRESH GUIX=guix sh tests/gearhead2-smoke.sh "$gearhead2_out"
guix shell guix python python-pyte coreutils findutils util-linux xorg-server xterm xdotool imagemagick font-dejavu -- sh tests/gearhead-smoke.sh "$gearhead_out" /tmp/gearhead-native-FRESH
GUIX=guix sh tests/fiqhack-smoke.sh "$fiqhack_out" /tmp/fiqhack-native-FRESH
```

## EvilHack and DynaHack — verified native paths

These distinct local tty/curses variants expose ordinary native launchers, with
external `tests/*` consumers requiring prebuilt output/new-empty evidence and
self-resolving proof-only dependencies through the selected `GUIX`.  Both passed
final serial build/reproducibility/offline lint/native/integrated gates.
No deployed host/profile change is established.

- **EvilHack #353** exports `evilhack` **0.9.3**, canonical `k21971/EvilHack`
  released tag commit `c444f6a3ab1e9f16d0676961dba86f628e91c6ba`, fixed Git
  NAR hash `0xrp2djn1mwvxkygkn8q8yjsfn3r6swgfxccvcyzzmxk5560pb5n`.
  NGPL game plus bundled ISAAC64 CC0 notices cover the selected native tty/
  curses closure; optional sounds/fonts/graphical-port assets are excluded.
  Restrictive legacy `doc/tmac.n`/derived formatter and grantless XCode config
  are removed; an original Expat-licensed adapter preserves source-generated
  Guidebook documentation.  Full dated modified-source/adapter/recipe notices
  cover the cleaned selected closure, not every original upstream asset.
  Mutable native state is `${XDG_DATA_HOME:-$HOME/.local/share}/evilhack`, with
  per-run playground cleanup and ordinary native flags retained.  External
  `tests/evilhack-smoke.sh OUTPUT EVIDENCE-DIRECTORY` honors `GUIX`; no installed
  `--guix-smoke` branch or fabricated native proof marker is used.  The consumer
  compares both complete 80-column HUD rows, turn/HP, source-derived player map
  coordinate, all 80x21 displayed cells and native inventory letters/descriptions
  across pages through two fresh-process restores and continued movement/quit.
  Binary saves are not decoded; hidden terrain/monsters/objects/RNG/timers and
  unshown attributes are excluded.  Live xterm PNG HUD pixels corroborate native
  state, not OCR guesses or a transcript renderer.  The declared gzip store
  path and native `.gz` save handling repair actual compressor errors; the
  consumer rejects those errors instead of accepting successful-looking saves.
  Encoded Atari assets are also excluded from the selected closure.
  Final corrected build/reproducibility/offline lint/native/integrated gates
  passed for `/gnu/store/fkc601vz1k8m945fggf2a0zd3mx77wgw-evilhack-0.9.3`.
  `/tmp/evilhack-native-gzip-final` retains genuine `.gz` saves with valid native
  decompression, two exact public-state restores and continued turns 1 → 2 → 3 → 4
  followed by native zero-status quits, with compressor errors rejected.
  UID 1000/offline lo/read-only store preserved NAR
  `00bbk3qbhvylwq0428cbrzhzcn2z2i1c58n0zdbnw7c285daa55z`.
  [The genuine final restored xterm](.goocastle/evidence/evilhack-native.png)
  is from this corrected output, not an earlier recipe or calibration fixture.
  The complete original Guidebook is source-generated without formatter errors;
  no upstream automated suite is invented.
- **DynaHack #342** exports `dynahack` **0.6.0**, canonical `tung/DynaHack`
  stable tag commit `25aaf2ab6a27a9104864d22337d7117c7d261571`, archive SHA-256
  `626de68b538265a6fd0a356079635f9c4e1a37ba5ada1e11c68194a1500e9880`.
  Local curses executable/shared libnitrohack/nhdat excludes network client/
  server/Jansson/PostgreSQL and fonts/tiles/sounds.  The source snippet removes
  unused restrictive `doc/tmac.n` and Windows `nitrohack/rc` resources before
  building/installing source; FOSS coverage applies to this cleaned local closure,
  not every original archive asset.  NGPL game/map source and MT19937 LGPL-2.0+
  notices retain original selected source/file notices, full LGPL-2.0 text,
  Debian copyright, Guidebook/changelog/save recovery docs and
  dated modified-source/recipe provenance.  Native `-H` selects immutable
  `share/dynahack`, `-U` selects `XDG_CONFIG_HOME/DynaHack`, and `-V` selects
  `XDG_STATE_HOME/dynahack`; terminfo comes from the declared ncurses closure.
  No upstream automatic/CTest suite exists.  External
  `tests/dynahack-smoke.sh OUTPUT EVIDENCE-DIRECTORY` honors `GUIX`, with no
  installed testing branch.  The consumer compares native player/role/race/
  gender/alignment identity, HP/max HP, turn, map/dungeon coordinates and initial
  identity indices, plus exact committed command/diff bytes after restore.
  The consumer permits only transient `flags.move` byte 82 to differ during a
  no-turn binary re-save; the final observed run had full binary equality.
  This is opaque equality, not decoded inventory/monster/map/timer/RNG semantics.
  Final build/reproducibility/offline lint/native/integrated gates passed for
  `/gnu/store/rliigp950xzkjvkwd30sjiqb0r0wsicr-dynahack-0.6.0`.
  `/tmp/dynahack-native-final` records three real adjacent moves, turn 1 → 4,
  exact turn-4 restore/native identity/coordinates/HP and committed log bytes,
  two continued moves to turn 6, second exact turn-6 restore/no-turn re-save and
  native quits.  The [genuine restored xterm](.goocastle/evidence/dynahack-native.png)
  is independently checked with exact real reference glyphs, including native
  bold+underlined player @; calibration is not game evidence or a cursor alias.
  UID 1000/offline lo/read-only store preserved NAR
  `0i41sr3021s7q182a7w6vl7c8mrs0f3b1c7jfvclckv7w67q3176`.

Only exact synthetic installed #684 (`--smoke-test`) and #685 (`--guix-smoke`)
contracts are retired; no fake replacement registry entries or Goocastle
executor are introduced.

Serial validation commands (fresh evidence directories):

```sh
guix lint -L guix --no-network --exclude=cve,refresh,archival evilhack dynahack
evilhack_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 evilhack)
dynahack_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 dynahack)
guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 --check evilhack dynahack
GUIX=guix sh tests/evilhack-smoke.sh "$evilhack_out" /tmp/evilhack-native-FRESH
GUIX=guix sh tests/dynahack-smoke.sh "$dynahack_out" /tmp/dynahack-native-FRESH
```

## AloneRL and Allure — Allure verified, AloneRL acceptance pending

**Historical pending context:** the earlier statements immediately below and
the retained original catalog/check comments are superseded by the final
2026-10-04 receipt. They are preserved to retain the chronology, not current gates.

These standalone source-built games retain ordinary Swing/SDL entrypoints.
External `tests/*` consumers require prebuilt output/new-empty evidence and
self-resolve proof-only dependencies through `GUIX`.  Allure passed its final
serial build/upstream tests/reproducibility/offline lint/native/integrated gates;
AloneRL acceptance awaits Main's serial runs.
No deployed host/profile change is established.

### AloneRL final local acceptance (2026-10-04)

This receipt supersedes the earlier pending statements in the preserved section
and catalog below; the original source/licensing history remains available.
Main's serial source build (bg943) produced
`/gnu/store/mswq4vzrpbpipqybrhz2kkimgbrbvha5-alone-rl-0.3.1` with terrain output
`/gnu/store/6ph2v9qjcliyhp7jg7divjpjywgydz4k-alone-rl-terrain-0.2.1`.
The `--check` rebuild reproduced both outputs bit-identically (bg945).
Offline lint reported no package findings (bg946); the known unrelated
Flex Launcher and NHFourk findings are not AloneRL acceptance failures.

Build repairs use upstream named JUnit module descriptors, source-built FastCSV
4.2.0 relocated exactly inside the params dependency with its MIT notice, full
Rust 1.93 including `rustdoc`, and the exact Pillow interpreter as a proof input.
All original tests are retained and Rust/rustdoc tests remain enabled. Source
compilation does not substitute a release terrain binary or online dependency
resolution. Kotlin interoperability is unexercised; compile-only empty Kotlin
module descriptors are not installed. Cross-compilation is unsupported.

The final ordinary Swing/X11 consumer passed with exit status 0 and
`ALONERL_RUNTIME_OK` (bg961, `/tmp/alone-rl-native-final-v6`). Its `evidence.json`
records real New/world/character creation, upstream F1 movement-delay debug
control and Craft/back interaction,
two successful moves from (512,512) to (513,512), then (513,514); same-process
Continue retained loaded objects and further moves reached (514,514), then
(514,515). An ordinary fresh launcher process used Continue, matched the
preserved elevation bytes and six selected native terrain/background fields,
then moved (512,512) to (512,514) and back to (512,512), and quit cleanly.
Both native process exits were 0; the independent integrated
`make check-alone-rl` also passed with exit 0/`ALONERL_RUNTIME_OK`
(bg962, `/tmp/alone-rl-make-final`) against the same output.

Input is real external XTEST focused at the discovered descendant AWT
`FocusProxy`, not application instrumentation or a custom frontend. Temporary
javaagent, `-Xint` and twm experiments were diagnostic only and are **not** the
final acceptance path. Fresh HOME/XDG state, same-UID private namespaces,
loopback-only networking, read-only caller mounts/store and a private temporary
directory isolated the proof. No native error/stacktrace was observed. Before
and after output NAR hashes both were
`1vs813bgk8jsh35cjpj464fzqcls0n0iqlz1lrnim905vbvs7lhh`.
The [genuine after-continued-play PNG](.goocastle/evidence/alone-rl-native.png)
is copied from that final production run, not a diagnostic rendering.
Main also visually inspected the actual screenshot: `@`, blue `~` water,
green terrain, the AloneRL HUD and combat message lines are visible without
a blank/error surface. Message lines do not establish comprehensive combat
acceptance.


**Continue persists terrain elevation only:** same-process Continue keeps loaded
objects, while fresh-process Continue creates them anew. This is not character,
inventory, position, time, hidden-state or future-RNG persistence. No deployed
host/profile change is established. Allure's separate final receipt below is
unchanged; publication of either package is established by signed channel
history rather than a temporary pending-publication sentence.
Elevation is the native 1024×1024 row-major byte map; reload comparisons do not
establish serialization of regenerated objects. First-use YAML seeding preserves
user modifications and does not automatically refresh YAML on upgrade.



### Preserved source and earlier gate details

- **AloneRL #272** exports `alone-rl` **0.3.1**, canonical `fabio-t/alone-rl`
  tag commit `de2ab3f0023cbfb0f9ab5a68e3d48fabf4b17de8`, fixed codeload archive
  Guix hash `0xhv3rmydq9hg29a2d9245gxdy822qrnpazbnrwlwcmz9harsdmv`.
  AGPL-3+ game and MIT vendored AsciiPanel/font assets retain their grants.
  Independent BSD-3 rlforj and Apache-2 terrain-generator plus the pinned
  source-built Java/Rust dependency closure are being completed.  Gradle
  wrapper/bootstrap files are removed before direct javac; no release native
  binary or network resolution substitutes for source compilation.  All ten
  unchanged AsciiPanel font sheets retain the explicit pinned MIT font grant;
  dependency documentation is copied from each independently built input's
  `share/doc` into `share/doc/alone-rl/dependencies`, not asserted from a label.
  Terrain v0.2.1 is separately pinned to
  `bc32cf49ef7a6032c24819a4b9e4a1a39745717d`; actual fixed codeload archive
  SHA-256 is `e56d2371963d5748a8a66c39d79b1e1c4b94173351b36939532e75ed29863925`
  (the historical research used a different archive representation).  Its
  actual lock contains 44 registry sources, not the historical 41; original
  lock and full notices are retained, including separately pinned Rustler
  notices where crate archives omit them.  Bundled libloading test DLLs are
  removed before the selected FFI-only/default-off/PNG-enabled source build;
  no CLI/NIF closure is claimed.  Rust 1.93 satisfies upstream MSRV 1.91.
  The JDK 25 binding JAR has no embedded native resource; the launcher loads
  source-built `libterrain_generator_ffi.so` through `-Dtergen.library` and
  explicit native access.  Original Rust/Java FFM and installed-artifact test
  phases are present but their actual results await Main.
  Actual Artemis 2.3.0 source grants are BSD-2 plus its Apache-2 libgdx
  notice, not the historical THIRD-PARTY Apache-only description; both full
  originals are retained.  JUnit 6.1.3's optional compile-only Kotlin utility
  uses a source reflection adaptation rather than an opaque Kotlin bootstrap
  or version downgrade.  Its reviewed original/dated SOURCE-NOTICE is retained
  without deleting optional features; actual Java tests await Main and optional
  Kotlin interoperability is not exercised.
  Actual Logback 1.6.3 `LICENSE.txt` grants EPL-2.0/LGPL-2.1, not the
  historical EPL-1.0 description; exact notice and full texts are retained.
  Matching Jansi 2.4.0/JLine 4.3.1 JNI sources use JDK-provided JNI headers;
  all bundled prebuilt natives and proprietary JNI headers are discarded
  before source rebuilding.  Installed `SOURCE-NOTICE` preserves rather than
  silently edits upstream THIRD-PARTY while explaining the actual grants.
  The settled Java closure has 27 source-built runtime JARs (three base, seven
  Jackson and seventeen logging) and nine JUnit/APIguardian/jspecify/OpenTest4J
  test JARs, with real Launcher API discovery, Guix `openjdk25` 25.0.2 (`jdk`
  output) directly and fixed 1980 JAR dates.  Complete EPL-2 text uses an immutable
  pinned JUnit text source, not a failed dynamic HTML fetch.
  Elevation-map persistence is not a character/inventory save-state claim.
  Native `-Dalone.data` points to writable `XDG_DATA_HOME/alone-rl` (fallback
  `HOME/.local/share/alone-rl`), including `map/elevation.data`; no-clobber
  first-use data seeding preserves existing elevation and locally edited YAML
  seed files on relaunch; no automatic upgrade migration or forced overwrite
  is claimed.  Users may deliberately remove copied YAML seeds to refresh them;
  generated map data is not overwritten.  No store data mutation or installed
  documentation screenshots are introduced.  External
  `tests/alone-rl-smoke.sh OUTPUT EVIDENCE-DIRECTORY` owns real Swing input/proof,
  not an installed `--guix-smoke` branch.  Its source-ready consumer selects
  real New/world/character generation, F1, two verified moves, Craft/back,
  same-process Continue/two moves/quit, then an ordinary launcher restart with
  Continue/elevation comparison/two moves/clean quit.  It retains actual
  825x825 PNGs decoded against the real font, raw 1024x1024 row-major elevation
  bytes/histogram/five selected byte points and six rendered native-field
  comparisons.  Elevation pixels/bytes and displayed fields do not prove
  hidden character/inventory persistence or future RNG equivalence.  Runtime
  error logs and NAR changes fail closed; `ALONERL_RUNTIME_OK` is an external
  consumer completion line only.  Actual acceptance remains pending.
- **Allure #271** exports `allure` **0.11.0.0** with native command **`Allure`**,
  canonical fixed source `0ec5296bec777c399e21d6fed44b5366dda95f84`, codeload
  SHA-256 `1e7648ad12f44806d7210f7b3fa37245369397a6ad960316aaa8f18aefde526e`.
  Its SDL LambdaHack engine is separately pinned **0.11.0.1** at
  `1399d5bd0f6a4c104249375a2968b314ca1a60d4`.  AGPL-3+ code and full original
  font grants are retained: original Angband fonts GPL-2+, LambdaHack font
  modifications GPL-2-only, Adobe-derived Binary OFL-1.1, DejaVu Vera/public-
  domain changes and Hack Expat/Vera.  Full GPL-2 text accompanies COPYLEFT's
  AGPL/OFL/Vera/Expat notices; no later-version grant for font modifications is
  inferred.  Full GPL-2 text comes from the selected FreeType source's
  `docs/GPLv2.TXT`, not an invented grant.  Actual SDL2 and SDL2_ttf original
  LICENSE files grant zlib terms (SDL2's historical Guix BSD-3 metadata is not
  repeated); renderer/compression notices cover FreeType FTL/GPL, BDF/PCF,
  HarfBuzz integration and zlib.  Source-derived native state is
  `~/.Allure/config.ui.ini`, saves and scores.  External
  `tests/allure-smoke.sh OUTPUT EVIDENCE-DIRECTORY` owns
  genuine SDL play/save/restore proof.  The selected consumer compares the map
  and both HUD pixel hashes (message row excluded), yellow leader position,
  native global/local-turn clocks through the bundled BDF, and outfit/shared-
  stash item-panel pixel hashes across two fresh-process restores, waits/moves,
  save exits and continued movement.  It explicitly selects bundled
  `--fontset 16x16xw` on an 80x45 SDL surface, not the default proportional font
  presentation.  It fails on native errors/log errors, temporary or backup save
  leftovers and unknown overlays; save hashes show integrity only.  No decoded
  hidden server fields/RNG, combat/win or byte-identical full-state claim is
  made.  The source closure has 71 private GHC 9.0.2 libraries with fixed
  Hackage/Cabal-revision hashes, including assert-failure 0.1.3.0, enummapset
  0.7.3.0, ghc-compact 0.1.0.0, hsini 0.5.2.2, miniutter 0.5.1.2 and witch
  1.1.6.1.  It retains compiler boot, every private source, GHC boot/inline
  grants and native SDL/font full notices; `Setup.hs` builds do not update a
  registry.

  Final output `/gnu/store/rcxvkmm1kvg4b6916ykrzjzydi10lvh1-allure-0.11.0.0`
  passed the serial build with both original game/engine test suites (AI frames
  and SDL fontset startup), a bit-identical `--check` rebuild and offline lint
  with no Allure findings.  Native consumer `/tmp/allure-native-final` started at
  leader (65,25), clock 1; the first fresh-process restore matched leader
  (65,26), clock 3, map/HUD and equipment/inventory hashes; continued movement
  and the second restore matched leader (66,26), clock 4; final movement reached
  (67,26), clock 5, with clean save-exits each session.  NAR
  `140i21z0qaq0hsqn72sl5kqd8nsj36ijpajn8mcbd9mn62z42ihm` was unchanged.
  [The genuine 1280x720 SDL frame](.goocastle/evidence/allure-native.png) is
  from the second fresh-process restore after continued human movement.
  Earlier builds and failed native attempts 918/922 preceded the final notice,
  lint and consumer repairs and are not acceptance.  Integrated
  `make check-allure` against the same output also passed
  (`/tmp/allure-make-final`).

  Main visually inspected the actual native SDL screenshot: a small ASCII
  room, boxed `@` and party markers, “3 Captain’s bridge”, Calm 65/70,
  HP 45/79 and Post-human Haskell Alvin are visible without an error surface.
  This remains selected native surface proof, not hidden-state/RNG acceptance.

Exact installed synthetic #654 (`--guix-smoke`) and #653's automated
null-frontend benchmark contract are retired; the verified external SDL proof
replaces #653.  The benchmark can remain supplemental, never GUI acceptance.
No fake external-helper registry entry or Goocastle executor is used.

Serial validation commands (fresh evidence directories; Allure passed, AloneRL pending):

```sh
guix lint -L guix --no-network --exclude=cve,refresh,archival alone-rl allure
alone_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 alone-rl)
allure_out=$(guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 allure)
guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 --check alone-rl allure
GUIX=guix sh tests/alone-rl-smoke.sh "$alone_out" /tmp/alone-rl-native-FRESH
GUIX=guix sh tests/allure-smoke.sh "$allure_out" /tmp/allure-native-FRESH
```

## Genera Fonts 0.1.3 — public source pins, 2026-10-09

The two installable packages `genera-fonts-latin` and `genera-fonts-symbols`
consume the immutable published generic archives of
https://github.com/htayj/genera-fonts/releases/tag/v0.1.3. Fresh `guix
download` hashes were compared with `sha256sum` against the adjacent
`.tar.gz.sha256` sidecars and the expected release hex values.

| Group | Public archive | SHA-256 hex | Guix nix-base32 |
| --- | --- | --- | --- |
| latin | `Genera-fonts-latin-v0.1.3.tar.gz` | `7001f82bf03943d61cc1481b07e48bb8c6d1ffd00880cd5657c8646814c2ae67` | `0rxfq8a6hr68axbcv008s3zx3imqigj0f6s8q4fdchrry0mzh0bh` |
| symbols | `Genera-fonts-symbols-v0.1.3.tar.gz` | `e77e1938ba70bed589e7fdacf4134d09ab8a4ef07c1da9387582dfd3aa86f276` | `0xpjhsmd7pw2flwaj7bwy178maq99l9z9b7xwy4xbgkhp8w1jzp7` |

The typeface notice remains a required provenance notice, not a BSD license
grant for the historical Genera designs; the package license references the
tag-specific `blob/v0.1.3/NOTICE.md` URL. The independent
`htayj-genera-fonts-source` package remains intentionally pinned.

Exercised verification, 2026-10-09: both channel builds and lint passed.
Exact store outputs:
`/gnu/store/qq6kq2g4c971i4jllvypw4hd9m18fbi4-genera-fonts-latin-0.1.3` and
`/gnu/store/sgwm5135q0gcx1sk2fvnmgqhp5wsi2qk-genera-fonts-symbols-0.1.3`.
Lint exited 0 with no genera-font diagnostics (unrelated missing-module
warnings only):

```sh
guix lint -L guix --no-network --exclude=cve,refresh,archival genera-fonts-latin genera-fonts-symbols
guix build -L guix --no-grafts --no-offload --cores=1 --max-jobs=1 genera-fonts-latin genera-fonts-symbols
```

Both actual prefix-verifier invocations exited 0:
`--layout <prefix> --prefix <store-output> --group <group> --skip-fontconfig`.
Installed smoke receipts are recorded under
`~/.local/share/genera-fonts-tools/evidence/2026-10-09/`:
`guix-v013-latin-package-files.json`,
`guix-v013-symbols-package-files.json`,
`guix-v013-installed-consumers.json`,
`guix-v013-installed-consumers-command.json`,
`guix-v013-relocated-checksums.json`,
`guix-v013-tool-versions.json` (fc-query profile tool Fontconfig 2.16.0,
Python 3.12.12; native receipt FreeType 2.13.3).

The native consumer receipt covers all 89 fonts (10,836 glyphs total: latin
78 fonts/9,985 glyphs, symbols 11 fonts/851 glyphs) via FreeType 2.13.3
rendering all pixels and advances exactly, through the existing
`scripts/check_otb.py` `check_pair(installed_bdf, installed_otb,
artifact.logical_identity, freetype_check=True)` API, with a TINY128 pass.
Every `fc-query` family/style/weight/slant/width/nativepixelsize/spacing
field equals the installed release manifest and BDF expectations (absent
spacing interpreted as 0). Direct file queries used a throwaway empty
`--privateconfig` only to isolate the user's Fontconfig; configured
`fc-match` and desktop/compositor scaling were not claimed. Distribution:
62 proportional, 26 monospace, 1 MOUSE-dual. All 89 faces are fixed-strike,
scalable false, outline false. The four HL8 faces are the canonical Symbolics
Genera Swiss Regular/Bold/Italic/Bold Italic at native 11 px, weights
80/200, slants 0/100, width 100, spacing 0, 128 glyphs each.

Checksum diagnosis: the verifier run with
`--layout prefix --prefix <store> --group <group> --skip-fontconfig` succeeds;
`SHA256SUMS` retains release-root paths, so running `sha256sum -c` directly
from the relocated data root reports 161 latin and 27 symbols paths as
missing there — a path-mapping artifact, not payload damage. Additional
read-only path-mapping verification covered all 166 latin and 32 symbols
checksums: `fonts/*` →
`<store>/share/fonts/genera-fonts/<group>/*`; `LICENSE`, `NOTICE.md`,
`README.release.md` → `<store>/share/doc/genera-fonts-<group>/*`; remaining
manifest/metadata files → `<store>/share/genera-fonts/<group>/*`. No files
were rewritten. The smoke used only the installed store outputs; no global
profile font installation, no channel publication or push, and no source
tests are claimed.

## Installable packages

| Package | Upstream | Installed contents |
| --- | --- | --- |
| `atarist-font` | ntwk/atarist-font | Atari ST 8x16 Unicode BDF and generated PCF font |
| `cadr-fonts-latin` | CADR-fonts 0.1.2 | Unicode BDF and OTB Latin fonts |
| `cadr-fonts-symbols` | CADR-fonts 0.1.2 | Unicode BDF and OTB specialty fonts |
| `dec-fonts` | DEC-Fonts 0.1.0-alpha.2 | BDF, OTB, and Linux-console PSF fonts |
| `genera-fonts-latin` | genera-fonts 0.1.3 | Unicode BDF and OTB Latin fonts |
| `genera-fonts-symbols` | genera-fonts 0.1.3 | Unicode BDF and OTB specialty fonts |
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
| `hyprland-dualmaster` | Local source 0.1.1, matched to Hyprland 0.55.4 | Coupled centered masters, adjustable 60% default and side stacks, `lib/hyprland/libdualmaster.so` |
| `dank-material-shell-shell-only` | DankMaterialShell 0.5.1 | Full upstream shell with external GTK/Qt icon mutation guarded by the user's settings and `DMS_DISABLE_MATUGEN` |
| `caelestia-shell` | caelestia-dots/shell 2.5.0 | Quickshell desktop shell, `Caelestia` QML plugin, and `caelestia-shell` launcher |
| `caelestia-cli` | caelestia-dots/cli 1.1.3 | `caelestia` shell control, colour scheme, screenshot, recording, and picker command |
| `caelestia-panes` | Local C/GTK4 source 1.0.0 | Persistent native SilverBullet/Memos/glirc layer-shell companion and Caelestia QML socket control |
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
| `emacs-vim-region` | ongaeshi/emacs-vim-region `7c4a99c` | GPL-3.0-or-later Vim-style region selection/editing with propagated expand-region; source-header grant retained |
| `org-mind-map` | the-ted/org-mind-map `95347b2` | GPL-3.0-or-later original Emacs Org graph exporter, propagated Dash and store-bound Graphviz; SVG viewport correction, unlicensed example images excluded |
| `terminaldrome` | thafaker/TerminalDrome | Rust terminal client for Navidrome and Subsonic servers |
| `image-tape` | larsbrinkhoff/image-tape | Magnetic-tape image reader with safe output handling |
| `klh10` | PDP-10/klh10 `6d733f2` | Source-built KL10/KS10 host emulator, console, disk/tape helpers and image converters; custom eight-clause Free-Fork license, modified source/notices included; no guest systems or network services |
| `pdp10-suppty` | PDP-10/SUPPTY `2da0135` | MIT/Expat source-built GTK 2 `suppty` and CLI `suppty-plink`; original SUPDUP host clients, namespaced commands/manuals; only isolated local SUPDUP runtime verified, not old-SSH security |
| `itstar` | PDP-10/itstar V1.10 (`b709cd8`) | GPL-3.0-or-later native ITS DUMP image create/list/extract/append tool, store-bound gzip and relicensing permission; remote rmt disabled, physical tape untested |
| `apout` | DoctorWkt/Apout `0-bd9af21` (upstream 2.4.0) | PDP-11 Unix a.out user-mode emulator; [verified original V7 guest contract](#apout--verified-native-v7-guest-contract), `APOUT_ROOT` prefix is not a sandbox |
| `blincolnlights` | aap/blincolnlights `0-932d2ce` | MIT/Expat SDL B18/PDP-1/Whirlwind virtual panels, PDP-1/PDP-5/TX-0/Whirlwind host emulators with XDG-state launchers; [verified PDP-1 panel/PDP-5 memory path](#blincolnlights--verified-native-pdp-1-panel-and-pdp-5-memory-path), fixed `/tmp` panel files and TCP ports are not isolated |
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
| `stoat-soup` | Stoat Soup 0.23-ish-aug26 (`5df72bd`) | Complete original console-only Crawl variant with immutable data/docs and native XDG saves, scores, macros and caches |
| `grunthack` | NHTangles/GruntHack 0.2.4 (`51d75ee`) | Original NGPL native TTY/curses game, immutable generated data/docs and XDG mutable state; three-process exact native save continuity |
| `nitrohack` | DanielT/NitroHack 4.0.4 (`21b9774`) | Original NGPL wide-curses game with network client retained, PostgreSQL server omitted, immutable data/notices and XDG configuration/native saves; exact three-process local continuity |
| `hackem` | elunna/hackem 1.2.2 (`6e99cff`) | Original NGPL TTY game, immutable data/symbols/notices and XDG configuration/native saves; final reproducibility, three-session movement/two exact restores and lint passed |
| `hellcrawl` | Hellmonk/hellcrawl 5.7 (`8abd877`) | Original GPL-2.0-or-later console Crawl fork/data/notices and XDG native state; reproducibility, native dungeon/save/reload and lint passed |
| `wired` | Toqozz/wired-notify 0.10.7 (`6b6f3c1`) | Source-built MIT X11 notification daemon, locked Rust manifests/notices and configuration examples; final reproducibility, real Notify/render/close/kill and lint passed |
| `scala-ts` | codingismy11to7/scala-ts 0.1.8 (`9342030`) | Source-built Apache-2.0 Scala-style TypeScript library and declarations; final supplemented-origin build/reproducibility/strict consumer and lint passed; raw-archive caveats retained |
| `crashrun` | DanaL/crashRun `v0.5.0` branch snapshot (`9b95cc7`) | Original GPL-3.0-or-later Python/SDL2 game and Bitstream Vera font; source build/reproducibility/native creation/turn/save/load and lint passed |
| `dungeon-monkey-unlimited` | Dungeon Monkey Unlimited 1.001 | Original LGPL-2.1-or-later Pascal/SDL game with attributed tiles/font and XDG native saves; final build/reproducibility/native GUI/lint passed |
| `emigo` | MatthewZMD/emigo `0.5-0.91d122a` | Emacs/local Python coding-agent backend with parser queries, fixed tokenizer and immutable default CA data; build/reproducibility/local IPC/parser/TLS/lint passed; no provider or interactive chat proof |
| `kraken` | mittagessen/kraken 7.1 (`eff0571e`) | Source-built Apache-2.0 OCR CLI/fixtures with binary-assisted CPU Python wheels; final build/repro/lint/integrated offline upstream-reference text/hOCR proof and 30 tests/51 subtests passed; no production accuracy/training claim |
| `gened` | lambdamikel/GenEd (`0d847a3b`) | GPL-3.0-only original Common Lisp/McCLIM editor/XDG assets; final build/repro/lint/native exact text edit/save/reopen/resave passed; CLASSIC and Allegro-only printing unavailable, Postscript export retained |
| `soundthread` | j-p-higgins/SoundThread (`a33198a`) | MIT source-run graph/audio app with OFL fonts/pristine Bravura and pinned prebuilt Godot 4.4.1; final build/repro/lint/native WAV/graph roundtrip/render/Master PCM passed; no CDP/host audio claim |
| `cotd` | gwathlobal/CotD 2.0.2 (`b771e2e`) | GPL-3.0-only original SBCL/SDL game/XDG native state; final build/repro/lint/standalone+integrated campaign day advance/save/restore passed; tactical combat unproved |
| `emacs-eaf-emacs-application-framework` | EAF (`5fe1a6c`) with eaf-demo (`d210ef3`) | GPL-3.0-or-later core/Qt demo plus Chromium BSD-3 JS and Python/EPC closure; final build/repro/lint/standalone+integrated GUI/IPC/theme/resize/shutdown passed; clipped greeting/no optional apps |
| `eca` | editor-code-assistant/eca 0.154.0 (`52b6f015`) | Official JVM jar/OpenJDK24 with retained source/provenance/notices; final build/repro/lint/integrated+exact ungrafted real server/client proof passed; no source-rebuild/provider claim |
| `pi-coding-agent` | earendil-works/pi 0.84.2 (`914cf147`) | Official prebuilt x86_64 CLI/TUI with matching source/assets/notices and XDG state; final build/repro/lint/exact ungrafted+integrated RPC/Bash/session/export/TUI passed, no source-rebuild/provider claim |
| `squad` | bradygaster/squad 0.13.0 (`92ff24ef`) | Source-built SDK/CLI/native PTY/Koffi plus SQL/Yoga WASM/notices; final build/repro/lint/standalone+integrated init/copy-mode/routing/casting/SQLite/PTY/FFI passed, proprietary Copilot excluded |
| `oh-my-opencode-slim` | alvinunreal/oh-my-opencode-slim 2.2.13 (`6faaed2`) | MIT source plugin/dependency+Bun notices/store companion; final build/repro/lint/standalone+integrated actual OpenCode agents/tools/skills/default+project override/idle state passed; zero prompts, no model claim |
| `oh-my-opencode-slim-companion` | Slim companion 0.1.3 (build `5a4a81a`, tag `04cdef5`) | Official prebuilt x86_64/aarch64 GUI/source provenance; final build/repro/lint/standalone+integrated local-state GUI passed; simulated busy fixture not plugin/model work, no audited Rust closure claim |
| `aiwnios` | aiwnios/Aiwnios 0.9.0-0.e155e87 (`e155e87a`) | Source-built HolyC compiler/HCRT/DolDoc resources/notices; final build/repro/lint/native+integrated repeated bootstrap/compiler/status23/typed SDL42/FileWrite/NAR passed; no sandbox/kernel/cross-build claim |
| `aiwnios-bytecode` | Aiwnios 0.9.0-0.e155e87 (`e155e87a`) | Full source environment/upstream bytecode with rounded-word overread repaired; final build/repro/lint/native+integrated bootstrap/compiler/typed SDL42/FileWrite passed; native assembly retained |
| `wrogue` | Warp Rogue 0.8.0 (`675bb5d`) | Recovered source-built SDL game/full immutable data/GPLv3+MT19937 BSD3 notices; build/repro/lint/standalone+integrated GUI create/save/exact Continue/move/second restore passed; HOME saves/settings |
| `babel7drl` | Jeff Lait/Tower of Babel 2019-03-09 | Source-built game/libtcod/maps/text/Oxygen glyphs/XDG config; build/repro/lint/standalone+integrated native login/help/move/climb feedback/death/reconnect passed; no floor advancement/supported save-resume |
| `the-smiths-hand` | Jeff Lait/The Smith's Hand 2014-03-16 | Source-built SDL game/private libtcod/BSD3+PD notices; final build/repro/lint/standalone+integrated real wait/Q save/fresh exact load/inventory-topology/NAR passed; XDG native save |
| `tetraworld` | blargdag/tetraworld (`14f5ca8`) + arsd (`d5c3539`) | Source-built GPL2+ D/Boost notices/embedded data; restored-agent fix final build/repro/lint/27tests/standalone+integrated four sessions byte-exact saves/HUD/turn1→2 passed; HOME autosaves |
| `splicehack-rewrite` | RojjaCebolla/SpliceHack-Rewrite (`0cf23cb`) + Lua 5.4.2 | Source-built NGPL tty/data/MIT Lua/CC0 notices/XDG state; complete11dungeon Lua/archive/Guidebook/HOME-limit final build/repro/lint/native+integrated3games/two exact restores/save consumption/NAR passed |
| `space-privateers` | Hackage SpacePrivateers 0.1.0.0 + LambdaHack 0.2.14 | Source-built BSD-3 Haskell/Vty game/private pinned closure/full notices/native HOME campaigns; final build/repro/lint/engine1of1/native+integrated real wait/moves/two exact visible-state restores/NAR passed; hidden state not fully decoded |
| `slashem` | Hardfought/k21971 SlashEM (`aae9ef2`) | Source-built NGPL tty game/full nhshare+nhushare data/notices/Guidebook/private XDG state; final build/repro/lint/native+integrated3sessions/two exact restores/live screenshot/NAR passed |
| `shamogu` | anaseto/Shamogu 1.5.0 (`fcd439d`) | Source-built ISC terminal game/pinned12module closure/full notices/XDG saves+replays; final build/repro/lint/TestGame/native+integrated turns0/1/1/2/2/two exported-state+screen exact restores/native Q/Ysave deletion passed |
| `revengate` | ygingras/Revengate 0.13.0 (`21b0cb4`) | Source-imported Godot game/full source/media/legal notices/native node-ownership fix; final build/repro/lint/3x1000sim/native+integrated move/save/restart/resume/continued movement/clean ExitGame0/noerrors/NAR passed; selected persisted fields, not all RNG |
| `plomrogue` | Please the Island God PtIG (`32c8b0d`) | Source-built GPL-3+ C engine/Python client-server/private XDG state; final build/repro/lint/original immutable90AI oracle/native+integrated two exact restores/90vs45reload45 fullsave+RNG/NAR passed |
| `obumbrata` | Martin Read/Obumbrata et Velata 1.0.0 | Source-built BSD-2 ncurses game/project generators/manual/native XDG save; final build/repro/lint/native+integrated two exact persisted-state restores/live screenshot/NAR passed; RNG not serialized |
| `lambdahack` | LambdaHack 0.9.5.0 (`aa89408`) | Source-built BSD-3 SDL game/private pinned Haskell closure/font+dependency notices; final build/repro/lint/original suite+50framebenchmark/native+integrated two selected-state restores/continued moves/clean exits/NAR passed; hidden state/RNG not decoded |
| `kimchi` | kimjoy2002/Kimchi 1.3.2 (`8f533dc`) | Source-built GPL-2+ console variant/system libraries/full notices/native XDG state; final build/repro/lint/original stress/native+integrated waits/save/restore/continued turn/Hangul/NAR passed; no exhaustive future RNG claim |
| `keeperrl` | miki151/KeeperRL (`95d2be4`) | Source-built GPL-2+ game/free CC-BY-SA2.0 ASCII data/full legal notices/no paid media/private native XDG cwd; final build/repro/lint/repaired upstream suite/native+integrated campaign waits/two exact clock restores/native quits/independent profile/NAR passed; hidden state/RNG not fully compared |
| `gearhead2` | GearHead 2 0.701 (`415dee8`) | Source-built LGPL-2.1+ Free Pascal ASCII game/text assets/native XDG save/config; final build/repro/lint/native+integrated two pilots/two full canonical serialized restores/exact effective mapHUD/movement/quit/NAR passed; unserialized RNG/UI caches excluded |
| `gearhead` | GearHead: Arena 1.310 (`4314041`) | Source-built LGPL-2.1+ Free Pascal ASCII game/text assets/native config/save/map state; final build/repro/lint/native+integrated creation/movement/selected state+clock restore/quit/NAR passed; no full hidden state/RNG claim |
| `fiqhack` | FIQHack 4.3.0 (`6292ea1`) | Source-built NGPL local tty fork/static libuncursed/text tiles/full notices/native XDG data; final build/repro/lint/1000TAP/native+integrated two identity+gamestate-record restores/movement/quit/NAR passed; wholefile equality false |
| `evilhack` | EvilHack 0.9.3 (`c444f6a`) | Source-built NGPL/CC0/Expat local tty/curses variant/native XDG playground/complete source-generated Guidebook/declared gzip; final build/repro/lint/native+integrated valid compressed saves/two exact public-state restores/continued moves/quit/NAR passed; hidden binary state not decoded |
| `dynahack` | DynaHack 0.6.0 (`25aaf2a`) | Source-built NGPL curses variant/libnitrohack/local nhdat/full MT19937 LGPL notices/native XDG state; final build/repro/lint/native+integrated movement/two fixed-field+committed-log restores/full no-turn binary re-save/quit/NAR passed; opaque bytes, not hidden-state semantics |
| `alone-rl` | AloneRL 0.3.1 (`de2ab3f`) | AGPL-3+ Swing survival game/MIT AsciiPanel/fonts/source-built Java+Rust terrain closure/native writable map data; final gates pending |
| `allure` | Allure 0.11.0.0 (`0ec5296`) | AGPL-3+ SDL game/private source-built LambdaHack 0.11.0.1 and 71-library GHC closure/full font and renderer notices/native `~/.Allure` state; final build/upstream tests/repro/lint/native two fresh-process restores/continued moves/save-exit/NAR passed; no hidden-state/RNG claim |
| `hermes-agent` | NousResearch/hermes-agent 0.21.5 (`f97608f`) | Actual CLI/JSON-RPC/WebSocket backend, pinned binary-assisted Python closure and source-built media; writable user configuration and Guix-only package updates; reproducibility and native/backend smoke passed |
| `hermes-desktop` | NousResearch/hermes-agent 2026.9.24 (`f97608f`) | Actual desktop app with pinned Electron 40.10.2, rebuilt terminal addon, packaged backend and free-font substitution; reproducible build and sandboxed real desktop acceptance passed without provider/model calls |
| `blightmud` | Blightmud 5.7.1 | Rust terminal MUD client with Lua, TLS, MCCP2, GMCP, and MSDP |
| `bell-labs-rogue7` | Bell Labs release 7.7.1 | Historical terminal dungeon game with XDG-managed score and save state |
| `hack` | CWI Hack 1.0.3 (1985-07-23) | Original BSD-3-Clause source-built terminal game/data/manual/notices, immutable store assets and XDG native mutable state; three-process exact native save continuity |
| `lbforth` | Lars Brinkhoff/lbForth (`912433b`) with forth-metacompiler (`40b99c0`) | GPL-3.0-only original self-hosted portable C `forth`, immutable system/library/target wordsets and notices; upstream suites and isolated installed-language/error-recovery proof |
| `legcord` | Legcord/Legcord 1.3.0 (`c8d91f6`) | OSL-3.0 source application and source-built Venmic, pinned binary-assisted Electron/Node/tools, writable settings/mod cache and Guix updates; actual onboarding/persisted settings/cold logged-out relaunch/sandbox and immutable-output proof |
| `chessrogue` | ChessRogue 0.3.1 | Historical terminal chess roguelike built from the canonical SourceForge release |
| `bcrawl` | b-crawl/bcrawl 1.42.1 | Terminal-only Dungeon Crawl Stone Soup fork with XDG-managed state |
| `unnethack` | UnNetHack 6.0.4 (`1f061e9`) | NGPL full native TTY game/data/recovery/docs; private XDG data playground, upstream five C suites and three-process exact save continuity |
| `avanor` | Avanor 0.5.8 | Historical terminal roguelike with XDG-managed saves and high scores |
| `nlarn` | NLarn 0.8.0 (`1873599`) | Original C/ncurses Larn rewrite, immutable console data/locales and native `~/.nlarn` configuration/saves; actual two-process gameplay/restore/resave proof |
| `robotfindskitten` | Codeberg robotfindskitten 3.0000000.726 (`4718727`) | Original GPL-2.0-or-later C/ncurses game installed as a direct native ELF, complete NKI/assets/docs; conflicting AppStream CC-BY-SA-4.0 metadata declaration retained |
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
| `notty` | pqwy/notty 0.2.3 (`e035d06`, tag `v0.2.3`) | ISC-licensed OCaml core, Unix/Lwt backends, toplevel support and all 18 upstream examples; no Async backend |
| `miou` | robur-coop/miou `5fcb7e6` (four commits after 0.8.0) | MIT-licensed OCaml-5.4.1 core, backoff, sync, Bitv, Unix and runtime-events libraries with native stubs |
| `tui` | pmatiello/tui `e435b1b` | EPL-2.0 Clojure styled text/page rendering and cooked line input, AOT jar and offline `tui-clojure` launcher; no raw-key/cursor API |
| `proiel` | syntacticus/proiel 1.3.3 (`8b74767`) | Corpus-free Ruby treebank library and MIT synthetic example; MIT code, historical TEI GPL-3.0-or-later and W3C schemas |
| `domainslib` | ocaml-multicore/domainslib `2a88486` | ISC native OCaml-5.4.1 multicore task pools, promises, parallel algorithms and channels; matching private compiler closure |
| `ruby-memoist` | memoist 0.16.2 | MIT Ruby method-result caching library |
| `ruby-sax-machine` | sax-machine 1.3.2 | MIT declarative SAX parsing library with Nokogiri backend |
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
| `tassh` | drbeefsupreme/tassh `672569a55e6f2a0ae4274103a99b8b9abac87f4d` | Source-built PNG clipboard relay CLI/daemon and license notices; verified isolated X11/Wayland loopback path, outside default build inventory; [limits](#tassh--verified-isolated-native-clipboard-relay) |
| `emacs-treesit-sexp` | alexispurslane/treesit-sexp | Tree-sitter-aware structural editing for Emacs |
| `dipc` | doprz/dipc | Offline-built image palette converter |
| `nrl-text-to-phoneme` | greg-kennedy/p5-NRL-TextToPhoneme | NRL text-to-phoneme command and rule tables |
| `you-can-datamosh-on-linux` | happyhorseskull/you-can-datamosh-on-linux | Datamoshing and video-to-GIF commands with argv-safe FFmpeg calls |
| `ffglitch` | [FFglitch 0.10.2](https://ffglitch.org/) / [ramiropolla/ffglitch-core](https://github.com/ramiropolla/ffglitch-core) | Native bitstream editor, glitch encoder, live scripted player, and private QuickJS/JSON helpers |
| `praat@7.0.02` | [Praat 7.0.02](https://praat.org/) / Debian audited DFSG source | Full GTK3 speech analysis/editor and batch scripting executable, ALSA/JACK/PulseAudio support, built-in manual and license notices |
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
Its native smoke locally assembles original lawful V7 PDP-11 CPU/write/error/
exit programs, without historical executable or filesystem downloads. Supply
`APOUT_OUTPUT` and a new/empty `APOUT_EVIDENCE`; see the [dated receipt](#apout--verified-native-v7-guest-contract).
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

### Praat: acoustic analysis, native files and the GTK editor

`(tay packages praat)` updates the inherited GNU Guix **6.6.30** recipe to
**7.0.02** (upstream release date: 2026-08-26), preserving the full GTK3 GUI,
command-line scripting, built-in manual and ALSA/JACK/PulseAudio support.
It compiles the original program and its adapted vendored numeric/audio
libraries from the audited
[Debian DFSG tarball](https://deb.debian.org/debian/pool/main/p/praat/praat_7.0.02+dfsg.orig.tar.xz),
SHA256 `454a4bbadcd5e3ea656c2f7d5394566047a3d786b3e43c3bd4c6678c04d03267`
(Guix base32 `0rrjs028qry6shxkrr5khvbs6iv0asa56z9gdijymqymvjx4njj5`).
The repack corresponds to upstream commit
`6f3da9ef1d8cce0d5684afc104d02888dfc71b25`; its
[versioned per-file copyright audit](https://sources.debian.org/data/main/p/praat/7.0.02%2Bdfsg-1/debian/copyright)
records the excluded executable downloads, ZIPs, obsolete font archive and
Unicode HTML copies.  The channel additionally removes exactly four Microsoft
Windows screenshots from `docs/pictures`: `arm64.png`, `dontrun.png`,
`intel64.png` and `unblock.png`.  Upstream `docs/LICENSE.txt` permits these only
under fair use, not a free license; they are download illustrations, not
application, manual or test dependencies.  All remaining source and fixtures
are retained.  The program is GPL-3.0-or-later and the remaining website is
CC-BY-SA-4.0; mixed component notices, GPL text, Debian's audit and the built-in
license-manual source are installed under `share/doc/praat-7.0.02`.

The package retains both real offline upstream batch suites, `test` and
`dwtest`, including their home-directory assertions.  A fresh build HOME
isolates preferences/plugins and no test-data download is requested.  The
zero-fuzz driver patch removes only the unmatched `endif` in
`dwtest/runAllTests_batch.praat`, leaving the complete loop and cleanup intact.
Driver threading follows Guix's requested build parallelism; the installed
application's threading is unchanged.  Installed `runSystem`/`runSystem$`
use the store's shell rather than relying on a host `/bin/sh`.

Select the channel package explicitly: plain `praat` can select the older
upstream package on the current Guix.  The aggregate build/lint lists use
`praat@7.0.02`, and `check-praat` uses the module expression.

```sh
guix install -L guix -e '(@ (tay packages praat) praat)'
# Or realize the output without changing any profile:
praat_out=$(guix build -L guix --no-grafts -e '(@ (tay packages praat) praat)')
"$praat_out/bin/praat" --version
make check-praat
```

For a self-contained batch example, generate an original two-second, mono
48 kHz, 440 Hz PCM fixture in a writable working directory, then use Praat's
actual analysis and native-file commands:

```sh
python3 - <<'PY'
import math, struct, wave
samples = [round(32768 * 0.2 * math.sin(2 * math.pi * 440 * n / 48000))
           for n in range(96000)]
with wave.open('original-440hz.wav', 'wb') as sound:
    sound.setparams((1, 2, 48000, 0, 'NONE', 'not compressed'))
    sound.writeframes(struct.pack('<' + 'h' * len(samples), *samples))
PY
cat > analysis.praat <<'PRAAT'
sound = Read from file: "original-440hz.wav"
intensity = Get intensity (dB)
pitch = To Pitch: 0, 75, 600
frequency = Get mean: 0.1, 1.9, "Hertz"
selectObject: sound
Save as binary file: "original.Sound"
reloaded = Read from file: "original.Sound"
Save as WAV file: "reloaded.wav"
writeInfoLine: "frequency_hz=", fixed$ (frequency, 9)
appendInfoLine: "intensity_db=", fixed$ (intensity, 9)
PRAAT
"$praat_out/bin/praat" --FULL-TRUST --run --no-pref-files --no-plugins analysis.praat
```

`--run` is batch mode, not a GUI launch.  On a working graphical display,
open the real SoundEditor with the same fixture and analysis settings:

```sh
cat > editor.praat <<'PRAAT'
sound = Read from file: "original-440hz.wav"
View & Edit
editor: sound
    Show analyses: "yes", "no", "no", "no", "no", 10
    Spectrogram settings: 0, 2000, 0.02, 70
    Zoom: 0.2, 0.3
    Move cursor to: 0.25
endeditor
PRAAT
"$praat_out/bin/praat" --FULL-TRUST --new-send --no-plugins editor.praat
```

The editor shows the waveform and spectrogram from 0.2 to 0.3 seconds with
the cursor at 0.25 seconds; use its normal controls to edit, zoom and save.
For ordinary interactive use, launch `praat` and use **Open → Read from file**,
select the Sound in Objects, then **View & Edit**.  The batch example disables
preferences/plugins; the GUI command disables plugins but can use preferences.
The isolated smoke supplies a fresh HOME/XDG environment for both modes.
`--FULL-TRUST` grants script filesystem/system-command access: use it only for
scripts you trust.

Verified 2026-10-02: the final notice-complete source build produced
`/gnu/store/y3qw2b94d4bdha7jkc65rdw5j14h1j77-praat-7.0.02` and passed both
upstream batch suites.  The explicit channel-package `guix build --check`
rebuild reproduced the output, Praat's no-network lint was clean, and the
integrated `make check-praat` passed.  The real numerical and GTK smoke
retained at `/tmp/omp-praat-published` measured **439.999584949 Hz** and
**76.989675205 dB**
from the generated fixture.  All **96,000 native sample values** round-tripped
exactly through `original.Sound`, and exported WAV PCM was identical.
`runSystem$ ("printf 42")` returned `42`.  The actual SoundEditor displayed
the waveform/spectrogram and reported the requested zoom/cursor state; the
smoke clicked the real pause dialog's **Continue** button, closed the editor
and quit with exit status **0**.  Return selects **Stop** in that dialog and
is not equivalent to Continue.  `result.json`, `editor-info.txt` and
`editor.png` retain the observed values, editor state and real Xvfb capture.
The final editor screenshot is retained at
[`.goocastle/evidence/praat-editor.png`](.goocastle/evidence/praat-editor.png);
it shows the actual waveform, spectrogram, zoom and cursor, not a replacement
UI or a Goocastle execution.
The proof used fresh HOME/XDG state and private user/mount/network/PID
namespaces, with only loopback and physical audio endpoints hidden; before
and after output NAR hashes matched.  This proves software analysis, native
file persistence and the GTK surface, **not physical recording/playback** or
a real desktop session.  No profile or deployed system was changed; no
network OKF catalog update applies to this repository-only integration.

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

### Dualmaster layout plugin

`(tay packages hyprland-dualmaster)` builds `0.55.4-0.1.1` from the local
`guix/tay/packages/files/hyprland-dualmaster/` source. It uses GCC 15 in Release
mode, the compositor's dependency ABI and an exact runtime Hyprland hash
check. The recipe rejects a different Hyprland package version: upgrade and
rebuild together with the compositor, not independently.

```sh
guix build -L ~/projects/guix-channel/guix hyprland-dualmaster --cores=1 --max-jobs=1
guix install -L ~/projects/guix-channel/guix hyprland-dualmaster
```

Load with `plugin = ~/.guix-profile/lib/hyprland/libdualmaster.so` after hy3
in the basedbox config. Select `workspace = N, layout:dualmaster` per workspace;
the package does not change user configuration. The basedbox dotfiles expose
**Right Alt+Y**, release Alt, then **W**, while **M** retains the built-in
half-width centered-master layout. Selection is runtime-only until config
reload/session restart; the default remains dwindle. The workstation Home
package declaration is in `~/src/guix-config/home-workstation-configuration.scm`.

Dualmaster's first two tiled windows share an adjustable centered region,
**60% of usable width by default** (30% per master). Slaves alternate between
left/right 20%-width columns and stack vertically on each side. A single
window occupies the current combined centered width; two masters reserve the
sides even without slaves. Removing a primary promotes the next tiled window.

The existing **Right Alt+right-button drag** `resizewindow` binding follows
built-in master mouse semantics: corner/side-aware direction, smart-resizing
scaling, 5%–95% combined-width clamp and vertical slave sizing. Horizontal
dragging resizes both masters together, keeping them equal with symmetric
sides. Width is per-workspace runtime state and resets on layout recreation
or config reload; no separate master widths or persistent width setting.

Verified 2026-10-02: version 0.1.1 build, scoped user-profile install and exact
ABI-checked load of
`/gnu/store/srab5n9r468z0gz27hqyxq3ggf13sh0w-hyprland-dualmaster-0.55.4-0.1.1`,
without compositor restart or Home/System activation. Selected offline lint
passed. Old two-window horizontal-resize no-op reproduced before replacement.
Actual virtual evdev/uinput Right Alt+right-button/motion exercised both
masters and all four corners through the unchanged binding; IPC confirmed
coupled growth/shrinkage, equal masters/symmetric sides, 5%/95% limits,
default 1/2/3/8-window geometry, smart/non-smart slave redistribution,
single-window/cornerless resizing, fullscreen/maximized guards and workspace
isolation. All active dualmaster workspaces switched to dwindle before unload;
the original 14 clients, workspaces, exact slot order, floating/fullscreen state,
focus/cursor were restored. Workspace 1 remains dualmaster at default 60%
(master clients `x=1076/2588`, width `1506` each); scratch/input removed, no config
errors, hy3 loaded. Resize worker issued no reload or monitor/DPMS commands.
Physical hand-operated dragging/compositor screenshots remain unverified.

**Historical initial 0.1.0 smoke, earlier 2026-10-02:** fixed two-thirds center,
one-third masters and one-sixth sides are superseded by the adjustable 60%
default. Initial store
`/gnu/store/0iym5g7mp415ssr78jrljsgyl7hnrs8x-hyprland-dualmaster-0.55.4-0.1.0`;
real IPC covered 1/2/3/4/6 windows in logical usable `x=65 y=15 w=5040 h=1410`.
Master clients `x=908/2588`, width `1674`; slave clients `x=66/4268`, width `836`;
six-window stacks `y=16/723`, height `701` (gaps/borders included). Fullscreen/
maximized, movement, promotion/removal/addition, slave resizing and virtual
W/M selection passed; scratch removed and baseline layouts restored for that
initial run. These are historical measurements, not current defaults.

### Caelestia shell

#### Persistent native service panes (2026-10-03)

`caelestia-panes` **1.0.0**, local source `apps/caelestia-panes/` and module
`(tay packages caelestia-panes)`, is a C/GTK4 **layer-shell companion** to
Caelestia, not a browser/Kitty scratchpad or foreign-window reparenting.
WebKitGTK 6 supplies the real SilverBullet UI, `GtkTextView` supplies native
Memos capture, and GTK4 VTE supplies a real glirc PTY. The shell's
`caelestia-shell-panes.patch` and small QML control module forward Caelestia
`panes` IPC to `$XDG_RUNTIME_DIR/caelestia-panes.sock` (same-user, 0600).

| Physical chord | Pane | First use |
| --- | --- | --- |
| Right Alt+B | Bottom SilverBullet reader | Complete the real SilverBullet login form; optionally remember the session. |
| Right Alt+M | Top native Memos capture | Authenticate through the genuine rbw re-prompt, then explicitly Submit PRIVATE. |
| Right Alt+I | Left glirc terminal | Click Connect glirc to create a separate client attachment. |

The same chord hides the pane. One pane takes focus at a time; no edge hover
or workspace reservation/retile. Reader/capture Escape hides; chat Escape
and Meta navigation stay with glirc. Physical Left Alt remains application
Meta; Right Alt+S keeps the existing special workspace binding.

The compact panes have no companion title/close header or reader toolbar.
Reader Ctrl+K opens Silversearch; F5/Ctrl+R explicitly reloads or retries
profile setup. F1 shows keyboard help; normal loading/ready feedback is hidden.
Chat's Connect control disappears after a successful start and returns on exit.
Drawers use the scheme's `surface` colour, no outline/shadow, rounded outer
corners and concave 28px joins flush with Caelestia's reserved frame edge.
Their reveal/retract animates on a fixed transparent surface with a shaped
input region; transparent corners do not steal pointer input. GTK >=4.14 is
required for the path clip. Keyboard mode stays EXCLUSIVE through retract
until unmap, avoiding Hyprland 0.55.4's mapped EXCLUSIVE-to-NONE null-focus
path. Hidden content remains allocated as before.

Build/install together from this local channel without activating unrelated
Home/System changes:

```sh
guix build -L ~/projects/guix-channel/guix --cores=2 --max-jobs=1 \
  caelestia-panes caelestia-shell
guix install -L ~/projects/guix-channel/guix caelestia-panes caelestia-shell
python3 ~/.config/hypr/caelestia-session.py ipc panes toggle silverbullet
python3 ~/.config/hypr/caelestia-session.py ipc panes toggle memos
python3 ~/.config/hypr/caelestia-session.py ipc panes toggle chat
python3 ~/.config/hypr/caelestia-session.py ipc panes close
```

The deployed dotfiles supervisor starts `caelestia-panes serve` hidden, checks
its socket readiness before the shell, and retains it when only Quickshell
restarts. It stops task-owned pane processes at session/supervisor exit.
Hide/show retains the same WebView URL/history/search/selection/scroll and
the same glirc process/input/buffer/scrollback; it does not reload or reconnect.
Reader process-restart recovery of arbitrary UI state is not guaranteed.
glirc's current Kitty PTY is **not migrated**: its unsent draft, selection and
scrollback remain untouched. Connect starts a new glirc using existing
`~/.config/glirc/config` (13 ZNC networks, existing verified-IP TLS/pin and
password.command); ZNC MultiClients was read back enabled. Shared history
buffers are not isolated by an optional client identifier. The pane does not
auto-connect/restart glirc; its existing client network policy remains intact.

Memos Enter is newline; Ctrl+Enter / Submit PRIVATE uses verified HTTPS
`https://elitedesk.tail53428b.ts.net:8443/api/v1/memos`. Authenticate uses
an in-pane VTE helper for the existing mandatory rbw prompt, with credential
stdout on a private FD rather than the terminal. It requires the operator's
already-unlocked vault, never unlocks/resets it, and caches a successful PAT
only in memory. Authentication success never auto-submits. One request at a
time disables editing, has a 30-second deadline, and clears the draft only
after HTTP 200, valid `memos/<uid>` and PRIVATE acknowledgement. Cancel/error/
timeout/ambiguous replies preserve it; no automatic write/auth retries or
redirects. Check Memos before deliberately resubmitting an ambiguous request.

Private local state is sensitive **plaintext**, not encryption at rest:

- Reader: `$XDG_STATE_HOME/caelestia-panes/reader/{data,cache}` (default
  `~/.local/state/caelestia-panes/reader/`), directories 0700, cookie file
  `data/cookies.sqlite` 0600; dedicated profile, no inherited browser cookies.
- Memos: `$XDG_STATE_HOME/memos-capture/draft-pane.json`, 0600/parent 0700,
  atomically saved text+cursor and restored on restart. Existing TUI
  `draft.txt` is separate. Unsafe existing storage fails closed.
- Chat scrollback is held by VTE/glirc during this daemon lifetime, not a
  copied/migrated history archive. Credentials are not put in Git/store,
  argv, environment, documentation or logs; vault lock/autolock is unchanged.

The reader deliberately loads **`http://192.168.7.135/`**, LAN HTTP, not TLS.
Login credentials and session cookies are transmitted over HTTP; owner-only
profile permissions protect local storage, not the wire. No SilverBullet
HTTPS endpoint has been established. Silversearch, wiki links and native
topbar Mark read remain the actual service functionality, not a custom search
substitute. Mark read and some installed library commands write wiki files;
hidden editor chrome is not read-only authorization.

Live deployment evidence and exact installed paths are recorded in the
existing `~/src/guix-config/k8-plus-install.md` and OKF
`network/servers/basedbox.md`. Earlier service/browser acceptance is distinct
from this companion: **authenticated pane SilverBullet search/read/Mark read,
native Memos creation and new glirc network authentication are not verified**
without operator login/re-prompt. Phone voice/Wi-Fi-off, route approval and
Second Brain expansion/lint limits remain unchanged.

Pane evidence: `~/.cache/caelestia-panes-smoke-live.json`,
`~/.cache/caelestia-panes-smoke-isolated.json` and adjacent PNG captures.
Live CRT layer/legibility and shell-only persistence were observed; isolated
tests covered layers/toggles, offline glirc and native draft/cursor restore.
Parent scoped no-network Guix lint description/synopsis/input/patch-name
checks exited 0, not the full lint suite. No dedicated pre-pane configuration
backup was established: older profile generations roll back packages only.
Source/live-linked dotfiles migration needs a reviewed manual revert preserving
unrelated edits; never overwrite reader state or either native/TUI draft.


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
make check-praat    # explicit 7.0.02 selection, acoustic/native round trip and isolated real GTK editor
make check-notty    # isolated native installed-library Unix/Lwt consumer, Unicode/colors/input/resize and snapshot NAR integrity
make check-miou     # fresh offline container, native six-library OCaml-5.4.1 consumer and immutable NAR
make check-tui      # installed-jar upstream suite, isolated Unicode/ANSI/cooked-input PTY and immutable package/snapshot NARs
make check-proiel   # canonical Ruby-3.3.9 isolated installed consumer, exact XML/token/edge/valency semantics and immutable NAR
make check-domainslib # isolated native concurrent task/parallel-array/channel proof with exact oracles and immutable NAR
make check-emacs-vim-region # isolated batch and real terminal Emacs keymap editing, exact buffer/active-region state and immutable files
make check-org-mind-map # isolated installed Emacs/Graphviz export, exact SVG nodes/edges/text/tags/images and viewport bounds
make check-hack # isolated three original 80x24 PTYs, actual movement/inventory, consumed saves, exact independent restores and read-only NAR
make check-hackem # build/repro/runtime/lint observed: three native moves/saves, full state continuity, two exact restores
make check-hellcrawl # build/repro/runtime/lint observed: native dungeon/save/restore/continued turns and NAR integrity
make check-wired # build/repro/runtime/lint observed: private D-Bus/Xvfb Notify/render/close/--kill and store integrity
make check-scala-ts # build/repro/runtime/lint observed: strict compiled Option/Either/Try/collection consumer and unchanged NAR
make check-crashrun # build/repro/runtime/lint passed: SDL creation/inventory/turn/save/load/resave and immutable output
make check-dungeon-monkey-unlimited # final build/repro/runtime/lint passed: GUI creation/movement/save/restore/continued play
make check-emigo # build/repro/native/lint passed: real loopback EPC/context/tokenizer/parser/path errors and TLS trust; no provider/chat UI proof
make check-kraken # final build/repro/lint/integrated offline CPU text+hOCR exact reference/export passed; ketos discovery only
make check-gened # final build/repro/lint/standalone+integrated native exact text edit/save/reopen/resave passed
make check-soundthread # final build/repro/lint/native WAV import/graph roundtrip/render/real Master-bus PCM passed; Dummy driver, no CDP/host audio
make check-cotd # final build/repro/lint/standalone+integrated native campaign day advance/save/restore passed; no tactical combat
make check-emacs-application-framework # final build/repro/lint/standalone+integrated GUI/demo/IPC/theme/resize/shutdown passed
make check-eca # final build/repro/lint/integrated+exact ungrafted local server/client proof passed; no provider
make check-pi-coding-agent # final build/repro/lint/exact ungrafted+integrated offline RPC/Bash/session/HTML export/PTY passed; no provider
make check-squad # final build/repro/lint/standalone+integrated native init/copy-mode/routing/casting/SQLite/PTY/FFI passed; no Copilot
make check-oh-my-opencode-slim # final build/repro/lint/standalone+integrated actual OpenCode agents/tools/skills/default+project override/idle state passed; zero prompts
make check-oh-my-opencode-slim-companion # final build/repro/lint/standalone+integrated actual GUI passed; separate local busy fixture, no provider
make check-aiwnios # final build/repro/lint/native+integrated repeated bootstrap/HolyC42,55,branches,720/status23/typed SDL42/FileWrite/NAR passed
make check-aiwnios-bytecode # final build/repro/lint/native+integrated same genuine repeated bootstrap/HolyC/typed SDL42/FileWrite/NAR passed
make check-wrogue # final build/repro/lint/standalone+integrated native create/save/exact Continue/move/second restore/NAR passed
make check-babel7drl # final build/repro/lint/standalone+integrated native login/help/move/climb feedback/death/reconnect/NAR passed; no floor advancement/save-resume
make check-smiths-hand # final build/repro/lint/standalone+integrated real wait/Q save/fresh byte-identical restore/inventory-topology/NAR passed
make check-tetraworld # final build/repro/lint/27tests/standalone+integrated4sessions entire save1=2/3=4 exact/turn1→2/HUD/live screenshot passed
make check-splicehack-rewrite # final full11dungeon archive/Guidebook build/repro/lint/native+integrated3games/two exact restores/live screenshot/NAR passed
make check-space-privateers # final build/repro/lint/engine1of1/native+integrated real wait/moves/two exact visible-state restores/live screenshot/NAR passed; hidden state not fully decoded
make check-slashem # final build/repro/lint/native+integrated3sessions/two exact restores/live screenshot/NAR passed
make check-shamogu # final build/repro/lint/TestGame/native+integrated turns0/1/1/2/2/two exported-state+map/HUD attrs exact restores/native Q/Y save deletion passed
make check-revengate # final ownership-fix build/repro/lint/3x1000sim/native+integrated movement/save/restart/resume/clean ExitGame0/noerrors/NAR passed; selected state fields only
make check-plomrogue # final build/repro/lint/original oracle/native+integrated two exact restores/90vs45reload45 fullsave+RNG/live screenshot/NAR passed
make check-obumbrata # final build/repro/lint/native+integrated moves/Ssave/two exact persisted-state restores/live screenshot/NAR passed; RNG not serialized
make check-lambdahack # final build/repro/lint/original suite+benchmark/native+integrated two selected-state restores/continued moves/clean exits/live screenshot/NAR passed
make check-kimchi # final build/repro/lint/original stress/native+integrated waits/save/restore/continued turn/Hangul/live screenshots/NAR passed
make check-keeperrl # final build/repro/lint/repaired upstream suite/native+integrated campaign waits/two exact clock restores/native quits/independent profile/live screenshot/NAR passed
make check-gearhead2 # final build/repro/lint/native+integrated two pilots/two full canonical serialized restores/exact effective mapHUD/movement/quit/live screenshot/NAR passed
guix shell guix make python python-pyte coreutils findutils util-linux xorg-server xterm xdotool imagemagick font-dejavu -- make check-gearhead GEARHEAD_OUTPUT="$gearhead_out" GEARHEAD_EVIDENCE=/tmp/gearhead-integrated-FRESH # final build/repro/lint/native+integrated creation/movement/selected state+clock restore/quit/live screenshot/NAR passed
make check-fiqhack FIQHACK_OUTPUT="$fiqhack_out" FIQHACK_EVIDENCE=/tmp/fiqhack-integrated-FRESH # final build/repro/lint/1000TAP/native+integrated two identity+gamestate-record restores/movement/quit/live screenshot/NAR passed
make check-evilhack EVILHACK_OUTPUT="$evilhack_out" EVILHACK_EVIDENCE=/tmp/evilhack-integrated-FRESH # final corrected build/repro/lint/native+integrated valid compressed saves/two exact public-state restores/continued moves/quit/live screenshot/NAR passed
make check-dynahack DYNAHACK_OUTPUT="$dynahack_out" DYNAHACK_EVIDENCE=/tmp/dynahack-integrated-FRESH # final build/repro/lint/native+integrated movement/two fixed-field+committed-log restores/no-turn binary re-save/quit/live screenshot/NAR passed
make check-alone-rl ALONE_RL_OUTPUT="$alone_out" ALONE_RL_EVIDENCE=/tmp/alone-rl-integrated-FRESH # self-resolved proof deps/prebuilt output/new-empty evidence; final gates pending
make check-allure ALLURE_OUTPUT="$allure_out" ALLURE_EVIDENCE=/tmp/allure-integrated-FRESH # self-resolved proof deps/genuine SDL two-restore gameplay, not null benchmark; final build/upstream tests/repro/lint/native+integrated/NAR passed
make check-lbforth # installed native arithmetic/control flow/recursion and error recovery from empty private cwd; python3 required, immutable output
make check-legcord # real native onboarding/settings and Discord logged-out cold-relaunch surface, sandbox and unchanged NAR; no credentials/login/live audio
make check-axmud    # Xvfb setup plus namespaced loopback Telnet/GMCP log smoke
make check-blightmud # channel-pinned Guix plus fresh-HOME PTY protocol/TLS smoke
make check-image-tape # Guix-toolchain output-safety regression; no tape hardware
make check-klh10    # three isolated native CPU/console PTYs, exact word/disk/tape-image roundtrips and NAR integrity
make check-suppty   # isolated RFC734 CLI/GTK handshake, location, real keyboard roundtrip, EOF and NAR integrity
make check-itstar   # isolated byte-exact DUMP create/list/extract/append, compressed input and independent SIMH/TM03 fixture
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
make check-stoat-soup # isolated real console PTYs, three waits, exact native save/restore, continued turn/re-save and NAR integrity
make check-rapidbrogue # fresh evidence, original SDL/terminal native save/resume and NAR integrity
make build-fontra   # local --no-grafts --no-offload build
make check-apout APOUT_OUTPUT="$(guix build -L guix --no-grafts apout)" APOUT_EVIDENCE=/tmp/apout-native-new # original lawful V7 guest CPU/syscall proof
make check-blincolnlights BLINCOLNLIGHTS_OUTPUT="$(guix build -L guix --no-grafts blincolnlights)" BLINCOLNLIGHTS_EVIDENCE=/tmp/blincolnlights-native-new # isolated real SDL PDP-1 panel/PDP-5 deposit, examine and coremem restore
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
make check-robotfindskitten # isolated actual native PTY movement, installed NKI description, kitten win/exit and unchanged NAR
make check-nlarn # isolated native 100x30 PTYs, exact HUD/items restore, further movement/turn/resave and unchanged NAR
make check-unnethack # isolated three native 100x24 TTYs, exact HUD/map/items restore, save consumption and further turns/resaves
make check-grunthack # isolated three native 100x24 TTYs, movement/search turns, exact HUD/map/items restore and consumed saves/resaves
make check-nitrohack # isolated three native 100x30 curses sessions, original menus, movement/search, exact HUD/map/items restore and same-file resaves
make check-hermes-desktop # actual installed backend plus Electron/Xvfb surface, writable config, Guix update refusal, sandbox and NAR checks; no real model/GPU/microphone proof
make check-sentinelone # no SentinelOne artifact/vendor network; free deps may use substitutes
make lint           # offline/local linters; no source-URL network checks
make lint-cve       # optional network-backed CVE database pass
make build          # default native free packages (not sentinelone or i686-only CalcRogue)
make build-calcrogue # explicit --system=i686-linux source build
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
