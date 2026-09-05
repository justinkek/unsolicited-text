---
name: settings
description: Change an unsolicited-text setting
---

# unsolicited-text settings

One file, read by every harness: `~/.unsolicited-text/settings`. One
`key = value` a line. Blank lines and lines opening with `#` are ignored, and
the last assignment of a key is the one that counts.

`UNSOLICITED_TEXT_HOME` moves that file and the state under it together.

| Key | Default |
| --- | --- |
| `UNSOLICITED_TEXT_PROSE_LINE_CEILING` | `8` |
| `UNSOLICITED_TEXT_STOP_NOTE_DIRECTORY` | `~/.unsolicited-text/state/notes` |
| `UNSOLICITED_TEXT_UPDATE_CHECK` | `on` |
| `UNSOLICITED_TEXT_QUEUE_MAX_VISIBLE_ITEMS` | unset, every item shown |
| `UNSOLICITED_TEXT_QUEUE_EMOJI` | `off` |

Setting `UNSOLICITED_TEXT_QUEUE_MAX_VISIBLE_ITEMS` shows only that many queue
items, with a count of the rest. Say when setting it that an item out of sight
may not come back, and that `0` shows the count alone.

Setting `UNSOLICITED_TEXT_QUEUE_EMOJI` to `on` opens each queue item with a
glyph as well as its word. Say when setting it that a terminal with no emoji
font shows a box instead.

## Changing one

Read the file, replace or add the one line, write it back. Leave the rest of
the file as it is, comments included. Create it holding that single line if it
is not there.

## Saying what is set

Name each key the file sets, and the default above for each key it does not.
An empty value counts as unset.

## What not to do

Do not edit `AGENTS.md` to change the ceiling. The session start hook rewrites
the ceiling in the rules it prints, from whatever is configured.

Do not export a variable to make a change stick. The environment wins over the
file for that session only.
