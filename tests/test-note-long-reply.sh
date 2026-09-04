#!/usr/bin/env bash

HOOK="$(cd "$(dirname "$0")/../hooks" && pwd)/note-long-reply.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

export UNSOLICITED_TEXT_STOP_NOTE_DIRECTORY="$TMPDIR/notes"
mkdir -p "$UNSOLICITED_TEXT_STOP_NOTE_DIRECTORY"
NOTES_FILE="$UNSOLICITED_TEXT_STOP_NOTE_DIRECTORY/test-length.stop-notes"

pass=0
fail=0

write_transcript() {
  local text="$1" file="$TMPDIR/transcript.jsonl" asked="${2:-a question}"
  : > "$file"
  jq --null-input --compact-output --arg a "$asked" '{type:"user",message:{content:$a}}' >> "$file"
  jq --null-input --compact-output --arg t "$text" \
    '{type:"assistant",message:{content:[{type:"text",text:$t}]}}' >> "$file"
  printf '%s' "$file"
}

run_payload() {
  local sent
  rm -f "$NOTES_FILE"
  sent="$(printf '%s' "$1" | bash "$HOOK" 2>/dev/null)"
  if [ -n "$sent" ]; then
    printf 'THE REPLY WAS DISCARDED: %s' "$sent"
    return 0
  fi
  [ -f "$NOTES_FILE" ] && cat "$NOTES_FILE"
  return 0
}

run_hook() {
  local text="$1" active="${2:-false}" asked="${3:-a question}" transcript payload
  transcript="$(write_transcript "$text" "$asked")"
  payload="$(jq --null-input --compact-output --arg p "$transcript" --argjson a "$active" \
    '{hook_event_name:"Stop",session_id:"test-length",transcript_path:$p,stop_hook_active:$a}')"
  run_payload "$payload"
}

assert_records() {
  local label="$1" note="$2"
  if [ -n "$note" ] && [ "${note#THE REPLY WAS DISCARDED}" = "$note" ]; then
    printf "  OK  %s\n" "$label"
    pass=$((pass + 1))
  else
    printf "  KO  %s — expected a recorded note, got '%s'\n" "$label" "$note"
    fail=$((fail + 1))
  fi
}

assert_silent() {
  local label="$1" note="$2"
  if [ -z "$note" ]; then
    printf "  OK  %s\n" "$label"
    pass=$((pass + 1))
  else
    printf "  KO  %s — expected nothing recorded, got '%s'\n" "$label" "$note"
    fail=$((fail + 1))
  fi
}

assert_names_the_queue() {
  local label="$1" note="$2"
  if printf '%s' "$note" | grep --quiet --fixed-strings "$queue_tag"; then
    printf "  OK  %s\n" "$label"
    pass=$((pass + 1))
  else
    printf "  KO  %s — the note never names the queue: '%s'\n" "$label" "$note"
    fail=$((fail + 1))
  fi
}

prose_of() { seq 1 "$1" | sed 's/^/point /'; }
queue_of() { seq 1 "$1" | awk '{ print NR ". Q: open item " NR }'; }

fence="$(printf '\140\140\140')"
queue_tag="$(printf '\140[queue]\140')"

printf "Test group: the ceiling\n"

assert_records "a write-up" "$(run_hook "$(prose_of 40)")"
assert_records "one line over" "$(run_hook "$(prose_of 9)")"
assert_silent "a one-line answer" "$(run_hook 'Done — the hook is wired up.')"
assert_silent "exactly at the ceiling" "$(run_hook "$(prose_of 8)")"
assert_silent "blank lines do not count" \
  "$(run_hook "$(prose_of 8)$(printf '\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n')")"

printf "\nTest group: the reply is never discarded\n"

discarded="$(printf '%s' "$(run_hook "$(prose_of 40)")" | grep --count 'THE REPLY WAS DISCARDED')"
if [ "$discarded" = "0" ]; then
  printf "  OK  %s\n" "the hook sends nothing back over the ceiling"
  pass=$((pass + 1))
else
  printf "  KO  %s\n" "the hook still discards the reply over the ceiling"
  fail=$((fail + 1))
fi

printf "\nTest group: long output that is not long prose\n"

assert_silent "a 60-line code block" \
  "$(run_hook "$(printf 'here is the diff:\n%s diff\n%s\n%s\n' "$fence" "$(prose_of 60)" "$fence")")"
assert_silent "an indented code block inside a toggle" \
  "$(run_hook "$(printf 'the change:\n\t%s bash\n%s\n\t%s\n' "$fence" "$(prose_of 60 | sed 's/^/\t/')" "$fence")")"
assert_silent "a 40-row table" \
  "$(run_hook "$(printf 'the options:\n%s\n' "$(seq 1 40 | sed 's/^/| row /;s/$/ | yes |/')")")"
assert_records "prose either side of a code block still counts" \
  "$(run_hook "$(printf '%s\n%s bash\necho hi\n%s\n%s\n' "$(prose_of 15)" "$fence" "$fence" "$(prose_of 15)")")"

printf "\nTest group: the queue below the answer\n"

assert_silent "an answer at the ceiling with a queue under it" \
  "$(run_hook "$(printf '%s\n\n%s\n\n%s\n' "$(prose_of 8)" "$queue_tag" "$(queue_of 6)")")"
assert_records "prose above the queue still counts" \
  "$(run_hook "$(printf '%s\n\n%s\n\n%s\n' "$(prose_of 9)" "$queue_tag" "$(queue_of 2)")")"
assert_records "a queue drawn inside a code block exempts nothing after it" \
  "$(run_hook "$(printf '%s\n%s\n%s\n%s\n' "$fence" "$queue_tag" "$fence" "$(prose_of 9)")")"
assert_records "prose below the queue is not exempted by it" \
  "$(run_hook "$(printf '%s\n\n%s\n\n%s\n\n%s\n' "$(prose_of 2)" "$queue_tag" "$(queue_of 2)" "$(prose_of 9)")")"
assert_names_the_queue "the note points at the queue" "$(run_hook "$(prose_of 9)")"

printf "\nTest group: the guards\n"

assert_silent "loop guard — already continued once" "$(run_hook "$(prose_of 40)" true)"
assert_silent "no transcript path" \
  "$(run_payload "$(jq --null-input --compact-output '{hook_event_name:"Stop",session_id:"test-length"}')")"
assert_silent "transcript path that does not exist" \
  "$(run_payload "$(jq --null-input --compact-output \
    '{hook_event_name:"Stop",session_id:"test-length",transcript_path:"/no/such/file"}')")"
assert_silent "no session id to file the note under" \
  "$(run_payload "$(jq --null-input --compact-output --arg p "$(write_transcript "$(prose_of 40)")" \
    '{hook_event_name:"Stop",transcript_path:$p}')")"

printf "\nTest group: whose reply is being measured\n"

sidechain="$TMPDIR/sidechain.jsonl"
jq --null-input --compact-output --arg t "$(prose_of 3)" \
  '{type:"assistant",message:{content:[{type:"text",text:$t}]}}' > "$sidechain"
jq --null-input --compact-output --arg t "$(prose_of 40)" \
  '{type:"assistant",isSidechain:true,message:{content:[{type:"text",text:$t}]}}' >> "$sidechain"
assert_silent "a subagent's reply is not the turn being read" \
  "$(run_payload "$(jq --null-input --compact-output --arg p "$sidechain" \
    '{hook_event_name:"Stop",session_id:"test-length",transcript_path:$p}')")"

multi="$TMPDIR/multi.jsonl"
jq --null-input --compact-output --arg t "$(prose_of 40)" \
  '{type:"assistant",message:{content:[{type:"text",text:$t}]}}' > "$multi"
jq --null-input --compact-output '{type:"user",message:{content:[{type:"tool_result",content:"ok"}]}}' >> "$multi"
jq --null-input --compact-output '{type:"assistant",message:{content:[{type:"text",text:"short now"}]}}' >> "$multi"
assert_silent "an earlier turn's length is not this turn's" \
  "$(run_payload "$(jq --null-input --compact-output --arg p "$multi" \
    '{hook_event_name:"Stop",session_id:"test-length",transcript_path:$p}')")"

trailing_tool="$TMPDIR/trailing-tool.jsonl"
jq --null-input --compact-output --arg t "$(prose_of 40)" \
  '{type:"assistant",message:{content:[{type:"text",text:$t}]}}' > "$trailing_tool"
jq --null-input --compact-output \
  '{type:"assistant",message:{content:[{type:"tool_use",name:"Bash",input:{}}]}}' >> "$trailing_tool"
assert_records "the reply is found behind a trailing tool call" \
  "$(run_payload "$(jq --null-input --compact-output --arg p "$trailing_tool" \
    '{hook_event_name:"Stop",session_id:"test-length",transcript_path:$p}')")"

thinking="$TMPDIR/thinking.jsonl"
jq --null-input --compact-output --arg think "$(prose_of 40)" \
  '{type:"assistant",message:{content:[{type:"thinking",thinking:$think},{type:"text",text:"short"}]}}' \
  > "$thinking"
assert_silent "words weighed in thinking are not words sent" \
  "$(run_payload "$(jq --null-input --compact-output --arg p "$thinking" \
    '{hook_event_name:"Stop",session_id:"test-length",transcript_path:$p}')")"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
