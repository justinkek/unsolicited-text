# Installing unsolicited-text

## 1. Claude Code, ZCode

    claude plugin marketplace add justinkek/unsolicited-text
    claude plugin install unsolicited-text@unsolicited-text

In ZCode, add `justinkek/unsolicited-text` through Settings, Marketplace.

### Cloud sessions

Claude Code on the web, on a phone, or on a CI runner runs in a container rebuilt
from scratch, and never resolves a marketplace: the install above reports nothing
and loads nothing. `SKIP_PLUGIN_MARKETPLACE` is set there, and
`~/.claude/plugins/installed_plugins.json` stays empty however many times you run
it.

This script installs it in the container instead. There are two ways to run it,
and they differ only in who runs it:

1. Paste it into the Setup script field of your environment, at claude.ai/code.
   Every session that environment starts from then on has the plugin, and the
   script re-runs on its own about weekly, so it follows releases.
2. Ask the agent to run it in the session you are already in. That covers this
   one session. Set your permission mode to accept edits first, or the classifier
   refuses the write.

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

It overwrites `~/.claude/settings.json`, so fold in anything already there rather
than pasting over it.

Run in a session already going, the hooks take effect from your next message, but
session start has passed, so print the rules once:

    cat /opt/unsolicited-text/rules/reply-shape.md

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

Codex asks you to trust each command the first time it meets it.

## 3. Pi

    pi install git:github.com/justinkek/unsolicited-text

Pi needs a shell on the machine, which the other harnesses already require.

To take it back off, 🔗 [check the uninstall instructions](UNINSTALL.md).
