#!/usr/bin/env bash

. "$(dirname "$0")/built.sh"

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
LOADER="$BUILT_HOOKS/load-rules.sh"
MISSED="$BUILT_HOOKS/print-rules-if-missed.sh"
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

prompt() {
  printf '{"hook_event_name":"UserPromptSubmit","session_id":"%s","prompt":"x"}' "$1" \
    | env HOME="$TMPDIR/home" bash "$MISSED" 2>/dev/null
}

session_start() {
  printf '{"hook_event_name":"SessionStart","session_id":"%s"}' "$1" \
    | env HOME="$TMPDIR/home" bash "$LOADER" 2>/dev/null
}

printf "Test group: a session that missed session start is given the rules at its first prompt\n"

rm -rf "$TMPDIR/home"
said="$(prompt missed-it)"
printf '%s' "$said" | grep --quiet --fixed-strings 'Keep a reply to at most'
assert "the first prompt carries the rules" "$?" "a session there would follow rules it never read"

printf '%s' "$said" | grep --quiet --fixed-strings 'replace the unsolicited-text rules printed earlier'
[ "$?" = "1" ]
assert "and does not say it is replacing an earlier print" "$?" "nothing was printed before it"

[ -z "$(prompt missed-it)" ]
assert "the next prompt carries nothing" "$?" "every message would carry the rules again"

printf "\nTest group: a session that was given them at session start is left alone\n"

rm -rf "$TMPDIR/home"
session_start had-them >/dev/null
[ -z "$(prompt had-them)" ]
assert "the first prompt after session start carries nothing" "$?" \
  "a session would read the rules twice, one straight after the other"

printf "\nTest group: what the hook needs before it says anything\n"

rm -rf "$TMPDIR/home"
[ -z "$(printf '{"hook_event_name":"UserPromptSubmit"}' | env HOME="$TMPDIR/home" bash "$MISSED" 2>/dev/null)" ]
assert "a payload with no session carries nothing" "$?" \
  "nothing marks that session, so the rules would print at every message"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
