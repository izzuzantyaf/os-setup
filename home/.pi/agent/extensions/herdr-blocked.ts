/**
 * Bridge Pi's blocking UI prompts to herdr's `blocked` agent state.
 *
 * herdr's managed integration (herdr-agent-state.ts) listens for
 * `herdr:blocked`, but nothing in this setup emits it. Because that
 * integration is the lifecycle authority for Pi once installed, herdr does
 * not fall back to screen detection — so without this the pane reads
 * `working` while Pi waits on a question and "needs input" notifications
 * never fire. Sits beside the managed file, per its own header.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	pi.on("ui_prompt_start", (event) => {
		pi.events.emit("herdr:blocked", {
			active: true,
			label: event.title ? `${event.kind}: ${event.title}` : event.kind,
		});
	});

	pi.on("ui_prompt_end", () => {
		pi.events.emit("herdr:blocked", { active: false });
	});
}
