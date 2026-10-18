#!@bash@
# Port of upstream nix/package.nix; core builders/relocation/probes stay upstream.
set -eu
image_root=$1
final=$2
expected_identity='@out@'
stage=
work=
previous=

image_set_valid()
{
  local directory=$1 entry
  [[ -d $directory && ! -L $directory ]] || return 1
  for entry in identity active/autolith-active.core active/manifest.sexp \
               recovery/autolith-recovery.core recovery/manifest.sexp; do
    [[ -f $directory/$entry && ! -L $directory/$entry && -r $directory/$entry ]] || return 1
  done
  [[ -d $directory/active && ! -L $directory/active &&
     -d $directory/recovery && ! -L $directory/recovery &&
     $(cat "$directory/identity") == "$expected_identity" ]]
}

image_set_usable()
{
  local directory=$1
  image_set_valid "$directory" &&
    grep -Eq '^\(:SBCL-GENERATIONS-IMAGE-MANIFEST :VERSION 1([[:space:]]|$)' \
      "$directory/active/manifest.sexp" &&
    grep -Eq '^\(:RECOVERY-IMAGE :VERSION 2([[:space:]]|$)' \
      "$directory/recovery/manifest.sexp" &&
    "$AUTOLITH_SBCL" --noinform --core "$directory/recovery/autolith-recovery.core" \
      --end-runtime-options '@source@/' --probe >/dev/null 2>&1 &&
    "$AUTOLITH_SBCL" --noinform --core "$directory/active/autolith-active.core" \
      --end-runtime-options '@source@/' \
      --autolith-internal-active-image-probe >/dev/null 2>&1
}

cleanup()
{
  if [[ -n $stage && -d $stage ]]; then rm -rf -- "$stage"; fi
  if [[ -n $work && -d $work ]]; then rm -rf -- "$work"; fi
  if [[ -n $previous && ( -e $previous || -L $previous ) ]]; then
    if [[ ! -e $final && ! -L $final ]]; then
      mv -- "$previous" "$final"
    else
      rm -rf -- "$previous"
    fi
  fi
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

if image_set_usable "$final"; then exit 0; fi

stage=$(mktemp -d "$image_root/.stage.XXXXXXXX")
work=$(mktemp -d "$image_root/.work.XXXXXXXX")
mkdir -p "$stage/active" "$stage/recovery" \
  "$work/home" "$work/config" "$work/data" "$work/state"
export HOME="$work/home"
export XDG_CONFIG_HOME="$work/config"
export XDG_DATA_HOME="$work/data"
export XDG_STATE_HOME="$work/state"

# Seed the mutable mapping with the reproducible compiled store output.
# Subsequent compilation (live changes/generations) never writes into the store.
if [[ ! -e $AUTOLITH_ASDF_CACHE/.guix-seeded ]]; then
  # An interrupted cp -a may have already copied store read-only modes.  Make
  # the incomplete cache writable before retrying; publish the marker last.
  chmod -R u+w "$AUTOLITH_ASDF_CACHE"
  cp -a '@out@/lib/common-lisp/sbcl/autolith/.' "$AUTOLITH_ASDF_CACHE/"
  chmod -R u+w "$AUTOLITH_ASDF_CACHE"
  touch "$AUTOLITH_ASDF_CACHE/.guix-seeded"
fi
"$AUTOLITH_SBCL" --script '@source@/script/build-recovery.lisp' \
  "$stage/recovery/autolith-recovery.core"
"$AUTOLITH_SBCL" --script '@source@/script/build-active.lisp' \
  "$stage/active/autolith-active.core"
printf '%s\n' "$expected_identity" > "$stage/identity"
image_set_usable "$stage"
"$AUTOLITH_SBCL" --script '@source@/script/relocate-image-manifests.lisp' \
  "$stage" "$final"
chmod u+w "$stage/active/autolith-active.core" "$stage/active/manifest.sexp"

if [[ -e $final || -L $final ]]; then
  previous=$(mktemp -d "$image_root/.invalid.XXXXXXXX")
  rmdir "$previous"
  mv -- "$final" "$previous"
fi
mv -- "$stage" "$final"
stage=
if [[ -n $previous ]]; then rm -rf -- "$previous"; previous=; fi
image_set_usable "$final"
