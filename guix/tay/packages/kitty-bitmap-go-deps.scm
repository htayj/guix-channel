;;; Channel-private Go module dependencies for kitty-bitmap.
;;;
;;; kitty-bitmap pins Kitty 0.48.2's source, but inherits its dependency
;;; graph from the rolling Guix `kitty' package.  Upstream Guix added
;;; go-github-com-emmansun-base64 and go-github-com-sgtdi-fswatcher as kitty
;;; inputs on 2026-08-26 (after the 2026-08-17 Guix revision this channel's
;;; host first shipped), so a kitty-bitmap build against an older Guix fails
;;; with `cannot find package' for exactly these two modules.  These
;;; channel-local definitions (copied from Guix 0bff26c, where upstream first
;;; packaged them) let kitty-bitmap build against both older and current Guix
;;; revisions.  They are verbatim apart from fswatcher's disabled tests and
;;; dropped test-only input, documented at that package.
;;;
;;; The package `name' fields carry a distinct "-kitty-bitmap" suffix so the
;;; definitions cannot collide with upstream Guix's identically-named
;;; specifications on newer revisions.  The mandatory "go-" prefix is what
;;; go-build-system's setup-go-environment uses to recognize Go inputs and
;;; union them onto GOPATH, so it must not be dropped; the suffix keys
;;; nothing and the Go module resolution still follows #:import-path.

(define-module (tay packages kitty-bitmap-go-deps)
  #:use-module (guix build-system go)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages golang-build)
  #:export (kitty-bitmap-go-emmansun-base64
            kitty-bitmap-go-sgtdi-fswatcher))

(define kitty-bitmap-go-emmansun-base64
  (package
    (name "go-github-com-emmansun-base64-kitty-bitmap")
    (version "0.10.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
              (url "https://github.com/emmansun/base64")
              (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0mkkk9xhc55jfq1nbavb8vivv2xb8sp0l807ci0ak3aimxxjqj9c"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/emmansun/base64"))
    (propagated-inputs (list go-golang-org-x-sys))
    (home-page "https://github.com/emmansun/base64")
    (synopsis "SIMD-accelerated drop-in replacement for Go's encoding/base64")
    (description
     "Package base64 implements base64 encoding as specified by
@url{https://rfc-editor.org/rfc/rfc4648.html, RFC 4648}.  This package keeps
the same public API and behavior as Go's standard @code{encoding/base64},
while using architecture-specific SIMD implementations where available.")
    (license license:bsd-3)))

(define kitty-bitmap-go-sgtdi-fswatcher
  (package
    (name "go-github-com-sgtdi-fswatcher-kitty-bitmap")
    (version "1.3.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
              (url "https://github.com/sgtdi/fswatcher")
              (commit (string-append "v" version))))
       (file-name (git-file-name name version))
       (sha256
        (base32 "134swn5x2g0dn8nn48f66r49h5mxfl8yrwrlmkargl25mi7yw383"))))
    (build-system go-build-system)
    (arguments
     (list
      #:import-path "github.com/sgtdi/fswatcher"
      ;; Upstream's suite is a live file-system watcher test: it drives real
      ;; inotify/fanotify syscalls, then asserts on events that arrive within
      ;; fixed sleeps (`TestWatcher/Watch' performs 500 random operations and
      ;; allows 6 seconds for every one of them to be observed).  What it
      ;; actually measures is the builder's kernel, scheduler and inotify
      ;; limits, so the same derivation passes on one machine and fails on
      ;; another.  `TestFanotify_Backend' is the sharpest edge: it gates on
      ;; `os.Getuid() != 0' rather than probing for CAP_SYS_ADMIN, so on a
      ;; guix-daemon that builds as root it runs anyway and fails with
      ;; "Should have received an event for the file using fanotify" -- the
      ;; build container cannot resolve a path from a fanotify file handle.
      ;;
      ;; kitty-bitmap consumes this package purely as Go source on Kitty's
      ;; GOPATH, so its runtime watch behaviour is never exercised here; only
      ;; the code compiling and exposing the API Kitty imports matters.  The
      ;; `build' phase still runs `go install', which type-checks the whole
      ;; package, and tests/kitty-bitmap-clean-old-guix-build.sh adds the
      ;; import proof that Kitty's own `tools/watch' can resolve it.
      #:tests? #f))
    ;; No native-inputs: upstream lists go-github-com-stretchr-testify only to
    ;; run the suite disabled above, and dropping it keeps testify's own
    ;; transitive closure out of this build.
    (propagated-inputs
     (list go-golang-org-x-sys))
    (home-page "https://github.com/sgtdi/fswatcher")
    (synopsis "File watcher for Go with built-in debouncing and filtering")
    (description
     "FSWatcher is a robust and concurrent file system watcher for Go.  It
provides a simple and powerful API to monitor directories for file system
changes, designed for high-performance applications and development tools.")
    (license license:expat)))
