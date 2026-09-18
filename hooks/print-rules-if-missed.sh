#!/usr/bin/env bash

# Some clients never carry the session start hook's output into the session.
# The rules arrive on the first prompt instead, once.
input="$(cat)"

. "$(dirname "$0")/hook-payload-lib.sh"

session_id="$(hook_field "$input" session_id)"
[ -n "$session_id" ] || exit 0

. "$(dirname "$0")/hook-settings-lib.sh"
. "$(dirname "$0")/hook-say-lib.sh"

[ -f "$UNSOLICITED_TEXT_STATE/printed/$session_id" ] && exit 0

printf '{"hook_event_name":"UserPromptSubmit","session_id":"%s"}' "$session_id" \
  | UNSOLICITED_TEXT_PLAIN=1 "$(dirname "$0")/load-rules.sh" \
  | hook_say UserPromptSubmit
exit 0
