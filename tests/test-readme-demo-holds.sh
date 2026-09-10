#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$REPOSITORY/hooks/note-long-reply.sh"
README="$REPOSITORY/README.md"
DEMO="$REPOSITORY/demo"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

export UNSOLICITED_TEXT_STOP_NOTE_DIRECTORY="$TMPDIR/notes"
mkdir -p "$UNSOLICITED_TEXT_STOP_NOTE_DIRECTORY"
NOTES_FILE="$UNSOLICITED_TEXT_STOP_NOTE_DIRECTORY/readme-demo.stop-notes"

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

note_for() {
  local reply="$1" transcript="$TMPDIR/transcript.jsonl"
  rm -f "$NOTES_FILE"
  jq --null-input --compact-output --rawfile body "$reply" \
    '{type:"assistant",message:{content:[{type:"text",text:$body}]}}' > "$transcript"
  jq --null-input --compact-output --arg p "$transcript" \
    '{hook_event_name:"Stop",session_id:"readme-demo",transcript_path:$p}' | bash "$HOOK" >/dev/null 2>&1
  cat "$NOTES_FILE" 2>/dev/null
}

asked_outside_the_queue() {
  awk '
    { probe = $0; sub(/^[[:space:]]+/, "", probe) }
    probe == "`[queue]`" { exit }
    /\?/ { asked++ }
    END { print asked + 0 }' "$1"
}

spelled() {
  case "$1" in
    6) printf 'six' ;;
    8) printf 'eight' ;;
    17) printf 'seventeen' ;;
    *) printf '%s' "$1" ;;
  esac
}

printf "Test group: the reply pair is what the hook says it is\n"

before="$(note_for "$DEMO/reply-before.txt")"
[ -n "$before" ]
assert "the reply recorded without the plugin is over the ceiling" "$?" "the hook recorded nothing"

after="$(note_for "$DEMO/reply-after.txt")"
[ -z "$after" ]
assert "the reply recorded with the plugin is within it" "$?" "the hook recorded '$after'"

printf "\nTest group: the drift pair is a reply that drifted and one that did not\n"

drifted="$(note_for "$DEMO/drift-before.txt")"
[ -n "$drifted" ]
assert "the reply shown without it is over the ceiling" "$?" "the hook recorded nothing"

held="$(note_for "$DEMO/drift-after.txt")"
[ -z "$held" ]
assert "the reply shown with it is within the ceiling" "$?" "the hook recorded '$held'"

grep --quiet --ignore-case --fixed-strings 'turn 40' "$DEMO/drift.prompt"
assert "and the prompt says how far into the session they are" "$?" \
  "nothing in the pair says this is a long session, which is the whole point"

printf "\nTest group: the demos show what a session shows by default\n"

emoji_in() {
  python3 -c '
import sys, unicodedata
print("".join(sorted({c for c in open(sys.argv[1]).read() if unicodedata.east_asian_width(c) == "W"})))' "$1"
}

carried=""
for reply in "$DEMO"/*.txt; do
  case "$(basename "$reply")" in emoji-after.txt) continue ;; esac
  [ -z "$(emoji_in "$reply")" ] || carried="$carried $(basename "$reply")"
done
[ -z "$carried" ]
assert "no recording shows the emoji, which are off unless asked for" "$?" "$carried does"

[ -n "$(emoji_in "$DEMO/emoji-after.txt")" ] && [ -z "$(emoji_in "$DEMO/emoji-before.txt")" ]
assert "except the pair whose whole subject is turning them on" "$?" \
  "its two halves do not differ, so it demonstrates nothing"

printf "\nTest group: the queue holds what the answer no longer asks\n"

scattered="$(asked_outside_the_queue "$DEMO/reply-before.txt")"
[ "$scattered" -gt 1 ]
assert "the reply recorded without the plugin asks more than once mid-answer" "$?" \
  "it asks $scattered times outside a queue"

held="$(asked_outside_the_queue "$DEMO/reply-after.txt")"
[ "$held" -eq 0 ]
assert "the reply recorded with the plugin asks nothing outside the queue" "$?" \
  "it asks $held times before the queue"

for kind in "Question:" "Investigate:" "Approve/Reject:"; do
  grep --quiet --extended-regexp "^[0-9]+\. $kind" "$DEMO/reply-after.txt"
  assert "the queue carries a $kind item" "$?" "no such item"
done

printf "\nTest group: the table pair compares in rows rather than sentences\n"

rows="$(grep --count '^|' "$DEMO/table-after.txt")"
[ "$rows" -gt 3 ]
assert "the reply recorded with the plugin lays the comparison out in rows" "$?" "only $rows rows"

rows="$(grep --count '^|' "$DEMO/table-before.txt")"
[ "$rows" -eq 0 ]
assert "the reply recorded without the plugin has none" "$?" "$rows rows already"

table="$(note_for "$DEMO/table-after.txt")"
[ -z "$table" ]
assert "rows do not count against the ceiling" "$?" "the hook recorded '$table'"

printf "\nTest group: the plain pair says the same thing without the decoding\n"

DECODED='doorbell|bouncer|under the hood|ISO 8601|schema|subsystem|payload'

carried="$(grep --count --extended-regexp --ignore-case "$DECODED" "$DEMO/plain-before.txt")"
[ "$carried" -gt 1 ]
assert "the reply recorded without the plugin makes the reader translate" "$?" \
  "only $carried lines carry a metaphor or a name to look up"

carried="$(grep --count --extended-regexp --ignore-case "$DECODED" "$DEMO/plain-after.txt")"
[ "$carried" -eq 0 ]
assert "the reply recorded with the plugin carries none of it" "$?" "$carried lines still do"

printf "\nTest group: the directive pair reports finished work in one line\n"

directive="$(note_for "$DEMO/directive-before.txt")"
[ -n "$directive" ]
assert "the write-up recorded without the plugin is over the ceiling" "$?" "the hook recorded nothing"

reported="$(grep --count . "$DEMO/directive-after.txt")"
[ "$reported" -le 2 ]
assert "the reply recorded with the plugin is one statement" "$?" "it runs to $reported lines"

grep --quiet --fixed-strings '`[' "$DEMO/directive-after.txt"
[ "$?" = "1" ]
assert "and carries no tag, because nothing was asked" "$?" "it is tagged"

printf "\nTest group: every line fits the terminal it is typed into\n"

COLUMNS_RECORDED="${DEMO_COLUMNS:-43}"

widest_line() {
  python3 -c '
import sys, unicodedata
widest = 0
for line in open(sys.argv[1]).read().splitlines():
    widest = max(widest, sum(2 if unicodedata.east_asian_width(c) == "W" else 1 for c in line))
print(widest)' "$1"
}

for reply in "$DEMO"/*.txt "$DEMO"/*.prompt; do
  widest="$(widest_line "$reply")"
  fits="$reply"
  pair="$(basename "$reply")"
  pair="${pair%-before.txt}"; pair="${pair%-after.txt}"; pair="${pair%.prompt}"
  allowed="$COLUMNS_RECORDED"
  if [ -f "$DEMO/$pair.width" ]; then
    allowed="$(awk -v pixels="$(head -1 "$DEMO/$pair.width")" -v fits="$COLUMNS_RECORDED" \
      'BEGIN { printf "%d", pixels * fits / 400 }')"
  fi
  [ "$widest" -le "$allowed" ]
  outcome="$?"
  assert "$(basename "$fits") fits in $allowed columns" "$outcome" \
    "its widest line is $widest, so the recording wraps it"
done

printf "\nTest group: every recording carries the sources it was recorded from\n"

shown=0

for prompt in "$DEMO"/*.prompt; do
  pair="$(basename "$prompt" .prompt)"

  for side in before after; do
    name="$pair-$side"

    [ -f "$DEMO/$name.gif" ]
    assert "$name.gif is recorded" "$?" "run demo/record"

    if grep --quiet --fixed-strings "demo/$name.gif" "$README"; then
      shown=$((shown + 1))
    fi
  done

  [ -f "$DEMO/$pair.sha" ]
  assert "$pair.sha names what the pair was recorded from" "$?" "run demo/record"
  [ -f "$DEMO/$pair.sha" ] || continue

  recorded=""
  while read -r hash source; do
    recorded="$recorded $source"
    [ "$hash" = "$(git -C "$DEMO" hash-object "$source" 2>/dev/null)" ]
    assert "$pair was recorded from the $source on disk" "$?" \
      "$source changed since the recording, run demo/record"
  done < "$DEMO/$pair.sha"

  for source in type "$pair.prompt" "$pair-before.txt" "$pair-after.txt"; do
    case " $recorded " in
      *" $source "*) continue ;;
    esac
    false
    assert "$pair.sha names $source" "$?" "the recording is unchecked against it, run demo/record"
  done
done

printf "\nTest group: every recording the readme shows is one this repository carries\n"

[ "$shown" -gt 0 ]
assert "the readme shows recordings at all" "$?" "no demo image in $README"

missing=""
while read -r image; do
  [ -f "$REPOSITORY/$image" ] || missing="$missing $image"
done < <(grep --only-matching --extended-regexp 'demo/[a-z-]+\.gif' "$README" | sort --unique)
[ -z "$missing" ]
assert "and carries every one it shows" "$?" "$missing"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
