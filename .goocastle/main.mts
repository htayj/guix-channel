import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, statSync } from "node:fs";
import { access, constants, lstat, mkdtemp, readFile, realpath, stat, unlink, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { isAbsolute, join, relative, resolve } from "node:path";
import { pathToFileURL } from "node:url";

const GENERATED_RUNNER_RUNTIME_API_VERSION = 2;
const GENERATED_RUNNER_RUNTIME_IDENTITY = "goocastle/generated-runner/api-2/journal-1";
const GENERATED_RUNNER_JOURNAL_SCHEMA_VERSION = 1;
const SELF_HOSTED_RUNTIME_ROOT_ENVIRONMENT = "GOOCASTLE_SELF_HOSTED_RUNTIME_ROOT";
const hostWorkTree = process.cwd();
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
const { AGENT_PROVIDER_REGISTRY, GENERATED_RUNNER_RUNTIME_API_VERSION: runtimeApiVersion, commitSigningRecoveryCommand, createConfiguredAgent, createSandbox, createSequentialTaskJournal, generatedRunnerRuntimeHandshake, gooflowDispositionImplementationTicket, gooflowDispositionLabels, gooflowImplementationTicketMarker, parseGooflowDispositionResult, renderGooflowImplementationTicket, renderGooflowDispositionComment, isTransientSequentialError, issueGooflowPhases, issueGooflowSetup, listSequentialTaskJournals, loadProjectConfig, parseGitHubIssueJson, parseGitHubIssueNumber, parseGitHubIssueReference, persistInterTaskDelay, preflightCommitSigning, reconcileInterTaskDelay, renderGitHubIssueContext, resolveIssueGooflow, retrySequential, runWorkflow, snapshotGitHubIssue, transitionSequentialTaskJournal, validateGitHubIssueListPayload, validateGitHubIssuePayload, validateGitHubIssueStatePayload, validateIssueSpecification } = runtimeModule;
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
const SPECIFICATION_OVERRIDE = process.env.GOOCASTLE_SPECIFICATION_OVERRIDE === "1";
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
    hostGit(["config", "--local", "commit.gpgSign", "false"]);
    return journal;
  }
  const prior = journal.commitSigning;
  const blocked = prior?.blockedBoundaries ?? [];
  const unsigned = prior?.unsignedBoundaries ?? [];
  const preflight = await preflightCommitSigning(hostWorkTree);
  if (preflight.available) {
    hostGit(["config", "--local", "commit.gpgSign", "true"]);
    return journal;
  }
  if (signingMode === "best-effort") {
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
// Agent sandboxes deliberately do not inherit the host's GnuPG home.  A
// successful host preflight therefore is not evidence that commits made by an
// agent are signed.  Do the verification at the host boundary, before a phase
// can be recorded as complete or its branch can be integrated.
const requireSignedPhaseCommits = async (journal, boundary, startSha, endSha) => {
  if (signingMode !== "required" || startSha === endSha) return journal;
  const commits = hostGit(["rev-list", "--reverse", startSha + ".." + endSha], { encoding: "utf8" })
    .trim().split("\n").filter(Boolean);
  const unsigned = commits.filter((commit) => {
    try { hostGit(["verify-commit", commit], { encoding: "utf8" }); return false; }
    catch { return true; }
  });
  if (unsigned.length === 0) return journal;
  const prior = journal.commitSigning;
  const blocked = prior?.blockedBoundaries ?? [];
  journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
    commitSigning: {
      mode: signingMode,
      blockedBoundaries: addSigningBoundary(blocked, boundary),
      ...(prior?.unsignedBoundaries?.length ? { unsignedBoundaries: prior.unsignedBoundaries } : {}),
    },
  });
  throw new Error("Required commit signing rejected " + String(unsigned.length) + " unsigned commit(s) before " + boundary + ". The task branch is preserved; sign or replace those commits, then resume with: " + resumeRecoveryCommand());
};
const signRequiredPhaseCommits = (branch, startSha, endSha) => {
  if (signingMode !== "required" || startSha === endSha) return endSha;
  const worktree = branchWorktreePath(branch);
  if (worktree === undefined) throw new Error("Required commit signing cannot locate the task worktree for " + branch + ". The branch is preserved for recovery.");
  // Sandbox agents cannot safely receive the host GnuPG material.  Replay the
  // already-reviewed linear phase commits at the trusted host boundary instead.
  gitAt(worktree, ["rebase", "--exec", "git -c commit.gpgSign=true commit --amend --no-edit", startSha], { stdio: "inherit" });
  return hostGit(["rev-parse", branch], { encoding: "utf8" }).trim();
};
const hostGitConfigPath = resolve(hostWorkTree, stripTrailingLineEnding(hostGit(["rev-parse", "--git-path", "config"], {
  encoding: "utf8",
})));
const gitCommonDir = resolve(hostWorkTree, stripTrailingLineEnding(hostGit(["rev-parse", "--git-common-dir"], {
  encoding: "utf8",
})));
const baseBranch = stripTrailingLineEnding(hostGit(["branch", "--show-current"], {
  encoding: "utf8",
}));
if (!baseBranch) {
  throw new Error("Current checkout is detached; check out the branch to integrate before running " + WORKFLOW_NAME);
}
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

const ghJson = async (args, validate) => await retrySequential(() => {
  const source = "gh " + args.slice(0, 2).join(" ");
  const output = execFileSync("gh", args, { encoding: "utf8", maxBuffer: 16 * 1024 * 1024 });
  return parseGitHubIssueJson(output, source, validate);
}, projectConfig.retryPolicy, { retryable: isTransientSequentialError });
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
const validateIssueForWorkflow = (issue, workflow) => {
  const policy = {
    ...projectConfig.issueSpecification,
    ...(workflow?.issueSpecificationMode === undefined ? {} : { mode: workflow.issueSpecificationMode }),
  };
  const explanation = validateIssueSpecification(
    { number: issue.number, body: issue.body },
    policy,
  );
  for (const warning of explanation.warnings) console.error("WARNING: " + warning);
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
const resolveForIssue = async (issue) => {
  const resolved = await resolveIssueGooflow({
    directory: hostWorkTree,
    config: projectConfig,
    issue: { number: issue.number, labels: issue.labels ?? [] },
    ...(requestedGooflowOverride ? { override: requestedGooflowOverride } : process.env.GOOCASTLE_GOOFLOW_BYPASS === "1" ? { override: "template" } : {}),
    onSelection: (selection) => console.log(
      "Selected Gooflow " + JSON.stringify(selection.workflow?.name ?? "template") +
        " via " + selection.source +
        (selection.schemaVersion === undefined ? "" : " (schema v" + selection.schemaVersion + ")") +
        (selection.override === undefined ? "" : "; explicit override=" + JSON.stringify(selection.override)),
    ),
  });
  if (resolved.selection.source === "template-fallback") {
    throw new Error("Missing .goocastle/gooflow.json; create the enforced Gooflow standard or set GOOCASTLE_GOOFLOW_BYPASS=1 for an audited template bypass");
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
  // A runner may refresh itself through an older runtime whose validated v1
  // task limits predate priorityLabels.  Preserve its historical numerical
  // ordering instead of failing during recovery.
  const priorityLabels = projectConfig.taskLimits.priorityLabels ?? [];
  const priorityOf = (issue) => {
    const index = priorityLabels.findIndex((label) =>
      issue.labels.some((candidate) => candidate.name === label));
    return index === -1 ? priorityLabels.length : index;
  };
  issues.sort((left, right) => priorityOf(left) - priorityOf(right) || left.number - right.number);
  for (const issue of issues) {
    if (excludedIssues.has(issue.number)) continue;
    if (hasTerminalBlockedLabel(issue)) continue;
    let resolved;
    let explanation;
    try {
      resolved = await resolveForIssue(issue);
      explanation = validateIssueForWorkflow(issue, resolved.workflow);
    } catch (error) {
      if (error instanceof Error && error.message.startsWith("Missing .goocastle/gooflow.json")) throw error;
      reportInvalidReadyIssue(issue, error);
      continue;
    }
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
      try {
        explanation = validateIssueForWorkflow(selected, resolved.workflow);
      } catch (error) {
        reportInvalidReadyIssue(selected, error);
        continue;
      }
      return { issue: selected, explanation };
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
const dispositionResultFromSandbox = async (sandbox, policy) => {
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
      throw new Error("Non-delivery Gooflow did not write its disposition result at " + policy.resultPath + ". Write the required JSON result and resume with: " + resumeRecoveryCommand());
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
  if (selected.implementationTicket) {
    let ticket = selected.implementationTicket;
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
    if (ticket.labels !== "complete") {
      if (ticket.issueNumber === undefined) throw new Error("Created implementation ticket has no recorded issue number; resume with: " + resumeRecoveryCommand());
      journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
        disposition: { ...journal.disposition, implementationTicket: { ...ticket, labels: "started" } }, status: "active",
      });
      for (const label of ticket.labelsToAdd) {
        const hasLabel = async () => (await selectedIssue(ticket.issueNumber)).labels.some((entry) => entry.name === label);
        if (await hasLabel()) continue;
        await retrySequential(async () => {
          if (await hasLabel()) return;
          execFileSync("gh", ["issue", "edit", String(ticket.issueNumber), "--add-label", label], { stdio: "inherit" });
        }, projectConfig.retryPolicy, { retryable: isTransientSequentialError });
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
  if (selected.comment !== "complete") {
    journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
      disposition: { ...selected, comment: "started" }, status: "active",
    });
    // The marker is predictable and may appear in unrelated user comments.
    // Only the complete, journaled host receipt proves this boundary ran.
    if (!(await commentAlreadyApplied())) {
      // A transport error can arrive after GitHub accepted the comment. Check
      // the durable external receipt before every retry to avoid duplicates.
      await retrySequential(async () => {
        if (await commentAlreadyApplied()) return;
        execFileSync("gh", ["issue", "comment", String(issue.number), "--body", comment], {
          stdio: "inherit",
        });
      }, projectConfig.retryPolicy, { retryable: isTransientSequentialError });
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
      await retrySequential(() => execFileSync("gh", ["issue", "edit", String(issue.number), "--add-label", label], {
        stdio: "inherit",
      }), projectConfig.retryPolicy, { retryable: isTransientSequentialError });
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
  { env: hostGitEnvironment, ...options },
);
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
  journal.remoteVerification === "complete" && journal.issueClose === "complete";
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
const reconciliationRecovery = (journal) =>
  "Original task tip is retained at " + journal.reconciliation.backupBranch + ". " +
  "Resolve the preserved replay with: " + shellDisplayCommand("git", ["-C", journal.reconciliation.recoveryWorktreePath, "rebase", "--continue"]) +
  "; or abandon only the replay with: " + shellDisplayCommand("git", ["-C", journal.reconciliation.recoveryWorktreePath, "rebase", "--abort"]) + ". " +
  "The original work is recoverable with: " + shellDisplayCommand("git", ["-C", hostWorkTree, "branch", "-f", "--", journal.branch, journal.reconciliation.backupBranch]);
const reconcileBaseAdvance = async (journal, issueNumber) => {
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
// A terminally blocked journal is intentionally skipped while a different
// eligible task proceeds.  A failed journal is different: before selecting
// fresh work, the run must stop and expose its recovery boundary.
const failedJournalIssues = new Set();
const incompleteJournal = async () => {
  const candidates = (await listSequentialTaskJournals(gitCommonDir, WORKFLOW_NAME))
    .filter((journal) => journal.status !== "complete" &&
      (!deliveryComplete(journal) || journal.cleanup !== "complete") &&
      !deferredJournalIssues.has(journal.issueNumber));
  // Cleanup-only work is safe and visible, but must never monopolize recovery
  // while another journal still has merge/push/close work to finish.
  return candidates.find((journal) => !deliveryComplete(journal)) ?? candidates.find(deliveryComplete);
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
for (let task = reexecutionState.nextTask; task <= MAX_TASKS; task += 1) {
  let journal = await incompleteJournal();
  if (!journal && RESUME_ONLY) {
    // Resume-only mode is strictly recovery-only. It must not consume the
    // pacing boundary left by an earlier delivery when there is no journal to
    // resume, and it must not wait merely to report that recovery is done.
    console.log("No incomplete " + WORKFLOW_NAME + " journals remain.");
    break;
  }
  if (!journal) {
    // The continue policy deliberately preserves a failed task for explicit recovery,
    // but it must not let an unattended run quietly consume fresh issues once
    // every recoverable journal has been deferred in this process.  Stop at
    // that durable boundary; a new invocation clears the in-memory deferral
    // set and retries the preserved work before selecting new work.
    if (failedJournalIssues.size > 0) {
      const deferred = [...failedJournalIssues].sort((left, right) => left - right);
      console.error(
        "Deferred failed or terminal journals remain: " + deferred.map((number) => "#" + number).join(", ") +
        ". No fresh issue will start in this invocation. Resume with: " + resumeRecoveryCommand(),
      );
      process.exitCode = 1;
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
    // A retained journal is recovery state, not authority to resume an issue
    // whose current terminal disposition says it must remain blocked. Check the
    // live issue before any branch, journal, or sandbox recovery action.
    if (issue.state === "OPEN" && hasTerminalBlockedLabel(issue)) {
      deferredJournalIssues.add(issue.number);
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
    resolvedGooflow = await resolveForIssue(issue);
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
    console.log("\n=== Task " + task + "/" + MAX_TASKS + ": #" + issue.number + " " + issue.title + " ===\n");
  }
  const branch = journal.branch;
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
  let integration = journal.issueClose === "complete"
    ? "closed"
    : journal.push === "complete"
      ? "pushed"
      : journal.merge === "complete" ? "merged" : "not-started";
  let closeResult;
  let refreshAfterIntegration = false;
  try {
    if (deliveryComplete(journal)) {
      journal = await reconcileDeliveredCleanup(journal, issue.number);
      console.log("Completed delivery cleanup for #" + issue.number + ".");
      await persistInterTaskDelay(gitCommonDir, projectConfig.taskLimits.interTaskDelayMs);
      // Do not run base-advance reconciliation, phases, remote checks, or an
      // issue-close retry for an already-delivered cleanup-only journal.
      continue;
    }
    journal = await reconcileBaseAdvance(journal, issue.number);
    baseHead = journal.reconciliation?.state === "complete"
      ? journal.reconciliation.reconciledBaseSha
      : journal.baseSha;
    const promptArgs = {
      ISSUE_NUMBER: String(issue.number),
      ISSUE_TITLE: issueContext.title,
      ISSUE_CONTEXT: renderGitHubIssueContext(issueContext),
      BRANCH: branch,
      BASE_BRANCH: baseBranch,
      CODING_STANDARDS: codingStandards,
    };
    // A running record has no completion evidence.  A process can die after
    // committing but before the phase callback, so branch movement is not a
    // substitute for a successful required command or agent completion.
    // Leave it pending and rerun it on resume.
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
            completionTimeoutMs: projectConfig.timeouts.completionMs,
            runtimeLimits: projectConfig.runtimeLimits,
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
            completionTimeoutMs: projectConfig.timeouts.completionMs,
            runtimeLimits: projectConfig.runtimeLimits,
            logging: projectConfig.logging,
          },
        },
      ];
    // Specification, dependency, and exact repository-local Gooflow routing
    // have all passed before this journal or sandbox can create task state.
    const selectedGooflow = resolvedGooflow.workflow?.name ?? "template";
    const materializedGooflow = resolvedGooflow.workflow
      ? materializeIssueWorkflow(resolvedGooflow.workflow, issue)
      : undefined;
    const dispositionPolicy = materializedGooflow?.disposition;
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
    const phases = materializedGooflow
      ? issueGooflowPhases(materializedGooflow, projectConfig, promptArgs, {
          directory: hostWorkTree,
          agentCommands: codexBinDirectory ? { codex: codexCommand } : {},
        })
      : templatePhases;
    const setup = materializedGooflow
      ? issueGooflowSetup(materializedGooflow, projectConfig)
      : [];
    const requiredGooflowPhases = new Set(materializedGooflow?.requiredPhases ?? []);
    // A disposition is the terminal receipt for a non-delivery workflow. If
    // interruption follows a completed phase but precedes receipt capture,
    // rerun its idempotent research phases rather than treating phase state as
    // evidence of a host-valid result.
    const dispositionResultRequired = dispositionPolicy !== undefined && journal.disposition === undefined;
    let capturedDisposition;
    const pendingPhases = phases.filter((phase) => {
      const record = phaseRecord(journal, phase.name);
      return dispositionResultRequired || record?.state !== "complete" || record?.stoppedEarly === true;
    });
    if (pendingPhases.length > 0) {
      // Setup commands run before onPhaseStart and are allowed to use Git, so
      // prepare the same signing boundary before the sandbox can execute
      // them. Their commits are recorded separately from agent work.
      const setupSigningBoundary = signingBoundary("setup", "workflow");
      if (setup.length > 0 && dispositionPolicy === undefined) journal = await prepareCommitSigning(journal, setupSigningBoundary);
      // Sandbox capability access must follow the same materialized workflow
      // that supplies the phases and setup. A repository policy overlay may
      // add or remove a phase capability, so checking the pre-materialized
      // document could leak a secret or make an otherwise valid phase fail.
      const sandboxAccess = sandboxAccessForWorkflow(materializedGooflow);
      sandbox = await retrySequential(() => createSandbox({
        branch,
        base: baseHead,
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
          ...(sandboxAccess.requestsGuixDaemon ? { guixDaemonSocket: true } : {}),
          exposes: codexBinDirectory ? [{ hostPath: codexBinDirectory, sandboxPath: "/opt/goocastle-codex" }] : [],
        }),
        env: { ...sandboxAccess.environment, GOOCASTLE_ISSUE_NUMBER: String(issue.number) },
      }), projectConfig.retryPolicy, { retryable: isTransientSequentialError });
      const setupStartSha = hostGit(["rev-parse", branch], { encoding: "utf8" }).trim();
      let setupObserved = setup.length === 0;
      const result = await retrySequential(() => runWorkflow({
        sandbox,
        setup,
        phases: phases.filter((phase) => dispositionResultRequired || phaseRecord(journal, phase.name)?.state !== "complete"),
        onSetupComplete: async () => {
          if (setupObserved) return;
          setupObserved = true;
          const setupHead = hostGit(["rev-parse", branch], { encoding: "utf8" }).trim();
          if (dispositionPolicy === undefined && setupHead !== setupStartSha) journal = await recordUnsignedCommit(journal, setupSigningBoundary);
        },
        onPhaseStart: async (phase) => {
          if (dispositionPolicy === undefined) journal = await prepareCommitSigning(journal, signingBoundary("phase", phase.name));
          journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
            status: "active",
            phases: [...journal.phases.filter((item) => item.name !== phase.name), {
              name: phase.name,
              state: "running",
              startSha: hostGit(["rev-parse", branch], { encoding: "utf8" }).trim(),
            }],
          });
          console.log("\n--- " + phase.name + " ---\n");
        },
        onPhaseComplete: async (phaseResult) => {
          const phaseStartSha = phaseRecord(journal, phaseResult.name)?.startSha;
          let phaseHead = phaseStartSha === undefined
            ? undefined
            : hostGit(["rev-parse", branch], { encoding: "utf8" }).trim();
          if (dispositionPolicy === undefined && phaseStartSha !== undefined && phaseHead !== undefined) {
            phaseHead = signRequiredPhaseCommits(branch, phaseStartSha, phaseHead);
          }
          const commitCount = phaseResult.type === "agent"
            ? phaseResult.result.commits.length
            : undefined;
          const observedCommitCount = phaseStartSha === undefined || phaseHead === undefined
            ? undefined
            : Number(hostGit(["rev-list", "--count", phaseStartSha + ".." + phaseHead], { encoding: "utf8" }).trim());
          const configuredPhase = phases.find((phase) => phase.name === phaseResult.name);
          const stoppedEarly = configuredPhase?.type === "agent" && configuredPhase.stopOnNoCommits === true && commitCount === 0;
          if (dispositionPolicy === undefined && phaseStartSha !== undefined && phaseHead !== undefined) {
            journal = await requireSignedPhaseCommits(journal, signingBoundary("phase", phaseResult.name), phaseStartSha, phaseHead);
          }
          journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
            phases: [...journal.phases.filter((item) => item.name !== phaseResult.name), {
              name: phaseResult.name,
              state: "complete",
              ...(commitCount === undefined ? {} : { commitCount }),
              ...(phaseRecord(journal, phaseResult.name)?.startSha === undefined ? {} : { startSha: phaseRecord(journal, phaseResult.name).startSha }),
              ...(stoppedEarly ? { stoppedEarly: true } : {}),
              completedAt: new Date().toISOString(),
            }],
          });
          if (dispositionPolicy === undefined && (observedCommitCount ?? commitCount ?? 0) > 0) {
            journal = await recordUnsignedCommit(journal, signingBoundary("phase", phaseResult.name));
          }
        },
        onPhaseFailure: async (failure) => {
          journal = await transitionSequentialTaskJournal(gitCommonDir, journal, {
            phases: [...journal.phases.filter((item) => item.name !== failure.phase.name), {
              name: failure.phase.name,
              state: "failed",
              ...(phaseRecord(journal, failure.phase.name)?.startSha === undefined ? {} : { startSha: phaseRecord(journal, failure.phase.name).startSha }),
            }],
          });
          console.warn("Phase " + failure.phase.name + " failed but continuing by Gooflow policy.");
        },
      }), projectConfig.retryPolicy, { retryable: isTransientSequentialError });
      if (dispositionPolicy !== undefined && journal.disposition === undefined) {
        const result = await dispositionResultFromSandbox(sandbox, dispositionPolicy);
        const implementationTicket = gooflowDispositionImplementationTicket(dispositionPolicy, result.disposition);
        capturedDisposition = {
          disposition: {
            disposition: result.disposition,
            finding: result.finding,
            labelsToAdd: gooflowDispositionLabels(dispositionPolicy, result.disposition),
            ...(implementationTicket === undefined ? {} : {
              implementationTicket: {
                ...renderGooflowImplementationTicket(implementationTicket, {
                  issueNumber: issue.number,
                  issueTitle: issue.title,
                  workflow: WORKFLOW_NAME,
                  epoch: journal.epoch ?? 1,
                  disposition: result.disposition,
                  finding: result.finding,
                }),
                create: "pending",
                labels: "pending",
              },
            }),
            comment: "pending",
            labels: "pending",
          },
        };
      }
      closeResult = await sandbox.close();
      sandbox = undefined;
      if (closeResult.preservedWorktreePath) throw new Error("Uncommitted changes preserved at " + closeResult.preservedWorktreePath);
      const failedRequiredPhases = [...new Set(
        (result.failures ?? [])
          .filter((failure) => requiredGooflowPhases.has(failure.phase.name))
          .map((failure) => failure.phase.name),
      )];
      if (failedRequiredPhases.length > 0) {
        throw new Error(
          "Required Gooflow phase(s) " + failedRequiredPhases.map((name) => JSON.stringify(name)).join(", ") +
            " failed; inspect the preserved branch and resume with: " + resumeRecoveryCommand(),
        );
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
      if (result.stoppedEarly) journal = await transitionSequentialTaskJournal(gitCommonDir, journal, { status: "failed" });
    }
    const stoppedPhase = phases.find((phase) => phaseRecord(journal, phase.name)?.stoppedEarly === true);
    if (stoppedPhase) {
      throw new Error("Required Gooflow phase " + JSON.stringify(stoppedPhase.name) + " made no commits for #" + issue.number + "; inspect the preserved branch and resume after fixing the phase");
    }
    if (dispositionPolicy !== undefined) {
      journal = await applyDisposition(journal, issue);
      console.log("Recorded disposition " + JSON.stringify(journal.disposition?.disposition) + " for #" + issue.number + ".");
      await persistInterTaskDelay(gitCommonDir, projectConfig.taskLimits.interTaskDelayMs);
      continue;
    }
    const branchHead = hostGit(["rev-parse", branch], { encoding: "utf8" }).trim();
    if (branchHead === baseHead) {
      throw new Error("Workflow produced no commits to integrate for #" + issue.number);
    }
    await restoreHostGitConfig();
    const integrationSha = journal.integrationSha ?? branchHead;
    if (journal.integrationSha && journal.integrationSha !== branchHead) {
      throw new Error("Cannot resume #" + issue.number + ": branch " + branch + " changed from expected SHA " + journal.integrationSha + " to " + branchHead);
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
        await retrySequential(() => execFileSync("gh", ["issue", "close", String(issue.number), "--comment", "Completed by Goocastle"], { stdio: "inherit" }), projectConfig.retryPolicy, { retryable: isTransientSequentialError });
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
    journal = await transitionSequentialTaskJournal(gitCommonDir, journal, { status: "failed" }).catch(() => journal);
    const recovery = closeResult ?? (sandbox ? await sandbox.close().catch(() => ({})) : {});
    await restoreHostGitConfig().catch((restoreError) => {
      console.error("Could not restore host Git config: " + restoreError);
    });
    const transientDeliveryPause = isTransientSequentialError(error) && (journal.merge !== "pending" || journal.push !== "pending" || journal.remoteVerification !== "pending");
    const signingPause = error instanceof Error && error.message.startsWith("Required commit signing");
    if (transientDeliveryPause) {
      reportTransientDeliveryPause(journal);
    } else if (!signingPause) {
      reportRecovery(issue, branch, integration, recovery);
    }
    attemptedIssues.add(issue.number);
    if (transientDeliveryPause) {
      // A local base that is ahead of origin cannot safely continue with a
      // different issue, even when phase failures are normally configured to
      // continue.  Leave the resumable journal as the sole next action.
      process.exitCode = 1;
      break;
    }
    if (projectConfig.failurePolicy === "continue") {
      deferredJournalIssues.add(issue.number);
      failedJournalIssues.add(issue.number);
      console.error("Task #" + issue.number + " failed; continuing by policy. Resume with: " + resumeRecoveryCommand());
      continue;
    }
    throw error;
  }
  if (refreshAfterIntegration) {
    reexecuteDogfoodRunner(task + 1, attemptedIssues);
  }
}
