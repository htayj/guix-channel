;;; FIQHack's upstream GNUmakefile builds the native, local tty client.
;;; SPDX-License-Identifier: AGPL-3.0-or-later

(define-module (tay packages fiqhack)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages flex)
  #:use-module (tay packages auxiliary)
  #:use-module (gnu packages perl))

;; Stable tag 4.3.0 resolves to this revision, not the unstable development
;; branch.  The tag archive's content hash fixes the complete source closure.
(define %fiqhack-commit
  "6292ea1d04b5cabac2865a93e3ac0d6fa6adcb84")

(define-public fiqhack
  (package
    (name "fiqhack")
    (version "4.3.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/FredrIQ/fiqhack/tar.gz/refs/tags/"
             version))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1p2nbw575454igs0610yc8li9fhfhh9dbmgbhib7y87ii14p23yh"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:make-flags
      #~(list (string-append "CC=" #$(cc-for-target))
              (string-append "CXX=" #$(cxx-for-target))
              (string-append "BINDIR=" #$output "/bin")
              (string-append "DATADIR=" #$output "/share/fiqhack")
              ;; No system-wide mutable directory is installed.  Native
              ;; init_game_paths below obtains all writable paths at runtime.
              (string-append "STATEDIR=" #$output "/share/fiqhack"))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'bootstrap)
          (delete 'configure)
          (add-after 'unpack 'prepare-native-build
            (lambda _
              (setenv "TZ" "UTC0")
              ;; NGPL paragraph 2(a) requires dated notices in modified files.
              ;; Keep the native build date deterministic, using this commit's
              ;; committer timestamp (2017-12-07T16:12:32Z).
              (substitute* "libnethack/util/makedefs.c"
                (("time\\(&clocktim\\);")
                 (string-append
                  "/* Guix modification, 2026-10-03: reproducible build date. */\n"
                  "    clocktim = 1512663152L;")))
              ;; Use XDG data for the complete native state/config tree, with
              ;; the existing --userdir override left intact.  Read-only nhdat
              ;; and text tiles are always resolved separately from the store.
              (substitute* "nethack/src/rungame.c"
                (("envval = getenv\\(\"XDG_CONFIG_HOME\"\\);")
                 (string-append
                  "/* Guix modification, 2026-10-03: per-user XDG data state. */\n"
                  "        envval = getenv(\"XDG_DATA_HOME\");"))
                (("%s/\\.config/FIQHack/%s")
                 "%s/.local/share/FIQHack/%s")
                ;; Fresh HOME need not already contain .local/share, and an
                ;; explicit XDG data root may have several missing parents.
                (("        mkdir\\(basedir, 0755\\);")
                 (string-append
                  "        /* Guix modification, 2026-10-03: "
                  "create nested state parents. */\n"
                  "        for (char *p = basedir + 1; *p; ++p) {\n"
                  "            if (*p != '/') continue;\n"
                  "            *p = '\\0';\n"
                  "            if (mkdir(basedir, 0755) == -1 && errno != EEXIST) {\n"
                  "                umask(mask);\n"
                  "                return FALSE;\n"
                  "            }\n"
                  "            *p = '/';\n"
                  "        }\n"
                  "        mkdir(basedir, 0755);")))
              (substitute* "nethack/src/main.c"
                (((string-append
                   "    /\\* alloc memory for the paths and "
                   "append slashes as required \\*/"))
                 (string-append
                  "    /* Guix modification, 2026-10-03: native writable state,\n"
                  "       separate from the read-only compiled data prefix. */\n"
                  "#ifdef UNIX\n"
                  "    char user_state[BUFSZ];\n"
                  "    if (!override_hackdir) {\n"
                  "        if (!get_gamedir(CONFIG_DIR, user_state)) {\n"
                  "            fputs(\"fiqhack: cannot create "
                  "user state directory\\n\", stderr);\n"
                  "            exit(EXIT_FAILURE);\n"
                  "        }\n"
                  "        pathlist[BONESPREFIX] = user_state;\n"
                  "        pathlist[SCOREPREFIX] = user_state;\n"
                  "        pathlist[LOCKPREFIX] = user_state;\n"
                  "        pathlist[TROUBLEPREFIX] = user_state;\n"
                  "    }\n"
                  "#endif\n"
                  "    /* Copy paths and append slashes as required. */")))
              ;; Main's conditional RNG breakpoint on upstream test 89 showed
              ;; mintrap's ANTI_MAGIC case calling rnd(0) for a level-zero
              ;; monster.  Clamp its dice range to one, as other monster-level
              ;; callers do; positive levels keep their original dice.
              ;; Do not weaken the RNG guard or the upstream test assertions.
              (substitute* "libnethack/src/trap.c"
                (("mdrain_en\\(mtmp, rnd\\(m_mlev\\(mtmp\\)\\) \\+ 1\\);")
                 (string-append
                  "/* Guix modification, 2026-10-03: level-zero anti-magic drain. */\n"
                  "                mdrain_en(mtmp, rnd(m_mlev(mtmp) > 0 ?\n"
                  "                                    m_mlev(mtmp) : 1) + 1);")))
              ;; Upstream's deterministic TAP testbench is normally discovered
              ;; by aimake, not GNUmakefile.  Build the same harness against the
              ;; same native game objects; no network client/server is linked.
              (substitute* "testbench/src/testgame.c"
                (("const char \\*gsd = aimake_get_option\\(\"gamesdatadir\"\\);")
                 (string-append
                  "/* Guix modification, 2026-10-03: test build-tree data. */\n"
                  "    const char *gsd = getenv(\"FIQHACK_TEST_DATADIR\");\n"
                  "    if (!gsd) gsd = aimake_get_option(\"gamesdatadir\");")))
              (let ((port (open-file "GNUmakefile" "a")))
                  (display
                   (string-append
                    "\n# Guix modification, 2026-10-03: upstream TAP harness.\n"
                    "TEST_O = testbench/src/testmain.o "
                    "testbench/src/testgame.o testbench/src/tap.o\n"
                    "$(TEST_O): CPPFLAGS += -Itestbench/include\n"
                    "$(TEST_O): libnethack/include/onames.h "
                    "libnethack/include/pm.h libnethack/include/verinfo.h\n"
                    "testbench/testmain: $(TEST_O) $(filter-out "
                    "nethack/src/% libuncursed/% tilesets/%,$(GAME_O))\n"
                    "\t$(CC) $(LDFLAGS) $^ $(EXTRAS) -lz -o $@\n")
                   port)
                (close-port port))))
          (replace 'check
            (lambda* (#:key tests? make-flags #:allow-other-keys)
              (when tests?
                (apply invoke "make" "testbench/testmain" make-flags)
                (setenv "FIQHACK_TEST_DATADIR"
                        (string-append (getcwd) "/libnethack/dat"))
                ;; Round-robin commands/objects/monsters are an upstream fuzz
                ;; campaign of millions of games.  Bound its deterministic
                ;; sample, preserving upstream's crash and paniclog assertions.
                (call-with-output-file "upstream-tests"
                  (lambda (port)
                    (display "exec ./testbench/testmain --seed 1 --limit 1000\n"
                             port)))
                (invoke "prove" "--exec" "sh" "upstream-tests")
                (delete-file "upstream-tests"))))
          (add-after 'install 'install-notices
            (lambda _
              (let ((doc (string-append #$output "/share/doc/fiqhack")))
                (for-each (lambda (file) (install-file file doc))
                          '("COPYING" "copyright" "binary-copyright.pod"
                            "README.md" "libnethack/dat/license"
                            "libnethack/dat/gpl" "doc/guidebook.asc"
                            "doc/changelog-fiqhack.txt"))
                ;; These are the sole shipped tiles: NGPL text sources.  No
                ;; graphical art/fonts/sounds or optional server is installed.
                (copy-recursively "tilesets/dat/text"
                                  (string-append doc "/text-tileset-sources"))
                ;; Retain changed source and exact build instructions with the
                ;; provenance notice, supplementing the original full notices.
                (for-each
                 (lambda (file)
                   (let ((target (string-append doc "/guix-modified-source/" file)))
                     (mkdir-p (dirname target))
                     (copy-file file target)))
                 '("GNUmakefile" "libnethack/util/makedefs.c"
                   "nethack/src/main.c" "nethack/src/rungame.c"
                   "libnethack/src/trap.c" "testbench/src/testgame.c"))
                (install-file
                 #$(local-file (search-tay-package-file "fiqhack.scm")) doc)
                (call-with-output-file (string-append doc "/SOURCE-NOTICE")
                  (lambda (port)
                    (format port
                            (string-append
                             "FIQHack ~a, stable tag ~a, upstream commit ~a.~%"
                             "Source: https://codeload.github.com/"
                             "FredrIQ/fiqhack/tar.gz/refs/tags/~a~%"
                             "Archive SHA256: d00f714988f1207f5684ebd5"
                             "d512840eba1429621e0403f48ba490720a5f56dc~%"
                             "Guix changes dated 2026-10-03: deterministic "
                             "date, native XDG data paths,~%"
                             "level-zero monster anti-magic drain, and "
                             "upstream TAP harness integration.~%"
                             "Modified sources and fiqhack.scm are "
                             "retained here.~%"
                             "Rebuild with guix build -L CHANNEL/guix "
                             "fiqhack.~%"
                             "Only the local GNUmakefile tty client and "
                             "NGPL nhdat/text tiles ship.~%"
                             "libuncursed permits NGPL or GPL-2+; Jansson "
                             "and graphical art are not~%"
                             "linked or installed by this build.  copyright "
                             "retains all upstream notices.~%")
                            #$version #$version #$%fiqhack-commit #$version)))))))))
    (native-inputs (list bison flex perl))
    (inputs (list zlib))
    (home-page "https://github.com/FredrIQ/fiqhack")
    (synopsis "NetHack variant with a native terminal interface")
    (description
     "FIQHack is an independently playable NetHack4 variant with revised
monsters, items, spells and dungeon mechanics.  This package builds the stable
local terminal client and complete dungeon data from source, including the ASCII
and Unicode text tilesets.  The optional network server and graphical assets
are not installed.  Configuration, saves, bones, scores, locks and logs use the
native per-user FIQHack directory under XDG_DATA_HOME, or ~/.local/share.
Installed documentation includes upstream licenses, third-party notices and
source provenance.  The external tests/fiqhack-smoke.sh exercises native play;
the installed executable has no testing mode.")
    ;; Text assets and the linked game are NGPL; libuncursed offers GPL-2+
    ;; alternatively.  The complete copyright notice is installed unchanged.
    (license (list (license:fsdg-compatible
                    "https://nethack.org/common/license.html")
                   license:gpl2+))))
