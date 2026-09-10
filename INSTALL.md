# Installing unsolicited-text

## 1. Claude Code, ZCode

    claude plugin marketplace add justinkek/unsolicited-text
    claude plugin install unsolicited-text@unsolicited-text

In ZCode, add `justinkek/unsolicited-text` through Settings, Marketplace.

Note for agents: check whether `SKIP_PLUGIN_MARKETPLACE` is set before using the install instructions above. If it is set, the user is in a cloud session and needs the instructions below. Ask which of the two routes they want before doing anything. For every session, print the steps and the script for them to paste, since the Setup script field is theirs to edit and not yours. For this session only, run the script yourself, then print `/opt/unsolicited-text/rules/reply-shape.md` into the session, since the user has no shell to run it in and session start has already passed.

### Cloud sessions

Claude Code cloud sessions, on the web or on a phone, run in a container rebuilt from scratch and never resolve a marketplace, so the install above does not work.

There are two ways to install it on cloud sessions:

#### Every session

1. Paste the "Cloud Session Install Script" (see below) into the Setup script field of your cloud environment.
2. Start a new session. The environment runs the script before the session begins.

#### This session only

1. Set your permission mode to accept edits, or the auto-permissions classifier refuses the write.
2. Ask the agent to run the "Cloud Session Install Script" (see below).
3. The hooks take effect from your next message. Session start has passed, so the agent prints the rules into the session once.
4. Run `/reload-skills` to list the settings and update skills. `/reload-plugins` does not work over a remote connection, and this route installs no plugin. The `/unsolicited-text-settings` and `/unsolicited-text-update` menu entries arrive on their own a moment later.

The container takes all of it away when the session ends.

#### Cloud Session Install Script

```bash
#!/bin/bash
git -C /opt/unsolicited-text pull --quiet \
	|| git clone --depth 1 https://github.com/justinkek/unsolicited-text /opt/unsolicited-text \
	|| true
mkdir -p "$HOME/.claude/skills" "$HOME/.claude/commands"
cp -R /opt/unsolicited-text/skills/. "$HOME/.claude/skills/"
for command in /opt/unsolicited-text/commands/*.md; do
	cp "$command" "$HOME/.claude/commands/unsolicited-text-$(basename "$command")"
done
cat > "$HOME/.claude/settings.json" <<'SETTINGS'
{
	"hooks": {
		"SessionStart": [
			{ "hooks": [
				{ "type": "command", "command": "/opt/unsolicited-text/hooks/load-rules.sh" }
			] }
		],
		"UserPromptSubmit": [
			{ "hooks": [
				{ "type": "command", "command": "/opt/unsolicited-text/hooks/remind-response-length.sh" },
				{ "type": "command", "command": "/opt/unsolicited-text/hooks/replay-stop-notes.sh" },
				{ "type": "command", "command": "/opt/unsolicited-text/hooks/note-new-version.sh" }
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

    [[hooks.UserPromptSubmit]]
    [[hooks.UserPromptSubmit.hooks]]
    type = "command"
    command = "<path to this checkout>/hooks/remind-response-length.sh"

    [[hooks.UserPromptSubmit.hooks]]
    type = "command"
    command = "<path to this checkout>/hooks/replay-stop-notes.sh"

    [[hooks.UserPromptSubmit.hooks]]
    type = "command"
    command = "<path to this checkout>/hooks/note-new-version.sh"

    [[hooks.Stop]]
    [[hooks.Stop.hooks]]
    type = "command"
    command = "<path to this checkout>/hooks/note-long-reply.sh"

    [[hooks.Stop.hooks]]
    type = "command"
    command = "<path to this checkout>/hooks/note-long-queue.sh"

## 3. Pi

    pi install git:github.com/justinkek/unsolicited-text

## Updating

For updating, see 🔗 [the update instructions](UPDATING.md).

## Uninstalling

For uninstalling, see 🔗 [the uninstall instructions](UNINSTALL.md).
