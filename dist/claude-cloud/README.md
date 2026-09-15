# unsolicited-text for Claude Code cloud sessions

(audience: humans)

Everything this install needs is in this folder. It is built from the
repository root by `build`, so edit the sources there rather than these files.

## Installing

A cloud session resolves no marketplace, so the marketplace install does not work. There are two ways to install it there. An agent asks which of the two you want before doing anything:

### Every session

1. Open 🔗 [claude.ai/code](https://claude.ai/code), open the environment settings, and find the Setup script field. See 🔗 [docs](https://code.claude.com/docs/en/cloud-environments#setup-scripts).
2. Paste the "Cloud Session Install Script" (see below) into that field and save. The field is yours to edit, so an agent prints the steps and the script for you rather than pasting them itself.
3. Start a new session. The environment rebuilds and runs the script before the session begins.

### This session only

1. Set your permission mode to accept edits, or the auto-permissions classifier refuses the write.
2. Ask the agent to run the "Cloud Session Install Script" (see below).
3. The hooks take effect from your next message. Session start has passed, so the agent prints the rules into the session once, with the command in 🔗 [RELOAD.md](https://github.com/justinkek/unsolicited-text/blob/main/RELOAD.md).
4. Run `/reload-skills` to list the settings and update skills. `/reload-plugins` does not work over a remote connection, and this install method adds no plugin. The `/unsolicited-text-settings` and `/unsolicited-text-update` menu entries arrive on their own a moment later.

The container takes all of it away when the session ends.

### Cloud Session Install Script

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
/opt/unsolicited-text/dist/claude-cloud/install.sh || true
```
