#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$REPOSITORY/hooks/note-new-version.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

PAYLOAD='{"hook_event_name":"SessionStart","session_id":"test-version"}'
STATE="$TMPDIR/home/.unsolicited-text/state"

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

session() {
  printf '%s' "$PAYLOAD" | env HOME="$TMPDIR/home" \
    UNSOLICITED_TEXT_VERSION_SOURCE="file://$TMPDIR/published.json" "$@" bash "$HOOK" 2>/dev/null
  sleep 1
}

installed="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  "$REPOSITORY/.claude-plugin/plugin.json" | head -1)"

printf "Test group: a newer version is noticed once and said once\n"

rm -rf "$TMPDIR/home"
printf '{"version":"9.9.9"}\n' > "$TMPDIR/published.json"

[ -z "$(session)" ]
assert "the session that checks says nothing" "$?" "it spoke before it knew"

said="$(session)"
printf '%s' "$said" | grep --quiet --fixed-strings "version 9.9.9 is now available (current: $installed)"
assert "the next session says what is out" "$?" "it said '$said'"

[ -z "$(session)" ]
assert "and does not say it twice" "$?" "the notice outlived being read"

printf "\nTest group: the check is throttled, and can be turned off\n"

rm -rf "$TMPDIR/home"
session >/dev/null
before="$(cat "$STATE/version-checked")"
session >/dev/null
[ "$(cat "$STATE/version-checked")" = "$before" ]
assert "a second session inside the interval does not check again" "$?" "it checked again"

rm -rf "$TMPDIR/home"
session UNSOLICITED_TEXT_UPDATE_CHECK=off >/dev/null
[ ! -f "$STATE/version-checked" ]
assert "off means it never reaches for the network" "$?" "it checked anyway"

printf "\nTest group: the version you are on is not news\n"

rm -rf "$TMPDIR/home"
printf '{"version":"%s"}\n' "$installed" > "$TMPDIR/published.json"
session >/dev/null
[ -z "$(rm -f "$STATE/version-checked"; session)" ]
assert "the same version says nothing" "$?" "it announced itself"

rm -rf "$TMPDIR/home"
printf '{"version":"0.0.1"}\n' > "$TMPDIR/published.json"
session >/dev/null
[ -z "$(rm -f "$STATE/version-checked"; session)" ]
assert "an older one says nothing either" "$?" "it offered a downgrade"

printf "\nTest group: an interval in seconds becomes one in days\n"

renamed="$(mktemp -d)"
mkdir -p "$renamed/.unsolicited-text"
printf 'UNSOLICITED_TEXT_UPDATE_CHECK_INTERVAL = 172800\n' > "$renamed/.unsolicited-text/settings"
printf '{}' | env HOME="$renamed" bash "$REPOSITORY/hooks/load-rules.sh" >/dev/null 2>&1

grep --quiet --line-regexp --fixed-strings 'UNSOLICITED_TEXT_UPDATE_CHECK_DAYS = 2' \
  "$renamed/.unsolicited-text/settings"
assert "two days of seconds is rewritten as two days" "$?" \
  "the old key is left behind and the setting stops holding"

printf 'UNSOLICITED_TEXT_UPDATE_CHECK_INTERVAL = 600\n' > "$renamed/.unsolicited-text/settings"
rm -f "$renamed/.unsolicited-text/state/applied-version"
printf '{}' | env HOME="$renamed" bash "$REPOSITORY/hooks/load-rules.sh" >/dev/null 2>&1

grep --quiet --line-regexp --fixed-strings 'UNSOLICITED_TEXT_UPDATE_CHECK_DAYS = 1' \
  "$renamed/.unsolicited-text/settings"
assert "anything under a day becomes one day" "$?" "a fraction of a day rounds to no check at all"

rm -rf "$renamed"

printf "\nTest group: the check runs where a long session reaches it\n"

for manifest in "$REPOSITORY/hooks/hooks.json" "$REPOSITORY/harness-adapters/codex/hooks.json"; do
  named="$(basename "$(dirname "$manifest")")"

  python3 - "$manifest" <<'CHECK'
import json, sys
hooks = json.load(open(sys.argv[1]))["hooks"]
def names(event):
    return [h["command"] for group in hooks.get(event, []) for h in group["hooks"]]
prompt = any("note-new-version" in c for c in names("UserPromptSubmit"))
start = any("note-new-version" in c for c in names("SessionStart"))
sys.exit(0 if prompt and not start else 1)
CHECK
  assert "$named asks at a prompt rather than at session start" "$?" \
    "a session that never restarts never checks, and never prints what it found"
done

grep --quiet --fixed-strings 'note-new-version.sh' "$REPOSITORY/harness-adapters/pi/src/index.ts"
assert "the pi shim asks too" "$?" "pi is told about no version but the one it installed"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
