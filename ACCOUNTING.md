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
