#!/usr/bin/env bash

input="$(cat)"

. "$(dirname "$0")/hook-say-lib.sh"

printf '%s\n' "[response-length] Answer in the shortest form that answers this ask - a chat reply, a commit message and a reply to a review comment alike. A completed directive is a one-line confirmation, not a write-up." \
  | hook_say "$(hook_event_of "$input")"

exit 0
