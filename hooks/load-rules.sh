#!/usr/bin/env bash

# A hand run carries no event name, and nothing takes an earlier print back out
# of the conversation.
payload="$(cat)"
case "$payload" in
  *'"hook_event_name"'*) reprint="" ;;
  *) reprint=1 ;;
esac

rules="$(dirname "$0")/../rules/reply-shape.md"
[ -f "$rules" ] || exit 0

. "$(dirname "$0")/hook-settings-lib.sh"

apply_migrations

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

[ -n "$reprint" ] && printf 'These rules replace any printed earlier in this session.\n\n'

sed "$rewrite" "$rules" | awk '
  /^@@drop@@$/ { dropping = 1; next }
  dropping && ($0 ~ /^[[:space:]]*$/ || $0 ~ /^[[:space:]]/) { next }
  { dropping = 0; print }
'

if ! onboarding_is_done; then
  if queue_emoji; then
    later="💤 Later:"
  else
    later="Later:"
  fi
  printf '\n## First session\n\nStart the queue with these two items:\n\n'
  printf '1. %s try the settings skill - it changes any of these rules\n' "$later"
  printf '2. %s try the update skill - it fetches a newer copy\n' "$later"
fi
