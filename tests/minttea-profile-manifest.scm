;;; Real package objects retain search-path metadata for native consumers.

(use-modules (gnu packages commencement)
             (gnu packages multiprecision)
             (guix profiles)
             (tay packages minttea)
             (tay packages ocaml-minttea-toolchain))

(packages->manifest
 (list minttea
       ocaml-minttea
       ocaml-findlib-minttea
       gcc-toolchain
       ;; Zarith's native archive links -lgmp through Riot's TLS closure.
       gmp))
