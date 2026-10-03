;;; Revengate's original desktop Godot project and complete asset notices.
(define-module (tay packages revengate)
  #:use-module (tay packages auxiliary)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages game-development)
  #:use-module (gnu packages python)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages))

(define-public revengate
  (package
    (name "revengate")
    (version "0.13.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://gitlab.com/ygingras/revengate.git")
             (commit "21b0cb49a84a1fada7e171064b68f1183818c32c")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0yqjav3ihbqhva1zf5qw16577khhys8b927v0bbysm8zqskn7cj7"))
       (patches
        (list (search-tay-package-file
               "patches/revengate-node-ownership.patch")))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:modules '((guix build gnu-build-system)
                  (guix build utils)
                  (ice-9 binary-ports)
                  (ice-9 regex)
                  (ice-9 textual-ports)
                  (rnrs bytevectors)
                  (srfi srfi-1))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'bootstrap)
          (delete 'configure)
          (add-after 'unpack 'prepare-offline-import
            (lambda _
              ;; Import the vendored dialogue compiler, but never its editor
              ;; update checker.  Runtime core scripts remain intact.
              (substitute* "addons/dialogue_manager/components/update_button.gd"
                (("if DialogueSettings.get_user_value\\(\"check_for_updates\", true\\):")
                 "if false:"))
              ;; Godot 4.6 returns extracted translation strings rather than
              ;; accepting two output arrays (the plugin targets Godot 4.3).
              (substitute*
                  "addons/dialogue_manager/editor_translation_parser_plugin.gd"
                (((string-append "func _parse_file\\(path: String, msgids: Array, "
                                 "msgids_context_plural: Array\\) -> void:"))
                 (string-append
                  "func _parse_file(path: String) -> Array[PackedStringArray]:\n"
                  "\tvar msgids_context_plural: Array[PackedStringArray] = []"))
                (("msgids_context_plural.append\\(\\[(.*)\\]\\)" all fields)
                 (string-append "msgids_context_plural.append("
                                "PackedStringArray([" fields "]))"))
                (("func _get_recognized_extensions")
                 (string-append "\treturn msgids_context_plural\n\n"
                                "func _get_recognized_extensions")))
              ;; Godot continues after some script errors, including inside a
              ;; synchronous turn loop. Fail immediately, retaining the real
              ;; engine diagnostics rather than waiting forever for Done!.
              (call-with-output-file ".godot-checked.py"
                (lambda (port)
                  (display
                   (string-append
                    "import subprocess, sys\n"
                    "process = subprocess.Popen(sys.argv[1:], stdout="
                    "subprocess.PIPE, stderr=subprocess.STDOUT, text=True)\n"
                    "try:\n"
                    "    for line in process.stdout:\n"
                    "        print(line, end='', flush=True)\n"
                    "        if line.startswith(('ERROR:', 'SCRIPT ERROR:')):\n"
                    "            process.terminate()\n"
                    "            try: process.wait(timeout=5)\n"
                    "            except subprocess.TimeoutExpired:\n"
                    "                process.kill(); process.wait()\n"
                    "            sys.exit(1)\n"
                    "    sys.exit(process.wait())\n"
                    "finally:\n"
                    "    if process.poll() is None:\n"
                    "        process.kill(); process.wait()\n") port)))
              (setenv "HOME" (string-append (getcwd) "/.build-home"))
              (setenv "XDG_CONFIG_HOME" (string-append (getenv "HOME") "/config"))
              (setenv "XDG_CACHE_HOME" (string-append (getenv "HOME") "/cache"))
              (setenv "XDG_DATA_HOME" (string-append (getenv "HOME") "/data"))
              (setenv "GODOT_SILENCE_ROOT_WARNING" "1")
              (mkdir-p (getenv "HOME"))))
          (replace 'build
            (lambda* (#:key inputs #:allow-other-keys)
              ;; The custom theme references fonts that do not exist until the
              ;; first import. Import without that editor theme, then validate
              ;; a normal import with it restored. Do not hide engine errors:
              ;; Godot can exit zero despite a failed plugin compilation.
              (define (import-project log)
                (invoke (search-input-file inputs "/bin/bash")
                        "-o" "pipefail" "-c" "\"$@\" 2>&1 | tee \"$0\"" log
                        (search-input-file inputs "/bin/python3")
                        ".godot-checked.py"
                        (search-input-file inputs "/bin/godot")
                        "--headless" "--path" "." "--editor" "--import")
                (let ((text (call-with-input-file log get-string-all)))
                  (when (string-match "(^|\n)(SCRIPT ERROR:|ERROR:)" text)
                    (error "Godot import reported errors" log)))
                (delete-file log))
              (copy-file "project.godot" "project.godot.build-original")
              (substitute* "project.godot"
                (("theme/custom=.*") ""))
              (import-project "initial-import.log")
              (rename-file "project.godot.build-original" "project.godot")
              (import-project "validated-import.log")))
          (replace 'check
            (lambda* (#:key inputs tests? #:allow-other-keys)
              (when tests?
                ;; --check-only --script omits project autoloads. Exercise the
                ;; original bounded scene with autoloads instead; no new scene
                ;; or gameplay instrumentation is added to the package.
                (invoke (search-input-file inputs "/bin/bash")
                        "-o" "pipefail" "-c" "\"$@\" 2>&1 | tee \"$0\""
                        "combat-check.log"
                        (search-input-file inputs "/bin/python3")
                        ".godot-checked.py"
                        (search-input-file inputs "/bin/godot")
                        "--headless" "--path" "." "--scene"
                        "src/combat/combat_sim.tscn")
                (let ((text
                       (call-with-input-file "combat-check.log" get-string-all)))
                  (when (string-match "(^|\n)(SCRIPT ERROR:|ERROR:)" text)
                    (error "Godot combat scene reported errors"))
                  (unless (string-match "(^|\n)Done!(\n|$)" text)
                    (error "Upstream combat simulator did not complete")))
                (delete-file "combat-check.log"))))
          (add-after 'check 'normalize-runtime-cache
            (lambda _
              ;; UID cache entries have append/import order, which is not
              ;; semantically meaningful. Keep all mappings, sort by ID.
              (let* ((path ".godot/uid_cache.bin")
                     (bytes (call-with-input-file path get-bytevector-all))
                     (count (bytevector-u32-ref bytes 0 (endianness little)))
                     (records
                      (let loop ((offset 4) (index 0) (result '()))
                        (if (= index count)
                            (begin
                              (unless (= offset (bytevector-length bytes))
                                (error "Unexpected Godot UID cache format"))
                              result)
                            (let* ((id (bytevector-u64-ref bytes offset
                                                         (endianness little)))
                                   (size (bytevector-u32-ref bytes (+ offset 8)
                                                            (endianness little)))
                                   (record (make-bytevector (+ 12 size))))
                              (bytevector-copy! bytes offset record 0 (+ 12 size))
                              (loop (+ offset 12 size) (+ index 1)
                                    (cons (cons id record) result)))))))
                (call-with-output-file path
                  (lambda (port)
                    (let ((header (make-bytevector 4)))
                      (bytevector-u32-set! header 0 count (endianness little))
                      (put-bytevector port header))
                    (for-each
                     (lambda (record) (put-bytevector port (cdr record)))
                     (sort records (lambda (a b) (< (car a) (car b))))))))
              ;; Editor caches include build paths and mtimes. Runtime needs
              ;; imported resources, class registration and UID mappings only.
              (for-each
               (lambda (path)
                 (when (file-exists? path) (delete-file-recursively path)))
               '(".godot/editor" ".godot/shader_cache" ".build-home"
                 ".godot-checked.py"))
              ;; Prevent an installed --editor invocation enabling the addon.
              ;; All compiled dialogue resources and core scripts are retained.
              (substitute* "project.godot"
                (((string-append "enabled=PackedStringArray\\(\"res://addons/"
                                 "dialogue_manager/plugin.cfg\"\\)"))
                 "enabled=PackedStringArray()"))))
          (replace 'install
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((data (string-append #$output "/share/revengate"))
                     (doc (string-append #$output "/share/doc/revengate"))
                     (bin (string-append #$output "/bin")))
                ;; Keep the original source, artwork and nested notices. Never
                ;; discard vendored attribution on the grounds it is not code.
                (copy-recursively "." data)
                (mkdir-p doc)
                (for-each (lambda (file) (install-file file doc))
                          '("COPYING.txt" "CREDITS.md" "README.md"))
                (copy-recursively "docs/legal" (string-append doc "/legal"))
                (for-each
                 (lambda (file)
                   (install-file file
                                 (string-append doc "/third-party/"
                                                (dirname file))))
                 '("addons/dialogue_manager/LICENSE"
                   "addons/kenney_particle_pack/LICENSE.txt"
                   "assets/dcss/LICENSE.txt" "assets/dcss/README.txt"))
                (call-with-output-file (string-append doc "/GUIX-CHANGES")
                  (lambda (port)
                    (display
                     (string-append
                      "The official v0.13.0 project is imported at build time "
                      "with Guix Godot 4.6.\n"
                      "The editor translation parser API is adapted to 4.6.\n"
                      "Editor update checks and installed plugin activation "
                      "are disabled.\n"
                      "Default deck builders and disposal limbo belong to the "
                      "game scene; detached HUD buttons are freed.\n"
                      "Temporary dynamic highlight nodes are freed after "
                      "packing their scene resources.\n"
                      "Imported runtime resources and complete original asset "
                      "notices are retained.\n"
                      "The launcher uses immutable project data; Godot user:// "
                      "state remains in HOME/XDG.\n"
                      "No Android export, runtime download, custom smoke mode "
                      "or game instrumentation is installed.\n") port)))
                (mkdir-p bin)
                (call-with-output-file (string-append bin "/revengate")
                  (lambda (port)
                    (format port "#!~a\nexec ~a --path ~s \"$@\"\n"
                            (search-input-file inputs "/bin/sh")
                            (search-input-file inputs "/bin/godot") data)))
                (chmod (string-append bin "/revengate") #o555)))))))
    (inputs (list bash-minimal godot))
    (native-inputs (list python))
    (home-page "https://revengate.org/")
    (synopsis "Steampunk roguelike set in nineteenth-century Lyon")
    (description
     "Revengate is a graphical, turn-based roguelike set in steampunk Lyon.
Explore its streets and dungeons, interact with characters, and pursue quests.
This package runs the original Godot project with pre-imported assets and keeps
saved games in the user's writable data directory.")
    (license
     (list license:gpl3+ license:expat license:cc0 license:public-domain
           license:cc-by3.0 license:cc-by4.0
           ;; Several artists grant CC-BY or CC-BY-SA without a version;
           ;; retain those grants verbatim instead of inventing a version.
           (license:license "CC-BY (version unspecified)"
                            (string-append
                             "https://gitlab.com/ygingras/revengate/"
                             "-/blob/v0.13.0/CREDITS.md")
                            "See the original artist grants in docs/legal.")
           (license:license "CC-BY-SA (version unspecified)"
                            (string-append
                             "https://gitlab.com/ygingras/revengate/"
                             "-/blob/v0.13.0/CREDITS.md")
                            "See the original artist grants and sound credits.")
           (license:non-copyleft
            "https://gitlab.com/ygingras/revengate/-/blob/v0.13.0/CREDITS.md"
            (string-append "Symbola font: free for any use, modification, "
                           "packaging and redistribution."))))))
