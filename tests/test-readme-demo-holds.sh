#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$REPOSITORY/hooks/note-long-reply.sh"
README="$REPOSITORY/README.md"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

export STOP_NOTE_DIRECTORY="$TMPDIR/notes"
mkdir -p "$STOP_NOTE_DIRECTORY"
NOTES_FILE="$STOP_NOTE_DIRECTORY/readme-demo.stop-notes"

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

block_of() {
  awk -v opening="$1" '
    $0 == opening { waiting = 1; next }
    waiting && $0 == "```" { waiting = 0; inside = 1; next }
    inside && $0 == "```" { exit }
    inside { print }
  ' "$README"
}

note_for() {
  local body="$1" transcript="$TMPDIR/transcript.jsonl"
  rm -f "$NOTES_FILE"
  jq --null-input --compact-output --arg t "$body" \
    '{type:"assistant",message:{content:[{type:"text",text:$t}]}}' > "$transcript"
  jq --null-input --compact-output --arg p "$transcript" \
    '{hook_event_name:"Stop",session_id:"readme-demo",transcript_path:$p}' | bash "$HOOK" >/dev/null 2>&1
  cat "$NOTES_FILE" 2>/dev/null
}

printf "Test group: the readme demo is what the hook actually does\n"

before="$(note_for "$(block_of 'Without it:')")"
[ -n "$before" ]
assert "the reply shown without the plugin is over the ceiling" "$?" "the hook recorded nothing"

after="$(note_for "$(block_of 'With it:')")"
[ -z "$after" ]
assert "the reply shown with the plugin is within it" "$?" "the hook recorded '$after'"

printf "\nTest group: the readme counts what the hook counted\n"

ran="$(printf '%s' "$before" | grep --only-matching 'ran [0-9][0-9]* lines' | grep --only-matching '[0-9][0-9]*')"
ceiling="$(printf '%s' "$before" | grep --only-matching 'ceiling of [0-9][0-9]*' | grep --only-matching '[0-9][0-9]*')"

spelled() {
  case "$1" in
    3) printf 'three' ;;
    8) printf 'eight' ;;
    13) printf 'thirteen' ;;
    *) printf '%s' "$1" ;;
  esac
}

grep --quiet --ignore-case --fixed-strings "$(spelled "$ran") lines of prose" "$README"
assert "the readme names the $ran lines the hook counted" "$?" "no such count in $README"

grep --quiet --ignore-case --fixed-strings "the ceiling is $(spelled "$ceiling")" "$README"
assert "the readme names the ceiling of $ceiling" "$?" "no such ceiling in $README"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
