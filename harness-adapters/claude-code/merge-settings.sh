#!/usr/bin/env bash

registrations="$1"
settings="$2"
checkout="$3"
stated=/opt/unsolicited-text

if ! command -v jq >/dev/null 2>&1; then
  printf 'unsolicited-text: no jq to merge with, so %s was left as it was and no hooks are registered\n' \
    "$settings" >&2
  exit 1
fi

rewrite=$(cat <<'JQ'
def rewrite: walk(if type == "string" then split($stated) | join($checkout) else . end);
JQ
)

run() {
  local written="$settings.merging"
  if jq --tab --arg stated "$stated" --arg checkout "$checkout" "$@" > "$written"; then
    mv "$written" "$settings"
    return 0
  fi
  rm -f "$written"
  printf 'unsolicited-text: could not write %s, so it was left as it was\n' "$settings" >&2
  return 1
}

fresh() { run "$rewrite rewrite" "$registrations"; }

[ -f "$settings" ] || { fresh; exit; }

if ! jq --exit-status 'type == "object"' "$settings" >/dev/null 2>&1; then
  mv "$settings" "$settings.unreadable" || exit 1
  printf 'unsolicited-text: %s did not read as an object, so it was kept as %s.unreadable and written fresh\n' \
    "$settings" "$settings" >&2
  fresh
  exit
fi

merge=$(cat <<'JQ'
def mine: (.command? // "") | startswith($checkout + "/");

def kept($event):
  [ (.hooks[$event] // [])[]
    | if type == "object"
      then .hooks = [ (.hooks // [])[] | select(mine | not) ]
      else . end
    | select(type != "object" or ((.hooks | length) > 0)) ];

($ours[0] | rewrite) as $registrations
| (if (.hooks | type) == "object" then . else .hooks = {} end)
| reduce ($registrations.hooks | to_entries[]) as $entry (
    .;
    .hooks[$entry.key] = (kept($entry.key) + $entry.value)
  )
JQ
)

run --slurpfile ours "$registrations" "$rewrite $merge" "$settings"
