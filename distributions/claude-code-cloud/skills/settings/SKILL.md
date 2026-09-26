---
name: settings
description: Change unsolicited-text's settings
---

# unsolicited-text settings

Settings are stored in `~/.unsolicited-text/settings` with one `key = value` a line.
Blank lines and lines opening with `#` are ignored, and the last assignment of a key is the one that counts.

| Key | Default | What it does, and what to say when setting it |
| --- | --- | --- |
| `UNSOLICITED_TEXT_STOP_NOTE_DIRECTORY` | `~/.unsolicited-text/state/notes` | where a turn's notes are written |
| `UNSOLICITED_TEXT_UPDATE_CHECK` | `on` | asks once a day whether a newer version is out |
| `UNSOLICITED_TEXT_UPDATE_CHECK_DAYS` | `1` | days between those asks |
| `UNSOLICITED_TEXT_VERSION_SOURCE` | `https://raw.githubusercontent.com/justinkek/unsolicited-text/main/package.json` | where the update check reads the published version from |
| `UNSOLICITED_TEXT_PROSE_LINE_CEILING` | `8` | the most non-blank lines of prose a reply may hold |
| `UNSOLICITED_TEXT_PROSE_WORD_CEILING` | `120` | the most words of prose a reply may hold |
| `UNSOLICITED_TEXT_QUEUE_MAX_VISIBLE_ITEMS` | unset, every item shown | shows only that many items, with a count of the rest. Say that an item out of sight may not come back, and that `0` shows the count alone |
| `UNSOLICITED_TEXT_QUEUE_EMOJI` | `off` | `on` opens each item with an emoji as well as its word: ❓ Question, 🔍 Investigate, 🚦 Approve/Reject, 🌱 Prevent, 💤 Later. Say that a terminal with no emoji font shows a box instead |
| `UNSOLICITED_TEXT_BREADCRUMB` | `off` | `on` opens every reply with the thread being worked on, `unsolicited-text › settings › breadcrumb`. Say that a session with one thread open shows nothing |
| `UNSOLICITED_TEXT_QUEUE_TREE` | `on-switch-only` | draws the queue as a tree of threads rather than a numbered list, on the reply that raises an item off the open thread. `always-on` draws it in every reply, `off` in none. Say that only the branch being worked is drawn, the rest carrying a count, and that an item is opened by naming it rather than by its number |

`UNSOLICITED_TEXT_HOME` moves the settings file and the state under it together.

A project can hold settings of its own in `.unsolicited-text/settings` at its root, in
the same shape. The hooks read it before `~/.unsolicited-text/settings`, and an
environment variable before either. Write there when the user wants a value
for everyone working in the project rather than for themselves, and say that
it is a file to commit.

## Before writing anything

Read the steps below. Where they say no hook runs, write no
file: follow them instead, since nothing would read what you wrote.

## How to update settings

Run this once per key, and edit no file yourself:

```
bash "/opt/unsolicited-text/distributions/claude-code-cloud/set-setting.sh" <key> <value>
```

It creates the file if it is not there, puts the new value where the old one
was, and leaves the rest of the file as it is, comments included. It writes
nothing and says what the setting takes when the value is one it cannot take,
so pass on what it says rather than trying again.

Where the file already holds a value for the key, say so before running it,
since the hooks read it as the default.

For the project's own file, put `--project <directory>` before the key,
naming the root of the project.

## How to apply settings

The steps below say what reads the file here, and what to do so the session
reads the new copy.

## Inform the user of their settings

Name each key the file sets, and the default above for keys that are unset / empty.

A key another setting has turned off keeps its value and says so in the parenthesis, naming the key and the value that turned it off:

| Key                                        | Value |
| ------------------------------------------ | ----- |
| `UNSOLICITED_TEXT_UPDATE_CHECK` | `off` (set) |
| `UNSOLICITED_TEXT_UPDATE_CHECK_DAYS` | `1` (set - n.a. because `UNSOLICITED_TEXT_UPDATE_CHECK` is set to `off`) |

Two pairs do this. `UNSOLICITED_TEXT_UPDATE_CHECK = off` asks nothing, so `UNSOLICITED_TEXT_UPDATE_CHECK_DAYS` throttles nothing. `UNSOLICITED_TEXT_QUEUE_TREE = always-on` draws no list, so `UNSOLICITED_TEXT_QUEUE_MAX_VISIBLE_ITEMS` limits nothing.

## What not to do

Do not edit what a hook prints to change a value. The hook rewrites it from
whatever is configured, every time it runs.

Do not export a variable in a shell to make a change stick: it lasts as long as
that shell. An environment variable set on a cloud environment is a different
thing, and the steps below say when it is the right one.

## The steps for this install

The hooks read the file every time they run, so a change takes effect at once,
and the reload skill prints with the new value.

The file is written inside the container, which is rebuilt for every session, so
a setting you want to keep goes in a `UNSOLICITED_TEXT_` environment variable on
the cloud environment, see
[the docs](https://code.claude.com/docs/en/cloud-environments#set-environment-variables).

## Note

Rendered from unsolicited-text 0.6.4. Say that version when asked which one is
installed, and say it is the version this file was built from rather than one
read off disk.

Generated by the ai-plugin-sdk build. Edit the plugin's own sources instead.
