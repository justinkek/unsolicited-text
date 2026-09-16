#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
LOADER="$REPOSITORY/hooks/load-rules.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

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

# Every setting the hook rewrites the rules with, at the values that read worst.
settings() {
  printf '%s\n' \
    "" \
    "UNSOLICITED_TEXT_PROSE_LINE_CEILING=1 UNSOLICITED_TEXT_PROSE_WORD_CEILING=1" \
    "UNSOLICITED_TEXT_PROSE_LINE_CEILING=2 UNSOLICITED_TEXT_PROSE_WORD_CEILING=40" \
    "UNSOLICITED_TEXT_QUEUE_MAX_VISIBLE_ITEMS=0" \
    "UNSOLICITED_TEXT_QUEUE_MAX_VISIBLE_ITEMS=1" \
    "UNSOLICITED_TEXT_QUEUE_MAX_VISIBLE_ITEMS=5" \
    "UNSOLICITED_TEXT_QUEUE_TREE=always-on" \
    "UNSOLICITED_TEXT_QUEUE_TREE=off UNSOLICITED_TEXT_QUEUE_MAX_VISIBLE_ITEMS=1" \
    "UNSOLICITED_TEXT_QUEUE_EMOJI=on UNSOLICITED_TEXT_BREADCRUMB=off" \
    "UNSOLICITED_TEXT_QUEUE_EMOJI=off UNSOLICITED_TEXT_BREADCRUMB=on"
}

printed() {
  local home="$TMPDIR/$1"
  mkdir -p "$home/.unsolicited-text/state"
  : > "$home/.unsolicited-text/state/onboarded"
  shift
  printf '{"hook_event_name":"SessionStart"}' | env HOME="$home" $@ bash "$LOADER" 2>/dev/null
}

printf "Test group: whatever the settings, the rules a session reads are written English\n"

run=0
while read -r combination; do
  run=$((run + 1))
  named="${combination:-defaults}"
  said="$(printed "run$run" $combination)"

  [ -n "$said" ]
  assert "$named prints the rules" "$?" "the hook printed nothing"

  printf '%s' "$said" | grep --quiet --extended-regexp '\{[a-z-]+(=[a-z|-]+)?\}'
  [ "$?" = "1" ]
  assert "$named leaves no setting tag behind" "$?" \
    "a session reads {queue-tree=...} as part of a rule"

  # Two marks in a row, except the ellipsis a rule writes on purpose.
  printf '%s' "$said" | grep --quiet --extended-regexp '[,;:][.,;:]|\.[,;:]'
  [ "$?" = "1" ]
  assert "$named punctuates once" "$?" \
    "$(printf '%s' "$said" | grep --extended-regexp --only-matching '.{0,40}([,;:][.,;:]|\.[,;:]).{0,20}' | head -1)"

  printf '%s' "$said" | grep --quiet --extended-regexp '\b1 (items|lines|words|replies|threads)\b'
  [ "$?" = "1" ]
  assert "$named counts one thing as one" "$?" \
    "$(printf '%s' "$said" | grep --extended-regexp --only-matching '.{0,40}\b1 (items|lines|words|replies|threads)\b' | head -1)"
done < <(settings)

printf "\nTest group: and the check catches a rule that reads wrong\n"

planted="$TMPDIR/planted.md"
sed 's/A completed directive is one untagged line/A completed directive is 1 lines and ends.:/' \
  "$REPOSITORY/rules/reply-shape.md" > "$planted"

grep --quiet --extended-regexp '\b1 (items|lines|words|replies|threads)\b' "$planted"
assert "a count that does not agree is refused" "$?" "the check saw nothing wrong with it"

grep --quiet --extended-regexp '[,;:][.,;:]|\.[,;:]' "$planted"
assert "and a sentence that ends twice is too" "$?" "the check saw nothing wrong with it"

grep --quiet --extended-regexp '[,;:][.,;:]|\.[,;:]' "$REPOSITORY/rules/reply-shape.md"
[ "$?" = "1" ]
assert "while the rules as they stand pass it" "$?" "the source itself punctuates twice"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
