#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
PAGE="$REPOSITORY/RELOADING.md"
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

printf "Test group: one page carries the command, and the rest send a reader to it\n"

for page in INSTALL.md UPDATING.md; do
  grep --quiet --fixed-strings '/rules/reply-shape.md' "$REPOSITORY/$page"
  outcome="$?"
  [ "$outcome" != "0" ]
  assert "$page names no path to the rules file" "$?" \
    "it tells a reader to print the file as it sits on disk, which is not what a session is given"

  grep --quiet --fixed-strings "$(basename "$PAGE")" "$REPOSITORY/$page"
  assert "and sends them to $(basename "$PAGE") instead" "$?" "it says to print the rules and never says how"
done

grep --quiet --fixed-strings 'load-rules.sh' "$PAGE"
assert "$(basename "$PAGE") names the hook" "$?" "the one page that carries the command does not name it"

printf "\nTest group: the hook gives a session something the file on disk does not\n"

printed="$TMPDIR/printed"
printf '{}' | "$REPOSITORY/hooks/load-rules.sh" > "$printed"

grep --quiet --fixed-strings 'replace the unsolicited-text rules printed earlier' "$printed"
assert "a run by hand says it replaces the rules already read" "$?" \
  "a session reprinted mid-conversation is left holding two sets of rules"

printf '{"hook_event_name":"SessionStart"}' | "$REPOSITORY/hooks/load-rules.sh" \
  | grep --quiet --fixed-strings 'replace the unsolicited-text rules printed earlier'
outcome="$?"
[ "$outcome" != "0" ]
assert "and session start does not, having nothing to replace" "$?" "the first print says it replaces something"

grep --quiet --extended-regexp '\{[a-z-]+=[a-z|-]+\}' "$REPOSITORY/rules/reply-shape.md"
assert "the file on disk carries the setting markers" "$?" \
  "nothing in it needs the hook, and this test is measuring nothing"

grep --quiet --extended-regexp '\{[a-z-]+=[a-z|-]+\}' "$printed"
outcome="$?"
[ "$outcome" != "0" ]
assert "and what the hook prints carries none of them" "$?" \
  "a session is handed the markers raw, which is what printing the file does"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
