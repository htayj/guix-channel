;;; GNU Guix package for the Hardfought SLASH'EM tty variant.

(define-module (tay packages slashem)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages groff)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ncurses))

(define %slashem-commit "aae9ef2e4c2e5b591a3bc5ded888bab1e157b20b")

(define-public slashem
  (package
    (name "slashem")
    (version "0.0.8E0F2-0.aae9ef2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://codeload.github.com/k21971/SlashEM/tar.gz/"
                           %slashem-commit))
       (file-name (string-append name "-" version ".tar.gz"))
       (sha256
        (base32 "01wr4wc4zcc87f6mbcx0nmdxgylmr2j1g7c5x6q052xdakp632g4"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:parallel-build? #f
      ;; No upstream check target or runnable test suite exists at this pin.
      ;; tests/slashem-smoke.sh drives ordinary native gameplay externally.
      #:tests? #f
      #:configure-flags
      #~(list "--enable-tty-graphics" "--disable-proxy-graphics"
              "--disable-x11-graphics" "--disable-sdl-graphics"
              "--disable-gl-graphics" "--disable-mswin-graphics"
              "--with-owner=no" "--with-group=no"
              (string-append "--with-compression="
                             #$(file-append gzip "/bin/gzip")))
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'prepare-native-source
            (lambda _
              ;; All edited source carries a dated NGPL change notice.  Match
              ;; counts fail closed; [[:blank:]] avoids eating line boundaries.
              (let ((playground 0) (mail 0) (mask 0))
                (substitute* "include/unixconf.h"
                  (("^/\\* #define VAR_PLAYGROUND[^\n]*" all)
                   (set! playground (+ playground 1))
                   (string-append
                    "/* Guix, 2026-10-03: private per-user writable playground. */\n"
                    "#define VAR_PLAYGROUND nh_getenv(\"SLASHEM_VAR_PLAYGROUND\")"))
                  (("^#define MAIL[[:blank:]]+[^\n]*")
                   (set! mail (+ mail 1))
                   "/* Guix, 2026-10-03: no external mail reader in local play. */")
                  (("^#define FCMASK[[:blank:]]+[^\n]*")
                   (set! mask (+ mask 1))
                   (string-append
                    "/* Guix, 2026-10-03: private state permissions. */\n"
                    "#define FCMASK 0600")))
                (unless (and (= playground 1) (= mail 1) (= mask 1))
                  (error "unexpected Unix state patch counts" playground mail mask)))
              (let ((hackdir 0) (dump 0) (extra 0))
                (substitute* "include/config.h"
                  (("^#    define HACKDIR \"/slashem-0\\.0\\.8E0F2\"[^\n]*")
                   (set! hackdir (+ hackdir 1))
                   (string-append
                    "/* Guix, 2026-10-03: immutable native game data. */\n"
                    "#    define HACKDIR \"" #$output "/share/slashem\""))
                  (("^#define DUMP_FN[^\n]*")
                   (set! dump (+ dump 1))
                   (string-append
                    "/* Guix, 2026-10-03: retain dumps inside private state. */\n"
                    "#define DUMP_FN nh_getenv(\"SLASHEM_DUMPFILE\")"))
                  (("^#define EXTRAINFO_FN[^\n]*")
                   (set! extra (+ extra 1))
                   (string-append
                    "/* Guix, 2026-10-03: no server dgamelaunch state in local play. */\n"
                    "/* #define EXTRAINFO_FN */")))
                (unless (and (= hackdir 1) (= dump 1) (= extra 1))
                  (error "unexpected immutable data patch counts" hackdir dump extra)))
              ;; dump_fn was an array initialized from a literal.  Its native
              ;; formatter accepts a const string; retain that API with the
              ;; environment-selected private absolute filename instead.
              (let ((definition 0) (declaration 0))
                (substitute* "src/decl.c"
                  (("^char dump_fn\\[\\] = DUMP_FN;")
                   (set! definition (+ definition 1))
                   (string-append
                    "/* Guix, 2026-10-03: resolve private dump path at runtime. */\n"
                    "char *dump_fn;")))
                (substitute* "include/decl.h"
                  (("^E char dump_fn\\[\\];[^\n]*")
                   (set! declaration (+ declaration 1))
                   (string-append
                    "/* Guix, 2026-10-03: environment-backed native dump path. */\n"
                    "E char *dump_fn;")))
                (unless (and (= definition 1) (= declaration 1))
                  (error "unexpected dump path declaration counts"
                         definition declaration)))
              (let ((initialization 0) (assignment 0))
                (substitute* "src/options.c"
                  (("^initoptions\\(\\)")
                   (set! initialization (+ initialization 1))
                   (string-append
                    "/* Guix, 2026-10-03: initialize the native private "
                    "dump path. */\n"
                    "initoptions()"))
                  (("^[[:blank:]]*opts = getenv\\(NETHACK_ENV_OPTIONS\\);")
                   (set! assignment (+ assignment 1))
                   "\tdump_fn = DUMP_FN;\n\topts = getenv(NETHACK_ENV_OPTIONS);"))
                (unless (and (= initialization 1) (= assignment 1))
                  (error "unexpected options initialization counts"
                         initialization assignment)))
              ;; Status colors call the tty API, whose declarations live in
              ;; wintty.h.  Ending a terminal color takes no argument.
              (let ((header 0) (end-color 0))
                (substitute* "src/botl.c"
                  (("^#include \"hack.h\"")
                   (set! header (+ header 1))
                   (string-append
                    "#include \"hack.h\"\n"
                    "/* Guix, 2026-10-03: declare native tty status-color API. */\n"
                    "#include \"wintty.h\""))
                  (("term_end_color\\(color_option\\.color\\);")
                   (set! end-color (+ end-color 1))
                   "term_end_color(); /* Guix, 2026-10-03: native no-argument API. */"))
                (unless (and (= header 1) (= end-color 1))
                  (error "unexpected status color API counts" header end-color)))
              (let ((no-glyph 0))
                (substitute* "src/display.c"
                  (("^[[:blank:]]*return ;")
                   (set! no-glyph (+ no-glyph 1))
                   (string-append
                    "        return ' '; "
                    "/* Guix, 2026-10-03: absent dump glyph is blank. */")))
                (unless (= no-glyph 1)
                  (error "unexpected no-glyph dump return count" no-glyph)))
              ;; list_vanquished reports whether anything died; the dump
              ;; implementation computes that result, so it must return it.
              (let ((declaration 0) (forward 0) (definition 0) (pending #f))
                (substitute* "src/end.c"
                  (("^void FDECL\\(do_vanquished, \\(int, BOOLEAN_P, BOOLEAN_P\\)\\);")
                   (set! declaration (+ declaration 1))
                   (string-append
                    "/* Guix, 2026-10-03: vanquished listing reports any deaths. */\n"
                    "boolean FDECL(do_vanquished, (int, BOOLEAN_P, BOOLEAN_P));"))
                  (("^  do_vanquished\\(defquery, ask, FALSE\\);")
                   (set! forward (+ forward 1))
                   (set! pending #t)
                   "  return do_vanquished(defquery, ask, FALSE); /* Guix, 2026-10-03 */")
                  (("^void")
                   (if pending
                       (begin
                         (set! pending #f)
                         (set! definition (+ definition 1))
                         "boolean /* Guix, 2026-10-03: returns any vanquished count. */")
                       "void")))
                (unless (and (= declaration 1) (= forward 1) (= definition 1))
                  (error "unexpected vanquished return patch counts"
                         declaration forward definition)))
              (let ((status-parser 0) (door 0))
                (substitute* "include/extern.h"
                  (("^E void NDECL\\(initoptions\\);")
                   (set! status-parser (+ status-parser 1))
                   (string-append
                    "/* Guix, 2026-10-03: share native options parser with files.c. */\n"
                    "E boolean FDECL(parse_status_color_options, (char *));\n"
                    "E void NDECL(initoptions);"))
                  (("^E int NDECL\\(doopen\\);")
                   (set! door (+ door 1))
                   (string-append
                    "/* Guix, 2026-10-03: native auto-open direction API. */\n"
                    "#ifdef AUTO_OPEN\nE int FDECL(doopen_indir, (int, int));\n#endif\n"
                    "E int NDECL(doopen);")))
                (unless (and (= status-parser 1) (= door 1))
                  (error "unexpected shared API declaration counts" status-parser door)))
              (let ((artifact-type 0))
                (substitute* "src/potion.c"
                  (("int chg, otyp = obj->otyp, otyp2;")
                   (set! artifact-type (+ artifact-type 1))
                   (string-append
                    "int chg, otyp = obj->otyp;\n"
                    "\tshort otyp2; "
                    "/* Guix, 2026-10-03: artifact_name writes short. */")))
                (unless (= artifact-type 1)
                  (error "unexpected artifact type storage count" artifact-type)))
              (let ((abort-tech 0))
                (substitute* "src/tech.c"
                  (("^aborttech\\(tech\\)")
                   (set! abort-tech (+ abort-tech 1))
                   (string-append
                    "aborttech(tech)\n"
                    "int tech; /* Guix, 2026-10-03: match get_tech_no integer ID. */")))
                (unless (= abort-tech 1)
                  (error "unexpected abort technique parameter count" abort-tech)))
              (let ((clock 0))
                (substitute* "util/makedefs.c"
                  (("\\(void\\) time\\([^\n]*\\);")
                   (set! clock (+ clock 1))
                   (string-append
                    "/* Guix, 2026-10-03: pinned upstream revision timestamp. */\n"
                    "\tclocktim = 1707587348;")))
                (unless (= clock 2)
                  (error "unexpected build clock patch count" clock)))
              (let ((archive 0))
                (substitute* "sys/autoconf/Makefile.top"
                  (("^UNSHARE_DATDLB =[^\n]*")
                   (set! archive (+ archive 1))
                   (string-append
                    "# Guix, 2026-10-03: archive every generated native special level.\n"
                    "UNSHARE_DATDLB = dungeon $(notdir $(sort $(wildcard dat/*.lev)))")))
                (unless (= archive 1)
                  (error "unexpected native archive inventory count" archive)))
              ;; ncurses exports has_colors while its split libtinfo exports
              ;; tgetent.  Supply the dependency to the genuine native link
              ;; probe; successful -lncurses selection then retains both.
              (setenv "LIBS" "-ltinfo")
              (let ((libs 0))
                (substitute* "sys/autoconf/Makefile.src"
                  (("^LIBS =[[:blank:]]*")
                   (set! libs (+ libs 1))
                   (string-append
                    "# Guix, 2026-10-03: retain configured native link dependencies.\n"
                    "LIBS = @LIBS@")))
                (unless (= libs 1)
                  (error "unexpected native link library template count" libs)))
              (let ((room-door 0))
                (substitute* "util/lev_comp.y"
                  (("tmprdoor\\[ndoor\\] = \\(struct room_door \\*\\)0;")
                   (set! room-door (+ room-door 1))
                   (string-append
                    "tmprdoor[ndoor] = (room_door *)0; "
                    "/* Guix, 2026-10-03: use actual typedef. */")))
                (unless (= room-door 1)
                  (error "unexpected level grammar door type count" room-door)))
              ;; GCC's pre-C23 dialect accepts this source's K&R definitions.
              ;; Keep AUTOCONF in upstream CC; configure receives only CFLAGS.
              (setenv "CFLAGS" "-O2 -g0 -std=gnu11 -fcommon")
              ;; Old AC_PATH_PROG searches PATH/absolute-name incorrectly;
              ;; COMPRESS is its supported absolute executable override.
              (setenv "COMPRESS" #$(file-append gzip "/bin/gzip"))
              (setenv "TZ" "UTC0")
              (setenv "SOURCE_DATE_EPOCH" "1707587348")))
          (replace 'build
            (lambda* (#:key make-flags #:allow-other-keys)
              (apply invoke "make" "all" make-flags)))
          (delete 'install-license-files)
          ;; Upstream install removes playgrounds and sets games ownership.
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/slashem"))
                     (doc (string-append out "/share/doc/slashem"))
                     (bin (string-append out "/bin"))
                     (libexec (string-append out "/libexec"))
                     (real (string-append libexec "/slashem-real")))
                (for-each mkdir-p (list data doc bin libexec))
                (copy-file "src/slashem" real)
                (chmod real #o555)
                (install-file "util/recover" libexec)
                (for-each (lambda (file) (install-file file data))
                          '("dat/nhshare" "dat/nhushare" "dat/license"))
                (copy-file "doc/Guidebook" (string-append data "/Guidebook.txt"))
                (copy-file "doc/Guidebook" (string-append doc "/Guidebook.txt"))
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE" "dat/license" "readme.txt" "README.34"
                            "history.txt" "README-compile.txt" "Porting"))
                (install-file "doc/slashem.6" (string-append out "/share/man/man6"))
                ;; Include corresponding native source with original notices,
                ;; dated changes, and generated headers; omit optional sound,
                ;; font, tile and graphical-port assets entirely.
                (let ((source (string-append doc "/tty-source")))
                  (for-each
                   (lambda (directory)
                     (for-each
                      (lambda (file)
                        (install-file file (string-append source "/" (dirname file))))
                      (find-files directory "\\.(c|h|l|y|des)$")))
                   '("src" "include" "util" "dat" "sys/unix" "sys/share"
                     "win/tty" "win/share"))
                  (copy-recursively "sys/autoconf" (string-append source "/sys/autoconf"))
                  (install-file "sys/winnt/win32api.h"
                                (string-append source "/sys/winnt"))
                  (for-each
                   (lambda (file) (install-file file (string-append source "/dat")))
                   '("dat/data.base" "dat/quest.txt" "dat/rumors.tru" "dat/rumors.fal"
                     "dat/oracles.txt" "dat/dungeon.def" "dat/help" "dat/hh" "dat/cmdhelp"
                     "dat/history" "dat/opthelp" "dat/wizhelp" "dat/gypsy.txt"
                     "dat/license"))
                  (for-each (lambda (file) (install-file file source))
                            '("configure" "LICENSE" "readme.txt" "Porting"
                              "slamfaq.txt" "README-compile.txt" "Files"))
                  (for-each
                   (lambda (file)
                     (install-file file (string-append source "/doc")))
                   '("doc/Guidebook.mn" "doc/tmac.n" "doc/slashem.6"
                     "doc/recover.6")))
                (call-with-output-file (string-append doc "/GUIX-CHANGES")
                  (lambda (port)
                    (display
                     (string-append
                      "SLASH'EM 0.0.8E0F2, Hardfought source revision "
                      #$%slashem-commit "\n"
                      "Source: https://github.com/k21971/SlashEM\n"
                      "2026-10-03: Guix retains native tty gameplay and NGPL notices.\n"
                      "Modified files carry dated notices: unixconf.h redirects mutable\n"
                      "state, uses private permissions and removes external mail; "
                      "config.h\n"
                      "pins immutable data, redirects dumps, disables server extrainfo;\n"
                      "decl.c/decl.h/options.c initialize the environment-backed "
                      "dump path;\n"
                      "makedefs.c fixes build time; Makefile.top includes every "
                      "native level.\n"
                      "botl.c includes native tty prototypes and fixes end-color arity.\n"
                      "display.c returns a blank dump cell for absent glyphs; end.c\n"
                      "returns the vanquished-list boolean through its dump "
                      "implementation.\n"
                      "extern.h declares native status-color parsing and "
                      "auto-open APIs.\n"
                      "potion.c uses short storage matching artifact_name's "
                      "output type.\n"
                      "tech.c explicitly declares aborttech's integer technique ID.\n"
                      "Ncurses probe uses libtinfo; Makefile.src retains "
                      "configured LIBS.\n"
                      "COMPRESS selects the store gzip executable.\n"
                      "lev_comp.y uses the actual anonymous room_door typedef for NULL.\n"
                      "The package uses GNU C11, serial offline make all, no privileged\n"
                      "installation, and a launcher with private XDG "
                      "state/configuration.\n"
                      "No game frontend, interpreter, smoke command or proof "
                      "is installed.\n"
                      "tty-source contains corresponding native source and notices.\n"
                      "Optional GUI font/tile resources and sys/share/sounds "
                      "are not shipped.\n"
                      "NGPL covers the tty code, data, generated levels and "
                      "documentation.\n"
                      "No upstream runnable test suite or check target exists "
                      "at this pin.\n") port)))
                (call-with-output-file (string-append bin "/slashem")
                  (lambda (port)
                    (format port "#!~a~%set -eu~%umask 077~%
state=\"${XDG_DATA_HOME:-${HOME:?}/.local/share}/slashem\"~%
config=\"${XDG_CONFIG_HOME:-${HOME:?}/.config}/slashem\"~%
case $state:$config in /*:/*) ;; *)~%
  echo 'slashem: XDG paths must be absolute' >&2; exit 1;; esac~%
export SLASHEM_VAR_PLAYGROUND=\"$state/\"~%
export SLASHEM_DUMPFILE=\"$state/dumps/%t.slashem.txt\"~%
for path in \"$SLASHEM_VAR_PLAYGROUND\" \"$SLASHEM_DUMPFILE\" \"$config\"; do~%
  bytes=$(LC_ALL=C; echo \"${#path}\")~%
  if test \"$bytes\" -gt 128; then~%
    echo 'slashem: path exceeds native 128-byte environment limit' >&2; exit 1~%
  fi~%
done~%
~s -p -- \"$state/save\" \"$state/dumps\" \"$config\"~%
for file in perm record logfile xlogfile paniclog; do~%
  test -e \"$state/$file\" || : > \"$state/$file\"~%
done~%
export HOME=\"$config\" HACKDIR=~s NETHACKDIR=~s~%
exec ~s \"$@\"~%"
                            #$(file-append bash-minimal "/bin/sh")
                            #$(file-append coreutils-minimal "/bin/mkdir")
                            data data real)))
                (chmod (string-append bin "/slashem") #o555))))
          (add-after 'compress-documentation 'make-output-immutable
            (lambda _
              (for-each
               (lambda (file)
                 (chmod file (cond ((file-is-directory? file) #o555)
                                   ((access? file X_OK) #o555)
                                   (else #o444))))
               (find-files #$output ".*" #:directories? #t)))))))
    (native-inputs (list bison flex groff-minimal util-linux))
    (inputs (list bash-minimal coreutils-minimal gzip ncurses/tinfo))
    (home-page "https://github.com/k21971/SlashEM")
    (synopsis "Extended-magic NetHack variant for the terminal")
    (description
     "SLASH'EM (Super Lotsa Added Stuff Hack, Extended Magic) is an
independently playable NetHack variant with additional roles, races, monsters,
items and special dungeon levels.  This package builds the Hardfought source
revision's native terminal interface and complete generated data offline.
Saves, bones, locks, scores, logs, dumps and configuration are private per-user
XDG data and configuration; immutable data and NGPL notices stay in the store.")
    (license (license:fsdg-compatible "https://nethack.org/common/license.html"))))
