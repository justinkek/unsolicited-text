#!/usr/bin/env bash

# Adds this plugin's hook registrations to a settings file without taking away
# what is already there. An entry belongs to this plugin when its command names
# a file inside the checkout, and only those entries are replaced, so installing
# twice registers each hook once.
#
#     merge-settings.sh <registrations> <settings> <checkout>

registrations="$1"
settings="$2"
checkout="$3"
stated=/opt/unsolicited-text

if ! command -v jq >/dev/null 2>&1; then
  printf 'unsolicited-text: no jq to merge with, so %s was left as it was and no hooks are registered\n' \
    "$settings" >&2
  exit 1
fi

# The registrations name the checkout a cloud session clones into. Point them at
# the checkout this script is running from, so an install works from anywhere.
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
# An entry this plugin registered, told apart from the ones anybody else
# registered by the checkout its command sits in.
def mine: (.command? // "") | startswith($checkout + "/");

# Everything already registered for one event, minus this plugin's own entries,
# minus any group those entries leave empty.
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
