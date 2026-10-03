;;; Guix-specific runtime policy for the pinned Hermes Agent source.
;;; SPDX-License-Identifier: GPL-3.0-or-later

(define-module (tay packages hermes-python-policy)
  #:use-module (guix gexp)
  #:export (hermes-guix-policy-phase))

;; Add after unpack, before copying or compiling the upstream source.  This
;; deliberately manages only the installed code, not writable user config:
;; HERMES_MANAGED also disables configuration writes and must not be set.
(define hermes-guix-policy-phase
  #~(lambda _
      (use-modules (ice-9 textual-ports) (srfi srfi-1) (srfi srfi-13))
      ;; Exact, single-occurrence replacements fail on a changed upstream
      ;; contract rather than silently shipping an unprotected store install.
      (define (patch file replacements)
        (let* ((source (call-with-input-file file get-string-all))
               (patched
                (fold
                 (lambda (replacement text)
                   (let* ((old (car replacement))
                          (new (cdr replacement))
                          (start (string-contains text old)))
                     (unless (and start
                                  (not (string-contains text old
                                                        (+ start (string-length old)))))
                       (error "Hermes policy patch no longer matches" file old))
                     (string-append
                      (substring text 0 start) new
                      (substring text (+ start (string-length old))))))
                 source replacements)))
          (call-with-output-file file
            (lambda (port) (display patched port)))))
      (patch
       "hermes_cli/config.py"
       '(("_NIX_STORE = Path(\"/nix/store\")"
          . "_NIX_STORE = Path(\"/nix/store\")\n_GUIX_STORE = Path(\"/gnu/store\")")
         ("frozenset({\"apt\", \"docker\", \"nix\", \"nixos\", \"home-manager\", \"git\", \"unknown\"})"
          . "frozenset({\"apt\", \"docker\", \"nix\", \"nixos\", \"home-manager\", \"guix\", \"git\", \"unknown\"})")
         ("Detect how Hermes was installed: apt/docker/nix/nixos/home-manager/git/unknown."
          . "Detect how Hermes was installed: apt/docker/nix/nixos/home-manager/guix/git/unknown.")
         ("    root = project_root if project_root is not None else get_project_root()\n    method = _install_method_stamp(root / \".install_method\")"
          . "    root = project_root if project_root is not None else get_project_root()\n    # The immutable Guix store wins over stale stamps in shared user homes\n    # and source trees; it does not imply declaratively managed user config.\n    try:\n        resolved = root.resolve()\n        if resolved == _GUIX_STORE or _GUIX_STORE in resolved.parents:\n            return \"guix\"\n    except OSError:\n        pass\n    method = _install_method_stamp(root / \".install_method\")")
         ("    \"apt\": \"pkg upgrade hermes-agent\","
          . "    \"guix\": (\"Update Hermes through the Guix channel that installed it \"\n             \"(e.g. guix pull && guix upgrade hermes-agent, or update your channels \"\n             \"and reconfigure Guix Home/System)\"),\n    \"apt\": \"pkg upgrade hermes-agent\",")))
      (patch
       "hermes_cli/update_contract.py"
       '(("# image-marker | image-marker-invalid | docker | nix | apt"
          . "# image-marker | image-marker-invalid | docker | nix | apt | guix")
         ("        if is_nix_install_method(method) or method == \"apt\":\n            return _refusal(method if method == \"apt\" else \"nix\", method)"
          . "        if is_nix_install_method(method) or method in {\"apt\", \"guix\"}:\n            return _refusal(method if method in {\"apt\", \"guix\"} else \"nix\", method)")))
      (patch
       "hermes_cli/web_routers/actions.py"
       '(("    \"nix\": \"nix_update_unsupported\","
          . "    \"nix\": \"nix_update_unsupported\", \"guix\": \"guix_update_unsupported\",")
         ("Returns install_method ('apt'|'git'|'docker'|'nix'|'nixos'|'unknown'),"
          . "Returns install_method ('apt'|'git'|'docker'|'nix'|'nixos'|'guix'|'unknown'),")
         ("    payload[\"behind\"] = behind\n    if behind is None:"
          . "    payload[\"behind\"] = behind\n    if install_method == \"guix\":\n        # Preserve read-only upstream notifications, but never offer an in-place\n        # apply or suggest retrying a package-managed update as a git checkout.\n        payload[\"message\"] = payload[\"update_command\"]\n        payload[\"update_available\"] = behind is not None and behind != 0\n        if payload[\"update_available\"]:\n            payload[\"commits\"] = await asyncio.to_thread(upstream_commits_behind)\n        return payload\n    if behind is None:")))
      (patch
       "hermes_cli/doctor_platform.py"
       '(("action = cmd if is_nix_install_method(method) else {"
          . "action = cmd if is_nix_install_method(method) or method == \"guix\" else {")))
      (patch
       "gateway/slash_commands.py"
       '(("        if not (Path(__file__).parent.parent.resolve() / '.git').exists():"
          . "        from hermes_cli.update_contract import evaluate_update_admission, record_refusal_receipt\n        refusal = evaluate_update_admission(Path(__file__).parent.parent.resolve())\n        if refusal is not None:\n            record_refusal_receipt(refusal)\n            return refusal.message\n        if not (Path(__file__).parent.parent.resolve() / '.git').exists():")))
      (patch
       "hermes_cli/cli_commands_mixin.py"
       '(("        # prompt_toolkit-native modal: renders above the composer, no raw input() races."
          . "        from hermes_cli.config import get_project_root\n        from hermes_cli.update_contract import evaluate_update_admission, record_refusal_receipt\n        refusal = evaluate_update_admission(get_project_root())\n        if refusal is not None:\n            record_refusal_receipt(refusal)\n            print(refusal.message)\n            return False\n        # prompt_toolkit-native modal: renders above the composer, no raw input() races.")))
      (patch
       "hermes_cli/tools_config_cua.py"
       '(("    venv_root = Path(sys.executable).parent.parent\n    install_flags = _post_setup_no_window_flags(streams_to_console=not capture_output)"
          . "    from hermes_cli.config import detect_install_method\n    if detect_install_method() == \"guix\":\n        from tools.lazy_deps import _allow_lazy_installs, _venv_pip_install\n        if not _allow_lazy_installs():\n            return subprocess.CompletedProcess(args, returncode=1, stdout=\"\",\n                stderr=\"Runtime installs are disabled; update Hermes dependencies through Guix\")\n        result = _venv_pip_install(tuple(args), timeout=timeout)\n        return subprocess.CompletedProcess(args, returncode=0 if result.success else 1,\n                                           stdout=result.stdout, stderr=result.stderr)\n    venv_root = Path(sys.executable).parent.parent\n    install_flags = _post_setup_no_window_flags(streams_to_console=not capture_output)")))
      (patch
       "hermes_cli/tools_config_post_setup.py"
       '(("def _post_setup_camofox() -> None:"
          . "def _camofox_package_root() -> Path:\n    from hermes_cli.config import detect_install_method\n    if detect_install_method() == \"guix\":\n        from hermes_constants import get_hermes_home\n        return get_hermes_home() / \"camofox\"\n    return PROJECT_ROOT\n\n\ndef _post_setup_camofox() -> None:")
         ("    camofox_dir = PROJECT_ROOT / \"node_modules\" / \"@askjo\" / \"camofox-browser\""
          . "    camofox_root = _camofox_package_root()\n    camofox_dir = camofox_root / \"node_modules\" / \"@askjo\" / \"camofox-browser\"")
         ("        result = _run_text([_npm_bin, \"install\", \"--silent\", \"--workspaces=false\"], timeout=None,\n                           cwd=str(PROJECT_ROOT), creationflags=_post_setup_no_window_flags())"
          . "        if camofox_root != PROJECT_ROOT:\n            camofox_root.mkdir(parents=True, exist_ok=True)\n            install_args = [_npm_bin, \"install\", \"--silent\", \"--prefix\", str(camofox_root),\n                            \"--no-save\", \"--workspaces=false\", \"@askjo/camofox-browser@^1.5.2\"]\n        else:\n            install_args = [_npm_bin, \"install\", \"--silent\", \"--workspaces=false\"]\n        result = _run_text(install_args, timeout=None, cwd=str(camofox_root),\n                           creationflags=_post_setup_no_window_flags())")
         ("            _print_warning(\"    npm install failed - run manually: npm install --workspaces=false\")"
          . "            import shlex\n            _print_warning(\"    npm install failed - run manually: \" + shlex.join(install_args))")
         ("        _info_lines(\"Start the Camofox server:\", \"  npx @askjo/camofox-browser\","
          . "        import shlex\n        start_command = (shlex.join([_npm_bin, \"exec\", \"--prefix\", str(camofox_root),\n                                     \"--offline\", \"--\", \"@askjo/camofox-browser\"])\n                         if camofox_root != PROJECT_ROOT and _npm_bin else \"npx @askjo/camofox-browser\")\n        _info_lines(\"Start the Camofox server:\", \"  \" + start_command,")
         ("    return (PROJECT_ROOT / \"node_modules\" / \"@askjo\" / \"camofox-browser\").exists()"
          . "    return (_camofox_package_root() / \"node_modules\" / \"@askjo\" / \"camofox-browser\").exists()")))
      ;; Leave the shared-metrics wire vocabulary unchanged.  Its existing
      ;; allowlist maps the new local method to "unknown"; the external ingest
      ;; server is not upgraded by this package's source patch.
      (patch
       "hermes_cli/_early_recovery.py"
       '(("def _run_ensurepip(root: Path) -> None:"
          . "def _is_guix_runtime(root: Path) -> bool:\n    # Recovery runs before third-party imports: use only pathlib, not config.\n    store = Path(\"/gnu/store\")\n    resolved = root.resolve()\n    if resolved == store or store in resolved.parents:\n        return True\n    try:\n        return (root / \".install_method\").read_text(encoding=\"utf-8\").strip().lower() == \"guix\"\n    except OSError:\n        return False\n\n\ndef _run_ensurepip(root: Path) -> None:")
         ("    \"\"\"Best-effort pip bootstrap — a killed install can leave the venv with no pip module at all.\"\"\"\n    try:"
          . "    \"\"\"Best-effort pip bootstrap — a killed install can leave the venv with no pip module at all.\"\"\"\n    if _is_guix_runtime(root):\n        return\n    try:")
         ("    externally_managed = _base_interpreter_is_externally_managed()"
          . "    if _is_guix_runtime(project_root):\n        print(\"Guix owns the Hermes runtime; repair or upgrade the package through Guix.\", file=sys.stderr)\n        return False\n    externally_managed = _base_interpreter_is_externally_managed()")
         ("        if not core_marker.exists() and not lazy_marker.exists():\n            return"
          . "        if not core_marker.exists() and not lazy_marker.exists():\n            return\n        if _is_guix_runtime(root):\n            print(\"Guix owns the Hermes runtime; repair or upgrade the package through Guix.\", file=sys.stderr)\n            return")))
      (patch
       "hermes_cli/_install_repair.py"
       '(("    prefix, env = _resolve_install_target(root)\n    group = \"termux-all\" if _is_termux_env(env) else \"all\""
          . "    if _er._is_guix_runtime(root):\n        raise RuntimeError(\"Guix owns the Hermes runtime; repair or upgrade the package through Guix.\")\n    prefix, env = _resolve_install_target(root)\n    group = \"termux-all\" if _is_termux_env(env) else \"all\"")))
      (patch
       "hermes_cli/main_install_repair.py"
       '(("    if not lazy_marker and not _update_marker_path().exists():\n        return"
          . "    if not lazy_marker and not _update_marker_path().exists():\n        return\n    from hermes_cli._early_recovery import _is_guix_runtime\n    if _is_guix_runtime(PROJECT_ROOT):\n        print(\"Guix owns the Hermes runtime; repair or upgrade the package through Guix.\", file=sys.stderr)\n        return")))
      (patch
       "tools/lazy_deps.py"
       '(("    want = _python_abi_tag()\n    stamp = target / _TARGET_STAMP_NAME"
          . "    # Reject even a symlink into the store before ABI cleanup can delete\n    # anything. User plugins belong in the writable durable target.\n    resolved = target.resolve()\n    store = Path(\"/gnu/store\")\n    if resolved == store or store in resolved.parents:\n        return \"runtime install target is inside the Guix store; set HERMES_LAZY_INSTALL_TARGET to a writable user directory\"\n    want = _python_abi_tag()\n    stamp = target / _TARGET_STAMP_NAME")
         ("    target = _lazy_install_target()\n    constraints: Optional[Path] = None"
          . "    target = _lazy_install_target()\n    from hermes_cli.config import detect_install_method\n    guix_install = detect_install_method() == \"guix\"\n    if guix_install and target is None:\n        return _InstallResult(False, \"\", \"Guix owns the Hermes runtime; update its package or set HERMES_LAZY_INSTALL_TARGET to a writable user directory for plugin dependencies\")\n    constraints: Optional[Path] = None")
         ("        except (subprocess.TimeoutExpired, FileNotFoundError):\n            try:\n                _run_installer([sys.executable, \"-m\", \"ensurepip\", \"--upgrade\", \"--default-pip\"], timeout=120, check=True)"
          . "        except (subprocess.TimeoutExpired, FileNotFoundError):\n            if guix_install:\n                return _InstallResult(False, \"\", \"pip is unavailable in the Guix Hermes runtime; update the Hermes package through Guix (ensurepip cannot modify the store)\")\n            try:\n                _run_installer([sys.executable, \"-m\", \"ensurepip\", \"--upgrade\", \"--default-pip\"], timeout=120, check=True)")))
      #t))
