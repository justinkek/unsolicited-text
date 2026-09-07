# Installing unsolicited-text

Four hook scripts and the rules they hold a reply to. Every harness runs the
same four; only the registration differs.

## 1. Claude Code, ZCode

    claude plugin marketplace add justinkek/unsolicited-text
    claude plugin install unsolicited-text@unsolicited-text

In ZCode, add `justinkek/unsolicited-text` through Settings, Marketplace. It preloads the Claude Code marketplace format and reads the same two manifests.

### A single cloud session

Wherever Claude Code runs in a container rebuilt from scratch - on the web, from a
phone, on a CI runner - it never resolves a marketplace, so the install above
reports nothing and loads nothing. `SKIP_PLUGIN_MARKETPLACE` is set in the
environment, and `~/.claude/plugins/installed_plugins.json` stays empty however
many times you run it.

Hooks themselves run there, and a settings file written mid-session is picked up
while that session is still going, so one session can carry the plugin without
installing anything. What follows is written in Claude Code's own settings format,
which ZCode reads too; the other two harnesses register hooks their own way and
this route has not been tried on either. Fetch it:

    git clone --depth 1 https://github.com/justinkek/unsolicited-text ~/.unsolicited-text/checkout

Then write `.claude/settings.local.json` in the working directory:

```json
{
	"hooks": {
		"SessionStart": [
			{ "hooks": [
				{ "type": "command", "command": "$HOME/.unsolicited-text/checkout/hooks/load-agents-md.sh" },
				{ "type": "command", "command": "$HOME/.unsolicited-text/checkout/hooks/note-new-version.sh" }
			] }
		],
		"UserPromptSubmit": [
			{ "hooks": [
				{ "type": "command", "command": "$HOME/.unsolicited-text/checkout/hooks/remind-response-length.sh" },
				{ "type": "command", "command": "$HOME/.unsolicited-text/checkout/hooks/replay-stop-notes.sh" }
			] }
		],
		"Stop": [
			{ "hooks": [
				{ "type": "command", "command": "$HOME/.unsolicited-text/checkout/hooks/note-long-reply.sh" },
				{ "type": "command", "command": "$HOME/.unsolicited-text/checkout/hooks/note-long-queue.sh" }
			] }
		]
	}
}
```

Write out `$HOME` as the path it stands for if your harness does not expand it in
a hook command.

Two things follow from writing it mid-session. The file is untracked, so nothing
reaches the repository or anyone else working in it, and the container takes it
away when the session ends, so this is the throwaway route rather than the one to
standardise on. And the rules load at session start, which
has already happened, so print them into the session once:

    cat ~/.unsolicited-text/checkout/AGENTS.md

Every turn after that is covered by the hooks above, which need no restart.

### A repository that carries it

The route above lasts one session. To have every session in a repository load it -
yours, a teammate's, a hosted one, a run on CI - the repository carries the plugin
itself and names it in settings everyone gets on clone. Nobody installs anything.

Copy the scripts and the rules in, keeping them together as the plugin ships them:

    git clone --depth 1 https://github.com/justinkek/unsolicited-text /tmp/unsolicited-text
    mkdir -p .claude/unsolicited-text
    cp -R /tmp/unsolicited-text/hooks /tmp/unsolicited-text/AGENTS.md .claude/unsolicited-text/

Then commit `.claude/settings.json` naming them from the project root, which
`${CLAUDE_PROJECT_DIR}` stands for wherever the repository is checked out:

```json
{
	"hooks": {
		"SessionStart": [
			{ "hooks": [
				{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/unsolicited-text/hooks/load-agents-md.sh" },
				{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/unsolicited-text/hooks/note-new-version.sh" }
			] }
		],
		"UserPromptSubmit": [
			{ "hooks": [
				{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/unsolicited-text/hooks/remind-response-length.sh" },
				{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/unsolicited-text/hooks/replay-stop-notes.sh" }
			] }
		],
		"Stop": [
			{ "hooks": [
				{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/unsolicited-text/hooks/note-long-reply.sh" },
				{ "type": "command", "command": "${CLAUDE_PROJECT_DIR}/.claude/unsolicited-text/hooks/note-long-queue.sh" }
			] }
		]
	}
}
```

Three things to know before you commit it. Everyone who works in the repository
gets these rules, so agree them first - a reply shape is a house style, not a
lint rule you can slip in. A copy does not update itself: repeat the two commands
above to move it forward, and the diff shows exactly what changed. And hooks in a
project settings file run once the folder is trusted, so the first session in a
fresh checkout asks before any of this takes effect.

This is Claude Code's settings format, which ZCode reads as well. Codex reads a
project layer of its own and Pi installs into a project directory of its own;
neither is written up here yet, because neither has been tried.

## 2. Codex

    codex plugin marketplace add justinkek/unsolicited-text
    codex plugin add unsolicited-text@unsolicited-text

Codex does not run a plugin's own `hooks.json` yet
([openai/codex#16430](https://github.com/openai/codex/issues/16430)), checked on codex-cli 0.144.5: the plugin installs and reports itself enabled, and a session fires none of its hooks. Until that changes, register the same four commands by hand in `~/.codex/config.toml`, which is the layer Codex does read:

    [[hooks.SessionStart]]
    [[hooks.SessionStart.hooks]]
    type = "command"
    command = "<path to this checkout>/hooks/load-agents-md.sh"

    [[hooks.UserPromptSubmit]]
    [[hooks.UserPromptSubmit.hooks]]
    type = "command"
    command = "<path to this checkout>/hooks/remind-response-length.sh"

    [[hooks.UserPromptSubmit.hooks]]
    type = "command"
    command = "<path to this checkout>/hooks/replay-stop-notes.sh"

    [[hooks.Stop]]
    [[hooks.Stop.hooks]]
    type = "command"
    command = "<path to this checkout>/hooks/note-long-reply.sh"

Codex asks you to trust each command the first time it meets it, and they stay trusted until the command text changes. The session start hook prints the rules into the session, so registering these four is all a Codex session needs - you do not have to put the rules in `~/.codex/AGENTS.md` as well. Keep the plugin installed alongside: when plugin hooks land, delete this block.

## 3. Pi

    pi install git:github.com/justinkek/unsolicited-text

Pi cannot register a subprocess, so `harness-adapters/pi/src/index.ts` is a shim: it builds the same line of JSON each script already reads on stdin, spawns the script, and returns what it printed. It carries no rule of its own, and it needs a shell on the machine, which the other three already require.

To take it back off, 🔗 [check the uninstall instructions](UNINSTALL.md).
