#!@bash@
set -eu
source '@out@/libexec/autolith-environment.sh'
source '@source@/script/launcher-cli.sh'
autolith_launcher_parse nix "$@"
# Uninstall is handled by the upstream launcher before Lisp or materialization.
if [[ $uninstall_requested == true ]]; then
  exec '@bash@' '@source@/bin/autolith' "$@"
fi
home=${HOME:-/home/user}
state_home=$(autolith_xdg_directory "${XDG_STATE_HOME:-}" "$home/.local/state")
# Each Guix derivation has its own mutable images and ASDF cache; conversations
# and mutation history continue to use the ordinary upstream XDG locations.
identity_name='@identity@'
guix_root="$state_home/autolith/guix"
image_root="$guix_root/images"
image_directory="$image_root/$identity_name"
export AUTOLITH_ASDF_CACHE="$guix_root/asdf-cache/$identity_name"
mkdir -p "$image_root" "$AUTOLITH_ASDF_CACHE"
image_output_fd=1
if [[ $acp_requested == true ]]; then image_output_fd=2; fi
'@flock@' "$image_root/.materialize.lock" \
  '@bash@' '@out@/libexec/autolith-materialize' \
  "$image_root" "$image_directory" >&"$image_output_fd"
export AUTOLITH_ACTIVE_CORE="$image_directory/active/autolith-active.core"
export AUTOLITH_RECOVERY_CORE="$image_directory/recovery/autolith-recovery.core"
exec '@bash@' '@source@/bin/autolith' "$@"
