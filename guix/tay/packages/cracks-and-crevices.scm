;;; GNU Guix package for the recovered Cracks and Crevices 0.5 release.

(define-module (tay packages cracks-and-crevices)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages sdl)
  #:use-module (tay packages auxiliary))

(define-public cracks-and-crevices
  (package
    (name "cracks-and-crevices")
    (version "0.5")
    (source
     (origin
       (method url-fetch)
       ;; Original attachment 32, not a reconstructed engine or current master.
       ;; Release 0.5 reports v0.05/0757; no assertion about today's latest.
       (uri (string-append
             "https://web.archive.org/web/20150804175538if_/"
             "https://redmine.bloodycactus.com/attachments/download/32/"
             "cracks_and_crevices-0.5.tar.bz2"))
       (file-name (string-append name "-" version ".tar.bz2"))
       ;; 121192 bytes; MD5 dd6e27a5bfea81549c94d52c12b9682e.
       ;; SHA256 a00cf6ab0a189673fe152f9325b14c1a6b6a531a8510d1cc321c44ccdeb9fb66.
       (sha256
        (base32 "0rpvp7gcqi0w6b6d2445399nlsqs9jqjb4rg2pz775hq1amzc350"))
       (patches
        (map search-tay-package-file
             '("patches/cracks-and-crevices-notices.patch"
               "patches/cracks-and-crevices-native-state.patch"
               "patches/cracks-and-crevices-build.patch")))
       (patch-flags '("-p1" "--fuzz=0"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ;release Makefile has no test target
      #:make-flags
      #~(list (string-append "CC=" #$(cc-for-target))
              (string-append "CPPFLAGS=-I" #$sdl12-compat "/include")
              (string-append "LDFLAGS=-L" #$sdl12-compat "/lib"))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (replace 'install
            (lambda _
              (let* ((libexec (string-append #$output
                                             "/libexec/cracks-and-crevices"))
                     (bin (string-append #$output "/bin"))
                     (doc (string-append #$output
                                         "/share/doc/cracks-and-crevices"))
                     (licenses (string-append doc "/licenses")))
                ;; Bypass upstream's privileged setgid /usr/games install.
                ;; Fonts, maps, rumors, and game data are compiled into cnc.
                (install-file "cnc" libexec)
                (mkdir-p bin)
                (symlink "../libexec/cracks-and-crevices/cnc"
                         (string-append bin "/cracks-and-crevices"))
                (copy-recursively "docs" doc)
                (install-file "config-example.ini" doc)
                (install-file "PROVENANCE.txt" doc)
                (install-file "COPYING.libfov" licenses)
                ;; Retain the full source notices, including MT19937's BSD
                ;; binary-redistribution terms and MEMWATCH's GPL2+ grant.
                (for-each (lambda (file) (install-file file licenses))
                          '("random_mt.c" "memwatch.c" "memwatch.h"))))))))
    ;; SDL 1.2 API, supplied by Guix's compatibility library.  No SDL_image,
    ;; Ruby/Rant generators, Lua interpreter, or MEMWATCH debug mode is used.
    (inputs (list sdl12-compat))
    ;; The original host is unmaintained and its current TLS certificate does
    ;; not match redmine.bloodycactus.com.  This is the recovered primary
    ;; release-files page, not a claim that the author maintains a live site.
    (home-page
     (string-append "https://web.archive.org/web/20160417095515id_/"
                    "https://redmine.bloodycactus.com/projects/sdlrl/files"))
    (synopsis "Real-time dungeon-crawling roguelike")
    (description
     "Cracks and Crevices is a real-time dungeon-crawling roguelike with
character advancement, quests, shops, and configurable SDL bitmap fonts.  This
package builds the original 0.5 release, including its embedded fonts and game
data.  Configuration, saved games, character dumps, and scores live in a private
per-user XDG state directory without modifying HOME or the immutable game files.")
    ;; docs/readme.txt grants GPL v2 for the project.  libfov is MIT,
    ;; MT19937 is BSD-3, and bundled MEMWATCH carries a GPL2-or-later grant.
    (license (list license:gpl2 license:expat license:bsd-3 license:gpl2+))))
