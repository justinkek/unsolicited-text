#!/usr/bin/env bash

# The reply a turn ended with. Some clients hand it over in the payload, and
# the rest name a transcript to read it out of.
hook_last_reply() {
  local payload="$1" transcript="$2" said

  if [ -n "$payload" ]; then
    said="$(printf '%s' "$payload" | jq --raw-output '
      .responseText // .last_assistant_message // .lastAssistantMessage // empty' 2>/dev/null)"
    if [ -n "$said" ]; then
      printf '%s' "$said"
      return 0
    fi
  fi

  [ -n "$transcript" ] && [ -f "$transcript" ] || return 0

  jq --raw-output --slurp '
    map(select(.type == "assistant" and .isSidechain != true))
    | map(
        (.message.content? // .content? // [])
        | if type == "string" then .
          else map(select(.type == "text") | .text) | join("\n")
          end
      )
    | map(select(. != null and . != ""))
    | last // ""
  ' "$transcript" 2>/dev/null
}
