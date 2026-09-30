;;; GNU Guix package for the xNetHack tty roguelike.

(define-module (tay packages xnethack)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix gexp)
  #:use-module (guix packages)
  #:use-module (guix utils)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages groff)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (tay packages auxiliary))

(define %xnethack-commit
  ;; Tag xnh10.0.
  "6eef39403f16f65e13f5d57242ee8d036307687a")

(define %xnethack-smoke-script
  (local-file (search-tay-package-file "xnethack-smoke.py")))

(define-public xnethack
  (package
    (name "xnethack")
    (version "10.0")
    (source
     (origin
       ;; Non-recursive: the Lua and PDCurses submodules are not used; Lua
       ;; comes from Guix and only the tty interface is built.
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/copperwater/xNetHack")
             (commit %xnethack-commit)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "0821an3xn2mbjr3k7ziw3ss4dvhc0nii2nzv6sissmng9qnbryi6"))))
    (build-system gnu-build-system)
    (arguments
     (list
      ;; makedefs, the Lua library copy, and dlb have ordering dependencies
      ;; which the upstream makefiles do not express completely.
      #:parallel-build? #f
      ;; There is no non-interactive upstream test target; the installed
      ;; launcher's --guix-smoke mode is exercised by tests/xnethack-smoke.sh.
      #:tests? #f
      #:make-flags
      #~(list (string-append "CC=" #$(cc-for-target))
              ;; The hints derive CFLAGS from CCFLAGS.
              "CCFLAGS=-O2 -g"
              (string-append "PREFIX=" #$output)
              ;; linux.500 turns this into -DHACKDIR and -DSYSCF_FILE.
              (string-append "HACKDIR=" #$output "/share/xnethack")
              ;; Link Guix's Lua 5.4.8 instead of the (unfetched) submodule.
              (string-append "LUATOP=" #$(file-append lua-5.4 "/lib"))
              (string-append "LUAHEADERS=" #$(file-append lua-5.4 "/include"))
              "LUAHPREFIX="
              "NOCRASHREPORT=1"
              ;; Avoids probing /sbin/ldconfig for libuuid.
              "NO_NHUUID=1"
              ;; There is no .git directory in the Guix source checkout.
              "GITINFO=0")
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (add-after 'unpack 'prepare-build
            (lambda _
              (substitute* "include/config.h"
                (("^/\\* #define REPRODUCIBLE_BUILD \\*/")
                 "#define REPRODUCIBLE_BUILD"))
              ;; Static data stays in the store; the launcher supplies the
              ;; writable per-user playground at run time.
              (substitute* "include/unixconf.h"
                (("^#define SERVER_ADMIN_MSG[[:space:]]+.*$")
                 "/* #define SERVER_ADMIN_MSG */\n")
                (("^/[*/][[:space:]]+#define VAR_PLAYGROUND.*$")
                 "#define VAR_PLAYGROUND nh_getenv(\"XNETHACK_VAR_PLAYGROUND\")\n"))
              (substitute* "sys/unix/hints/linux.500"
                (("/bin/gzip") #$(file-append gzip "/bin/gzip"))
                (("^GIT_HASH := .*") "GIT_HASH :=\n")
                (("^GIT_BRANCH := .*") "GIT_BRANCH :=\n")
                (("^GIT_PREFIX := .*") "GIT_PREFIX :=\n"))
              ;; The Guidebook is installed from the shipped plain-text copy.
              (substitute* "sys/unix/Makefile.top"
                (("recover Guidebook") "recover"))
              (call-with-output-file "dat/gitinfo.txt"
                (lambda (port)
                  (display (string-append "githash=" #$%xnethack-commit
                                          "\ngitbranch=xnh10.0\n")
                           port)))
              ;; dump_fmtstr() is declared NONNULLPTRS, so its own NULL
              ;; test is optimized away; with DUMPLOGFILE unset in sysconf
              ;; (below), dump_open_log() would crash at every game end.
              (substitute* "src/windows.c"
                (("fname = dump_fmtstr\\((DUMPLOG_FILE|DUMPHTML_FILE), buf, TRUE\\);"
                  all file)
                 (string-append "fname = " file " ? dump_fmtstr(" file
                                ", buf, TRUE) : (char *) 0;")))
              ;; Keep game-end dumps out of the shared /tmp and avoid host
              ;; tool paths in the store-resident system configuration.
              (substitute* "sys/unix/sysconf"
                (("^DUMPLOGFILE=") "#DUMPLOGFILE=")
                (("^DUMPHTMLFILE=") "#DUMPHTMLFILE=")
                (("^GDBPATH=") "#GDBPATH=")
                (("^GREPPATH=.*")
                 (string-append "GREPPATH=" #$(file-append grep "/bin/grep")
                                "\n"))
                (("^PANICTRACE_GDB=1") "PANICTRACE_GDB=0"))
              (substitute* "sys/unix/setup.sh"
                (("/bin/sh") #$(file-append bash-minimal "/bin/sh")))
              (invoke "sh" "sys/unix/setup.sh" "sys/unix/hints/linux.500")
              ;; makedefs uses this value when REPRODUCIBLE_BUILD is enabled.
              (setenv "SOURCE_DATE_EPOCH" "1779840932")
              (setenv "TZ" "UTC0")))
          (replace 'build
            (lambda* (#:key make-flags #:allow-other-keys)
              (apply invoke "make" "all" make-flags)))
          (delete 'install-license-files)
          (replace 'install
            (lambda _
              (let* ((out #$output)
                     (data (string-append out "/share/xnethack"))
                     (libexec (string-append out "/libexec"))
                     (bin (string-append out "/bin"))
                     (doc (string-append out "/share/doc/xnethack"))
                     (man (string-append out "/share/man/man6"))
                     (real (string-append libexec "/xnethack"))
                     (smoke-py (string-append libexec "/xnethack-smoke.py"))
                     (launcher (string-append bin "/xnethack"))
                     (shell #$(file-append bash-minimal "/bin/sh"))
                     (python #$(file-append python-minimal "/bin/python3"))
                     (chmod-bin #$(file-append coreutils-minimal "/bin/chmod"))
                     (mkdir #$(file-append coreutils-minimal "/bin/mkdir"))
                     (mktemp #$(file-append coreutils-minimal "/bin/mktemp"))
                     (rm #$(file-append coreutils-minimal "/bin/rm")))
                (for-each mkdir-p (list data libexec bin doc man))
                (copy-file "src/xnethack" real)
                (copy-file "util/recover"
                           (string-append libexec "/xnethack-recover"))
                (for-each (lambda (file) (install-file file data))
                          '("dat/nhdat" "dat/license" "dat/symbols"
                            "dat/NHdump.css" "sys/unix/sysconf"))
                (for-each (lambda (file) (install-file file doc))
                          '("LICENSE" "README" "README.md" "doc/Guidebook.txt"
                            "doc/xnh-changelog-10.0.md"))
                ;; Lua is linked statically; ship its MIT notice.
                (invoke "sh" "-c"
                        (string-append
                         ;; Only the trailing license comment, not the API.
                         "sed -n '/^\\* Copyright (C) 1994-2025 Lua\\.org/,"
                         "/^\\*\\*\\*\\*\\*/p' "
                         #$(file-append lua-5.4 "/include/lua.h")
                         " > " doc "/lua-COPYRIGHT"))
                (install-file "doc/xnethack.6" man)
                (copy-file "doc/recover.6"
                           (string-append man "/xnethack-recover.6"))
                (copy-file #$%xnethack-smoke-script smoke-py)
                (substitute* smoke-py
                  (("^#!.*") (string-append "#!" python "\n")))
                (chmod smoke-py #o555)
                (let ((port (open-file launcher "w")))
                  (format port "#!~a~%set -eu~%~%
real=~s~%
smoke_py=~s~%
python=~s~%
chmod=~s~%
mkdir=~s~%
mktemp=~s~%
rm=~s~%~%
prepare_state() {~%
  state=\"${XDG_STATE_HOME:-${HOME:?}/.local/state}/xnethack\"~%
  XNETHACK_VAR_PLAYGROUND=\"$state/\"~%
  # nh_getenv() rejects values over 128 bytes, and the game then uses NULL;~%
  # count bytes (not locale characters) in a C-locale subshell.~%
  playground_bytes=$(LC_ALL=C; echo \"${#XNETHACK_VAR_PLAYGROUND}\")~%
  if test \"$playground_bytes\" -gt 128; then~%
    echo 'xnethack: state directory path exceeds 128 bytes' >&2~%
    exit 1~%
  fi~%
  \"$mkdir\" -p \"$state/save\"~%
  for file in perm record logfile xlogfile livelog paniclog; do~%
    test -e \"$state/$file\" || : > \"$state/$file\"~%
  done~%
  unset HACKDIR NETHACKDIR~%
  export XNETHACK_VAR_PLAYGROUND~%
}~%~%
case \"${1-}\" in~%
  --guix-smoke)~%
    test \"$#\" -eq 1 || { echo 'usage: xnethack [--guix-smoke]' >&2; exit 64; }~%
    smoke=$(\"$mktemp\" -d \"${TMPDIR:-/tmp}/xnethack-guix-smoke.XXXXXXXX\")~%
    cleanup() { \"$rm\" -rf \"$smoke\"; }~%
    trap cleanup EXIT HUP INT TERM~%
    \"$mkdir\" \"$smoke/home\" \"$smoke/config\" \"$smoke/data\" \\
      \"$smoke/cache\" \"$smoke/state\" \"$smoke/runtime\" \"$smoke/tmp\"~%
    \"$chmod\" 700 \"$smoke/runtime\"~%
    export HOME=\"$smoke/home\" XDG_CONFIG_HOME=\"$smoke/config\"~%
    export XDG_DATA_HOME=\"$smoke/data\" XDG_CACHE_HOME=\"$smoke/cache\"~%
    export XDG_STATE_HOME=\"$smoke/state\" XDG_RUNTIME_DIR=\"$smoke/runtime\"~%
    export TMPDIR=\"$smoke/tmp\" TERM=xterm-256color LC_ALL=C LANG=C~%
    unset XNETHACKOPTIONS HACKOPTIONS NETHACKOPTIONS WIZKIT MAILREADER \\
      HACKPAGER NETHACKPAGER~%
    # A private, nonexistent mailbox avoids the passwd lookup for $MAIL.~%
    export MAIL=\"$smoke/tmp/no-mailbox\"~%
    prepare_state~%
    status=0~%
    \"$python\" \"$smoke_py\" \"$real\" \"$state\" || status=$?~%
    exit \"$status\"~%
    ;;~%
  *)~%
    prepare_state~%
    exec \"$real\" \"$@\"~%
    ;;~%
esac~%"
                          shell real smoke-py python chmod-bin mkdir mktemp rm)
                  (close-port port))
                (chmod launcher #o555))))
          (add-after 'install 'verify-license-notices
            (lambda _
              (let ((data (string-append #$output "/share/xnethack/"))
                    (doc (string-append #$output "/share/doc/xnethack/")))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append data file))
                     (error "missing installed xNetHack runtime file" file)))
                 '("nhdat" "license" "symbols" "sysconf"))
                (for-each
                 (lambda (file)
                   (unless (file-exists? (string-append doc file))
                     (error "missing installed xNetHack notice" file)))
                 '("LICENSE" "README.md" "Guidebook.txt"
                   "xnh-changelog-10.0.md" "lua-COPYRIGHT"))
                (when (file-exists? (string-append data "sounds"))
                  (error "unlicensed sound assets were installed"))
                (invoke "grep" "-F" "NETHACK GENERAL PUBLIC LICENSE"
                        (string-append data "license"))
                (invoke "grep" "-F" "Permission is hereby granted"
                        (string-append doc "lua-COPYRIGHT")))))
          ;; Guix makes completed store outputs immutable.  Run this after
          ;; documentation compression so generated manpages are finalized.
          (add-after 'compress-documentation 'make-output-immutable
            (lambda _
              (for-each
               (lambda (file)
                 (chmod file
                        (cond ((file-is-directory? file) #o555)
                              ((access? file X_OK) #o555)
                              (else #o444))))
               (find-files #$output ".*" #:directories? #t)))))))
    ;; The linux.500 hints probe nroff while parsing the makefiles.
    (native-inputs
     (list groff-minimal pkg-config))
    (inputs
     (list bash-minimal coreutils-minimal grep gzip lua-5.4 ncurses
           python-minimal))
    (home-page "https://github.com/copperwater/xNetHack")
    (synopsis "Variant of NetHack with gameplay and interface changes")
    (description
     "xNetHack is a variant of NetHack that aims to make the game more
challenging, varied, and interesting while keeping its classic feel.  This
package builds the terminal (tty) interface.  Static game data stays in the
store; saves, scores, and logs are kept in the per-user XDG state directory.")
    (license
     (list (license:fsdg-compatible "https://nethack.org/common/license.html")
           ;; Statically linked Lua 5.4.
           license:expat))))
