#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
LOADER="$REPOSITORY/hooks/load-agents-md.sh"
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

payload="$(jq --null-input --compact-output \
  '{hook_event_name:"SessionStart",session_id:"test-load",source:"startup"}')"
printed="$(printf '%s' "$payload" | bash "$LOADER" 2>/dev/null)"

printf "Test group: the rules reach the session\n"

for heading in "## Response Formatting" "## Plain English" "## Pre-send checklist" "## Reply shape"; do
  printf '%s' "$printed" | grep --quiet --fixed-strings "$heading"
  assert "the loader prints $heading" "$?" "no such heading on stdout"
done

printf "\nTest group: no rules file, no output\n"

mkdir -p "$TMPDIR/hooks"
cp "$LOADER" "$TMPDIR/hooks/load-agents-md.sh"
absent="$(printf '%s' "$payload" | bash "$TMPDIR/hooks/load-agents-md.sh" 2>/dev/null)"
status="$?"

[ "$status" = "0" ]
assert "it exits 0 with no rules file beside it" "$?" "exited $status"

[ -z "$absent" ]
assert "it prints nothing with no rules file beside it" "$?" "printed '$absent'"

printf "\nTest group: what earlier versions wrote is cleared away\n"

superseded="$TMPDIR/home/.local/state/unsolicited-text"

mkdir -p "$superseded/notes"
printf 'a note\n' > "$superseded/notes/session.stop-notes"
printf '%s' "$payload" | env HOME="$TMPDIR/home" bash "$LOADER" >/dev/null 2>&1
[ ! -d "$superseded" ]
assert "the old notes directory goes" "$?" "it is still there"

mkdir -p "$superseded/notes"
printf 'not ours\n' > "$superseded/keep-me"
printf '%s' "$payload" | env HOME="$TMPDIR/home" bash "$LOADER" >/dev/null 2>&1
[ -f "$superseded/keep-me" ]
assert "anything else in it stays" "$?" "it was removed"

printf "\nTest group: a settings file written before the rename is carried over\n"

home="$TMPDIR/home/.unsolicited-text"
mkdir -p "$home"
rm -f "$home/settings"
printf 'UNSOLICITED_TEXT_PROSE_LINE_CEILING = 11\n' > "$home/config"
printf '%s' "$payload" | env HOME="$TMPDIR/home" bash "$LOADER" >/dev/null 2>&1

[ ! -f "$home/config" ] && [ -f "$home/settings" ]
assert "the old file becomes the settings file" "$?" "it was not moved"

printf 'UNSOLICITED_TEXT_PROSE_LINE_CEILING = 9\n' > "$home/config"
printf '%s' "$payload" | env HOME="$TMPDIR/home" bash "$LOADER" >/dev/null 2>&1

grep --quiet --fixed-strings '11' "$home/settings"
assert "and a settings file already there is not overwritten" "$?" "the old file won"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
