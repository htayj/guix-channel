;;; GNU Guix package for Please the Island God, the PlomRogue PtIG release.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages plomrogue)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages python))

(define-public plomrogue
  (package
    (name "plomrogue")
    (version "0-1.20170821")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/plomlompom/plomrogue")
             ;; The PtIG tag, not the unrelated newer engine branches.
             (commit "32c8b0d55c091b10ba683621d7881ef57ce8a88a")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0inw5ddi33gb4pm26bygnnjd22xbbjjpv291l957xjl6hxdr7aw5"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'use-packaged-python
            (lambda _
              (setenv "PYTHONDONTWRITEBYTECODE" "1")
              (substitute* '("start_server_client_union.sh" "test_server.sh")
                (("python3") (string-append #$python "/bin/python3")))))
          (add-after 'use-packaged-python 'preserve-save-continuation
            (lambda _
              (define things-loop
                (string-append
                 "for ([a-zA-Z_]+) in world_db\\[\"Things\"\\]"
                 "([[:space:]]+if|[[:space:]]*$|\\]|:)"))
              ;; The native save format orders Things by ID.  Modern Python
              ;; preserves insertion order, so deletion/reuse changes actor
              ;; scheduling and same-cell precedence after a save/reload.
              ;; Canonical ID order makes the saved RNG stream continue exactly.
              ;; Keep the turn-start snapshot: births must wait until next turn.
              (substitute* (append (find-files "server" "\\.py$")
                                   (find-files "plugins/server" "\\.py$"))
                ((things-loop all variable suffix)
                 (string-append "for " variable
                                " in sorted(world_db[\"Things\"])" suffix))
                (("for Thing in world_db\\[\"Things\"\\]\\.values\\(\\)")
                 (string-append
                  "for Thing in (world_db[\"Things\"][tid] "
                  "for tid in sorted(world_db[\"Things\"]))")))))
          (replace 'build
            (lambda _ (invoke "sh" "build.sh")))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                ;; Upstream's diff|wc pipeline reports a mismatch without
                ;; failing.  Require exact equality with its original oracle.
                ;; Canonical actor ID order restores this semantic regression
                ;; on modern Python without changing any expected save data.
                (invoke "sh" "test_server.sh")
                (invoke "cmp" "testing/last_end" "testing/ref_end"))))
          (replace 'install
            (lambda _
              (let ((data (string-append #$output "/share/plomrogue"))
                    (doc (string-append #$output "/share/doc/plomrogue"))
                    (bin (string-append #$output "/bin")))
                (mkdir-p data)
                (mkdir-p bin)
                ;; Install complete source/data and notices, but none of the
                ;; check phase's generated profiles, saves, or copied modules.
                (for-each
                 (lambda (directory)
                   (copy-recursively directory
                                     (string-append data "/" directory)))
                 '("server" "client" "plugins" "confserver"))
                (for-each
                 (lambda (file) (install-file file data))
                 '("roguelike" "roguelike-server" "roguelike-client"
                   "start_server_client_union.sh" "build.sh" "test_server.sh"
                   "libplomrogue.c" "libplomrogue.so" "NOTICE" "GPLv3"
                   "README" "README_PtIG" "SERVER_COMMANDS" "TODO"))
                (for-each
                 (lambda (file)
                   (install-file (string-append "testing/" file)
                                 (string-append data "/testing")))
                 '("start" "run" "ref_end"))
                (for-each
                 (lambda (file) (install-file file doc))
                 '("NOTICE" "GPLv3" "README" "README_PtIG" "SERVER_COMMANDS"))
                ;; Only engine resources are linked into the writable state
                ;; directory.  Relative save/record/log/server_run paths remain
                ;; local, while imports and the library stay immutable.
                (call-with-output-file (string-append bin "/plomrogue")
                  (lambda (port)
                    (format port "#!~a/bin/python3\n" #$python)
                    (display
                     (string-append "import os\nfrom pathlib import Path\n"
                                    "import subprocess\nimport sys\n\n")
                     port)
                    (format port "data = Path(~s)\n" data)
                    (display
                     (string-append
                      "state = Path(os.environ.get('XDG_STATE_HOME') or "
                      "(Path.home() / '.local/state')) / 'plomrogue'\n"
                      "state.mkdir(parents=True, exist_ok=True, mode=0o700)\n"
                      "for name in ('server', 'client', 'plugins', "
                      "'confserver', 'roguelike', 'start_server_client_union.sh', "
                      "'roguelike-server', 'roguelike-client', "
                      "'libplomrogue.so'):\n"
                      "    target = state / name\n"
                      "    if not target.is_symlink() "
                      "or target.resolve() != data / name:\n"
                      "        if target.is_symlink():\n"
                      "            target.unlink()\n"
                      "        elif target.exists():\n"
                      "            raise SystemExit('Cannot replace user file: ' "
                      "+ str(target))\n"
                      "        target.symlink_to(data / name, "
                      "target_is_directory=(data / name).is_dir())\n"
                      "env = os.environ.copy()\n"
                      "env['PYTHONDONTWRITEBYTECODE'] = '1'\n")
                     port)
                    (format port
                            (string-append "env['PATH'] = ~s + os.pathsep "
                                           "+ env.get('PATH', '')\n")
                            (string-append #$python "/bin:"
                                           #$coreutils-minimal "/bin:"
                                           #$bash-minimal "/bin"))
                    (format port "env['TERMINFO'] = ~s\n"
                            (string-append #$ncurses "/share/terminfo"))
                    (display
                     (string-append
                      "sys.exit(subprocess.run([str(data / 'roguelike'), "
                      "*sys.argv[1:]], cwd=state, env=env).returncode)\n")
                     port)))
                (chmod (string-append bin "/plomrogue") #o555)))))))
    (inputs (list python ncurses coreutils-minimal bash-minimal))
    (home-page "https://github.com/plomlompom/plomrogue/releases/tag/PtIG")
    (synopsis "Ecological island roguelike with an ASCII terminal interface")
    (description
     "Please the Island God is the default game in this pinned PlomRogue
release.  Stranded on a hexagonal island, the player must please its god by
feeding wildlife, cultivating plants and completing missions while surviving.
The native Python curses client and C-backed server communicate through local
files.  Saves, recordings and logs are kept under XDG_STATE_HOME/plomrogue,
or ~/.local/state/plomrogue when XDG_STATE_HOME is unset.  Actor IDs define a
canonical iteration order, matching save serialization so reloaded worlds
continue the saved random stream.  The original upstream server test and
reference are included unchanged, and the build requires exact equality with
that reference after its 90 AI actions.")
    (license license:gpl3+)))
