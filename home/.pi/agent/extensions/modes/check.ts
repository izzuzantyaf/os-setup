// Self-check: bun ~/.pi/agent/extensions/modes/check.ts
// (not a discovered extension — only */index.ts is auto-loaded)
import assert from "node:assert/strict";
import { modeFromEntries, nextMode } from "./index.ts";
import { isSafeCommand } from "../plan-mode/utils.ts";

// modeFromEntries reflects the plan-mode entries pi persists.
assert.equal(modeFromEntries([]), "off");
assert.equal(modeFromEntries([{ type: "custom", customType: "plan-mode", data: { enabled: false } }]), "off");
assert.equal(modeFromEntries([{ type: "custom", customType: "plan-mode", data: { enabled: true } }]), "plan");
assert.equal(
	modeFromEntries([
		{ type: "custom", customType: "plan-mode", data: { enabled: true } },
		{ type: "custom", customType: "plan-mode", data: { enabled: false } },
	]),
	"off",
);

// Option+Tab cycle order: agent → plan → ask → agent.
assert.equal(nextMode("off"), "plan");
assert.equal(nextMode("plan"), "ask");
assert.equal(nextMode("ask"), "off");

// Bash floor is plan mode's allowlist.
assert.equal(isSafeCommand("rm -rf /tmp/x"), false);
assert.equal(isSafeCommand("git status"), true);

console.log("modes: all checks passed");
