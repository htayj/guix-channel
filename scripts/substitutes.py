#!/usr/bin/env python3
"""Evaluate one authenticated channel snapshot and retain its successful outputs."""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import time

SCRIPTS = Path(__file__).resolve().parent
REPOSITORY = SCRIPTS.parent
CHANNELS = [
    dict(name="guix", url="https://git.guix.gnu.org/guix.git", branch="master",
         introduction="9edb3f66fd807b096b48283debdcddccfea34bad",
         signer="BBB0 2DDF 2CEA F6A8 0D1D E643 A2A0 6DF2 A33A 54FA"),
    dict(name="nonguix", url="https://gitlab.com/nonguix/nonguix", branch="master",
         introduction="897c1a470da759236cc11798f4e0a5f7d4d59fbc",
         signer="2A39 3FFF 68F4 EF7A 3D29 12AF 6F51 20A0 22FB B2D5"),
    dict(name="tay", url="https://192.168.7.121/tay/guix-channel.git", branch="master",
         introduction="5de4b5693fae9aa776d089d9818126bc253a69a9",
         signer="997E 2BA6 B523 4026 8A39 87E3 D94F 0A11 ACD7 8333"),
]
RESTRICTED = {"tern", "sentinelone"}
DISK_GUARD_PATHS = (Path("/gnu/store"),)
MINIMUM_FREE_BYTES = 5 * 1024 ** 3

class EvaluationInterrupted(RuntimeError):
    """Stop the complete evaluation rather than recording one failed target."""

class DiskReserveError(RuntimeError):
    """Abort the full evaluation before exhausting the builder filesystem."""


def require_disk_reserve():
    for path in DISK_GUARD_PATHS:
        free = shutil.disk_usage(path).free
        if free < MINIMUM_FREE_BYTES:
            raise DiskReserveError(
                f"disk reserve exhausted at {path}: {free} bytes free; minimum is 5 GiB")



def atomic_json(path, value):
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")
    os.replace(temporary, path)


def clean_environment():
    # The Git acquisition alone can access the automatic workflow token. Neither
    # channel evaluation nor package builders need it or local module overrides.
    return {key: value for key, value in os.environ.items()
            if not any(part in key.upper() for part in ("TOKEN", "SECRET", "PASSWORD"))
            and key not in {"GIT_ASKPASS", "SSH_ASKPASS", "GUIX_PACKAGE_PATH",
                            "GUILE_LOAD_PATH", "GUILE_LOAD_COMPILED_PATH"}}


def run(command, log, timeout, env=None):
    require_disk_reserve()
    with log.open("ab") as errors:
        process = subprocess.Popen(command, cwd=REPOSITORY, env=env,
                                   stdout=subprocess.PIPE, stderr=errors,
                                   start_new_session=True)
        try:
            deadline = time.monotonic() + timeout
            while True:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    raise subprocess.TimeoutExpired(command, timeout)
                try:
                    out, _ = process.communicate(timeout=min(10, remaining))
                    break
                except subprocess.TimeoutExpired:
                    require_disk_reserve()
        except BaseException:
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            try:
                process.communicate(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.communicate()
            raise
    if process.returncode:
        raise RuntimeError(f"{Path(command[0]).name} {command[1]} failed ({process.returncode}); see {log}")
    return out.decode("utf-8").strip()


def scheme_string(value):
    return json.dumps(str(value))


def lock_channels(state, report, log, env):
    channels = [dict(channel) for channel in CHANNELS]
    for channel in channels:
        response = run(["git", "-c", "credential.helper=", "ls-remote", "--exit-code",
                        channel["url"], "refs/heads/" + channel["branch"]], log, 180,
                       None if channel["name"] == "tay" else env)
        commit = response.split()[0]
        if not re.fullmatch(r"[0-9a-f]{40}", commit):
            raise RuntimeError("invalid remote channel revision")
        channel["commit"] = commit
    report["channels"] = channels
    # A fixed bare mirror carries only published content and the authentication
    # keyring, not dirty worktree modules or credentials in a URL/config.
    mirror = state / "tay.git"
    if not mirror.exists():
        run(["git", "init", "--bare", str(mirror)], log, 60)
    tay = channels[-1]
    run(["git", "-c", "credential.helper=", "-C", str(mirror), "fetch", "--force",
         tay["url"], "+refs/heads/master:refs/heads/master",
         "+refs/heads/keyring:refs/heads/keyring"], log, 300)
    actual = run(["git", "-C", str(mirror), "rev-parse", "refs/heads/master"], log, 30)
    checkout = run(["git", "rev-parse", "HEAD"], log, 30)
    if actual != tay["commit"] or checkout != actual:
        raise RuntimeError("published master changed during checkout/evaluation; dispatch a fresh run")
    # Reject accidental manual invocation from a dirty checkout. The pull itself
    # uses only the pinned, authenticated mirror, never -L ./guix.
    if run(["git", "status", "--porcelain", "--untracked-files=normal"], log, 30):
        raise RuntimeError("automation checkout must be clean and published")
    expressions = []
    for channel in channels:
        url = mirror.as_uri() if channel["name"] == "tay" else channel["url"]
        expressions.append(
            "(channel (name '%s) (url %s) (branch %s) (commit %s) "
            "(introduction (make-channel-introduction %s (openpgp-fingerprint %s))))"
            % (channel["name"], scheme_string(url), scheme_string(channel["branch"]),
               scheme_string(channel["commit"]), scheme_string(channel["introduction"]),
               scheme_string(channel["signer"])))
    locked = log.parent / "channels.scm"
    locked.write_text("(use-modules (guix channels))\n(list\n" + "\n".join(expressions) + ")\n")
    bootstrap = shutil.which("guix", path=env.get("PATH"))
    if not bootstrap:
        raise RuntimeError("authenticated bootstrap Guix executable is missing")
    profile = state / "profile"
    run([bootstrap, "pull", "--profile=" + str(profile), "--channels=" + str(locked),
         "--cores=2", "--max-jobs=1", "--no-offload"], log, 7200, env)
    guix = str(profile / "bin/guix")
    described = json.loads(run([guix, "describe", "--format=json"], log, 60, env))
    if {item["name"]: item["commit"] for item in described} != {
            item["name"]: item["commit"] for item in channels}:
        raise RuntimeError("resulting Guix profile does not match every locked revision")
    # Only this automation's private profile generations; no user/global GC.
    run([guix, "pull", "--profile=" + str(profile), "--delete-generations"], log, 120, env)
    return guix


def discover(guix, log, env):
    text = run([guix, "repl", str(SCRIPTS / "substitute-targets.scm")], log, 600, env)
    targets = []
    for line in text.splitlines():
        module, binding, name, version, outputs, systems, location = line.split("\t")
        targets.append(dict(module=module, binding=binding, name=name, version=version,
                            outputs=outputs.split(","), systems=systems.split(","),
                            location=location))
    if not targets:
        raise RuntimeError("empty channel package inventory")
    return targets


def target_key(target):
    identity = target["module"] + ":" + target["binding"]
    return re.sub(r"[^a-zA-Z0-9_.-]", "-", identity) + "-" + hashlib.sha256(identity.encode()).hexdigest()[:12]


def build_options(target, system, seconds):
    return ["--system=" + system, "--cores=2", "--max-jobs=1", "--no-offload",
            "--timeout=" + str(seconds), "--max-silent-time=1800",
            *(["--no-grafts"] if target["name"] == "fontra" else [])]


def derivation(guix, target, system, log, seconds, env):
    module = "(list %s)" % " ".join(
        "(string->symbol %s)" % scheme_string(part) for part in target["module"].split())
    expression = "(module-ref (resolve-interface %s) (string->symbol %s))" % (
        module, scheme_string(target["binding"]))
    drv = run([guix, "build", "--derivations", "--expression=" + expression,
               *build_options(target, system, seconds)], log, 300, env)
    if not re.fullmatch(r"/gnu/store/[^/\s]+\.drv", drv):
        raise RuntimeError("expected exactly one derivation")
    inspection = dict(env, SUBSTITUTE_DERIVATION=drv)
    rows = run([guix, "repl", str(SCRIPTS / "substitute-derivation.scm")], log, 60, inspection)
    outputs = dict(row.split("\t") for row in rows.splitlines())
    if set(outputs) != set(target["outputs"]):
        raise RuntimeError("derivation outputs differ from discovered package outputs")
    return drv, outputs


def register_root(guix, path, output, log, env):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".new")
    temporary.unlink(missing_ok=True)
    temporary.symlink_to(output)
    # Register the final stable name; replacing its symlink does not invalidate
    # the daemon's indirect-root registration.
    if not path.is_symlink():
        path.symlink_to(output)
    run([guix, "repl", str(SCRIPTS / "substitute-derivation.scm")], log, 60,
        dict(env, SUBSTITUTE_REGISTER_ROOT=str(path)))
    os.replace(temporary, path)


def build_target(guix, target, system, outputs, drv, state, log, seconds, env, smoke):
    staging = log.parent / ("build-root-" + target_key(target) + "-" + system)
    try:
        run([guix, "build", drv, "--root=" + str(staging), *build_options(target, system, seconds),
             *(["--no-substitutes"] if smoke else [])], log, seconds + 120, env)
        for output, store_path in outputs.items():
            if not Path(store_path).exists():
                raise RuntimeError("successful build omitted output " + output)
            directory = state / "roots" / target_key(target) / system / output
            latest = directory / "latest"
            if latest.is_symlink() and os.readlink(latest) != store_path:
                register_root(guix, directory / "previous", os.readlink(latest), log, env)
            register_root(guix, latest, store_path, log, env)
    finally:
        # Remove only the temporary roots created by this invocation. Never
        # remove store objects or roots owned by another user/service.
        for root in staging.parent.glob(staging.name + "*"):
            if root.is_symlink():
                root.unlink()


def evaluate(args, state, report, directory, env):
    log = directory / "evaluation.log"
    guix = lock_channels(state, report, log, env)
    inventory = discover(guix, log, env)
    if not any(target["name"] == "calcrogue" for target in inventory):
        raise RuntimeError("inventory omitted the required i686 calcrogue target")
    report["inventory_count"] = len(inventory)
    atomic_json(directory / "inventory.json", inventory)
    smoke_done = False
    for target in inventory:
        name = target["name"]
        if name in RESTRICTED or target["module"] in {"tay packages tern", "tay packages sentinelone"}:
            report["skipped"].append(dict(target, reason="excluded: operator-supplied restricted artifact"))
            continue
        systems = ["x86_64-linux", "i686-linux"] if name == "calcrogue" else ["x86_64-linux"]
        for system in systems:
            item = dict(target, system=system)
            if system not in target["systems"]:
                report["skipped"].append(dict(item, reason="unsupported system"))
                continue
            if args.mode == "smoke" and not (name.endswith("-source") or name.startswith("font-")):
                continue
            target_log = directory / (target_key(target) + "-" + system + ".log")
            try:
                drv, outputs = derivation(guix, target, system, target_log, args.target_timeout, env)
                if args.mode == "smoke" and all(Path(path).exists() for path in outputs.values()):
                    continue
                before = {output: Path(path).exists() for output, path in outputs.items()}
                build_target(guix, target, system, outputs, drv, state, target_log,
                             args.target_timeout, env, args.mode == "smoke")
                report["succeeded"].append(dict(item, derivation=drv, outputs=outputs,
                                                existed_before=before))
                smoke_done = args.mode == "smoke"
            except (EvaluationInterrupted, DiskReserveError):
                raise
            except (RuntimeError, OSError, ValueError, subprocess.TimeoutExpired) as error:
                report["failed"].append(dict(item, error=str(error), log=str(target_log)))
            atomic_json(state / "status" / "running.json", report)
            if smoke_done:
                return
    if args.mode == "smoke" and not smoke_done:
        raise RuntimeError("no missing channel source/font output was successfully built; cache hits do not satisfy smoke")


def interrupted(number, frame):
    raise EvaluationInterrupted("evaluation interrupted by signal " + str(number))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=("all", "smoke"), default="all")
    parser.add_argument("--state", type=Path, default=Path("/home/guixbot/substitutes"))
    parser.add_argument("--target-timeout", type=int, default=7200)
    args = parser.parse_args()
    if not 60 <= args.target_timeout <= 7200:
        parser.error("target timeout must be between 60 and 7200 seconds")
    state = args.state.resolve()
    global DISK_GUARD_PATHS
    DISK_GUARD_PATHS = (Path("/gnu/store"), state)
    (state / "status").mkdir(parents=True, exist_ok=True)
    with (state / "evaluation.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print("another evaluation holds the single-flight lock", file=sys.stderr)
            return 1
        signal.signal(signal.SIGTERM, interrupted)
        signal.signal(signal.SIGINT, interrupted)
        started = time.time()
        directory = state / "status" / "runs" / (str(time.time_ns()) + "-" + args.mode)
        directory.mkdir(parents=True)
        report = dict(schema=1, mode=args.mode, started_at=started, completed_at=None,
                      success=False, channels=[], succeeded=[], skipped=[], failed=[])
        try:
            evaluate(args, state, report, directory, clean_environment())
        except (RuntimeError, OSError, ValueError, subprocess.TimeoutExpired) as error:
            report["failed"].append(dict(stage="evaluation", error=str(error)))
        finally:
            report["completed_at"] = time.time()
            report["success"] = not report["failed"] and bool(report["succeeded"])
            atomic_json(directory / "report.json", report)
            atomic_json(state / "status" / ("latest.json" if args.mode == "all" else "smoke.json"), report)
            (state / "status" / "running.json").unlink(missing_ok=True)
            # Bound this service's reports/logs, not the store or anyone's roots.
            for old in sorted(directory.parent.iterdir(), key=lambda path: path.name, reverse=True)[20:]:
                if old.is_dir() and not old.is_symlink():
                    shutil.rmtree(old)
        print(json.dumps({key: report[key] for key in ("mode", "success", "completed_at")}))
        print("targets: %d successful, %d failed, %d excluded/unsupported" %
              (len(report["succeeded"]), len(report["failed"]), len(report["skipped"])))
        return 0 if report["success"] else 1


if __name__ == "__main__":
    sys.exit(main())
