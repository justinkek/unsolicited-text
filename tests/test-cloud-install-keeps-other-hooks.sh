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

install() { env HOME="$home" bash "$INSTALL" 2>"$TMPDIR/said"; }

settings() { printf '%s' "$home/.claude/settings.json"; }

commands_at() {
  jq --raw-output ".hooks[\"$1\"][]?.hooks[]?.command" "$(settings)"
}

registered() {
  commands_at "$1" | grep --quiet --fixed-strings "$2"
}

printf "Test group: an install with nothing there writes the registrations\n"

install
assert "the install exits 0" "$?" "the setup script would report a failure"

registered SessionStart "$REPOSITORY/hooks/load-rules.sh"
assert "the rules are printed at session start" "$?" "a session would be handed no rules"

registered UserPromptSubmit "$REPOSITORY/hooks/note-new-version.sh"
assert "and every other hook is registered too" "$?" "some of them never fire"

printf "\nTest group: an install keeps hooks somebody else registered\n"

cat > "$(settings)" <<'JSON'
{
	"env": { "THEIRS": "kept" },
	"hooks": {
		"SessionStart": [ { "hooks": [ { "type": "command", "command": "/somewhere/theirs.sh" } ] } ],
		"PreToolUse": [ { "matcher": "Bash", "hooks": [ { "type": "command", "command": "/somewhere/guard.sh" } ] } ]
	}
}
JSON

install
assert "the install exits 0" "$?" "the setup script would report a failure"

registered SessionStart "/somewhere/theirs.sh"
assert "their session start hook is still registered" "$?" \
  "installing took away a hook the reader registered themselves"

registered PreToolUse "/somewhere/guard.sh"
assert "so is a hook on an event this plugin never touches" "$?" \
  "a whole event the reader configured was dropped"

[ "$(jq --raw-output '.env.THEIRS' "$(settings)")" = "kept" ]
assert "and a setting that is not a hook is untouched" "$?" "everything but the hooks was dropped"

registered SessionStart "$REPOSITORY/hooks/load-rules.sh"
assert "the plugin's own hooks are registered beside theirs" "$?" \
  "the merge kept their file and registered nothing"

printf "\nTest group: installing twice registers each hook once\n"

install
[ "$(commands_at SessionStart | grep --count --fixed-strings "$REPOSITORY/hooks/load-rules.sh")" = "1" ]
assert "a second install does not register load-rules.sh twice" "$?" \
  "every refresh adds another copy, and the rules print again for each"

[ "$(commands_at SessionStart | grep --count --fixed-strings "/somewhere/theirs.sh")" = "1" ]
assert "and still holds their hook once" "$?" "their hook was duplicated or dropped"

printf "\nTest group: a settings file that does not parse is kept, not thrown away\n"

printf 'this is not json' > "$(settings)"
install
assert "the install exits 0" "$?" "the setup script would report a failure"

[ "$(cat "$home/.claude/settings.json.unreadable")" = "this is not json" ]
assert "the file it could not read is kept beside the new one" "$?" \
  "what the reader wrote is gone with nothing to recover it from"

registered SessionStart "$REPOSITORY/hooks/load-rules.sh"
assert "and the registrations are written all the same" "$?" "the session gets no hooks"

grep --quiet --fixed-strings "unreadable" "$TMPDIR/said"
assert "the install says it did that" "$?" "it happened silently"

printf "\nTest group: the skills and commands are copied\n"

[ -f "$home/.claude/skills/settings/SKILL.md" ]
assert "the settings skill is in place" "$?" "the skill never appears"

[ -f "$home/.claude/commands/unsolicited-text-update.md" ]
assert "and the update command is in place" "$?" "the menu entry never appears"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
