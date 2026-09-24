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

. "$(dirname "$0")/lib/settings-lib.sh"
. "$(dirname "$0")/lib/say.sh"

event="$(hook_event_of "$payload")"

apply_migrations

# A ceiling of one is one line and one word, not "1 lines" and "1 words".
lines="$(prose_line_ceiling)"
words="$(prose_word_ceiling)"
if [ "$lines" = "1" ]; then line_word="line"; else line_word="lines"; fi
if [ "$words" = "1" ]; then word_word="word"; else word_word="words"; fi

rewrite="s/at most [0-9][0-9]* non-blank lines\{0,1\} of prose/at most $lines non-blank $line_word of prose/"
rewrite="$rewrite;s/at most [0-9][0-9]* words\{0,1\} of it/at most $words $word_word of it/"

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
  case "$visible" in
    0) held_items="no items" ;;
    1) held_items="the first item" ;;
    *) held_items="the first $visible items" ;;
  esac
  rewrite="$rewrite;s/{queue-limit}/$held_items/"
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

printed() {
  [ -n "$reprint" ] && printf 'These unsolicited-text rules replace the unsolicited-text rules printed earlier in this session, and nothing else.\n\n'

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
}

if [ -n "$event" ]; then
  printed | hook_say "$event"
else
  printed
fi
