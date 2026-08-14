;;; Immutable GitHub source snapshots for this channel.

(define-module (tay packages source-snapshot)
  #:use-module (guix build-system copy)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:export (make-github-source-snapshot
            %no-permission-license))

(define %no-permission-license
  (license:non-copyleft
   "https://choosealicense.com/no-permission/"
   "No explicit license was found; redistribution permission is not granted."))

(define* (make-github-source-snapshot package-name
                                      owner
                                      github-owner
                                      repo
                                      commit
                                      hash
                                      synopsis
                                      home-page
                                      project-license)
  "Return a non-mutating package for the exact GitHub codeload archive at
COMMIT.  OWNER determines the channel's stable installation namespace, while
GITHUB-OWNER selects the current upstream repository location."
  (let ((destination (string-append "share/" owner "/projects/" repo)))
    (package
      (name package-name)
      (version (string-append "0-" (substring commit 0 7)))
      (source
       (origin
         (method url-fetch)
         (uri (string-append "https://codeload.github.com/"
                             github-owner "/" repo "/tar.gz/" commit))
         (file-name (string-append repo "-" commit ".tar.gz"))
         (sha256 (base32 hash))))
      (build-system copy-build-system)
      (arguments
       (list
        ;; The archive is preservation material, not a build input.  Retain
        ;; its unpacked bytes rather than applying any standard mutation.
        #:phases
        #~(modify-phases %standard-phases
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
            (delete 'compress-documentation))
        #:install-plan #~(list (list "." #$destination))))
      (synopsis (string-append (string-upcase (substring synopsis 0 1))
                               (substring synopsis 1)))
      (description
       (string-append
        "This package installs an immutable source snapshot of " repo
        " at its recorded Git commit under @file{" destination
        "}.  It is intended for development, preservation, and downstream"
        " Guix packages; it does not build or alter the upstream source."))
      (home-page home-page)
      (license (or project-license %no-permission-license)))))
