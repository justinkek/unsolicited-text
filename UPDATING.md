# Updating unsolicited-text

The route you installed by is the route you update by.

## 1. Claude Code, ZCode

    claude plugin marketplace update unsolicited-text
    claude plugin update unsolicited-text@unsolicited-text

The first command refreshes the marketplace snapshot on disk. Without it the
second has nothing newer to install. A session already running holds the old
copy, so restart it.

### Cloud sessions

Installed by the Cloud Session Install Script from
🔗 [the install instructions](INSTALL.md), where the checkout lives at
`/opt/unsolicited-text` inside the container.

For every session, edit anything in the Setup script field of your cloud
environment. The edit rebuilds the environment, which runs the script again and
pulls the latest release. An untouched environment rebuilds about weekly on its
own, so it follows releases either way.

For the current session, ask the agent to run the script again. The hooks take
effect from your next message, and session start has passed, so ask it to print
`/opt/unsolicited-text/rules/reply-shape.md` into the session as well.

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
