# Installing unsolicited-text

## 1. Claude Code, ZCode

    claude plugin marketplace add justinkek/unsolicited-text
    claude plugin install unsolicited-text@unsolicited-text

In ZCode, add `justinkek/unsolicited-text` through Settings, Marketplace.

Note for agents: Check if `SKIP_PLUGIN_MARKETPLACE` is set before using the above install instructions. If it is set, the user is in a cloud session,and will need to use the installation instructions below.


### Cloud sessions

Claude Code Cloud sessions (e.g. on web/mobile) run in a container rebuilt from scratch and never resolves a marketplace, so the install above does not work. 

There are two ways to install it on cloud sessions: 
1. For all sessions
2. For the current session only

#### This session only

1. Ensure that permission mode to accept edits first, or the auto-permissions classifier refuses the write.
2. Ask the agent to run the "Cloud Session Install Script" (see below). 
3. The hooks will take effect from your next message. Session start has passed, so print the rules once:

    cat /opt/unsolicited-text/rules/reply-shape.md

#### Every session

1. Users will need to paste the "Cloud Session Install Script" (see below) into the Setup script field of your cloud environment.

#### Cloud Session Install Script

```bash
#!/bin/bash
git clone --depth 1 https://github.com/justinkek/unsolicited-text /opt/unsolicited-text || true
mkdir -p "$HOME/.claude"
cat > "$HOME/.claude/settings.json" <<'SETTINGS'
{
	"hooks": {
		"SessionStart": [
			{ "hooks": [
				{ "type": "command", "command": "/opt/unsolicited-text/hooks/load-rules.sh" },
				{ "type": "command", "command": "/opt/unsolicited-text/hooks/note-new-version.sh" }
			] }
		],
		"UserPromptSubmit": [
			{ "hooks": [
				{ "type": "command", "command": "/opt/unsolicited-text/hooks/remind-response-length.sh" },
				{ "type": "command", "command": "/opt/unsolicited-text/hooks/replay-stop-notes.sh" }
			] }
		],
		"Stop": [
			{ "hooks": [
				{ "type": "command", "command": "/opt/unsolicited-text/hooks/note-long-reply.sh" },
				{ "type": "command", "command": "/opt/unsolicited-text/hooks/note-long-queue.sh" }
			] }
		]
	}
}
SETTINGS
```

Note for agents: It overwrites `~/.claude/settings.json`, so fold in anything already there rather
than pasting over it.

## 2. Codex

    codex plugin marketplace add justinkek/unsolicited-text
    codex plugin add unsolicited-text@unsolicited-text

Codex does not run a plugin's own hooks yet
([openai/codex#16430](https://github.com/openai/codex/issues/16430)), so register
them by hand in `~/.codex/config.toml`:

    [[hooks.SessionStart]]
    [[hooks.SessionStart.hooks]]
    type = "command"
    command = "<path to this checkout>/hooks/load-rules.sh"

    [[hooks.SessionStart.hooks]]
    type = "command"
    command = "<path to this checkout>/hooks/note-new-version.sh"

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

    [[hooks.Stop.hooks]]
    type = "command"
    command = "<path to this checkout>/hooks/note-long-queue.sh"

## 3. Pi

    pi install git:github.com/justinkek/unsolicited-text

## Uninstalling

For uninstalling, see 🔗 [the uninstall instructions](UNINSTALL.md).
