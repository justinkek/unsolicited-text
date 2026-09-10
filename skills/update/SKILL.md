---
name: update
description: Update unsolicited-text to the latest version
---

# Updating unsolicited-text

Running this skill is the go-ahead. Update, then say which version was
installed and which one is now.

Work out which harness the session is in, and how the plugin was installed.
🔗 [UPDATING.md](../../UPDATING.md) carries the commands for every install
method,
including a cloud session, where the checkout sits at `/opt/unsolicited-text`
and no marketplace is involved.

Where the page names one script that pulls and installs together, run that and
nothing else. Pulling the checkout on its own is not an update: the session
reads its skills, commands and hook registrations from copies written outside
the checkout, and those stay on the old version until the script writes them.

Stop and ask before anything the page does not carry, and before a command
that removes an install rather than moving it forward.

## Afterwards

The session already running holds the old copy. Print the rules again, whatever
the install method: 🔗 [RELOADING.md](../../RELOADING.md) says where the script
is for each one. Say that a restart is needed only where it cannot be found.

If the version does not move, the marketplace snapshot is what is stale: the
first of the two commands failed or was skipped.

If it was already the latest, say so and change nothing.
