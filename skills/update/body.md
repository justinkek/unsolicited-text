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

When one of them fails on the machine rather than on the plugin - a licence to
accept, a credential to enter, a tool that is missing - say which command failed
and what it asked for, and hand that fix to me to run myself. Never run a
command that asks for a password, and never run one the steps do not carry.

## Afterwards

The session already running holds the old copy, so run the reload skill, which
prints the rules again whatever the install method. Say that a restart is needed
only where the script cannot be found.

If the version does not move, the marketplace snapshot is what is stale: the
first of the two commands failed or was skipped.

If it was already the latest, say so and change nothing.
