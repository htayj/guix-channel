;;; GNU Guix package for Nathan Hetherington's NarwhaRL.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages narwharl)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages ncurses))

(define-public narwharl
  (package
    (name "narwharl")
    (version "0.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://storage.googleapis.com/google-code-archive-downloads/v2/"
             "code.google.com/narwharl/narwharl-" version ".tar.gz"))
       ;; Independently fetched archive SHA-256:
       ;; 393744ba92536f16053c9813680c82634e327947fffc33d1fc9a288c16af0da5
       (sha256
        (base32 "198dmwb8qa4szk8k7z7z8xwk4kk3h866h4wq7h2icvskjax48drr"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ;No upstream automated test target.
      #:make-flags
      #~(list "CFLAGS=-std=c++98 -g -c" "LDFLAGS=-lncurses")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'fix-initialization-and-data-paths
            (lambda _
              ;; main.o precedes random.o: constructing Stuffgetter globally
              ;; calls the RNG before its constructor has seeded the shared
              ;; state.  Initialize after mtinit, before any map/definition use.
              (substitute* "main.cpp"
                (("Stuffgetter \\* objget = new Stuffgetter\\(\\);")
                 "Stuffgetter * objget = NULL;")
                (("  mtinit\\(&seed\\);")
                 "  mtinit(&seed);\n  objget = new Stuffgetter();"))
              ;; Fresh generation and native resume inspect these fields
              ;; before allocation; upstream leaves stack storage undefined.
              (substitute* "map.cpp"
                (("  seed = sseed;")
                 (string-append
                  "  seed = sseed;\n  map=NULL;\n  mlist=NULL;\n  plan=NULL;\n"
                  "  xsize=0;\n  ysize=0;"))
                ;; Stack members are created at (0,0), then placed through
                ;; put().  Persist the containing floor coordinates too:
                ;; otherwise save/load silently loses every extra arrow.
                (("  list_add\\(this->getitems\\(y,x\\),\\(void \\*\\)item\\);")
                 (string-append
                  "  item->y=y;\n  item->x=x;\n"
                  "  list_add(this->getitems(y,x),(void *)item);")))
              ;; The room-generation loop consumes this overload's return.
              ;; Falling off the end is undefined, especially with optimization.
              (substitute* "newgenmap.cpp"
                (("  placement\\(ly,lx,hy,hx,y,x,itemprob,monprob,0,map\\);")
                 "  return placement(ly,lx,hy,hx,y,x,itemprob,monprob,0,map);")
                ;; Unique end of the generator's commented debugging block.
                (("  \\}\\*/") "  }*/\n  return 1;"))
              ;; Restoring every creature merges its saved spells.  This
              ;; mutator has no return value, but upstream declares void*,
              ;; causing modern compilers to trap on the fall-through path.
              (substitute* '("llist.cpp" "nheader.h")
                (("void \\* ?list_merge") "void list_merge"))
              ;; No curses C++ classes are used.  This obsolete compatibility
              ;; header can be replaced with the standard curses declarations.
              (substitute* "nheader.h"
                (("#include <ncurses/cursesapp.h>") "#include <curses.h>"))
              ;; All six definition files are immutable installed data; native
              ;; save/ paths stay relative to the launcher's writable state cwd.
              (substitute* "stuffread.cpp"
                (("\"defs/")
                 (string-append "\"" #$output "/share/narwharl/defs/")))))
          (replace 'install
            (lambda _
              (let* ((bin (string-append #$output "/bin"))
                     (libexec (string-append #$output "/libexec"))
                     (data (string-append #$output "/share/narwharl"))
                     (doc (string-append #$output "/share/doc/narwharl"))
                     (launcher (string-append bin "/narwharl")))
                (install-file "narwharl" libexec)
                (copy-recursively "defs" (string-append data "/defs"))
                (for-each (lambda (file) (install-file file doc))
                          '("README" "INSTALL" "CHANGELOG" "gpl-2.0.txt"))
                ;; Preserve the actual GPL-2-or-later grant as well as README's
                ;; shorthand GPL 2.0 wording and the bundled BSD-3 notice.
                (install-file "main.cpp" (string-append doc "/source-notices"))
                (for-each (lambda (file)
                            (install-file (string-append "mtrand/" file)
                                          (string-append doc "/mtrand")))
                          '("mtreadme.txt" "mtrand.h"))
                (call-with-output-file (string-append doc "/THIRD-PARTY-NOTICES")
                  (lambda (port)
                    (display
                     "NarwhaRL 0.0.1: Copyright 2010 Nathan Hetherington.
The original C++ source headers grant GNU GPL version 2 or any later version;
README abbreviates this as GPL 2.0.  gpl-2.0.txt contains the license text and
source-notices/main.cpp preserves the original grant.  Code, documentation
and all six textual game definitions come from this same source release.
No fonts, tiles, sounds, prebuilt executables or external maps are installed.
Bundled Mtrand: Copyright 1997-2002 Makoto Matsumoto and Takuji Nishimura,
C++ port by Jasper Bedaux; BSD three-clause terms in mtrand/mtrand.h.
Mtrand is compiled from source; mtrand/mtreadme.txt retains its provenance.
Ncurses is a separately source-built Guix dependency under the X11 license.
The launcher uses separately packaged Bash and GNU Coreutils, whose licenses
and notices remain supplied by their respective Guix packages.
" port)))
                (mkdir-p bin)
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a/bin/sh~%set -eu~%umask 077~%"
                            #$bash-minimal)
                    (display
                     (string-append
                      "state=\"${XDG_STATE_HOME:-"
                      "${HOME:?HOME must be set}/.local/state}/narwharl\"\n")
                     port)
                    (format port "~a/bin/mkdir -p -- \"$state/save\"~%"
                            #$coreutils-minimal)
                    (display "cd -- \"$state\"\n" port)
                    (format port
                            (string-append "export TERMINFO_DIRS=~s"
                                           "\"${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"~%")
                            (string-append #$ncurses "/share/terminfo"))
                    (display "export TERM=\"${TERM:-xterm-256color}\"\n" port)
                    (format port "exec ~a/narwharl \"$@\"~%" libexec)))
                (chmod launcher #o555))))
          (add-after 'compress-documentation 'make-output-immutable
            (lambda _
              (for-each
               (lambda (file)
                 (chmod file (if (or (file-is-directory? file) (access? file X_OK))
                                 #o555 #o444)))
               (find-files #$output ".*" #:directories? #t))
              (chmod #$output #o555))))))
    (inputs (list bash-minimal coreutils-minimal ncurses))
    (home-page "https://code.google.com/archive/p/narwharl/")
    (synopsis "Terminal dungeon exploration roguelike")
    (description
     "NarwhaRL is Nathan Hetherington's terminal roguelike, with procedural
maps, monsters, equipment, potions, spells and persistent native save games.
This package builds the original 0.0.1 C++ source release and preserves its
curses interface and all game definitions.  Native saves live below
@env{XDG_STATE_HOME}/narwharl, falling back to
@file{~/.local/state/narwharl}; definitions are read from the immutable store.
The optional positional numeric random seed retains its upstream meaning.")
    (license (list license:gpl2+ license:bsd-3))))
