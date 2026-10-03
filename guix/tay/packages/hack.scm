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
  #:use-module (gnu packages ncurses))

;; Andries Brouwer's CWI page identifies 1.0.3, distributed on 23 July
;; 1985, as the last Hack release.  There is no upstream VCS revision to pin.
;; The same CWI page records two independent BSD-3-Clause grants: Jay
;; Fenlason for all code he wrote, and CWI for its 1985 code.  The archive's
;; COPYRIGHT and COPYRIGHT-JF retain both complete notices and disclaimers.
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
              ;; GCC no longer permits an implicit external declaration to
              ;; be followed by a file-local K&R definition.  Keep the
              ;; historical implementation and its internal linkage, but
              ;; declare the handful of local helpers before their callers.
              (substitute* "hack.apply.c"
                (("extern struct monst \\*bchit\\(\\);")
                 "static struct monst *bchit();\n")
                (("extern char pl_character\\[\\];")
                 (string-append
                  "extern char pl_character[];\n\n"
                  "static use_camera(), in_ice_box(), ck_ice_box(),\n"
                  "       out_ice_box(), use_ice_box(), use_whistle(),\n"
                  "       use_magic_whistle(), dig(), use_pick_axe();\n")))
              (substitute* "hack.do.c"
                (("extern char \\*nomovemsg;")
                 "extern char *nomovemsg;\n\nstatic drop();\n"))
              (substitute* "hack.invent.c"
                (("char \\*xprname\\(\\);")
                 "static char *xprname();\n"))
              (substitute* "hack.read.c"
                (("#include \"hack.h\"")
                 "#include \"hack.h\"\n\nextern struct obj *some_armor();"))
              (substitute* "hack.tty.c"
                (("inline") "input_line"))
              (substitute* "hack.shk.c"
                (("extern struct obj \\*o_on\\(\\), \\*bp_to_obj\\(\\);")
                 (string-append
                  "extern struct obj *o_on(), *bp_to_obj();\n\n"
                  "static setpaid(), addupbill(), findshk(), pay(),\n"
                  "       dopayobj(), getprice(), realhunger();\n")))
              (substitute* "hack.vault.c"
                (("#define[[:space:]]+EGD.*")
                 (string-append
                  "#define EGD\t((struct egd *)(&(guard->mextra[0])))\n\n"
                  "static restfakecorr(), goldincorridor();\n")))
              ;; The historical declaration disagrees with the POSIX libc
              ;; prototype now exposed by stdio.h, which GCC diagnoses as an
              ;; error when hack.c includes both headers.
              (substitute* "hack.h"
                (("extern char \\*sprintf\\(\\);" )
                 "extern int sprintf(char *, const char *, ...);"))
              (substitute* "hack.main.c"
                (("register char \\*sfoo;")
                 "register char *sfoo;\n\t\textern char genocided[], fut_geno[];\n")
                (("int hangup\\(\\);")
                 "int hangup();\n#ifdef CHDIR\nstatic chdirx();\n#endif CHDIR"))
              (substitute* "hack.makemon.c"
                (("\\{ extern boolean in_mklev;")
                 "extern boolean in_mklev;\n\t{"))
              (substitute* "hack.mkshop.c"
                (("^#ifndef QUEST.*$")
                 "extern char *getenv();\n\n#ifndef QUEST\n"))
              ;; Compile and link through the target compiler.  The source's
              ;; final command assumes /lib/crt0.o and an old termlib, and
              ;; `all' needlessly invokes an unavailable lint implementation.
              (substitute* "Makefile"
                (("@ld -X -o .* /lib/crt0\\.o .* -lc")
                 "\t@$(CC) $(LDFLAGS) -o $(GAME) $(HOBJ) $(TERMLIB) $(LDLIBS)")
                (("all:[[:space:]]+\\$\\(GAME\\)[[:space:]]+lint")
                 "all: $(GAME)")
                (("cc -o makedefs makedefs\\.c")
                 "$(CC) $(CFLAGS) -o makedefs makedefs.c")
                (("makedefs > hack\\.onames\\.h")
                 "./makedefs > hack.onames.h"))
              ;; Force this generated header through the pinned makedefs
              ;; source instead of trusting the copy in the distribution.
              (when (file-exists? "hack.onames.h")
                (delete-file "hack.onames.h"))))
          (replace 'build
            (lambda* (#:key make-flags #:allow-other-keys)
              ;; Building the executable pulls in makedefs and therefore
              ;; deterministically regenerates hack.onames.h.  Do not invoke
              ;; the upstream `all' target because it includes lint.
              (apply invoke "make" (append make-flags '("hack")))))
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
                     (ln #$(file-append coreutils-minimal "/bin/ln"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (readlink #$(file-append coreutils-minimal "/bin/readlink")))
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
ln=~s~%
mkdir=~s~%
readlink=~s~%
terminfo=~s~%~%
prepare_state() {~%
  state=\"${XDG_DATA_HOME:-${HOME:?}/.local/share}/hack\"~%
  test ! -L \"$state\" || { echo 'hack: state directory is a symlink' >&2; exit 1; }~%
  \"$mkdir\" -p \"$state\"~%
  save_dir=\"$state/save\"~%
  test ! -L \"$save_dir\" || {~%
    echo \"hack: save directory is a symlink\" >&2~%
    exit 1~%
  }~%
  if test -e \"$save_dir\"; then~%
    test -d \"$save_dir\" || {~%
      echo \"hack: save path is not a directory\" >&2~%
      exit 1~%
    }~%
  else~%
    \"$mkdir\" \"$save_dir\"~%
  fi~%
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
}~%~%
prepare_state~%
exec \"$real\" -d \"$state\" \"$@\"~%"
                            shell data real ln mkdir readlink
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
     (list gcc-toolchain gnu-make))
    ;; ncurses-with-tinfo supplies termcap symbols and the TERMINFO database.
    ;; Only ordinary launcher utilities are runtime dependencies.
    (inputs
     (list bash-minimal coreutils-minimal ncurses/tinfo))
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
