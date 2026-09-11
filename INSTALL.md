# Installing unsolicited-text

(audience: humans)

## 1. Claude Code, ZCode

    claude plugin marketplace add justinkek/unsolicited-text
    claude plugin install unsolicited-text@unsolicited-text

In ZCode, add `justinkek/unsolicited-text` through Settings, Marketplace.

(audience: agents) Check whether `SKIP_PLUGIN_MARKETPLACE` is set before using the install instructions above. If it is set, the user is in a cloud session and needs the instructions below.

### Cloud sessions

Claude Code cloud sessions, on the web or on a phone, run in a container rebuilt from scratch and never resolve a marketplace, so the install above does not work.

There are two ways to install it on cloud sessions. An agent asks which of the two you want before doing anything:

#### Every session

1. Open 🔗 [claude.ai/code](https://claude.ai/code), open the environment settings, and find the Setup script field. See 🔗 [docs](https://code.claude.com/docs/en/cloud-environments#setup-scripts).
2. Paste the "Cloud Session Install Script" (see below) into that field and save. The field is yours to edit, so an agent prints the steps and the script for you rather than pasting them itself.
3. Start a new session. The environment rebuilds and runs the script before the session begins.

Every session start refreshes the checkout from the published version before the rules are printed, and says so when there is a new version.

#### This session only

1. Set your permission mode to accept edits, or the auto-permissions classifier refuses the write.
2. Ask the agent to run the "Cloud Session Install Script" (see below).
3. The hooks take effect from your next message. Session start has passed, so the agent prints the rules into the session once, with the command in 🔗 [RELOAD.md](RELOAD.md).
4. Run `/reload-skills` to list the settings and update skills. `/reload-plugins` does not work over a remote connection, and this install method adds no plugin. The `/unsolicited-text-settings` and `/unsolicited-text-update` menu entries arrive on their own a moment later.

The container takes all of it away when the session ends.

#### Cloud Session Install Script

Paste this once.

```bash
#!/bin/bash
if git clone --depth 1 https://github.com/justinkek/unsolicited-text /opt/unsolicited-text.new; then
	rm -rf /opt/unsolicited-text
	mv /opt/unsolicited-text.new /opt/unsolicited-text
else
	echo "unsolicited-text: the clone failed, keeping whatever was already there" >&2
	rm -rf /opt/unsolicited-text.new
fi
/opt/unsolicited-text/harness-adapters/claude-code/install-cloud.sh || true
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

## A harness that runs no hooks

The chat interface at claude.ai is one: a skill installs and appears, and no
session start, prompt or turn end runs a script. Everything this plugin does
comes from `hooks/`, so none of it happens there. The settings and update
skills still appear, and they change and fetch what is not running.

What works instead is the harness's own way of holding text across a
conversation - user preferences, or a custom style. Paste
`rules/reply-shape.md` into one of those and the replies take their shape from
it. What you lose is the note at the end of a long turn, which is what catches
drift over a long conversation.

## Updating

For updating, see 🔗 [the update instructions](UPDATE.md).

## Uninstalling

For uninstalling, see 🔗 [the uninstall instructions](UNINSTALL.md).
