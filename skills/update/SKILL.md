---
name: update
description: Update unsolicited-text to the latest version
---

# Updating unsolicited-text

Running this skill is the go-ahead. Update, then say which version was
installed and which one is now.

Work out which harness the session is in, and how the plugin was installed.
🔗 [UPDATING.md](../../UPDATING.md) carries the commands for every route,
including a cloud session, where the checkout sits at `/opt/unsolicited-text`
and no marketplace is involved.

Stop and ask before anything the page does not carry, and before a command
that removes an install rather than moving it forward.

## Afterwards

The session already running holds the old copy. Say that it takes a restart.
On the cloud route, print the rules again from the session start hook instead:
`printf '{}' | /opt/unsolicited-text/hooks/load-rules.sh`

If the version does not move, the marketplace snapshot is what is stale: the
first of the two commands failed or was skipped.

If it was already the latest, say so and change nothing.
