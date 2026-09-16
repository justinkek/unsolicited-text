---
name: settings
description: Change an unsolicited-text setting
---

# unsolicited-text settings

Settings are stored in `~/.unsolicited-text/settings` with one `key = value` a line.
Blank lines and lines opening with `#` are ignored, and the last assignment of a key is the one that counts.

| Key                                        | Default                           | What it does, and what to say when setting it                                                                                                                                                                                                                                                                            |
| ------------------------------------------ | --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `UNSOLICITED_TEXT_PROSE_LINE_CEILING`      | `8`                               | the most non-blank lines of prose a reply may hold                                                                                                                                                                                                                                                                       |
| `UNSOLICITED_TEXT_PROSE_WORD_CEILING`      | `120`                             | the most words of prose a reply may hold                                                                                                                                                                                                                                                                                 |
| `UNSOLICITED_TEXT_STOP_NOTE_DIRECTORY`     | `~/.unsolicited-text/state/notes` | where a turn's notes are written                                                                                                                                                                                                                                                                                         |
| `UNSOLICITED_TEXT_UPDATE_CHECK`            | `on`                              | asks once a day whether a newer version is out                                                                                                                                                                                                                                                                           |
| `UNSOLICITED_TEXT_UPDATE_CHECK_DAYS`       | `1`                               | days between those asks                                                                                                                                                                                                                                                                                                  |
| `UNSOLICITED_TEXT_QUEUE_MAX_VISIBLE_ITEMS` | unset, every item shown           | shows only that many items, with a count of the rest. Say that an item out of sight may not come back, and that `0` shows the count alone                                                                                                                                                                                |
| `UNSOLICITED_TEXT_QUEUE_EMOJI`             | `off`                             | `on` opens each item with an emoji as well as its word. Say that a terminal with no emoji font shows a box instead                                                                                                                                                                                                       |
| `UNSOLICITED_TEXT_BREADCRUMB`              | `off`                             | `on` opens every reply with the thread being worked on, `unsolicited-text › settings › breadcrumb`. Say that a session with one thread open shows nothing                                                                                                                                                                |
| `UNSOLICITED_TEXT_QUEUE_TREE`              | `on-switch-only`                  | draws the queue as a tree of threads rather than a numbered list, on the reply that raises an item off the open thread. `always-on` draws it in every reply, `off` in none. Say that only the branch being worked is drawn, the rest carrying a count, and that an item is opened by naming it rather than by its number |

`UNSOLICITED_TEXT_HOME` moves the settings file and the state under it together.

## Before writing anything

Read the steps at the end of this file. Where they say no hook runs, write no
file - follow them instead, since nothing would ever read what you wrote.

## How to update settings

If the file is not there, create and add the setting.
Else, read the file, replace or add the setting, and write it back.
Leave the rest of the file as it is, comments included.

## How to apply settings

The hooks read the file every time they run, so a ceiling takes effect at once.

The rules are printed at session start, so print them again from the same hook, and the session reads the new copy.
The reload skill does it, and the command and the path for every install method are at the end of this file.

### A session in a container

The file is written inside the container, which is discarded with the session,
so say the setting lasts as long as this session does. Where the container is
built from settings you keep - a Claude Code cloud environment - the way to keep
it is an `UNSOLICITED_TEXT_` environment variable there, see
[the docs](https://code.claude.com/docs/en/cloud-environments#set-environment-variables).
The steps at the end of this file say which kind of session this is.

## Inform the user of their settings

Name each key the file sets, and the default above for keys that are unset / empty.

A key another setting has turned off keeps its value and says so in the parenthesis, naming the key and the value that turned it off:

| Key                                        | Value                                                                        |
| ------------------------------------------ | ---------------------------------------------------------------------------- |
| `UNSOLICITED_TEXT_QUEUE_TREE`              | `always-on` (set)                                                            |
| `UNSOLICITED_TEXT_QUEUE_MAX_VISIBLE_ITEMS` | `2` (set - n.a. because `UNSOLICITED_TEXT_QUEUE_TREE` is set to `always-on`) |

Two pairs do this. `UNSOLICITED_TEXT_QUEUE_TREE = always-on` draws no list, so
`UNSOLICITED_TEXT_QUEUE_MAX_VISIBLE_ITEMS` limits nothing.
`UNSOLICITED_TEXT_UPDATE_CHECK = off` asks nothing, so
`UNSOLICITED_TEXT_UPDATE_CHECK_DAYS` throttles nothing.

## What not to do

Do not edit `rules/reply-shape.md` to change the ceiling. The session start hook rewrites
the ceiling in the rules it prints, from whatever is configured.

Do not export a variable by hand to make a change stick.

## The steps for this install

The hooks run here. Print the rules again with the loader, which the plugin
carries:

    find ~ -name load-rules.sh 2>/dev/null

Settings live in `~/.unsolicited-text/settings` inside the session's container,
which is discarded when the session ends, so write the setting and say it lasts
as long as this session does.

## Note

Generated by ./build. Edit the sources at the repository root instead.
