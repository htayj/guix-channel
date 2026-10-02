;;; Installed-library consumer environment, never a development profile.
(add-to-load-path
 (string-append (dirname (current-filename)) "/../guix"))

(use-modules (guix profiles)
             (tay packages miou)
             (gnu packages commencement)
             (gnu packages base)
             (gnu packages linux))

(packages->manifest
 (list (@@ (tay packages miou) miou-ocaml)
       (@@ (tay packages miou) miou-findlib)
       miou
       gcc-toolchain
       coreutils
       util-linux
       grep))
