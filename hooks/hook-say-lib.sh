#!/usr/bin/env bash

# Clients differ in what they read from a hook. Every one of them reads this
# shape, and some read nothing else, so a hook that speaks says it this way.

. "$(dirname "${BASH_SOURCE[0]}")/hook-payload-lib.sh"

# The event a hook was called for, out of the payload it was handed.
hook_event_of() { hook_field "$1" hook_event_name; }

# Text on standard input, as the inside of a JSON string.
hook_escaped() {
  sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\r$//' -e 's/\t/\\t/g' \
    | awk 'BEGIN { ORS = "" } { if (NR > 1) printf "\\n"; printf "%s", $0 }'
}

# Text on standard input, printed for the event named in $1.
hook_say() {
  local event="$1" said
  said="$(hook_escaped)"
  [ -n "$said" ] || return 0
  printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' \
    "$event" "$said"
}
