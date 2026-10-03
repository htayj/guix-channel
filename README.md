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
| `emacs-vim-region` | ongaeshi/emacs-vim-region `7c4a99c` | GPL-3.0-or-later Vim-style region selection/editing with propagated expand-region; source-header grant retained |
| `org-mind-map` | the-ted/org-mind-map `95347b2` | GPL-3.0-or-later original Emacs Org graph exporter, propagated Dash and store-bound Graphviz; SVG viewport correction, unlicensed example images excluded |
| `terminaldrome` | thafaker/TerminalDrome | Rust terminal client for Navidrome and Subsonic servers |
| `image-tape` | larsbrinkhoff/image-tape | Magnetic-tape image reader with safe output handling |
| `klh10` | PDP-10/klh10 `6d733f2` | Source-built KL10/KS10 host emulator, console, disk/tape helpers and image converters; custom eight-clause Free-Fork license, modified source/notices included; no guest systems or network services |
| `pdp10-suppty` | PDP-10/SUPPTY `2da0135` | MIT/Expat source-built GTK 2 `suppty` and CLI `suppty-plink`; original SUPDUP host clients, namespaced commands/manuals; only isolated local SUPDUP runtime verified, not old-SSH security |
| `itstar` | PDP-10/itstar V1.10 (`b709cd8`) | GPL-3.0-or-later native ITS DUMP image create/list/extract/append tool, store-bound gzip and relicensing permission; remote rmt disabled, physical tape untested |
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
