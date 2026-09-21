// Self-check for the RTK-prefix normalization in isSafeCommand.
// Run: node /Users/izzu/.pi/agent/extensions/plan-mode/utils.test.ts
import assert from "node:assert/strict";
import { isSafeCommand } from "./utils.ts";

assert.equal(isSafeCommand("git status"), true);
assert.equal(isSafeCommand("rtk git status"), true); // RTK-rewritten, same verdict
assert.equal(isSafeCommand("rtk git log -n 5"), true);
assert.equal(isSafeCommand("rtk ls -la"), true);
assert.equal(isSafeCommand("rtk git push"), false); // destructive survives the rewrite
assert.equal(isSafeCommand("rtk rm -rf /"), false);
assert.equal(isSafeCommand("rtk npm install"), false);
assert.equal(isSafeCommand("rtk git status && rm -rf /"), false);
console.log("plan-mode isSafeCommand: ok");
