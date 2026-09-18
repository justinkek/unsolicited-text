(audience: agents) Run the two commands below. Do not clone this repository, and
do not copy any file into place: those two commands are the whole install, and
`/plugins` in the command line or the Plugins tab in the app does the same thing.
Print the hook blocks further down for the person to paste, because the config
file is theirs to edit.

    codex plugin marketplace add justinkek/unsolicited-text
    codex plugin add unsolicited-text@unsolicited-text

Codex does not run a plugin's own hooks yet
([openai/codex#16430](https://github.com/openai/codex/issues/16430)), so register
them by hand. The second command above ends by naming the directory it wrote:

    Installed plugin root: <plugin root>

The file to edit is `config.toml` inside the Codex home this session runs from,
which is not always `~/.codex`:

    printenv CODEX_HOME || echo ~/.codex

Add these blocks to it, with that plugin root in place of
`<path to this checkout>`:

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
