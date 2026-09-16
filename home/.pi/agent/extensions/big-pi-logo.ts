import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import { VERSION } from "@earendil-works/pi-coding-agent";

const BAR = "█".repeat(30);
const LEG = "   ██████            ██████";
const ART = [BAR, ...Array(7).fill(LEG)];

type Layer = "front" | "shadow";
type Paint = (layer: Layer, text: string) => string;

/** ART + tidy 3d: `dx`-col right face, `dy`-row bottom face under the base row only. */
export function buildLogo(paint: Paint, dx = 2, dy = 1): string[] {
	const w = Math.max(...ART.map((l) => l.length)) + dx;
	const grid = Array.from({ length: ART.length + dy }, () => new Array(w).fill(0));
	const set = (y: number, x: number, v: number) => {
		if (y < grid.length && x < w && grid[y][x] < v) grid[y][x] = v;
	};
	ART.forEach((line, y) =>
		[...line].forEach((ch, x) => {
			if (ch === " ") return;
			for (let d = 1; d <= dx; d++) set(y, x + d, 1); // right face
			if (y === ART.length - 1)
				for (let d = 1; d <= dy; d++)
					for (let k = 0; k <= dx; k++) set(y + d, x + k, 1); // base face closes the corner
			set(y, x, 2);
		}),
	);
	// collapse rows into same-layer runs so ANSI codes stay sparse
	return grid.map((row) => {
		let out = "";
		for (let i = 0; i < row.length; ) {
			let j = i;
			while (j < row.length && row[j] === row[i]) j++;
			const text = (row[i] === 2 ? "█" : row[i] === 1 ? "░" : " ").repeat(j - i);
			out += row[i] === 0 ? text : paint(row[i] === 2 ? "front" : "shadow", text);
			i = j;
		}
		return out.trimEnd();
	});
}

export default function (pi: ExtensionAPI) {
	// ponytail: fixed 30x8 logo extruded 2 deep. Raise depth for chunkier 3d; no width clamping until art > ~60 cols.
	const paintFor =
		(theme: Theme): Paint =>
		(layer, text) =>
			theme.fg(layer === "front" ? "accent" : "muted", text);
	// ponytail: shade = "muted" + "░". brighter: "▒"/"▓" char, or "borderAccent" role.

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		ctx.ui.setHeader((_tui, theme) => {
			const art = buildLogo(paintFor(theme));
			return {
				render: () => ["", ...art, theme.fg("dim", `  π · v${VERSION}`), ""],
				invalidate() {},
			};
		});
	});

	pi.registerCommand("builtin-header", {
		description: "Restore built-in header with keybinding hints",
		handler: async (_args, ctx) => {
			ctx.ui.setHeader(undefined);
			ctx.ui.notify("Built-in header restored", "info");
		},
	});
}

// self-check: `bun ~/.pi/agent/extensions/big-pi-logo.ts`
if (import.meta.main) {
	const fail = (m: string): never => {
		throw new Error(`big-pi-logo self-check: ${m}`);
	};
	const rows = buildLogo((_l, t) => t);
	if (rows.length !== ART.length + 1) fail(`row count ${rows.length}`);
	if (Math.max(...rows.map((r) => r.length)) !== 32) fail("width");
	if (rows.filter((r) => r.includes("█")).length !== ART.length) fail("front rows");
	if (!rows.some((r) => r.includes("░"))) fail("no shade");
	// one contiguous shade run per leg on the base row, no stray cells left of the legs
	if ((rows.at(-1)!.match(/░+/g) ?? []).length !== 2) fail("ragged base face");
	console.log(`${rows.map((r) => r.padEnd(32)).join("\n")}\nself-check ok`);
}
