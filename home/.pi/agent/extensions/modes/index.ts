/**
 * Mode selector for Tab: agent → plan → ask.
 *
 * plan-mode and ask-mode are separate extensions (plan-mode is an out-of-store
 * symlink, so a shared relative import will not resolve), hence this coordinator
 * knows nothing about them beyond the `mode:disable` / `mode:enable` events.
 * It derives the current mode from the entries those extensions persist, so
 * /plan and /ask stay in sync.
 */
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

export type Mode = "off" | "plan" | "ask";
export const ORDER: Mode[] = ["off", "plan", "ask"];

export const nextMode = (mode: Mode): Mode => ORDER[(ORDER.indexOf(mode) + 1) % ORDER.length];

interface ModeEntry {
	type?: string;
	customType?: string;
	data?: { enabled?: boolean };
}

/** Last enabled mode from the persisted extension entries, or "off". */
export function modeFromEntries(entries: ModeEntry[]): Mode {
	let planIndex = -1;
	let askIndex = -1;
	let planOn = false;
	let askOn = false;
	entries.forEach((entry, i) => {
		if (entry.type !== "custom") return;
		if (entry.customType === "plan-mode") {
			planIndex = i;
			planOn = entry.data?.enabled === true;
		}
		if (entry.customType === "ask-mode") {
			askIndex = i;
			askOn = entry.data?.enabled === true;
		}
	});
	if (planOn && askOn) return askIndex > planIndex ? "ask" : "plan";
	if (askOn) return "ask";
	if (planOn) return "plan";
	return "off";
}

/** Disable every mode, then enable the target. Disabling first keeps tool restore order correct. */
export function switchMode(pi: ExtensionAPI, mode: Mode): void {
	pi.events.emit("mode:disable", undefined);
	if (mode !== "off") pi.events.emit("mode:enable", mode);
}

export default function modeSelector(pi: ExtensionAPI): void {
	pi.registerShortcut("tab", {
		description: "Cycle modes: agent → plan → ask",
		handler: async (ctx: ExtensionContext) =>
			switchMode(pi, nextMode(modeFromEntries(ctx.sessionManager.getEntries() as ModeEntry[]))),
	});
}
