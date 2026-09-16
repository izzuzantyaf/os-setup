// Self-check: bun ~/.pi/agent/extensions/ask-mode/check.ts
// (not a discovered extension — only */index.ts is auto-loaded)
//
// Exercises the shared mode selector's pure logic and ask mode's toggle /
// mutual exclusion, using a fake ExtensionAPI.
import assert from "node:assert/strict";
import askModeExtension from "./index.ts";
import { modeFromEntries, nextMode, switchMode } from "../modes/index.ts";
import { isSafeCommand } from "../plan-mode/utils.ts";

type Handler = (event?: unknown, ctx?: unknown) => unknown;

function fakePi() {
	const status: Record<string, string | undefined> = {};
	const entries: Array<{ type: string; customType?: string; data?: unknown }> = [];
	const bus = new Map<string, Array<(data: unknown) => void>>();
	const handlers = new Map<string, Handler>();
	const commands = new Map<string, Handler>();
	let tools = ["read", "bash", "edit", "write", "custom_tool"];

	const pi = {
		getFlag: () => false,
		getActiveTools: () => [...tools],
		setActiveTools: (names: string[]) => {
			tools = [...names];
		},
		appendEntry: (customType: string, data?: unknown) => entries.push({ type: "custom", customType, data }),
		sendMessage: () => {},
		registerFlag: () => {},
		registerCommand: (name: string, opts: { handler: Handler }) => commands.set(name, opts.handler),
		registerShortcut: () => {},
		on: (event: string, handler: Handler) => {
			handlers.set(event, handler);
		},
		events: {
			emit: (channel: string, data: unknown) => bus.get(channel)?.forEach((h) => h(data)),
			on: (channel: string, handler: (data: unknown) => void) => {
				bus.set(channel, [...(bus.get(channel) ?? []), handler]);
			},
		},
	};

	const ctx = {
		cwd: process.cwd(),
		hasUI: true,
		ui: {
			theme: { fg: (_c: string, t: string) => t },
			setStatus: (k: string, v: string | undefined) => {
				status[k] = v;
			},
			notify: () => {},
			confirm: async () => true,
		},
		sessionManager: { getEntries: () => entries },
	};

	return { pi, ctx, status, tools: () => tools, handlers, commands };
}

// modeFromEntries reflects the extension entries pi persists.
assert.equal(modeFromEntries([]), "off");
assert.equal(modeFromEntries([{ type: "custom", customType: "plan-mode", data: { enabled: false } }]), "off");
assert.equal(modeFromEntries([{ type: "custom", customType: "plan-mode", data: { enabled: true } }]), "plan");
assert.equal(modeFromEntries([{ type: "custom", customType: "ask-mode", data: { enabled: true } }]), "ask");
assert.equal(
	modeFromEntries([
		{ type: "custom", customType: "plan-mode", data: { enabled: true } },
		{ type: "custom", customType: "plan-mode", data: { enabled: false } },
	]),
	"off",
);
// If both were persisted on, the most recent wins.
assert.equal(
	modeFromEntries([
		{ type: "custom", customType: "plan-mode", data: { enabled: true } },
		{ type: "custom", customType: "ask-mode", data: { enabled: true } },
	]),
	"ask",
);

// Tab cycle order: agent → plan → ask → agent.
assert.equal(nextMode("off"), "plan");
assert.equal(nextMode("plan"), "ask");
assert.equal(nextMode("ask"), "off");

// Ask mode toggle through the real factory.
const { pi, ctx, status, tools, handlers, commands } = fakePi();
askModeExtension(pi as never);
await handlers.get("session_start")?.({}, ctx);

const before = tools();
await commands.get("ask")!("", ctx);
assert.ok(!tools().includes("edit") && !tools().includes("write"), "ask mode must strip write tools");
assert.ok(tools().includes("read") && tools().includes("custom_tool"), "ask mode keeps read + unmanaged tools");
assert.equal(status["ask-mode"], "❓ ask");

// A switch to plan mode disables ask mode and restores the previous tool set.
switchMode(pi as never, "plan");
assert.equal(status["ask-mode"], undefined, "a plan-mode switch must disable ask mode");
assert.deepEqual([...tools()].sort(), [...before].sort(), "ask mode must restore the previous tool set");

// Bash floor is plan mode's allowlist.
assert.equal(isSafeCommand("rm -rf /tmp/x"), false);
assert.equal(isSafeCommand("git status"), true);

console.log("ask-mode: all checks passed");
