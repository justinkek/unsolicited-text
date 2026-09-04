#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$REPOSITORY/hooks/note-long-reply.sh"
README="$REPOSITORY/README.md"
DEMO="$REPOSITORY/demo"
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

printf "\nTest group: the queue holds what the answer no longer asks\n"

scattered="$(asked_outside_the_queue "$DEMO/reply-before.txt")"
[ "$scattered" -gt 1 ]
assert "the reply recorded without the plugin asks more than once mid-answer" "$?" \
  "it asks $scattered times outside a queue"

held="$(asked_outside_the_queue "$DEMO/reply-after.txt")"
[ "$held" -eq 0 ]
assert "the reply recorded with the plugin asks nothing outside the queue" "$?" \
  "it asks $held times before the queue"

for kind in "Q:" "Investigate:" "OK/KO:"; do
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

printf "\nTest group: every recording is no older than what it records\n"

shown=0

for prompt in "$DEMO"/*.prompt; do
  pair="$(basename "$prompt" .prompt)"
  for side in before after; do
    name="$pair-$side"

    [ -f "$DEMO/$name.gif" ]
    assert "$name.gif is recorded" "$?" "run demo/record"

    for source in "$name.txt" "$pair.prompt" type; do
      [ ! "$DEMO/$source" -nt "$DEMO/$name.gif" ]
      assert "$name.gif is no older than $source" "$?" "$source changed since it was recorded, run demo/record"
    done

    if grep --quiet --fixed-strings "demo/$name.gif" "$README"; then
      shown=$((shown + 1))
    fi
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
