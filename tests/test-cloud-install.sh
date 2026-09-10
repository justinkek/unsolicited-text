#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL="$REPOSITORY/harness-adapters/claude-code/install-cloud.sh"
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

home="$TMPDIR/home"
settings="$home/.claude/settings.json"

install() { env HOME="$home" bash "$INSTALL"; }

held() { jq --raw-output ".hooks[\"$1\"][]?.hooks[]?.command" "$settings" | grep --count --fixed-strings "$2"; }

printf "Test group: an install puts everything a session reads in place\n"

install
assert "the install exits 0" "$?" "the setup script would report a failure"

[ -f "$home/.claude/skills/settings/SKILL.md" ]
assert "the settings skill is in place" "$?" "the skill never appears"

[ -f "$home/.claude/commands/unsolicited-text-update.md" ]
assert "the update command is in place" "$?" "the menu entry never appears"

[ "$(held SessionStart "$REPOSITORY/hooks/load-rules.sh")" = "1" ]
assert "the rules are printed at session start" "$?" "a session would be handed no rules"

[ "$(held UserPromptSubmit "$REPOSITORY/hooks/note-new-version.sh")" = "1" ]
assert "and every other hook is registered too" "$?" "some of them never fire"

printf "\nTest group: installing over a settings file keeps what it holds\n"

jq --tab '.hooks.SessionStart += [ { hooks: [ { type: "command", command: "/somewhere/theirs.sh" } ] } ]' \
  "$settings" > "$settings.theirs" && mv "$settings.theirs" "$settings"

install
assert "the install exits 0" "$?" "the setup script would report a failure"

[ "$(held SessionStart "/somewhere/theirs.sh")" = "1" ]
assert "a hook the reader registered themselves survives it" "$?" \
  "every install and every refresh takes it away again"

[ "$(held SessionStart "$REPOSITORY/hooks/load-rules.sh")" = "1" ]
assert "and this plugin is registered once, not twice" "$?" "the rules print again for each copy"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
