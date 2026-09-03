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
    22) printf 'twenty-two' ;;
    *) printf '%s' "$1" ;;
  esac
}

printf "Test group: the length pair is what the hook says it is\n"

before="$(note_for "$DEMO/length-before.txt")"
[ -n "$before" ]
assert "the reply recorded without the plugin is over the ceiling" "$?" "the hook recorded nothing"

after="$(note_for "$DEMO/length-after.txt")"
[ -z "$after" ]
assert "the reply recorded with the plugin is within it" "$?" "the hook recorded '$after'"

ran="$(printf '%s' "$before" | grep --only-matching 'ran [0-9][0-9]* lines' | grep --only-matching '[0-9][0-9]*')"
ceiling="$(printf '%s' "$before" | grep --only-matching 'ceiling of [0-9][0-9]*' | grep --only-matching '[0-9][0-9]*')"
kept="$(awk '
  { probe = $0; sub(/^[[:space:]]+/, "", probe) }
  probe == "`[queue]`" { queued = 1; next }
  queued && probe ~ /^[0-9]+\. / { next }
  queued && probe != "" { queued = 0 }
  NF { kept++ }
  END { print kept + 0 }' "$DEMO/length-after.txt")"

grep --quiet --ignore-case --fixed-strings "$(spelled "$ran") lines of prose against $(spelled "$kept")" "$README"
assert "the readme names $ran lines against $kept" "$?" "no such comparison in $README"

grep --quiet --ignore-case --fixed-strings "the ceiling is $(spelled "$ceiling")" "$README"
assert "the readme names the ceiling of $ceiling" "$?" "no such ceiling in $README"

printf "\nTest group: the queue pair opens one thread rather than several\n"

scattered="$(asked_outside_the_queue "$DEMO/queue-before.txt")"
[ "$scattered" -gt 1 ]
assert "the reply recorded without the plugin asks more than once mid-answer" "$?" \
  "it asks $scattered times outside a queue"

held="$(asked_outside_the_queue "$DEMO/queue-after.txt")"
[ "$held" -eq 0 ]
assert "the reply recorded with the plugin asks nothing outside the queue" "$?" \
  "it asks $held times before the queue"

listed="$(awk '
  { probe = $0; sub(/^[[:space:]]+/, "", probe) }
  probe == "`[queue]`" { queued = 1; next }
  queued && probe ~ /^[0-9]+\. / { listed++ }
  END { print listed + 0 }' "$DEMO/queue-after.txt")"
[ "$listed" -gt 1 ]
assert "the questions are listed in the queue instead" "$?" "only $listed listed"

printf "\nTest group: every recording is no older than what it records\n"

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

    grep --quiet --fixed-strings "demo/$name.gif" "$README"
    assert "the readme shows $name.gif" "$?" "no such image in $README"
  done
done

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
