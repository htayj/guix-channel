# Taylor's Guix channel

This channel packages the public GitHub projects owned by
[`htayj`](https://github.com/htayj).  Every non-empty owned repository is
available as an immutable source package, pinned to a full commit and a real
Guix/NAR hash.  Source snapshots preserve submodule pointers but do not fetch
submodule contents.  Projects with reviewed, redistributable release artifacts
also have directly usable packages.

The initial inventory was taken on 2026-08-14.  It covers 38 owned public
repositories: 37 pinned source packages and one empty repository with no commit
to package.  Public forks are intentionally excluded because this channel does
not present other maintainers' projects as Taylor's work.  See
[`PROJECTS.md`](PROJECTS.md) for the complete disposition ledger.

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
guix install -L . genera-fonts-symbols
guix build -L . htayj-ivory-key-source
```

Source snapshots install below `share/htayj/projects/REPOSITORY`.  They are
development and preservation inputs, not claims that every repository has a
standalone executable.  Repositories without an explicit license carry a
custom no-permission marker; do not redistribute those package outputs or
publish substitutes for them without a separate rights review.

## Directly usable packages

| Package | Upstream | Contents |
| --- | --- | --- |
| `cadr-fonts-latin` | CADR-fonts 0.1.2 | Unicode BDF and OTB Latin fonts |
| `cadr-fonts-symbols` | CADR-fonts 0.1.2 | Unicode BDF and OTB specialty fonts |
| `dec-fonts` | DEC-Fonts 0.1.0-alpha.2 | BDF, OTB, and Linux-console PSF fonts |
| `genera-fonts-latin` | genera-fonts 0.1.1 | Unicode BDF and OTB Latin fonts |
| `genera-fonts-symbols` | genera-fonts 0.1.1 | Unicode BDF and OTB specialty fonts |

The font packages consume immutable generic GitHub Release archives rather
than repackaging `.deb`, RPM, Arch, or XBPS artifacts.  CADR and DEC releases
carry their upstream licenses.  Genera packages preserve the project's
separate BSD-3-Clause code/documentation license and required typeface
publication notice; that notice is not represented as an upstream license
grant.

## Validate

```sh
make check          # resolve packages; run deterministic/local linters
make lint-cve       # optional network-backed CVE database pass
make build          # build the five directly usable packages
make build-sources  # fetch and build all 37 source snapshots
```

The first signed commit authorizes subsequent channel commits through
`.guix-authorizations`.  The authorized OpenPGP fingerprint is
`997E 2BA6 B523 4026 8A39 87E3 D94F 0A11 ACD7 8333`.
