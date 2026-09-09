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

# A rule tagged with a setting is kept only when that setting holds; the rest go.
if breadcrumb; then
  keep="breadcrumb=on"
else
  keep="breadcrumb=off"
fi

keep="$keep queue-tree=$(queue_tree)"

visible="$(queue_visible_items)"
if [ -n "$visible" ]; then
  keep="$keep queue-limit=set"
  rewrite="$rewrite;s/{queue-limit}/$visible/"
else
  keep="$keep queue-limit=unset"
fi

for tag in $(grep --only-matching '{[a-z][a-z|-]*=[a-z][a-z|-]*}' "$rules" | tr -d '{}' | sort --unique); do
  held=""
  for value in $(printf '%s' "${tag#*=}" | tr '|' ' '); do
    case " $keep " in
      *" ${tag%%=*}=$value "*) held=1 ;;
    esac
  done
  if [ -n "$held" ]; then
    rewrite="$rewrite;s/ {$tag}//"
  else
    rewrite="$rewrite;/{$tag}/s/.*/@@drop@@/"
  fi
done

# A rule that goes takes the block written under it, the worked example among it.
sed "$rewrite" "$rules" | awk '
  /^@@drop@@$/ { dropping = 1; next }
  dropping && ($0 ~ /^[[:space:]]*$/ || $0 ~ /^[[:space:]]/) { next }
  { dropping = 0; print }
'
