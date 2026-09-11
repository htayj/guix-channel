;;; GNU Guix package for NLarn.

(define-module (tay packages nlarn)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages commencement)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages pkg-config))

(define-public nlarn
  (package
    (name "nlarn")
    (version "0.8.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/nlarn/nlarn")
             ;; Annotated release tag, whose tagged commit is
             ;; 7163a9925406014bfa74304032dfae920c6d8a8a.
             (commit "1873599a5682e4645e2801f7de6bd11ce54c2dfd")))
       (file-name (git-file-name name version))
       ;; Guix git-fetch tree hash for the fixed release checkout.  The
       ;; corresponding GitHub tag archive has SHA-256
       ;; 8f671fcbcec9d662648707fce4318ae3b2c7c68535c85848b55f8af346dfe735.
       (sha256
        (base32
         "0jcd5j2k23zx6ikwzkir47b9s57ign1hh82his1j1hs62nl8m34q"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ;upstream has no test target
      #:make-flags #~(list (string-append "CC=" #$(cc-for-target))
                          "config=release")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-before 'build 'patch-data-directory
            (lambda _
              ;; The executable first looks for a sibling lib directory and
              ;; then uses this fallback for a system-wide installation.
              ;; Guix installs the data below the immutable package output.
              (substitute* "src/nlarn.c"
                (("/usr/share/nlarn")
                 (string-append #$output "/share/nlarn")))))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (data (string-append out "/share/nlarn"))
                     (doc (string-append out "/share/doc/nlarn")))
                (mkdir-p bin)
                (mkdir-p data)
                (mkdir-p doc)
                (install-file "nlarn" bin)
                ;; Keep only the files used by the ncurses build.  The
                ;; Windows/SDL icon and Fira Mono font are not part of this
                ;; runtime path.
                (for-each
                 (lambda (file) (install-file file data))
                 (find-files
                  "lib"
                  "^(fortune(\\..*)?|maze|nlarn\\.hlp(\\..*)?|nlarn\\.msg(\\..*)?)$"))
                (copy-recursively "lib/locale"
                                  (string-append data "/locale"))
                (for-each
                 (lambda (file) (install-file file doc))
                 '("LICENSE" "README.md" "Changelog.md" "lib/maze_doc.txt"))
                (call-with-output-file
                    (string-append doc "/THIRD-PARTY-NOTICES")
                  (lambda (port)
                    (display "NLarn third-party notices\n"
                             port)
                    (display "========================\n\n"
                             port)
                    (display
                     "cJSON (src/external/cJSON.c and inc/external/cJSON.h)\n"
                     port)
                    (display
                     "Copyright (c) 2009-2017 Dave Gamble and cJSON contributors.\n"
                     port)
                    (display
                     "Permission is hereby granted, free of charge, to any person "
                     port)
                    (display "obtaining a copy\n" port)
                    (display
                     "of this software and associated documentation files "
                     port)
                    (display "(the Software), " port)
                    (display "to deal\n" port)
                    (display
                     "in the Software without restriction, including without limitation "
                     port)
                    (display "the rights\n" port)
                    (display
                     "to use, copy, modify, merge, publish, distribute, sublicense, "
                     port)
                    (display "and/or sell\n" port)
                    (display
                     "copies of the Software, and to permit persons to whom the Software "
                     port)
                    (display "is\n" port)
                    (display
                     "furnished to do so, subject to the following conditions:\n\n"
                     port)
                    (display
                     "The above copyright notice and this permission notice shall be "
                     port)
                    (display "included in\n" port)
                    (display
                     "all copies or substantial portions of the Software.\n\n"
                     port)
                    (display
                     "THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, "
                     port)
                    (display "EXPRESS OR\n" port)
                    (display
                     "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF "
                     port)
                    (display "MERCHANTABILITY,\n" port)
                    (display
                     "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT "
                     port)
                    (display "SHALL THE\n" port)
                    (display
                     "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR "
                     port)
                    (display "OTHER\n" port)
                    (display
                     "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, "
                     port)
                    (display "ARISING FROM,\n" port)
                    (display
                     "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER "
                     port)
                    (display "DEALINGS IN\n" port)
                    (display "THE SOFTWARE.\n\n" port)
                    (display
                     "enumFactory.h (inc/external/enumFactory.h)\n"
                     port)
                    (display
                     "Adapted from https://stackoverflow.com/a/202511/1519878\n"
                     port)
                    (display
                     "Author: StackOverflow user Suma\n"
                     port)
                    (display
                     "License: Creative Commons Attribution-ShareAlike (CC-BY-SA).\n"
                     port)
                    (display
                     "License text: https://creativecommons.org/licenses/by-sa/3.0/\n"
                     port)))))))))
    (native-inputs
     (list gcc-toolchain gnu-make pkg-config gettext-minimal))
    (inputs
     (list glib ncurses zlib))
    (home-page "https://github.com/nlarn/nlarn")
    (synopsis "Curses roguelike game inspired by Larn")
    (description
     "NLarn is an independently playable C and ncurses rewrite of the
classic roguelike game Larn.  This package builds the fixed NLarn 0.8.0
release without its optional PDCurses submodule, installs the curses game
data and locale catalogs in the store, and leaves configuration, saves, and
high scores in the user's @file{~/.nlarn} directory.")
    (license (list license:gpl3 license:expat license:cc-by-sa3.0))))

nlarn
