#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
CLOUD_STEPS="$REPOSITORY/clients/claude-code-cloud/install.md"
MARKETPLACE="$REPOSITORY/clients/claude-code-local/install.md"

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

printf "\nTest group: the page says what a reader has to know before running it\n"

grep --quiet --fixed-strings 'SKIP_PLUGIN_MARKETPLACE' "$MARKETPLACE"
assert "why the install above does nothing in a container" "$?" "no detection signal in $MARKETPLACE"

grep --quiet --extended-regexp 'reload skill|load-rules\.sh' "$CLOUD_STEPS"
assert "and how to load the rules in a session already going" "$?" \
  "session start has passed, so the rules have to be printed by hand"

grep --quiet --fixed-strings 'reload skill' "$REPOSITORY/clients/claude-chat/install.md"
assert "and what to do on a harness that runs no hooks" "$?" \
  "a reader on such a harness is told nothing works and nothing else"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
