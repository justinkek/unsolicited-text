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

last="$(hook_last_reply "$transcript")"
[ -n "$last" ] || exit 0

UNSOLICITED_TEXT_PROSE_LINE_CEILING="$(prose_line_ceiling)"

fence="$(printf '\140\140\140')"
queue_tag="$(printf '\140[queue]\140')"
prose_lines="$(printf '%s\n' "$last" | awk -v fence="$fence" -v queue_tag="$queue_tag" '
  { probe = $0; sub(/^[[:space:]]+/, "", probe) }
  index(probe, fence) == 1 { fenced = !fenced; next }
  fenced { next }
  probe == queue_tag { queued = 1; next }
  queued && probe ~ /^[0-9]+\. / { next }
  queued && probe != "" { queued = 0 }
  index(probe, "|") == 1 { next }
  NF { prose_lines++ }
  END { print prose_lines + 0 }')"
[ "$prose_lines" -gt "$UNSOLICITED_TEXT_PROSE_LINE_CEILING" ] || exit 0

stop_note_record "$session_id" "[reply-shape] The last reply ran $prose_lines lines of prose against a ceiling of $UNSOLICITED_TEXT_PROSE_LINE_CEILING. Hold this one to the ceiling: send only what the reader needs in order to act, and put what needs the user's attention under \`[queue]\`, which the ceiling does not count."
exit 0
