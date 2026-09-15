#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
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

printf "Test group: what ships is what the sources build\n"

"$REPOSITORY/build" "$TMPDIR/dist" >/dev/null
assert "the build runs" "$?" "nothing can be shipped from these sources"

diff --recursive --unified "$REPOSITORY/dist" "$TMPDIR/dist" > "$TMPDIR/drift"
assert "and dist matches it" "$?" \
  "an install would copy something no source says - run ./build"

printf "\nTest group: every folder carries what its install needs\n"

for product in claude-code claude-cloud codex pi; do
  for wanted in README.md rules/reply-shape.md hooks/load-rules.sh skills/reload/SKILL.md; do
    [ -e "$REPOSITORY/dist/$product/$wanted" ]
    assert "$product ships $wanted" "$?" "an install from that folder is missing it"
  done
done

[ -f "$REPOSITORY/dist/chat-cowork/skills/reload/SKILL.md" ]
assert "chat-cowork ships the skills a client copies" "$?" "the folder says nothing about what a session there receives"

for product in claude-code claude-cloud codex pi chat-cowork; do
  grep --quiet --fixed-strings 'Installing' "$REPOSITORY/dist/$product/README.md"
  assert "$product says how it is installed" "$?" "the folder is there and nothing tells a reader what to do with it"
done

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
