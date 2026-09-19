/**
 * Hermes-style default restrictions, adapted to pi.
 *
 * Ported from Hermes Agent's defaults (hermes-agent.nousresearch.com/docs/user-guide/security):
 *   - read-deny: secret stores + project env files
 *   - write-deny: credential/system paths (file tools, no prompt, no override)
 *   - write-ask:  ~/.ssh/config + agent-instruction files + project config trees
 *   - shell:      always-on floor (no override) + approval for writes to protected paths
 *
 * This is NOT a security boundary. `bash` runs as you; a determined model can
 * shell out around every check below, exactly as Hermes documents for itself.
 * User-typed `!` commands are intentionally not gated: that's you, not the agent.
 *
 * ponytail: skipped Hermes layers — approvals.mode (smart LLM risk scoring),
 * session/permanent allowlists, grep/find result filtering, pipe-to-shell and
 * SQL/docker/sudo approval patterns, powershell tool, container backends.
 * Escape hatch: PI_GUARDS=off (the analog of Hermes --yolo).
 */
import { realpathSync } from "node:fs";
import { homedir } from "node:os";
import { basename, dirname, join, relative, resolve, sep } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const HOME = homedir();

const real = (p: string) => {
  try {
    return realpathSync(p);
  } catch {
    return p; // not on disk yet; absPath() resolves the existing prefix
  }
};

/** Comparison lists carry the logical path and its realpath twin, so symlinked dotfiles match either way. */
const both = (paths: string[]) => [...new Set(paths.flatMap((p) => [p, real(p)]))];

const under = (p: string, dir: string) => p === dir || p.startsWith(dir + sep);
const PI_HOME = resolve(process.env.PI_CODING_AGENT_DIR ?? join(HOME, ".pi", "agent"));
const PI_HOMES = both([PI_HOME]);
const inPiHome = (p: string) => PI_HOMES.some((h) => under(p, h));
const piStore = (...f: string[]) => join(PI_HOME, ...f);

/** Shell profiles can carry API keys (TypeSafe etc.). Tooling reads its key from the keychain instead, so deny these both ways. */
const SHELL_PROFILES = [join(HOME, ".zprofile"), join(HOME, ".zshenv"), join(HOME, ".zshrc"), join(HOME, ".bash_profile"), join(HOME, ".bashrc"), join(HOME, ".profile"), join(HOME, ".config", "zsh", ".zshrc")];
/** Hermes: credential/secret stores — read-denied and write-denied. */
const SECRET_FILES = both([piStore("auth.json"), piStore("models.json"), piStore("models-store.json"), piStore(".env"), ...SHELL_PROFILES]);
/** Hermes: control files — read-denied, hard-blocked for the agent, edit them yourself. */
const CONTROL_FILES = both([piStore("trust.json")]);

const WRITE_DENY_FILES = both([
  ...SECRET_FILES,
  join(HOME, ".netrc"),
  join(HOME, ".pgpass"),
  join(HOME, ".npmrc"),
  join(HOME, ".pypirc"),
  join(HOME, ".git-credentials"),
  "/etc/sudoers",
  "/etc/passwd",
  "/etc/shadow",
  "/var/run/docker.sock",
  "/run/docker.sock",
]);

const WRITE_DENY_DIRS = both([
  join(HOME, ".ssh"),
  join(HOME, ".aws"),
  join(HOME, ".gnupg"),
  join(HOME, ".kube"),
  join(HOME, ".docker"),
  join(HOME, ".azure"),
  join(HOME, ".config", "gh"),
  join(HOME, ".config", "gcloud"),
  "/etc",
  "/boot",
  "/usr/lib/systemd",
  "/private/etc",
  "/private/var/db",
  "/private/var/root",
]);

/** Hermes: project env files are read-denied anywhere on disk but stay writable. */
const ENV_BASENAMES = new Set([".env", ".env.local", ".env.development", ".env.production", ".env.test", ".env.staging", ".envrc"]);

/** Hermes: not hard-blocked, but a human must confirm — they can steer execution/future turns. */
/** settings.json is agent-readable; writes still need a human because it steers every future session. */
const ASK_FILES = both([join(HOME, ".ssh", "config"), piStore("settings.json")]);
const INSTRUCTION_BASENAMES = new Set(["agents.md", "agents.override.md", "claude.md", "soul.md", ".cursorrules"]);
const CONFIG_SEGMENTS = new Set([".pi", ".agents"]);

/** Deterministic path as the tools will see it, with symlinks resolved. */
export function absPath(p: string, cwd: string): string {
  const expanded = p === "~" ? HOME : p.startsWith("~/") ? join(HOME, p.slice(2)) : p;
  const full = resolve(cwd, expanded);
  for (let q = full; ; q = dirname(q)) {
    try {
      return join(realpathSync(q), relative(q, full));
    } catch {
      if (q === dirname(q)) return full;
    }
  }
}

export type Verdict = { deny: string } | { ask: string } | null;

export function decideRead(raw: string, cwd: string): string | null {
  const p = absPath(raw, cwd);
  if (SECRET_FILES.includes(p) || CONTROL_FILES.includes(p)) return `read of pi's credential/config store (${p})`;
  if (ENV_BASENAMES.has(basename(p))) return `read of a project environment file (${basename(p)})`;
  return null;
}

export function decideWrite(raw: string, cwd: string): Verdict {
  const p = absPath(raw, cwd);
  if (CONTROL_FILES.includes(p)) return { deny: `write to pi's security config (${p}) — edit it yourself` };
  // Approval-gated paths are checked before the credential deny so ~/.ssh/ does not swallow ~/.ssh/config.
  if (ASK_FILES.includes(p)) return { ask: `write to ${p}, which can change process execution` };
  if (WRITE_DENY_FILES.includes(p)) return { deny: `write to a protected credential/config file (${p})` };
  for (const d of WRITE_DENY_DIRS) if (under(p, d)) return { deny: `write inside a protected directory (${d})` };
  const base = basename(p).toLowerCase();
  if (INSTRUCTION_BASENAMES.has(base)) return { ask: `write to ${base}, which steers future agent behavior` };
  if (!inPiHome(p)) {
    const seg = p.split(sep).find((s) => CONFIG_SEGMENTS.has(s));
    if (seg) return { ask: `write inside a ${seg} config tree (${p})` };
  }
  return null;
}

// --- shell ------------------------------------------------------------------

const START = "(?:^|[;&|(`\\n])\\s*(?:sudo\\s+)?";
const rx = (body: string) => new RegExp(START + body);

/** Hermes hardline blocklist: no approval, no yolo, no override. */
const HARDLINE: Array<[RegExp, string]> = [
  [rx("rm\\s+(?:-[^\\s]*[rR][^\\s]*|--recursive)\\s+(?:-[^\\s]+\\s+)*(?:--no-preserve-root\\s+)?[\"']?/(?:\\.\\.?/)*\\*?[\"']?(?:\\s*$|\\s*[;&|)`])"), "recursive delete of the filesystem root"],
  [rx("rm\\s+(?:-[^\\s]*[rR][^\\s]*|--recursive)[^\\n;&|]*\\s[\"']?(?:~|\\$\\{?HOME\\}?|/(?:home|root|etc|usr|var|bin|sbin|boot|lib)(?:/\\*?)?)[\"']?(?:\\s*$|\\s*[;&|)`])"), "recursive delete of a system or home directory"],
  [rx("mkfs(?:\\.[a-z0-9]+)?\\b"), "format a filesystem (mkfs)"],
  [rx("dd\\b[^\\n]*\\bof=/dev/(?:sd|nvme|hd|mmcblk|vd|disk|rdisk)"), "dd to a raw block device"],
  [/>\s*\/dev\/(?:sd|nvme|hd|mmcblk|vd|disk|rdisk)/, "redirect to a raw block device"],
  [/:\s*\(\s*\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;\s*:/, "fork bomb"],
  [rx("kill\\s+(?:-[^\\s]+\\s+)*-1\\b"), "kill all processes"],
  [rx("(?:shutdown|reboot|halt|poweroff)\\b"), "system shutdown or reboot"],
];

export function hardline(cmd: string): string | null {
  for (const [re, why] of HARDLINE) if (re.test(cmd)) return why;
  return null;
}

const WRITE_VERB = />>?|\b(?:tee|dd|truncate|rm|cp|mv|install|chmod|chown|ln|sed)\b/;

/** Path literals as a shell command would spell them: absolute, ~, $HOME, ${HOME}. */
const tokens = (paths: string[]) => {
  const set = new Set<string>();
  for (const p of paths) {
    set.add(p);
    if (under(p, HOME)) {
      const rest = p.slice(HOME.length + 1);
      for (const prefix of ["~/", "$HOME/", "${HOME}/"]) set.add(prefix + rest);
    }
  }
  return [...set];
};
/** Shell reads of these are the real exfil path — the file tools gated them, bash did not. */
const SECRET_TOKENS = tokens(SECRET_FILES);
const CONTROL_TOKENS = tokens(CONTROL_FILES);
const SENSITIVE_TOKENS = tokens([...WRITE_DENY_FILES, ...WRITE_DENY_DIRS, ...ASK_FILES].filter((p) => !CONTROL_FILES.includes(p)));

/**
 * Shell-side counterpart to decideWrite: same paths, since `sed -i`/`tee`/`>`
 * reach them just as well as the file tools do. Credential reads are denied
 * outright; every other path check needs a write verb, so mentioning a path
 * is not a write.
 * ponytail: token+verb heuristic, not a shell parser — quoted mentions can
 * false-positive and exotic quoting can false-negative. Upgrade path: reuse
 * Hermes' quote-aware command parsing if this ever needs to be airtight.
 */
export function decideShell(cmd: string): Verdict {
  const secret = SECRET_TOKENS.find((t) => cmd.includes(t));
  if (secret) return { deny: `shell read of pi's credential store (${secret})` };
  if (!WRITE_VERB.test(cmd)) return null;
  const control = CONTROL_TOKENS.find((t) => cmd.includes(t));
  if (control) return { deny: `shell write to pi's security config (${control})` };
  const hit = SENSITIVE_TOKENS.find((t) => cmd.includes(t));
  return hit ? { ask: `shell write to a protected path (${hit})` } : null;
}

// --- extension --------------------------------------------------------------

const PATH_TOOLS = new Set(["read", "grep", "find", "ls"]);
const WRITE_TOOLS = new Set(["write", "edit"]);

export default function (pi: ExtensionAPI) {
  if (process.env.PI_GUARDS === "off") return;

  pi.on("tool_call", async (event, ctx) => {
    const block = (reason: string) => ({ block: true as const, reason });
    const approve = async (ask: string, detail: unknown) => {
      if (!ctx.hasUI) return block(`Denied: ${ask}. Non-interactive mode cannot approve, so it fails closed.`);
      if (!(await ctx.ui.confirm("Protected path", `${ask}?\n\n${JSON.stringify(detail)}`))) return block(`Denied by user: ${ask}`);
      return undefined;
    };

    // ponytail: "powershell" is not covered; add if you run pi on Windows.
    if (event.toolName === "bash") {
      const cmd = String(event.input.command ?? "");
      const floor = hardline(cmd);
      if (floor) return block(`Blocked by the always-on floor: ${floor}. This cannot run through the agent — run it yourself in a terminal, it is not overridable.`);
      const verdict = decideShell(cmd);
      if (verdict && "deny" in verdict) return block(`Blocked: ${verdict.deny}. Do not retry or rephrase; the user must do this.`);
      if (verdict) return approve(verdict.ask, cmd);
    }

    if (WRITE_TOOLS.has(event.toolName) || PATH_TOOLS.has(event.toolName)) {
      const raw = String((event.input as { path?: unknown }).path ?? ".");
      if (WRITE_TOOLS.has(event.toolName)) {
        const verdict = decideWrite(raw, ctx.cwd);
        if (verdict && "deny" in verdict) return block(`Blocked: ${verdict.deny}. Do not retry or rephrase; the user must do this.`);
        if (verdict) return approve(verdict.ask, raw);
      } else {
        // grep/find/ls are gated on their search root only, so a recursive search
        // from a parent can still surface a denied file's contents.
        // ponytail: no per-result filtering (Hermes filters grep hits). Add if it bites.
        const why = decideRead(raw, ctx.cwd);
        if (why) return block(`Blocked: ${why}. Ask the user for the value instead.`);
      }
    }
  });
}
