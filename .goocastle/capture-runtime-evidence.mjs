#!/usr/bin/env node
// Execute the maintainer-reviewed runtime contract for the active issue.
// The final assertion is consumed by Goocastle's host-side verifier.
import { readFileSync, existsSync, statSync } from "node:fs";
import { resolve, sep } from "node:path";
import { spawnSync } from "node:child_process";

const fail = (message) => {
  process.stderr.write(`runtime-screenshot: ${message}\n`);
  process.exit(2);
};

const [contractPath, issueText] = process.argv.slice(2);
if (typeof contractPath !== "string" || !/^[0-9]+$/.test(issueText ?? "")) {
  fail("usage: capture-runtime-evidence.mjs CONTRACT_PATH ISSUE_NUMBER");
}
const issueNumber = Number(issueText);
if (!Number.isSafeInteger(issueNumber) || issueNumber < 1) fail("invalid issue number");

let document;
try {
  const info = statSync(contractPath);
  if (!info.isFile() || info.isSymbolicLink()) fail("runtime contract must be a regular file");
  document = JSON.parse(readFileSync(contractPath, "utf8"));
} catch (error) {
  fail(`cannot load runtime contract: ${error instanceof Error ? error.message : String(error)}`);
}
if (document?.version !== 1 || !Array.isArray(document.contracts)) fail("unsupported runtime contract document");
const contract = document.contracts.find((candidate) => candidate?.issueNumber === issueNumber);
if (!contract) fail(`no runtime contract for issue #${issueNumber}`);
const runtime = contract.runtime;
const safeName = (value) => typeof value === "string" && /^[a-z0-9][a-z0-9+.-]*$/i.test(value);
const safeRelativePath = (value) => typeof value === "string" && value.length > 0 && !value.startsWith("/")
  && !value.includes("\\") && value.split("/").every((part) => part && part !== "." && part !== "..");
const safeMarker = (value) => typeof value === "string" && value.length > 0 && value.length <= 256
  && value.trim() === value && !/[\0\r\n]/.test(value);
const executableContract = runtime?.kind === undefined || runtime?.kind === "executable";
const nodeLibraryContract = runtime?.kind === "node-library";
if (!safeName(contract.packageName) || !safeMarker(runtime?.successMarker)
    || (executableContract && (!(safeName(runtime?.executable)) || runtime?.invocation?.file !== runtime.executable
      || !Array.isArray(runtime.invocation.args) || !runtime.invocation.args.every((arg) => typeof arg === "string" && !/[\0\r\n]/.test(arg))))
    || (nodeLibraryContract && (!(safeName(runtime?.interpreterPackage)) || !safeRelativePath(runtime?.modulePath)
      || typeof runtime?.probe !== "string" || runtime.probe.length === 0 || runtime.probe.length > 4096 || /[\0\r\n]/.test(runtime.probe)))
    || (!executableContract && !nodeLibraryContract)) {
  fail("runtime contract entry is malformed");
}

const guix = process.env.GUIX || "guix";
const build = spawnSync(guix, ["build", "-L", ".", "--no-grafts", contract.packageName], {
  encoding: "utf8",
  maxBuffer: 1024 * 1024,
});
if (build.error || build.status !== 0) {
  process.stderr.write(build.stderr || build.stdout || "");
  fail(`cannot realize ${contract.packageName}`);
}
const output = build.stdout.trim();
if (!output.startsWith("/gnu/store/")) fail("Guix did not return a store output");
let executable;
let invocation;
let packageOutput;
if (nodeLibraryContract) {
  const moduleDirectory = resolve(output, runtime.modulePath);
  if (!moduleDirectory.startsWith(`${output}${sep}`) || !existsSync(moduleDirectory) || !statSync(moduleDirectory).isDirectory()) {
    fail("declared node-library module directory is absent from the realized package output");
  }
  const interpreter = spawnSync(guix, ["build", "-L", ".", "--no-grafts", runtime.interpreterPackage], {
    encoding: "utf8", maxBuffer: 1024 * 1024,
  });
  if (interpreter.error || interpreter.status !== 0) {
    process.stderr.write(interpreter.stderr || interpreter.stdout || "");
    fail(`cannot realize Node interpreter package ${runtime.interpreterPackage}`);
  }
  const interpreterOutput = interpreter.stdout.trim();
  executable = resolve(interpreterOutput, "bin", "node");
  if (!interpreterOutput.startsWith("/gnu/store/") || !existsSync(executable) || !statSync(executable).isFile()) {
    fail("declared Node interpreter is absent from its realized Guix package output");
  }
  invocation = ["-e", runtime.probe, moduleDirectory];
  packageOutput = output;
} else {
  executable = resolve(output, "bin", runtime.executable);
  if (!executable.startsWith(`${output}${sep}`) || !existsSync(executable) || !statSync(executable).isFile()) {
    fail("declared executable is absent from the realized package output");
  }
  invocation = runtime.invocation.args;
}
const run = spawnSync(executable, invocation, {
  encoding: "utf8",
  maxBuffer: 1024 * 1024,
  env: process.env,
});
process.stdout.write(run.stdout || "");
process.stderr.write(run.stderr || "");
if (run.error || run.status !== 0) fail(`declared invocation failed with status ${String(run.status)}`);
if (!run.stdout.split(/\r?\n/u).includes(runtime.successMarker)) {
  fail("declared invocation did not emit its standalone success marker on stdout");
}
process.stdout.write(`GOOCASTLE_RUNTIME_ASSERTION_V1 ${JSON.stringify({
  version: 1,
  executable,
  invocation: [executable, ...invocation],
  successMarker: runtime.successMarker,
  ...(packageOutput === undefined ? {} : { packageOutput }),
})}\n`);
