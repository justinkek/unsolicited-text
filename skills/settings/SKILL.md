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

## How to update settings

If the file is not there, create and add the setting.
Else, read the file, replace or add the setting, and write it back.
Leave the rest of the file as it is, comments included.

## How to apply settings

The hooks read the file every time they run, so a ceiling takes effect at once.

The rules are printed at session start, so print them again from the same hook, and the session reads the new copy.
🔗 [RELOAD.md](../../RELOAD.md) carries the command and the path for every install method.

### Cloud sessions

Cloud sessions do not share the settings file, so inform the user to update the environment variables for their cloud session.
For Claude Code cloud, see instructions [here](https://code.claude.com/docs/en/cloud-environments#set-environment-variables).

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
