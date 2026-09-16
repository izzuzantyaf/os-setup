/**
 * Ask Mode Extension
 *
 * Sibling of plan mode: a read-only Q&A mode. Answers questions and explains
 * code, but never edits and never produces a plan/todo workflow.
 *
 * - /ask command, --ask flag, Ctrl+Alt+A shortcut
 * - Bash restricted to plan mode's read-only allowlist
 * - Mutually exclusive with plan mode via pi.events
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { isSafeCommand } from "../plan-mode/utils.ts";

export const ASK_MODE_TOOLS = ["read", "bash", "grep", "find", "ls", "questionnaire"];
export const NORMAL_MODE_TOOLS = ["read", "bash", "edit", "write"];
const DISABLED_TOOLS = new Set<string>(["edit", "write"]);
const MANAGED_TOOLS = new Set<string>([...ASK_MODE_TOOLS, ...NORMAL_MODE_TOOLS]);

const unique = (names: string[]): string[] => [...new Set(names)];

/** Keep every active tool except the write tools, and ensure the read-only set. */
export function getAskModeTools(activeToolNames: string[]): string[] {
	return unique([...activeToolNames.filter((name) => !DISABLED_TOOLS.has(name)), ...ASK_MODE_TOOLS]);
}

/** Restore the core tools and preserve any tools neither mode manages. */
export function getNormalModeTools(activeToolNames: string[]): string[] {
	return unique([...NORMAL_MODE_TOOLS, ...activeToolNames.filter((name) => !MANAGED_TOOLS.has(name))]);
}

interface AskModeState {
	enabled: boolean;
	toolsBeforeAskMode?: string[];
}

export default function askModeExtension(pi: ExtensionAPI): void {
	let enabled = false;
	let toolsBeforeAskMode: string[] | undefined;
	let currentCtx: ExtensionContext | undefined;

	function updateStatus(ctx: ExtensionContext): void {
		ctx.ui.setStatus("ask-mode", enabled ? ctx.ui.theme.fg("accent", "❓ ask") : undefined);
	}

	function persistState(): void {
		pi.appendEntry("ask-mode", { enabled, toolsBeforeAskMode } satisfies AskModeState);
	}

	function enableAskModeTools(): void {
		if (toolsBeforeAskMode === undefined) {
			toolsBeforeAskMode = pi.getActiveTools();
		}
		pi.setActiveTools(getAskModeTools(toolsBeforeAskMode));
	}

	function restoreNormalModeTools(): void {
		pi.setActiveTools(toolsBeforeAskMode ?? getNormalModeTools(pi.getActiveTools()));
		toolsBeforeAskMode = undefined;
	}

	function setEnabled(next: boolean, ctx: ExtensionContext): void {
		if (enabled === next) return;
		enabled = next;
		if (next) {
			enableAskModeTools();
			ctx.ui.notify("Ask mode enabled. Read-only Q&A — no edits.");
		} else {
			restoreNormalModeTools();
			ctx.ui.notify("Ask mode disabled. Full access restored.");
		}
		updateStatus(ctx);
		persistState();
	}

	pi.registerFlag("ask", {
		description: "Start in ask mode (read-only Q&A)",
		type: "boolean",
		default: false,
	});

	pi.registerCommand("ask", {
		description: "Toggle ask mode (read-only Q&A)",
		handler: async () => {
			const wasOn = enabled;
			pi.events.emit("mode:disable", undefined);
			if (!wasOn) pi.events.emit("mode:enable", "ask");
		},
	});

	pi.registerShortcut("ctrl+alt+a", {
		description: "Toggle ask mode",
		handler: async () => {
			const wasOn = enabled;
			pi.events.emit("mode:disable", undefined);
			if (!wasOn) pi.events.emit("mode:enable", "ask");
		},
	});

	// React to the shared mode selector (Tab cycles agent → plan → ask).
	pi.events.on("mode:disable", () => {
		if (currentCtx) setEnabled(false, currentCtx);
	});
	pi.events.on("mode:enable", (data) => {
		if (data === "ask" && currentCtx) setEnabled(true, currentCtx);
	});

	// Block non-allowlisted bash, same floor as plan mode.
	pi.on("tool_call", async (event) => {
		if (!enabled || event.toolName !== "bash") return;
		const command = String(event.input.command ?? "");
		if (!isSafeCommand(command)) {
			return {
				block: true,
				reason: `Ask mode: command blocked (not allowlisted). Use /ask to disable ask mode first.\nCommand: ${command}`,
			};
		}
	});

	// Drop stale ask-mode context once the mode is off.
	pi.on("context", async (event) => {
		if (enabled) return;
		return {
			messages: event.messages.filter((m) => {
				const msg = m as { customType?: string; role?: string; content?: unknown };
				if (msg.customType === "ask-mode-context") return false;
				if (msg.role !== "user") return true;
				if (typeof msg.content === "string") return !msg.content.includes("[ASK MODE ACTIVE]");
				if (Array.isArray(msg.content)) {
					return !msg.content.some(
						(c) => (c as { type?: string; text?: string }).type === "text"
							&& (c as { text?: string }).text?.includes("[ASK MODE ACTIVE]"),
					);
				}
				return true;
			}),
		};
	});

	pi.on("before_agent_start", async () => {
		if (!enabled) return;
		return {
			message: {
				customType: "ask-mode-context",
				content: `[ASK MODE ACTIVE]
You are in ask mode - a read-only Q&A mode.

Restrictions:
- Built-in edit and write tools are disabled
- Other currently active tools remain available
- Bash is restricted to an allowlist of read-only commands

Answer the user's questions and explain the code. Do NOT create a "Plan:" section,
do NOT create todo lists, and do NOT attempt to make changes.
If the user asks for a change, describe what you would do and suggest leaving
ask mode (/ask) to apply it.`,
				display: false,
			},
		};
	});

	pi.on("session_start", async (_event, ctx) => {
		currentCtx = ctx;
		if (pi.getFlag("ask") === true) enabled = true;

		const entries = ctx.sessionManager.getEntries();
		const saved = entries
			.filter((e: { type: string; customType?: string }) => e.type === "custom" && e.customType === "ask-mode")
			.pop() as { data?: AskModeState } | undefined;

		if (saved?.data) {
			enabled = saved.data.enabled ?? enabled;
			toolsBeforeAskMode = saved.data.toolsBeforeAskMode ?? toolsBeforeAskMode;
		}

		if (enabled) {
			enableAskModeTools();
			persistState();
		}
		updateStatus(ctx);
	});
}
