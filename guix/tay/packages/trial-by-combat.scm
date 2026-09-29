;;; GNU Guix package for kunchenguid/trial-by-combat.
;;;
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages trial-by-combat)
  #:use-module (guix build-system node)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages node)
  #:use-module (tay packages auxiliary)
  #:use-module (tay packages starred-i-m)
  #:use-module (tay packages trial-by-combat-npm-sources))

;; Upstream loads the renderer from a jsdelivr CDN and the arcade face from
;; Google Fonts.  Both are replaced by fixed store origins so that a packaged
;; run renders identically with no outbound request.
(define pixi.js-8.2.6
  (origin
    (method url-fetch)
    (uri "https://registry.npmjs.org/pixi.js/-/pixi.js-8.2.6.tgz")
    (file-name "pixi.js-8.2.6.tgz")
    (sha256
     (base32 "03dymfhgbclndqp6js7k5yyg3l1i8kgcyc2b7h7jjg345g727cqj"))))

(define press-start-2p-v16
  (origin
    (method url-fetch)
    (uri (string-append "https://fonts.gstatic.com/s/pressstart2p/v16/"
                        "e3t4euO8T-267oIAQAu6jDQyK0nS.ttf"))
    (file-name "PressStart2P-v16.ttf")
    (sha256
     (base32 "0arckjpva735l7j0s2qcvrfcsgaxn1gyhn9cikfqbqccdy0rp4vv"))))

;; The SIL Open Font License must travel with the face.  This is the licence
;; text Google Fonts ships beside the same Press Start 2P release.
(define press-start-2p-ofl
  (origin
    (method url-fetch)
    (uri (string-append "https://raw.githubusercontent.com/google/fonts/"
                        "23e54b51ddffbc7713c583748e3bd86f62b1fa4a"
                        "/ofl/pressstart2p/OFL.txt"))
    (file-name "PressStart2P-OFL.txt")
    (sha256
     (base32 "1c24p7zdp3ryzk16n1s8awbfv7m5gknx96xmq3n6amqs531n0nbh"))))

;; Bounded self-check behind `trial-by-combat --smoke-host'.  It is installed
;; beside src/ so that it imports the real server and its locked modules.
(define %trial-by-combat-smoke-host
  (local-file (search-tay-package-file "trial-by-combat-smoke-host.mjs")))

;; The two upstream references that must stop pointing outside the store.
(define %pixi-cdn-reference
  (string-append "https://cdn\\.jsdelivr\\.net/npm/pixi\\.js@8\\.2\\.6"
                 "/dist/pixi\\.min\\.js"))

(define %google-fonts-reference
  (string-append "@import url\\(\"https://fonts\\.googleapis\\.com/css2"
                 "\\?family=Press\\+Start\\+2P&display=swap\"\\);"))

(define-public trial-by-combat
  (package
    (name "trial-by-combat")
    (version "0.1.0")
    (source (package-source kunchenguid-trial-by-combat-source))
    (build-system node-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          ;; No package manager resolves or fetches anything: rebuild the
          ;; exact locked tree from fixed Guix origins.  Development-only
          ;; nodes are absent from the input list and stay uninstalled.
          (add-after 'unpack 'materialize-locked-node-modules
            (lambda _
              (use-modules (json) (srfi srfi-1) (srfi srfi-13))
              (mkdir-p ".npm-source-cache")
              (let ((archives (list #$@(map cdr %trial-by-combat-npm-sources))))
                (for-each
                 (lambda (archive index)
                   (let ((directory (string-append ".npm-source-cache/"
                                                   (number->string index))))
                     (mkdir-p directory)
                     (invoke "tar" "xzf" archive "-C" directory
                             "--strip-components=1")))
                 archives
                 (iota (length archives)))
                (let ((sources
                       (map (lambda (index)
                              (let* ((directory (string-append ".npm-source-cache/"
                                                               (number->string index)))
                                     (metadata
                                      (call-with-input-file
                                          (string-append directory "/package.json")
                                        json->scm)))
                                (cons (string-append (assoc-ref metadata "name") "@"
                                                     (assoc-ref metadata "version"))
                                      directory)))
                            (iota (length archives)))))
                  (for-each
                   (lambda (entry)
                     (let* ((path (car entry))
                            (metadata (cdr entry)))
                       (unless (or (string-null? path)
                                   (eq? #t (assoc-ref metadata "dev")))
                         (let* ((start
                                 (let loop ((offset 0) (last #f))
                                   (let ((next (string-contains path "node_modules/"
                                                                offset)))
                                     (if next
                                         (loop (+ next 1) next)
                                         last))))
                                (name (substring path
                                                 (+ start
                                                    (string-length "node_modules/"))))
                                (key (string-append name "@"
                                                    (assoc-ref metadata "version")))
                                (cached (assoc-ref sources key)))
                           (unless cached
                             (error "locked npm source was not supplied" key))
                           (mkdir-p (dirname path))
                           (copy-recursively cached path)))))
                   (assoc-ref (call-with-input-file "package-lock.json" json->scm)
                              "packages"))))))
          ;; Vendor the renderer and the arcade face next to the other client
          ;; assets, then point the markup and stylesheet at those local
          ;; copies.  A packaged run must never reach a CDN.
          (add-after 'materialize-locked-node-modules 'vendor-client-assets
            (lambda _
              (let ((vendor "public/vendor"))
                (mkdir-p vendor)
                (mkdir-p ".pixi")
                (invoke "tar" "xzf" #$pixi.js-8.2.6 "-C" ".pixi"
                        "--strip-components=1")
                (copy-file ".pixi/dist/pixi.min.js"
                           (string-append vendor "/pixi.min.js"))
                (copy-file ".pixi/LICENSE"
                           (string-append vendor "/pixi.js-LICENSE"))
                (copy-file #$press-start-2p-v16
                           (string-append vendor "/PressStart2P-v16.ttf"))
                (substitute* "public/index.html"
                  ((#$%pixi-cdn-reference)
                   "/client/vendor/pixi.min.js"))
                (substitute* "public/styles.css"
                  ((#$%google-fonts-reference)
                   (string-append
                    "@font-face {\n"
                    "  font-family: \"Press Start 2P\";\n"
                    "  font-style: normal;\n"
                    "  font-weight: 400;\n"
                    "  font-display: swap;\n"
                    "  src: url(\"/client/vendor/PressStart2P-v16.ttf\")"
                    " format(\"truetype\");\n"
                    "}\n"
                    "\n"
                    ":root {\n"
                    "  --tbc-arcade-font: \"Press Start 2P\","
                    " \"DejaVu Sans\", sans-serif;\n"
                    "}"))))))
          ;; Guix 1.5 rewrites dependency ranges when it patches the manifest.
          ;; The tree above already matches the lockfile exactly, and the
          ;; lockfile must survive for the offline provenance check.
          (replace 'patch-dependencies (lambda _ #t))
          (delete 'delete-lockfiles)
          (add-after 'vendor-client-assets 'remove-build-dependencies
            (lambda _
              (modify-json (delete-fields '("devDependencies") #:strict? #f))))
          (replace 'configure (lambda _ #t))
          (replace 'build (lambda _ #t))
          ;; Upstream's suite is plain `node --test`, so it runs offline with
          ;; no test runner dependency.  Keep match logging off so the suite
          ;; cannot append to a file inside the build tree that we install.
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (setenv "TBC_MATCH_LOG" "0")
                (invoke #$(file-append node-lts "/bin/node") "--test"))))
          (replace 'install
            (lambda _
              (let* ((module (string-append #$output
                                            "/lib/node_modules/trial-by-combat"))
                     (documentation (string-append #$output
                                                   "/share/doc/trial-by-combat"))
                     (launcher (string-append #$output "/bin/trial-by-combat")))
                (mkdir-p module)
                (for-each
                 (lambda (directory)
                   (copy-recursively directory
                                     (string-append module "/" directory)))
                 '("node_modules" "public" "src"))
                (copy-file "package.json" (string-append module "/package.json"))
                (copy-file "package-lock.json"
                           (string-append module "/package-lock.json"))
                (copy-file "LICENSE" (string-append module "/LICENSE"))
                (mkdir-p documentation)
                (copy-file "LICENSE" (string-append documentation "/LICENSE"))
                (copy-file "README.md" (string-append documentation "/README.md"))
                (copy-file "public/vendor/pixi.js-LICENSE"
                           (string-append documentation "/pixi.js-LICENSE"))
                (copy-file #$press-start-2p-ofl
                           (string-append documentation "/PressStart2P-OFL.txt"))
                (copy-file #$%trial-by-combat-smoke-host
                           (string-append module "/smoke-host.mjs"))
                ;; The store is immutable, so the default match log would aim
                ;; at a read-only path.  Disable it unless the operator opts
                ;; in, and honour an inherited PORT so the documented 4178
                ;; default still applies.  `--smoke-host' runs the bounded
                ;; self-check instead of serving until interrupted.
                (mkdir-p (string-append #$output "/bin"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a
export TBC_MATCH_LOG=\"${TBC_MATCH_LOG:-0}\"
if [ \"$1\" = --smoke-host ]; then
  shift
  exec ~a ~a/smoke-host.mjs \"$@\"
fi
exec ~a ~a/src/server.js \"$@\"
"
                            (string-append #$bash-minimal "/bin/sh")
                            (string-append #$node-lts "/bin/node")
                            module
                            (string-append #$node-lts "/bin/node")
                            module)))
                (chmod launcher #o555)))))))
    ;; Origins are source archives only.  The node build system supplies Node;
    ;; every JavaScript runtime dependency comes from this locked list.
    (native-inputs (map cdr %trial-by-combat-npm-sources))
    (inputs (list bash-minimal node-lts))
    (home-page "https://github.com/kunchenguid/trial-by-combat")
    (synopsis "Tactical browser arena served over HTTP and WebSocket")
    (description
     "Trial by Combat is a turn-based tactical arena.  A Node server hosts the
match engine, an HTTP player API, and a WebSocket feed for the spectator and
admin consoles; browsers render the board with Pixi.js.  The package listens on
port 4178 by default, honours @env{PORT}, and is built and tested from the
pinned upstream source using its fully fixed npm closure with no package
manager resolution or network access.  The renderer and the arcade typeface are
vendored from fixed origins, so a packaged run never contacts a CDN, and match
logging defaults to off because the store is read-only.  Run
@command{trial-by-combat --smoke-host} for a bounded self-check that drives the
player API and the admin and spectator consoles through a match, then exits.")
    ;; Expat covers the program and Pixi.js; the locked dependency closure adds
    ;; ISC and BSD-3-Clause nodes, and the bundled face is OFL-1.1.
    (license (list license:expat license:isc license:bsd-3 license:silofl1.1))))
