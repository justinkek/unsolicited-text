#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$REPOSITORY/hooks"
LONG_REPLY_HOOK="$HOOKS_DIR/note-long-reply.sh"
RULES="$REPOSITORY/AGENTS.md"

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

printf "Test group: the ceiling the rules state is the ceiling the hook enforces\n"

enforced="$(grep --only-matching 'PROSE_LINE_CEILING=[0-9][0-9]*' "$LONG_REPLY_HOOK" \
  | grep --only-matching '[0-9][0-9]*' | sort --unique)"

if [ -n "$enforced" ]; then
  assert "the hook names a ceiling" 0 ""
else
  assert "the hook names a ceiling" 1 "no PROSE_LINE_CEILING assignment in $LONG_REPLY_HOOK"
fi

grep --quiet --fixed-strings "at most $enforced non-blank lines of prose" "$RULES"
assert "the rules state that same number" "$?" \
  "expected 'at most $enforced non-blank lines of prose' in $RULES"

stated="$(grep --only-matching 'at most [0-9][0-9]* non-blank lines of prose' "$RULES" \
  | grep --only-matching '[0-9][0-9]*' | sort --unique | grep --count .)"
[ "$stated" = "1" ]
assert "the rules state it once" "$?" "found $stated different numbers in $RULES"

printf "\nTest group: the queue is exempt on both sides and the note says so\n"

grep --quiet --fixed-strings 'probe == queue_tag' "$LONG_REPLY_HOOK"
assert "the hook skips the queue" "$?" "no queue skip in $LONG_REPLY_HOOK"

grep --quiet --fixed-strings 'the `[queue]` line with every item under it, do not count' "$RULES"
assert "the rules exempt the queue too" "$?" "the exemption clause does not name the queue in $RULES"

grep --quiet --fixed-strings 'under \`[queue]\`' "$LONG_REPLY_HOOK"
assert "the note points at the queue" "$?" "the note does not name the queue in $LONG_REPLY_HOOK"

grep --quiet --fixed-strings 'What needs my attention goes in the queue' "$RULES"
assert "the rules send what needs attention there" "$?" "no such clause in $RULES"

printf "\nTest group: no turn-end check discards the reply\n"

for hook_path in "$HOOKS_DIR/note-long-reply.sh"; do
  hook="$(basename "$hook_path")"
  grep --quiet --fixed-strings '"decision":"block"' "$hook_path"
  [ "$?" = "1" ]
  assert "$hook sends no block back" "$?" "$hook still returns a block decision"

  grep --quiet --fixed-strings 'stop_note_record' "$hook_path"
  assert "$hook records its finding" "$?" "no stop_note_record call in $hook"
done

grep --quiet --fixed-strings 'stop_note_take' "$HOOKS_DIR/replay-stop-notes.sh"
assert "the replay takes what they recorded" "$?" "no stop_note_take call in replay-stop-notes.sh"

printf "\nTest group: the rules name only the four tags a reply may carry\n"

defined_tags="$(grep --only-matching --extended-regexp '^  - `\[[a-z ]+\]`' "$RULES" | sort --unique)"
[ "$(printf '%s\n' "$defined_tags" | grep --count .)" = "4" ]
assert "four tag definitions and no more" "$?" \
  "expected 4 definitions in $RULES, found: $(printf '%s ' $defined_tags)"

for tag in answer problem fix queue; do
  printf '%s\n' "$defined_tags" | grep --quiet --fixed-strings "\`[$tag]\`"
  assert "the rules define [$tag]" "$?" "no definition of [$tag] in $RULES"
done

printf "\nTest group: an unanswered question is carried in the queue\n"

grep --quiet --fixed-strings 'stays listed in every reply until I answer it' "$RULES"
assert "the rules carry an unanswered question forward" "$?" \
  "expected the carry-forward rule to state how long it stays listed, in $RULES"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
