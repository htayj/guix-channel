;;; Autolith -- locked Common Lisp dependencies and matching compiler.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages autolith-dependencies)
  #:use-module (guix build-system asdf)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system trivial)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages rust-apps)
  #:use-module (gnu packages virtualization)
  #:use-module (srfi srfi-1)
  #:use-module (tay packages autolith-native)
  #:use-module (gnu packages lisp)
  #:use-module (gnu packages lisp-check)
  #:use-module (gnu packages lisp-xyz))

;; Keep the archive byte-for-byte identical to sbcl-source.sha256.  In
;; particular, the source exposed to the debugger is not Guix's patched tree.
(define %autolith-sbcl-origin
  (origin
    (method url-fetch)
    (uri "mirror://sourceforge/sbcl/sbcl/2.6.6/sbcl-2.6.6-source.tar.bz2")
    (sha256
     (base32 "0jx3gppml428fl5h1ihik73jgx8hx2wvk4hibn959brah4q7lnm6"))))

(define-public sbcl-autolith-runtime
  (package
    (inherit sbcl)
    (name "sbcl-autolith-runtime")
    (version "2.6.6")
    (source %autolith-sbcl-origin)
    (inputs
     (map (lambda (input)
            (if (string=? (car input) "zstd")
                (cons "zstd:lib" (cdr input))
                input))
          (package-inputs sbcl)))))

(define-public autolith-sbcl-source-tree
  (package
    (inherit sbcl-autolith-runtime)
    (name "autolith-sbcl-source-tree")
    (outputs '("out"))
    (build-system trivial-build-system)
    (arguments
     (list #:modules '((guix build utils))
           #:builder
           #~(begin
               (use-modules (guix build utils))
               (setenv "PATH" (string-append #$bzip2 "/bin"))
               (mkdir-p #$output)
               (invoke #$(file-append tar "/bin/tar")
                       "xf" #$%autolith-sbcl-origin
                       "--strip-components=1" "-C" #$output))))
    (native-inputs '())
    (inputs '())
    (synopsis "Exact SBCL source for Autolith's debugger")
    (description
     "This package installs the unmodified SBCL source matching Autolith's
pinned runtime, for source-aware debugging and compiler introspection.")))

;; The locked SSL revision must also replace the one below Dexador and its
;; test dependencies.  Retain Guix's OpenSSL store-path and coverage-cycle fixes.
(define %autolith-cl+ssl
  (package
    (inherit sbcl-cl+ssl)
    (name "sbcl-autolith-cl+ssl")
    (home-page "https://cl-plus-ssl.common-lisp.dev/")
    (version (git-version "0.0.0" "0" "d7a92f9ed0cbae10f07b1b9a9c3c5cc179798748"))
    (source
     (origin
       (method url-fetch)
       (uri "https://codeload.github.com/cl-plus-ssl/cl-plus-ssl/tar.gz/d7a92f9ed0cbae10f07b1b9a9c3c5cc179798748")
       (file-name "cl+ssl-d7a92f9ed0cbae10f07b1b9a9c3c5cc179798748.tar.gz")
       (sha256 (base32 "0c9nwrqkmvcqm89qq1241fi7rz8slil9xrjvyw7w6nfli5md10p7"))))
    (arguments
     (substitute-keyword-arguments (package-arguments sbcl-cl+ssl)
       ((#:asd-systems _ ''("cl+ssl")) ''("cl+ssl"))
       ((#:asd-test-systems _ ''("cl+ssl")) ''("cl+ssl"))
       ((#:phases phases)
        #~(modify-phases #$phases
            (add-after 'unpack 'omit-external-network-tests
              (lambda _
                ;; Only this suite contacts badssl.com.  ALPN's external test
                ;; is already opt-in upstream; keep local TLS/certificate tests.
                (unsetenv "TEST_ALPN")
                (substitute* "cl+ssl.test.asd"
                  (("\\(:file \"badssl-com\"\\)") ""))))))))))

;; YASON 0.8.4 changed the configurable TRUE/FALSE/NULL parser bindings used
;; by Argo.  Keep the exact Quicklisp release from Autolith's lock everywhere.
(define %autolith-yason
  (package
    (inherit sbcl-yason)
    (name "sbcl-autolith-yason")
    (version "0.8.3-0.20250622")
    (source
     (origin
       (method url-fetch)
       (uri "https://beta.quicklisp.org/archive/yason/2025-06-22/yason-20250622-git.tgz")
       (sha256
        (base32 "0nszm981p8xhgny0g12dy3p5bsni76rmdfxhwfc9hzg94c6m91mh"))))
    (arguments
     (list #:asd-systems ''("yason")
           #:asd-test-systems ''("yason")))
    (native-inputs (list sbcl-unit-test))))
;; Secondary systems defined in a primary .asd must share its slash prefix.
;; Fix the definitions and their consumers, rather than hiding ASDF warnings
;; when the application loads these transitive dependencies in a fresh image.
(define %autolith-ieee-floats
  (package
    (inherit sbcl-ieee-floats)
    (arguments
     (substitute-keyword-arguments (package-arguments sbcl-ieee-floats)
       ((#:phases phases #~%standard-phases)
        #~(modify-phases #$phases
            (add-after 'unpack 'name-secondary-system
              (lambda _
                (substitute* "ieee-floats.asd"
                  (("ieee-floats-tests") "ieee-floats/tests"))
                (substitute* "doc/index.html"
                  (("ieee-floats-tests") "ieee-floats/tests"))))))))))

(define %autolith-parse-float
  (package
    (inherit sbcl-parse-float)
    (arguments
     (substitute-keyword-arguments (package-arguments sbcl-parse-float)
       ((#:asd-systems _)
        ''("parse-float" "parse-float/tests"))
       ((#:phases phases #~%standard-phases)
        #~(modify-phases #$phases
            (add-after 'unpack 'name-secondary-system
              (lambda _
                ;; Keep the Lisp package and component file names unchanged.
                (substitute* "parse-float.asd"
                  (("defsystem #:parse-float-tests")
                   "defsystem #:parse-float/tests")
                  ((":name \"parse-float-tests\"")
                   ":name \"parse-float/tests\""))))))))))


;; Stop at non-Lisp tools: changing the Lisp compiler must not rebuild the
;; bootstrap compiler, shell, or native toolchain.  package-mapping memoizes
;; this closure, so every shared ASDF dependency has one compiler identity.
(define (autolith-input-labels inputs)
  ;; package-mapping preserves labels when it substitutes packages.  Rename
  ;; only the overridden YASON edge; leave every other package label intact.
  (map (lambda (input)
         (if (and (string=? (car input) "sbcl-yason")
                  (eq? (cadr input) sbcl-yason))
             (cons "sbcl-autolith-yason" (cdr input))
             input))
       inputs))

(define-public autolith-lisp-package
  (package-mapping
   (lambda (original)
     (let ((p (cond ((eq? original sbcl-cl+ssl) %autolith-cl+ssl)
                    ((eq? original sbcl-yason) %autolith-yason)
                    ((eq? original sbcl-ieee-floats) %autolith-ieee-floats)
                    ((eq? original sbcl-parse-float) %autolith-parse-float)
                    (else original))))
       (if (eq? (package-build-system p) asdf-build-system/sbcl)
           (package
             (inherit p)
             (inputs (autolith-input-labels (package-inputs p)))
             (native-inputs (autolith-input-labels (package-native-inputs p)))
             (propagated-inputs
              (autolith-input-labels (package-propagated-inputs p)))
             (arguments
              (substitute-keyword-arguments (package-arguments p)
                ((#:lisp _ #f) sbcl-autolith-runtime))))
           p)))
   (lambda (p)
     (not (eq? (package-build-system p) asdf-build-system/sbcl)))))

(define-public sbcl-autolith-cl+ssl
  (autolith-lisp-package %autolith-cl+ssl))

(define-public sbcl-autolith-yason
  (autolith-lisp-package %autolith-yason))

;; COLL-Attribution's active grant permits use, copying, modification,
;; distribution, sale and sublicensing, conditional only on retaining notices.
;; Its other named terms are not enabled by these pinned LICENSE.lisp files.
(define (coll-attribution repo commit)
  (license:license
   "COLL-Attribution"
   (string-append "https://github.com/" repo "/blob/" commit "/LICENSE.lisp")
   "Use, copy, modify, distribute, sell and sublicense; retain copyright and license notices.  No warranty or liability."))

(define* (autolith-library library-name repo commit hash synopsis
                           #:key (version "0.1.0") (inputs '())
                           (native-inputs '()) (systems (list library-name))
                           (test-systems (list library-name))
                           (license (coll-attribution repo commit)))
  (autolith-lisp-package
   (package
     (name (string-append "sbcl-autolith-" library-name))
     (version (git-version version "0" commit))
     (source
      (origin
        (method url-fetch)
        (uri (string-append "https://codeload.github.com/" repo "/tar.gz/" commit))
        (file-name (string-append library-name "-" commit ".tar.gz"))
        (sha256 (base32 hash))))
     (build-system asdf-build-system/sbcl)
     (arguments
      (list
       #:asd-systems (list 'quote systems)
       #:asd-test-systems (list 'quote test-systems)
       #:phases
       #~(modify-phases %standard-phases
           (add-after 'unpack 'prepare-locked-source
             (lambda* (#:key inputs #:allow-other-keys)
               ;; Do not allow an accidentally committed Quicklisp bootstrap
               ;; registry to override the declared package dependency closure.
               (when (file-exists? ".qlot")
                 (delete-file-recursively ".qlot"))
               ;; These packages execute local shell fixtures and worker
               ;; processes.  Preserve their tests, using declared store tools.
               (let ((files (find-files "." "\\.(lisp|asd)$")))
                 (substitute* files
                   (("/bin/bash") (which "bash"))
                   (("/bin/sh") (which "sh"))
                   (("/bin/true") (which "true"))
                   (("/bin/cat") (which "cat"))))
               (when (string=? #$library-name "agentcomms")
                 ;; The subprocess fixture needs only YASON from the inherited
                 ;; Guix XDG registry, not a project-local Qlot bootstrap.
                 (let ()
                   (define (remove-block file start end)
                     (let ((removing? #f))
                       (substitute file
                         (list
                          (cons ".*"
                                (lambda (line matches)
                                  (when (string-prefix? start line)
                                    (set! removing? #t))
                                  (if removing?
                                      (begin
                                        (when (string-contains line end)
                                          (set! removing? #f))
                                        "")
                                      line)))))))
                   (remove-block "tests/fixtures/echo-agent.lisp"
                                 "(let ((setup" "(load setup))")
                   (remove-block "tests/stdio-tests.lisp"
                                 "(-> test-qlot-setup-pathname"
                                 "(asdf:system-source-directory '#:agentcomms)))")
                   (substitute* "tests/fixtures/echo-agent.lisp"
                     ((";;;; Run with:.*")
                      ";;;; Run with the Guix dependency registry inherited by SBCL."))
                   (substitute* "tests/stdio-tests.lisp"
                     (("\"echo-agent.lisp\"\\)\\)")
                      "\"echo-agent.lisp\")))))")
                     ((".*\\(namestring \\(test-qlot-setup-pathname\\)\\)\\)\\)\\)")
                      ""))))
               (when (string=? #$library-name "daphne")
                 ;; Load the fixture's own ASD explicitly and resolve its
                 ;; dependencies through the inherited Guix XDG registry.
                 (substitute* "fixture.lisp"
                   ((".*\\(load \\(second sb-ext:\\*posix-argv\\*\\)\\).*") "")
                   (("third sb-ext:\\*posix-argv\\*")
                    "second sb-ext:*posix-argv*"))
                 (substitute* "tests.lisp"
                   (("  \\(let\\* \\(\\(root \\(asdf:system-source-directory \"daphne\"\\)\\)")
                    "  (let ((root (asdf:system-source-directory \"daphne\")))")
                   ((".*\\(setup \\(or \\(uiop:getenv \"DAPHNE_TEST_SETUP\"\\).*") "")
                   ((".*merge-pathnames \"../../\\.qlot/setup\\.lisp\".*") "")
                   (("setup \\(namestring \\(merge-pathnames \"daphne\\.asd\"")
                    "(namestring (merge-pathnames \"daphne.asd\"")))
               (when (string=? #$library-name "image-daemon")
                 ;; The child already registers its own source directory;
                 ;; dependencies come from Guix, not a Quicklisp home.
                 (substitute* "tests/message-tests.lisp"
                   ((".*\\(setup-symbol \\(find-symbol.*") "")
                   ((".*\\(setup \\(and setup-symbol.*") "")
                   ((".*Message subprocess tests require Quicklisp setup.*") "")
                   (("\"--load\" \\(namestring setup\\)")
                    "\"--eval\" \"(require :asdf)\"")))
               (when (string=? #$library-name "image-daemon")
                 ;; Raw SBCL CONDITION-WAIT returns NIL on timeout without
                 ;; reacquiring its mutex.  Restore ownership before the loop
                 ;; inspects shared completion state or waits again, matching
                 ;; Bordeaux Threads' established SBCL timeout handling.
                 (substitute* "src/eval.lisp"
                   (("do \\(sb-thread:condition-wait \\(eval-request-condition-variable request\\)")
                    "do (unless (sb-thread:condition-wait (eval-request-condition-variable request)")
                   ((":timeout remaining\\)\\)")
                    (string-append
                     ":timeout remaining)\n"
                     "                 (sb-sys:without-interrupts\n"
                     "                   (sb-sys:allow-with-interrupts\n"
                     "                     (sb-thread:grab-mutex (eval-request-lock request))))))"))))
               (when (string=? #$library-name "ls-compat")
                 ;; Descendant snapshots are part of the runtime API, not
                 ;; just a test fixture.  Do not depend on the caller's PATH.
                 (substitute* "src/posix.lisp"
                   (("\"ps\"")
                    (string-append "\""
                                   (search-input-file inputs "/bin/ps")
                                   "\""))))
               (when (string=? #$library-name "colorlisp")
                 (mkdir-p "native")
                 (symlink
                  (search-input-file inputs "/lib/libcolorlisp-tree-sitter.so")
                  "native/libcolorlisp-tree-sitter.so"))
               (when (string=? #$library-name "cl-exec-sandbox")
                 (mkdir-p "build")
                 (for-each
                  (lambda (helper)
                    (symlink (search-input-file inputs
                                                (string-append "/libexec/" helper))
                             (string-append "build/" helper)))
                  '("cl-exec-sandbox-helper" "cl-exec-sandbox-process-group"))
                 ;; Like upstream's Nix store root, Guix's immutable store
                 ;; must be visible for dynamically linked packaged tools.
                 (substitute* "source/rules.lisp"
                   (("#P\"/nix/store/\"")
                    "#P\"/gnu/store/\" #P\"/nix/store/\""))
                 ;; Preserve the override branches while making Guix's
                 ;; packaged tools the default on the supported Linux host.
                 (substitute* (find-files "." "\\.lisp$")
                   (("/usr/bin/bwrap|/bin/bwrap")
                    (search-input-file inputs "/bin/bwrap"))
                   (("/usr/bin/rg|/bin/rg")
                    (search-input-file inputs "/bin/rg"))))
               (when (string=? #$library-name "clasted")
                 (setenv "CLASTED_AST_GREP" (which "ast-grep")))))
           (add-before 'check 'enable-native-integration-tests
             (lambda* (#:key inputs #:allow-other-keys)
               (when (string=? #$library-name "image-daemon")
                 ;; Guix's build-root name alone consumes much of sun_path.
                 ;; /tmp is private to the build sandbox; the test suite adds
                 ;; fresh nonce directories and removes every fixture root.
                 (for-each (lambda (variable) (setenv variable "/tmp"))
                           '("TMPDIR" "TMP" "TEMP")))
               (when (string=? #$library-name "cl-worktree")
                 ;; The cherry-pick roundtrip asserts the original commit ID.
                 ;; Keep committer metadata identical even across wall-clock
                 ;; seconds while exercising the real Git integration path.
                 (setenv "GIT_AUTHOR_DATE" "2000-01-01T00:00:00+0000")
                 (setenv "GIT_COMMITTER_DATE" "2000-01-01T00:00:00+0000"))
               (when (string=? #$library-name "clifff")
                 (setenv "CLIFFF_LIBRARY"
                         (search-input-file inputs "/lib/libfff_c.so"))))))))
     (inputs inputs)
     (native-inputs
      (append
       ;; Sandbox networking tests exercise Bash's /dev/tcp redirection;
       ;; bash-minimal explicitly compiles that feature out.
       (list (if (string=? library-name "cl-exec-sandbox") bash bash-minimal)
             coreutils-minimal)
       native-inputs))
     (home-page
      (string-append "https://github.com/"
                     (if (member library-name '("cl-colorist" "idsmall"))
                         (string-append "lambda-symbolics/" library-name)
                         repo)))
     (synopsis synopsis)
     (description
      (string-append synopsis ".  This is the exact revision selected by "
                     "Autolith's dependency lock, compiled with its matching SBCL."))
     (license license))))

(define-public sbcl-autolith-nyaml
  (autolith-lisp-package
   (package
     (name "sbcl-autolith-nyaml")
     (version "0.9.0-0.20250622")
     (source
      (origin
        (method url-fetch)
        (uri "https://beta.quicklisp.org/archive/nyaml/2025-06-22/nyaml-20250622-git.tgz")
        (sha256
         (base32 "147825lyck49lgmgabg8kp3qn9dpal5dbm9fwks7cn5q1qfbip2n"))))
     (build-system asdf-build-system/sbcl)
     (arguments
      (list #:asd-systems ''("nyaml")
            #:asd-test-systems ''("nyaml")
            #:phases
            #~(modify-phases %standard-phases
                (add-after 'unpack 'declare-quasiquote-pattern-adapter
                  (lambda _
                    ;; NYAML uses Fare's readtable inside Trivia patterns.
                    ;; Both Guix and the locked Quicklisp Trivia keep that
                    ;; integration in a separately loaded ASDF system.
                    (substitute* "nyaml.asd"
                      (("#:fare-quasiquote-extras")
                       "#:fare-quasiquote-extras #:trivia.quasiquote"))))
                (add-after 'unpack 'remove-dangling-metadata-links
                  (lambda _
                    ;; These labels encode human-readable descriptions in
                    ;; link targets, not files.  Keep all real YAML fixtures.
                    (for-each
                     (lambda (file)
                       (when (and (eq? 'symlink (stat:type (lstat file)))
                                  (not (file-exists? file)))
                         (delete-file file)))
                     (find-files "test/yaml-test-suite-data"
                                 "\\.label$" #:stat lstat)))))))
     (inputs (list sbcl-esrap sbcl-alexandria sbcl-cl-ppcre sbcl-parse-number
                   sbcl-trivia sbcl-fare-quasiquote sbcl-babel))
     (native-inputs (list sbcl-split-sequence sbcl-parachute sbcl-yason))
     (home-page "https://github.com/jasom/nyaml")
     (synopsis "YAML parser and emitter for Common Lisp")
     (description "NYAML provides Common Lisp parsing and emission of YAML,
with the YAML conformance fixtures retained for its test suite.")
     (license license:expat))))

(define-public sbcl-autolith-argo
  (autolith-library
   "argo" "lambda-symbolics/argo"
   "3658b947372fb19ae07aca65a439b63b0685ae47"
   "07dsn420mglp5xf6jdqmhwlrjk6qk4i2a7r5m2k06y1vlw610n7g"
   "JSON values distinguishing false, null, and empty arrays"
   #:inputs (list sbcl-flexi-streams sbcl-serapeum sbcl-yason)))

(define-public sbcl-autolith-agentcomms
  (autolith-library
   "agentcomms" "lambda-symbolics/agentcomms"
   "2120a9df287731bf3a39edf7fabb02a5406494ff"
   "0knzyyph1ykiwhmz8fqfhd6swi0jxvp4f40ck021g99iwmyag3qq"
   "Agent Client Protocol for Common Lisp agents and clients"
   #:inputs (list sbcl-autolith-argo sbcl-bordeaux-threads sbcl-serapeum)))

(define-public sbcl-autolith-fetch-gist
  (autolith-library
   "fetch-gist" "lambda-symbolics/fetch-gist"
   "0adb33b6801d1218ce6249d2a751b05f88b98c40"
   "1zvffsvp8g9aa8m5jjvwrryg70zjffih4pdizyr68gp8cxkvz9wp"
   "Fetch a web page over HTTP and convert its HTML body to Markdown"
   #:inputs (list sbcl-dexador sbcl-plump)
   #:native-inputs (list sbcl-rove)
   #:license license:expat))

(define-public sbcl-autolith-cl-colorist
  (autolith-library
   "cl-colorist" "luciusmagn/cl-colorist"
   "a70749493fbdbe79d6766f254a664119042102b9"
   "0xaq5fax7l9k078ds000jh1i4dsvwvj826b1cs7xvpws2pr0jcgl"
   "Small, capability-aware ANSI text styling"
   #:version "0.2.0"
   #:license license:isc))

(define-public sbcl-autolith-clinedi
  (autolith-library
   "clinedi" "lambda-symbolics/clinedi"
   "1cc0c3a460c4b9c2a92f0022b17327bb3dc6e997"
   "0kwqhkfwqz26hfjbw3h38xfcp88175y5hrwz1fimy3kisgc1asjv"
   "Portable, Unicode-aware terminal line editor"
   #:inputs (list sbcl-autolith-cl-colorist sbcl-bordeaux-threads sbcl-trivial-gray-streams)
   #:systems '("clinedi" "clinedi/posix")
   #:test-systems '("clinedi" "clinedi/posix")
   #:license license:isc))

(define-public sbcl-autolith-clermaid
  (autolith-library
   "clermaid" "lambda-symbolics/clermaid"
   "9e38610ef0a595f9542b2727e1f97f5974f73ce5"
   "0g7rqmhvyh54afswadbwfhap6q60n9qby622gfvxibv3b8cdp0m6"
   "Bounded Mermaid diagrams as terminal text"
   #:inputs (list sbcl-autolith-clinedi)))

(define-public sbcl-autolith-cl-jobpond
  (autolith-library
   "cl-jobpond" "lambda-symbolics/cl-jobpond"
   "3fa176f20caaf954ebe3b352a18c01fef34d33ee"
   "0iwy7ni5wdr51adlr70igprxwhw2w5ny4xb58c3727pq1fp8ssyq"
   "Supervised bounded thread pool for cancellable in-process jobs"
   #:inputs (list sbcl-bordeaux-threads)
   #:systems '("cl-jobpond" "cl-jobpond/durable-state" "cl-jobpond/schedules" "cl-jobpond/mailboxes" "cl-jobpond/completions")
   #:test-systems '("cl-jobpond" "cl-jobpond/durable-state" "cl-jobpond/schedules" "cl-jobpond/mailboxes" "cl-jobpond/completions")))

(define-public sbcl-autolith-structlisp
  (autolith-library
   "structlisp" "lambda-symbolics/structlisp"
   "66bbfbe947b69f3105f71f5e4293637decc91746"
   "1jx0vkmpafnns43nnr9j9hpm8k04fw3hag0mkaznqdfcwm2pv183"
   "General-purpose data structures for interactive Common Lisp systems"))

(define-public sbcl-autolith-clinker-transcript
  (autolith-library
   "clinker-transcript" "lambda-symbolics/clinker-transcript"
   "d7cd04903fb36b62224fe618a0e1a11bebf0d8cb"
   "07vl35jg52bl955rhfgif7y9i1yvp880krqrw7q65499rr6a0kl2"
   "Portable provider transcript items for language-model clients"
   #:inputs (list sbcl-yason sbcl-autolith-structlisp)))

(define-public sbcl-autolith-cl-rfc8628
  (autolith-library
   "cl-rfc8628" "lambda-symbolics/cl-rfc8628"
   "740ccdff7d10c192c75cc1589259682e3e66e007"
   "0j6bx44yq64zdqf65yp7n82w1jh3z8bknxvmn3gvc2w6cqjl8y02"
   "OAuth 2.0 device authorization grant as a CLOS protocol"
   #:inputs (list sbcl-bordeaux-threads sbcl-cl-base64 sbcl-dexador sbcl-quri sbcl-yason)))

(define-public sbcl-autolith-cl-rfc8252
  (autolith-library
   "cl-rfc8252" "lambda-symbolics/cl-rfc8252"
   "b9affbd04c12e2adac4a2403f60a3a2802f9ac45"
   "09q66zig0dvn2b83n0nw6phjms5xhaz90nrwpp9y6nfb5jzz8zd6"
   "Installed-app browser OAuth with S256 PKCE and loopback redirects"
   #:inputs (list sbcl-autolith-cl-rfc8628 sbcl-babel sbcl-cl-base64 sbcl-ironclad sbcl-quri sbcl-usocket)
   #:native-inputs (list sbcl-bordeaux-threads)))

(define-public sbcl-autolith-cl-llm-provider-api
  (autolith-library
   "cl-llm-provider-api" "lambda-symbolics/cl-llm-provider-api"
   "1e67d70c13cdc52fedae82fdf310d3d9409099e1"
   "1gwcmsi98iyglf6y3sj4ln4sk60grqllma3y2dr0shj8dmcsx0vb"
   "Portable protocols and value types for language-model providers"
   #:version "0.2.0"
   #:inputs (list sbcl-babel sbcl-bordeaux-threads sbcl-ironclad sbcl-yason sbcl-dexador sbcl-autolith-cl+ssl sbcl-usocket sbcl-autolith-clinker-transcript sbcl-autolith-cl-rfc8628)
   #:systems '("cl-llm-provider-api" "cl-llm-provider-api/wire" "cl-llm-provider-api/dexador" "cl-llm-provider-api/context" "cl-llm-provider-api/contracts" "cl-llm-provider-api/registry")
   #:test-systems '("cl-llm-provider-api" "cl-llm-provider-api/wire" "cl-llm-provider-api/dexador" "cl-llm-provider-api/context" "cl-llm-provider-api/contracts" "cl-llm-provider-api/registry")))

(define-public sbcl-autolith-sexp-config
  (autolith-library
   "sexp-config" "lambda-symbolics/sexp-config"
   "d36be049fb4f31e7f51d0f9b718fbf36bd642fca"
   "1nkaird0mqwi1ysm2wpwrybsxzv451wa2ryr1vlpaz0pagn84kf0"
   "Bounded fail-closed reading of s-expression configuration sources"))

(define-public sbcl-autolith-cl-lsp
  (autolith-library
   "cl-lsp" "lambda-symbolics/cl-lsp"
   "170885bfc140fb7864c4cb6ddb0e91d96be7c468"
   "17hqndjydynkanv8apzqijbzwgpzbj5v7ppd0cbrr9wgd51yga61"
   "Bounded stdio Language Server Protocol clients"
   #:inputs (list sbcl-autolith-argo sbcl-bordeaux-threads sbcl-quri sbcl-serapeum sbcl-autolith-sexp-config)
   #:native-inputs (list sbcl-flexi-streams)))

(define-public sbcl-autolith-cl-resources
  (autolith-library
   "cl-resources" "lambda-symbolics/cl-resources"
   "2a160c6fdacac6f1f70689c43209b26182fd7f4d"
   "04z1rsjyzwmw52hpn5iz7j7jrkir15y9cqm1nji7bj29828zcxnd"
   "Authority-neutral revisioned resources and recoverable change sets"
   #:inputs (list sbcl-bordeaux-threads)
   #:license license:isc))

(define-public sbcl-autolith-clasted
  (autolith-library
   "clasted" "lambda-symbolics/clasted"
   "dc8b2df5a68b396c4cdd825a58e7a4d50dfb9def"
   "0qxdpk7sd6clazsp0qb2lls0lgq14ch94wy775kf8g08ymgph0yj"
   "Immutable structural queries and previewed edit plans"
   #:inputs (list sbcl-autolith-argo sbcl-babel sbcl-ironclad)
   #:native-inputs (list ast-grep)
   #:systems '("clasted" "clasted/ast-grep")
   #:test-systems '("clasted" "clasted/ast-grep")
   #:license license:isc))

(define-public sbcl-autolith-daphne
  (autolith-library
   "daphne" "lambda-symbolics/daphne"
   "65f68216152c70110a092b79050b37ce75cdbdb1"
   "0815skl57yhb65wry1mh3rynihb6bh4d0y60qd6c01a9w6bhyfsy"
   "Bounded Debug Adapter Protocol sessions"
   #:inputs (list sbcl-autolith-argo sbcl-babel sbcl-bordeaux-threads)
   #:license license:isc))

(define-public sbcl-autolith-ls-compat
  (autolith-library
   "ls-compat" "lambda-symbolics/ls-compat"
   "d67c607188ed434aa541c7048d422954d31bebcc"
   "09x21rl34axyadzbzlsc7s130kfgv683j3amyyra0qmsx3w1lz29"
   "Focused Common Lisp portability utilities for LS projects"
   #:inputs (list sbcl-babel sbcl-serapeum sbcl-usocket procps)
   #:systems '("ls-compat" "ls-compat/posix" "ls-compat/files" "ls-compat/tcp")
   #:test-systems '("ls-compat" "ls-compat/posix" "ls-compat/files" "ls-compat/tcp")))

(define-public sbcl-autolith-cl-skills
  (autolith-library
   "cl-skills" "lambda-symbolics/cl-skills"
   "9ece528bfe07253a9450651808b28457b7ede71d"
   "046swmvahf7as7qxgfpa7jasg0hfvmpz4dsilqdfsg1f1297ag0h"
   "Portable Agent Skills discovery, parsing, caching, and rendering"
   #:inputs (list sbcl-autolith-cl-llm-provider-api sbcl-ironclad sbcl-autolith-ls-compat sbcl-autolith-nyaml sbcl-serapeum sbcl-autolith-sexp-config)
   #:systems '("cl-skills" "cl-skills/executable")
   #:test-systems '("cl-skills" "cl-skills/executable")))

(define-public sbcl-autolith-colorlisp
  (autolith-library
   "colorlisp" "lambda-symbolics/colorlisp"
   "2654ae0fa34aee42cff401693b5a80a86f0942c4"
   "17gr7n3w0rrqrv2p1c1zjx40pr9avg0i21gcy969gv8g4wvlqwxj"
   "Style-neutral syntax highlighting for Common Lisp applications"
   #:version "0.2.0"
   #:inputs (list sbcl-babel sbcl-cffi sbcl-cl-ppcre autolith-colorlisp-native)
   #:license license:isc))

(define-public sbcl-autolith-colordiff
  (autolith-library
   "colordiff" "lambda-symbolics/colordiff"
   "1e1e85af707690e100e1c140513e042387fecf22"
   "0bbzm0c8zbcspq2jxdzagr8inyhzgqkmzw92q17hzv4wzhi04znx"
   "Colorful syntax-highlighted diffs in terminals"
   #:inputs (list sbcl-autolith-cl-colorist sbcl-autolith-colorlisp)))

(define-public sbcl-autolith-cl-termdown
  (autolith-library
   "cl-termdown" "lambda-symbolics/cl-termdown"
   "adf0278f493c72ad629906342341048f8a75d0df"
   "04n4ny1af4m06hxidjhyq5kc1awmc17p5a4cva71v2dmd1hj6ksz"
   "Terminal Markdown parser and semantic span renderer"
   #:inputs (list sbcl-autolith-clinedi sbcl-autolith-clermaid sbcl-autolith-colordiff sbcl-autolith-colorlisp sbcl-serapeum)))

(define-public sbcl-autolith-cl-worktree
  (autolith-library
   "cl-worktree" "lambda-symbolics/cl-worktree"
   "cd180c2b8f9cb4731be05c39320bbf91b0e2e63d"
   "0qb13pml024zyjwmp3iqrr1c9210jsbspcsgamj66bqa7kl1g3rw"
   "Owned Git worktree isolation and integration primitives"
   #:native-inputs (list git-minimal)
   #:license license:isc))

(define-public sbcl-autolith-cl-exec-sandbox
  (autolith-library
   "cl-exec-sandbox" "lambda-symbolics/cl-exec-sandbox"
   "684e840c7f6de632048e38dcf63279da19ebc2fe"
   "1i0im5w9bjm35sqazja6sn1z9q1rz18hl1zxycqyw9f5a3r0jjwk"
   "Policy-driven external process sandboxing for Common Lisp"
   #:inputs (list autolith-sandbox-helper bubblewrap ripgrep)
   #:license license:isc))

(define-public sbcl-autolith-cl-hashline
  (autolith-library
   "cl-hashline" "lambda-symbolics/cl-hashline"
   "9a989dc73bf46ff3f8e8c6921126612e2451a8a8"
   "1ba341gz2048s76ncppx2q9lvhc1yysy6x9gcap2v2pblrnjin5j"
   "Line-anchored, revision-gated text edits"
   #:inputs (list sbcl-babel sbcl-ironclad sbcl-autolith-structlisp)
   #:native-inputs (list sbcl-fiveam)))

(define-public sbcl-autolith-clifff
  (autolith-library
   "clifff" "lambda-symbolics/clifff"
   "c575f108ef497f113f87901ac91fd6dcce2a59cf"
   "0fqg58l0j7hgg57w36wdq8iidym9vl7c1ccxx6yqqzdxqx5zsass"
   "Common Lisp bindings and a supervised worker for fff"
   #:inputs (list sbcl-bordeaux-threads sbcl-cffi autolith-fff-c)
   #:license license:isc))

(define-public sbcl-autolith-parenchek
  (autolith-library
   "parenchek" "lambda-symbolics/parenchek"
   "60dcd4636cb7c18003f24a5e7192acba55979d6b"
   "1x3yvn3jz162k9lcn0jyzbw3yi2d9swigv2c3h49jzi1ivdz1c11"
   "Lisp-family delimiter balance checking"
   #:inputs (list sbcl-autolith-ls-compat sbcl-serapeum)))

(define-public sbcl-autolith-org-templater
  (autolith-library
   "org-templater" "lambda-symbolics/org-templater"
   "918d456528474e880014fe8377e4810e4a55e6a9"
   "04aqa3nbv4b696qskab25q3xkva700ji9rzal4a9x6pgsigdxc60"
   "Minimalist templated org file library"))

(define-public sbcl-autolith-idsmall
  (autolith-library
   "idsmall" "luciusmagn/idsmall"
   "3f4b8e067a1e41b5388f7c5af58585e8c9ab51b9"
   "0xb0h9pncprghfhxx2vaxchgxzzsapcy82llvlb4f7253b7lzs8v"
   "Short Base58 identifiers holding a reversibly scrambled timestamp"
   #:inputs (list sbcl-bordeaux-threads)))

(define-public sbcl-autolith-ls-flock
  (autolith-library
   "ls-flock" "lambda-symbolics/ls-flock"
   "0e3e0ada0f5b693cb3f32f46aefbb8dbebcc20f2"
   "0kzm33sznmv7m7hmmrfrw19hdrx0vz69bbf5sdaim2cd23g5pzy0"
   "Process-shared advisory file locks and exclusive leases"
   #:inputs (list sbcl-bordeaux-threads)))

(define-public sbcl-autolith-sexp-store
  (autolith-library
   "sexp-store" "lambda-symbolics/sexp-store"
   "4d38e6544d87412d99acef9f097272df41359eff"
   "1315s53h0h18d11ym9372xxgl18y72n21xkincy6ilfww41xw38d"
   "Crash-tolerant readable Common Lisp state files"
   #:version "0.4.0"
   #:inputs (list sbcl-autolith-ls-compat sbcl-autolith-ls-flock sbcl-autolith-sexp-config)
   #:license license:isc))

(define-public sbcl-autolith-image-daemon
  (autolith-library
   "image-daemon" "lambda-symbolics/image-daemon"
   "7cd4b782e54c3d583a718876df7bfdd89778249b"
   "0hgq3gn129ffp642mji5hbc1v5772i2148s4wwi4rcaxhkfjy9g0"
   "Authenticated loopback control endpoints for Lisp image daemons"
   #:inputs (list sbcl-autolith-idsmall sbcl-ironclad sbcl-bordeaux-threads sbcl-serapeum sbcl-autolith-ls-compat sbcl-autolith-ls-flock sbcl-autolith-sexp-config sbcl-autolith-sexp-store sbcl-autolith-structlisp sbcl-trivial-gray-streams)
   #:native-inputs (list sbcl-flexi-streams)
   #:systems '("image-daemon" "image-daemon/runtime" "image-daemon/eval" "image-daemon/messages")
   #:test-systems '("image-daemon" "image-daemon/runtime" "image-daemon/eval" "image-daemon/messages")))

(define-public sbcl-autolith-mcparen
  (autolith-library
   "mcparen" "lambda-symbolics/mcparen"
   "03c47248988ebb7dd9aaa40a77d4ca5ac6e21889"
   "168hkna6x7j0ckg1p676v1pvbdpzly8acs5z6x9vryddxn6icxkn"
   "Small Model Context Protocol client for Common Lisp"
   #:inputs (list sbcl-autolith-argo sbcl-autolith-ls-compat sbcl-babel sbcl-bordeaux-threads sbcl-dexador sbcl-quri sbcl-serapeum)
   #:systems '("mcparen" "mcparen/managed")
   #:test-systems '("mcparen" "mcparen/managed")
   #:license license:isc))

(define-public sbcl-autolith-sbcl-generations
  (autolith-library
   "sbcl-generations" "lambda-symbolics/sbcl-generations"
   "df5128f03e60fe3ab1b8740b6f6555f402623148"
   "0zg7b6k6d0zw5pj43kqdp3vc9c5rmnf6qh9q57brjbp4dwzpxagx"
   "Fork and supervised-restart checkpoints of exact SBCL heaps"
   #:inputs (list sbcl-bordeaux-threads)
   #:native-inputs (list git-minimal)))

(define-public sbcl-autolith-sophisticated-clipboard
  (autolith-library
   "sophisticated-clipboard" "lambda-symbolics/sophisticated-clipboard"
   "756b65f4f8be18c786e2331de89708729df42bd4"
   "0iy9073yk6gyhzwa4nm14z5yhxj82ww2f6l3h7z313cc0ah9sh92"
   "Portable system clipboard access for Common Lisp"
   #:inputs (list sbcl-cl-base64 sbcl-flexi-streams)
   #:native-inputs (list sbcl-fiveam)
   #:license license:expat))

(define-public sbcl-autolith-sbcl-workers
  (autolith-library
   "sbcl-workers" "lambda-symbolics/sbcl-workers"
   "b966b7a17bd122318ab12f5732885ff1680cc3b9"
   "08xvyvy62z4bixw8sq920rk9q6l60g92phl1sdc52jc2ncjw0497"
   "Persistent isolated SBCL workers and immutable heap images"
   #:inputs (list sbcl-autolith-ls-compat sbcl-autolith-sexp-store sbcl-bordeaux-threads sbcl-trivial-gray-streams)
   #:systems '("sbcl-workers" "sbcl-workers/host-callbacks")
   #:test-systems '("sbcl-workers" "sbcl-workers/host-callbacks")
   #:license license:isc))

(define-public sbcl-autolith-surgeon
  (autolith-library
   "surgeon" "lambda-symbolics/surgeon"
   "347e3a48f931c6ba178d0582fb8a79bd22a4ea6f"
   "1bc1whj725bynpq0dsfyck9kfn8y995qnnpwlhgsch2kkgyvy5yf"
   "Introspection and reversible redefinition for live SBCL images"
   #:inputs (list sbcl-autolith-ls-compat sbcl-closer-mop sbcl-serapeum)))

(define-public sbcl-autolith-setinka
  (autolith-library
   "setinka" "lambda-symbolics/setinka"
   "f1a7e186ad217e08cf4045c938398a0860126851"
   "057nscf4p3mk5i59zr9w1sgz8x1l3r7d4rz9wdfqq31gmyaql77w"
   "Typed, documented, layered settings with durable stores and dependent values"
   #:inputs (list sbcl-bordeaux-threads sbcl-serapeum)))

(define-public sbcl-autolith-lambda-debugger
  (autolith-library
   "lambda-debugger" "lambda-symbolics/lambda-debugger"
   "713c4a64ad109eb4f511426c21ae422b18674c77"
   "15bdvslqx1lshjjzrpvzc8q9qfjq4z48bf125f0bsq9hjr87nmq2"
   "Live restart selection, portable recoveries, and typed diagnostics"
   #:inputs (list sbcl-trivial-gray-streams)))

(define-public sbcl-autolith-yolokuva
  (autolith-library
   "yolokuva" "lambda-symbolics/yolokuva"
   "1a6e6e68b8d184496dbfda9defcac1f6dfaf18fe"
   "1cc0640dwp0kr9wfjjd58hrlsra1aq07qbv6v6qq9mghj0c5h01q"
   "Recognize, measure, and size images for multimodal model prompts"
   #:inputs (list sbcl-opticl)
   #:systems '("yolokuva" "yolokuva/opticl")
   #:test-systems '("yolokuva" "yolokuva/opticl")))

;; The application consumes this one closure rather than maintaining a second
;; lock inventory.  Stock Guix libraries are rebuilt with the same compiler.
(define-public %autolith-lisp-inputs
  (map autolith-lisp-package
       (list
        sbcl-autolith-agentcomms
        sbcl-autolith-fetch-gist
        sbcl-autolith-cl-colorist
        sbcl-autolith-cl+ssl
        sbcl-autolith-clinedi
        sbcl-autolith-clermaid
        sbcl-autolith-cl-jobpond
        sbcl-autolith-clinker-transcript
        sbcl-autolith-cl-rfc8252
        sbcl-autolith-cl-rfc8628
        sbcl-autolith-cl-llm-provider-api
        sbcl-autolith-cl-lsp
        sbcl-autolith-cl-resources
        sbcl-autolith-clasted
        sbcl-autolith-daphne
        sbcl-autolith-cl-skills
        sbcl-autolith-cl-termdown
        sbcl-autolith-cl-worktree
        sbcl-autolith-cl-exec-sandbox
        sbcl-autolith-cl-hashline
        sbcl-autolith-clifff
        sbcl-autolith-colorlisp
        sbcl-autolith-colordiff
        sbcl-autolith-parenchek
        sbcl-autolith-org-templater
        sbcl-autolith-image-daemon
        sbcl-autolith-ls-compat
        sbcl-autolith-ls-flock
        sbcl-autolith-idsmall
        sbcl-autolith-mcparen
        sbcl-autolith-sbcl-generations
        sbcl-autolith-sexp-config
        sbcl-autolith-sexp-store
        sbcl-autolith-sophisticated-clipboard
        sbcl-autolith-sbcl-workers
        sbcl-autolith-surgeon
        sbcl-autolith-structlisp
        sbcl-autolith-argo
        sbcl-autolith-setinka
        sbcl-autolith-lambda-debugger
        sbcl-autolith-yolokuva
        sbcl-autolith-nyaml
        sbcl-bordeaux-threads
        sbcl-cl-base64
        sbcl-cffi
        sbcl-clingon
        sbcl-closer-mop
        sbcl-dexador
        sbcl-fiveam
        sbcl-ironclad
        sbcl-opticl
        sbcl-quri
        sbcl-serapeum
        sbcl-trivial-gray-streams
        sbcl-autolith-yason
)))
