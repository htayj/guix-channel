;;; City of the Condemned -- Tapio Vierros's terminal roguelike.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages city-of-the-condemned)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system cmake)
  #:use-module (guix download)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages ncurses))

;; Preserve the original project's MIT declaration, rather than manufacturing
;; a copyright holder or treating a later mirror as the licensing authority.
(define reflexivelos-license-declaration
  (origin
    (method url-fetch)
    (uri "https://storage.googleapis.com/google-code-archive/v2/code.google.com/reflexivelos/project.json")
    (file-name "reflexivelos-project.json")
    (sha256
     (base32 "1s32n6v8bldfdrq327vi71h9dahhksccnmvqyn7w4dypnndc6p3c"))))

(define-public city-of-the-condemned
  (let ((commit "e9a8989d34c9d3e0c68e7e42b526e1bee923ac7c")
        (revision "0"))
    (package
      (name "city-of-the-condemned")
      (version (git-version "1.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/tapio/cotc")
               (commit commit)))
         (file-name (git-file-name name version))
         ;; NAR hash of the actual checkout, excluding only .git metadata.
         (sha256
          (base32 "0wrjwsiy5vg27hz0mzdja2v3nyclpicajnl5xidkhxn5sjx0ldvk"))
         (modules '((guix build utils)))
         (snippet
          '(begin
             ;; These are upstream's Windows and x86 prebuilt executables and
             ;; PDCurses DLL.  Build the complete game from the .cc/.hh sources.
             (delete-file-recursively "bin")))
         (patches
          (list (search-tay-package-file
                 "patches/city-of-the-condemned-cmake.patch")))))
      (build-system cmake-build-system)
      (arguments
       (list
        #:tests? #f                     ;Upstream provides no automated tests.
        #:configure-flags #~(list (string-append "-DCOTC_VERSION=" #$version))
        #:phases
        #~(modify-phases %standard-phases
            (add-after 'unpack 'install-notices
              (lambda _
                (let ((doc (string-append #$output
                                          "/share/doc/city-of-the-condemned")))
                  (for-each (lambda (file) (install-file file doc))
                            '("LICENSE" "README.md"))
                  (copy-file #$reflexivelos-license-declaration
                             (string-append doc "/reflexivelos-project.json"))
                  (call-with-output-file
                      (string-append doc "/THIRD-PARTY-NOTICES")
                    (lambda (port)
                      (display
                       (string-append
                        "City of the Condemned
=====================
Source: https://github.com/tapio/cotc
Commit: e9a8989d34c9d3e0c68e7e42b526e1bee923ac7c
The upstream LICENSE is retained verbatim: MIT, copyright (c) 2010-2013
Tapio Vierros.  This includes the author's Knight of Faith town generator
ported in generator.cc.  No prebuilt binaries, DLLs or external game assets
are installed; the game's text and terminal display come from these sources.

Reflexivelos field of view
=========================
world.cc retains upstream's attribution verbatim:
  // FOV algorithm from reflexivelos roguelike engine under MIT License.
  // Based on generalization of Bresenham, runs in O(N^3).
The implementation is retained, not replaced.  Its fov_dir core ports
showdir in the original project's trunk/los2.cpp (eps/ad2/s digital-line
loops), adapting tile access and visibility to this game.
Original project and grant:
https://storage.googleapis.com/google-code-archive/v2/"
                        "code.google.com/reflexivelos/project.json
The adjacent reflexivelos-project.json retains the original project metadata,
including license: mit and the author's declaration: 'This is a roguelike
engine I've been developing in my spare time. I'm putting it online so I
don't lose it when my computer explodes, but please, reuse the code.'
Metadata SHA-256: 6c5cc39ab5d737c28ff57857cb989e10aa966038711f31706eaed185b6b162e8
Original source archive:
https://storage.googleapis.com/google-code-archive-source/v2/"
                        "code.google.com/reflexivelos/source-archive.zip
Archive SHA-256: 8f7ca7e8f8f149f313753c483ba0ec4d1e920200064c95c1f6d43ee91a03919e
The archive's SVN metadata records the alias notzeb.  No separate license
notice, copyright year or legal holder name was found in its 39 non-SVN
files.  None is invented here.  A later source mirror is
https://github.com/RealityWarper/reflexivelos at commit
07d906ab89727f9ca059d813351e71eb31ec703c.

MIT terms reference
===================
The following canonical MIT permission and disclaimer text is a reference
for the original project's declared license, not a newly authored grant or
an assertion of a missing copyright notice.  Reference:
https://opensource.org/license/mit
https://spdx.org/licenses/MIT.html

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the \"Software\"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Dependencies and writable state
===============================
Boost headers are supplied by the separate Guix Boost package under the
Boost Software License 1.0; ncurses by Guix under the X11 license.  The
launcher uses separate Guix Bash and Coreutils packages under their own
GPL licenses.  Their original notices are retained by those packages.
The launcher preserves HOME and changes only the working directory to
${XDG_STATE_HOME:-$HOME/.local/state}/city-of-the-condemned.  Upstream writes
log.log there; it has no save/load facility.  No persistence is added.
") port))))))
            (replace 'install
              (lambda _
                ;; Upstream has no install target or external runtime data.
                (let* ((bin (string-append #$output "/bin"))
                       (libexec (string-append #$output "/libexec"))
                       (launcher (string-append bin "/city-of-the-condemned")))
                  (mkdir-p bin)
                  (mkdir-p libexec)
                  (copy-file "CotC" (string-append libexec "/cotc"))
                  (chmod (string-append libexec "/cotc") #o555)
                  (call-with-output-file launcher
                    (lambda (port)
                      (format port "#!~a/bin/sh~%" #$bash-minimal)
                      (display
                       (string-append
                        "set -eu\numask 077\n"
                        "state=${XDG_STATE_HOME:-${HOME:?HOME must be set}"
                        "/.local/state}/city-of-the-condemned\n") port)
                      (display
                       (string-append
                        "case $state in\n  /*) ;;\n"
                        "  *) printf '%s\\n' 'city-of-the-condemned: "
                        "state directory must be absolute' >&2; exit 1 ;;\n"
                        "esac\n") port)
                      (format port "~a/bin/mkdir -p -- \"$state\"~%"
                              #$coreutils-minimal)
                      (display "cd -- \"$state\"\n" port)
                      (format port
                              (string-append
                               "export TERMINFO_DIRS=\""
                               "${TERMINFO_DIRS:+$TERMINFO_DIRS:}"
                               "~a/share/terminfo\"~%") #$ncurses)
                      (format port "exec ~a/libexec/cotc \"$@\"~%" #$output)))
                  (chmod launcher #o555)))))))
      (inputs (list bash-minimal coreutils-minimal boost ncurses))
      (home-page "https://github.com/tapio/cotc")
      (synopsis "Terminal roguelike set in a city of angels and demons")
      (description
       "City of the Condemned is a turn-based terminal roguelike.  Play an angel
or an imp in a procedurally generated town, fighting or influencing its human,
angelic and demonic inhabitants with role-specific abilities.  The original
ncurses interface and reflexivelos field-of-view algorithm are retained.
Only its diagnostic log is written to a per-user XDG state directory; the
upstream game does not save or load sessions.")
      (license (list license:expat license:boost1.0)))))
