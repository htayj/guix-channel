;;; GNU Guix package for Ighalsk.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages ighalsk)
  #:use-module (tay packages auxiliary)
  #:use-module (guix build-system gnu)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages fonts)
  #:use-module (gnu packages python)
  #:use-module (gnu packages tcl))

(define %ighalsk-data-patch
  (local-file (search-tay-package-file "patches/ighalsk-immutable-data.patch")))
(define %ighalsk-smoke
  (local-file (search-tay-package-file "ighalsk-smoke.py")))

(define-public ighalsk
  (package
    (name "ighalsk")
    (version "0.1.16")
    (source
     (origin
       (method url-fetch)
       ;; Embedded SVN metadata identifies release_0_1_16 at revision 380.
       (uri (string-append "https://downloads.sourceforge.net/project/ighalsk/"
                           "ighalsk/" version "/ighalsk-" version "-src.zip"))
       (sha256
        (base32 "1vd5vpbqbi60x9z0kj7p3bpv6yfm78532p1xpzw27c4s8c2hf32g"))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
          (add-after 'unpack 'enter-source
            (lambda _
              ;; The archive contains two identically named directory layers.
              (chdir "ighalsk-0.1.16-src")))
          (add-after 'check 'integrate-state-and-data
            (lambda _
              ;; The Windows-produced archive stores Python sources as CRLF.
              ;; Normalize source text before applying the reviewed LF patch.
              (substitute* (find-files "." "\\.py$")
                (("\r") ""))
              (invoke "patch" "-p1" "--no-backup-if-mismatch"
                      "--input" #$%ighalsk-data-patch)
              (delete-file "igh2exe.py") ; unlicensed Windows-only py2exe helper
              (for-each delete-file-recursively
                        (find-files "." "\\.svn$" #:directories? #t))
              ;; Editors retain installed templates and list their saved XDG
              ;; versions separately; every editor save goes to writable state.
              (for-each
               (lambda (file)
                 (substitute* file
                   (("import sys") "import os\nimport sys")
                   (("dataPath = \"..//\"")
                    (string-append "dataPath = os.path.dirname(os.path.dirname("
                                   "os.path.abspath(__file__))) + os.sep"))))
               '("Editor/LevelEditor.py" "Editor/MonsterEditor.py"
                 "Editor/MonsterController.py" "Editor/MonsterViewer.py"))
              (substitute* "Editor/MonsterController.py"
                (("saveAs\\(dataPath \\+ filename\\)")
                 "saveAs(os.path.join(os.environ['IGHALSK_STATE_DIR'], filename))"))))
          (delete 'configure)
          (delete 'build)
          (replace 'check
            (lambda* (#:key inputs tests? #:allow-other-keys)
              (when tests?
                (setenv "PYTHONDONTWRITEBYTECODE" "1")
                (setenv "PYTHONPATH"
                        (string-append #$python-2:tk
                                       "/lib/python2.7/site-packages"))
                (with-directory-excursion "test"
                  ;; TestAll.py does not propagate failures in its exit code.
                  ;; Reuse every upstream suite, but make failures fatal.
                  (invoke #$(file-append python-2 "/bin/python2") "-c"
                          (string-append
                           "import TestAll, unittest, sys; "
                           "suite = unittest.TestSuite([m.TheTestSuite() "
                           "for n, m in vars(TestAll).items() "
                           "if n.startswith('Test')]); "
                           "sys.exit(not unittest.TextTestRunner(verbosity=2)"
                           ".run(suite).wasSuccessful())"))))))
          (delete 'install-license-files)
          (replace 'install
            (lambda* (#:key inputs #:allow-other-keys)
              (let* ((data (string-append #$output "/share/ighalsk"))
                     (doc (string-append #$output "/share/doc/ighalsk"))
                     (bin (string-append #$output "/bin"))
                     (libexec (string-append #$output "/libexec/ighalsk"))
                     (python #$(file-append python-2 "/bin/python2"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (tk-site (string-append #$python-2:tk
                                             "/lib/python2.7/site-packages")))
                (for-each mkdir-p (list data doc bin libexec))
                ;; Install only the licensed application closure, never test
                ;; scratch files or the embedded version-control working copy.
                (when (file-exists? "data/quests/allwalls.txt")
                  (delete-file "data/quests/allwalls.txt"))
                (for-each
                 (lambda (directory)
                   (copy-recursively directory (string-append data "/" directory)))
                 '("Common" "Model" "View" "Controller" "Editor" "data" "help"))
                (for-each (lambda (file) (install-file file data))
                          '("ighalsk.py" "armour.txt" "weapons.txt" "powers.txt"
                            "monsters.txt" "onemonsterd.txt" "families.txt"
                            "epithets.txt" "quests.txt" "shops.txt"
                            "COPYING" "CREDITS" "README" "FEATURES" "changelog.txt"))
                (for-each (lambda (file) (install-file file doc))
                          '("COPYING" "CREDITS" "README" "FEATURES" "changelog.txt"))
                (copy-file #$%ighalsk-smoke
                           (string-append libexec "/ighalsk-smoke.py"))
                (call-with-output-file (string-append bin "/ighalsk")
                  (lambda (port)
                    (format port "#!~a\nset -eu\n" shell)
                    (format port "python=~s\ndata=~s\nsmoke=~s\nmkdir=~s\n"
                            python data (string-append libexec "/ighalsk-smoke.py") mkdir)
                    (format port "export PYTHONPATH=~s\n" tk-site)
                    (format port "export FONTCONFIG_FILE=~s\n"
                            (search-input-file inputs "etc/fonts/fonts.conf"))
                    (format port "export IGHALSK_FONT_DIR=~s\n"
                            #$(file-append font-dejavu "/share/fonts/truetype"))
                    (display "\
export PYTHONDONTWRITEBYTECODE=1
data_home=\"${XDG_DATA_HOME:-${HOME:?HOME must be set}/.local/share}\"
state=\"$data_home/ighalsk\"
\"$mkdir\" -p \"$state/data/quests\"
export IGHALSK_STATE_DIR=\"$state\"
cd \"$state\"
case \"${1-}\" in
  --guix-smoke)
    test \"$#\" -eq 1 || {
      echo 'usage: ighalsk [--guix-smoke|--level-editor|--monster-editor]' >&2
      exit 64
    }
    exec \"$python\" \"$smoke\" \"$data\" ;;
  --level-editor) program=\"$data/Editor/LevelEditor.py\" ;;
  --monster-editor) program=\"$data/Editor/MonsterEditor.py\" ;;
  '') program=\"$data/ighalsk.py\" ;;
  *) echo 'usage: ighalsk [--guix-smoke|--level-editor|--monster-editor]' >&2; exit 64 ;;
esac
test \"$#\" -le 1 || exit 64
exec \"$python\" \"$program\"
" port)))
                (chmod (string-append bin "/ighalsk") #o555)))))))
    (native-inputs (list unzip))
    (inputs
     `(("bash-minimal" ,bash-minimal)
       ("coreutils-minimal" ,coreutils-minimal)
       ("python2" ,python-2)
       ("python2:tk" ,python-2 "tk")
       ("tk" ,tk)
       ("fontconfig-minimal" ,fontconfig)
       ("font-dejavu" ,font-dejavu)))
    (home-page "https://sourceforge.net/projects/ighalsk/")
    (synopsis "Python and Tk dungeon adventure")
    (description
     "Ighalsk is a turn-based dungeon adventure with procedurally generated
levels, quests, equipment, powers, and level and monster editors.  This package
runs the original Python 2 and Tk application from its fixed source release.
Game data and editor templates are immutable; saves, scores and editor output
live below @env{XDG_DATA_HOME}/ighalsk, defaulting to
@file{~/.local/share/ighalsk}.  Editors can reopen saved user versions while
retaining access to shipped templates.  The @option{--guix-smoke} mode exercises
the actual Tk application, movement, game save/load and editor save/reload on an
external display; screenshot capture is optional.")
    ;; Source headers and COPYING say GPLv3+, despite SF's GPLv2 metadata.
    (license license:gpl3+)))
