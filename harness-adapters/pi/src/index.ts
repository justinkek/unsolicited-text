import { execFileSync } from "node:child_process";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

type ExtensionAPI = { on: (event: string, handler: (event: any, ctx: any) => any) => void };

const hooks = join(dirname(fileURLToPath(import.meta.url)), "..", "..", "..", "hooks");
const notes = mkdtempSync(join(tmpdir(), "unsolicited-text-notes-"));
const session = "pi";
let held = "";

function spawnHook(script: string, payload: Record<string, unknown>): string {
	try {
		return execFileSync(join(hooks, script), {
			input: JSON.stringify({ session_id: session, ...payload }),
			env: { ...process.env, UNSOLICITED_TEXT_STOP_NOTE_DIRECTORY: notes },
			encoding: "utf8",
		}).trim();
	} catch {
		return "";
	}
}

function textOf(message: any): string {
	const content = message?.content ?? "";
	if (typeof content === "string") return content;
	return content
		.filter((part: any) => part?.type === "text")
		.map((part: any) => part.text)
		.join("\n");
}

export default function (pi: ExtensionAPI) {
	pi.on("before_agent_start", async () => {
		const content = [spawnHook("remind-response-length.sh", {}), held].filter(Boolean).join("\n");
		held = "";
		return content ? { message: { customType: "unsolicited-text", content, display: true } } : undefined;
	});

	pi.on("turn_end", async (event: any) => {
		const transcript = join(notes, "turn.jsonl");
		writeFileSync(transcript, `${JSON.stringify({ type: "assistant", message: { content: [{ type: "text", text: textOf(event?.message) }] } })}\n`);
		spawnHook("note-long-reply.sh", { transcript_path: transcript });
		held = spawnHook("replay-stop-notes.sh", {});
	});
}
