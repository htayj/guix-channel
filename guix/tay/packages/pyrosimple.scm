;;; GNU Guix package for kannibalox/pyrosimple and its missing Python helpers.

(define-module (tay packages pyrosimple)
  #:use-module ((tay packages starred-i-m)
                #:select (kannibalox-pyrosimple-source))
  #:use-module (guix build-system pyproject)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module ((gnu packages check) #:select (python-pytest))
  #:use-module ((gnu packages monitoring) #:select (python-prometheus-client))
  #:use-module ((gnu packages python-build)
                #:select (python-pbr python-poetry-core python-setuptools
                          python-tomli-w))
  #:use-module ((gnu packages python-web) #:select (python-requests))
  #:use-module ((gnu packages python-xyz)
                #:select (python-apscheduler python-box python-daemon
                          python-inotify python-jinja2 python-prompt-toolkit
                          python-regex python-shtab)))

(define python-lockfile
  (package
    (name "python-lockfile")
    (version "0.12.2")
    (source
     (origin
       (method url-fetch)
       (uri (pypi-uri "lockfile" version))
       (sha256
        (base32 "16gpx5hm73ah5n1079ng0vy381hl802v606npkx4x8nb0gg05vba"))))
    (build-system pyproject-build-system)
    (arguments
     (list
      ;; The sdist's compliance tests are nose-style classes with setup and
      ;; teardown methods, which current pytest no longer collects.  Drive
      ;; every Test* class method directly instead.
      #:test-backend #~'custom
      #:test-flags
      #~(list "-c" "
import inspect, sys
sys.path.insert(0, 'test')
import test_lockfile
ran = 0
for name, cls in sorted(vars(test_lockfile).items()):
    if not (inspect.isclass(cls) and name.startswith('Test')):
        continue
    for method in sorted(m for m in dir(cls) if m.startswith('test_')):
        case = cls()
        case.setup()
        try:
            getattr(case, method)()
        finally:
            case.teardown()
        ran += 1
assert ran > 0, 'no lockfile tests ran'
print(ran, 'lockfile compliance tests passed')
")))
    (native-inputs (list python-pbr python-setuptools))
    (home-page "https://launchpad.net/pylockfile")
    (synopsis "Platform-independent file locking module")
    (description
     "The lockfile package exports a @code{LockFile} class which provides a
simple API for locking files, with link, mkdir, SQLite and PID-file based
implementations.  It is retained for software such as pyrotorque that still
imports @code{lockfile.pidlockfile}.")
    (license license:expat)))

;;; Guix patches python-daemon to use filelock, whose TimeoutPIDLockFile has
;;; neither a callable is_locked nor read_pid; pyrotorque calls both.  Use the
;;; unmodified upstream 3.1.2 release, which pyrosimple's lock file also pins,
;;; with its declared lockfile dependency.
(define python-daemon-for-pyrosimple
  (package
    (inherit python-daemon)
    (source
     (origin
       (inherit (package-source python-daemon))
       (patches '())))
    (propagated-inputs (list python-lockfile))))

(define python-bencode.py
  (package
    (name "python-bencode.py")
    (version "4.0.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/fuzeman/bencode.py")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "14famvp349mxpbnp61w1yjprf2hinpbqq9c65b1399s938caqaxw"))))
    (build-system pyproject-build-system)
    (arguments (list #:test-flags #~(list "tests")))
    (native-inputs (list python-pbr python-pytest python-setuptools))
    (home-page "https://github.com/fuzeman/bencode.py")
    (synopsis "Bencode encoder and decoder for Python")
    (description
     "bencode.py encodes and decodes the bencode serialization format used by
BitTorrent metainfo files.  It provides the @code{bencode} and
@code{bencodepy} modules, including file helpers and decode errors.")
    ;; The exact LICENSE file is the BitTorrent Open Source License 1.1.
    (license (license:fsf-free "file://LICENSE"
                               "BitTorrent Open Source License, version 1.1"))))

(define python-parsimonious
  (package
    (name "python-parsimonious")
    (version "0.10.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/erikrose/parsimonious")
             (commit version)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1lbi2wpjgfl48zsm2qsx9n7rah1kcwy4iahb8f3s94nb4ynykdgd"))))
    (build-system pyproject-build-system)
    (arguments
     ;; The benchmark tests compare wall-clock timings and are not stable on
     ;; loaded build machines.
     (list #:test-flags
           #~(list "parsimonious/tests"
                   "--ignore=parsimonious/tests/test_benchmarks.py")))
    (propagated-inputs (list python-regex))
    (native-inputs (list python-pytest python-setuptools))
    (home-page "https://github.com/erikrose/parsimonious")
    (synopsis "Pure-Python parsing expression grammar parser")
    (description
     "Parsimonious parses text with grammars written in a simplified parsing
expression grammar syntax, builds parse trees and provides visitors for
turning them into application data.")
    (license license:expat)))

(define-public pyrosimple
  (let ((commit "d24655a708059d322633e361e2e204983e51f491")
        (revision "16"))
    (package
      (name "pyrosimple")
      ;; The pinned revision is 16 commits after the v2.14.2 tag; upstream
      ;; metadata still declares 2.14.2.
      (version (git-version "2.14.2" revision commit))
      (source (package-source kannibalox-pyrosimple-source))
      (build-system pyproject-build-system)
      (arguments
       (list
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'unpack 'relax-prometheus-client
              ;; Poetry's caret pins prometheus-client below 0.17, but the
              ;; counters, summaries and WSGI exposition helpers used here are
              ;; present in Guix's newer client.
              (lambda _
                (substitute* "pyproject.toml"
                  (("prometheus-client = \"\\^0\\.16\\.0\"")
                   "prometheus-client = \">=0.16.0\""))))
            (add-after 'unpack 'honour-mktor-no-date
              ;; mktor only skips re-adding the timestamp, while
              ;; Metafile.from_path still stores one; pass the option through
              ;; so --no-date really omits "creation date".
              (lambda _
                (substitute* "src/pyrosimple/scripts/mktor.py"
                  (("created_by=\"PyroSimple\",")
                   "created_by=\"PyroSimple\",
            no_date=self.options.no_date,"))))
            (add-before 'check 'disable-live-tests
              ;; Live tests contact an rTorrent instance; keep them skipped.
              (lambda _
                (setenv "PYTEST_PYRO_LIVE" "false")))
            (add-after 'wrap 'install-pyrosimple-launcher
              ;; Upstream installs no "pyrosimple" command.  Provide one for
              ;; rtcontrol, the main query tool, after wrapping so it reuses
              ;; rtcontrol's GUIX_PYTHONPATH wrapper.
              (lambda _
                (with-directory-excursion (string-append #$output "/bin")
                  (symlink "rtcontrol" "pyrosimple"))))
            (replace 'install-license-files
              (lambda _
                (install-file "COPYING"
                              (string-append #$output
                                             "/share/doc/pyrosimple")))))))
      (propagated-inputs
       (list python-apscheduler
             python-bencode.py
             python-box
             python-daemon-for-pyrosimple
             python-inotify
             python-jinja2
             python-parsimonious
             python-prometheus-client
             python-prompt-toolkit
             python-requests
             python-shtab
             python-tomli-w))
      ;; setuptools lets the sanity check load all seven console entry points.
      (native-inputs
       (list python-poetry-core python-pytest python-setuptools))
      (home-page "https://github.com/kannibalox/pyrosimple")
      (synopsis "Command-line tools for rTorrent and BitTorrent metainfo files")
      (description
       "Pyrosimple is a Python 3 fork of the pyrocore tools for working with
the rTorrent client.  It provides @command{rtcontrol} for querying and acting
on downloads, @command{rtxmlrpc} for raw XML-RPC calls,
@command{pyrotorque} for queue and watch jobs, @command{pyroadmin} for
configuration helpers, and the offline metainfo tools @command{mktor},
@command{lstor} and @command{chtor}.  This package also installs a
@command{pyrosimple} command that runs @command{rtcontrol}.")
      (license license:gpl3+))))
