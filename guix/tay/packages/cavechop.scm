;;; GNU Guix package for Martin Read's Cave Chop 7DRL.

(define-module (tay packages cavechop)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages ncurses))

(define-public cavechop
  (package
    (name "cavechop")
    ;; The upstream Makefile declares MAJVERS=1 and MINVERS=0.  The fixed
    ;; snapshot is commit ecc8bcfd56b96b71a2521f9b2a005f9cc89f0692, which is
    ;; both the last master revision and the bugfix-release-1 tag.
    (version "1.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://git.blackswordsonics.com/?p=cavechop-7drl;"
             "a=snapshot;h=ecc8bcfd56b96b71a2521f9b2a005f9cc89f0692;"
             "sf=tgz"))
       (file-name (string-append name "-" version ".tar.gz"))
       ;; SHA-256:
       ;; 6c16c18125ebd6b3fd56402c0dd2094abfd716b7515700da2050be4a908aef97
       (sha256
        (base32 "15zgia84mgjh43d00msinwbdggsa1790sb20avyv7mpb4n0w25kc"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The upstream tree has no automated test target.
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-before 'build 'patch-compressor-paths
            (lambda _
              ;; Cave Chop invokes these tools with system(), so a PATH-only
              ;; wrapper would leave the installed binary dependent on the
              ;; caller's environment.  Use the declared Guix input directly.
              (substitute* "main.c"
                (("\"gzip cavechop.sav\"" )
                 (string-append "\"" #$gzip "/bin/gzip cavechop.sav\""))
                ;; The upstream load call omits the .gz suffix, which makes
                ;; gzip reject the save and leaves load_game with no file.
                (("\"gunzip cavechop.sav\"" )
                 (string-append "\"" #$gzip "/bin/gunzip cavechop.sav.gz\""))
                ;; permobjs has NUM_OF_PERMOBJS entries, not 100.  The
                ;; upstream count corrupts memory when a save is loaded.
                (("fwrite\\(permobjs, 100, sizeof \\(struct permobj\\), fp\\);")
                 "fwrite(permobjs, NUM_OF_PERMOBJS, sizeof (struct permobj), fp);")
                (("fread\\(permobjs, 100, sizeof \\(struct permobj\\), fp\\);")
                 ;; Keep the bounded raw-record layout written above, but
                 ;; restore only scalar state.  The immutable names and
                 ;; process-local description pointers stay in the static
                 ;; table; skipping the records would lose flavour powers.
                 "{
        int i;
        struct permobj saved;
        for (i = 0; i < NUM_OF_PERMOBJS; ++i)
        {
            fread(&saved, sizeof saved, 1, fp);
            permobjs[i].poclass = saved.poclass;
            permobjs[i].rarity = saved.rarity;
            permobjs[i].sym = saved.sym;
            permobjs[i].power = saved.power;
            permobjs[i].used = saved.used;
            permobjs[i].depth = saved.depth;
        }
    }"))))
          (replace 'build
            (lambda _
              (invoke "make" "all" "CC=gcc")))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (doc (string-append out "/share/doc/cavechop"))
                     (program (string-append libexec "/cavechop"))
                     (launcher (string-append bin "/cavechop")))
                ;; Keep the real binary private to the state-isolating
                ;; launcher.  Install both the game's notes and its common
                ;; header, which retains the inherited 2005-2012 notice.
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p doc)
                (install-file "cavechop" libexec)
                (install-file "notes.txt" doc)
                (install-file "cavechop.h" doc)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%set -eu~%~%
real=~a~%
state=\"${XDG_STATE_HOME:-${HOME:?}/.local/state}/cavechop\"~%
~a/bin/mkdir -p \"$state\"~%
export TERM=\"${TERM:-xterm-256color}\"~%
export TERMINFO_DIRS=\"~a/share/terminfo${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"~%
cd \"$state\"~%
exec \"$real\" \"$@\"~%"
                            #$(file-append bash-minimal)
                            program
                            #$(file-append coreutils-minimal)
                            #$(file-append ncurses))))
                (chmod launcher #o555)))))))
    ;; gcc-toolchain is explicit because the upstream Makefile compiles the
    ;; complete C source tree directly.
    (native-inputs (list gcc-toolchain))
    (inputs (list bash-minimal coreutils-minimal gzip ncurses))
    (home-page "http://git.blackswordsonics.com/?p=cavechop-7drl;a=summary")
    (synopsis "Seven-day roguelike dungeon game")
    (description
     "Cave Chop is a terminal seven-day roguelike by Martin Read.  This
package builds the fixed upstream source snapshot with GNU make and ncurses,
and keeps saves, logs, and character dumps under
@file{$XDG_STATE_HOME/cavechop}, falling back to
@file{$HOME/.local/state/cavechop}.  It performs no build-time or runtime
downloads.")
    (license license:bsd-2)))
