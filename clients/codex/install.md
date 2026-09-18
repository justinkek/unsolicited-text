(audience: agents) Run the two commands below. Do not clone this repository, and
do not copy any file into place: those two commands are the whole install, and
`/plugins` in the command line or the Plugins tab in the app does the same thing.
Print the hook blocks further down for the person to paste, because
`~/.codex/config.toml` is theirs to edit.

    codex plugin marketplace add justinkek/unsolicited-text
    codex plugin add unsolicited-text@unsolicited-text

Codex does not run a plugin's own hooks yet
([openai/codex#16430](https://github.com/openai/codex/issues/16430)), so register
them by hand in `~/.codex/config.toml`. This prints the path
they need:

    find ~/.codex -name load-rules.sh 2>/dev/null

Put the directory it names in place of `<path to this checkout>`:

    [[hooks.SessionStart]]
    [[hooks.SessionStart.hooks]]
    type = "command"
    command = "bash \"<path to this checkout>/hooks/load-rules.sh\""

    [[hooks.UserPromptSubmit]]
    [[hooks.UserPromptSubmit.hooks]]
    type = "command"
    command = "bash \"<path to this checkout>/hooks/print-rules-if-missed.sh\""

    [[hooks.UserPromptSubmit.hooks]]
    type = "command"
    command = "bash \"<path to this checkout>/hooks/remind-response-length.sh\""

    [[hooks.UserPromptSubmit.hooks]]
    type = "command"
    command = "bash \"<path to this checkout>/hooks/replay-stop-notes.sh\""

    [[hooks.UserPromptSubmit.hooks]]
    type = "command"
    command = "bash \"<path to this checkout>/hooks/note-new-version.sh\""

    [[hooks.Stop]]
    [[hooks.Stop.hooks]]
    type = "command"
    command = "bash \"<path to this checkout>/hooks/note-long-reply.sh\""

    [[hooks.Stop.hooks]]
    type = "command"
    command = "bash \"<path to this checkout>/hooks/note-long-queue.sh\""
