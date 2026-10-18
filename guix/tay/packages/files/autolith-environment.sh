# Sourced by the Guix launcher and its transient build-time image validation.
export PATH='@runtime-path@'${PATH:+:$PATH}
export AUTOLITH_SBCL='@sbcl@'
export AUTOLITH_SBCL_SOURCE_ROOT='@sbcl-source@'
export AUTOLITH_NIX_SOURCE_ROOT='@source@/'
export AUTOLITH_GUIX_CONFIG_ROOT='@out@/etc/xdg/common-lisp/'
# Upstream's "nix" kind is its immutable-package protocol, also used by Guix.
export AUTOLITH_INSTALLATION_KIND=nix
export COLORLISP_NATIVE_LIBRARY='@colorlisp@/lib/libcolorlisp-tree-sitter.so'
export AUTOLITH_FFF_LIBRARY='@fff@/lib/libfff_c.so'
export CLASTED_AST_GREP='@ast-grep@'
export CL_EXEC_SANDBOX_PROCESS_GROUP_HELPER='@sandbox@/libexec/cl-exec-sandbox-process-group'
export CL_EXEC_SANDBOX_BWRAP='@bwrap@/bin/bwrap'
export CL_EXEC_SANDBOX_HELPER='@sandbox@/libexec/cl-exec-sandbox-helper'
export GIT_OPTIONAL_LOCKS=0
# Append scoped trust entries; never overwrite the user's Git configuration.
autolith_git_config_count=${GIT_CONFIG_COUNT:-0}
if [[ ! $autolith_git_config_count =~ ^[0-9]+$ ]]; then
  printf 'Invalid GIT_CONFIG_COUNT for Autolith.\n' >&2
  exit 1
fi
for autolith_git_safe in '@source@' '@source@/.git'; do
  export "GIT_CONFIG_KEY_${autolith_git_config_count}=safe.directory"
  export "GIT_CONFIG_VALUE_${autolith_git_config_count}=$autolith_git_safe"
  autolith_git_config_count=$((autolith_git_config_count + 1))
done
export GIT_CONFIG_COUNT=$autolith_git_config_count
unset autolith_git_config_count autolith_git_safe
