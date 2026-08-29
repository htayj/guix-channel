import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { randomBytes } from "node:crypto";
import { existsSync, readFileSync, statSync } from "node:fs";
import { access, constants, lstat, mkdtemp, readFile, realpath, stat, unlink, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { isAbsolute, join, relative, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const GENERATED_RUNNER_RUNTIME_API_VERSION = 8;
const GENERATED_RUNNER_RUNTIME_IDENTITY = "goocastle/generated-runner/api-8/journal-1";
const GENERATED_RUNNER_JOURNAL_SCHEMA_VERSION = 1;
// This digest is a secret-free capability identity for the generated runner.
// It deliberately follows the checked-in runner bytes so a repaired runner
// cannot be mistaken for the one that exhausted a prior proof window.
const RUNNER_REPAIR_SEMANTIC_FINGERPRINT = createHash("sha256")
  .update(readFileSync(fileURLToPath(import.meta.url), "utf8"))
  .digest("hex");
const stableRepairJson = (value) => {
  if (value === null) return "null";
  if (Array.isArray(value)) return "[" + value.map(stableRepairJson).join(",") + "]";
  if (typeof value === "object") return "{" + Object.keys(value).sort().map((key) => JSON.stringify(key) + ":" + stableRepairJson(value[key])).join(",") + "}";
  const encoded = JSON.stringify(value);
  return encoded === undefined ? "undefined" : encoded;
};
const repairSemanticFingerprintFor = (workflow, phaseName) => createHash("sha256")
  .update(stableRepairJson({
    version: 1,
    runner: RUNNER_REPAIR_SEMANTIC_FINGERPRINT,
    workflow: workflow === undefined ? undefined : {
      name: workflow.name,
      requiredPhases: workflow.requiredPhases,
      setup: workflow.setup,
      evidence: workflow.evidence,
      // The failed gate and the agent phases rerun before it define the
      // repair's observable branch and execution semantics. Unrelated command
      // gates do not consume a new repair window.
      phases: workflow.phases.filter((phase) => phase.name === phaseName || phase.type === "agent"),
    },
    phase: phaseName,
  }))
  .digest("hex");
const SELF_HOSTED_RUNTIME_ROOT_ENVIRONMENT = "GOOCASTLE_SELF_HOSTED_RUNTIME_ROOT";
const hostWorkTree = process.cwd();
if (process.env.GOOCASTLE_PHASE_WORKER === "1") {
  throw new Error(
    "Refusing to run a generated Goocastle runner from an active phase worker; return to the parent harness instead of recursively starting Goocastle.",
  );
}
// Display-only POSIX renderer for operator recovery text.  Launches below
// continue to use structured argv and never feed this string to a shell.
const shellDisplayQuote = (value) => /^(?!-)[A-Za-z0-9_@%+=:,./-]+$/.test(value)
  ? value
  : "'" + value.replaceAll("'", "'\"'\"'") + "'";
const shellDisplayCommand = (file, args = []) => [file, ...args].map(shellDisplayQuote).join(" ");
const bootstrapGitEnvironment = { ...process.env };
delete bootstrapGitEnvironment.GIT_COMMON_DIR;
delete bootstrapGitEnvironment.GIT_DIR;
delete bootstrapGitEnvironment.GIT_WORK_TREE;
const selfHostedRuntimeRoot = (() => {
  const configured = process.env[SELF_HOSTED_RUNTIME_ROOT_ENVIRONMENT];
  if (configured !== undefined) {
    if (!isAbsolute(configured) || resolve(configured) !== hostWorkTree) {
      throw new Error(
        SELF_HOSTED_RUNTIME_ROOT_ENVIRONMENT + " must identify the current repository before its runtime can be refreshed: " +
          JSON.stringify(configured),
      );
    }
    return hostWorkTree;
  }
  // A direct Node launch has no CLI parent to set the marker.  Only infer
  // self-hosting from the repository root itself, never from a task worktree.
  try {
    const packageManifest = JSON.parse(readFileSync(join(hostWorkTree, "package.json"), "utf8"));
    return packageManifest?.name === "goocastle" ? hostWorkTree : undefined;
  } catch {
    return undefined;
  }
})();
const runtimeModuleUrl = (() => {
  if (!selfHostedRuntimeRoot) return process.env.GOOCASTLE_MODULE_URL ?? "goocastle";
  const gitDirectory = resolve(selfHostedRuntimeRoot, execFileSync("git", ["rev-parse", "--git-dir"], {
    cwd: selfHostedRuntimeRoot,
    encoding: "utf8",
    env: bootstrapGitEnvironment,
    stdio: ["ignore", "pipe", "pipe"],
    maxBuffer: 1024 * 1024,
  }).trim());
  const gitCommonDirectory = resolve(selfHostedRuntimeRoot, execFileSync("git", ["rev-parse", "--git-common-dir"], {
    cwd: selfHostedRuntimeRoot,
    encoding: "utf8",
    env: bootstrapGitEnvironment,
    stdio: ["ignore", "pipe", "pipe"],
    maxBuffer: 1024 * 1024,
  }).trim());
  if (gitDirectory !== gitCommonDirectory) {
    const worktrees = execFileSync("git", ["worktree", "list", "--porcelain"], {
      cwd: selfHostedRuntimeRoot,
      encoding: "utf8",
      env: bootstrapGitEnvironment,
      stdio: ["ignore", "pipe", "pipe"],
      maxBuffer: 1024 * 1024,
    });
    const integratedWorkTree = worktrees.split(/\r?\n/)
      .find((line) => line.startsWith("worktree "))?.slice("worktree ".length);
    const recovery = integratedWorkTree && isAbsolute(integratedWorkTree)
      ? "cd " + shellDisplayQuote(integratedWorkTree) + " && npm run build && " + shellDisplayCommand("goocastle", ["start", integratedWorkTree])
      : "git worktree list --porcelain";
    throw new Error(
      "Refusing to refresh a self-hosted runtime from a linked worktree. Build only the clean integrated host checkout with: " + recovery,
    );
  }
  const status = execFileSync("git", ["-c", "core.hooksPath=/dev/null", "status", "--porcelain"], {
    cwd: selfHostedRuntimeRoot,
    encoding: "utf8",
    env: bootstrapGitEnvironment,
    stdio: ["ignore", "pipe", "pipe"],
    maxBuffer: 1024 * 1024,
  }).trim();
  if (status) {
    throw new Error(
      "Refusing to refresh the self-hosted runtime from a dirty checkout. Commit or stash changes in " +
        JSON.stringify(selfHostedRuntimeRoot) + " and restart with: npm run build",
    );
  }
  try {
    // This is deliberately the integrated host checkout, after its cleanliness
    // check above; issue worktrees are never accepted as a runtime root.
    execFileSync("npm", ["run", "build"], {
      cwd: selfHostedRuntimeRoot,
      env: bootstrapGitEnvironment,
      stdio: "inherit",
    });
  } catch (error) {
    throw new Error(
      "Could not refresh the integrated self-hosted Goocastle runtime. Run npm run build in " +
        JSON.stringify(selfHostedRuntimeRoot) + " and restart the runner from that checkout.",
      { cause: error },
    );
  }
  const modulePath = join(selfHostedRuntimeRoot, "dist", "index.js");
  const guixModulePath = join(selfHostedRuntimeRoot, "dist", "sandboxes", "guix.js");
  if (!existsSync(modulePath) || !statSync(modulePath).isFile() || !existsSync(guixModulePath) || !statSync(guixModulePath).isFile()) {
    throw new Error(
      "The self-hosted runtime build did not produce dist/index.js and dist/sandboxes/guix.js. Run npm run build in " +
        JSON.stringify(selfHostedRuntimeRoot) + " and restart the runner.",
    );
  }
  const moduleUrl = pathToFileURL(modulePath).href;
  const guixModuleUrl = pathToFileURL(guixModulePath).href;
  process.env[SELF_HOSTED_RUNTIME_ROOT_ENVIRONMENT] = selfHostedRuntimeRoot;
  process.env.GOOCASTLE_MODULE_URL = moduleUrl;
  process.env.GOOCASTLE_GUIX_MODULE_URL = guixModuleUrl;
  return moduleUrl;
})();
const runtimeModule = await import(runtimeModuleUrl);
const { AGENT_PROVIDER_REGISTRY, DEFAULT_SEQUENTIAL_PHASE_LIVENESS, SEQUENTIAL_PHASE_FAILURE_HISTORY_LIMIT, SEQUENTIAL_PROVIDER_STATE_RECOVERY_MAX_EPOCHS, GENERATED_RUNNER_RUNTIME_API_VERSION: runtimeApiVersion, commitSigningRecoveryCommand, createConfiguredAgent, createSandbox, createSequentialTaskJournal, createWorktree, generatedRunnerRuntimeHandshake, gooflowDispositionImplementationTicket, gooflowDispositionLabels, gooflowImplementationTicketMarker, inspectRuntimeEvidenceArtifact, materializeGooflowEvidence, materializeGooflowImplementationTicketBody, parseGooflowDispositionResult, quarantineManagedStateHome, reconcileStalledSequentialPhases, renderGooflowImplementationTicket, renderGooflowDispositionComment, renderRuntimeEvidenceComment, resolveGooflowEvidence, validateGooflowImplementationTicketRuntimeEvidence, validateRuntimeEvidenceCapture, isProviderInterruption, isRetryableGitHubError, isTransientSequentialError, issueGooflowPhases, issueGooflowSetup, listSequentialTaskJournals, loadProjectConfig, parseGitHubIssueJson, parseGitHubIssueNumber, parseGitHubIssueReference, persistInterTaskDelay, preflightCommitSigning, reconcileInterTaskDelay, renderGitHubIssueContext, resolveIssueGooflow, retrySequential, runWorkflow, sequentialRetryDelay, snapshotGitHubIssue, transitionSequentialTaskJournal, validateGitHubIssueListPayload, validateGitHubIssuePayload, validateGitHubIssueStatePayload, validateIssueSpecification } = runtimeModule;
const defaultSequentialPhaseLiveness = DEFAULT_SEQUENTIAL_PHASE_LIVENESS ?? Object.freeze({
  expectedPacingMs: 5 * 60_000,
  stalledAfterMs: 15 * 60_000,
});
const sequentialPhaseFailureHistoryLimit = SEQUENTIAL_PHASE_FAILURE_HISTORY_LIMIT ?? 8;
const providerStateRecoveryMaxEpochs = SEQUENTIAL_PROVIDER_STATE_RECOVERY_MAX_EPOCHS ?? 2;
const runtimeHandshake = typeof generatedRunnerRuntimeHandshake === "function"
  ? generatedRunnerRuntimeHandshake()
  : undefined;
if (
  runtimeApiVersion !== GENERATED_RUNNER_RUNTIME_API_VERSION ||
  runtimeHandshake?.identity !== GENERATED_RUNNER_RUNTIME_IDENTITY ||
  runtimeHandshake?.apiVersion !== GENERATED_RUNNER_RUNTIME_API_VERSION ||
  runtimeHandshake.journalSchemaVersion !== GENERATED_RUNNER_JOURNAL_SCHEMA_VERSION
) {
  const recovery = selfHostedRuntimeRoot
    ? "Run npm run build in " + JSON.stringify(selfHostedRuntimeRoot) + " and restart the runner."
    : "Start with " + shellDisplayCommand("goocastle", ["start", hostWorkTree]) + " so it can select a compatible runtime.";
  throw new Error(
    "Generated runner/runtime compatibility mismatch (" + GENERATED_RUNNER_RUNTIME_IDENTITY + "; runner API v" + GENERATED_RUNNER_RUNTIME_API_VERSION +
      ", journal schema v" + GENERATED_RUNNER_JOURNAL_SCHEMA_VERSION + "). " + recovery,
  );
}
const { guix } = await import(process.env.GOOCASTLE_GUIX_MODULE_URL ?? "goocastle/sandboxes/guix");

const projectConfig = await loadProjectConfig(process.cwd());
const WORKFLOW_NAME = projectConfig.template;
if (projectConfig.template !== "sequential-reviewer") {
  throw new Error(
    "Config template " + JSON.stringify(projectConfig.template) +
      " does not match this generated entrypoint; set template to " +
      JSON.stringify("sequential-reviewer"),
  );
}
if (projectConfig.sandbox !== "guix") {
  throw new Error("The generated workflow requires the registered guix sandbox provider");
}
if (projectConfig.issueTracker !== "github") {
  throw new Error("The generated issue workflow requires the registered github issue tracker");
}

// GitHub can intermittently return an authentication-shaped 401, rate-limit
// response, or other transport failure. Delivery below is checkpointed and
// reconciled before mutations, so keep the harness alive through a transient
// forge outage rather than requiring an operator to restart it. Each retry
// batch remains bounded; recovery waits are capped and logged for visibility.
const githubRetryPolicy = Object.freeze({
  ...projectConfig.retryPolicy,
  maxAttempts: Math.max(projectConfig.retryPolicy.maxAttempts, 8),
  initialDelayMs: Math.max(projectConfig.retryPolicy.initialDelayMs, 5_000),
  maxDelayMs: Math.max(projectConfig.retryPolicy.maxDelayMs, 120_000),
});
const sleep = async (milliseconds) => await new Promise((resolve) => setTimeout(resolve, milliseconds));
const providerRecoveryDelay = (attempt) => {
  if (typeof sequentialRetryDelay === "function") return sequentialRetryDelay(projectConfig.retryPolicy, attempt);
  const policy = projectConfig.retryPolicy;
  const capped = Math.min(policy.maxDelayMs, policy.initialDelayMs * 2 ** (attempt - 1));
  return Math.min(policy.maxDelayMs, Math.max(0, Math.round(capped * (1 + ((Math.random() * 2) - 1) * policy.jitterRatio))));
};
const retryGitHub = async (description, operation) => {
  let recoveryAttempt = 0;
  for (;;) {
    try {
      return await retrySequential(operation, githubRetryPolicy, {
        retryable: (error) => isTransientSequentialError(error) || isRetryableGitHubError(error),
      });
    } catch (error) {
      if (!isTransientSequentialError(error) && !isRetryableGitHubError(error)) throw error;
      recoveryAttempt += 1;
      const waitMs = Math.min(10 * 60_000, 120_000 * 2 ** Math.min(recoveryAttempt - 1, 3));
      console.error("GitHub " + description + " is still returning a transient failure; retaining the journal and retrying automatically in " + Math.ceil(waitMs / 1000) + "s (recovery attempt " + recoveryAttempt + ").");
      await sleep(waitMs);
    }
  }
};

const secretEnvironment = new Set(projectConfig.secrets.environment);
const agentProvider = AGENT_PROVIDER_REGISTRY.find((provider) => provider.name === projectConfig.agent);
if (!agentProvider) throw new Error("Unknown configured agent provider: " + projectConfig.agent);
const credentialEnvironment = agentProvider.requiredCredentials
  .filter((credential) => credential.type === "environment")
  .map((credential) => credential.reference);
const credentialFiles = new Set(agentProvider.requiredCredentials
  .filter((credential) => credential.type === "file")
  .map((credential) => credential.reference));
const loadEnvironment = async (path, allowedNames) => {
  try {
    const contents = await readFile(path, "utf8");
    for (const rawLine of contents.split(/\r?\n/)) {
      const line = rawLine.trim();
      if (!line || line.startsWith("#")) continue;
      const separator = line.indexOf("=");
      if (separator < 1) continue;
      const name = line.slice(0, separator).trim();
      if (!allowedNames.has(name)) continue;
      let value = line.slice(separator + 1).trim();
      if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
        value = value.slice(1, -1);
      }
      if (process.env[name] === undefined) process.env[name] = value;
    }
  } catch (error) {
    if (error?.code !== "ENOENT") throw error;
  }
};

await loadEnvironment(".goocastle/.env", secretEnvironment);

const codexHome = process.env.CODEX_HOME ?? join(homedir(), ".codex");
const codexAuthAllowlisted = projectConfig.secrets.files.includes(".codex/auth.json");
if (codexAuthAllowlisted && !isAbsolute(codexHome)) {
  throw new Error("CODEX_HOME must be an absolute directory path: " + codexHome);
}
const codexAuth = isAbsolute(codexHome) ? join(codexHome, "auth.json") : "";
const usableEnvironmentCredential = credentialEnvironment.some(
  (name) => secretEnvironment.has(name) && Boolean(process.env[name]),
);
const allowlistedCredentialFile = [...credentialFiles].some(
  (path) => projectConfig.secrets.files.includes(path),
);
if (agentProvider.requiredCredentials.length > 0 && !usableEnvironmentCredential && !allowlistedCredentialFile) {
  throw new Error(
    "Credentials for " + agentProvider.name + " are not allowlisted; add one of " +
      credentialEnvironment.join(", ") + " to secrets.environment or one of " +
      [...credentialFiles].join(", ") + " to secrets.files",
  );
}
const homeFiles = [];
for (const relativePath of projectConfig.secrets.files) {
  const hostPath = relativePath === ".codex/auth.json"
    ? codexAuth
    : resolve(homedir(), relativePath);
  try {
    await access(hostPath);
  } catch (error) {
    if (credentialFiles.has(relativePath) && usableEnvironmentCredential) continue;
    throw new Error(
      "Allowlisted secret file " + JSON.stringify(relativePath) +
        " was not found at " + JSON.stringify(hostPath) +
        "; remove it from secrets.files or create the file",
      { cause: error },
    );
  }
  homeFiles.push({ hostPath, relativePath, sensitive: true });
}
const preservedEnvironment = projectConfig.secrets.environment.filter(
  (name) => process.env[name] !== undefined,
);
const sandboxEnvironment = Object.fromEntries(
  preservedEnvironment.map((name) => [name, process.env[name] ?? ""]),
);


const forgeTokenEnvironment = "GH_TOKEN";
const workflowRequestsForgeAccess = (workflow) =>
  [...(workflow?.phases ?? []), ...(workflow?.setup ?? [])]
    .some((entry) => entry.capabilities?.environment?.includes(forgeTokenEnvironment) === true);
const workflowRequestsGuixDaemon = (workflow) =>
  [...(workflow?.phases ?? []), ...(workflow?.setup ?? [])]
    .some((entry) => entry.capabilities?.guixDaemon === true);
const sandboxAccessForWorkflow = (workflow) => {
  const requestsForgeAccess = workflowRequestsForgeAccess(workflow);
  const requestsGuixDaemon = workflowRequestsGuixDaemon(workflow);
  if (requestsForgeAccess && !sandboxEnvironment[forgeTokenEnvironment]) {
    throw new Error(
      "Gooflow requests GH_TOKEN for a sandbox phase, but no GH_TOKEN value is available. " +
      "Set it in .goocastle/.env or the host environment, keep GH_TOKEN in secrets.environment, and retry after reviewing the phase trust boundary",
    );
  }
  const environment = { ...sandboxEnvironment };
  const preserveEnv = preservedEnvironment.filter((name) => requestsForgeAccess || name !== forgeTokenEnvironment);
  if (!requestsForgeAccess) delete environment[forgeTokenEnvironment];
  if (requestsGuixDaemon && !projectConfig.resourcePolicy.guixDaemon) {
    throw new Error(
      "Gooflow requests the Guix daemon, but resourcePolicy.guixDaemon is false. " +
      "Enable it only for reviewed package-build workflows and retry",
    );
  }
  return { environment, preserveEnv, requestsGuixDaemon };
};

const MAX_TASKS = projectConfig.taskLimits.maxTasks;
const RESUME_ONLY = process.env.GOOCASTLE_RESUME === "1";
// A terminal bounded-repair receipt is never reopened by ordinary scheduling.
// This opt-in is only meaningful for the explicit resume command and is kept
// separate from the normal resume path so branch repair is deliberate.
const RECOVER_BLOCKED = RESUME_ONLY && process.env.GOOCASTLE_RECOVER_BLOCKED === "1";
const SPECIFICATION_OVERRIDE = process.env.GOOCASTLE_SPECIFICATION_OVERRIDE === "1";
// This identity is intentionally opaque and secret-free. It proves which
// runner last owned a phase without retaining a PID, command line, or session.
const EXECUTOR_ID = "runner-" + process.pid + "-" + Date.now().toString(36) + "-" + Math.random().toString(36).slice(2, 10);
const stripTrailingLineEnding = (value) => value.endsWith("\r\n") ? value.slice(0, -2) : value.endsWith("\n") ? value.slice(0, -1) : value;
const REEXECUTION_STATE_ENVIRONMENT = "GOOCASTLE_DOGFOOD_REEXECUTION_STATE";
const parseReexecutionState = () => {
  const raw = process.env[REEXECUTION_STATE_ENVIRONMENT];
  if (raw === undefined) return { nextTask: 1, attemptedIssues: [] };
  let value;
  try {
    value = JSON.parse(raw);
  } catch (error) {
    throw new Error(
      "Could not read " + REEXECUTION_STATE_ENVIRONMENT + "; remove it and restart the runner from " + hostWorkTree,
      { cause: error },
    );
  }
  if (
    value === null || typeof value !== "object" || Array.isArray(value) ||
    value.version !== 1 || !Number.isSafeInteger(value.nextTask) || value.nextTask < 1 ||
    !Array.isArray(value.attemptedIssues) ||
    value.attemptedIssues.some((number) => !Number.isSafeInteger(number) || number < 1) ||
    new Set(value.attemptedIssues).size !== value.attemptedIssues.length
  ) {
    throw new Error(
      "Invalid " + REEXECUTION_STATE_ENVIRONMENT + "; remove it and restart the runner from " + hostWorkTree,
    );
  }
  return { nextTask: value.nextTask, attemptedIssues: value.attemptedIssues };
};
const reexecutionState = parseReexecutionState();
const hostGitEnvironment = { ...process.env };
for (const name of projectConfig.secrets.environment) delete hostGitEnvironment[name];
delete hostGitEnvironment.GIT_COMMON_DIR;
delete hostGitEnvironment.GIT_DIR;
delete hostGitEnvironment.GIT_WORK_TREE;
const hostGitDir = resolve(hostWorkTree, stripTrailingLineEnding(execFileSync("git", ["-c", "core.hooksPath=/dev/null", "rev-parse", "--git-dir"], {
  encoding: "utf8",
  env: hostGitEnvironment,
})));
const hostGit = (args, options = {}) => execFileSync(
  "git",
  ["-c", "core.hooksPath=/dev/null", "--git-dir=" + hostGitDir, "--work-tree=" + hostWorkTree, ...args],
  // execFileSync otherwise mirrors failed stderr to this process before the
  // caller can classify it.  Keep transport diagnostics bounded and private;
  // recovery output below is deliberately secret-free and structured.
  { env: hostGitEnvironment, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], maxBuffer: 1024 * 1024, ...options },
);
const signingMode = projectConfig.commitSigning?.mode ?? "inherit";
const signingBoundary = (kind, name) => kind + ":" + name;
const addSigningBoundary = (boundaries, boundary) =>
  boundaries.includes(boundary) ? boundaries : [...boundaries, boundary].slice(-32);
const unavailableBestEffortBoundaries = new Set();
let commitSigningEnvironment = signingMode === "inherit" ? {} : {
  GIT_CONFIG_COUNT: "1",
  GIT_CONFIG_KEY_0: "commit.gpgSign",
  // Signing keys stay on the trusted host. Required phases are signed by the
  // host at their phase boundary, so a Guix/Codex sandbox cannot silently
  // fall back to an unavailable or user-controlled keyring.
  GIT_CONFIG_VALUE_0: "false",
};
const setCommitSigningEnvironment = (enabled) => {
  commitSigningEnvironment = signingMode === "inherit" ? {} : {
    GIT_CONFIG_COUNT: "1",
    GIT_CONFIG_KEY_0: "commit.gpgSign",
    GIT_CONFIG_VALUE_0: String(enabled),
  };
};
const recordUnsignedCommit = async (journal, boundary) => {
  if (!unavailableBestEffortBoundaries.has(boundary)) return journal;
  const prior = journal.commitSigning;
  const unsigned = prior?.unsignedBoundaries ?? [];
  if (unsigned.includes(boundary)) return journal;
  return await transitionSequentialTaskJournal(gitCommonDir, journal, {
    commitSigning: {
      mode: signingMode,
      ...(prior?.blockedBoundaries?.length ? { blockedBoundaries: prior.blockedBoundaries } : {}),
      unsignedBoundaries: addSigningBoundary(unsigned, boundary),
    },
  });
};
const prepareCommitSigning = async (journal, boundary) => {
  if (signingMode === "inherit") return journal;
  if (signingMode === "disabled") {
    setCommitSigningEnvironment(false);
    hostGit(["config", "--local", "commit.gpgSign", "false"]);
    return journal;
  }
  const prior = journal.commitSigning;
  const blocked = prior?.blockedBoundaries ?? [];
  const unsigned = prior?.unsignedBoundaries ?? [];
  const preflight = await preflightCommitSigning(hostWorkTree, { environment: hostSigningEnvironment, localConfig: hostLocalGitConfig });
  if (preflight.available) {
    setCommitSigningEnvironment(false);
    hostGit(["config", "--local", "commit.gpgSign", "true"]);
    return journal;
  }
  if (signingMode === "best-effort") {
    setCommitSigningEnvironment(false);
    hostGit(["config", "--local", "commit.gpgSign", "false"]);
    unavailableBestEffortBoundaries.add(boundary);
    if (!unsigned.includes(boundary)) {
      console.warn("Commit signing is unavailable for " + boundary + "; best-effort policy will record unsigned commits. Unlock with: " + commitSigningRecoveryCommand());
    }
    return journal;
  }
  journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
    commitSigning: { mode: signingMode, blockedBoundaries: addSigningBoundary(blocked, boundary), ...(unsigned.length === 0 ? {} : { unsignedBoundaries: unsigned }) },
  });
  if (!blocked.includes(boundary)) {
    throw new Error("Required commit signing is unavailable before " + boundary + ". No replay or phase was started. Unlock once with: " + commitSigningRecoveryCommand() + ". Then resume with: " + resumeRecoveryCommand());
  }
  throw new Error("Required commit signing remains unavailable before " + boundary + ". Unlock the signer, then resume the preserved journal.");
};
// Inspect commits in the host Git repository so the sandbox cannot bypass a
// required signing policy with a direct Git invocation or a phase-specific
// override. The configured host signer is exercised by preflight, then each
// phase range is replayed and signed at its boundary; private signing material
// is never mounted into a Guix/Codex sandbox.
// Verify commit signatures in the host repository. A gpgsig header alone is
// not evidence: it can be copied into a commit message or contain an invalid
// packet. Git's verifier checks the cryptographic signature using the user's
// configured trust store while keeping its diagnostics out of recovery state.
const commitSignatureIsValid = (commit) => {
  try {
    hostSigningGit(["verify-commit", commit], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], maxBuffer: 64 * 1024 });
    return true;
  } catch {
    return false;
  }
};
const unsignedPhaseCommits = (startSha, endSha) => {
  if (startSha === endSha) return [];
  const commits = hostGit(["rev-list", "--reverse", startSha + ".." + endSha], { encoding: "utf8" })
    .trim().split("\n").filter(Boolean);
  return commits.filter((commit) => !commitSignatureIsValid(commit));
};
const blockCommitSigning = async (journal, boundary) => {
  const prior = journal.commitSigning;
  const blocked = prior?.blockedBoundaries ?? [];
  return await transitionSequentialTaskJournal(gitCommonDir, journal, {
    commitSigning: {
      mode: signingMode,
      blockedBoundaries: addSigningBoundary(blocked, boundary),
      ...(prior?.unsignedBoundaries?.length ? { unsignedBoundaries: prior.unsignedBoundaries } : {}),
    },
  });
};
const requireSignedPhaseCommits = async (journal, boundary, startSha, endSha) => {
  if (signingMode !== "required" || startSha === endSha) return journal;
  const unsigned = unsignedPhaseCommits(startSha, endSha);
  if (unsigned.length === 0) return journal;
  journal = await blockCommitSigning(journal, boundary);
  throw new Error("Required commit signing rejected " + String(unsigned.length) + " unsigned or unverifiable commit(s) before " + boundary + ". The task branch is preserved; inspect it with: " + recoveryCommand(journal.branch) + ", sign or replace those commits, then resume the workflow.");
};
const signRequiredPhaseCommits = async (journal, boundary, startSha, endSha) => {
  if (signingMode !== "required" || startSha === endSha) return { journal, head: endSha };
  const worktree = branchWorktreePath(journal.branch);
  if (worktree === undefined) {
    journal = await blockCommitSigning(journal, boundary);
    throw new Error("Required commit signing cannot locate the task worktree for " + journal.branch + ". The branch is preserved; inspect it with: " + recoveryCommand(journal.branch) + " and resume the workflow.");
  }
  if (hostGit(["rev-parse", journal.branch], { encoding: "utf8" }).trim() !== endSha) {
    throw new Error("Required commit signing found a changed task branch " + journal.branch + ". The branch is preserved; inspect it with: " + recoveryCommand(journal.branch) + " before resuming the workflow.");
  }
  try {
    // The sandbox has no private signing material. Replay only this phase's
    // commits in the host worktree and sign each replayed commit, not merely
    // the final tip. The command is static and passed as one argv element to
    // Git's documented --exec hook.
    gitAt(worktree, ["rebase", "--exec", "git -c core.hooksPath=/dev/null -c commit.gpgSign=true commit --amend --no-edit --no-verify", startSha], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], maxBuffer: 1024 * 1024 });
  } catch (error) {
    try { gitAt(worktree, ["rebase", "--abort"], { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], maxBuffer: 64 * 1024 }); } catch { /* preserve the conflict for manual recovery */ }
    journal = await blockCommitSigning(journal, boundary);
    throw new Error("Required commit signing could not sign every commit before " + boundary + ". The task branch is preserved; unlock the signer with: " + commitSigningRecoveryCommand() + ", inspect it with: " + recoveryCommand(journal.branch) + ", then resume the workflow.", { cause: error });
  }
  return { journal, head: hostGit(["rev-parse", journal.branch], { encoding: "utf8" }).trim() };
};
const ensureSignedPhaseCommits = async (journal, boundary, startSha, endSha) => {
  if (signingMode !== "required" || startSha === endSha) return { journal, head: endSha };
  if (unsignedPhaseCommits(startSha, endSha).length === 0) return { journal, head: endSha };
  const signed = await signRequiredPhaseCommits(journal, boundary, startSha, endSha);
  journal = await requireSignedPhaseCommits(signed.journal, boundary, startSha, signed.head);
  return { journal, head: signed.head };
};
const requireSignedCommit = async (journal, boundary, commit) => {
  if (signingMode !== "required" || commitSignatureIsValid(commit)) return journal;
  journal = await blockCommitSigning(journal, boundary);
  throw new Error("Required commit signing rejected an unsigned or unverifiable host integration commit before push for " + boundary + ". The integrated branch is preserved; inspect it with: " + recoveryCommand(journal.branch) + ", correct the signing configuration, then resume the workflow.");
};
const hostGitConfigPath = resolve(hostWorkTree, stripTrailingLineEnding(hostGit(["rev-parse", "--git-path", "config"], {
  encoding: "utf8",
})));
const hostLocalGitConfig = hostGit(["config", "--null", "--local", "--list"], { encoding: "utf8" });
const hostEffectiveGitConfig = hostGit(["config", "--null", "--list"], { encoding: "utf8" });
const hostSigningEnvironment = (() => {
  const environment = { ...hostGitEnvironment };
  for (const name of Object.keys(environment)) {
    if (name === "GIT_CONFIG_COUNT" || name === "GIT_CONFIG_PARAMETERS" || /^GIT_CONFIG_(KEY|VALUE)_\d+$/.test(name)) delete environment[name];
  }
  const values = new Map();
  for (const entry of hostEffectiveGitConfig.split("\0")) {
    const separator = entry.indexOf("\n");
    if (separator < 1) continue;
    const key = entry.slice(0, separator);
    if (key === "user.signingkey" || key.startsWith("gpg.")) values.set(key, entry.slice(separator + 1));
  }
  const format = values.get("gpg.format") ?? "openpgp";
  const defaultFormatProgram = values.get("gpg." + format + ".program") ??
    values.get("gpg.program") ??
    (format === "ssh" ? "ssh-keygen" : "gpg");
  const defaults = [
    ["user.signingkey", ""],
    ["gpg.format", format],
    ["gpg.program", "gpg"],
    ["gpg." + format + ".program", defaultFormatProgram],
    ["gpg.minTrustLevel", "undefined"],
    ["gpg.ssh.allowedSignersFile", ""],
    ["gpg.ssh.defaultKeyCommand", ""],
    ["gpg.ssh.revocationFile", ""],
  ];
  for (const [key, value] of defaults) if (!values.has(key)) values.set(key, value);
  const entries = [...values.entries()];
  if (entries.length > 0) {
    environment.GIT_CONFIG_COUNT = String(entries.length);
    entries.forEach(([key, value], index) => {
      environment["GIT_CONFIG_KEY_" + String(index)] = key;
      environment["GIT_CONFIG_VALUE_" + String(index)] = value;
    });
  }
  return environment;
})();
const hostSigningGit = (args, options = {}) => execFileSync(
  "git",
  ["-c", "core.hooksPath=/dev/null", "--git-dir=" + hostGitDir, "--work-tree=" + hostWorkTree, ...args],
  { env: hostSigningEnvironment, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], maxBuffer: 1024 * 1024, ...options },
);
const gitCommonDir = resolve(hostWorkTree, stripTrailingLineEnding(hostGit(["rev-parse", "--git-common-dir"], {
  encoding: "utf8",
})));
const baseBranch = stripTrailingLineEnding(hostGit(["branch", "--show-current"], {
  encoding: "utf8",
}));
if (!baseBranch) {
  throw new Error("Current checkout is detached; check out the branch to integrate before running " + WORKFLOW_NAME);
}
const recoveryCommand = (branch) => shellDisplayCommand("git", ["-C", hostWorkTree, "log", baseBranch + ".." + branch]);
const hostStatus = hostGit(["status", "--porcelain"], {
  encoding: "utf8",
}).trim();
if (hostStatus) {
  throw new Error(
    "Host checkout has uncommitted changes; commit or stash them before running " +
      WORKFLOW_NAME +
      "\n" +
      hostStatus,
  );
}
const codingStandards = await readFile(".goocastle/CODING_STANDARDS.md", "utf8");
const codexBinDirectory = projectConfig.agent === "codex"
  ? process.env.GOOCASTLE_CODEX_BIN_DIR
  : undefined;
if (codexBinDirectory) {
  if (!isAbsolute(codexBinDirectory)) {
    throw new Error(
      "GOOCASTLE_CODEX_BIN_DIR must be an absolute directory path: " +
        codexBinDirectory,
    );
  }
  const codexBinary = join(codexBinDirectory, "codex");
  const codexDirectoryInfo = await stat(codexBinDirectory).catch(() => undefined);
  const codexBinaryInfo = await stat(codexBinary).catch(() => undefined);
  if (!codexDirectoryInfo?.isDirectory() || !codexBinaryInfo?.isFile()) {
    throw new Error(
      "GOOCASTLE_CODEX_BIN_DIR must be a directory containing a codex executable: " +
        codexBinary,
    );
  }
  try {
    await access(codexBinary, constants.X_OK);
  } catch {
    throw new Error("GOOCASTLE_CODEX_BIN_DIR must contain an executable codex: " + codexBinary);
  }
}
const codexCommand = codexBinDirectory
  ? "/opt/goocastle-codex/codex"
  : "codex";
const configuredAgent = () => createConfiguredAgent({
  provider: projectConfig.agent,
  model: projectConfig.model,
  effort: projectConfig.effort,
  ...(projectConfig.agent === "codex" ? { command: codexCommand } : {}),
});
const materializeIssueWorkflow = (workflow, _issue) => workflow;
const agentProvenance = (workflow) => workflow?.phases
  .filter((phase) => phase.type === "agent")
  .map((phase) => ({
    name: phase.name,
    provider: phase.provider ?? projectConfig.agent,
    model: phase.model ?? projectConfig.model,
    effort: phase.effort ?? projectConfig.effort,
  })) ?? [];
const templateAgentProvenance = (phases) => phases
  .filter((phase) => phase.type === "agent")
  .map((phase) => ({
    name: phase.name,
    provider: projectConfig.agent,
    model: projectConfig.model,
    effort: projectConfig.effort,
  }));

const ghRestIssuePage = (value, source) => {
  if (!Array.isArray(value)) return validateGitHubIssueListPayload(value, source);
  // The REST issues endpoint includes pull requests.  Keep the issue-list
  // contract identical to the GitHub CLI issue-list command before validating its payload.
  return validateGitHubIssueListPayload(value.filter((entry) =>
    entry === null || typeof entry !== "object" || Array.isArray(entry) || !("pull_request" in entry)), source);
};
const ghRestIssueList = async (args) => {
  const stateIndex = args.indexOf("--state");
  const limitIndex = args.indexOf("--limit");
  const state = stateIndex === -1 ? "open" : args[stateIndex + 1];
  const limit = limitIndex === -1 ? 100 : Number(args[limitIndex + 1]);
  if ((state !== "open" && state !== "all") || !Number.isSafeInteger(limit) || limit < 1 || limit > 1000) {
    throw new Error("GitHub REST fallback received an unsupported issue-list request");
  }
  const repository = githubRepositoryFromOrigin();
  const issues = [];
  for (let page = 1; page <= Math.ceil(limit / 100); page += 1) {
    const endpoint = "repos/" + repository + "/issues?state=" + state + "&per_page=100&page=" + page;
    const output = execFileSync("gh", ["api", endpoint], { encoding: "utf8", maxBuffer: 16 * 1024 * 1024 });
    const received = parseGitHubIssueJson(output, "gh api " + endpoint, ghRestIssuePage);
    issues.push(...received);
    if (received.length < 100) break;
  }
  return issues.slice(0, limit);
};
const ghRestIssueView = async (args, validate) => {
  const number = parseGitHubIssueNumber(args[2], "GitHub REST issue view");
  const repository = githubRepositoryFromOrigin();
  const endpoint = "repos/" + repository + "/issues/" + number;
  const output = execFileSync("gh", ["api", endpoint], { encoding: "utf8", maxBuffer: 16 * 1024 * 1024 });
  const issue = JSON.parse(output);
  if (issue === null || typeof issue !== "object" || Array.isArray(issue)) return validate(issue, "gh api " + endpoint);
  const fields = args[args.indexOf("--json") + 1]?.split(",") ?? [];
  const result = {
    number: issue.number,
    title: issue.title,
    body: issue.body,
    labels: issue.labels,
    ...(fields.includes("state") ? { state: typeof issue.state === "string" ? issue.state.toUpperCase() : issue.state } : {}),
  };
  if (!fields.includes("comments")) return validate(result, "gh api " + endpoint);
  const comments = [];
  for (let page = 1; page <= 10; page += 1) {
    const commentEndpoint = endpoint + "/comments?per_page=100&page=" + page;
    const pageOutput = execFileSync("gh", ["api", commentEndpoint], { encoding: "utf8", maxBuffer: 16 * 1024 * 1024 });
    const received = JSON.parse(pageOutput);
    if (!Array.isArray(received)) throw new Error("gh api " + commentEndpoint + " returned a malformed comments payload");
    comments.push(...received.map((comment) => ({ body: comment.body, author: comment.user === null ? null : { login: comment.user?.login }, createdAt: comment.created_at })));
    if (received.length < 100) break;
  }
  return validate({ ...result, comments }, "gh api " + endpoint);
};
const ghJson = async (args, validate) => {
  let output;
  try {
    // GraphQL is optional for issue discovery.  Do only ordinary bounded
    // transport retries here so a GraphQL-only authentication failure reaches
    // the REST fallback below immediately.  The fallback itself owns the
    // persistent GitHub recovery loop.
    output = await retrySequential(() => execFileSync("gh", args, {
      encoding: "utf8",
      maxBuffer: 16 * 1024 * 1024,
    }), projectConfig.retryPolicy, { retryable: isTransientSequentialError });
  } catch (error) {
    if (args[0] !== "issue") throw error;
    if (args[1] === "list") {
      console.error("GitHub GraphQL issue discovery failed; retrying the same bounded issue scan through the REST API.");
      return await retryGitHub("REST issue discovery", () => ghRestIssueList(args));
    }
    if (args[1] === "view") {
      console.error("GitHub GraphQL issue view failed; retrying the same issue read through the REST API.");
      return await retryGitHub("REST issue view", () => ghRestIssueView(args, validate));
    }
    throw error;
  }
  // A command that successfully returned malformed data is not a transport
  // failure. Preserve the validation error rather than silently switching
  // transports and weakening the forge-data boundary.
  return parseGitHubIssueJson(output, "gh " + args.slice(0, 2).join(" "), validate);
};
const selectedIssue = async (number) => await ghJson([
  "issue", "view", String(number), "--json", "number,title,state,body,labels,comments",
], (value, source) => validateGitHubIssuePayload(value, source, number));

const specificationProvenance = (explanation, decision = "initial") => ({
  policyVersion: explanation.policyVersion,
  policyDigest: explanation.policyDigest,
  specificationDigest: explanation.specificationDigest,
  mode: explanation.policy.mode,
  decision,
});
const validateIssue = (issue) => {
  const explanation = validateIssueSpecification(
    { number: issue.number, body: issue.body },
    projectConfig.issueSpecification,
  );
  for (const warning of explanation.warnings) console.error("WARNING: " + warning);
  return explanation;
};
const validateIssueForWorkflow = (issue, workflow, { reportWarnings = true } = {}) => {
  const policy = {
    ...projectConfig.issueSpecification,
    ...(workflow?.issueSpecificationMode === undefined ? {} : { mode: workflow.issueSpecificationMode }),
  };
  const explanation = validateIssueSpecification(
    { number: issue.number, body: issue.body },
    policy,
  );
  if (reportWarnings) for (const warning of explanation.warnings) console.error("WARNING: " + warning);
  return explanation;
};
const reportInvalidReadyIssue = (issue, error) => {
  const detail = error instanceof Error ? error.message : String(error);
  console.error(
    "Skipping invalid ready-for-agent issue #" + issue.number + ": " + detail +
      " Fix the issue specification and rerun goocastle explain-readiness " +
      issue.number + " before restoring the ready-for-agent label.",
  );
};
const requestedGooflowOverride = process.env.GOOCASTLE_GOOFLOW_OVERRIDE;
if (requestedGooflowOverride && process.env.GOOCASTLE_GOOFLOW_BYPASS === "1") {
  throw new Error("GOOCASTLE_GOOFLOW_OVERRIDE conflicts with GOOCASTLE_GOOFLOW_BYPASS; choose one explicit workflow selection");
}
const resolveForIssue = async (issue, { reportSelection = true } = {}) => {
  const resolved = await resolveIssueGooflow({
    directory: hostWorkTree,
    config: projectConfig,
    issue: { number: issue.number, labels: issue.labels ?? [] },
    ...(requestedGooflowOverride ? { override: requestedGooflowOverride } : process.env.GOOCASTLE_GOOFLOW_BYPASS === "1" ? { override: "template" } : {}),
    ...(reportSelection ? { onSelection: (selection) => console.log(
      "Selected Gooflow " + JSON.stringify(selection.workflow?.name ?? "template") +
        " via " + selection.source +
        (selection.schemaVersion === undefined ? "" : " (schema v" + selection.schemaVersion + ")") +
        (selection.override === undefined ? "" : "; explicit override=" + JSON.stringify(selection.override)),
    ) } : {}),
  });
  if (resolved.selection.source === "template-fallback") {
    throw new Error("Missing .goocastle/gooflow.json; create the enforced Gooflow standard or set GOOCASTLE_GOOFLOW_BYPASS=1 for an audited template bypass");
  }
  // A per-issue evidence contract is host configuration, not issue content.
  // Resolve it while routing candidates so a missing or malformed entry cannot
  // create a journal or sandbox, and resolve it again after materialization
  // immediately before the phases run.
  if (resolved.workflow?.evidence?.runtimeContractPath !== undefined) {
    await resolveGooflowEvidence(resolved.workflow.evidence, hostWorkTree, issue.number);
  }
  return resolved;
};

const hasTerminalBlockedLabel = (issue) =>
  issue.labels.some((label) => label.name === "state:blocked");

const nextActionableIssue = async (excludedIssues = new Set()) => {
  const issues = (await ghJson([
    // The GitHub CLI fetches only the requested number of entries.  Keep the scan
    // large enough that an older explicitly-ready issue is not hidden by a
    // newly-created research backlog.
    "issue", "list", "--state", "open", "--limit", "1000",
    "--json", "number,title,body,labels",
  ], validateGitHubIssueListPayload)).filter((issue) => issue.labels.some((label) =>
    label.name === "ready-for-agent" || label.name.startsWith("gooflow:")));
  // Scheduling is deliberately opt-in for v1 projects.  Explicit priority
  // labels remain first; a repository can then prefer delivery over research
  // and define its own ascending difficulty vocabulary.
  const priorityLabels = projectConfig.taskLimits.priorityLabels ?? [];
  const deliveryFirst = projectConfig.taskLimits.deliveryFirst ?? false;
  const difficultyLabels = projectConfig.taskLimits.difficultyLabels ?? [];
  const priorityOf = (issue) => {
    const index = priorityLabels.findIndex((label) =>
      issue.labels.some((candidate) => candidate.name === label));
    return index === -1 ? priorityLabels.length : index;
  };
  const difficultyOf = (issue) => {
    const index = difficultyLabels.findIndex((label) =>
      issue.labels.some((candidate) => candidate.name === label));
    return index === -1 ? difficultyLabels.length : index;
  };
  const candidates = [];
  for (const issue of issues) {
    if (excludedIssues.has(issue.number)) continue;
    if (hasTerminalBlockedLabel(issue)) continue;
    let resolved;
    let explanation;
    try {
      // Candidate routing is a preflight, not an execution event.  Avoid
      // emitting a workflow selection and legacy-policy warning for every
      // open issue; the selected ticket is resolved again and reported below.
      resolved = await resolveForIssue(issue, { reportSelection: false });
      explanation = validateIssueForWorkflow(issue, resolved.workflow, { reportWarnings: false });
    } catch (error) {
      if (error instanceof Error && error.message.startsWith("Missing .goocastle/gooflow.json")) throw error;
      reportInvalidReadyIssue(issue, error);
      continue;
    }
    candidates.push({ issue, resolved, explanation });
  }
  candidates.sort((left, right) =>
    priorityOf(left.issue) - priorityOf(right.issue) ||
    (deliveryFirst ? Number(Boolean(left.resolved.workflow?.disposition)) - Number(Boolean(right.resolved.workflow?.disposition)) : 0) ||
    difficultyOf(left.issue) - difficultyOf(right.issue) ||
    left.issue.number - right.issue.number);
  for (const candidate of candidates) {
    const { issue } = candidate;
    const section = (issue.body ?? "").match(/## Blocked by\s*([\s\S]*?)(?=\n##|$)/i)?.[1] ?? "";
    const blockers = [...section.matchAll(/#(\d+)/g)].map((match) => parseGitHubIssueReference(match[1], "Blocked by issue reference"));
    let unblocked = true;
    for (const number of blockers) {
      if ((await ghJson(["issue", "view", String(number), "--json", "state"], validateGitHubIssueStatePayload)).state !== "CLOSED") {
        unblocked = false;
        break;
      }
    }
    if (unblocked) {
      const selected = await selectedIssue(issue.number);
      const resolved = await resolveForIssue(selected);
      const selectorLabels = resolved.workflow?.selectorLabels ?? ["ready-for-agent"];
      if (!selectorLabels.every((label) => selected.labels.some((entry) => entry.name === label))) continue;
      let explanation;
      try {
        explanation = validateIssueForWorkflow(selected, resolved.workflow);
      } catch (error) {
        reportInvalidReadyIssue(selected, error);
        continue;
      }
      const priority = priorityOf(selected);
      const difficulty = difficultyOf(selected);
      const delivery = !resolved.workflow?.disposition;
      const rationale = "priority=" + (priority === priorityLabels.length ? "none" : JSON.stringify(priorityLabels[priority])) +
        "; delivery=" + (delivery ? "yes" : "research/disposition") +
        "; difficulty=" + (difficulty === difficultyLabels.length ? "none" : JSON.stringify(difficultyLabels[difficulty])) +
        "; tie-breaker=#" + selected.number;
      console.log("Scheduler selected #" + selected.number + ": " + rationale);
      return { issue: selected, resolved, explanation, rationale };
    }
  }
  return undefined;
};

const remoteSha = async () => await retrySequential(() => {
  const output = hostGit(["ls-remote", "--heads", "origin", baseBranch], { encoding: "utf8" }).trim();
  return output === "" ? undefined : output.split(/\s+/)[0];
}, projectConfig.retryPolicy, { retryable: isTransientSequentialError });
// A transport error after the remote accepted a push is ambiguous.  Observe
// the remote before retrying so a resumable delivery never needlessly repeats
// the mutation (and never force-pushes).
const pushAndReconcile = async (integrationSha) => await retrySequential(async () => {
  try {
    hostGit(["push", "origin", baseBranch], { encoding: "utf8" });
  } catch (error) {
    if (!isTransientSequentialError(error)) throw error;
    if ((await remoteSha()) === integrationSha) return;
    throw error;
  }
}, projectConfig.retryPolicy, { retryable: isTransientSequentialError });

const phaseRecord = (journal, name) => journal.phases.find((phase) => phase.name === name);
const dispositionResultFromSandbox = async (sandbox, policy, stopReason) => {
  const worktree = resolve(sandbox.worktreePath);
  const path = resolve(worktree, policy.resultPath);
  const containment = relative(worktree, path);
  if (containment === "" || containment === ".." || containment.startsWith(".." + "/") || isAbsolute(containment)) {
    throw new Error("Configured Gooflow disposition result path escapes the sandbox worktree; fix disposition.resultPath before resuming");
  }
  let info;
  try {
    info = await lstat(path);
  } catch (error) {
    if (error?.code === "ENOENT") {
      const budgetNote = stopReason?.type === "budget-exhausted"
        ? " The phase command budget was exhausted before a disposition was journaled; the gathered evidence is insufficient to select a disposition."
        : "";
      throw new Error("Non-delivery Gooflow did not write its disposition result at " + policy.resultPath + "." + budgetNote + " Write the required JSON result and resume with: " + resumeRecoveryCommand());
    }
    throw error;
  }
  if (info.isSymbolicLink() || !info.isFile() || (await realpath(path)) !== path) {
    throw new Error("Refusing non-regular or symlinked Gooflow disposition result at " + policy.resultPath + "; replace it with a regular file and resume");
  }
  const result = parseGooflowDispositionResult(await readFile(path, "utf8"), policy);
  await unlink(path);
  return result;
};
const applyDisposition = async (journal, issue) => {
  const selected = journal.disposition;
  if (!selected) throw new Error("Non-delivery Gooflow has no recorded disposition; rerun its pending phases to produce one");
  const epoch = journal.epoch ?? 1;
  const exactImplementationTickets = async (ticket) => {
    const marker = gooflowImplementationTicketMarker(WORKFLOW_NAME, issue.number, epoch, selected.disposition);
    const candidates = await ghJson([
      "issue", "list", "--state", "all", "--limit", "100", "--search", marker,
      "--json", "number,title,body,labels",
    ], validateGitHubIssueListPayload);
    const receiptMatches = candidates.filter((candidate) => candidate.title === ticket.title && candidate.body.includes(marker));
    if (receiptMatches.length > 1) {
      throw new Error("Found multiple implementation tickets with the Goocastle receipt for #" + issue.number + "; resolve the duplicate tickets manually, then resume with: " + resumeRecoveryCommand());
    }
    return candidates.filter((candidate) => candidate.title === ticket.title && candidate.body === ticket.body);
  };
  const validateTicketRuntimeEvidence = async (ticket) => {
    if (ticket.runtimeEvidence === undefined) return undefined;
    const routed = await resolveIssueGooflow({
      directory: hostWorkTree,
      config: projectConfig,
      issue: { number: issue.number, labels: ticket.labelsToAdd },
    });
    if (routed.workflow === undefined) {
      throw new Error("Implementation ticket runtime evidence names workflow " + JSON.stringify(ticket.runtimeEvidence.workflow) + ", but its labels do not select a delivery workflow; add the workflow assignment label and resume");
    }
    let handoff;
    try {
      handoff = validateGooflowImplementationTicketRuntimeEvidence(
        { workflow: ticket.runtimeEvidence.workflow },
        routed.workflow,
        ticket.runtimeEvidence.contract,
      );
    } catch (error) {
      throw new Error("Implementation ticket runtime-evidence contract is not valid for the selected workflow: " + (error instanceof Error ? error.message : String(error)) + "; fix the reviewed handoff and resume", { cause: error });
    }
    if (handoff.contractPath !== ticket.runtimeEvidence.contractPath ||
        handoff.proofPhase !== ticket.runtimeEvidence.proofPhase ||
        handoff.capturePhase !== ticket.runtimeEvidence.capturePhase ||
        handoff.adapter !== ticket.runtimeEvidence.adapter) {
      throw new Error("Implementation ticket runtime-evidence workflow changed after journaling; restore the selected workflow's contract path and proof phases, then resume");
    }
    return handoff;
  };
  if (selected.implementationTicket) {
    let ticket = selected.implementationTicket;
    const runtimeEvidenceHandoff = await validateTicketRuntimeEvidence(ticket);
    if (ticket.create !== "complete") {
      let matches = await exactImplementationTickets(ticket);
      if (matches.length > 1) {
        throw new Error("Found multiple implementation tickets with the exact Goocastle receipt for #" + issue.number + "; resolve the duplicate tickets manually, then resume with: " + resumeRecoveryCommand());
      }
      if (matches.length === 0) {
        // A started boundary is deliberately ambiguous: the host could have exited
        // after GitHub accepted a create but before recording its number.
        // A second create here could make a duplicate while issue search is
        // still indexing the durable receipt, so only reconcile on resume.
        if (ticket.create === "started") {
          throw new Error("Could not determine whether Goocastle created the implementation ticket for #" + issue.number + ". Do not create another ticket; wait for GitHub issue search to index the receipt, then resume with: " + resumeRecoveryCommand());
        }
        journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
          disposition: { ...selected, implementationTicket: { ...ticket, create: "started" } }, status: "active",
        });
        ticket = journal.disposition.implementationTicket;
        try {
          await retryGitHub("implementation-ticket creation", async () => {
            // Reconcile before every retry. GitHub can accept a mutation and
            // lose its response; the exact receipt turns the otherwise
            // non-idempotent create into a duplicate-safe recovery boundary.
            const existing = await exactImplementationTickets(ticket);
            if (existing.length > 1) {
              throw new Error("Found multiple implementation tickets with the exact Goocastle receipt for #" + issue.number + "; resolve the duplicate tickets manually, then resume with: " + resumeRecoveryCommand());
            }
            if (existing.length === 1) {
              matches = existing;
              return;
            }
            const output = execFileSync("gh", ["issue", "create", "--title", ticket.title, "--body", ticket.body], { encoding: "utf8" });
            const issueNumber = /\/issues\/([1-9][0-9]*)\/?\s*$/.exec(output)?.[1];
            if (issueNumber === undefined) throw new Error("gh issue create did not return an issue URL");
            const createdIssueNumber = Number(issueNumber);
            if (!Number.isSafeInteger(createdIssueNumber)) throw new Error("gh issue create returned an unsafe issue number");
            const created = await selectedIssue(createdIssueNumber);
            if (created.title !== ticket.title || created.body !== ticket.body) {
              throw new Error("gh issue create returned an issue without the expected Goocastle receipt");
            }
            matches = [created];
          });
        } catch {
          // A failed transport can still mean GitHub accepted the create.
          // Reconcile once, but never retry the non-idempotent mutation.
          matches = await exactImplementationTickets(ticket);
          if (matches.length === 0) {
            throw new Error("Could not determine whether Goocastle created the implementation ticket for #" + issue.number + ". Do not create another ticket; wait for GitHub issue search to index the receipt, then resume with: " + resumeRecoveryCommand());
          }
        }
      }
      if (matches.length > 1) {
        throw new Error("Found multiple implementation tickets with the exact Goocastle receipt for #" + issue.number + "; resolve the duplicate tickets manually, then resume with: " + resumeRecoveryCommand());
      }
      if (matches.length !== 1) {
        throw new Error("Could not verify the created implementation ticket for #" + issue.number + ". Wait for GitHub issue search to index the receipt, then resume with: " + resumeRecoveryCommand());
      }
      ticket = { ...ticket, issueNumber: matches[0].number, create: "complete" };
      journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
        disposition: { ...journal.disposition, implementationTicket: ticket }, status: "active",
      });
    }
    ticket = journal.disposition.implementationTicket;
    if (ticket.runtimeEvidence !== undefined && ticket.contract !== "complete") {
      if (ticket.issueNumber === undefined || runtimeEvidenceHandoff === undefined) {
        throw new Error("Implementation ticket runtime-evidence contract has no assigned issue number; resume the ticket creation boundary");
      }
      const originalBody = ticket.preContractBody ?? ticket.body;
      const materializedBody = materializeGooflowImplementationTicketBody(originalBody, runtimeEvidenceHandoff, ticket.issueNumber);
      if (ticket.body !== materializedBody || ticket.preContractBody === undefined) {
        journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
          disposition: { ...journal.disposition, implementationTicket: { ...ticket, body: materializedBody, preContractBody: originalBody, contract: "started" } }, status: "active",
        });
        ticket = journal.disposition.implementationTicket;
      }
      const current = await selectedIssue(ticket.issueNumber);
      if (current.body !== ticket.body) {
        if (ticket.preContractBody === undefined || current.body !== ticket.preContractBody) {
          throw new Error("Implementation ticket #" + ticket.issueNumber + " changed before its runtime-evidence contract was materialized; restore its reviewed body and resume");
        }
        await retryGitHub("runtime-evidence contract handoff", async () => {
          const latest = await selectedIssue(ticket.issueNumber);
          if (latest.body === ticket.body) return;
          if (latest.body !== ticket.preContractBody) throw new Error("Implementation ticket #" + ticket.issueNumber + " changed before its runtime-evidence contract was materialized; restore its reviewed body and resume");
          execFileSync("gh", ["issue", "edit", String(ticket.issueNumber), "--body", ticket.body], { stdio: "inherit" });
        });
      }
      if ((await selectedIssue(ticket.issueNumber)).body !== ticket.body) {
        throw new Error("GitHub did not expose the materialized runtime-evidence contract for implementation ticket #" + ticket.issueNumber + "; retry with: " + resumeRecoveryCommand());
      }
      journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
        disposition: { ...journal.disposition, implementationTicket: { ...ticket, contract: "complete" } }, status: "active",
      });
      ticket = journal.disposition.implementationTicket;
    }
    if (ticket.labels !== "complete") {
      if (ticket.issueNumber === undefined) throw new Error("Created implementation ticket has no recorded issue number; resume with: " + resumeRecoveryCommand());
      journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
        disposition: { ...journal.disposition, implementationTicket: { ...ticket, labels: "started" } }, status: "active",
      });
      const labels = [...ticket.labelsToAdd.filter((label) => label !== "ready-for-agent"), ...ticket.labelsToAdd.filter((label) => label === "ready-for-agent")];
      for (const label of labels) {
        const hasLabel = async () => (await selectedIssue(ticket.issueNumber)).labels.some((entry) => entry.name === label);
        if (await hasLabel()) continue;
        await retryGitHub("implementation-ticket label delivery", async () => {
          if (await hasLabel()) return;
          execFileSync("gh", ["issue", "edit", String(ticket.issueNumber), "--add-label", label], { stdio: "inherit" });
        });
      }
      journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
        disposition: { ...journal.disposition, implementationTicket: { ...journal.disposition.implementationTicket, labels: "complete" } }, status: "active",
      });
    }
  }
  const implementationIssueNumber = journal.disposition.implementationTicket?.issueNumber;
  const comment = renderGooflowDispositionComment(WORKFLOW_NAME, issue.number, epoch, selected, implementationIssueNumber);
  const commentAlreadyApplied = async () =>
    (await selectedIssue(issue.number)).comments.some((entry) => entry.body === comment);
  if (journal.disposition.comment !== "complete") {
    journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
      disposition: { ...journal.disposition, comment: "started" }, status: "active",
    });
    // The marker is predictable and may appear in unrelated user comments.
    // Only the complete, journaled host receipt proves this boundary ran.
    if (!(await commentAlreadyApplied())) {
      // A transport error can arrive after GitHub accepted the comment. Check
      // the durable external receipt before every retry to avoid duplicates.
      await retryGitHub("disposition comment delivery", async () => {
        if (await commentAlreadyApplied()) return;
        execFileSync("gh", ["issue", "comment", String(issue.number), "--body", comment], {
          stdio: "inherit",
        });
      });
    }
    journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
      disposition: { ...journal.disposition, comment: "complete" }, status: "active",
    });
  }
  if (journal.disposition.labels !== "complete") {
    journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
      disposition: { ...journal.disposition, labels: "started" }, status: "active",
    });
    const current = await selectedIssue(issue.number);
    for (const label of journal.disposition.labelsToAdd) {
      if (current.labels.some((entry) => entry.name === label)) continue;
      await retryGitHub("disposition label delivery", () => execFileSync("gh", ["issue", "edit", String(issue.number), "--add-label", label], {
        stdio: "inherit",
      }));
    }
    journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
      disposition: { ...journal.disposition, labels: "complete" }, status: "complete",
    });
  }
  return journal;
};
const gitAt = (directory, args, options = {}) => execFileSync(
  "git",
  ["-c", "core.hooksPath=/dev/null", "-C", directory, ...args],
  { env: { ...hostSigningEnvironment, GIT_TERMINAL_PROMPT: "0", GPG_TTY: "/dev/null" }, ...options },
);
const githubRepositoryFromOrigin = () => {
  const origin = hostGit(["config", "--get", "remote.origin.url"], { encoding: "utf8" }).trim();
  const match = /^(?:https:\/\/github\.com\/|ssh:\/\/git@github\.com\/|git@github\.com:)([A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+?)(?:\.git)?$/.exec(origin);
  if (!match) throw new Error("Runtime evidence requires a GitHub remote.origin.url without credentials; configure origin as https://github.com/OWNER/REPOSITORY.git and resume");
  return match[1];
};
const runtimeEvidenceArtifactUrl = (integrationSha, artifactPath) => {
  const repository = githubRepositoryFromOrigin();
  const encodedPath = artifactPath.split("/").map((segment) => encodeURIComponent(segment)).join("/");
  return "https://github.com/" + repository + "/blob/" + encodeURIComponent(integrationSha) + "/" + encodedPath + "?raw=1";
};
const runtimeEvidenceArtifactCommit = async (journal, evidenceConfig, capturePhase, taskWorktree, branch, issueNumber) => {
  if (!taskWorktree) throw new Error("Cannot record runtime evidence without the task worktree; inspect the journal and resume");
  if (!journal.runtimeEvidence?.runtimeAssertion) {
    throw new Error("Cannot record runtime evidence without the host-validated packaged-runtime assertion; resume the screenshot phase after it emits the declared marker");
  }
  const artifact = await inspectRuntimeEvidenceArtifact(taskWorktree.worktreePath, evidenceConfig.artifactPath);
  const status = gitAt(taskWorktree.worktreePath, ["status", "--porcelain=v1", "--untracked-files=all", "-z"], { encoding: "utf8" });
  const entries = status.split("\0").filter(Boolean);
  const expected = "?? " + evidenceConfig.artifactPath;
  const expectedStaged = "A  " + evidenceConfig.artifactPath;
  const artifactCommitSubject = "test(runtime): record package screenshot for #" + String(issueNumber);
  let artifactCommitSha;
  if (entries.length === 0) {
    // A crash can happen after Git commits the artifact but before the journal
    // records the boundary. Reconcile only a clean, single-parent commit that
    // has the exact deterministic subject and adds only the declared image.
    const candidate = hostGit(["rev-parse", branch], { encoding: "utf8" }).trim();
    const parents = hostGit(["rev-list", "--parents", "-n", "1", candidate], { encoding: "utf8" }).trim().split(" ").filter(Boolean);
    const changes = gitAt(taskWorktree.worktreePath, ["diff-tree", "--no-commit-id", "--name-status", "-r", "-z", parents[1] ?? candidate, candidate], { encoding: "utf8" }).split("\0").filter(Boolean);
    const subject = hostGit(["show", "-s", "--format=%s", candidate], { encoding: "utf8" }).trim();
    if (journal.runtimeEvidence?.artifactStartSha === undefined || parents.length !== 2 || parents[1] !== journal.runtimeEvidence.artifactStartSha || subject !== artifactCommitSubject || changes.length !== 2 || changes[0] !== "A" || changes[1] !== evidenceConfig.artifactPath) {
      throw new Error("Runtime screenshot artifact boundary is neither the declared untracked image nor an exact committed artifact; inspect the preserved branch before resuming");
    }
    const signed = await ensureSignedPhaseCommits(journal, signingBoundary("runtime-evidence", capturePhase), journal.runtimeEvidence.artifactStartSha, candidate);
    journal = signed.journal;
    artifactCommitSha = signed.head;
    journal = await recordUnsignedCommit(journal, signingBoundary("runtime-evidence", capturePhase));
  } else if (entries.length !== 1 || (entries[0] !== expected && entries[0] !== expectedStaged)) {
    throw new Error("Runtime screenshot capture must produce exactly the declared untracked artifact " + JSON.stringify(evidenceConfig.artifactPath) + "; inspect the preserved branch and remove unrelated changes before resuming");
  } else {
    const artifactStartSha = hostGit(["rev-parse", branch], { encoding: "utf8" }).trim();
    if (journal.runtimeEvidence?.artifactStartSha !== undefined && journal.runtimeEvidence.artifactStartSha !== artifactStartSha) {
      throw new Error("Runtime screenshot artifact branch changed before its host commit; inspect the preserved branch before resuming");
    }
    if (journal.runtimeEvidence?.artifactStartSha === undefined) {
      journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
        runtimeEvidence: { ...journal.runtimeEvidence, artifactStartSha },
      });
    }
    journal = await prepareCommitSigning(journal, signingBoundary("runtime-evidence", capturePhase));
    if (entries[0] === expected) gitAt(taskWorktree.worktreePath, ["add", "--", evidenceConfig.artifactPath], { stdio: "inherit" });
    const staged = gitAt(taskWorktree.worktreePath, ["status", "--porcelain=v1", "-z"], { encoding: "utf8" }).split("\0").filter(Boolean);
    if (staged.length !== 1 || staged[0] !== expectedStaged) {
      throw new Error("Runtime screenshot artifact did not stage as a new file; inspect the preserved branch and resume after correcting the capture adapter");
    }
    gitAt(taskWorktree.worktreePath, ["commit", "--no-verify", "-m", artifactCommitSubject], { stdio: "inherit" });
    const unsignedArtifactCommitSha = hostGit(["rev-parse", branch], { encoding: "utf8" }).trim();
    const signed = await ensureSignedPhaseCommits(journal, signingBoundary("runtime-evidence", capturePhase), artifactStartSha, unsignedArtifactCommitSha);
    journal = signed.journal;
    artifactCommitSha = signed.head;
    journal = await recordUnsignedCommit(journal, signingBoundary("runtime-evidence", capturePhase));
  }
  return await transitionSequentialTaskJournal(gitCommonDir, journal, {
    runtimeEvidence: {
      ...journal.runtimeEvidence,
      artifact: "complete",
      artifactSha256: artifact.sha256,
      artifactBytes: artifact.bytes,
      artifactFormat: artifact.format,
      artifactCommitSha,
    },
  });
};
const postRuntimeEvidence = async (journal, evidenceConfig, integrationSha, phases, issueNumber) => {
  const evidence = journal.runtimeEvidence;
  if (!evidence || evidence.artifact !== "complete" || !evidence.artifactSha256 || !evidence.artifactBytes || !evidence.artifactFormat || !evidence.artifactCommitSha || !evidence.runtimeAssertion) {
    throw new Error("Cannot post runtime evidence before the bounded screenshot artifact and packaged-runtime assertion are committed; inspect the preserved journal and resume");
  }
  const proofPhase = phases.find((phase) => phase.name === evidenceConfig.proofPhase);
  const capturePhase = phases.find((phase) => phase.name === evidenceConfig.capturePhase);
  if (!proofPhase || proofPhase.type !== "command" || !capturePhase || capturePhase.type !== "command") {
    throw new Error("Runtime evidence receipt could not resolve its proof and capture command phases; restore the declared Gooflow and resume");
  }
  const artifactUrl = runtimeEvidenceArtifactUrl(integrationSha, evidence.artifactPath);
  const comment = renderRuntimeEvidenceComment({
    workflow: WORKFLOW_NAME,
    issueNumber,
    epoch: journal.epoch ?? 1,
    packageName: evidence.packageName,
    proofPhase: evidence.proofPhase,
    proofCommand: proofPhase.command,
    capturePhase: evidence.capturePhase,
    captureCommand: capturePhase.command,
    runtime: evidence.runtime,
    runtimeAssertion: evidence.runtimeAssertion,
    ...(evidence.runtimeContract === undefined ? {} : { runtimeContract: evidence.runtimeContract }),
    artifactPath: evidence.artifactPath,
    artifactSha256: evidence.artifactSha256,
    artifactBytes: evidence.artifactBytes,
    artifactFormat: evidence.artifactFormat,
    artifactCommitSha: evidence.artifactCommitSha,
    artifactUrl,
  });
  const marker = "<!-- goocastle-runtime-evidence:" + WORKFLOW_NAME + ":" + String(issueNumber) + ":" + String(journal.epoch ?? 1) + " -->";
  const commentAlreadyApplied = async () => {
    const current = await selectedIssue(issueNumber);
    const existing = current.comments.find((entry) => entry.body.includes(marker));
    if (existing && existing.body !== comment) {
      throw new Error("A different runtime evidence receipt already exists for #" + issueNumber + "; inspect the issue comment and preserved journal before retrying");
    }
    return existing !== undefined;
  };
  if (!(await commentAlreadyApplied())) {
    journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
      runtimeEvidence: { ...evidence, comment: "started", artifactUrl },
    });
    // A transport error can arrive after GitHub accepted the comment. Re-read
    // the durable external receipt before every retry so the non-idempotent
    // mutation is never repeated after an acknowledged comment.
    await retryGitHub("runtime-evidence comment delivery", async () => {
      if (await commentAlreadyApplied()) return;
      execFileSync("gh", ["issue", "comment", String(issueNumber), "--body", comment], { stdio: "inherit" });
    });
    const posted = await selectedIssue(issueNumber);
    if (!posted.comments.some((entry) => entry.body === comment)) throw new Error("GitHub did not expose the runtime evidence receipt after posting; issue remains open, retry with: " + resumeRecoveryCommand());
  }
  return await transitionSequentialTaskJournal(gitCommonDir, journal, {
    runtimeEvidence: { ...evidence, comment: "complete", artifactUrl },
  });
};
const branchWorktreePath = (branch) => {
  const fields = hostGit(["worktree", "list", "--porcelain", "-z"], { encoding: "utf8" }).split("\0");
  let worktree;
  for (const field of fields) {
    if (field.startsWith("worktree ")) worktree = field.slice("worktree ".length);
    else if (field === "branch refs/heads/" + branch) return worktree;
    else if (field === "") worktree = undefined;
  }
  return undefined;
};
const deliveryComplete = (journal) => journal.merge === "complete" && journal.push === "complete" &&
  journal.remoteVerification === "complete" && journal.issueClose === "complete" &&
  (journal.runtimeEvidence === undefined || (journal.runtimeEvidence.artifact === "complete" && journal.runtimeEvidence.comment === "complete"));
const exactRefSha = (ref) => {
  try {
    hostGit(["show-ref", "--verify", "--quiet", ref], { encoding: "utf8" });
  } catch (error) {
    // show-ref returns exactly 1 for an absent ref. Any other result leaves
    // cleanup resumable rather than treating inaccessible metadata as deleted.
    if ((error as { readonly status?: unknown }).status === 1) return undefined;
    throw error;
  }
  try {
    return hostGit(["rev-parse", "--verify", "--quiet", ref], { encoding: "utf8" }).trim();
  } catch (error) {
    // The ref may disappear or be renamed after the existence probe. Treat
    // that race exactly like an already-missing ref so cleanup remains
    // idempotent and can inspect explicit recovery refs.
    if ((error as { readonly status?: unknown }).status === 1) return undefined;
    throw error;
  }
};
const cleanupOutcome = async (journal, outcome) => await transitionSequentialTaskJournal(gitCommonDir, journal, {
  cleanup: "complete",
  cleanupOutcome: outcome,
  status: "complete",
});
const retainCleanupRef = async (journal, ref, sha, reason) => {
  // This is intentionally the only recovery line for a divergent ref. It is
  // terminal journal state, not an exception that would produce an uncaught
  // stack and block subsequent delivery recovery.
  console.error("Cleanup retained recovery ref: " + ref + " @ " + sha + " (" + reason + ").");
  return await cleanupOutcome(journal, { state: "retained", ref, sha, reason });
};
const reconcileDeliveredCleanup = async (journal, issueNumber) => {
  if (!deliveryComplete(journal)) {
    throw new Error("Cannot clean up #" + issueNumber + " before merge, push, remote verification, and issue close are complete");
  }
  if (journal.cleanup === "complete") return journal;
  journal = await transitionSequentialTaskJournal(gitCommonDir, journal, { cleanup: "started", status: "active" });
  const ref = "refs/heads/" + journal.branch;
  const branchHead = exactRefSha(ref);
  if (branchHead === undefined) {
    // These names are explicit recovery refs, never a fuzzy ref search. A
    // renamed generated branch may therefore be retained idempotently without
    // risking an unrelated branch that happens to contain the same patch.
    const recoveryRefs = [
      ...(journal.reconciliation?.backupBranch === undefined
        ? []
        : ["refs/heads/" + journal.reconciliation.backupBranch]),
      "refs/heads/goocastle/recovery/issue-" + issueNumber,
    ];
    for (const recoveryRef of recoveryRefs) {
      const recoveryHead = exactRefSha(recoveryRef);
      if (recoveryHead !== undefined) {
        return await retainCleanupRef(journal, recoveryRef, recoveryHead, "divergent-head");
      }
    }
    return await cleanupOutcome(journal, { state: "cleaned", ref, reason: "missing" });
  }
  if (!journal.integrationSha) {
    return await retainCleanupRef(journal, ref, branchHead, "missing-integration-sha");
  }
  // Patch equivalence is deliberately insufficient: only the exact commit
  // verified as integrated can make this task ref redundant.
  if (branchHead !== journal.integrationSha) {
    return await retainCleanupRef(journal, ref, branchHead, "divergent-head");
  }
  if (branchWorktreePath(journal.branch) !== undefined) {
    return await retainCleanupRef(journal, ref, branchHead, "checked-out");
  }
  try {
    // Compare-and-delete prevents a ref that changed after inspection from
    // being removed. Unlike branch -d, this uses the exact ref and SHA.
    hostGit(["update-ref", "-d", ref, branchHead], { encoding: "utf8" });
  } catch (error) {
    const currentHead = exactRefSha(ref);
    if (currentHead === undefined) return await cleanupOutcome(journal, { state: "cleaned", ref, reason: "missing" });
    if (currentHead !== branchHead) return await retainCleanupRef(journal, ref, currentHead, "changed");
    throw error;
  }
  return await cleanupOutcome(journal, { state: "cleaned", ref, sha: branchHead, reason: "deleted" });
};
const reconcileClosedRecoveryJournal = async (journal, issueNumber) => {
  if (journal.status === "complete") return journal;
  if (journal.merge === "complete" && journal.push === "complete" && journal.remoteVerification === "complete") {
    if (journal.issueClose !== "complete") {
      journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
        issueClose: "complete",
        status: "active",
      });
    }
    if (deliveryComplete(journal)) return await reconcileDeliveredCleanup(journal, issueNumber);
  }
  return await transitionSequentialTaskJournal(
    gitCommonDir,
    journal,
    journal.disposition
      ? { disposition: { ...journal.disposition, comment: "issue-closed" }, status: "complete" }
      : { status: "complete" },
  );
};
const reconciliationRecovery = (journal) =>
  "Original task tip is retained at " + journal.reconciliation.backupBranch + ". " +
  "Resolve the preserved replay with: " + shellDisplayCommand("git", ["-C", journal.reconciliation.recoveryWorktreePath, "rebase", "--continue"]) +
  "; or abandon only the replay with: " + shellDisplayCommand("git", ["-C", journal.reconciliation.recoveryWorktreePath, "rebase", "--abort"]) + ". " +
  "The original work is recoverable with: " + shellDisplayCommand("git", ["-C", hostWorkTree, "branch", "-f", "--", journal.branch, journal.reconciliation.backupBranch]);
const reconcileBaseAdvance = async (journal, issueNumber, dispositionPolicy) => {
  const currentBase = hostGit(["rev-parse", "HEAD"], { encoding: "utf8" }).trim();
  const recordedBase = journal.reconciliation?.state === "started"
    ? journal.reconciliation.sourceBaseSha
    : journal.reconciliation?.state === "complete"
      ? journal.reconciliation.reconciledBaseSha
      : journal.baseSha;
  if (journal.reconciliation?.state === "conflicted") {
    throw new Error("Cannot resume #" + issueNumber + " while base reconciliation is conflicted. " + reconciliationRecovery(journal));
  }
  if (journal.merge === "complete" || journal.push === "complete" || journal.issueClose === "complete") {
    if (currentBase === journal.integrationSha) return journal;
    throw new Error(
      "Cannot resume #" + issueNumber + ": " + journal.baseBranch + " advanced after integration began (expected " +
      journal.integrationSha + ", found " + currentBase + "). Do not rewrite or force-push it; inspect " +
      journal.branch + " and reconcile the published branch manually.",
    );
  }
  if (journal.merge === "started" && currentBase === journal.integrationSha) {
    return await transitionSequentialTaskJournal(gitCommonDir, journal, { merge: "complete" });
  }
  if (currentBase === recordedBase) return journal;
  try {
    hostGit(["merge-base", "--is-ancestor", recordedBase, currentBase]);
  } catch (error) {
    throw new Error(
      "Cannot resume #" + issueNumber + ": local " + journal.baseBranch + " moved from " + recordedBase +
      " to non-descendant " + currentBase + ". The task branch was not changed. Inspect it with: " +
      shellDisplayCommand("git", ["-C", hostWorkTree, "log", journal.baseBranch + ".." + journal.branch]),
      { cause: error },
    );
  }
  const taskHead = hostGit(["rev-parse", journal.branch], { encoding: "utf8" }).trim();
  // A task that has not produced commits is exactly its recorded base.  There
  // is nothing to replay: advance its checked-out worktree directly instead
  // of creating a rebase worktree that can fail during otherwise-idempotent
  // finalization.
  if (taskHead === recordedBase) {
    const checkedOutWorktree = branchWorktreePath(journal.branch);
    if (checkedOutWorktree === undefined) hostGit(["branch", "-f", journal.branch, currentBase]);
    else {
      const dirty = gitAt(checkedOutWorktree, ["status", "--porcelain=v1", "-z"], { encoding: "utf8" });
      // A non-delivery phase may leave its sandbox result behind when the
      // host rejects it before cleanup.  Its next run is required to replace
      // that exact untracked file, so permit deleting only that disposable
      // handoff; every other worktree mutation remains recovery evidence.
      const disposableResult = dispositionPolicy === undefined || journal.disposition !== undefined
        ? undefined
        : "?? " + dispositionPolicy.resultPath + " ";
      if (dirty.length > 0 && dirty !== disposableResult) {
        throw new Error("Cannot fast-forward #" + issueNumber + ": its task worktree has uncommitted changes at " + checkedOutWorktree);
      }
      if (dirty === disposableResult) {
        gitAt(checkedOutWorktree, ["clean", "-f", "--", dispositionPolicy.resultPath], { stdio: "inherit" });
      }
      gitAt(checkedOutWorktree, ["reset", "--keep", currentBase], { stdio: "inherit" });
    }
    return await transitionSequentialTaskJournal(gitCommonDir, journal, {
      reconciliation: {
        state: "complete", originalBaseSha: journal.baseSha, reconciledBaseSha: currentBase,
        sourceBaseSha: recordedBase, taskHead, rewrittenHead: currentBase,
        backupBranch: journal.reconciliation?.state === "started" ? journal.reconciliation.backupBranch : journal.branch + "-before-reconcile-" + taskHead.slice(0, 12),
      },
    });
  }
  if (journal.reconciliation?.state === "started" &&
      journal.reconciliation.reconciledBaseSha === currentBase &&
      taskHead !== journal.reconciliation.taskHead) {
    hostGit(["merge-base", "--is-ancestor", currentBase, taskHead]);
    const phases = journal.phases.map((phase) => {
      if (phase.state !== "running" || !phase.startSha) return phase;
      const commitCount = Number(hostGit(["rev-list", "--count", phase.startSha + ".." + journal.reconciliation.taskHead], { encoding: "utf8" }).trim());
      return commitCount === 0
        ? { ...phase, startSha: taskHead }
        : { ...phase, state: "complete", commitCount, completedAt: new Date().toISOString() };
    });
    return await transitionSequentialTaskJournal(gitCommonDir, journal, {
      phases,
      reconciliation: { ...journal.reconciliation, state: "complete", rewrittenHead: taskHead },
    });
  }
  journal = await prepareCommitSigning(journal, signingBoundary("reconciliation", journal.baseBranch));
  const backupBranch = journal.reconciliation?.state === "started"
    ? journal.reconciliation.backupBranch
    : journal.branch + "-before-reconcile-" + taskHead.slice(0, 12);
  if (journal.reconciliation?.state !== "started") {
    let existingBackup;
    try {
      existingBackup = hostGit(["rev-parse", backupBranch], { encoding: "utf8" }).trim();
    } catch { /* A crash before journal persistence may have created no backup yet. */ }
    if (existingBackup === undefined) hostGit(["branch", backupBranch, taskHead]);
    else if (existingBackup !== taskHead) {
      throw new Error("Cannot resume #" + issueNumber + ": reconciliation backup " + backupBranch + " changed; inspect " + journal.branch + " before retrying.");
    }
  } else if (hostGit(["rev-parse", backupBranch], { encoding: "utf8" }).trim() !== journal.reconciliation.taskHead) {
    throw new Error("Cannot resume #" + issueNumber + ": reconciliation backup " + backupBranch + " changed; inspect " + journal.branch + " before retrying.");
  }
  journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
    ...(journal.merge === "started" ? { merge: "pending", integrationSha: undefined } : {}),
    reconciliation: {
      state: "started",
      originalBaseSha: journal.baseSha,
      reconciledBaseSha: currentBase,
      sourceBaseSha: recordedBase,
      taskHead,
      backupBranch,
    },
  });
  const reconciliationWorktree = await mkdtemp(join(hostWorkTree, ".goocastle", "reconcile-"));
  hostGit(["worktree", "add", "--detach", reconciliationWorktree, taskHead], { stdio: "inherit" });
  try {
    gitAt(reconciliationWorktree, ["rebase", "--onto", currentBase, recordedBase], { stdio: "inherit" });
  } catch (error) {
    journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
      reconciliation: { ...journal.reconciliation, state: "conflicted", recoveryWorktreePath: reconciliationWorktree },
    });
    throw new Error("Could not reconcile #" + issueNumber + " onto " + journal.baseBranch + ". " + reconciliationRecovery(journal), { cause: error });
  }
  const rewrittenHead = gitAt(reconciliationWorktree, ["rev-parse", "HEAD"], { encoding: "utf8" }).trim();
  if (hostGit(["rev-parse", journal.branch], { encoding: "utf8" }).trim() !== taskHead) {
    throw new Error("Cannot finish reconciliation for #" + issueNumber + ": task branch changed while replaying. Original work remains at " + backupBranch + ".");
  }
  const checkedOutWorktree = branchWorktreePath(journal.branch);
  if (checkedOutWorktree === undefined) {
    hostGit(["branch", "-f", journal.branch, rewrittenHead]);
  } else {
    const dirty = gitAt(checkedOutWorktree, ["status", "--porcelain=v1", "-z"], { encoding: "utf8" });
    if (dirty.length > 0) {
      throw new Error(
        "Cannot finish reconciliation for #" + issueNumber + ": the checked-out task worktree has uncommitted changes. " +
          "Preserved worktree: " + checkedOutWorktree + ". Original work remains at " + backupBranch + ".",
      );
    }
    gitAt(checkedOutWorktree, ["reset", "--keep", rewrittenHead], { stdio: "inherit" });
  }
  const phases = journal.phases.map((phase) => {
    if (phase.state !== "running" || !phase.startSha) return phase;
    const commitCount = Number(hostGit(["rev-list", "--count", phase.startSha + ".." + taskHead], { encoding: "utf8" }).trim());
    return commitCount === 0
      ? { ...phase, startSha: rewrittenHead }
      : { ...phase, state: "complete", commitCount, completedAt: new Date().toISOString() };
  });
  journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
    phases,
    reconciliation: { ...journal.reconciliation, state: "complete", rewrittenHead },
  });
  if (Number(gitAt(reconciliationWorktree, ["rev-list", "--count", currentBase + ".." + rewrittenHead], { encoding: "utf8" }).trim()) > 0) {
    journal = await recordUnsignedCommit(journal, signingBoundary("reconciliation", journal.baseBranch));
  }
  hostGit(["worktree", "remove", reconciliationWorktree], { stdio: "inherit" });
  return journal;
};
const deferredJournalIssues = new Set();
const terminallyBlockedJournalIssues = new Set();
// A terminally blocked journal is intentionally skipped while a different
// eligible task proceeds.  A failed journal is different: before selecting
// fresh work, the run must stop and expose its recovery boundary.
const retryableFailedPhaseIssues = new Set();
const manuallyRecoverableJournalIssues = new Set();
const missingBranchManualJournalIssues = new Set();
const incompleteJournal = async () => {
  const journals = await listSequentialTaskJournals(gitCommonDir, WORKFLOW_NAME);
  const candidates = journals
    .filter((journal) => (!deliveryComplete(journal) || journal.cleanup !== "complete") &&
      (journal.status !== "complete" || journal.branchRecovery !== undefined) &&
      !(journal.status === "complete" && journal.branchRecovery?.state === "fresh-worktree" &&
        journal.branchRecovery.sourceEpoch === undefined &&
        journals.some((candidate) => candidate.issueNumber === journal.issueNumber &&
          candidate.branchRecovery?.sourceEpoch === (journal.epoch ?? 1))) &&
      !deferredJournalIssues.has(journal.issueNumber));
  // Cleanup-only work is safe and visible, but must never monopolize recovery
  // while another journal still has merge/push/close work to finish. Terminal
  // missing-branch receipts stay in this queue so a later launch cannot
  // silently start a new epoch around an unresolved recovery boundary.
  const recoveryCandidates = candidates.filter((journal) => !deliveryComplete(journal));
  if (recoveryCandidates.length > 0) {
    // Refresh each candidate's forge state before selecting retained recovery
    // state. A candidate that no longer has an open issue is closed or
    // archived for scheduling purposes; preserve its journal as audit history
    // while preventing it from monopolizing an eligible open issue.
    for (const candidate of recoveryCandidates) {
      const issue = await selectedIssue(candidate.issueNumber);
      if (issue.state === "OPEN") return candidate;
      await reconcileClosedRecoveryJournal(candidate, candidate.issueNumber);
      console.log(
        "Skipping closed or archived issue #" + candidate.issueNumber +
          "; its preserved journal is recorded complete without replay.",
      );
    }
  }
  return candidates.find(deliveryComplete);
};
const journalEpoch = (journal) => journal.epoch ?? 1;
const MISSING_BRANCH_MANUAL_ACTION = "git fsck --no-reflogs --lost-found";
const createFreshRecoveryJournal = async (terminal, sourceEpoch) => {
  let replacement;
  for (let attempt = 0; attempt < 8; attempt += 1) {
    const branch = "goocastle/recovery/issue-" + terminal.issueNumber + "-epoch-" + sourceEpoch + "-" + randomBytes(8).toString("hex");
    if (exactRefSha("refs/heads/" + branch) !== undefined) continue;
    try {
      replacement = await createSequentialTaskJournal({
        gitCommonDir,
        workflow: WORKFLOW_NAME,
        issueNumber: terminal.issueNumber,
        baseSha: hostGit(["rev-parse", "HEAD"], { encoding: "utf8" }).trim(),
        baseBranch,
        branch,
        specification: terminal.specification,
        branchRecovery: {
          state: "fresh-worktree",
          reason: "missing-empty-branch",
          sourceEpoch,
        },
      });
      break;
    } catch (error) {
      const concurrent = (await listSequentialTaskJournals(gitCommonDir, WORKFLOW_NAME)).find((candidate) =>
        candidate.issueNumber === terminal.issueNumber &&
        candidate.branchRecovery?.state === "fresh-worktree" &&
        candidate.branchRecovery.sourceEpoch === sourceEpoch,
      );
      if (concurrent !== undefined) {
        replacement = concurrent;
        break;
      }
      throw error;
    }
  }
  if (replacement === undefined) {
    throw new Error("Could not allocate a fresh recovery branch for #" + terminal.issueNumber + "; run: " + MISSING_BRANCH_MANUAL_ACTION);
  }
  console.error("Recovered missing empty task branch for #" + terminal.issueNumber + " with fresh journal epoch " + journalEpoch(replacement) + ".");
  return replacement;
};
// A missing ref is not by itself evidence that no work existed.  The sole
// automatic path is deliberately narrower: no linked worktree, no phase start
// receipt, no reconciliation receipt, and no incomplete setup receipt means
// the runner never observed a point at which work could have been committed.
// Every other case is terminal and manual.
const recoverMissingTaskBranch = async (journal) => {
  if (journal.branchRecovery?.state === "manual") return journal;
  const sourceEpoch = journalEpoch(journal);
  if (journal.status === "complete" && journal.branchRecovery?.state === "fresh-worktree" &&
      journal.branchRecovery.sourceEpoch === undefined) {
    const concurrent = (await listSequentialTaskJournals(gitCommonDir, WORKFLOW_NAME)).find((candidate) =>
      candidate.issueNumber === journal.issueNumber &&
      candidate.branchRecovery?.state === "fresh-worktree" &&
      candidate.branchRecovery.sourceEpoch === sourceEpoch,
    );
    return concurrent === undefined
      ? await createFreshRecoveryJournal(journal, sourceEpoch)
      : await recoverMissingTaskBranch(concurrent);
  }
  if (deliveryComplete(journal)) return journal;
  const ref = "refs/heads/" + journal.branch;
  const branchHead = exactRefSha(ref);
  if (branchHead !== undefined) return journal;
  const worktree = branchWorktreePath(journal.branch);
  const setupProvesEmpty = journal.setup === undefined ||
    (journal.setup.state === "complete" && journal.setup.startSha === journal.setup.endSha);
  const emptyPreCommit = worktree === undefined && journal.phases.length === 0 &&
    journal.reconciliation === undefined && setupProvesEmpty;
  if (journal.branchRecovery?.state === "fresh-worktree" && emptyPreCommit) {
    // A previous fresh epoch can itself be interrupted before createWorktree.
    // Its branch is known empty, so restore only that generated ref at its
    // recorded base and let ordinary fast-forward reconciliation continue.
    try {
      hostGit(["branch", journal.branch, journal.baseSha], { encoding: "utf8" });
    } catch (error) {
      // A concurrent resume may have restored this same generated ref after
      // our probe. Never overwrite it; ordinary reconciliation will verify it.
      if (exactRefSha(ref) === undefined) throw error;
    }
    return journal;
  }
  if (!emptyPreCommit) {
    if (journal.branchRecovery?.state === "manual") return journal;
    return await transitionSequentialTaskJournal(gitCommonDir, journal, {
      branchRecovery: {
        state: "manual",
        reason: "missing-ambiguous-branch",
        manualAction: MISSING_BRANCH_MANUAL_ACTION,
      },
      status: "complete",
      failure: "Recorded task branch is missing and journal evidence cannot prove it was empty. Run the recorded manual recovery action before starting another epoch.",
    });
  }
  let terminal;
  try {
    terminal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
      branchRecovery: { state: "fresh-worktree", reason: "missing-empty-branch" },
      status: "complete",
      failure: "Recorded task branch was missing before any phase start; a fresh worktree recovery was created with the original specification receipt.",
    });
  } catch (error) {
    // Another resume may have atomically published the successor after this
    // invocation read the old epoch. Reuse only the explicitly linked epoch;
    // if it has only terminalized the source so far, this invocation can
    // safely race to publish the single successor below.
    const journals = await listSequentialTaskJournals(gitCommonDir, WORKFLOW_NAME);
    const concurrent = journals.find((candidate) =>
      candidate.status !== "complete" &&
      candidate.issueNumber === journal.issueNumber &&
      candidate.branchRecovery?.state === "fresh-worktree" &&
      candidate.branchRecovery.sourceEpoch === sourceEpoch,
    );
    if (concurrent !== undefined) return concurrent;
    const publishedTerminal = journals.find((candidate) =>
      candidate.status === "complete" &&
      candidate.issueNumber === journal.issueNumber &&
      journalEpoch(candidate) === sourceEpoch &&
      candidate.branchRecovery?.state === "fresh-worktree" &&
      candidate.branchRecovery.reason === "missing-empty-branch",
    );
    if (publishedTerminal === undefined) throw error;
    terminal = publishedTerminal;
  }
  return await createFreshRecoveryJournal(terminal, sourceEpoch);
};
const latestCompletedBoundary = async () => {
  let latest;
  for (const journal of await listSequentialTaskJournals(gitCommonDir, WORKFLOW_NAME)) {
    if (journal.status !== "complete") continue;
    const completedAt = Date.parse(journal.updatedAt);
    if (Number.isSafeInteger(completedAt) && (latest === undefined || completedAt > latest)) latest = completedAt;
  }
  return latest;
};

const reportRecovery = (issue, branch, integration, recovery) => {
  if (recovery.preservedWorktreePath) {
    console.error("Recovery worktree: " + recovery.preservedWorktreePath);
    console.error("Inspect it with: " + shellDisplayCommand("git", ["-C", recovery.preservedWorktreePath, "status"]));
  } else if (integration === "merged") {
    console.error("Recovery branch: " + branch);
    console.error("Integration was fast-forwarded locally but not pushed. Push after review with: " + shellDisplayCommand("git", ["-C", hostWorkTree, "push", "origin", baseBranch]));
  } else if (integration === "pushed") {
    console.error("Recovery branch: " + branch);
    console.error("Integration was pushed but the issue remains open. Close it after review with: " + shellDisplayCommand("gh", ["issue", "close", String(issue.number), "--comment", "Completed by Goocastle"]));
  } else {
    console.error("Recovery branch: " + branch);
    console.error("Inspect it with: " + shellDisplayCommand("git", ["-C", hostWorkTree, "log", baseBranch + ".." + branch]));
  }
};
const resumeRecoveryCommand = () => shellDisplayCommand("goocastle", ["resume", hostWorkTree]);
const reconcileAbandonedPhases = async () => {
  // Older compatible test/runtime facades may not expose the optional
  // liveness helper. A real generated runner still receives it from the
  // current package; retaining this guard keeps normal recovery semantics
  // intact for an otherwise complete journal API.
  if (typeof reconcileStalledSequentialPhases !== "function") return;
  for (const candidate of await listSequentialTaskJournals(gitCommonDir, WORKFLOW_NAME)) {
    if (candidate.status === "complete") continue;
    const reconciled = await reconcileStalledSequentialPhases(gitCommonDir, candidate, {
      recoveryCommand: resumeRecoveryCommand(),
    });
    if (reconciled !== candidate) {
      console.error(
        "Marked stalled executor phase(s) failed for #" + candidate.issueNumber +
        "; no phase was replayed. Inspect the preserved worktree and resume explicitly with: " + resumeRecoveryCommand(),
      );
    }
  }
};
const providerInterruptionFor = (error) => {
  if (typeof isProviderInterruption === "function") return isProviderInterruption(error);
  const messages = [];
  let current = error;
  while (current instanceof Error && messages.length < 4) {
    messages.push(current.message);
    current = current.cause;
  }
  return messages.some((message) => /\bAgent\b[\s\S]{0,256}\b(?:exited with code 137|SIGKILL)\b/iu.test(message));
};
const boundedFailureKind = (error, providerPhase = false) => {
  if (providerPhase && providerInterruptionFor(error)) return "provider-interruption";
  const messages = [];
  let current = error;
  while (current instanceof Error && messages.length < 4) {
    messages.push(current.message.toLowerCase());
    current = current.cause;
  }
  const reason = messages.join(" ");
  return reason.includes("timeout") ? "timeout"
    : reason.includes("resource-limit") || reason.includes("resource limit") ? "resource-limit"
      : reason.includes("cancellation") || reason.includes("aborted") ? "cancelled"
        : "error";
};
const reportTransientDeliveryPause = (journal) => {
  console.error(
    "Delivery paused after bounded transient Git transport retries. " +
      "The secret-free journal remains at " + JSON.stringify(gitCommonDir) +
      " (merge=" + journal.merge + ", push=" + journal.push +
      ", remoteVerification=" + journal.remoteVerification +
      ", issueClose=" + journal.issueClose + ", cleanup=" + journal.cleanup + ").",
  );
  // Keep this as the sole executable recovery line for automation and people.
  console.error("Recovery command: " + resumeRecoveryCommand());
};

const failureDiagnosticFor = (summary, maximum = 8_000) => {
  if (!summary || typeof summary !== "object") return "";
  const command = shellDisplayCommand(summary.command?.file ?? "unknown", summary.command?.args ?? []);
  const lines = Array.isArray(summary.lines) ? summary.lines.slice(-8).map((line) => "  [" + line.stream + "] " + line.text) : [];
  const diagnostic = "\n\nFailed command: " + command + "\nExit status: " + String(summary.exitCode) +
    "\nFinal failure lines:\n" + (lines.length > 0 ? lines.join("\n") : "  (no output retained)") +
    (summary.truncated === true ? "\n  [earlier or oversized output omitted]" : "");
  return diagnostic.length <= maximum ? diagnostic : diagnostic.slice(0, Math.max(0, maximum - 1)) + "…";
};

// A required command defect is different from an unavailable host
// prerequisite: the task branch can be repaired by re-entering the agent and
// audit phases. Keep the repair receipt in the journal so a restart cannot
// silently turn the repair into an unbounded proof retry loop.
const MAX_REQUIRED_COMMAND_REPAIR_EPOCHS = 2;
const repairFailureFingerprint = (phase, receipt) => JSON.stringify({ phase, receipt });
const reopenBlockedRequiredCommandRepair = async (journal, phaseName, semanticFingerprint) => {
  if (journal.repair?.state !== "blocked") return { journal, reopened: false };
  // A normal scheduler launch must preserve terminal exhaustion, even when a
  // generated runner or Gooflow changed. Only an explicit resume may reopen it.
  const latest = journal.repair.epochs.at(-1);
  if (!RESUME_ONLY) return { journal, reopened: false };
  // A missing fingerprint identifies a journal written before this migration.
  // Re-enter it once under the current runner/Gooflow identity; the normal
  // two-attempt bound is then reinstated and future unchanged failures remain
  // terminally blocked.
  if (latest?.semanticFingerprint === semanticFingerprint && !RECOVER_BLOCKED) return { journal, reopened: false };
  const branchHead = exactRefSha("refs/heads/" + journal.branch);
  if (branchHead === undefined) {
    throw new Error(
      "Cannot reopen bounded repair for #" + journal.issueNumber + ": the preserved task branch is missing. " +
      "Inspect the journal and run: " + resumeRecoveryCommand(),
    );
  }
  const failureReceipt = latest?.failureReceipt;
  if (failureReceipt === undefined) return { journal, reopened: false };
  const reopened = {
    state: "scheduled",
    reopenedFromBlocked: true,
    epochs: [{
      epoch: 1,
      phase: phaseName,
      branch: journal.branch,
      startSha: branchHead,
      failureReceipt,
      semanticFingerprint,
      state: "scheduled",
    }],
  };
  return {
    journal: await transitionSequentialTaskJournal(gitCommonDir, journal, { repair: reopened, status: "active" }),
    reopened: true,
  };
};
const reconcileReopenedRequiredCommandRepair = async (journal, issueNumber) => {
  if (journal.repair?.reopenedFromBlocked !== true) return journal;
  await retryGitHub("required command repair reopening", async () => {
    const current = await selectedIssue(issueNumber);
    const blocked = current.labels.some((label) => label.name === "state:blocked");
    const ready = current.labels.some((label) => label.name === "ready-for-agent");
    if (!blocked && ready) return;
    execFileSync("gh", [
      "issue", "edit", String(issueNumber),
      ...(blocked ? ["--remove-label", "state:blocked"] : []),
      ...(ready ? [] : ["--add-label", "ready-for-agent"]),
    ], { stdio: "inherit" });
  });
  const repair = journal.repair;
  if (!repair) return journal;
  return await transitionSequentialTaskJournal(gitCommonDir, journal, {
    repair: { state: repair.state, epochs: repair.epochs },
    status: "active",
  });
};
const scheduleRequiredCommandRepair = async (journal, phaseName, semanticFingerprint) => {
  const phase = journal.phases.find((candidate) => candidate.name === phaseName);
  const failureReceipt = phase?.failureReceipt;
  if (failureReceipt === undefined) return { journal, blocked: false };
  const previous = journal.repair?.epochs.at(-1);
  const semanticChanged = previous !== undefined && previous.semanticFingerprint !== semanticFingerprint;
  if (semanticChanged || (previous !== undefined && previous.semanticFingerprint === undefined)) {
    const branchHead = hostGit(["rev-parse", journal.branch], { encoding: "utf8" }).trim();
    const reopened = {
      state: "scheduled",
      ...(journal.repair?.state === "blocked" ? { reopenedFromBlocked: true } : {}),
      epochs: [{
        epoch: 1,
        phase: phaseName,
        branch: journal.branch,
        startSha: branchHead,
        failureReceipt,
        semanticFingerprint,
        state: "scheduled",
      }],
    };
    return {
      journal: await transitionSequentialTaskJournal(gitCommonDir, journal, { repair: reopened, status: "active" }),
      blocked: false,
    };
  }
  const sameFailure = previous !== undefined && repairFailureFingerprint(previous.phase, previous.failureReceipt) === repairFailureFingerprint(phaseName, failureReceipt);
  const exhausted = journal.repair?.epochs.length === MAX_REQUIRED_COMMAND_REPAIR_EPOCHS;
  if (journal.repair?.state === "blocked" || sameFailure || exhausted) {
    const existingEpochs = journal.repair?.epochs ?? [];
    const blockedEpochs = journal.repair?.state === "blocked"
      ? existingEpochs
      : existingEpochs.length < MAX_REQUIRED_COMMAND_REPAIR_EPOCHS
        ? [...existingEpochs.slice(0, -1), { ...existingEpochs.at(-1), state: "blocked" }, {
            epoch: existingEpochs.length + 1,
            phase: phaseName,
            branch: journal.branch,
            startSha: hostGit(["rev-parse", journal.branch], { encoding: "utf8" }).trim(),
            failureReceipt,
            semanticFingerprint,
            state: "blocked",
          }]
        : [...existingEpochs.slice(0, -1), { ...existingEpochs.at(-1), failureReceipt, state: "blocked" }];
    const blockedRepair = { state: "blocked", epochs: blockedEpochs };
    return {
      journal: journal.repair?.state === "blocked"
        ? journal
        : await transitionSequentialTaskJournal(gitCommonDir, journal, {
            repair: blockedRepair,
            status: "failed",
          }),
      blocked: true,
    };
  }
  const epoch = (journal.repair?.epochs.length ?? 0) + 1;
  const repair = {
    state: "scheduled",
    epochs: [
      ...(journal.repair?.epochs ?? []),
      {
        epoch,
        phase: phaseName,
        branch: journal.branch,
        startSha: hostGit(["rev-parse", journal.branch], { encoding: "utf8" }).trim(),
        failureReceipt,
        semanticFingerprint,
        state: "scheduled",
      },
    ],
  };
  return {
    journal: await transitionSequentialTaskJournal(gitCommonDir, journal, { repair, status: "active" }),
    blocked: false,
  };
};

const requiredCommandRepairComment = (issueNumber, phaseName, failureReceipt) => {
  const boundedEvidence = failureDiagnosticFor(failureReceipt?.failureSummary, 4_000).trim() || "(no failure evidence retained)";
  return [
    "<!-- goocastle-repair-blocked:" + String(issueNumber) + ":" + phaseName + " -->",
    "",
    "Goocastle blocked this ticket after the bounded repair budget was exhausted for the required command gate.",
    "The failure receipt and task branch provenance remain preserved; inspect the branch and repair the package before retrying.",
    "",
    "Bounded failure evidence:",
    boundedEvidence,
  ].join("\n");
};
const reconcileBlockedRequiredCommandRepair = async (journal, issueNumber) => {
  const latest = journal.repair?.epochs.at(-1);
  if (latest === undefined) return;
  const comment = requiredCommandRepairComment(issueNumber, latest.phase, latest.failureReceipt);
  await retryGitHub("required command repair escalation", async () => {
    const current = await selectedIssue(issueNumber);
    const blocked = current.labels.some((label) => label.name === "state:blocked");
    const ready = current.labels.some((label) => label.name === "ready-for-agent");
    if (!current.comments.some((entry) => entry.body === comment)) {
      execFileSync("gh", ["issue", "comment", String(issueNumber), "--body", comment], { stdio: "inherit" });
    }
    if (!blocked || ready) {
      execFileSync("gh", [
        "issue", "edit", String(issueNumber),
        ...(blocked ? [] : ["--add-label", "state:blocked"]),
        ...(ready ? ["--remove-label", "ready-for-agent"] : []),
      ], { stdio: "inherit" });
    }
  });
};

const reexecutionRecoveryCommand = (state) => {
  const argumentsForNode = [process.execPath, ...process.execArgv, ...process.argv.slice(1)];
  const runtimeEnvironment = [
    REEXECUTION_STATE_ENVIRONMENT + "=" + JSON.stringify(state),
    ...(process.env[SELF_HOSTED_RUNTIME_ROOT_ENVIRONMENT] === undefined
      ? []
      : [SELF_HOSTED_RUNTIME_ROOT_ENVIRONMENT + "=" + process.env[SELF_HOSTED_RUNTIME_ROOT_ENVIRONMENT]]),
    ...(process.env.GOOCASTLE_MODULE_URL === undefined
      ? []
      : ["GOOCASTLE_MODULE_URL=" + process.env.GOOCASTLE_MODULE_URL]),
    ...(process.env.GOOCASTLE_GUIX_MODULE_URL === undefined
      ? []
      : ["GOOCASTLE_GUIX_MODULE_URL=" + process.env.GOOCASTLE_GUIX_MODULE_URL]),
  ];
  return "cd " + shellDisplayQuote(hostWorkTree) + " && env " +
    runtimeEnvironment.map(shellDisplayQuote).join(" ") + " " +
    argumentsForNode.map(shellDisplayQuote).join(" ");
};
const reexecuteDogfoodRunner = (nextTask, attemptedIssues) => {
  const state = {
    version: 1,
    nextTask,
    attemptedIssues: [...attemptedIssues].sort((left, right) => left - right),
  };
  const recovery = reexecutionRecoveryCommand(state);
  if (typeof process.execve !== "function") {
    throw new Error(
      "The integrated runner cannot safely refresh this Node process. Completed journals are preserved and will not be repeated. Restart with: " + recovery,
    );
  }
  console.log("Restarting the runner after integration so subsequent tasks use the integrated runtime and configuration.");
  try {
    process.execve(process.execPath, [process.execPath, ...process.execArgv, ...process.argv.slice(1)], {
      ...process.env,
      [REEXECUTION_STATE_ENVIRONMENT]: JSON.stringify(state),
    });
  } catch (error) {
    throw new Error(
      "Could not safely restart after integration. Completed journals are preserved and will not be repeated. Restart with: " + recovery,
      { cause: error },
    );
  }
  throw new Error(
    "The integrated runner returned without refreshing. Completed journals are preserved and will not be repeated. Restart with: " + recovery,
  );
};

const attemptedIssues = new Set(reexecutionState.attemptedIssues);
// An explicit blocked-repair request opens at most one fresh bounded window
// per issue in this invocation. If that window exhausts again, leave the
// journal terminally blocked until a later explicit command.
const explicitlyRecoveredBlockedIssues = new Set();
// Reconcile before either resumed work or fresh selection. A prior executor
// cannot be assumed live after this scheduler starts, and a stale heartbeat is
// converted to a durable, actionable terminal receipt before any new phase.
await reconcileAbandonedPhases();
for (let task = reexecutionState.nextTask; task <= MAX_TASKS; task += 1) {
  let journal = await incompleteJournal();
  if (journal && !RESUME_ONLY && journal.phases.some((phase) => phase.failureReceipt?.kind === "stalled")) {
    // A terminal issue label is authoritative even when the retained journal
    // has an intentionally manual stalled-worktree receipt.  Preserve that
    // state, but do not let already-blocked work starve a later eligible
    // issue from the queue.
    const stalledIssue = await selectedIssue(journal.issueNumber);
    if (stalledIssue.state === "OPEN" && hasTerminalBlockedLabel(stalledIssue)) {
      deferredJournalIssues.add(journal.issueNumber);
      terminallyBlockedJournalIssues.add(journal.issueNumber);
      attemptedIssues.add(journal.issueNumber);
      console.log(
        "Skipping open terminally blocked stalled journal #" + journal.issueNumber +
        " (state:blocked); its preserved journal and worktree remain unchanged.",
      );
      task -= 1;
      continue;
    }
    manuallyRecoverableJournalIssues.add(journal.issueNumber);
    deferredJournalIssues.add(journal.issueNumber);
    console.error(
      "Journal #" + journal.issueNumber + " has a stalled executor receipt. Automatic retry is disabled because idempotence and worktree ownership have not been proven. " +
      "Run preflight (git -C preserved-worktree status), then resume explicitly with: " + resumeRecoveryCommand(),
    );
    task -= 1;
    continue;
  }
  if (!journal) {
    if (missingBranchManualJournalIssues.size > 0) {
      const manual = [...missingBranchManualJournalIssues].sort((left, right) => left - right);
      console.error(
        "Missing task branches with ambiguous work remain for: " + manual.map((number) => "#" + number).join(", ") + ". " +
        "Automatic recovery is disabled. Run exactly: " + MISSING_BRANCH_MANUAL_ACTION,
      );
      process.exitCode = 1;
      break;
    }
    // A failed phase deliberately remains retryable, even when this invocation
    // is resume-only. Check this boundary before the no-journal message so a
    // second failed attempt cannot be reported as successful recovery.
    if (retryableFailedPhaseIssues.size > 0 || manuallyRecoverableJournalIssues.size > 0) {
      const retryable = [...retryableFailedPhaseIssues].sort((left, right) => left - right);
      const manual = [...manuallyRecoverableJournalIssues].sort((left, right) => left - right);
      const blocked = [...terminallyBlockedJournalIssues].sort((left, right) => left - right);
      console.error(
        (retryable.length === 0 ? "" : "Retryable failed phase journals remain: " + retryable.map((number) => "#" + number).join(", ") + ". ") +
        (manual.length === 0 ? "" : "Manually recoverable journals remain: " + manual.map((number) => "#" + number).join(", ") + ". ") +
        (blocked.length === 0 ? "" : "Terminally blocked journals were skipped and preserved: " + blocked.map((number) => "#" + number).join(", ") + ". ") +
        "No fresh issue will start in this invocation. Resume with: " + resumeRecoveryCommand(),
      );
      process.exitCode = 1;
      break;
    }
    if (RESUME_ONLY) {
      // Resume-only mode is strictly recovery-only. It must not consume the
      // pacing boundary left by an earlier delivery when there is no journal to
      // resume, and it must not wait merely to report that recovery is done.
      if (terminallyBlockedJournalIssues.size > 0) {
        const blocked = [...terminallyBlockedJournalIssues].sort((left, right) => left - right);
        console.log(
          "No retryable " + WORKFLOW_NAME + " journals remain. Terminally blocked journals were skipped and preserved: " +
            blocked.map((number) => "#" + number).join(", ") + ".",
        );
      } else {
        console.log("No incomplete " + WORKFLOW_NAME + " journals remain.");
      }
      break;
    }
    // A completed ticket leaves a durable eligibility boundary. Reconcile it
    // before any fresh issue list/view request; an incomplete journal is the
    // same-ticket resume path and must remain immediate.
    const completedAt = await latestCompletedBoundary();
    if (completedAt !== undefined) {
      // Backfill state for a completed journal produced before durable pacing
      // was available, including a manually reconciled delivery boundary.
      await persistInterTaskDelay(gitCommonDir, projectConfig.taskLimits.interTaskDelayMs, { now: () => completedAt });
    }
    await reconcileInterTaskDelay(gitCommonDir, projectConfig.taskLimits.interTaskDelayMs, { log: console.log });
  }
  let issue;
  let issueContext;
  let specification;
  let resolvedGooflow;
  let reopenedBlockedRepair = false;
  if (journal) {
    if (deliveryComplete(journal)) {
      // A delivered journal needs no forge snapshot, specification approval,
      // Gooflow lookup, or base-branch check. Those delivery concerns must not
      // prevent a newer incomplete journal from recovering.
      issue = { number: journal.issueNumber, title: "cleanup-only recovery" };
      attemptedIssues.add(journal.issueNumber);
      console.log("\n=== Reconciling cleanup for delivered #" + issue.number + " from journal ===\n");
    } else {
    issue = await selectedIssue(journal.issueNumber);
    // A forge-closed issue is an authoritative terminal disposition.  Its
    // preserved journal may predate the delivery (or be a stale failed
    // replay), but it must never trigger branch reconciliation or prevent
    // unrelated eligible work from starting.
    if (issue.state === "CLOSED") {
      // The close request may have reached GitHub before its transport
      // failed.  A live CLOSED state is the durable receipt for that host
      // boundary, so finalize it before performing ordinary cleanup.
      journal = await reconcileClosedRecoveryJournal(journal, issue.number);
      attemptedIssues.add(issue.number);
      console.log(
        "Skipping closed issue #" + issue.number +
        "; its preserved journal is recorded complete without replay.",
      );
      task -= 1;
      continue;
    }
    if (issue.state === "OPEN" && journal.repair?.state === "blocked") {
      // Resolve the current Gooflow before honoring a terminal repair state.
      // The old ordering made a repaired proof command invisible to resume.
      resolvedGooflow = await resolveForIssue(issue);
      // Preserve both the issue-specification and Gooflow selection
      // boundaries before publishing any external reopening label. A changed
      // issue contract or workflow selection must still fail closed.
      const repairExplanation = validateIssueForWorkflow(issue, resolvedGooflow.workflow, { reportWarnings: false });
      if (journal.specification && (
        journal.specification.policyVersion !== repairExplanation.policyVersion ||
        journal.specification.policyDigest !== repairExplanation.policyDigest ||
        journal.specification.specificationDigest !== repairExplanation.specificationDigest ||
        journal.specification.mode !== repairExplanation.policy.mode
      ) && !SPECIFICATION_OVERRIDE) {
        throw new Error(
          "Issue #" + issue.number + " specification changed since the task was journaled (body or policy digest differs). " +
            "Review the preserved branch and journal with goocastle status, then rerun with GOOCASTLE_SPECIFICATION_OVERRIDE=1 for an explicit audited decision.",
        );
      }
      const latestRepair = journal.repair.epochs.at(-1);
      const currentRepairWorkflow = resolvedGooflow.workflow === undefined
        ? undefined
        : materializeIssueWorkflow(resolvedGooflow.workflow, issue);
      const selectedGooflow = resolvedGooflow.workflow?.name ?? "template";
      const selectedAgents = currentRepairWorkflow === undefined ? [] : agentProvenance(currentRepairWorkflow);
      const gooflowChanged = journal.gooflow && (
        journal.gooflow.workflow !== selectedGooflow ||
        journal.gooflow.bypassed !== resolvedGooflow.bypassed ||
        (journal.gooflow.source !== undefined && journal.gooflow.source !== resolvedGooflow.selection.source) ||
        (journal.gooflow.schemaVersion !== undefined && journal.gooflow.schemaVersion !== resolvedGooflow.selection.schemaVersion) ||
        (journal.gooflow.override !== undefined && journal.gooflow.override !== resolvedGooflow.selection.override) ||
        (journal.gooflow.agents !== undefined && JSON.stringify(journal.gooflow.agents) !== JSON.stringify(selectedAgents))
      );
      if (gooflowChanged) {
        throw new Error(
          "Gooflow selection for #" + issue.number + " changed from " +
            JSON.stringify(journal.gooflow.workflow) + " (bypassed=" + String(journal.gooflow.bypassed) + ") to " +
            JSON.stringify(selectedGooflow) + " (bypassed=" + String(resolvedGooflow.bypassed) + "). Review the journal with goocastle status, then restore the original standard or deliberately start a new task.",
        );
      }
      const repairPhase = currentRepairWorkflow?.phases.find((phase) => phase.name === latestRepair?.phase);
      const canReopen = repairPhase?.type === "command" &&
        currentRepairWorkflow?.requiredPhases?.includes(latestRepair?.phase) === true &&
        (latestRepair.phase === "safe-package-proof" ||
          currentRepairWorkflow.evidence?.proofPhase === latestRepair.phase ||
          currentRepairWorkflow.evidence?.capturePhase === latestRepair.phase);
      const explicitRecoveryAlreadyUsed = RECOVER_BLOCKED && explicitlyRecoveredBlockedIssues.has(issue.number);
      if (canReopen && latestRepair !== undefined && !explicitRecoveryAlreadyUsed) {
        const semanticFingerprint = repairSemanticFingerprintFor(currentRepairWorkflow, latestRepair.phase);
        const reopened = await reopenBlockedRequiredCommandRepair(journal, latestRepair.phase, semanticFingerprint);
        journal = reopened.journal;
        if (reopened.reopened) {
          reopenedBlockedRepair = true;
          journal = await reconcileReopenedRequiredCommandRepair(journal, issue.number);
          if (RECOVER_BLOCKED) explicitlyRecoveredBlockedIssues.add(issue.number);
          console.log(
            "Reopened bounded repair epoch for #" + issue.number + " after " +
              (RECOVER_BLOCKED ? "the explicit maintainer recovery request for " : "the runner or Gooflow semantics changed for ") +
              JSON.stringify(latestRepair.phase) + "; implementation and audit will run before the proof is retried.",
          );
        } else {
          await reconcileBlockedRequiredCommandRepair(journal, issue.number);
          deferredJournalIssues.add(issue.number);
          terminallyBlockedJournalIssues.add(issue.number);
          attemptedIssues.add(issue.number);
          console.log(
            "Skipping open issue #" + issue.number +
              " with durable bounded repair state:blocked; its preserved journal and worktree remain unchanged.",
          );
          task -= 1;
          continue;
        }
      } else {
        if (RECOVER_BLOCKED && !canReopen) {
          throw new Error(
            "Cannot recover terminally blocked journal for #" + issue.number + ": " +
              JSON.stringify(latestRepair?.phase ?? "unknown") +
              " is not a required package-proof or runtime-evidence command gate. " +
              "Review the preserved journal and branch; no phase was replayed.",
          );
        }
        await reconcileBlockedRequiredCommandRepair(journal, issue.number);
        deferredJournalIssues.add(issue.number);
        terminallyBlockedJournalIssues.add(issue.number);
        attemptedIssues.add(issue.number);
        console.log(
          "Skipping open issue #" + issue.number +
            " with durable bounded repair state:blocked; its preserved journal and worktree remain unchanged.",
        );
        task -= 1;
        continue;
      }
    }
    if (journal.repair?.reopenedFromBlocked === true && !RESUME_ONLY) {
      throw new Error(
        "Terminal bounded repair for #" + issue.number + " was explicitly reopened but its external recovery receipt is incomplete. " +
          "Run: " + shellDisplayCommand("goocastle", ["resume", hostWorkTree, "--recover-blocked"]),
      );
    }
    if (journal.repair?.reopenedFromBlocked === true) {
      reopenedBlockedRepair = true;
      journal = await reconcileReopenedRequiredCommandRepair(journal, issue.number);
    }
    // A retained journal is recovery state, not authority to resume an issue
    // whose current terminal disposition says it must remain blocked. Check the
    // live issue before any branch, journal, or sandbox recovery action.
    if (issue.state === "OPEN" && hasTerminalBlockedLabel(issue) && !reopenedBlockedRepair) {
      deferredJournalIssues.add(issue.number);
      terminallyBlockedJournalIssues.add(issue.number);
      attemptedIssues.add(issue.number);
      console.log(
        "Skipping open terminally blocked issue #" + issue.number +
          " (state:blocked); its preserved journal and worktree remain unchanged.",
      );
      // A skipped terminal journal must not consume an execution slot; continue
      // this run with the next currently eligible issue.
      task -= 1;
      continue;
    }
    if (journal.baseBranch !== baseBranch) {
      throw new Error("Journal for #" + journal.issueNumber + " expects base branch " + journal.baseBranch + "; check out that branch and run goocastle resume");
    }
    issueContext = snapshotGitHubIssue(issue, journal.issueNumber);
    // Resumption must use the same routed policy as fresh selection.  A
    // research Gooflow may deliberately disable the repository's delivery
    // specification policy, so validating before routing rejects a valid
    // journal solely because it was interrupted.
    resolvedGooflow = await resolveForIssue(issue);
    journal = await recoverMissingTaskBranch(journal);
    if (journal.branchRecovery?.state === "manual") {
      manuallyRecoverableJournalIssues.add(journal.issueNumber);
      missingBranchManualJournalIssues.add(journal.issueNumber);
      deferredJournalIssues.add(journal.issueNumber);
      task -= 1;
      continue;
    }
    const explanation = validateIssueForWorkflow(issue, resolvedGooflow.workflow);
    let decision = "initial";
    if (journal.specification && (
      journal.specification.policyVersion !== explanation.policyVersion ||
      journal.specification.policyDigest !== explanation.policyDigest ||
      journal.specification.specificationDigest !== explanation.specificationDigest ||
      journal.specification.mode !== explanation.policy.mode
    )) {
      if (!SPECIFICATION_OVERRIDE) {
        throw new Error(
          "Issue #" + issue.number + " specification changed since the task was journaled (body or policy digest differs). " +
          "Review the preserved branch and journal with goocastle status, then rerun with GOOCASTLE_SPECIFICATION_OVERRIDE=1 for an explicit audited decision.",
        );
      }
      decision = "audited-change";
      console.error("WARNING: accepting the changed specification for #" + issue.number + " because GOOCASTLE_SPECIFICATION_OVERRIDE=1 was explicitly set; review the preserved branch and criteria.");
    }
    specification = specificationProvenance(explanation, decision);
    attemptedIssues.add(issue.number);
    console.log("\n=== Resuming #" + issue.number + " " + issue.title + " from journal ===\n");
    const failedPhaseNames = journal.phases
      .filter((phase) => phase.state === "failed")
      .map((phase) => phase.name);
    if (failedPhaseNames.length > 0) {
      console.log(
        "Retrying failed sequential phase(s) " + failedPhaseNames.map((name) => JSON.stringify(name)).join(", ") +
          " for #" + issue.number + "; completed phase receipts and issue identity are preserved.",
      );
    } else if (journal.status === "failed") {
      console.log(
        "Resuming manually recoverable journal state for #" + issue.number +
          "; delivery and recovery boundaries are preserved.",
      );
    }
    }
  } else {
    const selected = await nextActionableIssue(attemptedIssues);
    if (!selected) {
      console.log("No actionable ready-for-agent issues remain.");
      break;
    }
    issue = selected.issue;
    issueContext = snapshotGitHubIssue(issue, issue.number);
    // The forge can report a just-closed issue as open briefly. Record the
    // selection before any further asynchronous work so this invocation never
    // starts a second epoch for the same issue.
    attemptedIssues.add(issue.number);
    const explanation = selected.explanation;
    specification = specificationProvenance(explanation);
    // nextActionableIssue refreshed, routed, and reported this exact forge
    // snapshot immediately before returning it. Reuse that provenance instead
    // of reporting the same selection a second time.
    resolvedGooflow = selected.resolved;
    const branch = "goocastle/" + WORKFLOW_NAME + "/issue-" + issue.number + "-" + Date.now() + "-" + task;
    const baseHead = hostGit(["rev-parse", "HEAD"], { encoding: "utf8" }).trim();
    journal = await createSequentialTaskJournal({
      gitCommonDir,
      workflow: WORKFLOW_NAME,
      issueNumber: issue.number,
      baseSha: baseHead,
      baseBranch,
      branch,
      specification,
    });
    console.log("\n=== Task " + task + "/" + MAX_TASKS + ": #" + issue.number + " " + issue.title + " ===\nScheduler rationale: " + selected.rationale + "\n");
  }
  const branch = journal.branch;
  let materializedGooflow;
  let dispositionPolicy;
  let baseHead = journal.reconciliation?.state === "complete"
    ? journal.reconciliation.reconciledBaseSha
    : journal.baseSha;
  const hostGitConfig = await readFile(hostGitConfigPath);
  let hostGitConfigRestored = false;
  const restoreHostGitConfig = async () => {
    if (hostGitConfigRestored) return;
    await writeFile(hostGitConfigPath, hostGitConfig);
    hostGitConfigRestored = true;
  };

  let sandbox;
  let evidenceSandbox;
  let taskWorktree;
  let integration = journal.issueClose === "complete"
    ? "closed"
    : journal.push === "complete"
      ? "pushed"
      : journal.merge === "complete" ? "merged" : "not-started";
  let closeResult;
  let refreshAfterIntegration = false;
  let freshAttemptPhaseNames = new Set();
  const failureSummaryFor = (error) => {
    const visited = new Set();
    let current = error;
    for (let depth = 0; depth < 8 && current && typeof current === "object"; depth += 1) {
      if (visited.has(current)) return undefined;
      visited.add(current);
      if (current.failureSummary && typeof current.failureSummary === "object") return current.failureSummary;
      current = current.cause;
    }
    return undefined;
  };
  const daemonOperationFor = (error) => {
    const visited = new Set();
    let current = error;
    for (let depth = 0; depth < 8 && current && typeof current === "object"; depth += 1) {
      if (visited.has(current)) return undefined;
      visited.add(current);
      if (current.guixDaemonOperation && typeof current.guixDaemonOperation === "object") return current.guixDaemonOperation;
      current = current.cause;
    }
    return undefined;
  };
  try {
    if (deliveryComplete(journal)) {
      journal = await reconcileDeliveredCleanup(journal, issue.number);
      console.log("Completed delivery cleanup for #" + issue.number + ".");
      await persistInterTaskDelay(gitCommonDir, projectConfig.taskLimits.interTaskDelayMs);
      // Do not run base-advance reconciliation, phases, remote checks, or an
      // issue-close retry for an already-delivered cleanup-only journal.
      continue;
    }
    // Resolve the non-delivery policy before reconciliation: it determines
    // whether a failed sandbox result is a disposable handoff or user work.
    // Delivered cleanup journals intentionally have no routed workflow here.
    materializedGooflow = resolvedGooflow.workflow
      ? materializeIssueWorkflow(resolvedGooflow.workflow, issue)
      : undefined;
    dispositionPolicy = materializedGooflow?.disposition;
    journal = await reconcileBaseAdvance(journal, issue.number, dispositionPolicy);
    baseHead = journal.reconciliation?.state === "complete"
      ? journal.reconciliation.reconciledBaseSha
      : journal.baseSha;
    const failureEvidenceFor = (candidateJournal) => {
      const failed = [...candidateJournal.phases].reverse().find((phase) => phase.state === "failed" && phase.failureReceipt?.failureSummary);
      return failed?.failureReceipt?.failureSummary === undefined ? "" : failureDiagnosticFor(failed.failureReceipt.failureSummary);
    };
    const promptArgs = {
      ISSUE_NUMBER: String(issue.number),
      ISSUE_TITLE: issueContext.title,
      ISSUE_CONTEXT: renderGitHubIssueContext(issueContext),
      BRANCH: branch,
      BASE_BRANCH: baseBranch,
      CODING_STANDARDS: codingStandards,
      FAILURE_EVIDENCE: failureEvidenceFor(journal),
    };
    const evidenceConfig = materializedGooflow?.evidence === undefined
      ? undefined
      : await resolveGooflowEvidence(materializeGooflowEvidence(materializedGooflow.evidence, promptArgs), hostWorkTree, issue.number);
    if (journal.runtimeEvidence !== undefined && evidenceConfig === undefined &&
      (journal.runtimeEvidence.artifact !== "complete" || journal.runtimeEvidence.comment !== "complete")) {
      throw new Error("Runtime evidence receipt for #" + issue.number + " is pending but the selected Gooflow no longer declares it; restore the original evidence configuration before resuming");
    }
    // The generated template fallback has the same hard phase wall-time
    // contract as a materialized Gooflow. Keep the legacy resource wall cap
    // out of the phase invocation so timeout receipts remain distinct from
    // resource-limit receipts.
    const phaseRuntimeLimits = (() => {
      const { wallTimeMs: _wallTimeMs, ...limits } = projectConfig.runtimeLimits;
      return limits;
    })();
    // A running record has no completion evidence.  A process can die after
    // committing but before the phase callback, so branch movement is not a
    // substitute for a successful required command or agent completion.
    // Leave it pending and rerun it on resume. Recovered phases additionally
    // pass through a durable `fresh` record before an executor is launched.
    const templatePhases = [
        {
          type: "agent",
          name: "implement",
          stopOnNoCommits: true,
          run: {
            agent: configuredAgent(),
            promptFile: ".goocastle/implement-prompt.md",
            promptArgs,
            maxIterations: 1,
            idleTimeoutMs: projectConfig.timeouts.idleMs,
            timeoutMs: projectConfig.timeouts.wallMs,
            completionTimeoutMs: projectConfig.timeouts.completionMs,
            runtimeLimits: phaseRuntimeLimits,
            logging: projectConfig.logging,
          },
        },
        {
          type: "agent",
          name: "review",
          run: {
            agent: configuredAgent(),
            promptFile: ".goocastle/review-prompt.md",
            promptArgs,
            maxIterations: 1,
            idleTimeoutMs: projectConfig.timeouts.idleMs,
            timeoutMs: projectConfig.timeouts.wallMs,
            completionTimeoutMs: projectConfig.timeouts.completionMs,
            runtimeLimits: phaseRuntimeLimits,
            logging: projectConfig.logging,
          },
        },
      ];
    // Specification, dependency, and exact repository-local Gooflow routing
    // have all passed before this journal or sandbox can create task state.
    const selectedGooflow = resolvedGooflow.workflow?.name ?? "template";
    const selectedAgents = materializedGooflow
      ? agentProvenance(materializedGooflow)
      : templateAgentProvenance(templatePhases);
    for (const agent of selectedAgents) {
      console.log(
        "Gooflow agent phase " + JSON.stringify(agent.name) +
          ": provider=" + JSON.stringify(agent.provider) +
          ", model=" + JSON.stringify(agent.model) +
          ", effort=" + JSON.stringify(agent.effort),
      );
    }
    // Journals written before routing provenance was added contain only the
    // workflow name and bypass flag. Preserve their resumability when the
    // selected workflow is unchanged, then persist the richer provenance.
    const gooflowChanged = journal.gooflow && (
      journal.gooflow.workflow !== selectedGooflow ||
      journal.gooflow.bypassed !== resolvedGooflow.bypassed ||
      (journal.gooflow.source !== undefined && journal.gooflow.source !== resolvedGooflow.selection.source) ||
      (journal.gooflow.schemaVersion !== undefined && journal.gooflow.schemaVersion !== resolvedGooflow.selection.schemaVersion) ||
      (journal.gooflow.override !== undefined && journal.gooflow.override !== resolvedGooflow.selection.override) ||
      (journal.gooflow.agents !== undefined && JSON.stringify(journal.gooflow.agents) !== JSON.stringify(selectedAgents))
    );
    if (gooflowChanged) {
      throw new Error(
        "Gooflow selection for #" + issue.number + " changed from " +
          JSON.stringify(journal.gooflow.workflow) + " (bypassed=" + String(journal.gooflow.bypassed) + ") to " +
          JSON.stringify(selectedGooflow) + " (bypassed=" + String(resolvedGooflow.bypassed) + "). Review the journal with goocastle status, then restore the original standard or deliberately start a new task.",
      );
    }
    journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
      specification,
      gooflow: {
        workflow: selectedGooflow,
        bypassed: resolvedGooflow.bypassed,
        source: resolvedGooflow.selection.source,
        ...(resolvedGooflow.selection.schemaVersion === undefined ? {} : { schemaVersion: resolvedGooflow.selection.schemaVersion }),
        ...(resolvedGooflow.selection.override === undefined ? {} : { override: resolvedGooflow.selection.override }),
        ...(selectedAgents.length === 0 ? {} : { agents: selectedAgents }),
      },
    });
    const configuredPhases = materializedGooflow
      ? issueGooflowPhases(materializedGooflow, projectConfig, promptArgs, {
          directory: hostWorkTree,
          agentCommands: codexBinDirectory ? { codex: codexCommand } : {},
          ...(dispositionPolicy === undefined ? {} : {
            hostPromptSuffix: "HOST-ENFORCED DISPOSITION HANDOFF: Before completing this phase, write the required version 1 disposition JSON to " +
              JSON.stringify(dispositionPolicy.resultPath) + ". The disposition must be one of " +
              JSON.stringify(dispositionPolicy.allowed.map((option) => option.name)) + ". The finding must be non-empty, at most 10000 characters, and the complete UTF-8 JSON file at most 16384 bytes. Summarize evidence; do not enumerate large dependency lists. Verify its byte length before completing. This host contract overrides any conflicting repository prompt." +
              (dispositionPolicy.allowed.some((option) => option.implementationTicket?.runtimeEvidence !== undefined)
                ? " If you select a disposition whose implementation ticket declares runtimeEvidence, also include its reviewed runtimeEvidence draft with packageName, artifactPath, runtime.executable, the exact runtime.invocation argv, and runtime.successMarker; without that draft the host refuses to publish the delivery ticket and you must choose an actionable non-delivery disposition instead."
                : ""),
          }),
        })
      : templatePhases;
    // Every executable phase gets the bounded default even when a repository
    // does not opt into an explicit Gooflow liveness override.
    const phases = configuredPhases.map((phase) => ({
      ...phase,
      liveness: phase.liveness ?? defaultSequentialPhaseLiveness,
    }));
    const setup = materializedGooflow
      ? issueGooflowSetup(materializedGooflow, projectConfig)
      : [];
    const requiredGooflowPhases = new Set(materializedGooflow?.requiredPhases ?? []);
    if (evidenceConfig !== undefined) {
      const priorEvidence = journal.runtimeEvidence;
      if (priorEvidence !== undefined && !priorEvidence.legacy && (
        priorEvidence.packageName !== evidenceConfig.packageName ||
        priorEvidence.proofPhase !== evidenceConfig.proofPhase ||
        priorEvidence.capturePhase !== evidenceConfig.capturePhase ||
        priorEvidence.artifactPath !== evidenceConfig.artifactPath ||
        JSON.stringify(priorEvidence.runtime) !== JSON.stringify(evidenceConfig.runtime) ||
        JSON.stringify(priorEvidence.runtimeContract) !== JSON.stringify(evidenceConfig.runtimeContract) ||
        priorEvidence.adapter !== evidenceConfig.adapter
      )) {
        throw new Error("Runtime evidence configuration changed after journaling for #" + issue.number + "; inspect the preserved journal and restore the original package proof/capture configuration before resuming");
      }
      if (priorEvidence === undefined || priorEvidence.legacy) {
        // Pre-assertion journals can be read for recovery but their screenshot
        // is intentionally not trusted as packaged-program proof.  Replace
        // the receipt from the reviewed current contract and replay capture.
        const legacyCapturePhase = priorEvidence?.legacy
          ? phases.find((phase) => phase.name === evidenceConfig.capturePhase)
          : undefined;
        journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
          ...(legacyCapturePhase === undefined ? {} : {
            phases: journal.phases.map((record) => record.name !== legacyCapturePhase.name ? record : {
              name: record.name,
              state: "fresh",
              attempt: (record.attempt ?? 0) + 1,
              startSha: hostGit(["rev-parse", branch], { encoding: "utf8" }).trim(),
              ...(record.failureHistory === undefined ? {} : { failureHistory: record.failureHistory }),
            }),
          }),
          runtimeEvidence: {
            version: 1,
            packageName: evidenceConfig.packageName,
            proofPhase: evidenceConfig.proofPhase,
            capturePhase: evidenceConfig.capturePhase,
            artifactPath: evidenceConfig.artifactPath,
            runtime: evidenceConfig.runtime,
            ...(evidenceConfig.runtimeContract === undefined ? {} : { runtimeContract: evidenceConfig.runtimeContract }),
            adapter: evidenceConfig.adapter,
            artifact: "pending",
            comment: "pending",
          },
        });
      }
    }
    // A disposition is the terminal receipt for a non-delivery workflow. If
    // interruption follows a completed phase but precedes receipt capture,
    // rerun its idempotent research phases rather than treating phase state as
    // evidence of a host-valid result.
    const dispositionResultRequired = dispositionPolicy !== undefined && journal.disposition === undefined;
    let capturedDisposition;
    const activeRepair = journal.repair?.state === "scheduled" || journal.repair?.state === "running";
    const repairPhaseName = activeRepair ? journal.repair.epochs.at(-1)?.phase : undefined;
    // Gooflows may name their implementation phase after the artifact or
    // language they produce.  The commit requirement is the workflow's
    // explicit implementation signal; retain the first agent fallback for
    // older Gooflows that predate that completion metadata.  Template
    // workflows keep their historical `implement` phase name.
    const implementationPhaseName = materializedGooflow?.phases.find((phase) => phase.type === "agent" && phase.completion?.requiresCommits === true)?.name
      ?? materializedGooflow?.phases.find((phase) => phase.type === "agent")?.name
      ?? "implement";
    const repairPhases = activeRepair
      ? [
          phases.find((phase) => phase.name === implementationPhaseName && phase.type === "agent"),
          phases.find((phase) => phase.name === "edge-case-audit" && phase.type === "agent") ?? phases.find((phase) => phase.type === "agent" && /audit|review/iu.test(phase.name) && phase.name !== implementationPhaseName),
          phases.find((phase) => phase.name === repairPhaseName),
        ].filter((phase, index, candidates) => phase !== undefined && candidates.indexOf(phase) === index)
      : [];
    const defaultProviderStateHomeName = WORKFLOW_NAME + "-issue-" + issue.number;
    let providerStateHomeName = journal.providerStateRecovery?.epochs.at(-1)?.stateHomeName ?? defaultProviderStateHomeName;
    const repeatedAgentPhase = phases.find((phase) => {
      const record = phaseRecord(journal, phase.name);
      return phase.type === "agent" && record?.state === "failed" && record.failureReceipt !== undefined &&
        ((record.failureHistory?.length ?? 0) >= 1 || record.failureReceipt.kind === "provider-interruption");
    });
    if (journal.providerStateRecovery?.state === "blocked") {
      throw new Error(journal.providerStateRecovery.recovery ??
        "Fresh provider-state recovery is terminally blocked; inspect the preserved state homes and resume only after manual repair.");
    }
    if (repeatedAgentPhase !== undefined) {
      const priorRecovery = journal.providerStateRecovery;
      const latestRecovery = priorRecovery?.epochs.at(-1);
      // A crash after quarantine but before the phase starts leaves a
      // scheduled epoch. Reuse that already-isolated home rather than moving
      // it again or consuming another automatic retry.
      if (priorRecovery?.state === "active" && latestRecovery?.phase === repeatedAgentPhase.name && latestRecovery.state === "scheduled") {
        providerStateHomeName = latestRecovery.stateHomeName;
      } else if ((priorRecovery?.epochs.length ?? 0) >= providerStateRecoveryMaxEpochs) {
        const recovery = "Fresh provider-state recovery exhausted after " + providerStateRecoveryMaxEpochs +
          " isolated retry attempts for agent phase " + JSON.stringify(repeatedAgentPhase.name) +
          ". Preserved state homes: " + JSON.stringify((priorRecovery?.epochs ?? []).map((entry) => entry.quarantinePath ?? entry.stateHomeName)) +
          ". Inspect the preserved branch and state homes, then resume with: " + resumeRecoveryCommand();
        const epochs = (priorRecovery?.epochs ?? []).map((entry, index, entries) =>
          index === entries.length - 1 ? { ...entry, state: "blocked" } : entry);
        journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
          status: "failed",
          failure: recovery,
          providerStateRecovery: { state: "blocked", epochs, recovery },
          phases: journal.phases.map((record) => record.name !== repeatedAgentPhase.name ? record : {
            ...record,
            failureReceipt: { ...record.failureReceipt, recovery },
          }),
        });
        throw new Error(recovery);
      } else {
        const sourceStateHomeName = latestRecovery?.stateHomeName ?? defaultProviderStateHomeName;
        const timestamp = new Date().toISOString().replace(/[-:]/gu, "").replace(/\.\d{3}Z$/u, "Z");
        const quarantinePath = await quarantineManagedStateHome({
          gitCommonDir,
          name: sourceStateHomeName,
          timestamp,
        });
        const epoch = (priorRecovery?.epochs.length ?? 0) + 1;
        providerStateHomeName = defaultProviderStateHomeName + ".fresh-" + epoch;
        journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
          status: "active",
          providerStateRecovery: {
            state: "active",
            epochs: [
              ...(priorRecovery?.epochs ?? []),
              {
                epoch,
                phase: repeatedAgentPhase.name,
                stateHomeName: providerStateHomeName,
                ...(quarantinePath === undefined ? {} : { quarantinePath }),
                state: "scheduled",
              },
            ],
          },
        });
        console.warn(
          "Repeated agent-phase failure for #" + issue.number + "; preserved provider state at " +
            (quarantinePath ?? "(no prior state home)") + " and scheduled fresh isolated state " + providerStateHomeName + ".",
        );
      }
    }
    const pendingPhases = phases.filter((phase) => {
      const record = phaseRecord(journal, phase.name);
      return activeRepair
        ? repairPhases.some((candidate) => candidate?.name === phase.name)
        : dispositionResultRequired || record?.state !== "complete" || record?.stoppedEarly === true;
    });
    const freshAttemptPhases = activeRepair
      ? repairPhases
      : pendingPhases.filter((phase) => {
          const record = phaseRecord(journal, phase.name);
          return record?.state === "failed" || record?.state === "fresh";
        });
    // A capture can complete before the host commits its declared artifact.
    // Recreate the task-worktree boundary on resume even though no executable
    // phase remains, so the artifact receipt can finish without replaying the
    // package proof or screenshot command.
    const evidenceArtifactPending = evidenceConfig !== undefined && journal.runtimeEvidence?.artifact !== "complete";
    if (pendingPhases.length > 0 || evidenceArtifactPending) {
      if (freshAttemptPhases.length > 0) {
        const freshNames = new Set(freshAttemptPhases.map((phase) => phase.name));
        const freshStartedAt = new Date().toISOString();
        journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
          status: "active",
          phases: journal.phases.map((record) => {
            if (!freshNames.has(record.name)) return record;
            const phase = phases.find((candidate) => candidate.name === record.name);
            const phaseLiveness = phase?.liveness ?? defaultSequentialPhaseLiveness;
            const history = [
              ...(record.failureHistory ?? []),
              ...(record.failureReceipt === undefined ? [] : [record.failureReceipt]),
            ].slice(-sequentialPhaseFailureHistoryLimit);
            const attempt = record.attempt === undefined
              ? record.state === "failed" ? 2 : 1
              : record.attempt + 1;
            return {
              name: record.name,
              state: "fresh",
              attempt,
              // Preserve the original boundary when an operator has repaired
              // a failed phase on its task branch.  The completion callback
              // can then verify and account for those signed commits.
              startSha: record.failureHistory !== undefined && record.startSha !== undefined
                ? record.startSha
                : hostGit(["rev-parse", branch], { encoding: "utf8" }).trim(),
              liveness: {
                executorId: EXECUTOR_ID,
                startedAt: freshStartedAt,
                activityAt: freshStartedAt,
                supervisorHeartbeatAt: freshStartedAt,
                expectedPacingMs: phaseLiveness.expectedPacingMs,
                stalledAfterMs: phaseLiveness.stalledAfterMs,
              },
              ...(history.length === 0 ? {} : { failureHistory: history }),
            };
          }),
        });
        freshAttemptPhaseNames = freshNames;
      }
      // Setup commands run before onPhaseStart and are allowed to use Git, so
      // prepare the same signing boundary before the sandbox can execute
      // them. Their commits are recorded separately from agent work.
      const setupSigningBoundary = signingBoundary("setup", "workflow");
      const initialSigningBoundary = pendingPhases.length > 0 && setup.length > 0
        ? setupSigningBoundary
        : pendingPhases.length > 0
        ? signingBoundary("phase", pendingPhases[0].name)
        : signingBoundary("runtime-evidence", evidenceConfig!.capturePhase);
      journal = await prepareCommitSigning(journal, initialSigningBoundary);
      // Sandbox capability access must follow the same materialized workflow
      // that supplies the phases and setup. A repository policy overlay may
      // add or remove a phase capability, so checking the pre-materialized
      // document could leak a secret or make an otherwise valid phase fail.
      const sandboxAccess = sandboxAccessForWorkflow(materializedGooflow);
      // Keep the task worktree owner separate from the disposable Guix
      // sandbox. A failed command must leave the exact linked worktree
      // available for resume; createWorktree reuses it by branch after any
      // base reconciliation. Persist the fresh boundary first so worktree
      // setup failures still leave an actionable phase receipt.
      taskWorktree = await retrySequential(() => createWorktree({
        cwd: hostWorkTree,
        branchStrategy: { type: "branch", branch, base: baseHead },
      }), projectConfig.retryPolicy, { retryable: isTransientSequentialError });
      if (pendingPhases.length > 0) {
        sandbox = await retrySequential(() => taskWorktree.createSandbox({
          name: providerStateHomeName,
          sandbox: guix({
            manifest: codexBinDirectory ? ".goocastle/manifest-external-codex.scm" : ".goocastle/manifest.scm",
            channels: ".goocastle/channels.scm",
            cores: projectConfig.resourcePolicy.cores,
            network: projectConfig.network,
            emulateFhs: projectConfig.resourcePolicy.emulateFhs,
            nesting: projectConfig.resourcePolicy.nesting,
            runtimeLimits: projectConfig.runtimeLimits,
            preserveEnv: sandboxAccess.preserveEnv,
            homeFiles,
            ...(sandboxAccess.requestsGuixDaemon ? { allowGuixDaemonSocket: true } : {}),
            exposes: codexBinDirectory ? [{ hostPath: codexBinDirectory, sandboxPath: "/opt/goocastle-codex" }] : [],
          }),
          env: {
            ...sandboxAccess.environment,
            ...commitSigningEnvironment,
            GOOCASTLE_ISSUE_NUMBER: String(issue.number),
            GOOCASTLE_PHASE_WORKER: "1",
          },
        }), projectConfig.retryPolicy, { retryable: isTransientSequentialError });
      }
      let setupStartSha;
      let setupEvidenceStartSha;
      if (pendingPhases.length > 0) {
        setupStartSha = hostGit(["rev-parse", branch], { encoding: "utf8" }).trim();
        setupEvidenceStartSha = journal.setup?.startSha ?? setupStartSha;
        journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
          setup: { state: "started", startSha: setupEvidenceStartSha },
        });
      }
      let setupObserved = false;
      const phaseCallbacks = {
        onSetupComplete: async () => {
          if (setupObserved) return;
          setupObserved = true;
          let setupHead = hostGit(["rev-parse", branch], { encoding: "utf8" }).trim();
          if (setupHead !== setupStartSha) {
            const signed = await ensureSignedPhaseCommits(journal, setupSigningBoundary, setupStartSha, setupHead);
            journal = signed.journal;
            setupHead = signed.head;
            journal = await recordUnsignedCommit(journal, setupSigningBoundary);
          }
          journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
            setup: { state: "complete", startSha: setupEvidenceStartSha, endSha: setupHead },
          });
        },
        onPhaseStart: async (phase) => {
          journal = await prepareCommitSigning(journal, signingBoundary("phase", phase.name));
          const providerRecovery = journal.providerStateRecovery;
          const providerRecoveryEpoch = providerRecovery?.epochs.at(-1);
          if (providerRecovery?.state === "active" && providerRecoveryEpoch?.phase === phase.name && providerRecoveryEpoch.state === "scheduled") {
            journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
              providerStateRecovery: {
                state: "active",
                epochs: [...providerRecovery.epochs.slice(0, -1), { ...providerRecoveryEpoch, state: "running" }],
              },
            });
          }
          const phaseLiveness = phase.liveness ?? defaultSequentialPhaseLiveness;
          const phaseStartedAt = new Date().toISOString();
          const existingRecord = phaseRecord(journal, phase.name);
          const attempt = existingRecord?.attempt ?? 1;
          // Fresh records are staged for the whole sequential retry batch so
          // setup failures can identify every recovery phase. Refresh the
          // execution boundary here: later phases must not claim commits or
          // liveness from an earlier phase in that batch.
          // A recovered phase can have a signed operator repair after its
          // original execution boundary.  Preserve that boundary so the
          // completion gate can account for the repair rather than replaying
          // an implementation agent solely to manufacture another commit.
          // Newly staged phases have no failure history and still receive a
          // fresh boundary, which keeps ordinary multi-phase batches isolated.
          const startSha = existingRecord?.state === "fresh" && existingRecord.failureHistory === undefined
            ? hostGit(["rev-parse", branch], { encoding: "utf8" }).trim()
            : existingRecord?.startSha ?? hostGit(["rev-parse", branch], { encoding: "utf8" }).trim();
          const liveness = existingRecord?.state === "fresh" && existingRecord.liveness !== undefined
            ? { ...existingRecord.liveness, startedAt: phaseStartedAt, activityAt: phaseStartedAt, supervisorHeartbeatAt: phaseStartedAt, providerProgressAt: undefined }
            : {
                executorId: EXECUTOR_ID,
                startedAt: phaseStartedAt,
                activityAt: phaseStartedAt,
                supervisorHeartbeatAt: phaseStartedAt,
                expectedPacingMs: phaseLiveness.expectedPacingMs,
                stalledAfterMs: phaseLiveness.stalledAfterMs,
              };
          journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
            status: "active",
            ...(evidenceConfig?.capturePhase === phase.name && journal.runtimeEvidence === undefined ? {} : {}),
            phases: [...journal.phases.filter((item) => item.name !== phase.name), {
              name: phase.name,
              state: "running",
              attempt,
              startSha,
              liveness,
              ...(existingRecord?.failureHistory === undefined ? {} : { failureHistory: existingRecord.failureHistory }),
            }],
            ...(evidenceConfig?.capturePhase === phase.name && journal.runtimeEvidence !== undefined ? {
              runtimeEvidence: { ...journal.runtimeEvidence, artifact: "started" },
            } : {}),
          });
          console.log("\n--- " + phase.name + " ---\n");
        },
        onPhaseHeartbeat: async (phase) => {
          const record = phaseRecord(journal, phase.name);
          // The workflow serializes heartbeat callbacks and drains them before
          // completion/failure callbacks, so this cannot resurrect a terminal
          // phase after its durable receipt has been written.
          if (record?.state !== "running" || record.liveness?.executorId !== EXECUTOR_ID) return;
          journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
            phases: journal.phases.map((item) => item.name !== phase.name ? item : {
              ...item,
              liveness: { ...item.liveness, activityAt: new Date().toISOString(), supervisorHeartbeatAt: new Date().toISOString() },
            }),
          });
        },
        onPhaseProgress: async (phase) => {
          const record = phaseRecord(journal, phase.name);
          if (record?.state !== "running" || record.liveness?.executorId !== EXECUTOR_ID) return;
          journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
            phases: journal.phases.map((item) => item.name !== phase.name ? item : {
              ...item,
              liveness: { ...item.liveness, providerProgressAt: new Date().toISOString() },
            }),
          });
        },
        onPhaseComplete: async (phaseResult) => {
          const phaseBeforeComplete = phaseRecord(journal, phaseResult.name);
          const phaseStartSha = phaseBeforeComplete?.startSha;
          let phaseHead = phaseStartSha === undefined
            ? undefined
            : hostGit(["rev-parse", branch], { encoding: "utf8" }).trim();
          const commitCount = phaseResult.type === "agent"
            ? phaseResult.result.commits.length
            : undefined;
          const configuredPhase = phases.find((phase) => phase.name === phaseResult.name);
          const runtimeAssertion = phaseResult.type === "command" && evidenceConfig?.capturePhase === phaseResult.name
            ? validateRuntimeEvidenceCapture(phaseResult.result.stdout, evidenceConfig.runtime)
            : undefined;
          const commandReceipt = phaseResult.type === "command" && configuredPhase?.type === "command" &&
            phaseResult.result.exitCode === 0 && !phaseResult.result.exitReason
            ? { command: configuredPhase.command, exitCode: 0 }
            : undefined;
          const stopReason = phaseResult.type === "agent" ? phaseResult.result.stopReason : undefined;
          if (phaseStartSha !== undefined && phaseHead !== undefined) {
            const signed = await ensureSignedPhaseCommits(journal, signingBoundary("phase", phaseResult.name), phaseStartSha, phaseHead);
            journal = signed.journal;
            phaseHead = signed.head;
          }
          const observedCommitCount = phaseStartSha === undefined || phaseHead === undefined
            ? undefined
            : Number(hostGit(["rev-list", "--count", phaseStartSha + ".." + phaseHead], { encoding: "utf8" }).trim());
          const stoppedEarly = stopReason !== undefined ||
            (configuredPhase?.type === "agent" && configuredPhase.stopOnNoCommits === true &&
              (observedCommitCount ?? commitCount ?? 0) === 0);
          const providerRecovery = journal.providerStateRecovery;
          const providerRecoveryEpoch = providerRecovery?.epochs.at(-1);
          journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
            phases: [...journal.phases.filter((item) => item.name !== phaseResult.name), {
              name: phaseResult.name,
              state: "complete",
              ...(phaseBeforeComplete?.attempt === undefined ? {} : { attempt: phaseBeforeComplete.attempt }),
              ...(commitCount === undefined ? {} : { commitCount }),
              ...(phaseBeforeComplete?.startSha === undefined ? {} : { startSha: phaseBeforeComplete.startSha }),
              ...(phaseBeforeComplete?.liveness === undefined ? {} : {
                liveness: { ...phaseBeforeComplete.liveness, activityAt: new Date().toISOString(), supervisorHeartbeatAt: new Date().toISOString() },
              }),
              ...(phaseBeforeComplete?.failureHistory === undefined ? {} : { failureHistory: phaseBeforeComplete.failureHistory }),
              ...(stoppedEarly ? { stoppedEarly: true } : {}),
              ...(stopReason === undefined ? {} : { stopReason }),
              ...(commandReceipt === undefined ? {} : { commandReceipt }),
              ...(phaseResult.type !== "command" || phaseResult.result.guixDaemonOperation === undefined ? {} : {
                guixDaemonOperation: phaseResult.result.guixDaemonOperation,
              }),
              completedAt: new Date().toISOString(),
            }],
            ...(providerRecovery?.state === "active" && providerRecoveryEpoch?.phase === phaseResult.name &&
                (providerRecoveryEpoch.state === "scheduled" || providerRecoveryEpoch.state === "running") ? {
              providerStateRecovery: {
                state: "complete",
                epochs: [...providerRecovery.epochs.slice(0, -1), { ...providerRecoveryEpoch, state: "complete" }],
              },
            } : {}),
            ...(runtimeAssertion === undefined || journal.runtimeEvidence === undefined ? {} : {
              runtimeEvidence: { ...journal.runtimeEvidence, runtimeAssertion },
            }),
          });
          if ((observedCommitCount ?? commitCount ?? 0) > 0) {
            journal = await recordUnsignedCommit(journal, signingBoundary("phase", phaseResult.name));
          }
        },
        onPhaseFailure: async (failure) => {
          // Retain only host-bounded, sandbox-redacted command evidence. Never
          // persist the exception text because provider errors can contain
          // credentials or unbounded output.
          const kind = boundedFailureKind(failure.error, failure.phase.type === "agent");
          const recovery = "Inspect the preserved branch, correct the phase, then resume with: " + resumeRecoveryCommand();
          const failureSummary = failureSummaryFor(failure.error);
          const phaseBeforeFailure = phaseRecord(journal, failure.phase.name);
          journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
            phases: [...journal.phases.filter((item) => item.name !== failure.phase.name), {
              name: failure.phase.name,
              state: "failed",
              ...(phaseBeforeFailure?.attempt === undefined ? {} : { attempt: phaseBeforeFailure.attempt }),
              ...(phaseBeforeFailure?.startSha === undefined ? {} : { startSha: phaseBeforeFailure.startSha }),
              ...(phaseBeforeFailure?.liveness === undefined ? {} : {
                liveness: { ...phaseBeforeFailure.liveness, activityAt: new Date().toISOString(), supervisorHeartbeatAt: new Date().toISOString() },
              }),
              ...(phaseBeforeFailure?.failureHistory === undefined ? {} : { failureHistory: phaseBeforeFailure.failureHistory }),
              failureReceipt: {
                kind,
                recovery,
                ...(failureSummary === undefined ? {} : { failureSummary }),
                ...(failure.guixDaemonOperation === undefined ? {} : { guixDaemonOperation: failure.guixDaemonOperation }),
              },
              ...(failure.guixDaemonOperation === undefined ? {} : { guixDaemonOperation: failure.guixDaemonOperation }),
            }],
          });
          console.warn("Phase " + failure.phase.name + " failed (" + kind + "); " + recovery + failureDiagnosticFor(failureSummary));
        },
      };
      const runBatch = async (batchSandbox, batch, includeSetup = false) => {
        if (batch.length === 0 && !includeSetup) return undefined;
        if (includeSetup) setupIncluded = true;
        return await retrySequential(() => runWorkflow({
          sandbox: batchSandbox,
          ...(includeSetup ? { setup } : {}),
          phases: batch,
          ...phaseCallbacks,
        }), projectConfig.retryPolicy, { retryable: isTransientSequentialError });
      };
      const workflowResults = [];
      let setupIncluded = false;
      let repairExecutionActive = activeRepair;
      if (activeRepair && journal.repair !== undefined) {
        const epochs = journal.repair.epochs;
        const latest = epochs.at(-1);
        if (latest !== undefined && latest.state !== "running") {
          journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
            repair: { state: "running", epochs: [...epochs.slice(0, -1), { ...latest, state: "running" }] },
            status: "active",
          });
        }
      }
      const pendingFor = (batch) => batch.filter((phase) => {
        const record = phaseRecord(journal, phase.name);
        return repairExecutionActive
          ? repairPhases.some((candidate) => candidate?.name === phase.name)
          : dispositionResultRequired || record?.state !== "complete" || record?.stoppedEarly === true;
      });
      const evidencePhaseIndex = evidenceConfig === undefined ? -1 : phases.findIndex((phase) => phase.name === evidenceConfig.proofPhase);
      const capturePhaseIndex = evidenceConfig === undefined ? -1 : phases.findIndex((phase) => phase.name === evidenceConfig.capturePhase);
      const phaseRequestsGuixDaemon = (phase) => phase.type === "command"
        ? phase.options?.guixDaemonSocket === true
        : phase.run.guixDaemonSocket === true;
      const evidenceProvider = (phase) => guix({
        manifest: codexBinDirectory ? ".goocastle/manifest-external-codex.scm" : ".goocastle/manifest.scm",
        channels: ".goocastle/channels.scm",
        // Evidence commands do not need a synthetic account, and some
        // rootless Guix hosts cannot resolve it in an FHS container.  Use the
        // host-mapped caller identity while retaining the same mounts and
        // no-network capability boundary as the proof sandbox.
        user: execFileSync("id", ["-un"], { encoding: "utf8" }).trim(),
        cores: projectConfig.resourcePolicy.cores,
        network: false,
        emulateFhs: projectConfig.resourcePolicy.emulateFhs,
        nesting: projectConfig.resourcePolicy.nesting,
        runtimeLimits: projectConfig.runtimeLimits,
        preserveEnv: [],
        homeFiles: [],
        ...(phaseRequestsGuixDaemon(phase) ? { allowGuixDaemonSocket: true } : {}),
        exposes: codexBinDirectory ? [{ hostPath: codexBinDirectory, sandboxPath: "/opt/goocastle-codex" }] : [],
      });
      const runEvidencePhase = async (phase) => {
        if (pendingFor([phase]).length === 0) return;
        evidenceSandbox = await retrySequential(() => taskWorktree.createSandbox({
          sandbox: evidenceProvider(phase),
          name: WORKFLOW_NAME + "-runtime-evidence-" + phase.name,
          env: { GOOCASTLE_ISSUE_NUMBER: String(issue.number), GOOCASTLE_PHASE_WORKER: "1" },
        }), projectConfig.retryPolicy, { retryable: isTransientSequentialError });
        try {
          const evidenceResult = await runBatch(evidenceSandbox, [phase]);
          if (evidenceResult !== undefined) workflowResults.push(evidenceResult);
        } finally {
          const closed = await evidenceSandbox.close();
          evidenceSandbox = undefined;
          if (closed.preservedWorktreePath) throw new Error("Runtime evidence sandbox left uncommitted changes at " + closed.preservedWorktreePath);
        }
      };
      const runNormalPending = async () => {
        if (evidenceConfig === undefined) {
          const result = await runBatch(sandbox, phases.filter((phase) => {
            const record = phaseRecord(journal, phase.name);
            return dispositionResultRequired || record?.state !== "complete" || record?.stoppedEarly === true;
          }), setup.length > 0 && !setupIncluded);
          if (result !== undefined) workflowResults.push(result);
          return;
        }
        const before = phases.slice(0, evidencePhaseIndex).filter((phase) => {
          const record = phaseRecord(journal, phase.name);
          return dispositionResultRequired || record?.state !== "complete" || record?.stoppedEarly === true;
        });
        const between = phases.slice(evidencePhaseIndex + 1, capturePhaseIndex).filter((phase) => {
          const record = phaseRecord(journal, phase.name);
          return dispositionResultRequired || record?.state !== "complete" || record?.stoppedEarly === true;
        });
        const after = phases.slice(capturePhaseIndex + 1).filter((phase) => {
          const record = phaseRecord(journal, phase.name);
          return dispositionResultRequired || record?.state !== "complete" || record?.stoppedEarly === true;
        });
        // A resumed evidence workflow can have every pre-proof phase already
        // complete. Do not invoke runWorkflow with an empty phase batch and no
        // setup commands: that produces no executable work.
        const initial = await runBatch(sandbox, before, pendingPhases.length > 0 && setup.length > 0 && !setupIncluded);
        if (initial !== undefined) workflowResults.push(initial);
        await runEvidencePhase(phases[evidencePhaseIndex]);
        const middle = await runBatch(sandbox, between);
        if (middle !== undefined) workflowResults.push(middle);
        await runEvidencePhase(phases[capturePhaseIndex]);
        const final = await runBatch(sandbox, after);
        if (final !== undefined) workflowResults.push(final);
      };
      if (activeRepair) {
        const failedRepairPhase = phases.find((phase) => phase.name === repairPhaseName);
        const evidenceRepair = evidenceConfig !== undefined &&
          (repairPhaseName === evidenceConfig.proofPhase || repairPhaseName === evidenceConfig.capturePhase);
        if (evidenceRepair && failedRepairPhase !== undefined) {
          const preparation = repairPhases.filter((phase) => phase.name !== repairPhaseName);
          const initial = await runBatch(sandbox, preparation, pendingPhases.length > 0 && setup.length > 0 && !setupIncluded);
          if (initial !== undefined) workflowResults.push(initial);
          await runEvidencePhase(failedRepairPhase);
        } else {
          const repairResult = await runBatch(sandbox, repairPhases, pendingPhases.length > 0 && setup.length > 0 && !setupIncluded);
          if (repairResult !== undefined) workflowResults.push(repairResult);
        }
        const epochs = journal.repair?.epochs ?? [];
        const latest = epochs.at(-1);
        if (latest !== undefined) {
          journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
            repair: { state: "complete", epochs: [...epochs.slice(0, -1), { ...latest, state: "complete" }] },
            status: "active",
          });
        }
        repairExecutionActive = false;
      }
      await runNormalPending();
      const result = {
        failures: workflowResults.flatMap((entry) => entry.failures ?? []),
        stoppedEarly: workflowResults.some((entry) => entry.stoppedEarly),
        ...(workflowResults.find((entry) => entry.stopReason !== undefined)?.stopReason === undefined ? {} : { stopReason: workflowResults.find((entry) => entry.stopReason !== undefined).stopReason }),
      };
      if (dispositionPolicy !== undefined && journal.disposition === undefined) {
        const dispositionResult = await dispositionResultFromSandbox(sandbox, dispositionPolicy, result.stopReason);
        const implementationTicket = gooflowDispositionImplementationTicket(dispositionPolicy, dispositionResult.disposition);
        let renderedImplementationTicket;
        let runtimeEvidenceHandoff;
        if (implementationTicket !== undefined) {
          if (implementationTicket.runtimeEvidence !== undefined) {
            const routed = await resolveIssueGooflow({
              directory: hostWorkTree,
              config: projectConfig,
              issue: {
                number: issue.number,
                labels: ["ready-for-agent", ...(implementationTicket.labels ?? [])],
              },
            });
            if (routed.workflow === undefined) {
              throw new Error("Research disposition selected a package delivery ticket, but its labels do not select implementation workflow " + JSON.stringify(implementationTicket.runtimeEvidence.workflow) + "; add the workflow assignment label to the ticket template and resume");
            }
            runtimeEvidenceHandoff = validateGooflowImplementationTicketRuntimeEvidence(
              implementationTicket.runtimeEvidence,
              routed.workflow,
              dispositionResult.runtimeEvidence,
            );
          }
          renderedImplementationTicket = renderGooflowImplementationTicket(implementationTicket, {
            issueNumber: issue.number,
            issueTitle: issue.title,
            workflow: WORKFLOW_NAME,
            epoch: journal.epoch ?? 1,
            disposition: dispositionResult.disposition,
            finding: dispositionResult.finding,
          }, runtimeEvidenceHandoff);
        }
        capturedDisposition = {
          disposition: {
            disposition: dispositionResult.disposition,
            finding: dispositionResult.finding,
            labelsToAdd: gooflowDispositionLabels(dispositionPolicy, dispositionResult.disposition),
            ...(renderedImplementationTicket === undefined ? {} : {
              implementationTicket: {
                ...renderedImplementationTicket,
                ...(runtimeEvidenceHandoff === undefined ? {} : { runtimeEvidence: runtimeEvidenceHandoff }),
                create: "pending",
                ...(runtimeEvidenceHandoff === undefined ? {} : { contract: "pending" }),
                labels: "pending",
              },
            }),
            comment: "pending",
            labels: "pending",
          },
        };
      }
      if (evidenceConfig !== undefined && journal.runtimeEvidence?.artifact !== "complete") {
        const proofRecord = phaseRecord(journal, evidenceConfig.proofPhase);
        const captureRecord = phaseRecord(journal, evidenceConfig.capturePhase);
        if (proofRecord?.state !== "complete" || captureRecord?.state !== "complete" || !proofRecord.commandReceipt || !captureRecord.commandReceipt) {
          throw new Error("Runtime screenshot evidence requires host-recorded successful proof and capture command receipts before artifact inspection; inspect the preserved journal and resume");
        }
        journal = await runtimeEvidenceArtifactCommit(journal, evidenceConfig, evidenceConfig.capturePhase, taskWorktree, branch, issue.number);
      }
      if (sandbox !== undefined) {
        closeResult = await sandbox.close();
        sandbox = undefined;
        if (closeResult.preservedWorktreePath) throw new Error("Uncommitted changes preserved at " + closeResult.preservedWorktreePath);
      }
      const taskWorktreeCloseResult = await taskWorktree.close();
      closeResult = taskWorktreeCloseResult;
      if (taskWorktreeCloseResult.preservedWorktreePath) {
        throw new Error("Uncommitted changes preserved at " + taskWorktreeCloseResult.preservedWorktreePath);
      }
      taskWorktree = undefined;
      const failedRequired = (result.failures ?? []).filter((failure) => requiredGooflowPhases.has(failure.phase.name));
      const failedRequiredPhases = [...new Set(failedRequired.map((failure) => failure.phase.name))];
      if (failedRequiredPhases.length > 0) {
        const failedSummary = failureSummaryFor(failedRequired[0]?.error);
        const requiredFailure = new Error(
          "Required Gooflow phase(s) " + failedRequiredPhases.map((name) => JSON.stringify(name)).join(", ") +
            " failed; inspect the preserved branch and resume with: " + resumeRecoveryCommand() + failureDiagnosticFor(failedSummary),
          { cause: failedRequired[0]?.error },
        );
        // Preserve the failed phase when a phase opted into continue. The
        // outer recovery boundary needs the same phase identity as the
        // fail-fast WorkflowPhaseError in order to classify host prerequisites.
        requiredFailure.name = "WorkflowPhaseError";
        requiredFailure.phase = failedRequired[0]?.phase;
        throw requiredFailure;
      }
      // Capture the result only after its sandbox is cleanly finalized and
      // required gates have passed. A crash after this point can resume the
      // host boundaries without retaining a completed research worktree.
      if (capturedDisposition !== undefined) {
        journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
          ...capturedDisposition,
          status: "active",
        });
      }
      if (result.stoppedEarly && dispositionPolicy === undefined) journal = await transitionSequentialTaskJournal(gitCommonDir, journal, { status: "failed" });
    }
    const stoppedPhase = phases.find((phase) => phaseRecord(journal, phase.name)?.stoppedEarly === true);
    if (stoppedPhase && dispositionPolicy === undefined) {
      throw new Error("Required Gooflow phase " + JSON.stringify(stoppedPhase.name) + " made no commits for #" + issue.number + "; inspect the preserved branch and resume after fixing the phase");
    }
    if (dispositionPolicy !== undefined) {
      journal = await applyDisposition(journal, issue);
      await restoreHostGitConfig();
      console.log("Recorded disposition " + JSON.stringify(journal.disposition?.disposition) + " for #" + issue.number + ".");
      await persistInterTaskDelay(gitCommonDir, projectConfig.taskLimits.interTaskDelayMs);
      continue;
    }
    // Delivery is forbidden until the host-owned evidence artifact is
    // committed.  A previous crash can leave every executable phase complete
    // while this boundary remains pending; never let that state bypass the
    // proof required for issue closure.
    if (evidenceConfig !== undefined && journal.runtimeEvidence?.artifact !== "complete") {
      throw new Error("Runtime screenshot evidence artifact is still pending; inspect the preserved worktree and resume after its host commit succeeds");
    }
    const branchHead = hostGit(["rev-parse", branch], { encoding: "utf8" }).trim();
    if (branchHead === baseHead) {
      throw new Error("Workflow produced no commits to integrate for #" + issue.number);
    }
    journal = await requireSignedPhaseCommits(
      journal,
      signingBoundary("integration", String(issue.number)),
      baseHead,
      branchHead,
    );
    await restoreHostGitConfig();
    const integrationSha = journal.integrationSha ?? branchHead;
    if (journal.integrationSha && journal.integrationSha !== branchHead) {
      throw new Error("Cannot resume #" + issue.number + ": branch " + branch + " changed from expected SHA " + journal.integrationSha + " to " + branchHead);
    }
    // Runtime evidence is a delivery prerequisite. Post its exact receipt
    // before merge/push so a pending comment cannot leave a partially
    // delivered issue with no resumable evidence boundary. A legacy journal
    // that already merged or pushed is still reconciled using its recorded
    // integration SHA.
    if (evidenceConfig !== undefined && journal.runtimeEvidence?.comment !== "complete") {
      journal = await postRuntimeEvidence(journal, evidenceConfig, integrationSha, phases, issue.number);
    }
    if (journal.merge === "complete" && hostGit(["rev-parse", "HEAD"], { encoding: "utf8" }).trim() !== integrationSha) {
      throw new Error("Cannot resume #" + issue.number + ": local " + baseBranch + " is not expected integration SHA " + integrationSha);
    }
    if (journal.merge !== "complete") {
      journal = await transitionSequentialTaskJournal(gitCommonDir, journal, { integrationSha, merge: "started", status: "active" });
      const currentHead = hostGit(["rev-parse", "HEAD"], { encoding: "utf8" }).trim();
      if (currentHead === baseHead) {
        hostGit(["merge-base", "--is-ancestor", baseHead, integrationSha]);
        hostGit(["merge", "--ff-only", branch], { stdio: "inherit" });
      } else if (currentHead !== integrationSha) {
        throw new Error("Cannot resume #" + issue.number + ": expected HEAD " + baseHead + " or " + integrationSha + ", found " + currentHead + ". Inspect " + branch);
      }
      if (hostGit(["rev-parse", "HEAD"], { encoding: "utf8" }).trim() !== integrationSha) throw new Error("Merge did not produce expected SHA " + integrationSha);
      journal = await transitionSequentialTaskJournal(gitCommonDir, journal, { merge: "complete" });
      integration = "merged";
    }
    journal = await requireSignedCommit(journal, signingBoundary("integration", String(issue.number)), integrationSha);
    if (journal.push !== "complete") {
      journal = await transitionSequentialTaskJournal(gitCommonDir, journal, { push: "started" });
      const beforePush = await remoteSha();
      if (beforePush !== integrationSha) {
        if (beforePush !== baseHead) throw new Error("Refusing to push #" + issue.number + ": origin/" + baseBranch + " is " + beforePush + ", expected " + baseHead + " or " + integrationSha);
        await pushAndReconcile(integrationSha);
      }
    }
    if (journal.remoteVerification !== "complete") {
      journal = await transitionSequentialTaskJournal(gitCommonDir, journal, { remoteVerification: "started" });
      if ((await remoteSha()) !== integrationSha) throw new Error("Push did not publish expected SHA " + integrationSha + "; inspect origin/" + baseBranch);
      journal = await transitionSequentialTaskJournal(gitCommonDir, journal, { remoteVerification: "complete" });
    }
    if (journal.push !== "complete") {
      journal = await transitionSequentialTaskJournal(gitCommonDir, journal, { push: "complete" });
      integration = "pushed";
    } else if (journal.remoteVerification !== "complete" || (await remoteSha()) !== integrationSha) {
      throw new Error("Cannot close #" + issue.number + ": origin/" + baseBranch + " is not expected integration SHA " + integrationSha);
    }
    if (journal.issueClose !== "complete") {
      journal = await transitionSequentialTaskJournal(gitCommonDir, journal, { issueClose: "started" });
      if ((await ghJson(["issue", "view", String(issue.number), "--json", "state"], validateGitHubIssueStatePayload)).state !== "CLOSED") {
        await retryGitHub("issue closure", () => execFileSync("gh", ["issue", "close", String(issue.number), "--comment", "Completed by Goocastle"], { stdio: "inherit" }));
      }
      if ((await ghJson(["issue", "view", String(issue.number), "--json", "state"], validateGitHubIssueStatePayload)).state !== "CLOSED") throw new Error("GitHub did not close #" + issue.number + "; retry with: " + shellDisplayCommand("gh", ["issue", "close", String(issue.number)]));
      journal = await transitionSequentialTaskJournal(gitCommonDir, journal, { issueClose: "complete" });
      integration = "closed";
    }
    journal = await reconcileDeliveredCleanup(journal, issue.number);
    console.log("Completed and integrated #" + issue.number + ".");
    await persistInterTaskDelay(gitCommonDir, projectConfig.taskLimits.interTaskDelayMs);
    refreshAfterIntegration = !RESUME_ONLY && task < MAX_TASKS;
  } catch (error) {
    const failedPhase = error !== null && typeof error === "object" && error.name === "WorkflowPhaseError" && error.phase !== null && typeof error.phase === "object"
      ? error.phase
      : undefined;
    const providerInterruption = failedPhase?.type === "agent" && providerInterruptionFor(error);
    const kind = boundedFailureKind(error, failedPhase?.type === "agent");
    const recoveryCommand = resumeRecoveryCommand();
    const failureSummary = failureSummaryFor(error);
    // Setup failures (before an agent command exists) have no command
    // failure summary. Preserve one bounded diagnostic so recovery does not
    // collapse a concrete sandbox/worktree error into an opaque "error".
    const exceptionDiagnostic = failureSummary === undefined && error instanceof Error
      ? error.message.replace(/[\r\n\0]+/gu, " ").slice(0, 1_000)
      : "";
    const daemonOperation = daemonOperationFor(error);
    const freshRecoveryNames = failedPhase === undefined
      ? new Set(journal.phases.filter((phase) => phase.state === "fresh" && freshAttemptPhaseNames.has(phase.name)).map((phase) => phase.name))
      : new Set([failedPhase.name]);
    const recoveryFailureNames = freshRecoveryNames.size === 0 ? undefined : freshRecoveryNames;
    const providerRecovery = journal.providerStateRecovery;
    const providerRecoveryEpoch = providerRecovery?.epochs.at(-1);
    const providerRecoveryLaunchFailed = failedPhase === undefined &&
      providerRecovery?.state === "active" &&
      providerRecoveryEpoch !== undefined &&
      (providerRecoveryEpoch.state === "scheduled" || providerRecoveryEpoch.state === "running") &&
      freshRecoveryNames.has(providerRecoveryEpoch.phase);
    const providerRecoveryPhaseFailed = providerInterruption &&
      providerRecovery?.state === "active" &&
      providerRecoveryEpoch !== undefined &&
      (providerRecoveryEpoch.state === "scheduled" || providerRecoveryEpoch.state === "running") &&
      failedPhase?.name === providerRecoveryEpoch.phase;
    // Persist a bounded diagnostic before releasing the sandbox.  A completed
    // agent phase can still fail host-side validation (for example, when a
    // disposition result is absent); without this the recovery journal is
    // indistinguishable from an interrupted run.
    journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
      status: "failed",
      failure: "Goocastle task failed (" + kind + ")" +
        (exceptionDiagnostic ? ": " + exceptionDiagnostic : failureDiagnosticFor(failureSummary, 1_000)) +
        "; inspect the preserved branch and resume with: " + recoveryCommand,
      ...(recoveryFailureNames === undefined ? {} : {
        phases: [
          ...journal.phases.filter((item) => !recoveryFailureNames.has(item.name)),
          ...[...recoveryFailureNames].map((name) => {
            const previous = phaseRecord(journal, name);
            return {
              name,
              state: "failed",
              ...(previous?.attempt === undefined ? {} : { attempt: previous.attempt }),
              ...(previous?.startSha === undefined ? {} : { startSha: previous.startSha }),
              ...(previous?.liveness === undefined ? {} : {
                liveness: { ...previous.liveness, activityAt: new Date().toISOString(), supervisorHeartbeatAt: new Date().toISOString() },
              }),
              ...(previous?.failureHistory === undefined ? {} : { failureHistory: previous.failureHistory }),
              failureReceipt: {
                kind,
                recovery: (failedPhase === undefined
                  ? "Recovery could not start phase " + JSON.stringify(name) + "; inspect the preserved branch, then resume with: "
                  : "Inspect the preserved branch, correct the phase, then resume with: ") + recoveryCommand,
                ...(failureSummary === undefined ? {} : { failureSummary }),
                ...(daemonOperation === undefined ? {} : { guixDaemonOperation: daemonOperation }),
              },
              ...(daemonOperation === undefined ? {} : { guixDaemonOperation: daemonOperation }),
            };
          }),
        ],
      }),
      ...(providerRecoveryPhaseFailed || providerRecoveryLaunchFailed ? {
        providerStateRecovery: {
          state: "active" as const,
          epochs: [...providerRecovery!.epochs.slice(0, -1), { ...providerRecoveryEpoch!, state: "failed" as const }],
        },
      } : {}),
    }).catch(() => journal);
    const evidenceSandboxRecovery = evidenceSandbox ? await evidenceSandbox.close().catch(() => ({})) : {};
    evidenceSandbox = undefined;
    const sandboxRecovery = sandbox ? await sandbox.close().catch(() => ({})) : {};
    const taskWorktreeRecovery = taskWorktree
      ? await taskWorktree.preserve().catch(() => ({ preservedWorktreePath: taskWorktree.worktreePath }))
      : {};
    taskWorktree = undefined;
    const recovery = evidenceSandboxRecovery.preservedWorktreePath
      ? evidenceSandboxRecovery
      : sandboxRecovery.preservedWorktreePath
      ? sandboxRecovery
      : taskWorktreeRecovery.preservedWorktreePath
        ? taskWorktreeRecovery
        : closeResult ?? sandboxRecovery;
    await restoreHostGitConfig().catch((restoreError) => {
      console.error("Could not restore host Git config: " + restoreError);
    });
    let providerRecoveryEscalation;
    const providerBranchIsValid = providerInterruption && taskWorktreeRecovery.preservedWorktreePath !== undefined
      ? (() => {
          try {
            return exactRefSha("refs/heads/" + branch) !== undefined;
          } catch {
            return false;
          }
        })()
      : false;
    const currentProviderRecovery = journal.providerStateRecovery;
    const providerRecoveryAttempts = currentProviderRecovery?.epochs.length ?? 0;
    const providerRecoveryCanRetry = providerInterruption &&
      providerBranchIsValid &&
      currentProviderRecovery?.state !== "blocked" &&
      providerRecoveryAttempts < providerStateRecoveryMaxEpochs &&
      journal.merge === "pending" && journal.push === "pending" && journal.remoteVerification === "pending" && journal.issueClose === "pending";
    if (providerRecoveryCanRetry) {
      const recoveryAttempt = providerRecoveryAttempts + 1;
      const waitMs = providerRecoveryDelay(recoveryAttempt);
      console.warn(
        "Provider interruption in agent phase " + JSON.stringify(failedPhase.name) + " for #" + issue.number +
        "; preserved worktree and journal are valid. Re-entering with a fresh provider session after " +
        String(waitMs) + "ms backoff (automatic recovery attempt " + String(recoveryAttempt) + "/" +
        String(providerStateRecoveryMaxEpochs) + ").",
      );
      if (waitMs > 0) await sleep(waitMs);
      // The same incomplete journal is selected on the next scheduler turn;
      // its failed provider phase causes the existing fresh-state epoch logic
      // to quarantine the old home and create the new provider session.
      task -= 1;
      continue;
    }
    if (providerInterruption && currentProviderRecovery?.state === "active" && providerRecoveryAttempts >= providerStateRecoveryMaxEpochs) {
      providerRecoveryEscalation =
        "Automatic provider interruption recovery exhausted after " + String(providerStateRecoveryMaxEpochs) +
        " fresh provider-state attempts for agent phase " + JSON.stringify(failedPhase.name) +
        ". Preserved branch and provider state homes remain in the durable journal. Inspect them, then resume with: " + resumeRecoveryCommand();
      const epochs = currentProviderRecovery.epochs.map((entry, index, entries) =>
        index === entries.length - 1 ? { ...entry, state: "blocked" } : entry);
      journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
        status: "failed",
        failure: providerRecoveryEscalation,
        providerStateRecovery: { state: "blocked", epochs, recovery: providerRecoveryEscalation },
        phases: journal.phases.map((record) => record.name !== failedPhase.name ? record : {
          ...record,
          state: "failed",
          failureReceipt: { ...record.failureReceipt, kind: "provider-interruption", recovery: providerRecoveryEscalation },
        }),
      });
    }
    const transientDeliveryPause = isTransientSequentialError(error) && (journal.merge !== "pending" || journal.push !== "pending" || journal.remoteVerification !== "pending");
    const signingPause = error instanceof Error && error.message.startsWith("Required commit signing");
    if (transientDeliveryPause) {
      reportTransientDeliveryPause(journal);
    } else if (!signingPause) {
      reportRecovery(issue, branch, integration, recovery);
    }
    if (providerRecoveryEscalation !== undefined) {
      throw new Error(providerRecoveryEscalation, { cause: error });
    }
    attemptedIssues.add(issue.number);
    const failedGooflowPhase = failedPhase === undefined
      ? undefined
      : materializedGooflow?.phases.find((phase) => phase.name === failedPhase.name);
    const failureText = Array.isArray(failureSummary?.lines)
      ? failureSummary.lines.map((line) => typeof line?.text === "string" ? line.text : "").join("\n")
      : "";
    const unavailableGuixDaemon = failedGooflowPhase?.type === "command" &&
      materializedGooflow?.requiredPhases?.includes(failedGooflowPhase.name) === true &&
      failedGooflowPhase.capabilities?.guixDaemon === true &&
      /\/var\/guix\/daemon-socket\/socket\b/iu.test(failureText) &&
      /(?:failed|unable|cannot|could not|can't)\s+(?:to\s+)?(?:connect|reach|open|access)|(?:connection\s+refused|no such file|not found|unavailable|inaccessible|does not exist|not available|permission denied)/iu.test(failureText);
    if (unavailableGuixDaemon) {
      const marker = "<!-- goocastle-external-prerequisite:guix-daemon:" + String(issue.number) + " -->";
      const boundedEvidence = failureDiagnosticFor(failureSummary, 4_000).trim() || "(no failure evidence retained)";
      const comment = [
        marker,
        "",
        "Goocastle blocked this ticket after the required daemon-authorized Guix proof could not reach /var/guix/daemon-socket/socket.",
        "The preserved journal and task branch remain resumable; unblock only after the daemon is available.",
        "",
        "Bounded failure evidence:",
        boundedEvidence,
      ].join("\n");
      await retryGitHub("Guix daemon prerequisite classification", async () => {
        const current = await selectedIssue(issue.number);
        const blocked = current.labels.some((label) => label.name === "state:blocked");
        const ready = current.labels.some((label) => label.name === "ready-for-agent");
        // The marker is predictable and may appear in an unrelated user
        // comment. Only the exact rendered host comment is an idempotent
        // receipt for this classification.
        if (!current.comments.some((entry) => entry.body === comment)) {
          execFileSync("gh", ["issue", "comment", String(issue.number), "--body", comment], { stdio: "inherit" });
        }
        // Publish the blocking label only after the evidence receipt exists.
        // If the process stops between these host mutations, recovery can
        // still finish the label without skipping a missing comment.
        if (!blocked || ready) {
          execFileSync("gh", [
            "issue", "edit", String(issue.number),
            ...(blocked ? [] : ["--add-label", "state:blocked"]),
            ...(ready ? ["--remove-label", "ready-for-agent"] : []),
          ], { stdio: "inherit" });
        }
      });
      console.error("Task #" + issue.number + " is blocked on the required Guix daemon; continuing to unrelated eligible work.");
      // A terminal prerequisite classification is not completed work. Do not
      // consume the queue slot that the unrelated eligible issue needs.
      task -= 1;
      continue;
    }
    const requiredCommandGate = failedGooflowPhase?.type === "command" &&
      materializedGooflow?.requiredPhases?.includes(failedGooflowPhase.name) === true &&
      (failedGooflowPhase.name === "safe-package-proof" ||
        materializedGooflow.evidence?.proofPhase === failedGooflowPhase.name ||
        materializedGooflow.evidence?.capturePhase === failedGooflowPhase.name);
    if (requiredCommandGate) {
      const semanticFingerprint = repairSemanticFingerprintFor(materializedGooflow, failedGooflowPhase.name);
      const repairResult = await scheduleRequiredCommandRepair(journal, failedGooflowPhase.name, semanticFingerprint);
      journal = repairResult.journal;
      if (!repairResult.blocked) {
        const epoch = journal.repair?.epochs.at(-1)?.epoch;
        console.error(
          "Scheduled bounded repair epoch " + String(epoch) + " for #" + issue.number +
          "; implementation and audit will run before retrying " + JSON.stringify(failedGooflowPhase.name) + ".",
        );
        task -= 1;
        continue;
      }
      await reconcileBlockedRequiredCommandRepair(journal, issue.number);
      console.error(
        "Task #" + issue.number + " is blocked after bounded repair epochs for required gate " +
        JSON.stringify(failedGooflowPhase.name) + "; continuing to unrelated eligible work.",
      );
      task -= 1;
      continue;
    }
    if (transientDeliveryPause) {
      // A local base that is ahead of origin cannot safely continue with a
      // different issue, even when phase failures are normally configured to
      // continue.  Leave the resumable journal as the sole next action.
      process.exitCode = 1;
      break;
    }
    if (projectConfig.failurePolicy === "continue") {
      deferredJournalIssues.add(issue.number);
      if (journal.phases.some((phase) => phase.state === "failed")) {
        retryableFailedPhaseIssues.add(issue.number);
        console.error("Task #" + issue.number + " failed in a retryable phase;" + failureDiagnosticFor(failureSummary) + " continuing by policy. Resume with: " + resumeRecoveryCommand());
      } else {
        manuallyRecoverableJournalIssues.add(issue.number);
        console.error("Task #" + issue.number + " requires manual recovery; continuing by policy. Resume with: " + resumeRecoveryCommand());
      }
      continue;
    }
    if (failureSummary !== undefined) {
      throw new Error(
        "Goocastle task failed (" + kind + ")" + failureDiagnosticFor(failureSummary) +
          "; inspect the preserved branch and resume with: " + recoveryCommand,
      );
    }
    throw error;
  }
  if (refreshAfterIntegration) {
    reexecuteDogfoodRunner(task + 1, attemptedIssues);
  }
}
