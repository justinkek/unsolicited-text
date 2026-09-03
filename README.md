# unsolicited-text

What passes between a person and the agent: how a reply is formatted, the
english it is written in, the checklist before it is sent, and the ceiling
on its length. Nothing about the code or the instructions the agent writes.

The rules themselves are `AGENTS.md` at the root of this checkout. Any tool
that reads `AGENTS.md` natively already has them once the repository is on
disk. The plugin is what adds the hooks that hold a reply to them: a reminder
on every prompt, and a note at the end of a turn naming a reply that ran over
the ceiling.

## What changes

One ask, answered without the plugin and with it. Both answers are correct;
only the second can be read at a glance.

> the reminder fires twice on some prompts, why?

Without it:

```
Great question! Let me walk you through what is happening here.

So when you register a hook there are really two layers at play. The first
is your own settings, which live in your home directory and apply to every
session you start. The second is the plugin's own registration, which
travels with the plugin wherever it is installed.

What is happening in your case is that both layers are registering the same
script. This is a really common gotcha and it catches a lot of people out!

Essentially the harness does not deduplicate across those two layers, so the
command just runs once per registration. That is why you are seeing it twice.

To fix it you will want to remove one of them. I would probably suggest
removing the one in your own settings, since the plugin is the source of
truth now, but honestly either works depending on your setup.

Let me know if you would like me to walk through how to do that!
```

With it:

```
`[problem]` The script is registered twice, once in your own settings and
once by the plugin, and the harness does not deduplicate across the two.

`[fix]` Drop the entry from your own settings and leave the plugin's.

`[queue]`

1. Q: Should the readme say which registrations to remove on upgrade?
```

Thirteen lines of prose against three. The ceiling is eight, the queue does
not count against it, and what needs an answer is asked in one place.

## What is installed

| File | When it runs | What it does |
| --- | --- | --- |
| `hooks/load-agents-md.sh` | session start | prints `AGENTS.md` into the session |
| `hooks/remind-response-length.sh` | every prompt | restates the shortest-form rule |
| `hooks/replay-stop-notes.sh` | every prompt | prints the note the last turn recorded |
| `hooks/note-long-reply.sh` | turn end | records a note when the reply ran over the ceiling |

Every harness runs those same four scripts. Only the registration differs.

## Claude Code, ZCode

    claude plugin marketplace add justinkek/unsolicited-text
    claude plugin install unsolicited-text@unsolicited-text

In ZCode, add `justinkek/unsolicited-text` through Settings, Marketplace. It
preloads the Claude Code marketplace format and reads the same two manifests.

## Codex

    codex plugin marketplace add justinkek/unsolicited-text
    codex plugin add unsolicited-text@unsolicited-text

Codex does not run a plugin's own `hooks.json` yet
([openai/codex#16430](https://github.com/openai/codex/issues/16430)), checked on
codex-cli 0.144.5: the plugin installs and reports itself enabled, and a session
fires none of its hooks. Until that changes, register the same four commands by
hand in `~/.codex/config.toml`, which is the layer Codex does read:

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

Codex asks you to trust each command the first time it meets it, and they stay
trusted until the command text changes. The session start hook prints the rules
into the session, so registering these four is all a Codex session needs - you
do not have to put the rules in `~/.codex/AGENTS.md` as well. Keep the plugin
installed alongside: when plugin hooks land, delete this block.

## Pi

    pi install git:github.com/justinkek/unsolicited-text

Pi cannot register a subprocess, so `harness-adapters/pi/src/index.ts` is a
shim: it builds the same line of JSON each script already reads on stdin,
spawns the script, and returns what it printed. It carries no rule of its own,
and it needs a shell on the machine, which the other three already require.

## Tests

    tests/run-tests
