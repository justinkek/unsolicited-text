import { execFileSync } from "node:child_process";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

type ExtensionAPI = { on: (event: string, handler: (event: any, ctx: any) => any) => void };

// The hooks this plugin registers, by the event each one answers to.
const registered: Record<string, string[]> = {"SessionStart":["load-rules.sh","mark-session-started.sh"],"UserPromptSubmit":["note-a-new-version.sh","print-session-start-if-missed.sh","remind-response-length.sh","replay-notes.sh"],"Stop":["note-long-reply.sh","note-long-queue.sh"]};

const hooks = join(dirname(fileURLToPath(import.meta.url)), "..", "hooks");
const notes = mkdtempSync(join(tmpdir(), "unsolicited-text-notes-"));
const session = "pi";
let started = false;

function spawnHook(script: string, payload: Record<string, unknown>): string {
	try {
		return execFileSync("bash", [join(hooks, script)], {
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

// Pi names its tools and their fields its own way. A hook reads the names every
// other client sends.
const toolNames: Record<string, string> = {
	read: "Read",
	write: "Write",
	edit: "Edit",
	bash: "Bash",
	grep: "Grep",
	find: "Glob",
	ls: "LS",
};

// Every hook registered on the tool call answers, and the answers are merged by
// the same library the hooks speak through: deny outranks ask, ask outranks allow.
function decided(event: any, ctx: any): { decision: string; reason: string } | undefined {
	const scripts = registered.PreToolUse ?? [];
	if (scripts.length === 0) return undefined;
	const input = event?.input ?? {};
	const payload = {
		hook_event_name: "PreToolUse",
		cwd: ctx?.cwd ?? process.cwd(),
		tool_name: toolNames[event?.toolName] ?? event?.toolName,
		tool_input: { ...input, file_path: input.path, old_string: input.oldText, new_string: input.newText },
	};
	const answers = scripts.map((script) => spawnHook(script, payload)).join("\n");
	let strongest = "";
	try {
		strongest = execFileSync("bash", ["-c", `. "${join(hooks, "lib", "permission.sh")}"; strongest_permission`], {
			input: answers,
			encoding: "utf8",
		}).trim();
	} catch {
		return { decision: "deny", reason: "unsolicited-text could not read what its hooks decided." };
	}
	if (!strongest) return undefined;
	try {
		const said = JSON.parse(strongest)?.hookSpecificOutput ?? {};
		return { decision: said.permissionDecision ?? "deny", reason: said.permissionDecisionReason ?? "" };
	} catch {
		return { decision: "deny", reason: "unsolicited-text could not read what its hooks decided." };
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
		// The session start hooks speak once, when the first turn of the session starts.
		const opening = started ? [] : ran("SessionStart", {});
		started = true;
		const content = [...opening, ...ran("UserPromptSubmit", {})].filter(Boolean).join("\n");
		return content ? { message: { customType: "unsolicited-text", content, display: true } } : undefined;
	});

	pi.on("tool_call", async (event: any, ctx: any) => {
		const answer = decided(event, ctx);
		if (!answer || answer.decision === "allow") return undefined;
		if (answer.decision === "ask" && ctx?.hasUI && ctx?.ui?.confirm) {
			if (await ctx.ui.confirm("unsolicited-text", answer.reason)) return undefined;
		}
		return { block: true, reason: answer.reason };
	});

	pi.on("turn_end", async (event: any) => {
		// Pi hands over the turn's reply; the stop hooks read a transcript, so
		// it is written out as one.
		const transcript = join(notes, "turn.jsonl");
		writeFileSync(transcript, `${JSON.stringify({ type: "assistant", message: { content: [{ type: "text", text: textOf(event?.message) }] } })}\n`);
		ran("Stop", { transcript_path: transcript });
	});
}
