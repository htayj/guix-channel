;;; GNU Guix package for Andries Brouwer's historical Hack roguelike.
;;;
;;; SPDX-License-Identifier: BSD-3-Clause

(define-module (tay packages hack)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages ncurses))

;; Andries Brouwer's CWI page identifies 1.0.3, distributed on 23 July
;; 1985, as the last Hack release.  There is no upstream VCS revision to pin.
(define-public hack
  (package
    (name "hack")
    (version "1.0.3")
    (source
     (origin
       (method url-fetch)
       (uri "https://homepages.cwi.nl/~aeb/games/hack/hack-1.0.3.tar.gz")
       (file-name (string-append name "-" version ".tar.gz"))
       ;; SHA-256: 688534e776acfe620ea9e24822bea8b0b4bbe8ec2c2f3c74c8db89b51c7bcc30
       (sha256
        (base32 "0c6cgcfbb2fvr1s3qbrcxklbpd5hm2z24j72m4765zmcfvkk91b8"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The historical dependency file is complete, but the original build
      ;; uses a non-portable linker command and has a lint-only all target.
      #:parallel-build? #f
      ;; No automated upstream test target is shipped.  The installed tty
      ;; game, including save/restore, is exercised by tests/hack-smoke.sh.
      #:tests? #f
      #:make-flags
      #~(list (string-append "CC=" #$(cc-for-target))
              ;; Hack 1.0.3 is K&R C and relies on common tentative globals.
              "CFLAGS=-O2 -g0 -std=gnu89 -fcommon -D_DEFAULT_SOURCE"
              "TERMLIB=-ltinfo")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'prepare-build
            (lambda _
              ;; Linux provides the old termio interface, while the archive's
              ;; BSD branch expects obsolete sgtty structures and ioctls.
              (substitute* "config.h"
                (("^#define BSD.*$") "/* #define BSD */")
                (("^#define[[:space:]]+MAIL.*$") "/* #define MAIL */")
                (("^#define[[:space:]]+SHELL.*$") "/* #define SHELL */")
                (("^#define[[:space:]]+HACKDIR.*$")
                 "/* #define HACKDIR */"))
              ;; Compile and link through the target compiler.  The source's
              ;; final command assumes /lib/crt0.o and an old termlib, and
              ;; `all' needlessly invokes an unavailable lint implementation.
              (substitute* "Makefile"
                (("^\t@ld -X -o .* /lib/crt0\\.o .* -lc$")
                 "\t@$(CC) $(LDFLAGS) -o $(GAME) $(HOBJ) $(TERMLIB) $(LDLIBS)")
                (("^all: .* lint$") "all: $(GAME)")
                (("^cc -o makedefs makedefs\\.c$")
                 "$(CC) $(CFLAGS) -o makedefs makedefs.c")
                (("^[[:space:]]*cc -o makedefs makedefs.c$")
                 "\t$(CC) $(CFLAGS) -o makedefs makedefs.c"))
              ;; Force this generated header through the pinned makedefs
              ;; source instead of trusting the copy in the distribution.
              (when (file-exists? "hack.onames.h")
                (delete-file "hack.onames.h"))))
          (replace 'build
            (lambda _
              ;; Building the executable pulls in makedefs and therefore
              ;; deterministically regenerates hack.onames.h.  Do not invoke
              ;; the upstream `all' target because it includes lint.
              (invoke "make" "hack")))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/hack"))
                     (libexec (string-append #$output "/libexec"))
                     (bin (string-append #$output "/bin"))
                     (doc (string-append #$output "/share/doc/hack"))
                     (man (string-append #$output "/share/man/man6"))
                     (real (string-append libexec "/hack"))
                     (launcher (string-append bin "/hack"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (cat #$(file-append coreutils-minimal "/bin/cat"))
                     (cp #$(file-append coreutils-minimal "/bin/cp"))
                     (chmod-bin #$(file-append coreutils-minimal "/bin/chmod"))
                     (dirname #$(file-append coreutils-minimal "/bin/dirname"))
                     (find #$(file-append findutils "/bin/find"))
                     (grep-bin #$(file-append grep "/bin/grep"))
                     (ln #$(file-append coreutils-minimal "/bin/ln"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (mktemp #$(file-append coreutils-minimal "/bin/mktemp"))
                     (readlink #$(file-append coreutils-minimal "/bin/readlink"))
                     (script #$(file-append util-linux "/bin/script"))
                     (sleep #$(file-append coreutils-minimal "/bin/sleep")))
                (mkdir-p data)
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                (mkdir-p man)
                (install-file "hack" libexec)
                ;; These are the complete same-origin runtime assets.  The
                ;; launcher links to them read-only from the store.
                (for-each (lambda (file) (install-file file data))
                          '("data" "help" "hh" "rumors"))
                (install-file "READ_ME" doc)
                (install-file "COPYRIGHT" doc)
                (install-file "COPYRIGHT-JF" doc)
                (install-file "hack.6" man)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%~%
data=~s~%
real=~s~%
shell=~s~%
cat=~s~%
cp=~s~%
chmod=~s~%
dirname=~s~%
find=~s~%
grep=~s~%
ln=~s~%
mkdir=~s~%
mktemp=~s~%
readlink=~s~%
script=~s~%
sleep=~s~%
terminfo=~s~%~%
prepare_state() {~%
  state=\"${XDG_DATA_HOME:-${HOME:?}/.local/share}/hack\"~%
  test ! -L \"$state\" || { echo 'hack: state directory is a symlink' >&2; exit 1; }~%
  \"$mkdir\" -p \"$state/save\"~%
  for file in data help hh rumors; do~%
    path=\"$state/$file\"~%
    target=\"$data/$file\"~%
    if test -e \"$path\" || test -L \"$path\"; then~%
      test -L \"$path\" || { echo \"hack: refusing mutable $path\" >&2; exit 1; }~%
      test \"$(\"$readlink\" \"$path\")\" = \"$target\" ||~%
        { echo \"hack: unexpected data link $path\" >&2; exit 1; }~%
    else~%
      \"$ln\" -s \"$target\" \"$path\"~%
    fi~%
  done~%
  for file in perm record; do~%
    path=\"$state/$file\"~%
    if test -L \"$path\"; then~%
      echo \"hack: refusing mutable symlink $path\" >&2~%
      exit 1~%
    fi~%
    test -e \"$path\" || : > \"$path\"~%
  done~%
  export HACKDIR=\"$state\"~%
  export TERMINFO_DIRS=\"$terminfo${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"~%
  export TERM=\"${TERM:-xterm-256color}\"~%
  unset HACKOPTIONS MAIL MAILREADER SHELL~%
}~%~%
run_game() {~%
  log=$1~%
  \"$script\" -qefc \"$real -d \\\"$state\\\" -n -u goocastle\" \"$log\" >/dev/null~%
}~%~%
case \"${1-}\" in~%
  --guix-smoke)~%
    test \"$#\" -eq 1 || { echo 'usage: hack [--guix-smoke]' >&2; exit 64; }~%
    smoke=$(\"$mktemp\" -d \"${TMPDIR:-/tmp}/hack-guix-smoke.XXXXXXXX\")~%
    \"$mkdir\" \"$smoke/home\" \"$smoke/config\" \"$smoke/data\"~%
    \"$mkdir\" \"$smoke/cache\" \"$smoke/state\" \"$smoke/runtime\" \"$smoke/tmp\"~%
    \"$chmod\" 700 \"$smoke/runtime\"~%
    export HOME=\"$smoke/home\" XDG_CONFIG_HOME=\"$smoke/config\"~%
    export XDG_DATA_HOME=\"$smoke/data\" XDG_CACHE_HOME=\"$smoke/cache\"~%
    export XDG_STATE_HOME=\"$smoke/state\" XDG_RUNTIME_DIR=\"$smoke/runtime\"~%
    export TMPDIR=\"$smoke/tmp\" TERM=xterm-256color LC_ALL=C~%
    prepare_state~%
    first_log=\"$state/smoke-first.log\"~%
    second_log=\"$state/smoke-second.log\"~%
    if ! { \"$sleep\" 1; printf '.'; \"$sleep\" 1; printf 'S'; } |~%
      run_game \"$first_log\"; then~%
      echo 'hack smoke: first game failed' >&2~%
      exit 1~%
    fi~%
    saved=~%
    for file in \"$state/save\"/*; do~%
      test -f \"$file\" || continue~%
      saved=\"$file\"~%
    done~%
    test -n \"$saved\" || { echo 'hack smoke: save missing' >&2; exit 1; }~%
    \"$grep\" -F 'Hello goocastle, welcome to hack!' \"$first_log\" >/dev/null~%
    if ! { \"$sleep\" 1; printf '.'; \"$sleep\" 1;~%
      printf 'Q'; \"$sleep\" 1; printf 'y'; } |~%
      run_game \"$second_log\"; then~%
      echo 'hack smoke: restore game failed' >&2~%
      exit 1~%
    fi~%
    \"$grep\" -F 'Restoring old save file...' \"$second_log\" >/dev/null~%
    \"$grep\" -F 'Hello goocastle, welcome to hack!' \"$second_log\" >/dev/null~%
    \"$grep\" -F '@' \"$second_log\" >/dev/null~%
    # Game files are all relative to the private -d directory.  The only
    # files outside it would indicate a path escape; the empty isolation
    # directories themselves are expected.
    escaped=$(\"$find\" \"$smoke\" -type f ! -path \"$state/*\"~%
      -print -quit) 2>/dev/null || true~%
    test -z \"$escaped\" || {~%
      echo \"hack smoke: path escaped state: $escaped\" >&2~%
      exit 1~%
    }~%
    escaped=$(\"$find\" \"$smoke\" -type l ! -path \"$state/*\"~%
      -print -quit) 2>/dev/null || true~%
    test -z \"$escaped\" || {~%
      echo \"hack smoke: link escaped state: $escaped\" >&2~%
      exit 1~%
    }~%
    if test -n \"${GOOCASTLE_RUNTIME_RAW_CAPTURE-}\"; then~%
      \"$mkdir\" -p \"$(\"$dirname\" \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\")\"~%
      \"$cp\" \"$first_log\" \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"~%
      \"$cat\" \"$second_log\" >> \"$GOOCASTLE_RUNTIME_RAW_CAPTURE\"~%
    fi~%
    printf '%s\\n' 'hack guix smoke passed'~%
    exit 0~%
    ;;~%
  *)~%
    prepare_state~%
    exec \"$real\" -d \"$state\" \"$@\"~%
    ;;~%
esac~%"
                            shell data real shell cat cp chmod-bin dirname find
                            grep-bin ln mkdir mktemp readlink script sleep
                            #$(file-append ncurses/tinfo "/share/terminfo"))))
                (chmod launcher #o555))))
          (add-after 'install 'verify-license-notices
            (lambda _
              (let ((data (string-append #$output "/share/hack/"))
                    (doc (string-append #$output "/share/doc/hack/"))
                    (man (string-append #$output "/share/man/man6/")))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append data file))
                     (error "missing installed Hack runtime asset" file)))
                 '("data" "help" "hh" "rumors"))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append doc file))
                     (error "missing installed Hack notice" file)))
                 '("COPYRIGHT" "COPYRIGHT-JF" "READ_ME"))
                (unless (file-exists? (string-append man "hack.6"))
                  (error "missing installed Hack manual"))
                (invoke "grep" "-F"
                        "Stichting Centrum voor Wiskunde en Informatica"
                        (string-append doc "COPYRIGHT"))
                (invoke "grep" "-F" "Copyright (c) 1982 Jay Fenlason"
                        (string-append doc "COPYRIGHT-JF")))))
          ;; Leave the completed store output immutable; game state is created
          ;; only in the wrapper's XDG data directory.
          (add-after 'make-dynamic-linker-cache 'make-output-immutable
            (lambda _
              (for-each
               (lambda (file)
                 (chmod file
                        (cond ((file-is-directory? file) #o555)
                              ((access? file X_OK) #o555)
                              (else #o444))))
               (find-files #$output ".*" #:directories? #t)))))))
    (native-inputs
     (list gcc-toolchain gnu-make))
    ;; ncurses-with-tinfo supplies the termcap-compatible symbols and the
    ;; TERMINFO database used by the launcher.  util-linux supplies `script'
    ;; only for the bounded package smoke mode.
    (inputs
     (list bash-minimal coreutils-minimal findutils grep ncurses/tinfo
           util-linux))
    (home-page "https://homepages.cwi.nl/~aeb/games/hack/hack.html")
    (synopsis "Historical terminal dungeon exploration game")
    (description
     "Hack is Andries Brouwer's final 1.0.3 release of the early terminal
 dungeon exploration game originally written by Jay Fenlason and contributors.
 This package builds the tty game from its fixed CWI source archive, disables
 the historical shell-escape and mailbox features, and keeps records, locks,
 bones, levels, saves, and other mutable files below the user's XDG data
 directory.  The original data, help, rumors, manual, and both upstream BSD
 notices are retained; no build-time or runtime downloads are performed.")
    (license license:bsd-3)))
