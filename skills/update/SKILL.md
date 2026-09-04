---
name: update
description: Update unsolicited-text to the latest version
---

# Updating unsolicited-text

Say which version is installed and which is out, and ask before running
anything. These commands change what is installed on the machine.

Work out which harness the session is in, and run its pair. A marketplace
snapshot on disk is only refreshed by the first command, so the second has
nothing newer to install without it.

## Claude Code, ZCode

    claude plugin marketplace update unsolicited-text
    claude plugin update unsolicited-text@unsolicited-text

## Codex

    codex plugin marketplace upgrade unsolicited-text
    codex plugin add unsolicited-text@unsolicited-text

Running `add` again on an installed plugin re-installs it at the snapshot's
version; there is no separate update command.

## Pi

    pi update git:github.com/justinkek/unsolicited-text

## Afterwards

The session already running holds the old copy. Say that it takes a restart.

If the version does not move, the snapshot is what is stale: the first command
failed or was skipped.
