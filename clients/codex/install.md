(audience: agents) Do not install this yourself. Print this page for the person
and stop. They run the two commands below, or install from the plugin browser
with `/plugins` in the command line and the Plugins tab in the app, and they
edit their own `~/.codex/config.toml`.

    codex plugin marketplace add justinkek/unsolicited-text
    codex plugin add unsolicited-text@unsolicited-text

Codex does not run a plugin's own hooks yet
([openai/codex#16430](https://github.com/openai/codex/issues/16430)), so register
them by hand in `~/.codex/config.toml`. This prints the path they
need:

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
