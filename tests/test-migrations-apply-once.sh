#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$REPOSITORY/hooks/apply-migrations.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

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

payload='{"hook_event_name":"SessionStart","session_id":"test-migrate"}'
home="$TMPDIR/home/.unsolicited-text"
mkdir -p "$home"

printf "Test group: what earlier versions wrote is cleared away\n"

superseded="$TMPDIR/home/.local/state/unsolicited-text"
moved_on() { rm -f "$TMPDIR/home/.unsolicited-text/state/applied-version"; }

mkdir -p "$superseded/notes"
printf 'a note\n' > "$superseded/notes/session.stop-notes"
moved_on
printf '%s' "$payload" | env HOME="$TMPDIR/home" bash "$HOOK" >/dev/null 2>&1
[ ! -d "$superseded" ]
assert "the old notes directory goes" "$?" "it is still there"

mkdir -p "$superseded/notes"
printf 'not ours\n' > "$superseded/keep-me"
moved_on
printf '%s' "$payload" | env HOME="$TMPDIR/home" bash "$HOOK" >/dev/null 2>&1
[ -f "$superseded/keep-me" ]
assert "anything else in it stays" "$?" "it was removed"

printf "\nTest group: a settings file written before the rename is carried over\n"

home="$TMPDIR/home/.unsolicited-text"
mkdir -p "$home"
rm -f "$home/settings"
printf 'UNSOLICITED_TEXT_PROSE_LINE_CEILING = 11\n' > "$home/config"
moved_on
printf '%s' "$payload" | env HOME="$TMPDIR/home" bash "$HOOK" >/dev/null 2>&1

[ ! -f "$home/config" ] && [ -f "$home/settings" ]
assert "the old file becomes the settings file" "$?" "it was not moved"

printf 'UNSOLICITED_TEXT_PROSE_LINE_CEILING = 9\n' > "$home/config"
moved_on
printf '%s' "$payload" | env HOME="$TMPDIR/home" bash "$HOOK" >/dev/null 2>&1

grep --quiet --fixed-strings '11' "$home/settings"
assert "and a settings file already there is not overwritten" "$?" "the old file won"

printf "\nTest group: a migration runs when the version moves, and not otherwise\n"

version="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  "$REPOSITORY/package.json" | head -1)"
marker="$TMPDIR/home/.unsolicited-text/state/applied-version"

grep --quiet --line-regexp --fixed-strings "$version" "$marker"
assert "the version applied is written down" "$?" "nothing records what has already run"

printf 'UNSOLICITED_TEXT_PROSE_LINE_CEILING = 7\n' > "$home/config"
printf '%s' "$payload" | env HOME="$TMPDIR/home" bash "$HOOK" >/dev/null 2>&1

[ -f "$home/config" ]
assert "and a migration does not run again at the same version" "$?" \
  "every migration ever written runs on every session start"

rm -f "$home/config"


printf "\nTest group: the hook says nothing into the session\n"

said="$(printf '%s' "$payload" | env HOME="$TMPDIR/home" bash "$HOOK" 2>/dev/null)"
[ -z "$said" ]
assert "it prints nothing" "$?" "it printed '$said'"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
