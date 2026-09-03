;;; GNU Guix package for the DRL terminal roguelike.
;;;
;;; SPDX-License-Identifier: GPL-2.0-only

(define-module (tay packages drl)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages pascal)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages xorg))

(define %drl-commit
  "90b797888be2550454b2b4b7d0df6aa9ef5b71ac")

(define %fpcvalkyrie-commit
  "f89735a741a968997656c2d48a003ec569db7f22")

(define %fpcvalkyrie-source
  (origin
    (method git-fetch)
    (uri (git-reference
          (url "https://github.com/ChaosForge/fpcvalkyrie")
          (commit %fpcvalkyrie-commit)))
    (file-name (git-file-name "fpcvalkyrie" "0.10.11"))
    (sha256
     (base32 "0i2dw8z70mqcwm1vccr2clvkzzhc5dn6vqjb24lx6a86ap8nldkg"))))

(define-public drl
  (package
    (name "drl")
    (version "0.10.11")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/chaosforgeorg/drl")
             (commit %drl-commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "02xqdnyhw2yw8hz220dnxfy8fq99s9d0ipsjm297kxrjdc551wif"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; The upstream repository has no automated test target.  The installed
      ;; console executable is exercised by tests/drl-smoke.sh instead.
      #:tests? #f
      #:parallel-build? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-before 'build 'prepare-fpcvalkyrie
            (lambda* (#:key inputs #:allow-other-keys)
              ;; The library source is an input and is consequently read-only.
              ;; The Pascal build also writes generated units beside it.
              (copy-recursively (assoc-ref inputs "fpcvalkyrie")
                                "fpcvalkyrie")
              ;; The pinned build scripts place compiler objects in this
              ;; repository-root directory.
              (mkdir-p "tmp")
              ;; The Lua build helper reads compiler flags from this list;
              ;; FPC_CMD is not an environment-variable lookup there.
              (substitute*
                  "makefile.lua"
                (("\"-Fu\"..VALKYRIE_ROOT..\"libs\",")
                 (string-append
                  "\"-Fu\"..VALKYRIE_ROOT..\"libs\",\n"
                  "\t\t\"-dLUA_DYNAMIC\",\n"
                  "\t\t\"-Fl" #$(file-append ncurses/tinfo "/lib") "\",\n"
                  "\t\t\"-Fl" #$(file-append libx11 "/lib") "\",\n"
                  "\t\t\"-k-rpath=" #$(file-append ncurses/tinfo "/lib") "\",\n"
                  "\t\t\"-k-rpath=" #$(file-append libx11 "/lib") "\",\n"
                  "\t\t\"-k-ltinfo\",")))
              ;; Valkyrie otherwise statically links Lua, which is not
              ;; available as an FPC static input in the required Lua 5.1
              ;; configuration.  DRL uses dlopen for this dynamic build.
              (substitute*
                  "fpcvalkyrie/libs/vlualibrary.pas"
                (("LuaDefaultPath = 'lua5\\.1\\.so';")
                 "LuaDefaultPath = 'liblua.so.5.1';"))
              ;; FPC expands these macros into the executable, so pin the
              ;; diagnostic values instead of embedding the build clock.
              (substitute*
                  "fpcvalkyrie/src/vlog.pas"
                (("\\{\\$I %TIME%\\}") "\"00:00:00\"")
                (("\\{\\$I %DATE%\\}") "\"1970-01-01\""))))
          (replace 'build
            (lambda _
              (setenv "FPCVALKYRIE_ROOT" "fpcvalkyrie/")
              (invoke #$(file-append lua-5.1 "/bin/lua")
                      "makefile.lua")))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/drl/data"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (config (string-append out "/share/drl"))
                     (data-root (string-append out "/share/drl/"))
                     (doc (string-append out "/share/doc/drl"))
                     (real (string-append libexec "/drl-real"))
                     (launcher (string-append bin "/drl"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (cat #$(file-append coreutils-minimal "/bin/cat"))
                     (cp #$(file-append coreutils-minimal "/bin/cp"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (mktemp #$(file-append coreutils-minimal "/bin/mktemp"))
                     (rm #$(file-append coreutils-minimal "/bin/rm"))
                     (sleep #$(file-append coreutils-minimal "/bin/sleep"))
                     (script #$(file-append util-linux "/bin/script"))
                     (lua-lib #$(file-append lua-5.1 "/lib"))
                     (terminfo #$(file-append ncurses/tinfo "/share/terminfo")))
                (mkdir-p data)
                (mkdir-p libexec)
                (mkdir-p bin)
                (mkdir-p config)
                (mkdir-p doc)
                (install-file "bin/drl" libexec)
                (rename-file (string-append libexec "/drl") real)
                ;; The console core consumes raw Lua/map/help data.  Graphics,
                ;; fonts, audio modules, and all ext/* foreign libraries are
                ;; intentionally not part of this output.
                (copy-recursively "bin/data/core"
                                  (string-append data "/core"))
                (copy-recursively "bin/data/drl"
                                  (string-append data "/drl"))
                (delete-file-recursively (string-append data "/drl/graphics"))
                (delete-file-recursively (string-append data "/drl/fonts"))
                (install-file "bin/config.lua" config)
                (for-each
                 (lambda (file) (install-file file doc))
                 '("README.md" "LICENSE" "bin/manual.txt" "bin/version.txt"
                   "bin/version_api.txt"))
                ;; fpcvalkyrie is source-built into the executable, so retain
                ;; its complete MIT notice alongside DRL's GPL notice.
                (copy-file "fpcvalkyrie/LICENSE"
                           (string-append doc "/FPCVALKYRIE-LICENSE"))
                ;; Preserve the license texts shipped by each runtime input.
                ;; FPC is native-only and is not copied into the output.
                (let ((notice-dir (string-append doc "/third-party-licenses")))
                  ;; The Lua 5.1 runtime output contains no notice file, even
                  ;; though its package metadata identifies the MIT license.
                  ;; Install the exact notice shipped in the pinned Lua source
                  ;; archive so the closure remains auditable.
                  (let ((lua-notice (string-append notice-dir
                                                   "/lua-5.1/COPYRIGHT")))
                    (mkdir-p (dirname lua-notice))
                    (call-with-output-file lua-notice
                      (lambda (port)
                        (display
                         (string-append
                          "Lua License\n"
                          "-----------\n\n"
                          "Lua is licensed under the terms of the MIT license "
                          "reproduced below.\n"
                          "This means that Lua is free software and can be used "
                          "for both academic\n"
                          "and commercial purposes at absolutely no cost.\n\n"
                          "For details and rationale, see "
                          "http://www.lua.org/license.html .\n\n"
                          "========================================"
                          "=======================================\n\n"
                          "Copyright (C) 1994-2012 Lua.org, PUC-Rio.\n\n"
                          "Permission is hereby granted, free of charge, to any person "
                          "obtaining a copy\n"
                          "of this software and associated documentation files (the "
                          "\"Software\"), to deal\n"
                          "in the Software without restriction, including without "
                          "limitation the rights\n"
                          "to use, copy, modify, merge, publish, distribute, sublicense, "
                          "and/or sell\n"
                          "copies of the Software, and to permit persons to whom the "
                          "Software is\n"
                          "furnished to do so, subject to the following conditions:\n\n"
                          "The above copyright notice and this permission notice shall "
                          "be "
                          "included in\n"
                          "all copies or substantial portions of the Software.\n\n"
                          "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY "
                          "KIND, "
                          "EXPRESS OR\n"
                          "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF "
                          "MERCHANTABILITY,\n"
                          "FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO "
                          "EVENT "
                          "SHALL THE\n"
                          "AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES "
                          "OR "
                          "OTHER\n"
                          "LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR "
                          "OTHERWISE, "
                          "ARISING FROM,\n"
                          "OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER "
                          "DEALINGS IN\n"
                          "THE SOFTWARE.\n\n"
                          "========================================"
                          "=======================================\n\n"
                          "(end of COPYRIGHT)\n")
                         port))))
                  (for-each
                   (lambda (item)
                     (let* ((root (car item))
                            (name (cdr item))
                            (target (string-append notice-dir "/" name))
                            (files (find-files
                                    root
                                    "^(COPYING|LICENSE|COPYRIGHT|NOTICE)([-.].*)?$")))
                       (unless (pair? files)
                         (error "runtime dependency has no discoverable license notice"
                                name))
                       (mkdir-p target)
                       (for-each
                        (lambda (file) (install-file file target))
                        files)))
                   (list (cons #$bash-minimal "bash")
                         (cons #$coreutils-minimal "coreutils")
                         (cons #$ncurses/tinfo "ncurses")
                         (cons #$libx11 "libx11")
                         (cons #$util-linux "util-linux"))))
                (call-with-output-file (string-append doc "/THIRD-PARTY-NOTICES")
                  (lambda (port)
                    (display
                     (string-append
                      "DRL runtime dependency and asset audit\n"
                      "=====================================\n\n"
                      "DRL code and data are GPL-2.0-only; see LICENSE.\n"
                      "The embedded FPC Valkyrie source is MIT licensed; see\n"
                      "FPCVALKYRIE-LICENSE.\n\n"
                      "The console build uses Guix bash-minimal,\n"
                      "coreutils-minimal, Lua 5.1, ncurses/tinfo, libX11, and\n"
                      "util-linux.  Their notices are under\n"
                      "third-party-licenses/.  Free Pascal is a native build\n"
                      "input and is not shipped by this package.\n\n"
                      "The upstream CC BY-SA graphics and font assets,\n"
                      "permission-based external music/sounds, audio modules,\n"
                      "and proprietary FMOD/Steam/SDL files are excluded.\n")
                     port)))
                (call-with-output-file launcher
                  (lambda (port)
                    (format port "#!~a~%set -eu~%" shell)
                    (format port "real=~s~%data=~s~%config=~s~%output=~s~%"
                            real data-root config out)
                    (format port "cat=~s~%cp=~s~%mkdir=~s~%mktemp=~s~%"
                            cat cp mkdir mktemp)
                    (format port "rm=~s~%sleep=~s~%script=~s~%"
                            rm sleep script)
                    (format port "lua_lib=~s~%terminfo=~s~%"
                            lua-lib terminfo)
                    (display
                     (string-append
                      "export LD_LIBRARY_PATH=\"$lua_lib"
                      "${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}\"\n")
                     port)
                    (display
                     (string-append
                      "export TERMINFO_DIRS=\"$terminfo"
                      "${TERMINFO_DIRS:+:$TERMINFO_DIRS}\"\n")
                     port)
                    (display
                     (string-append
                      "state_root=\"${XDG_STATE_HOME:-${HOME:?HOME or "
                      "XDG_STATE_HOME must be set}/.local/state}\"\n")
                     port)
                    (display "state=\"$state_root/drl\"\n" port)
                    (display "run_game() {\n" port)
                    (display "  \"$mkdir\" -p \"$state\"\n" port)
                    (display "  cd \"$state\"\n" port)
                    ;; Put package-owned arguments last so an ambient caller
                    ;; cannot redirect the ordinary launcher into the store.
                    (display
                     (string-append
                      "  exec \"$real\" \"$@\" -datapath \"$data\" "
                      "-config \"$config/config.lua\" -writepath \"$state/\" "
                      "-scorepath \"$state/\" -console -nosound -module drl\n")
                     port)
                    (display "}\n\n" port)
                    (display "if test \"${1-}\" = --guix-smoke; then\n" port)
                    (display
                     (string-append
                      "  test \"$#\" -eq 1 || { echo "
                      "'usage: drl [--guix-smoke]' >&2; exit 64; }\n")
                     port)
                    ;; Keep every mutable path in a fresh temporary tree.  A
                    ;; PTY is supplied by util-linux script because curses
                    ;; needs terminal semantics even in the isolated smoke.
                    (display
                     (string-append
                      "  smoke_tmp=\"${TMPDIR:-/tmp}\"\n"
                      "  case \"$smoke_tmp\" in /*) ;; *) "
                      "echo 'drl smoke: TMPDIR must be absolute' >&2; exit 1 ;; esac\n"
                      "  smoke_root=$(\"$mktemp\" -d "
                      "\"$smoke_tmp/drl-guix-smoke.XXXXXXXX\")\n")
                     port)
                    (display
                     (string-append
                      "  case \"$smoke_root\" in \"$smoke_tmp\"/drl-guix-smoke.*) ;; *) "
                      "echo 'drl smoke: invalid temporary root' >&2; exit 1 ;; esac\n")
                     port)
                    (display "  trap '\"$rm\" -rf \"$smoke_root\"' EXIT HUP INT TERM\n"
                             port)
                    (display
                     (string-append
                      "  \"$mkdir\" -p \"$smoke_root/home\" "
                      "\"$smoke_root/config\" \"$smoke_root/data\" "
                      "\"$smoke_root/cache\" \"$smoke_root/state\" "
                      "\"$smoke_root/runtime\" \"$smoke_root/tmp\" "
                      "\"$smoke_root/work\" \"$smoke_root/write\" "
                      "\"$smoke_root/score\"\n")
                     port)
                    (display "  chmod 700 \"$smoke_root/runtime\"\n" port)
                    (display "  export HOME=\"$smoke_root/home\"\n" port)
                    (display "  export XDG_CONFIG_HOME=\"$smoke_root/config\"\n" port)
                    (display "  export XDG_DATA_HOME=\"$smoke_root/data\"\n" port)
                    (display "  export XDG_CACHE_HOME=\"$smoke_root/cache\"\n" port)
                    (display "  export XDG_STATE_HOME=\"$smoke_root/state\"\n" port)
                    (display "  export XDG_RUNTIME_DIR=\"$smoke_root/runtime\"\n" port)
                    (display
                     (string-append
                      "  export TMPDIR=\"$smoke_root/tmp\" "
                      "TERM=xterm-256color LC_ALL=C\n")
                     port)
                    (display
                     (string-append
                      "  write=\"$smoke_root/write\"\n"
                      "  score=\"$smoke_root/score\"\n")
                     port)
                    (display "  first_log=\"$smoke_root/work/first.log\"\n" port)
                    (display "  second_log=\"$smoke_root/work/second.log\"\n" port)
                    (display "  capture=\"${GOOCASTLE_RUNTIME_RAW_CAPTURE-}\"\n" port)
                    (display "  run_session() {\n" port)
                    (display "    log=$1\n    mode=${2-truncate}\n" port)
                    (display
                     (string-append
                      "    command=\"$real -datapath $data "
                      "-config $config/config.lua -writepath $write/ "
                      "-scorepath $score/ -console -nosound -module drl\"\n")
                     port)
                    (display "    if test -n \"$capture\"; then\n" port)
                    (display "      if test \"$mode\" = append; then\n" port)
                    (display
                     (string-append
                      "        \"$script\" -qefc \"$command\" \"$log\" "
                      ">> \"$capture\"\n")
                     port)
                    (display
                     (string-append
                      "      else\n        \"$script\" -qefc \"$command\" "
                      "\"$log\" > \"$capture\"\n      fi\n")
                     port)
                    (display
                     (string-append
                      "    else\n      \"$script\" -qefc \"$command\" "
                      "\"$log\" >/dev/null\n    fi\n")
                     port)
                    (display "  }\n" port)
                    (display
                     (string-append
                      "  if ! { \"$sleep\" 1; printf '\\r'; "
                      "\"$sleep\" 1; printf '\\r'; "
                      "\"$sleep\" 1; printf '\\r'; "
                      "\"$sleep\" 1; printf '\\r'; "
                      "\"$sleep\" 1; printf '\\r'; "
                      "\"$sleep\" 1; printf '\\r'; "
                      "\"$sleep\" 1; printf '\\r'; "
                      "\"$sleep\" 1; printf 'Smoke'; printf '\\r'; "
                      "\"$sleep\" 2; printf '\\033[C'; "
                      "\"$sleep\" 1; printf '\\033'; "
                      "\"$sleep\" 1; printf '\\033[B\\033[B\\033[B"
                      "\\033[B\\033[B\\033[B'; "
                      "printf '\\r'; \"$sleep\" 3; } | "
                      "run_session \"$first_log\"; then\n")
                     port)
                    (display
                     (string-append
                      "    echo 'drl smoke: first game failed' >&2; "
                      "exit 1\n  fi\n")
                     port)
                    (display
                     (string-append
                      "  save=\"$write/user/drl/save\"\n"
                      "  test -s \"$save\"\n")
                     port)
                    (display "  first_text=$(\"$cat\" \"$first_log\")\n" port)
                    (display
                     (string-append
                      "  for marker in DRL HP: @; do case \"$first_text\" in "
                      "*\"$marker\"*) ;; *) echo \"drl smoke: missing "
                      "first-run marker $marker\" >&2; exit 1 ;; esac; done\n")
                     port)
                    (display
                     (string-append
                      "  if ! { \"$sleep\" 1; printf '\\r'; "
                      "\"$sleep\" 1; printf '\\r'; \"$sleep\" 3; "
                      "printf '\\033'; \"$sleep\" 1; "
                      "printf '\\033[B\\033[B\\033[B\\033[B\\033[B\\033[B'; "
                      "printf '\\r'; \"$sleep\" 3; } | "
                      "run_session \"$second_log\" append; then\n")
                     port)
                    (display
                     (string-append
                      "    echo 'drl smoke: restore game failed' >&2; "
                      "exit 1\n  fi\n")
                     port)
                    (display "  second_text=$(\"$cat\" \"$second_log\")\n" port)
                    (display
                     (string-append
                      "  for marker in 'Continue game' HP: @; do case "
                      "\"$second_text\" in *\"$marker\"*) ;; *) echo "
                      "\"drl smoke: missing restore marker $marker\" >&2; "
                      "exit 1 ;; esac; done\n")
                     port)
                    (display
                     (string-append
                      "  test ! -w \"$output\"\n"
                      "  printf '%s\\n' DRL_GOOCASTLE_RUNTIME_OK\n"
                      "  exit 0\nfi\n\n")
                     port)
                    (display "run_game \"$@\"\n" port)))
                (chmod launcher #o555))))
          (add-after 'install 'verify-license-notices
            (lambda _
              (let ((data (string-append #$output "/share/drl/data"))
                    (doc (string-append #$output "/share/doc/drl/")))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append doc file))
                     (error "missing installed DRL document" file)))
                 '("LICENSE" "FPCVALKYRIE-LICENSE" "THIRD-PARTY-NOTICES"))
                (invoke "grep" "-F" "GNU GENERAL PUBLIC LICENSE"
                        (string-append doc "LICENSE"))
                (invoke "grep" "-F" "MIT License"
                        (string-append doc "FPCVALKYRIE-LICENSE"))
                (unless (file-exists?
                         (string-append data "/core/main.lua"))
                  (error "missing DRL core data"))
                (unless (file-exists?
                         (string-append data "/drl/main.lua"))
                  (error "missing DRL module data"))
                 (for-each
                 (lambda (file)
                   (when (file-exists? (string-append #$output "/" file))
                     (error "forbidden non-console asset installed" file)))
                 '("ext" "share/drl/data/drl/graphics"
                   "share/drl/data/drl/fonts")))))
          ;; Keep the store output immutable after all generated files and
          ;; launcher shebangs have been installed.
          (add-after 'make-dynamic-linker-cache 'make-output-immutable
            (lambda _
              (for-each
               (lambda (file)
                 (chmod file
                        (cond ((file-is-directory? file) #o555)
                              ((access? file X_OK) #o555)
                              (else #o444))))
               (find-files #$output ".*" #:directories? #t)))))))
    (native-inputs
     (list `("fpc" ,fpc)
           `("fpcvalkyrie" ,%fpcvalkyrie-source)
           `("make" ,gnu-make)
           `("lua" ,lua-5.1)))
    ;; Lua is dynamically loaded by the console executable.  The launcher
    ;; supplies its library and terminfo paths without consulting host state.
    (inputs
     (list `("bash-minimal" ,bash-minimal)
           `("coreutils-minimal" ,coreutils-minimal)
           `("lua" ,lua-5.1)
           `("ncurses-with-tinfo" ,ncurses/tinfo)
           `("libx11" ,libx11)
           `("util-linux" ,util-linux)))
    (home-page "https://github.com/chaosforgeorg/drl")
    (synopsis "Console roguelike game")
    (description
     "DRL is a console roguelike game built from the rebranded DoomRL
source tree.  This package builds release 0.10.11 with Free Pascal, Lua 5.1,
and the pinned FPC Valkyrie library.  It installs the text-console core only;
graphics, fonts, audio, proprietary libraries, and foreign platform bundles
are excluded from the output.")
    (license (list license:gpl2 license:expat))))
