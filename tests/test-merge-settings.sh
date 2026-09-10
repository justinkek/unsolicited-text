#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
MERGE="$REPOSITORY/harness-adapters/claude-code/merge-settings.sh"
REGISTRATIONS="$REPOSITORY/harness-adapters/claude-code/cloud-settings.json"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

pass=0
fail=0

assert() {
  local label="$1" outcome="$2" detail="$3"
  if [ "$outcome" = "0" ]; then
    printf "  PASS  %s\n" "$label"
    pass=$((pass + 1))
  else
    printf "  FAIL  %s — %s\n" "$label" "$detail"
    fail=$((fail + 1))
  fi
}

settings="$TMPDIR/settings.json"
checkout="$TMPDIR/checkout"

merge() { bash "$MERGE" "$REGISTRATIONS" "$settings" "$checkout" 2>"$TMPDIR/said"; }

commands_at() { jq --raw-output ".hooks[\"$1\"][]?.hooks[]?.command" "$settings"; }

held() { commands_at "$1" | grep --count --fixed-strings "$2"; }

printf "Test group: with no file there, the registrations are written as they are\n"

rm -f "$settings"
merge
assert "the merge exits 0" "$?" "an install would report a failure"

[ "$(held SessionStart "$checkout/hooks/load-rules.sh")" = "1" ]
assert "every command names the checkout it was run from" "$?" \
  "they still name the path the registrations state, which an install elsewhere has nothing at"

printf '%s' "$(cat "$settings")" | grep --quiet --perl-regexp '^\t"hooks"'
assert "and the file is written with tabs, as the one beside it is" "$?" \
  "a reader opening it sees it reformatted"

printf "\nTest group: what somebody else registered is kept\n"

cat > "$settings" <<'JSON'
{
	"env": { "THEIRS": "kept" },
	"hooks": {
		"SessionStart": [ { "hooks": [ { "type": "command", "command": "/somewhere/theirs.sh" } ] } ],
		"PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "/somewhere/guard.sh" } ] } ]
	}
}
JSON

merge
assert "the merge exits 0" "$?" "an install would report a failure"

[ "$(held SessionStart "/somewhere/theirs.sh")" = "1" ]
assert "their hook on an event this plugin uses is still registered" "$?" \
  "merging took away a hook the reader registered themselves"

[ "$(held PreToolUse "/somewhere/guard.sh")" = "1" ]
assert "so is their hook on an event it never touches" "$?" \
  "a whole event the reader configured was dropped"

[ "$(jq --raw-output '.env.THEIRS' "$settings")" = "kept" ]
assert "and a key that is not a hook at all is untouched" "$?" "everything but the hooks was dropped"

[ "$(held SessionStart "$checkout/hooks/load-rules.sh")" = "1" ]
assert "this plugin is registered beside them" "$?" "the merge kept their file and registered nothing"

[ "$(jq '.hooks.SessionStart | length' "$settings")" = "2" ]
assert "in a group of its own, not folded into theirs" "$?" \
  "their group was rewritten rather than left as it was"

printf "\nTest group: merging twice registers each hook once\n"

merge
[ "$(held SessionStart "$checkout/hooks/load-rules.sh")" = "1" ]
assert "the second merge does not register load-rules.sh twice" "$?" \
  "every refresh adds another copy, and the rules print again for each"

[ "$(held SessionStart "/somewhere/theirs.sh")" = "1" ]
assert "and still holds their hook once" "$?" "their hook was duplicated or dropped"

printf "\nTest group: a group this plugin filled on its own goes away rather than sitting empty\n"

jq --tab '{ hooks: { Stop: [ { hooks: [ { type: "command", command: "'"$checkout"'/hooks/note-long-reply.sh" } ] } ] } }' \
  --null-input > "$settings"
merge
[ "$(jq '.hooks.Stop | length' "$settings")" = "1" ]
assert "the emptied group is dropped" "$?" \
  "an empty group is left behind, and it grows by one on every refresh"

printf "\nTest group: a file that does not read as an object is kept, not thrown away\n"

for holds in 'this is not json' '[1, 2, 3]'; do
  printf '%s' "$holds" > "$settings"
  rm -f "$settings.unreadable"
  merge
  assert "the merge exits 0 on: $holds" "$?" "an install would report a failure"

  [ "$(cat "$settings.unreadable")" = "$holds" ]
  assert "what it could not read is kept beside the new file" "$?" \
    "what the reader wrote is gone with nothing to recover it from"

  [ "$(held SessionStart "$checkout/hooks/load-rules.sh")" = "1" ]
  assert "and the registrations are written all the same" "$?" "the session gets no hooks"

  grep --quiet --fixed-strings "unreadable" "$TMPDIR/said"
  assert "the merge says it did that" "$?" "it happened silently"
done

printf "\nTest group: without jq the file is left alone\n"

cat > "$settings" <<'JSON'
{ "env": { "THEIRS": "kept" } }
JSON

env PATH="$TMPDIR/empty" "$BASH" "$MERGE" "$REGISTRATIONS" "$settings" "$checkout" 2>"$TMPDIR/said"
[ "$?" != "0" ]
assert "the merge fails rather than reporting success" "$?" "an install would say the hooks are registered"

[ "$(jq --raw-output '.env.THEIRS' "$settings")" = "kept" ]
assert "and what the reader wrote is still there" "$?" "it was overwritten by a merge that could not merge"

grep --quiet --fixed-strings "jq" "$TMPDIR/said"
assert "and it says what is missing" "$?" "it failed without saying why"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
