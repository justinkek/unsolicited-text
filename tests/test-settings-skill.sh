#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$REPOSITORY/skills/settings/SKILL.md"
HOOKS_DIR="$REPOSITORY/hooks"

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

printf "Test group: the skill is one a harness will find\n"

[ -f "$SKILL" ]
assert "skills/settings/SKILL.md is there" "$?" "no skill at $SKILL"

grep --quiet --line-regexp --fixed-strings 'name: settings' "$SKILL"
assert "it is named settings, and takes the plugin prefix from the manifest" "$?" \
  "the name is missing or carries the prefix itself"

grep --quiet --line-regexp --fixed-strings 'description: Change an unsolicited-text setting' "$SKILL"
assert "its description is the one line every session pays for" "$?" "the description has grown"

printf "\nTest group: what it tells the user matches what the hooks read\n"

while read -r key; do
  grep --quiet --fixed-strings "$key" "$HOOKS_DIR/hook-config-lib.sh" "$HOOKS_DIR/hook-stop-note-lib.sh"
  assert "$key is a setting the hooks read" "$?" "no hook reads it, so the skill would set nothing"
done < <(grep --only-matching --extended-regexp 'UNSOLICITED_TEXT_[A-Z_]+' "$SKILL" | sort --unique)

ceiling="$(grep --only-matching 'UNSOLICITED_TEXT_PROSE_LINE_CEILING_DEFAULT=[0-9][0-9]*' \
  "$HOOKS_DIR/hook-config-lib.sh" | grep --only-matching '[0-9][0-9]*')"
grep --quiet --extended-regexp "UNSOLICITED_TEXT_PROSE_LINE_CEILING\` \| \`$ceiling\`" "$SKILL"
assert "the ceiling it states is the ceiling the hooks default to" "$?" \
  "the hooks default to $ceiling and the skill says otherwise"

notes="$(grep --only-matching 'UNSOLICITED_TEXT_STATE/notes' "$HOOKS_DIR/hook-stop-note-lib.sh" | head -1)"
[ -n "$notes" ]
assert "the notes default is still under the state directory" "$?" "hook-stop-note-lib.sh no longer says so"

grep --quiet --fixed-strings '~/.unsolicited-text/state/notes' "$SKILL"
assert "and the skill spells that same path out" "$?" "the skill names a different one"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
