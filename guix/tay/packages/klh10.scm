;;; KLH10 host emulator, without the separately licensed Auxiliary Distribution.

(define-module (tay packages klh10)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:))

;; This is the eight-clause grant at the pin below, NOT the later UW license
;; with an export-control clause.  README explicitly permits unrestricted use.
;; Its operative clauses match the UW Free-Fork grant shipped in Debian main:
;; https://sources.debian.org/src/uw-imap/7%3A2002edebian1-11sarge1/debian/copyright
;; Source disclosure, origin labels, notice retention, warranty disclaimer and
;; no-endorsement terms preserve the four freedoms required by Guix:
;; https://guix.gnu.org/manual/en/html_node/Software-Freedom.html
;; Clauses 5 and 6 preserve upstream's rights and allow other free licenses;
;; clause 7 excludes non-releasable proprietary additions, not commercial use.
;; No named FSF approval or GNU Guix upstream acceptance is claimed here.
(define-public klh10-license
  (license:license
   "KLH10 Free-Fork (eight clauses)"
   "https://raw.githubusercontent.com/PDP-10/klh10/6d733f2a47644964492fd864454cbe1331655e53/LICENSE"
   "Source-sharing license derived from the eight-clause UW Free-Fork grant; retain notices and label modified versions."))

(define-public klh10
  (package
    (name "klh10")
    (version "2.0l-guix-0.6d733f2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://codeload.github.com/PDP-10/klh10/tar.gz/"
             "6d733f2a47644964492fd864454cbe1331655e53"))
       (file-name "klh10-6d733f2a47644964492fd864454cbe1331655e53.tar.gz")
       (sha256
        (base32 "1kg68m8yyd3za3y4yjfi5lrbf1hipvamqqv3dq7m5kgb61x19br8"))
       (modules '((guix build utils)))
       (snippet
        #~(with-fluids ((%default-port-encoding "ISO-8859-1"))
            ;; README/READaux exclude run and contrib from the host license.
            ;; Remove the entire auxiliary distribution, not just its binaries.
            (for-each delete-file-recursively
                      '("run" "contrib" "install-guides" ".github"))
            (delete-file "READaux")
            ;; Keep the console/reference and developer documentation only.
            ;; Installation/guest-OS guides recommend separately licensed code.
            (for-each
             (lambda (file)
               (unless (member file '("doc/cmdref.txt" "doc/cmdsum.txt"
                                      "doc/coding.txt"))
                 (delete-file file)))
             (find-files "doc"))
            ;; tapedd otherwise retains cmdsget's zero as failure status even
            ;; after a successful copy; its no-skip path also reads err unset.
            (substitute* "src/tapedd.c"
              (("if \\(!docopy\\(\\)\\) ")
               "ret = TRUE;\n    if (!docopy()) ")
              (("int err, ret = TRUE;") "int err = 0, ret = TRUE;"))
            ;; Clause 2 requires a visible origin tag on modified versions.
            (substitute* "configure.ac"
              (("\\[2\\.0l\\]") "[2.0l-guix]"))
            (substitute* "configure"
              (("2\\.0l") "2.0l-guix"))
            (substitute* "src/klh10.h"
              (("V2\\.0i") "V2.0i-guix"))
            ;; Native help/version terminate before host or machine setup.
            ;; Accept both the historical single-dash and GNU double-dash forms.
            (substitute* "src/klh10.c"
              (("/\\* Not yet \\*/") "/* Informational switch */")
              (("Usage: klh10 \\[-background\\] \\[initfile\\]")
               (string-append "Usage: klh10 [-background] [-help|--help] "
                              "[-version|--version] [initfile]"))
              (("res = s_xkeylookup\\(cp\\+1,")
               "res = s_xkeylookup(cp + (cp[1] == '-' ? 2 : 1),")
              (("case SWI_BKGD:")
               (string-append
                "case SWI_HELP:\n"
                "\t\tfputs(usage, stdout);\n"
                "\t\tfputs(\"Start without an initfile for the console; "
                "type help for commands.\\n\", stdout);\n"
                "\t\tos_exit(0);\n"
                "\t\treturn;\n"
                "\t    case SWI_VERSION:\n"
                "\t\tpversion(stdout);\n"
                "\t\tos_exit(0);\n"
                "\t\treturn;\n"
                "\t    case SWI_BKGD:"))
              ;; Compile timestamps make binaries unreproducible.
              (("#if defined\\(__DATE__\\) && defined\\(__TIME__\\)")
               "#if 0 /* Reproducible Guix build: omit wall-clock timestamp. */"))))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:out-of-source? #t
      #:tests? #f                      ;Upstream has no check target.
      #:configure-flags
      #~(list "--disable-lights" "--without-vde" "--disable-bridge"
              "CFLAGS=-std=gnu99 -fcommon")
      #:phases
      #~(modify-phases %standard-phases
          (replace 'build
            (lambda* (#:key parallel-build? #:allow-other-keys)
              ;; Do not build the network-interface processes or enaddr.
              ;; Explicit subdirectory invocations also propagate failures that
              ;; upstream's top-level shell-loop makefile otherwise discards.
              (let ((jobs (if parallel-build? (number->string (parallel-job-count)) "1"))
                    (flags (string-append
                            "CONFFLAGS_USR=-DKLH10_DEV_NI20=0 "
                            "-DKLH10_DEV_DPNI20=0 -DKLH10_DEV_CH11=0 "
                            "-DKLH10_DEV_LHDH=0 -DKLH10_DEV_DPIMP=0")))
                (for-each
                 (lambda (model)
                   (invoke "make" "-C" (string-append "bld-" model)
                           "-j" jobs flags
                           (string-append "kn10-" model) "dprpxx" "dptm03"))
                 '("kl" "ks" "ks-its"))
                (invoke "make" "-C" "bld-kl" "-j" jobs flags
                        "wfconv" "tapedd" "vdkfmt" "wxtest"
                        "udlconv" "uexbconv"))))
          (replace 'install
            (lambda _
              (let ((bin (string-append #$output "/bin"))
                    (libexec (string-append #$output "/libexec/klh10"))
                    (doc (string-append #$output "/share/doc/klh10")))
                (for-each
                 (lambda (model)
                   (install-file (string-append "bld-" model "/kn10-" model) bin))
                 '("kl" "ks" "ks-its"))
                (for-each
                 (lambda (program)
                   (install-file (string-append "bld-kl/" program) bin))
                 '("wfconv" "tapedd" "vdkfmt" "wxtest" "udlconv" "uexbconv"))
                (for-each
                 (lambda (program)
                   (install-file (string-append "bld-kl/" program) libexec))
                 '("dprpxx" "dptm03"))
                (symlink "kn10-kl" (string-append bin "/klh10"))
                (for-each
                 (lambda (file)
                   (install-file (string-append (getenv "KLH10_SOURCE_DIRECTORY")
                                                "/" file) doc))
                 '("LICENSE" "README" "doc/cmdref.txt"
                   "doc/cmdsum.txt" "doc/coding.txt")))
              ;; Clause 1 says modified distributions accompany their source
              ;; and documentation, not merely an offer to obtain them later.
              (copy-recursively (getenv "KLH10_SOURCE_DIRECTORY")
                                (string-append #$output "/share/klh10/source"))))
          (add-before 'configure 'locate-device-processes
            (lambda _
              (setenv "KLH10_SOURCE_DIRECTORY" (getcwd))
              ;; These use execl, not PATH lookup; installed emulators must not
              ;; require copies of helpers in their current working directory.
              ;; These legacy files contain literal Latin-1 copyright 0xa9.
              ;; Decode and re-encode one-to-one; never drop notice bytes.
              (with-fluids ((%default-port-encoding "ISO-8859-1"))
              (substitute* "src/dvrpxx.c"
                (("\"dprpxx\";")
                 (string-append "\"" #$output "/libexec/klh10/dprpxx\";")))
              (substitute* "src/dvtm03.c"
                (("\"dptm03\";")
                 (string-append "\"" #$output "/libexec/klh10/dptm03\";")))))))))
    (home-page "https://github.com/PDP-10/klh10")
    (synopsis "KL10 and KS10 PDP-10 host emulator")
    (description
     "KLH10 emulates the PDP-10 KL10 and KS10 processors and provides an
interactive front-end console with memory deposit/examine, single stepping,
breakpoints and device control.  This package includes three host emulator
configurations, disk and tape device processes, and image-conversion utilities.
It does not include guest systems, boot images, the Auxiliary Distribution,
network-interface processes or network services.  Modified sources and runtime
version banners carry the Guix origin tag required by the Free-Fork license.")
    (license klh10-license)))
