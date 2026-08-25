#!/usr/bin/env node

import { execFile } from "node:child_process";
import { randomUUID } from "node:crypto";
import { access, constants, lstat, link, mkdir, open, realpath, unlink } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, join, resolve } from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);
const HOOK_NAME = "pre-commit";
const BACKUP_NAME = "pre-commit.goocastle-original";
const MARKER = "# goocastle-secret-hook:v1";
const MAX_HOOK_BYTES = 256 * 1024;
const TEMPORARY_HOOK_PREFIX = ".pre-commit.goocastle-";

// A pathname is not a stable capability: a hooks directory can be renamed and
// replaced after it has passed validation.  Linux exposes an opened directory
// through /proc/self/fd, so child lookups below remain rooted at the verified
// directory even when its old pathname is moved out from underneath us.
const requireLinuxAnchors = () => {
  if (process.platform !== "linux") {
    throw new Error("Goocastle secret-hook install/remove requires Linux directory-handle safety; use Linux to modify hooks, or manage the hook manually on this platform");
  }
};

let faultInjector;
/** Test-only deterministic hook for exercising every mutation boundary. */
const setSecretHookFaultInjectorForTesting = (injector) => { faultInjector = injector; };
const atMutationBoundary = async (boundary) => { await faultInjector?.(boundary); };

const sameFile = (left, right) => left.dev === right.dev && left.ino === right.ino;
const sameSnapshot = (left, right) => sameFile(left, right) &&
  left.size === right.size && left.mode === right.mode &&
  left.mtimeMs === right.mtimeMs && left.ctimeMs === right.ctimeMs;
const samePublishedSnapshot = (left, right) => sameFile(left, right) &&
  left.size === right.size && left.mode === right.mode && left.mtimeMs === right.mtimeMs;

const readBoundedHook = async (handle, displayPath, label) => {
  const buffer = Buffer.alloc(MAX_HOOK_BYTES + 1);
  let offset = 0;
  while (offset < buffer.byteLength) {
    const { bytesRead } = await handle.read(buffer, offset, buffer.byteLength - offset, offset);
    if (bytesRead === 0) break;
    offset += bytesRead;
  }
  if (offset > MAX_HOOK_BYTES) throw new Error(`${label} is too large to inspect safely: ${displayPath}`);
  return buffer.subarray(0, offset).toString("utf8");
};

const lstatIfPresent = async (path) => {
  try {
    return await lstat(path);
  } catch (error) {
    if (error?.code === "ENOENT") return undefined;
    throw error;
  }
};

const withoutGitRouting = (environment) => {
  const isolated = { ...environment };
  delete isolated.GIT_COMMON_DIR;
  delete isolated.GIT_DIR;
  delete isolated.GIT_WORK_TREE;
  return isolated;
};
const stripTrailingLineEnding = (value) => value.endsWith("\r\n") ? value.slice(0, -2) : value.endsWith("\n") ? value.slice(0, -1) : value;

const validateDirectory = async (path, label) => {
  const absolute = resolve(path);
  const info = await lstat(absolute).catch(() => undefined);
  if (!info?.isDirectory() || info.isSymbolicLink() || await realpath(absolute).catch(() => undefined) !== absolute) {
    throw new Error(`${label} must be a real directory: ${absolute}`);
  }
  return absolute;
};

const validateRegularFile = async (path, label) => {
  const absolute = resolve(path);
  const info = await lstat(absolute).catch(() => undefined);
  if (!info?.isFile() || info.isSymbolicLink() || await realpath(absolute).catch(() => undefined) !== absolute) {
    throw new Error(`${label} must be a real file: ${absolute}`);
  }
  return absolute;
};

const changedDirectory = (directory, label) => new Error(
  `${label} changed during the operation and was left unchanged: ${directory.path}; inspect that directory and retry`,
);

const anchorDirectory = async (path, label) => {
  requireLinuxAnchors();
  const absolute = await validateDirectory(path, label);
  const initial = await lstat(absolute);
  let handle;
  try {
    handle = await open(absolute, constants.O_RDONLY | constants.O_DIRECTORY | constants.O_NOFOLLOW);
    const opened = await handle.stat();
    const current = await lstat(absolute);
    if (!sameFile(initial, opened) || !sameFile(current, opened)) throw changedDirectory({ path: absolute }, label);
  } catch (error) {
    await handle?.close().catch(() => undefined);
    if (error?.code === "ELOOP" || error?.code === "ENOTDIR") {
      throw new Error(`${label} must be a real directory: ${absolute}`, { cause: error });
    }
    throw error;
  }
  const identity = await handle.stat();
  return {
    path: absolute,
    child: (name) => `/proc/self/fd/${handle.fd}/${name}`,
    async verify(operation) {
      const current = await lstat(absolute).catch(() => undefined);
      const opened = await handle.stat().catch(() => undefined);
      if (!current?.isDirectory() || current.isSymbolicLink() || !opened || !sameFile(current, identity) || !sameFile(opened, identity)) {
        throw changedDirectory({ path: absolute }, `${label} before ${operation}`);
      }
    },
    close: async () => { await handle.close(); },
  };
};

const git = async (cwd, args) => {
  try {
    const result = await execFileAsync("git", ["-C", cwd, ...args], {
      encoding: "utf8",
      env: withoutGitRouting(process.env),
      maxBuffer: 1024 * 1024,
    });
    return stripTrailingLineEnding(result.stdout);
  } catch (error) {
    throw new Error(
      `Could not inspect the Git repository at ${cwd}; run the hook command from a checkout with Git metadata`,
      { cause: error },
    );
  }
};

const resolveRepository = async (cwd, createHooksDirectory = false) => {
  const workingDirectory = await validateDirectory(cwd, "Secret hook directory");
  const root = await validateDirectory(await git(workingDirectory, ["rev-parse", "--show-toplevel"]), "Git repository root");
  const commonDirectory = await validateDirectory(await git(root, ["rev-parse", "--path-format=absolute", "--git-common-dir"]), "Git common directory");
  const configuredHooksPath = await git(root, ["config", "--path", "--get", "core.hooksPath"]).catch(() => undefined);
  if (configuredHooksPath === "") {
    throw new Error("Configured Git hooks path must not be empty; unset core.hooksPath and retry");
  }
  const hooksPath = configuredHooksPath === undefined
    ? resolve(root, await git(root, ["rev-parse", "--path-format=absolute", "--git-path", "hooks"]))
    : resolve(root, configuredHooksPath);
  const hookDirectory = createHooksDirectory
    ? await ensureHooksDirectory(hooksPath)
    : await inspectHooksDirectory(hooksPath);
  return { root, commonDirectory, hookDirectory };
};

const ensureHooksDirectory = async (path) => {
  const absolute = resolve(path);
  const existing = await lstatIfPresent(absolute);
  if (existing?.isSymbolicLink() || (existing && !existing.isDirectory())) {
    throw new Error(`Configured Git hooks path must be a real directory: ${absolute}; restore core.hooksPath and retry`);
  }
  if (!existing) {
    const parent = dirname(absolute);
    if (parent === absolute) throw new Error(`Configured Git hooks path must be a real directory: ${absolute}`);
    await ensureHooksDirectory(parent);
    const parentAnchor = await anchorDirectory(parent, "Configured Git hooks parent directory");
    try {
      await atMutationBoundary("create-hooks-directory");
      await parentAnchor.verify("creating the hooks directory");
      await mkdir(parentAnchor.child(absolute.slice(parent.length + 1)), { mode: 0o755 });
      await parentAnchor.verify("creating the hooks directory");
    } catch (error) {
      if (error?.code !== "EEXIST") throw error;
    } finally {
      await parentAnchor.close();
    }
  }
  return await validateDirectory(absolute, "Configured Git hooks directory");
};

const inspectHooksDirectory = async (path) => {
  const absolute = resolve(path);
  const existing = await lstatIfPresent(absolute);
  if (!existing) return absolute;
  return await validateDirectory(absolute, "Configured Git hooks directory");
};

const resolveLayout = async (root) => {
  const candidates = [
    [".goocastle", "generated"],
    [".guix", "repository"],
  ];
  for (const [directory, kind] of candidates) {
    const channels = join(root, directory, "channels.scm");
    const manifest = join(root, directory, "manifest.scm");
    try {
      await validateRegularFile(channels, `Pinned Guix channels file in ${directory}`);
      await validateRegularFile(manifest, `Pinned Guix manifest in ${directory}`);
      const config = join(root, ".gitleaks.toml");
      const configInfo = await lstat(config).catch(() => undefined);
      if (configInfo) await validateRegularFile(config, "Gitleaks configuration");
      return { channels, manifest, kind };
    } catch {
      // Try the other supported layout before reporting the actionable error.
    }
  }
  throw new Error(
    `No pinned Guix secret-scan environment was found in ${root}; run goocastle init or restore .guix/channels.scm and .guix/manifest.scm before installing the hook`,
  );
};

const shellQuote = (value) => `'${value.replaceAll("'", `'"'"'`)}'`;

const renderHook = () => `#!/bin/sh
${MARKER}
set -eu

hook_path=$0
case "$hook_path" in
  /*) ;;
  *) hook_path="$PWD/$hook_path" ;;
esac
hook_directory=$(CDPATH= cd -- "$(dirname -- "$hook_path")" && pwd -P)
original_hook="$hook_directory/${BACKUP_NAME}"
if test -L "$original_hook"; then
  echo "Goocastle preserved pre-commit hook must not be a symlink: $original_hook" >&2
  exit 1
fi
if test -e "$original_hook"; then
  if test ! -f "$original_hook" || test ! -x "$original_hook"; then
    echo "Goocastle preserved pre-commit hook is not executable: $original_hook" >&2
    exit 1
  fi
  "$original_hook" "$@"
fi

unset GIT_COMMON_DIR GIT_DIR GIT_WORK_TREE
repository=$(git rev-parse --show-toplevel) || {
  echo "Goocastle secret hook could not find the Git repository root" >&2
  exit 1
}
if test -f "$repository/.goocastle/channels.scm" && test ! -L "$repository/.goocastle" && test ! -L "$repository/.goocastle/channels.scm" && test -f "$repository/.goocastle/manifest.scm" && test ! -L "$repository/.goocastle/manifest.scm"; then
  channels="$repository/.goocastle/channels.scm"
  manifest="$repository/.goocastle/manifest.scm"
elif test -f "$repository/.guix/channels.scm" && test ! -L "$repository/.guix" && test ! -L "$repository/.guix/channels.scm" && test -f "$repository/.guix/manifest.scm" && test ! -L "$repository/.guix/manifest.scm"; then
  channels="$repository/.guix/channels.scm"
  manifest="$repository/.guix/manifest.scm"
else
  echo "Goocastle secret hook cannot find a pinned Guix environment; restore .guix or .goocastle channels.scm and manifest.scm" >&2
  exit 1
fi
if ! command -v guix >/dev/null 2>&1; then
  echo "Goocastle secret hook requires Guix; enter the documented Guix environment or install Guix before committing" >&2
  exit 1
fi
cd "$repository"
set -- gitleaks protect --staged --redact --no-banner --no-color --verbose --exit-code 1
if test -L "$repository/.gitleaks.toml"; then
  echo "Goocastle secret hook refuses a symlinked Gitleaks configuration" >&2
  exit 1
fi
if test -f "$repository/.gitleaks.toml"; then
  set -- "$@" --config "$repository/.gitleaks.toml"
fi
exec guix time-machine -C "$channels" -- shell -m "$manifest" -- "$@"
`;

const readHook = async (directory, name, displayPath, label) => {
  await directory.verify(`inspecting ${name}`);
  const path = directory.child(name);
  const info = await lstat(path).catch(() => undefined);
  if (!info) return undefined;
  if (info.isSymbolicLink() || !info.isFile()) throw new Error(`${label} must be a regular file: ${displayPath}`);
  if (info.size > MAX_HOOK_BYTES) throw new Error(`${label} is too large to inspect safely: ${displayPath}`);
  let handle;
  try {
    handle = await open(path, constants.O_RDONLY | constants.O_NOFOLLOW | constants.O_NONBLOCK);
    const opened = await handle.stat();
    if (!opened.isFile() || !sameSnapshot(opened, info)) {
      throw new Error(`${label} changed during inspection and was left unchanged: ${displayPath}`);
    }
    const contents = await readBoundedHook(handle, displayPath, label);
    const afterRead = await handle.stat();
    if (!sameSnapshot(afterRead, opened)) {
      throw new Error(`${label} changed during inspection and was left unchanged: ${displayPath}`);
    }
    const current = await lstat(path).catch(() => undefined);
    if (!current || !sameSnapshot(current, opened)) {
      throw new Error(`${label} changed during inspection and was left unchanged: ${displayPath}`);
    }
    return { contents, info: opened };
  } finally {
    await handle?.close();
  }
};

const isExecutable = async (directory, name, displayPath, info) => {
  if (!(info.mode & 0o111)) return false;
  await directory.verify(`checking ${name} permissions`);
  const path = directory.child(name);
  try {
    await access(path, constants.X_OK);
  } catch {
    return false;
  }
  const current = await lstat(path).catch(() => undefined);
  if (!current || current.isSymbolicLink() || !current.isFile() || !sameSnapshot(current, info)) {
    throw new Error(`Hook changed while checking permissions and was left unchanged: ${displayPath}`);
  }
  return true;
};

const unlinkIfUnchanged = async (directory, name, displayPath, expected, label, boundary) => {
  await atMutationBoundary(boundary);
  await directory.verify(label);
  const path = directory.child(name);
  const current = await lstat(path).catch((error) => {
    if (error?.code === "ENOENT") return undefined;
    throw error;
  });
  if (!current) return false;
  if (current.isSymbolicLink() || !current.isFile() || !sameSnapshot(current, expected)) {
    throw new Error(`${label} changed during the operation and was left unchanged: ${displayPath}`);
  }
  await unlink(path);
  await directory.verify(label);
  return true;
};

const unlinkIfSameIdentity = async (directory, name, expected) => {
  const current = await lstat(directory.child(name)).catch((error) => {
    if (error?.code === "ENOENT") return undefined;
    throw error;
  });
  if (current && sameFile(current, expected)) await unlink(directory.child(name));
};

const unlinkIfSameSnapshot = async (directory, name, expected) => {
  const current = await lstat(directory.child(name)).catch((error) => {
    if (error?.code === "ENOENT") return undefined;
    throw error;
  });
  if (current && sameSnapshot(current, expected)) await unlink(directory.child(name));
};

// Restore without rename(), which would silently replace a hook created after
// the initial inspection. A hard link is safe here because both paths are in
// the same hooks directory, and leaving both links behind is recoverable if
// unlinking the backup is interrupted.
const restoreBackup = async (directory, backupPath, hookPath, expected) => {
  await atMutationBoundary("restore-backup-link");
  await directory.verify("restoring the preserved hook");
  const backup = await lstat(directory.child(BACKUP_NAME));
  if (backup.isSymbolicLink() || !backup.isFile() || !sameSnapshot(backup, expected)) {
    throw new Error(`Preserved pre-commit hook changed during restoration and was left unchanged: ${backupPath}`);
  }
  try {
    await link(directory.child(BACKUP_NAME), directory.child(HOOK_NAME));
  } catch (error) {
    if (error?.code === "EEXIST") return false;
    throw error;
  }
  // link(2) updates the shared inode ctime.  Refresh the backup snapshot
  // before its destructive transition, and verify the new hook names it too.
  const linked = await lstat(directory.child(BACKUP_NAME));
  const restored = await lstat(directory.child(HOOK_NAME));
  if (!sameFile(linked, backup) || !sameFile(restored, backup)) {
    throw new Error(`Preserved pre-commit hook changed during restoration and was left unchanged: ${backupPath}`);
  }
  await unlinkIfUnchanged(directory, BACKUP_NAME, backupPath, linked, "Preserved pre-commit hook", "restore-backup-unlink");
  return true;
};

const preserveOriginal = async (directory, hookPath, backupPath, expected) => {
  let linked;
  try {
    await atMutationBoundary("preserve-original-link");
    await directory.verify("preserving the existing hook");
    const current = await lstat(directory.child(HOOK_NAME));
    if (current.isSymbolicLink() || !current.isFile() || !sameSnapshot(current, expected)) {
      throw new Error(`Existing pre-commit hook changed during the operation and was left unchanged: ${hookPath}`);
    }
    await link(directory.child(HOOK_NAME), directory.child(BACKUP_NAME));
    linked = await lstat(directory.child(BACKUP_NAME));
    // Creating the hard link updates ctime on the shared inode, so identity is
    // the only stable comparison at this point.  unlinkIfUnchanged below uses
    // the post-link snapshot for its final check.
    if (!sameFile(linked, expected)) throw new Error(`Existing pre-commit hook changed during the operation and was left unchanged: ${hookPath}`);
    await unlinkIfUnchanged(directory, HOOK_NAME, hookPath, linked, "Existing pre-commit hook", "preserve-original-unlink");
    // Removing the original directory entry changes the inode ctime again.
    // Return a fresh backup snapshot so an installation failure can restore
    // it without comparing against the pre-unlink timestamp.
    linked = await lstat(directory.child(BACKUP_NAME));
    return linked;
  } catch (error) {
    if (linked) await unlinkIfSameIdentity(directory, BACKUP_NAME, linked).catch(() => undefined);
    throw error;
  }
};

const ensureBackup = async (directory, backupPath) => {
  const backup = await readHook(directory, BACKUP_NAME, backupPath, "Existing Goocastle hook backup");
  if (backup && !(await isExecutable(directory, BACKUP_NAME, backupPath, backup.info))) {
    throw new Error(`Existing Goocastle hook backup is not executable: ${backupPath}; inspect it before retrying`);
  }
  return backup;
};

const createManagedHook = async (directory, hookPath, contents) => {
  await atMutationBoundary("create-managed-hook");
  await directory.verify("creating the Goocastle hook");
  const temporaryName = `${TEMPORARY_HOOK_PREFIX}${randomUUID()}.tmp`;
  let handle;
  let temporaryIdentity;
  let publishedSnapshot;
  let completed = false;
  try {
    // Keep the temporary inode in the hooks directory so its publication does
    // not cross filesystems. It remains owner-only while its contents are
    // prepared.
    handle = await open(directory.child(temporaryName), constants.O_WRONLY | constants.O_CREAT | constants.O_EXCL | constants.O_NOFOLLOW, 0o700);
    temporaryIdentity = await handle.stat();
    await atMutationBoundary("write-managed-hook");
    await handle.writeFile(contents, "utf8");
    await handle.sync();
    const written = await handle.stat();
    const temporary = await lstat(directory.child(temporaryName));
    if (!sameFile(temporary, temporaryIdentity) || !temporary.isFile() || temporary.isSymbolicLink() || !sameSnapshot(temporary, written)) {
      throw new Error(`Temporary Goocastle pre-commit hook changed during creation and was left unchanged: ${hookPath}`);
    }
    await directory.verify("preparing the Goocastle hook");

    // rename() would replace a hook that appeared after the initial read.
    // Linking the completed inode publishes it under the final name without
    // following or replacing that pathname; unlinking the temporary name then
    // leaves one complete, executable hook behind.
    await atMutationBoundary("publish-managed-hook");
    await directory.verify("publishing the Goocastle hook");
    await handle.chmod(0o755);
    await handle.sync();
    const publishable = await handle.stat();
    const publishableTemporary = await lstat(directory.child(temporaryName));
    if (!sameFile(publishableTemporary, temporaryIdentity) || !publishableTemporary.isFile() || publishableTemporary.isSymbolicLink() || !sameSnapshot(publishableTemporary, publishable)) {
      throw new Error(`Temporary Goocastle pre-commit hook changed during publication and was left unchanged: ${hookPath}`);
    }
    try {
      await link(directory.child(temporaryName), directory.child(HOOK_NAME));
    } catch (error) {
      if (error?.code === "EEXIST") {
        throw new Error(`Could not publish the Goocastle secret hook at ${hookPath}; an existing hook appeared and was left unchanged`, { cause: error });
      }
      throw error;
    }
    const published = await lstat(directory.child(HOOK_NAME));
    if (!published.isFile() || published.isSymbolicLink() || !sameFile(published, publishable)) {
      throw new Error(`Published Goocastle pre-commit hook changed during creation and was left unchanged: ${hookPath}`);
    }
    publishedSnapshot = published;
    await atMutationBoundary("publish-managed-hook-after-link");
    await unlinkIfSameIdentity(directory, temporaryName, temporaryIdentity);
    const created = await lstat(directory.child(HOOK_NAME));
    if (!created.isFile() || created.isSymbolicLink() || !samePublishedSnapshot(created, published)) {
      throw new Error(`Published Goocastle pre-commit hook changed during creation and was left unchanged: ${hookPath}`);
    }
    publishedSnapshot = created;
    await directory.verify("publishing the Goocastle hook");
    completed = true;
    return created;
  } finally {
    try {
      await handle?.close();
    } finally {
      if (!completed && publishedSnapshot) {
        // If publication succeeded but a later verification or cleanup step
        // failed, remove only the unchanged inode this operation published. A
        // concurrent unmanaged replacement or edit remains untouched.
        await unlinkIfSameSnapshot(directory, HOOK_NAME, publishedSnapshot).catch(() => undefined);
      }
      if (!completed && temporaryIdentity) {
        // Remove only the temporary inode opened by this operation. The final
        // hook is never removed here, so a concurrent unmanaged replacement is
        // preserved even when publication or cleanup fails.
        await unlinkIfSameIdentity(directory, temporaryName, temporaryIdentity).catch(() => undefined);
      }
    }
  }
};

const install = async (cwd = process.cwd()) => {
  requireLinuxAnchors();
  const { root, hookDirectory } = await resolveRepository(cwd, true);
  await resolveLayout(root);
  const hookPath = join(hookDirectory, HOOK_NAME);
  const backupPath = join(hookDirectory, BACKUP_NAME);
  const directory = await anchorDirectory(hookDirectory, "Configured Git hooks directory");
  try {
  const current = await readHook(directory, HOOK_NAME, hookPath, "Existing pre-commit hook");
  if (current && !(await isExecutable(directory, HOOK_NAME, hookPath, current.info))) {
    const managed = current.contents.startsWith(`#!/bin/sh\n${MARKER}\n`);
    throw new Error(
      managed
        ? `Goocastle pre-commit hook is not executable: ${hookPath}; restore its permissions before retrying`
        : `Existing pre-commit hook is not executable: ${hookPath}; make it executable before installing Goocastle`,
    );
  }
  const backup = await ensureBackup(directory, backupPath);
  const hook = renderHook();

  if (current?.contents.startsWith(`#!/bin/sh\n${MARKER}\n`)) {
    if (current.contents !== hook) {
      throw new Error(`Goocastle pre-commit hook was modified after installation: ${hookPath}; restore or remove it manually, then retry`);
    }
    console.log(`Goocastle secret hook is already installed at ${hookPath}.`);
    return { hookPath, backupPath: backup ? backupPath : undefined, installed: false };
  }
  if (current && backup) {
    throw new Error(`Cannot compose pre-commit hook: ${hookPath} and ${backupPath} already exist; inspect both and remove the stale backup before retrying`);
  }
  let movedOriginal;
  let createdHook;
  try {
    if (current) {
      movedOriginal = await preserveOriginal(directory, hookPath, backupPath, current.info);
    }
    createdHook = await createManagedHook(directory, hookPath, hook);
  } catch (error) {
    if (createdHook) await unlinkIfUnchanged(directory, HOOK_NAME, hookPath, createdHook, "New Goocastle pre-commit hook", "rollback-managed-hook-unlink").catch(() => undefined);
    if (movedOriginal) await restoreBackup(directory, backupPath, hookPath, movedOriginal).catch(() => undefined);
    throw new Error(
      `Could not install the Goocastle secret hook at ${hookPath}; any existing hook was restored when possible. Retry after inspecting the hook directory`,
      { cause: error },
    );
  }
  console.log(
    movedOriginal
      ? `Installed Goocastle secret hook at ${hookPath}; existing hook preserved at ${backupPath}.`
      : `Installed Goocastle secret hook at ${hookPath}.`,
  );
  return { hookPath, ...(movedOriginal ? { backupPath } : {}), installed: true };
  } finally {
    await directory.close();
  }
};

const remove = async (cwd = process.cwd()) => {
  requireLinuxAnchors();
  const { hookDirectory } = await resolveRepository(cwd);
  const hookPath = join(hookDirectory, HOOK_NAME);
  const backupPath = join(hookDirectory, BACKUP_NAME);
  // A missing directory means there cannot be managed state to remove.  Do
  // not create it merely to obtain an anchor.
  if (!(await lstatIfPresent(hookDirectory))) {
    console.log(`Goocastle secret hook is not installed at ${hookPath}.`);
    return { hookPath, removed: false };
  }
  const directory = await anchorDirectory(hookDirectory, "Configured Git hooks directory");
  try {
  const current = await readHook(directory, HOOK_NAME, hookPath, "Existing pre-commit hook");
  const backup = await ensureBackup(directory, backupPath);
  if (!current) {
    if (!backup) {
      console.log(`Goocastle secret hook is not installed at ${hookPath}.`);
      return { hookPath, removed: false };
    }
    if (!(await restoreBackup(directory, backupPath, hookPath, backup.info))) {
      throw new Error(`A replacement pre-commit hook appeared while restoring ${hookPath}; the preserved hook was left unchanged`);
    }
    console.log(`Restored the preserved pre-commit hook to ${hookPath}.`);
    return { hookPath, backupPath, removed: true };
  }
  if (!current.contents.startsWith(`#!/bin/sh\n${MARKER}\n`)) {
    throw new Error(`Refusing to remove non-Goocastle pre-commit hook ${hookPath}; it was left unchanged`);
  }
  const expected = renderHook();
  if (current.contents !== expected) {
    throw new Error(`Goocastle pre-commit hook was modified after installation: ${hookPath}; it was left unchanged`);
  }
  if (!(current.info.mode & 0o111)) {
    throw new Error(`Goocastle pre-commit hook is not executable: ${hookPath}; it was left unchanged`);
  }
  await unlinkIfUnchanged(directory, HOOK_NAME, hookPath, current.info, "Goocastle pre-commit hook", "remove-managed-hook");
  if (backup) {
    try {
      if (!(await restoreBackup(directory, backupPath, hookPath, backup.info))) {
        throw new Error(`A replacement pre-commit hook appeared while removing Goocastle: ${hookPath}`);
      }
    } catch (error) {
      throw new Error(
        `Removed the Goocastle hook but could not restore ${backupPath}; restore it manually with: mv ${shellQuote(backupPath)} ${shellQuote(hookPath)}`,
        { cause: error },
      );
    }
    console.log(`Removed the Goocastle secret hook and restored ${hookPath}.`);
  } else {
    console.log(`Removed the Goocastle secret hook from ${hookPath}.`);
  }
  return { hookPath, ...(backup ? { backupPath } : {}), removed: true };
  } finally {
    await directory.close();
  }
};

export { install, remove, renderHook, setSecretHookFaultInjectorForTesting };

const main = async () => {
  const [operation, directory, ...extra] = process.argv.slice(2);
  if (extra.length > 0 || (operation !== "install" && operation !== "remove")) {
    throw new Error("Usage: node scripts/secret-hook.mjs <install|remove> [directory]");
  }
  if (directory?.startsWith("-")) throw new Error("Secret hook directory must be a path, not an option");
  await (operation === "install" ? install(directory) : remove(directory));
};

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main().catch((error) => {
    console.error(error instanceof Error ? error.message : String(error));
    process.exitCode = 1;
  });
}
