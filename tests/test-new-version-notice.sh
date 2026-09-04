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
    printf "  OK  %s\n" "$label"
    pass=$((pass + 1))
  else
    printf "  KO  %s — %s\n" "$label" "$detail"
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
printf '%s' "$said" | grep --quiet --fixed-strings "9.9.9 is now available (current: $installed)"
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

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
