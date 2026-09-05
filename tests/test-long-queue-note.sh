#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$REPOSITORY/hooks/note-long-queue.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

export UNSOLICITED_TEXT_STOP_NOTE_DIRECTORY="$TMPDIR/notes"
NOTES_FILE="$UNSOLICITED_TEXT_STOP_NOTE_DIRECTORY/test-queue.stop-notes"

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

note_for() {
  local visible="$1" reply="$2" transcript="$TMPDIR/transcript.jsonl"
  rm -f "$NOTES_FILE"
  jq --null-input --compact-output --arg body "$reply" \
    '{type:"assistant",message:{content:[{type:"text",text:$body}]}}' > "$transcript"
  jq --null-input --compact-output --arg p "$transcript" \
    '{hook_event_name:"Stop",session_id:"test-queue",transcript_path:$p}' \
    | env UNSOLICITED_TEXT_QUEUE_MAX_VISIBLE_ITEMS="$visible" bash "$HOOK" >/dev/null 2>&1
  cat "$NOTES_FILE" 2>/dev/null
}

four_items="$(printf '%s\n' 'Some answer.' '' '`[queue]`' '' \
  '1. Question: one?' '2. Question: two?' '3. Question: three?' '4. Question: four?')"

elided="$(printf '%s\n' 'Some answer.' '' '`[queue]`' '' \
  '1. Question: one?' '2. Question: two?' '...1 more pending' '4. Question: four?')"

printf "Test group: a reply showing more than the setting allows is noted\n"

said="$(note_for 2 "$four_items")"
printf '%s' "$said" | grep --quiet --fixed-strings 'showed 4 queue items with 2 visible allowed'
assert "four shown against two allowed is noted" "$?" "it said '$said'"

[ -z "$(note_for 4 "$four_items")" ]
assert "four shown against four allowed is silent" "$?" "it complained anyway"

[ -z "$(note_for 8 "$four_items")" ]
assert "and fewer than allowed is silent" "$?" "it complained anyway"

printf "\nTest group: what is raised below the elision does not count\n"

[ -z "$(note_for 2 "$elided")" ]
assert "an elided reply passes, whatever sits below the line" "$?" "the item below the elision was counted"

said="$(note_for 1 "$elided")"
printf '%s' "$said" | grep --quiet --fixed-strings 'showed 2 queue items with 1 visible allowed'
assert "only the items above the line are counted" "$?" "it said '$said'"

printf "\nTest group: zero means the count alone\n"

said="$(note_for 0 "$four_items")"
printf '%s' "$said" | grep --quiet --fixed-strings 'with 0 visible allowed'
assert "any item shown at zero is noted" "$?" "it said '$said'"

[ -z "$(note_for 0 "$(printf '%s\n' 'Some answer.' '' '`[queue]` 4 pending')")" ]
assert "and the count on its own passes" "$?" "it complained about a bare count"

printf "\nTest group: unset changes nothing\n"

[ -z "$(note_for '' "$four_items")" ]
assert "unset never notes" "$?" "it noted with no setting"

[ -z "$(note_for 'two' "$four_items")" ]
assert "and a value that is not a number counts as unset" "$?" "it read a word as a number"

printf "\nTest group: a queue inside a fenced block is an example, not a reply\n"

fenced="$(printf '%s\n' 'Here is what it looks like:' '' '```' '`[queue]`' \
  '1. Question: one?' '2. Question: two?' '3. Question: three?' '```')"
[ -z "$(note_for 1 "$fenced")" ]
assert "an example queue is not counted" "$?" "the fenced example was read as the reply's own queue"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
