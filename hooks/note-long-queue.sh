#!/usr/bin/env bash

input="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0

[ "$(printf '%s' "$input" | jq --raw-output '.stop_hook_active // false')" = "true" ] && exit 0

transcript="$(printf '%s' "$input" | jq --raw-output '.transcript_path // empty')"
[ -n "$transcript" ] && [ -f "$transcript" ] || exit 0

session_id="$(printf '%s' "$input" | jq --raw-output '.session_id // empty')"
[ -n "$session_id" ] || exit 0

. "$(dirname "$0")/hook-transcript-lib.sh"
. "$(dirname "$0")/hook-stop-note-lib.sh"

visible="$(queue_visible_items)"
[ -n "$visible" ] || exit 0

last="$(hook_last_reply "$transcript")"
[ -n "$last" ] || exit 0

fence="$(printf '\140\140\140')"
queue_tag="$(printf '\140[queue]\140')"
shown="$(printf '%s\n' "$last" | awk -v fence="$fence" -v queue_tag="$queue_tag" '
  { probe = $0; sub(/^[[:space:]]+/, "", probe) }
  index(probe, fence) == 1 { fenced = !fenced; next }
  fenced { next }
  index(probe, queue_tag) == 1 { queued = 1; next }
  !queued { next }
  index(probe, "more pending") { exit }
  probe ~ /^[0-9]+\. / { shown++; next }
  probe != "" { exit }
  END { print shown + 0 }')"

[ "$shown" -gt "$visible" ] || exit 0

stop_note_record "$session_id" "[queue-shape] The last reply showed $shown queue items with $visible visible allowed. Show the first $visible, write \`...N more pending\` under them with N the number left unshown, and list anything raised this turn below that line."
exit 0
