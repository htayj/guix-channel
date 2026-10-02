;;; Installed-library consumer environment, never a development profile.
(add-to-load-path
 (string-append (dirname (current-filename)) "/../guix"))

(use-modules (guix profiles)
             (tay packages domainslib)
             (gnu packages commencement)
             (gnu packages base)
             (gnu packages linux))

(packages->manifest
 (list (@@ (tay packages miou) miou-ocaml)
       (@@ (tay packages miou) miou-findlib)
       domainslib
       gcc-toolchain
       coreutils
       diffutils
       util-linux
       grep))
