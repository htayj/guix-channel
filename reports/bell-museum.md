# Bell Museum packaging disposition

`bell-museum` packages commit
`15f0093f4a9808580b09d8d77c018d57961ee635` of
`https://github.com/htayj/bell-museum`, using the verified Guix NAR hash
`102j7nmnwwxv70l499lp2cq3a9ljy99pk0fy6p05ylm6dssvivkw`.  It installs the
MIT-licensed museum documentation, its seven reference specimen images, and
`bell-museum-render-inferno-specimens`.  The command forwards the renderer's
explicit `--source` and `--output` arguments and makes no network request.

## Pinned submodule disposition

The top-level tree has a gitlink at `sources/inferno-1e1`, pinned to
`a3c06a9d046c66c83120a4eed91b82dc674719f6`.  Its full checkout has the
independently verified NAR hash
`0in2snyhjs26rgrkxanbz960mgvias8kgm45i58l6ljg300s34g0`, but is deliberately
not an origin or build input of this package.

This is not an accidental missing-submodule case:

- The non-recursive repository snapshot lacks `sources/inferno-1e1` entirely.
- `.gitmodules` names `git@github.com:inferno-os/inferno-1e1.git`; making the
  source origin recursive would introduce SSH-based submodule acquisition.
- The checkout's `NOTICE` offers MIT terms by default, but its retained
  `LICENSE.orig` is a Lucent limited-use agreement granting only a personal,
  non-transferable internal-evaluation right and limiting reproduction and
  distribution.  The `NOTICE` expressly permits directory/file exceptions.

Shipping that tree needs a rights review that resolves the contradictory,
file-level licensing evidence.  Until then, users who are authorized to hold a
checkout can give its local path to the installed renderer; the package does
not download, copy, or expose it.

## Validation

- `guix lint -L .` with the local structural and semantic checkers passed.
  Guix's default updater checker reports that the documentation repository has
  no release tags; that is not a package-definition error.
- `guix build -L . bell-museum` succeeded.
- The installed renderer regenerated all eight tracked outputs from the
  separately inspected pinned checkout, `--check` reported them current, and
  `diff -ru` confirmed byte-for-byte equality with the packaged reference
  assets.
