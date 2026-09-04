# Installing unsolicited-text

Four hook scripts and the rules they hold a reply to. Every harness runs the
same four; only the registration differs.

## 1. Claude Code, ZCode

    claude plugin marketplace add justinkek/unsolicited-text
    claude plugin install unsolicited-text@unsolicited-text

In ZCode, add `justinkek/unsolicited-text` through Settings, Marketplace. It preloads the Claude Code marketplace format and reads the same two manifests.

## 2. Codex

    codex plugin marketplace add justinkek/unsolicited-text
    codex plugin add unsolicited-text@unsolicited-text

Codex does not run a plugin's own `hooks.json` yet
([openai/codex#16430](https://github.com/openai/codex/issues/16430)), checked on codex-cli 0.144.5: the plugin installs and reports itself enabled, and a session fires none of its hooks. Until that changes, register the same four commands by hand in `~/.codex/config.toml`, which is the layer Codex does read:

    [[hooks.SessionStart]]
    [[hooks.SessionStart.hooks]]
    type = "command"
    command = "<path to this checkout>/hooks/load-agents-md.sh"

    [[hooks.UserPromptSubmit]]
    [[hooks.UserPromptSubmit.hooks]]
    type = "command"
    command = "<path to this checkout>/hooks/remind-response-length.sh"

    [[hooks.UserPromptSubmit.hooks]]
    type = "command"
    command = "<path to this checkout>/hooks/replay-stop-notes.sh"

    [[hooks.Stop]]
    [[hooks.Stop.hooks]]
    type = "command"
    command = "<path to this checkout>/hooks/note-long-reply.sh"

Codex asks you to trust each command the first time it meets it, and they stay trusted until the command text changes. The session start hook prints the rules into the session, so registering these four is all a Codex session needs - you do not have to put the rules in `~/.codex/AGENTS.md` as well. Keep the plugin installed alongside: when plugin hooks land, delete this block.

## 3. Pi

    pi install git:github.com/justinkek/unsolicited-text

Pi cannot register a subprocess, so `harness-adapters/pi/src/index.ts` is a shim: it builds the same line of JSON each script already reads on stdin, spawns the script, and returns what it printed. It carries no rule of its own, and it needs a shell on the machine, which the other three already require.
