;;; Praat 7.0.02, extending the Guix 6.6.30 package with the full desktop build.

(define-module (tay packages praat)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module ((gnu packages language) #:prefix upstream:)
  #:use-module (tay packages auxiliary))

;; Keep Debian's exact, versioned per-file license audit with the installation.
;; The upstream built-in Acknowledgments/License manual supplements this audit
;; (notably BLAKE3's CC0 grant) and remains available inside the application.
(define %praat-copyright
  (origin
    (method url-fetch)
    (uri "https://sources.debian.org/data/main/p/praat/7.0.02%2Bdfsg-1/debian/copyright")
    (file-name "praat-7.0.02-debian-copyright")
    (sha256
     (base32 "1sxma04rz6w0qxnsckx3ax3vm49fmhpbh1nidympiqghx8qz5vr1"))))

(define-public praat
  (package
    (inherit upstream:praat)
    (version "7.0.02")
    (source
     (origin
       (method url-fetch)
       ;; Audited Debian repack of upstream commit
       ;; 6f3da9ef1d8cce0d5684afc104d02888dfc71b25 in the canonical repository
       ;; https://github.com/praat/praat.github.io.  Files-Excluded in the
       ;; copyright audit above removes ONLY:
       ;; test/manually/spit/*exe, *intel64, *arm64; docs/*.exe;
       ;; docs/sendpraat*-linux-*, docs/sendpraat*-mac; docs/*.zip;
       ;; docs/silipa93.sit; generate/Unicode/UAX*.html.
       ;; Keep all remaining source, manual, fixtures and both test suites,
       ;; except the four fair-use-only screenshots documented below.
       (uri (string-append "https://deb.debian.org/debian/pool/main/p/praat/"
                           "praat_" version "+dfsg.orig.tar.xz"))
       (sha256
        (base32 "0rrjs028qry6shxkrr5khvbs6iv0asa56z9gdijymqymvjx4njj5"))
       (patches
        (list (search-tay-package-file "patches/praat-dwtest-driver.patch")))
       (patch-flags '("-p1" "--fuzz=0"))
       (modules '((guix build utils)))
       (snippet
        ;; Debian's repack misses these Microsoft Windows screenshots.
        ;; docs/LICENSE.txt explicitly relies on fair use, not a free license.
        ;; They are download instructions, unused by the build/manual/tests.
        #~(for-each delete-file
                    '("docs/pictures/arm64.png"
                      "docs/pictures/dontrun.png"
                      "docs/pictures/intel64.png"
                      "docs/pictures/unblock.png")))))
    ;; Reuse Guix's GNU build system and GTK3/ALSA/JACK/PulseAudio inputs.
    ;; Praat deliberately builds its adapted vendored numeric/audio libraries;
    ;; replacing them with incompatible stock libraries would lose features.
    (arguments
     (list
      #:make-flags
      #~(list "PRAAT_OS=linux"
              (string-append "CC=" #$(cc-for-target))
              (string-append "CXX=" #$(cxx-for-target))
              (string-append "LINKER_COMMAND=" #$(cxx-for-target))
              (string-append "PKG_CONFIG=" #$(pkg-config-for-target))
              (string-append "PREFIX=" #$output))
      #:parallel-tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'use-store-shell
            (lambda _
              ;; runSystem/runSystem$ must work beyond Guix's /bin/sh build
              ;; sandbox bind mount, in the installed scripting interface.
              (substitute* "melder/melder_sysenv.cpp"
                (("\"/bin/sh\"")
                 (string-append "\"" #$(file-append bash-minimal "/bin/sh")
                                "\"")))))
          (add-after 'unpack 'prepare-offline-tests
            (lambda _
              ;; Retain the real home-directory assertions rather than Guix
              ;; 6.6.30's deletion of them.  Never read the user's preferences,
              ;; recognition models or plugins, and never fetch test data.
              (let ((home (string-append (getcwd) "/test-home")))
                (mkdir-p home)
                (setenv "HOME" home))
              ;; The upstream drivers hardcode eight worker threads.  Follow
              ;; the requested Guix build parallelism, including --cores=1,
              ;; without restricting the installed application's threading.
              (substitute* '("test/runAllTests_batch.praat"
                             "dwtest/runAllTests_batch.praat")
                (("Debug multi-threading: \"yes\", 8, 0, \"no\"")
                 (string-append "Debug multi-threading: \"yes\", "
                                (number->string (parallel-job-count))
                                ", 0, \"no\"")))))
          (replace 'check
            (lambda* (#:key tests? #:allow-other-keys)
              (when tests?
                (let ((executable (string-append (getcwd) "/praat")))
                  ;; --FULL-TRUST permits the upstream filesystem tests in
                  ;; the isolated sandbox, as in Debian's test runner.
                  (for-each
                   (lambda (directory)
                     (with-directory-excursion directory
                       (invoke executable "--FULL-TRUST" "--run"
                               "runAllTests_batch.praat")))
                   '("test" "dwtest"))))))
          (add-after 'install 'install-license-notices
            (lambda _
              (let ((doc (string-append #$output "/share/doc/praat-" #$version)))
                (mkdir-p doc)
                (copy-file #+%praat-copyright
                           (string-append doc "/debian-copyright"))
                (install-file "main/gpl-3.0.txt" doc)
                (install-file "fon/manual_licenses.cpp" doc)
                (for-each
                 (lambda (library)
                   (install-file
                    (string-append "external/" library "/COPYING")
                    (string-append doc "/" library)))
                 '("opusfile" "vorbis"))
                (for-each
                 (lambda (notice)
                   (install-file (string-append "external/whispercpp/" notice)
                                 (string-append doc "/whispercpp")))
                 '("LICENSE-whisper-cpp.txt" "LICENSE-Whisper-OpenAI"
                   "LICENSE-Silero-VAD"))))))))
    (home-page "https://praat.org/")
    (synopsis "Speech analysis, synthesis and phonetic annotation")
    (description
     "Praat analyzes, synthesizes and manipulates speech.  It offers pitch,
formant, intensity and spectral analysis, TextGrid annotation, speech synthesis,
statistical and numerical tools, and a scripting language.  The GTK3 desktop
and command-line scripting interface share the same executable, with ALSA,
JACK and PulseAudio support.  The source includes Praat's adapted third-party
libraries and the built-in manual; their license notices accompany the package.")
    ;; The combined program is GPL3+ (fon/manual_licenses.cpp).  The remaining
    ;; source website is CC-BY-SA4.0; the installed notice files enumerate the
    ;; mixed GPL/LGPL/BSD/MIT/Boost/Unicode/CC0/zlib vendored components.
    (license (list license:gpl3+ license:cc-by-sa4.0))))
