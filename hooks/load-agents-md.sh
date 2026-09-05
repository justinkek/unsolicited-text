#!/usr/bin/env bash

cat >/dev/null

rules="$(dirname "$0")/../AGENTS.md"
[ -f "$rules" ] || exit 0

. "$(dirname "$0")/hook-settings-lib.sh"

discard_notes_from_before_v_0_1_2
move_settings_from_before_v_0_1_4

rewrite="s/at most [0-9][0-9]* non-blank lines of prose/at most $(prose_line_ceiling) non-blank lines of prose/"

visible="$(queue_visible_items)"
if [ -n "$visible" ]; then
  rewrite="$rewrite;s|- Show every item of the queue in every reply.|- Show only the first $visible items of the queue. Write \`...N more pending\` under them, with N the number left unshown, and list anything raised this turn below that line.|"
fi

sed "$rewrite" "$rules"
