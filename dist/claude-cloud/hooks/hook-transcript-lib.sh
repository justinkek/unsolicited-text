#!/usr/bin/env bash

hook_last_reply() {
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
  ' "$1" 2>/dev/null
}
