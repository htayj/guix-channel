;;; GNU Guix package for robotfindskitten.

(define-module (tay packages robotfindskitten)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages texinfo))

(define-public robotfindskitten
  (package
    (name "robotfindskitten")
    (version "3.0000000.726")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append
         "https://codeberg.org/robotfindskitten/robotfindskitten/archive/"
         "471872786ca3a40db5b53f7baf96233a3793c45d.tar.gz"))
       (file-name (string-append name "-" version ".tar.gz"))
       ;; SHA-256:
       ;; 6be0c9bab746e8484e29b2033bb915a59880cc1205c9f4ec3a377c62ca6cd5e7
       (sha256
        (base32
         "1rymdk564z1p7bng9j852b6816552nwkn0xj5574is26nyxckq3b"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The release has no test programs, but Automake supplies a check
      ;; target.  Leave Guix's check phase enabled so that target is exercised.
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'configure 'bootstrap
            (lambda _
              ;; The source archive intentionally contains no generated
              ;; configure script or Makefiles.
              (invoke "autoreconf" "-vfi")))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (bin (string-append out "/bin"))
                     (installed
                      (string-append out "/games/robotfindskitten"))
                     (doc (string-append out "/share/doc/robotfindskitten")))
                ;; Let the upstream install rules place the complete runtime
                ;; set: NKI data, man/info documentation, desktop metadata,
                ;; and both icon formats.
                (invoke "make" "install")
                (mkdir-p bin)
                (mkdir-p doc)
                (rename-file installed (string-append bin "/robotfindskitten"))
                (rmdir (string-append out "/games"))
                ;; Keep the complete upstream license and REUSE information
                ;; beside every installed code and data asset.
                (for-each
                 (lambda (file) (install-file file doc))
                 '("AUTHORS" "BUGS" "ChangeLog" "COPYING" "NEWS"
                   "README.md" "REUSE.toml"))
                (install-file "LICENSES/GPL-2.0-or-later.txt" doc)))))))
    ;; Autoconf, Automake, and Libtool are needed to regenerate the release's
    ;; missing build machinery.  Texinfo is needed by doc/Makefile.am's
    ;; info_TEXINFOS target; no gnulib or TeX Live target is referenced.
    (native-inputs (list autoconf automake libtool texinfo))
    (inputs (list ncurses))
    (home-page "https://robotfindskitten.org/")
    (synopsis "Zen simulation of a robot finding kitten")
    (description
     "robotfindskitten is a meditative terminal game in which a robot moves
around a field of non-kitten items while searching for kitten.  This package
builds the fixed Codeberg release from source with the declared Autotools and
ncurses toolchain, installs its data, documentation, desktop metadata, and
icons.  The native ncurses executable supports colored items, eight-direction
movement, deterministic random seeds, and custom non-kitten item collections.
No build-time or runtime downloads are used.")
    ;; Source, NKI data, documentation, and icons are GPL-2.0-or-later.
    ;; AppStream explicitly declares CC-BY-SA-4.0 for its metadata (while
    ;; the file's SPDX header is GPL-2.0-or-later); retain both declarations.
    (license (list license:gpl2+ license:cc-by-sa4.0))))
