#!/bin/sh
# Exercise the installed game in a fresh XDG tree and a networkless PTY.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$channel_dir"

if test "$#" -gt 1; then
    echo "usage: $0 [xrogue-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    game_out=$1
else
    game_out=$($guix_bin build -L "$channel_dir/guix" --no-grafts --no-substitutes \
        xrogue)
fi

find_output ()
{
    program=$1
    package=$2
    for output in $($guix_bin build -L "$channel_dir/guix" --no-grafts \
                       --no-substitutes "$package"); do
        if test -x "$output/$program"; then
            printf '%s\n' "$output"
            return 0
        fi
    done
    echo "could not find $program in Guix package $package" >&2
    return 1
}

bash_out=$(find_output bin/bash bash)
coreutils_out=$(find_output bin/mktemp coreutils)
diffutils_out=$(find_output bin/cmp diffutils)
findutils_out=$(find_output bin/find findutils)
grep_out=$(find_output bin/grep grep)
guile_out=$(find_output bin/guile guile)
util_linux_out=$(find_output bin/script util-linux)

test -x "$game_out/bin/xrogue"
test -x "$game_out/libexec/xrogue"
for document in LICENSE.TXT README.TXT; do
    test -s "$game_out/share/doc/xrogue/$document"
done

# Check the complete license and notices that cover the installed program:
# the unmodified upstream files from the fixed source revision.
license=$game_out/share/doc/xrogue/LICENSE.TXT
readme=$game_out/share/doc/xrogue/README.TXT
test "$("$coreutils_out/bin/sha256sum" "$license" | \
    "$coreutils_out/bin/cut" -d ' ' -f 1)" = \
    34403e2867c9abfd01df009e980b690739db9ed67882fc21554caec8112ac106
test "$("$coreutils_out/bin/sha256sum" "$readme" | \
    "$coreutils_out/bin/cut" -d ' ' -f 1)" = \
    6cc58ff46c5470c97f749126d7698c19790cf2dd061da7bb683a52137c1e7c56
for notice in \
    'Copyright (C) 1991 Robert Pietkivitch' \
    'Copyright (C) 1984, 1985 Michael Morgan, Ken Dalka and AT&T' \
    'Copyright (C) 1980, 1981 Michael Toy, Ken Arnold and Glenn Wichman' \
    'Copyright (C) 2000 Nicholas J. Kisseberth' \
    'Copyright (C) 1994 David Burren' \
    'Products derived from this software may not be called "XRogue",' \
    'Products derived from this software may not be called "Advanced Rogue" or'
do
    "$grep_out/bin/grep" -F "$notice" "$license" >/dev/null
done
"$grep_out/bin/grep" -F 'See the file LICENSE.TXT' "$readme" >/dev/null

# The per-issue runtime-evidence contract is part of this package proof.
contract=.goocastle/runtime-evidence-contracts.json
test -s "$contract"
"$grep_out/bin/grep" -F '"issueNumber": 736' "$contract" >/dev/null
"$grep_out/bin/grep" -F '"packageName": "xrogue"' "$contract" >/dev/null
"$grep_out/bin/grep" -F '"artifactPath": ".goocastle/evidence/issue-736.png"' \
    "$contract" >/dev/null
"$grep_out/bin/grep" -F '"successMarker": "Top 20 Adventurers:"' \
    "$contract" >/dev/null

test -x "$util_linux_out/bin/unshare"
test -x "$util_linux_out/bin/script"
if ! "$util_linux_out/bin/unshare" --user --map-current-user --net --fork \
    true >/dev/null 2>&1; then
    echo 'xrogue smoke requires an unprivileged network namespace' >&2
    exit 77
fi

before=$($guix_bin hash -S nar "$game_out")
scratch=$("$coreutils_out/bin/mktemp" -d "${TMPDIR:-/tmp}/xrogue-smoke.XXXXXXXX")
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
"$coreutils_out/bin/mkdir" -p "$scratch/home" "$scratch/config" \
    "$scratch/data" "$scratch/cache" "$scratch/state" "$scratch/tmp" \
    "$scratch/work" "$scratch/fallback-home"

# Encode and decode XRogue's score file independently of the game, following
# rs_write_scorefile/rs_read_scorefile in state.c: a 32-bit little-endian
# entry count (NUMSCORE, 20) followed by 20 records, each holding a 32-bit
# score, an 80-byte name (NAMELEN), a 10-byte system (SYSLEN), a 9-byte login
# (LOGLEN), and five 16-bit fields: flags, level, class, monster, and quest.
# Every field is written by a separate encwrite() call in save.c, which XORs
# it with the encstr key from vers.c starting again at the key's first byte.
"$coreutils_out/bin/cat" >"$scratch/work/score.scm" <<'EOF'
(use-modules (ice-9 binary-ports) (rnrs bytevectors) (srfi srfi-1))

(define key
  #vu8(236 169 163 218 65 129 124 193 209 112 136 169 215 34 175 245 116
       225 37 51 185 94 96 126 131 122 123 225 125 59 12 225 153 146 101
       156 233 93 209))

(define (crypt bv)
  (let ((out (bytevector-copy bv)))
    (do ((i 0 (+ i 1)))
        ((= i (bytevector-length out)) out)
      (bytevector-u8-set! out i
                          (logxor (bytevector-u8-ref out i)
                                  (bytevector-u8-ref
                                   key (modulo i (bytevector-length key))))))))

(define (u32 n)
  (let ((bv (make-bytevector 4 0)))
    (bytevector-u32-set! bv 0 n (endianness little))
    bv))

(define (s16 n)
  (let ((bv (make-bytevector 2 0)))
    (bytevector-s16-set! bv 0 n (endianness little))
    bv))

(define (text s len)
  (let ((bv (make-bytevector len 0))
        (src (string->utf8 s)))
    (bytevector-copy! src 0 bv 0 (bytevector-length src))
    bv))

(define empty-record '(0 "" "" "" 0 0 0 0 0))

;; score name system login flags level class monster quest.  Flags 0 is
;; KILLED and 1 is CHICKEN (quit); class 3 is magician and 8 is monk;
;; monster 1 is the giant rat in mons_def.c.
(define seeded-records
  '((12345 "Seeded Mage" "fixture" "seed" 0 3 3 1 0)
    (150 "Seeded Monk" "fixture" "seed" 1 2 8 0 0)))

(define (encode-record record)
  (apply
   (lambda (score name system login flags level class monster quest)
     (append (list (u32 score) (text name 80) (text system 10) (text login 9))
             (map s16 (list flags level class monster quest))))
   record))

(define (write-scores file)
  (call-with-output-file file
    (lambda (port)
      (for-each (lambda (field) (put-bytevector port (crypt field)))
                (cons (u32 20)
                      (append-map encode-record
                                  (append seeded-records
                                          (make-list 18 empty-record))))))
    #:binary #t))

(define (c-string bv)
  (let loop ((end 0))
    (if (or (= end (bytevector-length bv))
            (zero? (bytevector-u8-ref bv end)))
        (let ((out (make-bytevector end)))
          (bytevector-copy! bv 0 out 0 end)
          (utf8->string out))
        (loop (+ end 1)))))

(define (read-scores file)
  (let* ((data (call-with-input-file file get-bytevector-all #:binary #t))
         (offset 0))
    (define (field len)
      (let ((bv (make-bytevector len)))
        (bytevector-copy! data offset bv 0 len)
        (set! offset (+ offset len))
        (crypt bv)))
    (define (read-u32) (bytevector-u32-ref (field 4) 0 (endianness little)))
    (define (read-s16) (bytevector-s16-ref (field 2) 0 (endianness little)))
    (unless (= (bytevector-length data) (+ 4 (* 20 113)))
      (error "unexpected score file size" (bytevector-length data)))
    (unless (= (read-u32) 20)
      (error "unexpected score entry count"))
    (map (lambda (i)
           (let* ((score (read-u32))
                  (name (c-string (field 80)))
                  (system (c-string (field 10)))
                  (login (c-string (field 9))))
             (cons* score name system login
                    (map (lambda (_) (read-s16)) (iota 5)))))
         (iota 20))))

(define (check-played-scores file)
  (let ((records (read-scores file)))
    (unless (equal? (first records) (first seeded-records))
      (error "seeded first entry changed" (first records)))
    (unless (equal? (second records) (second seeded-records))
      (error "seeded second entry changed" (second records)))
    ;; The new game quit on level 1 as a fighter (class 0) with 2000 gold,
    ;; which XRogue scores as 2000 / 100.
    (let ((new (third records)))
      (unless (and (= (list-ref new 0) 20)
                   (string=? (list-ref new 1) "Smoke Tester")
                   (equal? (take (drop new 4) 3) '(1 1 0)))
        (error "unexpected recorded game" new)))
    (unless (every (lambda (record) (zero? (car record))) (drop records 3))
      (error "unexpected additional score entries"))
    (display "XROGUE_SCORE_FILE_OK\n")))

(let ((args (cdr (command-line))))
  (cond ((equal? (car args) "write") (write-scores (cadr args)))
        ((equal? (car args) "check") (check-played-scores (cadr args)))
        (else (error "unknown mode" args))))
EOF

"$coreutils_out/bin/mkdir" -p "$scratch/work/seed"
"$guile_out/bin/guile" --no-auto-compile -s "$scratch/work/score.scm" \
    write "$scratch/work/seed/xrogue.scr"
seed_sum=$("$coreutils_out/bin/sha256sum" "$scratch/work/seed/xrogue.scr" | \
    "$coreutils_out/bin/cut" -d ' ' -f 1)

# Expected "xrogue -s" output for a missing score file and for the seeded one,
# following the printf formats in rip.c.
printf '\nTop 20 Adventurers:\nRank     Score\tName\n' \
    >"$scratch/work/empty.expected"
{
    "$coreutils_out/bin/cat" "$scratch/work/empty.expected"
    printf '  1      12345\tSeeded Mage (magician):\n'
    printf '\t\tkilled on level 3 by a giant rat\n'
    printf '  2        150\tSeeded Monk (monk):\n'
    printf '\t\tquit on level 2\n'
} >"$scratch/work/seeded.expected"
{
    "$coreutils_out/bin/cat" "$scratch/work/seeded.expected"
    printf '  3         20\tSmoke Tester (fighter):\n'
    printf '\t\tquit on level 1\n'
} >"$scratch/work/played.expected"

export XROGUE_GAME=$game_out/bin/xrogue
export XROGUE_SCRIPT=$util_linux_out/bin/script
export XROGUE_COREUTILS=$coreutils_out/bin
export XROGUE_HOME=$scratch/home
export XROGUE_CONFIG=$scratch/config
export XROGUE_DATA=$scratch/data
export XROGUE_CACHE=$scratch/cache
export XROGUE_STATE=$scratch/state
export XROGUE_TMP=$scratch/tmp
export XROGUE_WORK=$scratch/work
export XROGUE_FALLBACK_HOME=$scratch/fallback-home
export XROGUE_LONG=$scratch/long

# The new network namespace has no network interfaces; every invocation of
# the installed game runs there.  The user keeps its own, non-root uid, so
# file permissions apply to the game exactly as they do outside.
"$util_linux_out/bin/unshare" --user --map-current-user --net --fork \
    "$bash_out/bin/bash" -eu -c '
      export HOME="$XROGUE_HOME"
      export XDG_CONFIG_HOME="$XROGUE_CONFIG"
      export XDG_DATA_HOME="$XROGUE_DATA"
      export XDG_CACHE_HOME="$XROGUE_CACHE"
      export XDG_STATE_HOME="$XROGUE_STATE"
      export TMPDIR="$XROGUE_TMP"
      export TERM=xterm-256color
      export LC_ALL=C
      state="$XROGUE_DATA/xrogue"

      # The runtime-evidence invocation in a fresh tree: the launcher creates
      # the state directory and listing scores never creates a score file.
      "$XROGUE_GAME" -s >"$XROGUE_WORK/empty.out"
      test -d "$state"
      test ! -e "$state/xrogue.scr"

      # Listing a seeded, read-only score file parses it without writing it.
      # Upstream opened the score file for writing even for "-s" and, when
      # that failed, printed "Unable to open or create score file" instead
      # of the scores, so the output comparison below catches a regression.
      # That needs a user that cannot write the file after chmod.
      test "$("$XROGUE_COREUTILS/id" -u)" != 0
      "$XROGUE_COREUTILS/cp" "$XROGUE_WORK/seed/xrogue.scr" "$state/xrogue.scr"
      "$XROGUE_COREUTILS/chmod" 0444 "$state/xrogue.scr"
      if (: >>"$state/xrogue.scr") 2>/dev/null; then
        echo "the read-only score file is still writable" >&2
        exit 1
      fi
      "$XROGUE_GAME" -s >"$XROGUE_WORK/seeded.out"
      "$XROGUE_COREUTILS/sha256sum" "$state/xrogue.scr" \
        >"$XROGUE_WORK/seeded-after-listing.sum"
      "$XROGUE_COREUTILS/chmod" 0644 "$state/xrogue.scr"

      # Play a fighter with the default attributes: dismiss the quest
      # message, inspect the inventory, dismiss it, and save the game.
      export ROGUEOPTS="class=fighter,default,name=Smoke Tester"
      printf " i Sy" | "$XROGUE_COREUTILS/timeout" 120 "$XROGUE_SCRIPT" -qefc \
        "stty rows 24 cols 80; exec $XROGUE_GAME" /dev/null \
        >"$XROGUE_WORK/first.raw"
      test -s "$state/xrogue.sav"

      # Restore that save, rest for one turn, and quit, which records the
      # game in the score file.  A restored save is consumed by the game.
      printf " .Qyes\r\r\r" | "$XROGUE_COREUTILS/timeout" 120 \
        "$XROGUE_SCRIPT" -qefc \
        "stty rows 24 cols 80; exec $XROGUE_GAME -r" /dev/null \
        >"$XROGUE_WORK/restore.raw"
      test ! -e "$state/xrogue.sav"
      "$XROGUE_GAME" -s >"$XROGUE_WORK/played.out"

      # Without an absolute XDG_DATA_HOME the launcher falls back to HOME.
      HOME="$XROGUE_FALLBACK_HOME" XDG_DATA_HOME=relative "$XROGUE_GAME" -s \
        >"$XROGUE_WORK/fallback.out"
      test -d "$XROGUE_FALLBACK_HOME/.local/share/xrogue"

      # The save and score file names must fit XRogue'"'"'s 256-byte buffers:
      # a 244-byte state directory is the longest one accepted, and a longer
      # one is refused before anything is written instead of being truncated.
      long_data_home ()
      {
        path=$XROGUE_LONG
        while test "${#path}" -lt "$1"; do
          remaining=$(($1 - ${#path} - 1))
          if test "$remaining" -gt 100; then n=50; else n=$remaining; fi
          path=$path/$(printf "%0${n}d" 0)
        done
        printf "%s\n" "$path"
      }
      if test "${#XROGUE_LONG}" -gt 200; then
        echo "TMPDIR is too long for the ROGUEHOME length boundary test" >&2
        exit 1
      fi
      fits=$(long_data_home 237)
      test "${#fits}" = 237
      test "$(printf %s "$fits/xrogue" | "$XROGUE_COREUTILS/wc" -c)" = 244
      XDG_DATA_HOME=$fits "$XROGUE_GAME" -s >"$XROGUE_WORK/fits.out"
      printf " Sy" | XDG_DATA_HOME=$fits "$XROGUE_COREUTILS/timeout" 120 \
        "$XROGUE_SCRIPT" -qefc \
        "stty rows 24 cols 80; exec $XROGUE_GAME" /dev/null \
        >"$XROGUE_WORK/fits.raw"
      test -s "$fits/xrogue/xrogue.sav"
      test ! -e "$fits/xrogue/xrogue.scr"

      too_long=$(long_data_home 238)
      test "${#too_long}" = 238
      if XDG_DATA_HOME=$too_long "$XROGUE_GAME" -s >"$XROGUE_WORK/too-long.out" \
          2>"$XROGUE_WORK/too-long.err"; then
        echo "xrogue accepted a 245-byte ROGUEHOME" >&2
        exit 1
      fi
      test -d "$too_long/xrogue"
      test -z "$("$XROGUE_COREUTILS/ls" -A "$too_long/xrogue")"
      test ! -s "$XROGUE_WORK/too-long.out"
    '

cmp=$diffutils_out/bin/cmp
"$cmp" "$scratch/work/empty.expected" "$scratch/work/empty.out"
"$cmp" "$scratch/work/seeded.expected" "$scratch/work/seeded.out"
"$cmp" "$scratch/work/played.expected" "$scratch/work/played.out"
"$cmp" "$scratch/work/empty.expected" "$scratch/work/fallback.out"
"$cmp" "$scratch/work/empty.expected" "$scratch/work/fits.out"
printf '%s\n' 'xrogue: ROGUEHOME is too long (at most 244 bytes)' | \
    "$cmp" - "$scratch/work/too-long.err"
"$grep_out/bin/grep" -Fx 'Top 20 Adventurers:' "$scratch/work/empty.out" \
    >/dev/null
test "$("$coreutils_out/bin/cut" -d ' ' -f 1 \
    "$scratch/work/seeded-after-listing.sum")" = "$seed_sum"

# Decode the score file written by the game and check both preserved seeded
# entries and the newly recorded game.
"$guile_out/bin/guile" --no-auto-compile -s "$scratch/work/score.scm" \
    check "$scratch/data/xrogue/xrogue.scr" >"$scratch/work/score-check.out"
"$grep_out/bin/grep" -Fx 'XROGUE_SCORE_FILE_OK' "$scratch/work/score-check.out" \
    >/dev/null

tr -d '\r' <"$scratch/work/first.raw" >"$scratch/work/first.txt"
tr -d '\r' <"$scratch/work/restore.raw" >"$scratch/work/restore.txt"
for text in 'Hello Smoke Tester' 'You have been quested to retrieve the' \
    'a) A food ration.' 'Lvl:1' 'Save file ('; do
    "$grep_out/bin/grep" -F "$text" "$scratch/work/first.txt" >/dev/null
done
for text in 'Welcome back!' 'Really quit?' \
    'Contents of your pack when you quit:' 'Top 20 Adventurers:'; do
    "$grep_out/bin/grep" -F "$text" "$scratch/work/restore.txt" >/dev/null
done
if "$grep_out/bin/grep" -E 'out of date|Cannot restore|Unable to open' \
    "$scratch/work/first.txt" "$scratch/work/restore.txt" >/dev/null; then
    echo 'xrogue failed to save, restore, or record its score' >&2
    exit 1
fi

# All game state was confined to the launcher's XDG directory, apart from
# the explicit HOME fallback check; no other XDG location changed.
test "$("$findutils_out/bin/find" "$scratch/data" -mindepth 1 -print | \
    "$coreutils_out/bin/sort")" = \
    "$(printf '%s\n' "$scratch/data/xrogue" "$scratch/data/xrogue/xrogue.scr")"
test "$("$findutils_out/bin/find" "$scratch/fallback-home" -mindepth 1 -print | \
    "$coreutils_out/bin/sort")" = \
    "$(printf '%s\n' "$scratch/fallback-home/.local" \
        "$scratch/fallback-home/.local/share" \
        "$scratch/fallback-home/.local/share/xrogue")"
test -z "$("$findutils_out/bin/find" "$scratch/home" "$scratch/config" \
    "$scratch/cache" "$scratch/state" "$scratch/tmp" -mindepth 1 -print -quit)"

after=$($guix_bin hash -S nar "$game_out")
test "$before" = "$after"
printf '%s\n' 'XROGUE_RUNTIME_OK'
