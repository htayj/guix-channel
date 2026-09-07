;;; GNU Guix package for the Hack'EM tty roguelike.

(define-module (tay packages hackem)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compiler-tools)
  #:use-module (gnu packages groff)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ncurses))

(define %hackem-commit
  "6e99cffbeecd2cbf71b3d27b9285be345aca298b")

(define-public hackem
  (package
    (name "hackem")
    (version "1.2.2")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/elunna/hackem")
             (commit %hackem-commit)))
       (file-name (git-file-name name version))
       ;; The GitHub commit archive is also reproducibly identified by
       ;; SHA-256 53cee6b27997eceab653401b20face1f64f6e7360ec6ad448f5b2256c76dddb.
       ;; The hash below is the Guix git-fetch checkout hash for this commit.
       (sha256
        (base32 "1x50zq5rw5skvxb4qbnvx2rh04nqsp730sqin5060hdaj3cqn7af"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The generated yacc/lex sources, maps, and data archive have ordering
      ;; dependencies which the upstream makefiles do not express completely.
      #:parallel-build? #f
      ;; Hack'EM has no non-interactive upstream test target.  Its installed
      ;; tty executable is exercised by tests/hackem-smoke.sh.
      #:tests? #f
      #:make-flags
      #~(list (string-append "CC=" #$(cc-for-target))
              (string-append "LINK=" #$(cc-for-target))
              ;; This historical source uses K&R definitions and common
              ;; tentative globals, while its current code also needs C99.
              (string-append
               "CFLAGS=-O2 -g0 -std=gnu99 -fcommon -D_DEFAULT_SOURCE "
               ;; Keep the upstream CHDIR phase enabled: it maps the
               ;; variable playground prefixes to HACKEM_VAR_PLAYGROUND
               ;; while leaving the read-only data directory as cwd.
               "-I../include -DNOTPARMDECL "
               ;; setup.sh's Linux hint can otherwise leave the default
               ;; /usr/games/lib/hackemdir in the final compile.
               "-DHACKDIR=\\\"" #$output "/share/hackem\\\" "
               "-DCURSES_GRAPHICS -DDLB -DREPRODUCIBLE_BUILD "
               "-DDUMPLOG -DNOMAIL -DNOSHELL -DNOUSER_SOUNDS "
               "-DFCMASK=0644")
              "WINLIB=-lncurses -ltinfo"
              "LEX=flex"
              "YACC=bison -y"
              ;; There is no .git directory in the Guix source archive.
              "GITINFO=0")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'prepare-build
            (lambda _
              ;; Keep static data in the store and obtain the writable
              ;; playground from the launcher at run time.
              (substitute* "include/config.h"
                (("^#define SYSCF[[:space:]]*$")
                 "/* #define SYSCF */")
                (("^#define SYSCF_FILE[[:space:]]+.*$")
                 "/* #define SYSCF_FILE */")
                (("^#define HACKDIR[[:space:]]+\"/usr/games/lib/hackemdir\"$")
                 (string-append "#define HACKDIR \"" #$output
                                "/share/hackem\""))
                (("^/\\*[[:space:]]+#define REPRODUCIBLE_BUILD[[:space:]]+\\*/$")
                 "#define REPRODUCIBLE_BUILD"))
              (substitute* "include/unixconf.h"
                (("^#define SERVER_ADMIN_MSG[[:space:]]+.*$")
                 "/* #define SERVER_ADMIN_MSG */")
                (("^/[*/][[:space:]]+#define VAR_PLAYGROUND.*$")
                 "#define VAR_PLAYGROUND nh_getenv(\"HACKEM_VAR_PLAYGROUND\")"))
              ;; append_slash is defined by the Unix tty port, but the
              ;; upstream declaration is incorrectly limited to PC ports;
              ;; C99 rejects its use from files.c without a prototype.
              (substitute* "include/extern.h"
                (("/\\* ### files\\.c ### \\*/")
                 "E void FDECL(append_slash, (char *));\n\n/* ### files.c ### */"))
              ;; The upstream installer deletes HACKDIR and creates mutable
              ;; files there.  Generate only the build makefiles and install
              ;; the resulting files explicitly in the install phase.
              (substitute* "sys/unix/setup.sh"
                (("/bin/sh") #$(file-append bash-minimal "/bin/sh")))
              ;; setup.sh is called from the repository root, so the hint
              ;; path must include its sys/unix prefix.
              (invoke "sh" "sys/unix/setup.sh" "sys/unix/hints/linux")
              ;; makedefs uses this value when REPRODUCIBLE_BUILD is enabled.
              (setenv "SOURCE_DATE_EPOCH" "1698401163")
              (setenv "TZ" "UTC0")))
          (replace 'build
            (lambda* (#:key make-flags #:allow-other-keys)
              (apply invoke "make" (append (list "all") make-flags))))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/hackem"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (doc (string-append out "/share/doc/hackem"))
                     (man (string-append out "/share/man/man6"))
                     (real (string-append libexec "/hackem-real"))
                     (launcher (string-append bin "/hackem"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (cat #$(file-append coreutils-minimal "/bin/cat"))
                     (chmod-bin #$(file-append coreutils-minimal "/bin/chmod"))
                     (dirname #$(file-append coreutils-minimal "/bin/dirname"))
                     (find #$(file-append findutils "/bin/find"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (mktemp #$(file-append coreutils-minimal "/bin/mktemp"))
                     (rm #$(file-append coreutils-minimal "/bin/rm"))
                     (sleep #$(file-append coreutils-minimal "/bin/sleep"))
                     (script #$(file-append util-linux "/bin/script")))
                (mkdir-p data)
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                (mkdir-p man)
                (install-file "src/hackem" libexec)
                (rename-file (string-append libexec "/hackem") real)
                (install-file "dat/nhdat" data)
                (install-file "dat/license" data)
                (install-file "LICENSE" doc)
                (install-file "README.md" doc)
                (install-file "doc/Guidebook.txt" doc)
                (install-file "doc/hackem_changelog.txt" doc)
                (install-file "sys/unix/README.linux" doc)
                (install-file "doc/nethack.6" man)
                (rename-file (string-append man "/nethack.6")
                             (string-append man "/hackem.6"))
                (let ((port (open-file launcher "w")))
                  (format port "#!~a~%set -eu~%~%
data=~s~%
real=~s~%
cat=~s~%
chmod=~s~%
dirname=~s~%
find=~s~%
mkdir=~s~%
mktemp=~s~%
rm=~s~%
sleep=~s~%
script=~s~%~%
prepare_state() {~%
  caller_home=\"${HOME:?}\"~%
  state_root=\"${XDG_STATE_HOME:-${XDG_DATA_HOME:-$caller_home/.local/state}}\"~%
  config_root=\"${XDG_CONFIG_HOME:-$caller_home/.config}\"~%
  state=\"$state_root/hackem\"~%
  config=\"$config_root/hackem\"~%
  \"$mkdir\" -p \"$state/save\" \"$state/whereis\" \"$config\"~%
  for file in perm record logfile xlogfile livelog paniclog hangup; do~%
    test -e \"$state/$file\" || : > \"$state/$file\"~%
  done~%
  export HOME=\"$config\"~%
  export HACKDIR=\"$data\" NETHACKDIR=\"$data\"~%
  export HACKEM_VAR_PLAYGROUND=\"$state/\"~%
  export TERM=\"${TERM:-xterm-256color}\"~%
  export LC_ALL=\"${LC_ALL:-C}\" LANG=\"${LANG:-C}\"~%
}~%~%
run_game() {~%
  log=$1~%
  mode=${2-truncate}~%
  if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE-}\"; then~%
    \"$mkdir\" -p \"$(\"$dirname\" \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\")\"~%
    if test \"$mode\" = append; then~%
      \"$script\" -qefc \"$real -u goocastle-tourist-human-neutral-male\" \\
        \"$log\" >> \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"~%
    else~%
      \"$script\" -qefc \"$real -u goocastle-tourist-human-neutral-male\" \\
        \"$log\" > \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"~%
    fi~%
  else~%
    \"$script\" -qefc \"$real -u goocastle-tourist-human-neutral-male\" \\
      \"$log\" >/dev/null~%
  fi~%
}~%~%
case \"${1-}\" in~%
  --guix-smoke)~%
    test \"$#\" -eq 1 || { echo 'usage: hackem [--guix-smoke]' >&2; exit 64; }~%
    smoke=$(\"$mktemp\" -d \\
      \"${TMPDIR:-/tmp}/hackem-guix-smoke.XXXXXXXX\")~%
    cleanup() { \"$rm\" -rf \"$smoke\"; }~%
    trap cleanup EXIT HUP INT TERM~%
    \"$mkdir\" \"$smoke/home\" \"$smoke/config\" \"$smoke/data\" \\
      \"$smoke/cache\" \"$smoke/state\" \"$smoke/runtime\" \"$smoke/tmp\"~%
    \"$chmod\" 700 \"$smoke/runtime\"~%
    export HOME=\"$smoke/home\" XDG_CONFIG_HOME=\"$smoke/config\"~%
    export XDG_DATA_HOME=\"$smoke/data\" XDG_CACHE_HOME=\"$smoke/cache\"~%
    export XDG_STATE_HOME=\"$smoke/state\" XDG_RUNTIME_DIR=\"$smoke/runtime\"~%
    export TMPDIR=\"$smoke/tmp\" TERM=xterm-256color LC_ALL=C LANG=C~%
    prepare_state~%
    first_log=\"$state/smoke-first.log\"~%
    second_log=\"$state/smoke-second.log\"~%
    if ! {~%
      printf 'y'; \"$sleep\" 1; printf 'y'; \"$sleep\" 1;~%
      printf ' '; \"$sleep\" 1; printf 'l'; \"$sleep\" 1;~%
      printf 'S'; \"$sleep\" 2; printf 'y'; \"$sleep\" 1;~%
    } | run_game \"$first_log\"; then~%
      echo 'hackem smoke: first game failed' >&2; exit 1~%
    fi~%
    saved=~%
    for file in \"$state/save\"/*; do~%
      test -f \"$file\" || continue~%
      saved=\"$file\"~%
    done~%
    test -n \"$saved\" || { echo 'hackem smoke: save missing' >&2; exit 1; }~%
    first_text=$(\"$cat\" \"$first_log\")~%
    case \"$first_text\" in~%
      *Hack*EM*|*Hack\\'EM*) ;;~%
      *) echo 'hackem smoke: title missing' >&2; exit 1 ;;~%
    esac~%
    if ! {~%
      printf ' '; \"$sleep\" 1; printf '.'; \"$sleep\" 1;~%
      printf '#quit\\n'; \"$sleep\" 2; printf 'y'; \"$sleep\" 1;~%
      printf 'n'; \"$sleep\" 1; printf '    ';~%
    } | run_game \"$second_log\" append; then~%
      echo 'hackem smoke: restore game failed' >&2; exit 1~%
    fi~%
    second_text=$(\"$cat\" \"$second_log\")~%
    case \"$second_text\" in~%
      *\"Restoring save file\"*|*\"Welcome back\"*) ;;~%
      *) echo 'hackem smoke: restore missing' >&2; exit 1 ;;~%
    esac~%
    for root in \"$smoke/home\" \"$smoke/config\" \"$smoke/data\" \\
      \"$smoke/cache\" \"$smoke/state\" \"$smoke/runtime\" \"$smoke/tmp\"; do~%
      case \"$root\" in~%
        \"$smoke\"/*) ;;~%
        *) echo 'hackem smoke: mutable root escaped isolated tree' >&2; exit 1 ;;~%
      esac~%
    done~%
    printf '%s\\n' 'hackem guix smoke passed'~%
    exit 0~%
    ;;~%
  *)~%
    prepare_state~%
    exec \"$real\" \"$@\"~%
    ;;~%
esac~%"
                            shell data real cat chmod-bin dirname find mkdir mktemp rm
                            sleep script)
                  (close-port port))
                (chmod launcher #o555))))
          (add-after 'install 'verify-license-notices
            (lambda _
              (let ((data (string-append #$output "/share/hackem/"))
                    (doc (string-append #$output "/share/doc/hackem/"))
                    (man (string-append #$output "/share/man/man6/")))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append data file))
                     (error "missing installed Hack'EM runtime file" file)))
                 '("nhdat" "license"))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append doc file))
                     (error "missing installed Hack'EM notice" file)))
                 '("LICENSE" "README.md" "Guidebook.txt"
                   "hackem_changelog.txt" "README.linux"))
                (unless (file-exists? (string-append man "hackem.6"))
                  (error "missing installed Hack'EM manual"))
                (unless (not (file-exists? (string-append data "sounds")))
                  (error "unlicensed sound assets were installed"))
                (invoke "grep" "-F" "NETHACK GENERAL PUBLIC LICENSE"
                        (string-append data "license"))
                (invoke "grep" "-F" "Hack'EM"
                        (string-append doc "README.md")))))
          ;; Guix makes completed store outputs immutable.  Run this after
          ;; documentation compression so generated manpages can be finalized.
          (add-after 'compress-documentation 'make-output-immutable
            (lambda _
              (for-each
               (lambda (file)
                 (chmod file
                        (cond ((file-is-directory? file) #o555)
                              ((access? file X_OK) #o555)
                              (else #o444))))
               (find-files #$output ".*" #:directories? #t)))))))
    (native-inputs
     (list bison flex gcc-toolchain gnu-make groff-minimal))
    (inputs
     (list bash-minimal coreutils-minimal findutils ncurses/tinfo util-linux))
    (home-page "https://github.com/elunna/hackem")
    (synopsis "Hack'EM terminal dungeon exploration game")
    (description
     "Hack'EM is an independently playable EvilHack-based NetHack variant
with features from several other variants.  This package builds its Linux
curses interface from a fixed upstream release, generates all game data
offline, and installs only the executable, immutable data archive, license,
and relevant documentation.  Its launcher keeps saves, scores, bones, locks,
logs, and configuration below the user's XDG state and configuration
directories.")
    ;; The upstream dat/license is the NETHACK GENERAL PUBLIC LICENSE for the
    ;; C sources, generated maps/data, and resulting executable.
    (license (license:fsdg-compatible
              "https://nethack.org/common/license.html"))))
