# Updating unsolicited-text

(audience: humans)

You update the way you installed.

## 1. Claude Code, ZCode

    claude plugin marketplace update unsolicited-text
    claude plugin update unsolicited-text@unsolicited-text

Without the first, the second has nothing newer to install. A session already
running holds the old copy, so restart it.

### Cloud sessions

Installed by the Cloud Session Install Script from
🔗 [the install instructions](INSTALL.md), where the checkout lives at
`/opt/unsolicited-text` inside the container.

For every session, edit anything in the Setup script field of your cloud
environment. The edit rebuilds the environment, which runs the script again and
pulls the latest release. An untouched environment rebuilds about weekly on its
own, so it follows releases either way.

For the current session, run `/unsolicited-text-update`, or ask for it in plain
words. It pulls the checkout, copies the new skills, commands and hook
registrations into place, says what changed, and prints the rules again.

(audience: agents) Run the refresh script, then print the rules. Pulling the checkout on its own is not an update. 🔗 [RELOAD.md](RELOAD.md) carries the second command.

    printf '{}' | /opt/unsolicited-text/harness-adapters/claude-code/refresh-cloud.sh

The hooks take effect from your next message. Run `/reload-skills` yourself for a
skill the new version adds.

## 2. Codex

    codex plugin marketplace upgrade unsolicited-text
    codex plugin add unsolicited-text@unsolicited-text

Running `add` again re-installs at the snapshot's version; there is no separate
update command.

## 3. Pi

    pi update git:github.com/justinkek/unsolicited-text

## Which version is installed

    cat /opt/unsolicited-text/.claude-plugin/plugin.json

On a marketplace install, `claude plugin list` says the same thing.
