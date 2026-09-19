    codex plugin marketplace upgrade unsolicited-text
    codex plugin add unsolicited-text@unsolicited-text

Running `add` again re-installs at the snapshot's version; there is no separate
update command.

An update rewrites the hooks, so Codex marks all seven for review and runs none
of them until you trust them again: `/hooks` in the command line, or Settings,
then Hooks, then Plugin in the desktop app. Then start again.
