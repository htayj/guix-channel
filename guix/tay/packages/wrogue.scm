;;; Warp Rogue's recovered original 0.8.0 release.

(define-module (tay packages wrogue)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages sdl))

(define-public wrogue
  (package
    (name "wrogue")
    (version "0.8.0")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             ;; LibreGameWiki identifies this recovery of the last original
             ;; release.  Later commits port only the Mac build to SDL2.
             (url "https://github.com/anthonycicc/warp_rogue")
             (commit "675bb5db48434469582367c420b907b129bd6543")))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1klv8ya4pqfll4qvafb3rqyrnlzgnsq0kj0yxshzf54021y51q6c"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f                       ;upstream has no test target
      #:make-flags #~(list "-f" "unix.mak" "release"
                          (string-append "CC=" #$(cc-for-target)))
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'enter-source-directory
            (lambda _ (chdir "src")))
          (replace 'install
            (lambda _
              (let* ((data (string-append #$output "/share/wrogue"))
                     (doc (string-append #$output "/share/doc/wrogue"))
                     (program (string-append #$output "/libexec/wrogue"))
                     (launcher (string-append #$output "/bin/wrogue")))
                (install-file "wrogue" (dirname program))
                ;; Install every original game resource, including the bitmap
                ;; font, scenarios, character scripts, help and credits.
                ;; No Mac bundle, SDLMain, or Windows assets are installed.
                (copy-recursively "../data" (string-append data "/data"))
                (for-each (lambda (file) (install-file file doc))
                          '("../license.txt" "../changes.txt"
                            "../compile_guide.txt" "../scenario_guide.txt"
                            "platform/unix/readme.txt" "platform/sdl/sdl.txt"
                            "../data/info/credits.txt"))
                ;; MT19937 has a separate BSD notice with binary distribution
                ;; obligations.  Keep its complete unmodified source notice.
                (install-file "lib/tt.c" (string-append doc "/third-party"))
                ;; Unix data reads are relative to cwd; all mutable state is
                ;; directed by upstream to $HOME/.wrogue, not to this directory.
                (mkdir-p (dirname launcher))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%cd ~s~%exec ~s \"$@\"~%"
                            #$(file-append bash-minimal "/bin/sh") data program)))
                (chmod launcher #o555)))))))
    (inputs (list bash-minimal sdl))
    (home-page "https://github.com/anthonycicc/warp_rogue")
    (synopsis "Gothic science fantasy roguelike with recruitable companions")
    (description
     "Warp Rogue is a turn-based science fantasy roguelike with character
careers, psychic powers, tactical combat and recruitable companions.  This
package builds the recovered original 0.8.0 C release with SDL 1.2 and includes
its complete scenario, bitmap font, graphics, help and scripts.  Saved games
and user settings are stored in @file{~/.wrogue}.  The game is no longer
maintained upstream.")
    ;; Root license.txt and changes.txt establish GPLv3; LibreGameWiki also
    ;; records GPL for the media.  lib/tt.c contains the BSD-3 MT19937 notice.
    (license (list license:gpl3 license:bsd-3))))
