;;; GNU Guix package definition for the proprietary SentinelOne Linux agent.

(define-module (tay packages sentinelone)
  #:use-module (guix build-system copy)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages debian)
  #:use-module (gnu packages elf))

(define %sentinelone-version "24.3.3.1")

(define %sentinelone-file-name
  "SentinelAgent-Linux-24-3-3-1-x86-64-release-24-3-3_linux_x86_64_v24_3_3_1.deb")

(define %sentinelone-upstream-sha256
  "0mrfn998zqxilng2zi1mp65a83m9z83z7l9rd0gfgpg6hm2s21hj")

(define %sentinelone-placeholder-source
  (plain-file
   "sentinelone-installer-required"
   "This is not a SentinelOne installer.\n\
Supply an authorized Debian installer with --with-source=sentinelone=PATH.\n"))

(define %sentinelone-license
  ((@ (guix licenses) license)
   "SentinelOne proprietary license"
   "https://www.sentinelone.com/legal/"
   "Use and redistribution are governed by the applicable SentinelOne agreement."))

(define-public sentinelone
  (package
    (name "sentinelone")
    (version %sentinelone-version)
    ;; No vendor artifact is fetched or distributed by this channel.  These
    ;; immutable provenance values come from sentinelone-guix upstream commit
    ;; 2ed11dd6f935e0498c2bf91d355990c062147c2c; the hash is intentionally not
    ;; used to fetch an installer.  Replace this harmless source explicitly:
    ;;
    ;;   guix build -L . --with-source=sentinelone=/path/to/INSTALLER.deb \
    ;;     sentinelone
    (source %sentinelone-placeholder-source)
    (build-system copy-build-system)
    (arguments
     (list
      ;; Do not distribute this proprietary agent through Guix substitutes.
      ;; This does not prevent an operator from publishing their local source
      ;; store item; that requires publish-server ACLs outside this definition.
      #:substitutable? #f
      ;; Preserve the opaque vendor binaries and their integrity metadata.
      #:strip-binaries? #f
      #:patch-shebangs? #f
      ;; The vendor controls most ELF metadata.  Only the known libbpf
      ;; compatibility issue below is changed deliberately.
      #:validate-runpath? #f
      #:phases
      #~(modify-phases %standard-phases
          (replace 'unpack
            (lambda* (#:key source #:allow-other-keys)
              (use-modules (ice-9 popen)
                           (ice-9 rdelim))
              (when (string-suffix? "sentinelone-installer-required" source)
                (error
                 (string-append
                  "SentinelOne installer not supplied; use --with-source=sentinelone="
                  "/path/to/"
                  #$%sentinelone-file-name)))
              (define (deb-field field)
                (let ((port (open-pipe* OPEN_READ "dpkg-deb" "-f" source field)))
                  (let ((value (read-line port)))
                    (close-pipe port)
                    value)))
              (define (validate-deb-field field expected)
                (let ((actual (deb-field field)))
                  (unless (and (string? actual) (string=? actual expected))
                    (error "installer has unexpected Debian field"
                           field actual "expected" expected))))
              (validate-deb-field "Version" #$%sentinelone-version)
              (validate-deb-field "Architecture" "amd64")
              (invoke "dpkg-deb" "-x" source ".")))
          ;; The input is an opaque vendor payload.  Do not rewrite, delete,
          ;; re-compress, or otherwise mutate it outside the libbpf fix below.
          (delete 'patch-usr-bin-file)
          (delete 'patch-source-shebangs)
          (delete 'patch-generated-file-shebangs)
          (delete 'patch-shebangs)
          (delete 'strip)
          (delete 'delete-info-dir-file)
          (delete 'patch-dot-desktop-files)
          (delete 'make-dynamic-linker-cache)
          (delete 'install-license-files)
          (delete 'reset-gzip-timestamps)
          (delete 'compress-documentation)
          (replace 'install
            (lambda _
              (let* ((sentinel-root (string-append #$output "/opt/sentinelone"))
                     (bin (string-append #$output "/bin")))
                (unless (file-exists? "opt/sentinelone")
                  (error "installer does not contain opt/sentinelone"))
                (mkdir-p (dirname sentinel-root))
                (copy-recursively "opt/sentinelone" sentinel-root)
                (mkdir-p bin)
                (for-each (lambda (program)
                            (let ((target (string-append sentinel-root "/bin/"
                                                         program)))
                              (unless (file-exists? target)
                                (error
                                 "installer is missing expected executable"
                                 program))
                              (symlink target
                                       (string-append bin "/" program))))
                          '("sentinelctl" "sentinelone-agent"
                            "sentinelone-watchdog"))
                (symlink (string-append sentinel-root "/lib")
                         (string-append #$output "/lib")))))
          (add-after 'install 'fix-libbpf
            (lambda _
              (let ((libbpf (string-append #$output
                                           "/opt/sentinelone/lib/libbpf.so")))
                (when (file-exists? libbpf)
                  ;; SentinelOne ships a libbpf linked to libelf.so.0, while
                  ;; current elfutils exposes the compatible libelf.so name.
                  (invoke "patchelf" "--replace-needed" "libelf.so.0"
                          "libelf.so" libbpf)
                  (invoke "patchelf" "--set-rpath"
                          (string-append #$output
                                         "/opt/sentinelone/lib:"
                                         #$elfutils
                                         "/lib:"
                                         #$zlib
                                         "/lib") libbpf))))))))
    (native-inputs (list dpkg patchelf))
    (inputs (list elfutils zlib))
    (supported-systems '("x86_64-linux"))
    (synopsis "Endpoint security agent from SentinelOne")
    (description
     "This package extracts the proprietary SentinelOne Linux agent from its
Debian installer and exposes its control, agent, and watchdog executables.
No installer is bundled or fetched: supply an authorized Debian installer with
@code{--with-source}.  The installer must declare the expected version and
@code{amd64} architecture.  A management token and a system service
configuration are required to run the agent.")
    (home-page "https://www.sentinelone.com/")
    ;; The channel is GPL-3.0-or-later; the agent remains proprietary.
    (license %sentinelone-license)))
