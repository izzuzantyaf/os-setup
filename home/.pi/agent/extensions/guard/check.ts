// Self-check: bun ~/.pi/agent/extensions/guard/check.ts
// (not a discovered extension — only */index.ts is auto-loaded)
import assert from "node:assert/strict";
import { homedir } from "node:os";
import { join } from "node:path";
import { absPath, decideRead, decideShell, decideWrite, hardline } from "./index.ts";

const H = homedir();
const cwd = join(H, "proj");

// read deny
assert.match(decideRead("~/.pi/agent/auth.json", cwd)!, /credential/);
assert.match(decideRead(".env", cwd)!, /environment file/);
assert.match(decideRead("/etc/.envrc", cwd)!, /environment file/);
assert.equal(decideRead(".env.example", cwd), null);
assert.equal(decideRead("src/index.ts", cwd), null);

// write deny
assert.match(decideWrite("~/.ssh/id_ed25519", cwd)!.deny!, /protected directory/);
assert.match(decideWrite("~/.aws/credentials", cwd)!.deny!, /protected directory/);
assert.match(decideWrite("/etc/hosts", cwd)!.deny!, /protected directory/);
assert.match(decideWrite("~/.git-credentials", cwd)!.deny!, /credential/);
assert.match(decideWrite("~/.pi/agent/trust.json", cwd)!.deny!, /security config/);
assert.equal(decideRead("~/.pi/agent/settings.json", cwd), null); // readable so the agent can inspect itself

// shell profiles carry API keys: denied both ways, file tools and bash alike
assert.match(decideRead("~/.zprofile", cwd)!, /credential/);
assert.match(decideRead("~/.zshenv", cwd)!, /credential/);
assert.match(decideRead("~/.zshrc", cwd)!, /credential/);
assert.match(decideWrite("~/.zprofile", cwd)!.deny!, /credential/);
assert.match(decideShell("grep TYPESAFE ~/.zprofile")!.deny!, /credential store/);
assert.match(decideShell("cat ~/.zshrc")!.deny!, /credential store/);

// write ask
assert.match(decideWrite("~/.ssh/config", cwd)!.ask!, /process execution/);
assert.match(decideWrite("~/.pi/agent/settings.json", cwd)!.ask!, /process execution/);
assert.match(decideWrite("AGENTS.md", cwd)!.ask!, /steers future/);
assert.match(decideWrite(join(cwd, "sub", "CLAUDE.md"), cwd)!.ask!, /steers future/);
assert.match(decideWrite(join(cwd, ".pi", "extensions", "x.ts"), cwd)!.ask!, /\.pi config tree/);

// allowed
assert.equal(decideWrite("src/index.ts", cwd), null);
assert.match(decideWrite("~/.pi/agent/extensions/x.ts", cwd)!.ask!, /agent tooling/); // tooling dirs stay writable, but a human confirms
assert.equal(decideWrite(".env", cwd), null); // env files stay writable, only read-denied

// symlink escape cannot bypass the deny list
const { mkdtempSync, symlinkSync } = await import("node:fs");
const tmp = mkdtempSync("/tmp/guards-");
symlinkSync(join(H, ".ssh"), join(tmp, "link"));
assert.match(decideWrite(join(tmp, "link", "id_rsa"), cwd)!.deny!, /protected directory/);
assert.equal(absPath("~/../..", cwd).startsWith("/"), true);

// shell floor
for (const cmd of ["rm -rf /", "sudo rm -rf /*", "rm -rf --no-preserve-root /", `rm -rf "~"`, "mkfs.ext4 /dev/sda1", "dd if=/dev/zero of=/dev/sda", ":(){ :|:& };:", "kill -9 -1", "sudo reboot"]) {
  assert.ok(hardline(cmd), `expected floor: ${cmd}`);
}
for (const cmd of ["rm -rf /tmp/build", "rm -rf node_modules", "grep -r 'rm -rf /' docs", "echo reboot"]) {
  assert.equal(hardline(cmd), null, `false positive: ${cmd}`);
}

// shell path policy
assert.match(decideShell("echo x > ~/.pi/agent/settings.json")!.ask!, /protected path/);
// shell read-deny: the file tools gated secrets, bash did not
assert.match(decideShell("cat ~/.pi/agent/auth.json")!.deny!, /credential store/);
assert.match(decideShell("grep -r KEY ~/.pi/agent/models.json")!.deny!, /credential store/);
assert.equal(decideShell("cat ~/.pi/agent/settings.json"), null); // mentioning a control file is not a write
assert.match(decideShell("tee -a ~/.ssh/authorized_keys")!.ask!, /protected path/);
assert.equal(decideShell("cat ~/.ssh/config"), null); // read via shell is not gated
assert.equal(decideShell("rm -rf build"), null);

// agent tooling is writable-in-place via out-of-store symlinks: deleting it is the bypass
assert.match(decideWrite(join(H, ".agents", "skills", "typesafe", "scripts", "jev.sh"), cwd)!.ask!, /agent tooling/);
assert.match(decideWrite(join(H, ".pi", "agent", "extensions", "guard", "index.ts"), cwd)!.ask!, /agent tooling/);
// the out-of-store symlinks resolve into the repo, so the repo side must hit the same rule
assert.match(decideWrite(join(H, ".os-setup", "home", ".pi", "agent", "extensions", "guard", "index.ts"), cwd)!.ask!, /agent tooling/);
assert.match(decideWrite(join(H, ".os-setup", "home", ".agents", "skills", "typesafe", "SKILL.md"), cwd)!.ask!, /agent tooling/);
assert.match(decideShell("rm -rf ~/.agents/skills/typesafe")!.ask!, /protected path/);
assert.match(decideShell("mv ~/.pi/agent/extensions ~/tmp-ext")!.ask!, /protected path/);
assert.match(decideShell("cat /dev/null > ~/.pi/agent/extensions/guard/index.ts")!.ask!, /protected path/);
assert.equal(decideShell("rm -rf ~/agents-skills-backup"), null);

console.log("guards: all checks passed");
