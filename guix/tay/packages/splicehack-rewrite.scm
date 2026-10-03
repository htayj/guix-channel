;;; GNU Guix package for the SpliceHack Rewrite tty roguelike.

(define-module (tay packages splicehack-rewrite)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages groff)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages linux))

(define %splicehack-commit
  "0cf23cb19eedd6b985502b1b8fdc86fd249a8172")

(define %splicehack-lua
  (origin
    (method url-fetch)
    (uri "https://www.lua.org/ftp/lua-5.4.2.tar.gz")
    (sha256
     (base32 "0ksj5zpj74n0jkamy3di1p6l10v4gjnd2zjnb453qc6px6bhsmqi"))))

(define-public splicehack-rewrite
  (package
    (name "splicehack-rewrite")
    (version "0.8.2-0.0cf23cb")
    (source
     (origin
       ;; The archive has no PDCurses gitlink; the optional Windows port is
       ;; outside this tty-only source and installed closure.
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/RojjaCebolla/SpliceHack-Rewrite/tar.gz/"
             %splicehack-commit))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "1z71vi128kbrxfhw7gcf9prd5n66xy6l22f66sq3qqhdyj75ipa6"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; Generated headers, Lua, makedefs, and dlb have ordering dependencies
      ;; not completely described by the historical makefiles.
      #:parallel-build? #f
      ;; The installed game is exercised by the external native consumer in
      ;; tests/splicehack-rewrite-smoke.sh, never by an installed test mode.
      ;; test/*.lua requires game-specific nh/des/selection bindings.  The
      ;; pinned sys/libnh/test/libtest.c is an unfinished interactive renderer
      ;; callback stub, not a runnable regression harness or check target.
      #:tests? #f
      #:make-flags
      #~(list (string-append "CC=" #$(cc-for-target))
              (string-append "LINK=" #$(cc-for-target))
              (string-append
               "CFLAGS=-O2 -g0 -std=gnu99 -fcommon -D_DEFAULT_SOURCE -DLUA_USE_POSIX "
               "-I../include -DDLB -DREPRODUCIBLE_BUILD -DNOMAIL -DNOSHELL "
               "-DNOUSER_SOUNDS -DFCMASK=0600 "
               "-DHACKDIR=\\\"" #$output "/share/splicehack-rewrite\\\" "
               "-DCOMPRESS=\\\"" #$(file-append gzip "/bin/gzip")
               "\\\" -DCOMPRESS_EXTENSION=\\\".gz\\\"")
              "WINTTYLIB=-lncurses -ltinfo"
              "GITINFO=0")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'prepare-build
            (lambda* (#:key inputs #:allow-other-keys)
              (mkdir-p "lib")
              (invoke "tar" "xf" (assoc-ref inputs "lua-source") "-C" "lib")
              ;; Preserve compiler-owned attribute identifiers: empty macro
              ;; definitions break glibc's __has_attribute query expansion.
              (substitute* "include/tradstdc.h"
                (((string-append
                   "/\\* disable gcc's __attribute__\\(\\("
                   "__warn_unused_result__\\)\\) since explicitly"))
                 (string-append
                  "/* Guix, 2026-10-03: preserve compiler attributes. */\n"
                  "/* Historically, explicitly"))
                (("^#define (__warn_unused_result__|warn_unused_result) /\\*empty\\*/")
                 ""))
              ;; windows.c always defines livelog_dump_url (it handles the
              ;; non-DUMPLOG case itself), and end.c always calls it.
              (let ((removed 0) (inserted 0))
                (substitute* "include/extern.h"
                  (("^extern void livelog_dump_url\\(unsigned int\\);[[:space:]]*$")
                   (set! removed (+ removed 1))
                   "")
                  (("^extern void dump_open_log\\(time_t\\);[[:space:]]*$")
                   (set! inserted (+ inserted 1))
                   (string-append
                    "/* Guix, 2026-10-03: match unconditional implementation "
                    "and caller of livelog_dump_url. */\n"
                    "extern void livelog_dump_url(unsigned int);\n"
                    "extern void dump_open_log(time_t);\n")))
                (unless (and (= removed 1) (= inserted 1))
                  (error "unexpected livelog declaration patch match counts"
                         removed inserted)))
              ;; Pirate speech is gameplay, not a dump-log facility.  The
              ;; historical guard accidentally hides both helpers while the
              ;; ordinary message path still calls piratesay unconditionally.
              (let ((closed 0) (opened 0))
                (substitute* "src/pline.c"
                  (("^/\\*Ben Collver's fixes\\*/[[:space:]]*$" all)
                   (set! closed (+ closed 1))
                   (if (= closed 1)
                       (string-append
                        "#endif\n"
                        "/* Guix, 2026-10-03: compile pirate speech in all "
                        "gameplay configurations. */\n" all)
                       all))
                  (((string-append
                     "^/\\* keep the most recent DUMPLOG_MSG_COUNT messages "
                     "\\*/[[:space:]]*$") all)
                   (set! opened (+ opened 1))
                   (string-append "#if defined(DUMPLOG) || defined(DUMPHTML)\n" all)))
                (unless (and (= closed 2) (= opened 1))
                  (error "unexpected pirate speech guard patch match counts"
                         closed opened)))
              ;; dat/symbols still carries ten entries for six symbols absent
              ;; from this rewrite's rm.h, trap.h, and symbols.c vocabulary.
              ;; They cannot name real glyphs; remove stale records, not the
              ;; native parser diagnostics or supported symbol sets.
              (let ((removed 0))
                (substitute* "dat/symbols"
                  (((string-append
                     "^[[:blank:]]*S_(furnace|buzzsaw_trap|whirlwind_trap|"
                     "ice_block_trap|sin|zouthern):.*$"))
                   (set! removed (+ removed 1))
                   "")
                  (("^# NetHack 3\\.7  symbols" all)
                   (string-append
                    "# Guix, 2026-10-03: remove stale non-rewrite glyph records.\n"
                    all)))
                (unless (= removed 10)
                  (error "unexpected stale symbol record match count" removed)))
              (substitute* "include/config.h"
                (("^#define SYSCF([[:space:]]|$).*$")
                 (string-append
                  "/* Guix, 2026-10-03: use private per-user configuration, "
                  "not global sysconf. */\n/* #define SYSCF */\n"))
                (("^#define SYSCF_FILE[[:space:]]+.*$")
                 "/* #define SYSCF_FILE */\n"))
              (substitute* "include/unixconf.h"
                (("^/\\*[[:space:]]+#define VAR_PLAYGROUND.*$")
                 (string-append
                  "/* Guix, 2026-10-03: launcher supplies private writable "
                  "state while HACKDIR remains immutable. */\n"
                  "#define VAR_PLAYGROUND nh_getenv(\"SPLICEHACK_VAR_PLAYGROUND\")\n")))
              ;; Both upstream fetch targets are made unavailable.  Lua is
              ;; supplied solely by the independently hash-verified origin.
              (substitute* "sys/unix/Makefile.top"
                (("^fetch-lua: fetch-Lua[[:space:]]*$")
                 "# Guix, 2026-10-03: Lua is an offline fixed origin.\nfetch-lua:\n")
                (("^fetch-Lua:[[:space:]]*$") "fetch-Lua:\n\t@false\n")
                (("^[[:blank:]]+\\( mkdir -p lib && cd lib &&.*$") "")
                (("^[[:blank:]]+curl -R -O http://www.lua.org/ftp/lua-.*$") "")
                (("^[[:blank:]]+tar zxf lua-.*$") "")
                (("^[[:blank:]]+-rm include/nhlua.h[[:space:]]*$") ""))
              ;; Keep every rewrite level available to dungeon.lua through
              ;; DLB; upstream's inherited inventory omits eleven new levels.
              (let ((matched 0))
                (substitute* "sys/unix/Makefile.top"
                  (("^[[:blank:]]+rats\\.lua[[:space:]]*$")
                   (set! matched (+ matched 1))
                   (string-append
                    "\trats.lua banquet.lua brass.lua darkforest.lua "
                    "foogardens.lua gemarray.lua ice.lua icewaste.lua "
                    "laboratory.lua mephisto.lua statuary.lua void.lua\n"
                    "# Guix, 2026-10-03: include all rewrite special levels.\n")))
                (unless (= matched 1)
                  (error "unexpected special level inventory match count" matched)))
              ;; Pin even the clock used to validate SOURCE_DATE_EPOCH, so
              ;; makedefs never depends on the build machine's wall clock.
              (substitute* "util/makedefs.c"
                (("\\(void\\) time\\(&clocktim\\);")
                 (string-append
                  "/* Guix, 2026-10-03: fixed upstream revision timestamp. */\n"
                  "    clocktim = (time_t) 1628715174;")))
              (substitute* "sys/unix/setup.sh"
                (("/bin/sh") #$(file-append bash-minimal "/bin/sh"))
                (("^#!([^\n]+)")
                 (string-append "#!" #$(file-append bash-minimal "/bin/sh")
                                "\n# Guix, 2026-10-03: use the build-input shell.")))
              (substitute* "doc/Guidebook.mn"
                (("^\\.so tmac\\.nh[[:blank:]]+.*$")
                 (string-append
                  ".\\\" Guix, 2026-10-03: normalize include whitespace for groff.\n"
                  ".so tmac.nh\n")))
              (invoke "sh" "sys/unix/setup.sh" "sys/unix/hints/linux-minimal")
              (setenv "SOURCE_DATE_EPOCH" "1628715174")
              (setenv "TZ" "UTC0")))
          (replace 'build
            (lambda* (#:key make-flags #:allow-other-keys)
              (apply invoke "make" "all" make-flags)))
          (delete 'install-license-files)
          ;; Never invoke upstream install: it recursively removes playgrounds
          ;; and installs mutable files alongside shared data.
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/splicehack-rewrite"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (doc (string-append out "/share/doc/splicehack-rewrite"))
                     (real (string-append libexec "/splicehack-rewrite-real"))
                     (launcher (string-append bin "/splicehack-rewrite")))
                (for-each mkdir-p (list data libexec bin doc))
                (copy-file "src/nethack" real)
                (chmod real #o555)
                (for-each (lambda (file) (install-file file data))
                          '("dat/nhdat" "dat/license" "dat/symbols"))
                (for-each (lambda (file) (install-file file doc))
                          '("README" "src/isaac64.c"
                            "doc/spl-sources.txt" "doc/spl-changelog.txt"))
                (copy-file "doc/Guidebook" (string-append doc "/Guidebook.txt"))
                (copy-file "dat/license" (string-append doc "/license"))
                (copy-file "lib/lua-5.4.2/doc/readme.html"
                           (string-append doc "/lua-readme.html"))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%umask 077~%
state=\"${XDG_DATA_HOME:-${HOME:?}/.local/share}/splicehack-rewrite\"~%
config=\"${XDG_CONFIG_HOME:-${HOME:?}/.config}/splicehack-rewrite\"~%
export SPLICEHACK_VAR_PLAYGROUND=\"$state/\"~%
# nh_getenv rejects values longer than 128 bytes; fail before a NULL prefix.~%
bytes=$(LC_ALL=C; echo \"${#SPLICEHACK_VAR_PLAYGROUND}\")~%
if test \"$bytes\" -gt 128; then~%
  echo 'splicehack-rewrite: state path exceeds 128 bytes' >&2~%
  exit 1~%
fi~%
bytes=$(LC_ALL=C; echo \"${#config}\")~%
if test \"$bytes\" -gt 128; then~%
  echo 'splicehack-rewrite: config path exceeds 128 bytes' >&2~%
  exit 1~%
fi~%
~s -p \"$state/save\" \"$state/whereis\" \"$config\"~%
for file in perm record logfile xlogfile livelog paniclog; do~%
  test -e \"$state/$file\" || : > \"$state/$file\"~%
done~%
export HOME=\"$config\" HACKDIR=~s NETHACKDIR=~s~%
exec ~s \"$@\"~%"
                            #$(file-append bash-minimal "/bin/sh")
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            data data real)))
                (chmod launcher #o555))))
          (add-after 'install 'verify-license-notices
            (lambda _
              (let ((data (string-append #$output "/share/splicehack-rewrite/"))
                    (doc (string-append #$output "/share/doc/splicehack-rewrite/")))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append data file))
                     (error "missing SpliceHack runtime file" file)))
                 '("nhdat" "license" "symbols"))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append doc file))
                     (error "missing SpliceHack notice" file)))
                 '("README" "Guidebook.txt" "isaac64.c" "lua-readme.html"
                   "license" "spl-sources.txt" "spl-changelog.txt"))
                (invoke "grep" "-F" "NETHACK GENERAL PUBLIC LICENSE"
                        (string-append data "license"))
                (invoke "grep" "-F" "Permission is hereby granted"
                        (string-append doc "lua-readme.html")))))
          (add-after 'compress-documentation 'make-output-immutable
            (lambda _
              (for-each
               (lambda (file)
                 (chmod file (cond ((file-is-directory? file) #o555)
                                   ((access? file X_OK) #o555)
                                   (else #o444))))
               (find-files #$output ".*" #:directories? #t)))))))
    (native-inputs
     `(("groff-minimal" ,groff-minimal)
       ("util-linux" ,util-linux)
       ("lua-source" ,%splicehack-lua)))
    (inputs
     (list bash-minimal coreutils-minimal gzip ncurses/tinfo))
    (home-page "https://github.com/RojjaCebolla/SpliceHack-Rewrite")
    (synopsis "SpliceHack's NetHack 3.7 rewrite for the terminal")
    (description
     "SpliceHack Rewrite is an independently playable NetHack 3.7 variant
with new monsters, roles, races, and dungeon features.  This package builds
only its terminal interface from fixed source origins, including embedded
Lua, and generates the game data offline.  Saves, bones, scores, locks, logs,
and configuration remain in private per-user XDG directories; immutable
runtime data and license notices stay in the store.")
    (license
     (list (license:fsdg-compatible "https://nethack.org/common/license.html")
           license:expat license:cc0))))
