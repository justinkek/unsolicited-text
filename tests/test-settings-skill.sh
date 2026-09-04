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
  grep --quiet --recursive --fixed-strings "$key" "$HOOKS_DIR"
  assert "$key is a setting the hooks read" "$?" "no hook reads it, so the skill would set nothing"
done < <(grep --only-matching --extended-regexp 'UNSOLICITED_TEXT_[A-Z_]+' "$SKILL" | sort --unique)

ceiling="$(grep --only-matching 'UNSOLICITED_TEXT_PROSE_LINE_CEILING_DEFAULT=[0-9][0-9]*' \
  "$HOOKS_DIR/hook-settings-lib.sh" | grep --only-matching '[0-9][0-9]*')"
grep --quiet --extended-regexp "UNSOLICITED_TEXT_PROSE_LINE_CEILING\` \| \`$ceiling\`" "$SKILL"
assert "the ceiling it states is the ceiling the hooks default to" "$?" \
  "the hooks default to $ceiling and the skill says otherwise"

notes="$(grep --only-matching 'UNSOLICITED_TEXT_STATE/notes' "$HOOKS_DIR/hook-stop-note-lib.sh" | head -1)"
[ -n "$notes" ]
assert "the notes default is still under the state directory" "$?" "hook-stop-note-lib.sh no longer says so"

grep --quiet --fixed-strings '~/.unsolicited-text/state/notes' "$SKILL"
assert "and the skill spells that same path out" "$?" "the skill names a different one"

printf "\nTest group: the update skill covers every harness the plugin installs into\n"

UPDATE="$REPOSITORY/skills/update/SKILL.md"

[ -f "$UPDATE" ]
assert "skills/update/SKILL.md is there" "$?" "no skill at $UPDATE"

grep --quiet --line-regexp --fixed-strings 'name: update' "$UPDATE"
assert "it is named update" "$?" "the name is missing or carries the plugin prefix"

grep --quiet --line-regexp --fixed-strings 'description: Update unsolicited-text to the latest version' "$UPDATE"
assert "its description is one line" "$?" "the description has grown"

while read -r harness; do
  grep --quiet --fixed-strings "$harness" "$UPDATE"
  assert "it says how to update on $harness" "$?" "$harness is in INSTALL.md and not in the skill"
done < <(grep --only-matching --extended-regexp '^## [0-9]+\. .*' "$REPOSITORY/INSTALL.md" \
  | sed 's/^## [0-9]*\. //' | tr ',' '\n' | sed 's/^ *//')

grep --quiet --fixed-strings 'Ask me to update it' "$REPOSITORY/hooks/note-new-version.sh"
assert "and the notice sends the reader to it" "$?" "the notice tells them to do it themselves"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
