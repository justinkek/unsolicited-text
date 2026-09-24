#!/usr/bin/env bash

. "$(dirname "$0")/built.sh"

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS="$BUILT_HOOKS"
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

# Some clients read nothing but this shape, and discard plain text in silence.
said_for() {
  printf '{"hook_event_name":"%s","session_id":"%s","prompt":"x"}' "$2" "${3:-$1}" \
    | env HOME="$TMPDIR/home" bash "$HOOKS/$1" 2>/dev/null
}

carried() {
  python3 -c '
import json, sys
said = json.load(sys.stdin)["hookSpecificOutput"]
print(said["hookEventName"])
print(said["additionalContext"][:80])' 2>/dev/null
}

printf "Test group: every hook that speaks says it in the one shape\n"

rm -rf "$TMPDIR/home"
for pair in "load-rules.sh SessionStart" "remind-response-length.sh UserPromptSubmit" \
  "print-session-start-if-missed.sh UserPromptSubmit"; do
  set -- $pair
  said="$(said_for "$1" "$2")"

  [ -n "$said" ]
  assert "$1 says something" "$?" "it printed nothing at all"

  event="$(printf '%s' "$said" | carried | head -1)"
  [ "$event" = "$2" ]
  assert "and names $2, in JSON a client can read" "$?" "it said '$said'"
done

printf "\nTest group: what it carries is the text, escaped and whole\n"

rm -rf "$TMPDIR/home"
said="$(said_for load-rules.sh SessionStart carrying | carried)"
printf '%s' "$said" | grep --quiet --fixed-strings 'Agent Rules'
assert "the rules arrive inside it" "$?" "it carried '$said'"

printf "\nTest group: a hand run still prints the text itself\n"

rm -rf "$TMPDIR/home"
plain="$(printf '{}' | env HOME="$TMPDIR/home" bash "$HOOKS/load-rules.sh" 2>/dev/null | head -1)"
printf '%s' "$plain" | grep --quiet --fixed-strings '{"hookSpecificOutput"'
[ "$?" = "1" ]
assert "a payload with no event name is answered in text" "$?" \
  "a person piping it by hand reads JSON"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
