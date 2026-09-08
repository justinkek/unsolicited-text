#!/usr/bin/env bash

cat >/dev/null

rules="$(dirname "$0")/../rules/reply-shape.md"
[ -f "$rules" ] || exit 0

. "$(dirname "$0")/hook-settings-lib.sh"

discard_notes_from_before_v_0_1_2
move_settings_from_before_v_0_1_4

rewrite="s/at most [0-9][0-9]* non-blank lines of prose/at most $(prose_line_ceiling) non-blank lines of prose/"
rewrite="$rewrite;s/at most [0-9][0-9]* words of it/at most $(prose_word_ceiling) words of it/"

if ! queue_emoji; then
  for emoji in ❓ 🔍 🚦 🌱 💤; do
    rewrite="$rewrite;s/$emoji //g"
  done
fi

if breadcrumb; then
  rewrite="$rewrite;s|- Do not write a breadcrumb.|- Open every reply with the thread you are on, as its own first line: \`unsolicited-text › settings › breadcrumb\`. Keep the root and the last two levels, write \`…\` for any between, and name a branch the same two or three words every time. Write nothing when one thread is open.|"
fi

visible="$(queue_visible_items)"
if [ -n "$visible" ]; then
  rewrite="$rewrite;s|- Show every item of the queue in every reply.|- Show only the first $visible items of the queue. Write \`...N more pending\` under them, with N the number left unshown, and list anything raised this turn below that line.|"
fi

sed "$rewrite" "$rules"
