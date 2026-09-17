#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="$REPOSITORY/distributions/claude/skills/settings/SKILL.md"
HOOKS_DIR="$REPOSITORY/hooks"
UNSOLICITED_TEXT_SETTINGS_PATH="~/.unsolicited-text/settings"

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

printf "\nTest group: where the skill sends a reader for a setting that outlives the session\n"

grep --quiet --ignore-case --fixed-strings 'environment variable' \
  "$REPOSITORY/distributions/claude-code-cloud/skills/settings/SKILL.md"
assert "the cloud settings skill says where a setting outlives the session" "$?" \
  "a reader loses every setting on the next rebuild with nothing saying why"

grep --quiet --fixed-strings "$UNSOLICITED_TEXT_SETTINGS_PATH" "$SKILL"
assert "and names the file a rebuilt container takes away" "$?" \
  "nothing says what the environment stands in for"

printf "\nTest group: the update skill covers every harness the plugin installs into\n"

UPDATE_SKILL="$REPOSITORY/distributions/claude/skills/update/SKILL.md"

[ -f "$UPDATE_SKILL" ]
assert "skills/update/SKILL.md is there" "$?" "no skill at $UPDATE"

grep --quiet --line-regexp --fixed-strings 'name: update' "$UPDATE_SKILL"
assert "it is named update" "$?" "the name is missing or carries the plugin prefix"

grep --quiet --line-regexp --fixed-strings 'description: Update unsolicited-text to the latest version' "$UPDATE_SKILL"
assert "its description is one line" "$?" "the description has grown"

grep --quiet --fixed-strings 'no hook runs' "$SKILL"
assert "the settings skill covers a client with no hook" "$?" \
  "a session there is told a setting took effect when the file it wrote is read by nobody"

grep --quiet --fixed-strings 'holds for this conversation' "$SKILL"
assert "and says what it can do instead" "$?" "the skill is left with nothing to offer"

grep --quiet --fixed-strings '## The steps for this install' "$UPDATE_SKILL"
assert "it carries the commands for the clients it ships to" "$?" \
  "the skill neither holds them nor says where they are"

while read -r client; do
  [ -s "$REPOSITORY/clients/$client/update.md" ]
  assert "$client says how it is updated" "$?" \
    "it is installable and has no way forward from there"
done < <(jq --raw-output '.[].serves[]' "$REPOSITORY/distributions.json" | sort --unique)

printf "\nTest group: a change reaches the session that made it\n"

RELOAD="$(cat "$REPOSITORY"/clients/*/reload.md)"

grep --quiet --fixed-strings '## The steps for this install' "$SKILL"
assert "the settings skill carries the reload steps for its clients" "$?" \
  "the rules were printed at session start, and a change would wait for a restart"

grep --quiet --fixed-strings 'reload skill' "$UPDATE_SKILL"
assert "the update skill sends a reader to the reload skill" "$?" \
  "the rules were printed at session start, and a change would wait for a restart"

printf '%s' "$RELOAD" | grep --quiet --fixed-strings 'load-rules.sh'
assert "the reload steps name the loader" "$?" "there is no script to run"

missing=""
for page in "$REPOSITORY"/clients/*/reload.md; do
  grep --quiet --fixed-strings 'load-rules.sh' "$page" || continue
  grep --quiet --extended-regexp "printf '\{\}' \|" "$page" \
    || missing="$missing $(basename "$(dirname "$page")")"
done
[ -z "$missing" ]
assert "and pipe a line into every command they give" "$?" \
  "$missing names the script and never says to run it, and it waits on standard input"

while read -r client; do
  [ -s "$REPOSITORY/clients/$client/reload.md" ]
  assert "$client says where its loader is" "$?" \
    "it is installable and cannot reload its rules"
done < <(jq --raw-output '.[].serves[]' "$REPOSITORY/distributions.json" | sort --unique)

printf "\nTest group: a value the table does not allow is refused\n"

grep --quiet --fixed-strings 'Refuse a value the table above does not allow' "$SKILL"
assert "the skill refuses a value outside the table" "$?" \
  "it writes whatever it is handed, and the hooks read it as the default in silence"

grep --quiet --fixed-strings 'the hooks read it as' "$SKILL"
assert "and says when the file already holds one" "$?" "a wrong value reads as applied"

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
    = "$(sed -n 's/^description: //p' "$skill/body.md" | head -1)" ]
  assert "and describes $named the same way the skill does" "$?" \
    "the menu and the skill list would say different things about it"
done

for named in update settings; do
  grep --quiet --fixed-strings "unsolicited-text:$named" "$REPOSITORY/hooks/note-new-version.sh"
  assert "the notice names unsolicited-text:$named" "$?" "it names a skill nobody can invoke"
  [ -f "$REPOSITORY/distributions/claude/skills/$named/SKILL.md" ]
  assert "and that skill is one this repository carries" "$?" "no skill at skills/$named"
done

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
