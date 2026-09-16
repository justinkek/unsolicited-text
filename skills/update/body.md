---
name: update
description: Update unsolicited-text to the latest version
---

# Updating unsolicited-text

Running this skill is the go-ahead. Update, then say which version was
installed and which one is now.

The commands for this install are at the end of this file.

Stop and ask before anything they do not carry, and before a command that
removes an install rather than moving it forward.

## Afterwards

The session already running holds the old copy, so run the reload skill, which
prints the rules again whatever the install method. Say that a restart is needed
only where the script cannot be found.

If the version does not move, the marketplace snapshot is what is stale: the
first of the two commands failed or was skipped.

If it was already the latest, say so and change nothing.
