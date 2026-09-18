#!/usr/bin/env bash

input="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0

session_id="$(printf '%s' "$input" | jq --raw-output '.session_id // empty')"
[ -n "$session_id" ] || exit 0

. "$(dirname "$0")/hook-stop-note-lib.sh"
. "$(dirname "$0")/hook-say-lib.sh"

notes="$(stop_note_take "$session_id")"
[ -n "$notes" ] || exit 0

printf '%s\n' "$notes" | hook_say "$(hook_event_of "$input")"
exit 0
