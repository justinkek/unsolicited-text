import { execFileSync } from "node:child_process";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

type ExtensionAPI = { on: (event: string, handler: (event: any, ctx: any) => any) => void };

// The hooks this plugin registers, by the event each one answers to.
const registered: Record<string, string[]> = {"SessionStart":["load-rules.sh","mark-session-started.sh"],"UserPromptSubmit":["print-session-start-if-missed.sh","remind-response-length.sh","replay-stop-notes.sh","note-new-version.sh"],"Stop":["note-long-reply.sh","note-long-queue.sh"]};

const hooks = join(dirname(fileURLToPath(import.meta.url)), "..", "hooks");
const notes = mkdtempSync(join(tmpdir(), "unsolicited-text-notes-"));
const session = "pi";
let started = false;

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

// A hook may answer with JSON meant for a harness that reads it; Pi shows text.
function said(output: string): string {
	if (!output.startsWith("{")) return output;
	try {
		const answer = JSON.parse(output);
		return answer?.hookSpecificOutput?.additionalContext ?? answer?.systemMessage ?? "";
	} catch {
		return output;
	}
}

function ran(event: string, payload: Record<string, unknown>): string[] {
	return (registered[event] ?? []).map((script) => said(spawnHook(script, { hook_event_name: event, ...payload })));
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
		// The session start hooks speak once, when the first turn of the session starts.
		const opening = started ? [] : ran("SessionStart", {});
		started = true;
		const content = [...opening, ...ran("UserPromptSubmit", {})].filter(Boolean).join("\n");
		return content ? { message: { customType: "unsolicited-text", content, display: true } } : undefined;
	});

	pi.on("turn_end", async (event: any) => {
		// Pi hands over the turn's reply; the stop hooks read a transcript, so
		// it is written out as one.
		const transcript = join(notes, "turn.jsonl");
		writeFileSync(transcript, `${JSON.stringify({ type: "assistant", message: { content: [{ type: "text", text: textOf(event?.message) }] } })}\n`);
		ran("Stop", { transcript_path: transcript });
	});
}
