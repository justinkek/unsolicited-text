#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
README="$REPOSITORY/README.md"

pass=0
fail=0

assert() {
  local label="$1" outcome="$2" detail="$3"
  if [ "$outcome" = "0" ]; then
    printf "  OK  %s\n" "$label"
    pass=$((pass + 1))
  else
    printf "  KO  %s — %s\n" "$label" "$detail"
    fail=$((fail + 1))
  fi
}

rounded_tokens() {
  awk 'END { print int((length_of_file / 4 + 50) / 100) * 100 }' length_of_file="$(wc -c < "$1" | tr -d ' ')" /dev/null
}

with_separator() {
  printf '%s' "$1" | sed 's/\([0-9]\)\([0-9][0-9][0-9]\)$/\1,\2/'
}

printf "Test group: the readme counts what the hooks actually put into a session\n"

stated="$(with_separator "$(rounded_tokens "$REPOSITORY/AGENTS.md")")"
grep --quiet --extended-regexp "~$stated +\\|" "$README"
assert "the rules cost about $stated tokens and the readme says so" "$?" \
  "AGENTS.md now measures ~$stated, which $README does not state"

for hook in remind-response-length replay-stop-notes; do
  printed="$(printf '{"session_id":"tokens","prompt":"x"}' | bash "$REPOSITORY/hooks/$hook.sh" 2>/dev/null | wc -c | tr -d ' ')"
  [ "$printed" -lt 400 ]
  assert "$hook.sh prints little enough to be the small number it claims" "$?" \
    "it printed $printed characters"
done

printed="$(printf '{"session_id":"tokens"}' | bash "$REPOSITORY/hooks/note-long-reply.sh" 2>/dev/null | wc -c | tr -d ' ')"
[ "$printed" -eq 0 ]
assert "note-long-reply.sh prints nothing into the session" "$?" "it printed $printed characters"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
