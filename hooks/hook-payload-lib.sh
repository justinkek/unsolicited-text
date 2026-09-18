#!/usr/bin/env bash

# Clients spell the payload's keys differently: session_id here, sessionId
# there. A hook asks for the name it knows and gets whichever one was sent.
hook_field() {
  local payload="$1" key="$2" camel said

  camel="$(printf '%s' "$key" | awk -F_ '{
    printf "%s", $1
    for (i = 2; i <= NF; i++) printf "%s%s", toupper(substr($i, 1, 1)), substr($i, 2)
  }')"

  for said in "$key" "$camel"; do
    printf '%s' "$payload" \
      | sed -n "s/.*\"$said\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1 \
      | grep . && return 0

    # true, false and numbers carry no quotes.
    printf '%s' "$payload" \
      | sed -n "s/.*\"$said\"[[:space:]]*:[[:space:]]*\([A-Za-z0-9.-]*\).*/\1/p" | head -1 \
      | grep . && return 0
  done

  return 1
}
