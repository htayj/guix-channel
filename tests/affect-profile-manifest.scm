;;; Package objects for the isolated Affect consumer profile.  Unlike raw
;;; store-item installs, these retain the packages' native search paths.

(use-modules (gnu packages commencement)
             (guix profiles)
             (tay packages affect)
             (tay packages ocaml-affect-toolchain))

(packages->manifest
 (list affect
       ocaml-affect
       ocaml-findlib-affect
       ocaml-cmdliner-affect
       gcc-toolchain))
