---
name: update
description: Update unsolicited-text to the latest version
---

# Updating unsolicited-text

Running this skill is the go-ahead. Update, then say which version was
installed and which one is now.

Work out which harness the session is in, and how the plugin was installed.
The commands for every install method are at the end of this file.

Stop and ask before anything they do not carry, and before a command that
removes an install rather than moving it forward.

## Afterwards

The session already running holds the old copy, so run the reload skill, which
prints the rules again whatever the install method. Say that a restart is needed
only where the script cannot be found.

If the version does not move, the marketplace snapshot is what is stale: the
first of the two commands failed or was skipped.

If it was already the latest, say so and change nothing.

## UPDATE.md, as it stands in this copy

You update the way you installed.

### 1. Claude Code, ZCode

    claude plugin marketplace update unsolicited-text
    claude plugin update unsolicited-text@unsolicited-text

A session already running holds the old copy, so restart it or run
`/reload-plugins`.

#### Cloud sessions

Installed by the Cloud Session Install Script from
🔗 [the install instructions](https://github.com/justinkek/unsolicited-text/blob/main/INSTALL.md), where the checkout lives at
`/opt/unsolicited-text` inside the container.

For every session, edit anything in the Setup script field of your cloud
environment. The edit rebuilds the environment, which runs the script again and
pulls the latest release. An untouched environment rebuilds about weekly on its
own, so it follows releases either way.

For the current session, run `/unsolicited-text-update`, or ask the agent to
update unsolicited-text.

(audience: agents) Run the refresh script. Pulling the checkout on its own is not an update.

    printf '{}' | /opt/unsolicited-text/harness-adapters/claude-code/refresh-cloud.sh

(audience: agents) Then follow 🔗 [RELOAD.md](https://github.com/justinkek/unsolicited-text/blob/main/RELOAD.md) to print the rules again.

Run `/reload-skills` to finish.

### 2. Codex

    codex plugin marketplace upgrade unsolicited-text
    codex plugin add unsolicited-text@unsolicited-text

Running `add` again re-installs at the snapshot's version; there is no separate
update command.

### 3. Pi

    pi update git:github.com/justinkek/unsolicited-text

### 4. Claude Chat, Cowork

Open the plus menu, then Plugins, then Manage plugins, and update it there.

### Which version is installed

    cat /opt/unsolicited-text/.claude-plugin/plugin.json

On a marketplace install, `claude plugin list` says the same thing.
