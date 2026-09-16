#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$REPOSITORY/distributions/claude-code-local/skills/reload/SKILL.md"
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

printf "Test group: the skill carries the rules a hookless session never gets\n"

grep --quiet --line-regexp --fixed-strings 'name: reload' "$SKILL"
assert "it is named reload" "$?" "the name is missing or carries the plugin prefix"

grep --quiet --fixed-strings 'load-rules.sh' "$SKILL"
assert "it names the script for a session that can run one" "$?" \
  "a session with hooks would read a copy instead of the settings it has"

grep --quiet --fixed-strings 'Agent Rules' "$SKILL"
assert "and carries the rules for a session that cannot" "$?" \
  "Chat receives this file alone, so rules it does not hold are rules nobody has"

printf "\nTest group: the copy in the skill is the rules as they stand\n"

"$REPOSITORY/skills/reload/render" "$TMPDIR/SKILL.md"
assert "the generator runs" "$?" "the skill cannot be rebuilt from the rules"

diff --unified "$SKILL" "$TMPDIR/SKILL.md" >"$TMPDIR/drift"
assert "and the skill matches what it renders" "$?" \
  "the rules moved on without it - run skills/reload/render"

grep --quiet --extended-regexp '\{[a-z-]+=' "$SKILL"
[ "$?" = "1" ]
assert "no setting tag survives into the copy" "$?" "a session would read {queue-tree=...} as a rule"

grep --quiet --fixed-strings 'First session' "$SKILL"
[ "$?" = "1" ]
assert "and no onboarding block does either" "$?" "every reader would be told to start a queue"

printf "\nTest group: a skill carries the steps for its own distribution\n"

for folder in "$REPOSITORY"/distributions/*/skills/update/SKILL.md; do
  named="$(basename "$(dirname "$(dirname "$(dirname "$folder")")")")"

  grep --quiet --fixed-strings '## The steps for this install' "$folder"
  assert "the $named update skill carries its own steps" "$?" \
    "it links them, or carries every install method the plugin knows"

  others="$(jq --raw-output --arg named "$named" 'to_entries[] | select(.key != $named) | .value.heading' \
    "$REPOSITORY/distributions.json" | tr ',' '\n' | sed 's/^ *//' | sort --unique)"
  wrong=""
  while read -r heading; do
    [ -n "$heading" ] || continue
    grep --quiet --fixed-strings "## $heading" "$folder" && wrong="$wrong $heading"
  done <<< "$others"
  [ -z "$wrong" ]
  assert "and names no other client" "$?" "it also carries$wrong"
done

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
