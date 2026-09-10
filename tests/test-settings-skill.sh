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
grep --quiet --extended-regexp "UNSOLICITED_TEXT_PROSE_LINE_CEILING\` +\| +\`$ceiling\`" "$SKILL"
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

grep --quiet --fixed-strings 'UPDATING.md' "$UPDATE"
assert "it points at the page that carries the commands" "$?" \
  "the skill neither holds them nor says where they are"

while read -r harness; do
  grep --quiet --fixed-strings "$harness" "$REPOSITORY/UPDATING.md"
  assert "UPDATING.md says how to update on $harness" "$?" \
    "$harness is installable from INSTALL.md and has no way forward from there"
done < <(grep --only-matching --extended-regexp '^## [0-9]+\. .*' "$REPOSITORY/INSTALL.md" \
  | sed 's/^## [0-9]*\. //' | tr ',' '\n' | sed 's/^ *//')

printf "\nTest group: a change reaches the session that made it\n"

RELOADING="$REPOSITORY/RELOADING.md"

for skill in "$SKILL" "$UPDATE"; do
  named="$(basename "$(dirname "$skill")")"
  grep --quiet --fixed-strings 'RELOADING.md' "$skill"
  assert "the $named skill points at the reloading page" "$?" \
    "the rules were printed at session start, and a change would wait for a restart"
done

grep --quiet --fixed-strings 'load-rules.sh' "$RELOADING"
assert "the page names the loader" "$?" "there is no script to run"

[ "$(grep --count --fixed-strings 'load-rules.sh' "$RELOADING")" \
  -ge "$(grep --count --extended-regexp "printf '\{\}' \|" "$RELOADING")" ]
assert "and pipes a line into every command it gives" "$?" \
  "the script waits on standard input, so a command without the pipe hangs"

while read -r harness; do
  grep --quiet --fixed-strings "$harness" "$RELOADING"
  assert "RELOADING.md says where the loader is on $harness" "$?" \
    "$harness is installable from INSTALL.md and cannot reload its rules"
done < <(grep --only-matching --extended-regexp '^## [0-9]+\. .*' "$REPOSITORY/INSTALL.md" \
  | sed 's/^## [0-9]*\. //' | tr ',' '\n' | sed 's/^ *//')

printf "\nTest group: a setting another one turns off says so\n"

grep --quiet --fixed-strings 'n.a.' "$SKILL"
assert "the skill has a value for a setting that does nothing" "$?" \
  "a key reads as set while the setting above it makes it do nothing"

for pair in UNSOLICITED_TEXT_QUEUE_MAX_VISIBLE_ITEMS UNSOLICITED_TEXT_UPDATE_CHECK_DAYS; do
  grep --quiet --fixed-strings "$pair" "$SKILL"
  assert "$pair is named as one of them" "$?" "the skill cannot say what turned it off"
done

printf "\nTest group: each skill has a menu entry that says the same thing\n"

for skill in "$REPOSITORY"/skills/*/; do
  named="$(basename "$skill")"
  command="$REPOSITORY/commands/$named.md"

  [ -f "$command" ]
  assert "commands/$named.md is there" "$?" \
    "skills/$named has no menu entry, and a skill alone never reaches the slash menu"

  [ "$(sed -n 's/^description: //p' "$command" | head -1)" \
    = "$(sed -n 's/^description: //p' "$skill/SKILL.md" | head -1)" ]
  assert "and describes $named the same way the skill does" "$?" \
    "the menu and the skill list would say different things about it"
done

for named in update settings; do
  grep --quiet --fixed-strings "unsolicited-text:$named" "$REPOSITORY/hooks/note-new-version.sh"
  assert "the notice names unsolicited-text:$named" "$?" "it names a skill nobody can invoke"
  [ -f "$REPOSITORY/skills/$named/SKILL.md" ]
  assert "and that skill is one this repository carries" "$?" "no skill at skills/$named"
done

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
