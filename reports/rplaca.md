# RPLACA package validation blockers

`sbcl-rplaca` builds from the immutable
`htayj-rplaca-source-20260729-1.7cffbb8` package source and its installed
launcher loads the compiled ASDF system without Quicklisp.  The complete
upstream FiveAM suite was run outside the derivation with a writable temporary
ASDF cache:

```
Did 5915 checks.
   Pass: 5904 (99%)
   Skip: 0 ( 0%)
   Fail: 11 ( 0%)
```

The failures are not hidden by the package's disabled standard check phase:
the upstream `rplaca/tests` ASDF system has no `test-op` method, and its
subprocess tests hard-code a Quicklisp launcher.  Running the suite requires a
writable ASDF output cache because the installed output is immutable.

* Three failed assertions in
  `PINNED-MCCLIM-WORD-KILL-CAN-BE-YANKED`: Guix's packaged McCLIM 0.9.9 does
  not allow the expected `IE-ERASE-WORD` and `IE-YANK-KILL-RING` behavior.
* Two compose-pane tests fail because the supplied ESA/Drei systems reject the
  `:ACTIVATION-GESTURES`, `:BORDER-WIDTH`, `:SCROLL-BARS`, `:NLINES`, and
  `:NCOLUMNS` initargs.  These systems are bundled with Guix's McCLIM package;
  they are not separate Guix packages.
* Six crash-report and session-migration assertions fail because their spawned
  scripts require `RPLACA_QUICKLISP_SETUP`.  Adding Quicklisp to a Guix package
  would make the build and runtime depend on a mutable, network-resolved
  distribution, so the package deliberately uses the packaged ASDF dependency
  closure instead.

The package's GUI launcher and core ASDF load are usable with the supplied
Guix dependencies.  Resolving the remaining suite failures requires either
upstream compatibility changes for the packaged McCLIM version or a separately
packaged, immutable replacement for the Quicklisp subprocess harness.
