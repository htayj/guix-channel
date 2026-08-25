#!/bin/sh
# Exercise the installed Org popup-posframe library without user state.
set -eu

guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if test "$#" -gt 1; then
    echo "usage: $0 [emacs-org-popup-posframe-output]" >&2
    exit 64
fi

if test "$#" -eq 1; then
    package_out=$1
else
    package_out=$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes \
        emacs-org-popup-posframe)
fi

emacs_out=
for candidate in $($guix_bin build emacs); do
    if test -x "$candidate/bin/emacs"; then
        emacs_out=$candidate
        break
    fi
done
test -n "$emacs_out"

posframe_out=$($guix_bin build emacs-posframe)
xvfb_out=$($guix_bin build xvfb-run)
test -x "$xvfb_out/bin/xvfb-run"
unshare_out=
for candidate in $($guix_bin build util-linux); do
    if test -x "$candidate/bin/unshare"; then
        unshare_out=$candidate/bin/unshare
        break
    fi
done
test -n "$unshare_out"

license="$package_out/share/doc/emacs-org-popup-posframe/LICENSE"
test -f "$license"
grep -Fx 'GNU GENERAL PUBLIC LICENSE' "$license" >/dev/null
grep -Fx 'Version 3, 29 June 2007' "$license" >/dev/null
# The upstream screenshots are documentation assets, not Emacs runtime files.
test -z "$(find "$package_out" -type f -iname '*.png' -print)"

package_lisp=$(find "$package_out" -type f \( -name org-popup-posframe.el \
    -o -name org-popup-posframe.elc \) -print | sed -n '1p')
posframe_lisp=$(find "$posframe_out" -type f \( -name posframe.el \
    -o -name posframe.elc \) -print | sed -n '1p')
test -n "$package_lisp"
test -n "$posframe_lisp"
package_lisp_dir=$(dirname "$package_lisp")
posframe_lisp_dir=$(dirname "$posframe_lisp")

temporary=$(mktemp -d -t emacs-org-popup-posframe-smoke.XXXXXX)
trap 'rm -rf -- "$temporary"' EXIT HUP INT TERM
mkdir "$temporary/home" "$temporary/config" "$temporary/data" "$temporary/cache" "$temporary/tmp"

before="$temporary/package-before"
after="$temporary/package-after"
find "$package_out" -type f -exec sha256sum {} \; | LC_ALL=C sort >"$before"

clean_emacs() {
    env -i \
        HOME="$temporary/home" \
        XDG_CONFIG_HOME="$temporary/config" \
        XDG_DATA_HOME="$temporary/data" \
        XDG_CACHE_HOME="$temporary/cache" \
        TMPDIR="$temporary/tmp" \
        LANG=C.UTF-8 \
        PATH="$PATH" \
        "$@"
}

if ! clean_emacs "$unshare_out" --user --map-root-user --net --fork /bin/true; then
    echo "emacs-org-popup-posframe-smoke: network namespaces are required" >&2
    exit 1
fi

offline_emacs() {
    clean_emacs "$unshare_out" --user --map-root-user --net --fork "$@"
}

# In batch mode posframe-workable-p is false; enabling the mode must still add
# its Org advice and disabling it must remove the advice without writing to the
# installed output or consulting user configuration/network state.
offline_emacs "$emacs_out/bin/emacs" --batch -Q \
    -L "$package_lisp_dir" -L "$posframe_lisp_dir" \
    --eval "(progn
      (require 'org)
      (require 'posframe)
      (require 'org-popup-posframe)
      (org-popup-posframe-mode 1)
      (unless (advice-member-p #'org-popup-posframe--org-capture-advice 'org-capture)
        (error \"org-capture advice was not installed\"))
      (unless (advice-member-p #'org-popup-posframe--org-insert-link-advice 'org-insert-link)
        (error \"org-insert-link advice was not installed\"))
      (org-popup-posframe-mode -1)
      (when (advice-member-p #'org-popup-posframe--org-capture-advice 'org-capture)
        (error \"org-capture advice was not removed\"))
      (when (advice-member-p #'org-popup-posframe--org-insert-link-advice 'org-insert-link)
        (error \"org-insert-link advice was not removed\")))"

# A separate graphical session proves that the installed display helper creates
# a live child frame.  Xvfb supplies an isolated display and no network path.
offline_emacs "$xvfb_out/bin/xvfb-run" -a "$emacs_out/bin/emacs" --batch -Q \
    -L "$package_lisp_dir" -L "$posframe_lisp_dir" \
    --eval "(progn
      (require 'org)
      (require 'posframe)
      (require 'org-popup-posframe)
      (let ((buffer (get-buffer-create \" *org-popup-posframe-smoke*\"))
            child-frame)
        (unwind-protect
            (progn
              (with-current-buffer buffer (org-mode))
              (org-popup-posframe--show-buffer buffer #'posframe-poshandler-frame-center)
              (with-current-buffer buffer
                (unless (and (boundp 'posframe--frame) (frame-live-p posframe--frame))
                  (error \"posframe child frame was not created\"))
                (setq child-frame posframe--frame)))
          (posframe-hide buffer)
          (posframe-delete buffer)
          (when (frame-live-p child-frame)
            (error \"posframe child frame was not deleted\"))
          (when (get-buffer buffer)
            (error \"posframe buffer was not deleted\")))))"

for state_dir in "$temporary/home" "$temporary/config" "$temporary/data" \
    "$temporary/cache" "$temporary/tmp"; do
    test -z "$(find "$state_dir" -mindepth 1 -print -quit)"
done

find "$package_out" -type f -exec sha256sum {} \; | LC_ALL=C sort >"$after"
cmp "$before" "$after"
test -z "$(find "$package_out" -type f -perm /222 -print)"
