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

for heading in "## Response Formatting" "## Plain English" "## Pre-send checklist"; do
  printf '%s' "$printed" | grep --quiet --fixed-strings "$heading"
  assert "the loader prints $heading" "$?" "no such heading on stdout"
done

printf "\nTest group: what a session gets is not what a contributor reads\n"

printf '%s' "$printed" | grep --quiet --fixed-strings 'Working in this repository'
[ "$?" = "1" ]
assert "the loader does not print AGENTS.md" "$?" \
  "AGENTS.md is instructions for working on the plugin, and a session is paying for them"

grep --quiet --fixed-strings 'rules/reply-shape.md' "$REPOSITORY/AGENTS.md"
assert "and AGENTS.md says where the printed rules live" "$?" \
  "a reader who edits AGENTS.md expecting a session to change has no way to know better"

printf "\nTest group: no rules file, no output\n"

mkdir -p "$TMPDIR/hooks"
cp "$LOADER" "$TMPDIR/hooks/load-rules.sh"
absent="$(printf '%s' "$payload" | bash "$TMPDIR/hooks/load-rules.sh" 2>/dev/null)"
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

printf "\nTest group: the rules carry the visible limit that is set\n"

unlimited="$(printf '%s' "$payload" | env HOME="$TMPDIR/home" bash "$LOADER" 2>/dev/null)"
printf '%s' "$unlimited" | grep --quiet --fixed-strings 'Show every item of the queue'
assert "unset tells the reader to show every item" "$?" "the rules say otherwise"

limited="$(printf '%s' "$payload" | env HOME="$TMPDIR/home" \
  UNSOLICITED_TEXT_QUEUE_MAX_VISIBLE_ITEMS=2 bash "$LOADER" 2>/dev/null)"
printf '%s' "$limited" | grep --quiet --fixed-strings 'Show only the first 2 items of the queue'
assert "a limit of 2 reaches the rules as 2" "$?" "the rules do not name it"

printf '%s' "$limited" | grep --quiet --fixed-strings 'Show every item of the queue'
[ "$?" = "1" ]
assert "and the unlimited rule is gone when one is set" "$?" "both rules are printed"

printf "\nTest group: no rule reaches a session still carrying its tag\n"

for shown in "$unlimited" "$limited"; do
  printf '%s' "$shown" | grep --quiet --extended-regexp '\{(breadcrumb|queue-limit|queue-tree)=?[a-z|-]*\}'
  [ "$?" = "1" ]
  assert "the tags are stripped or the line is dropped" "$?" \
    "a session was handed a rule with the setting that keeps it still written on the end"
done

printf "\nTest group: the queue is a tree only when it is asked for\n"

shape_of() {
  printf '%s' "$payload" | env HOME="$TMPDIR/home" \
    ${1:+UNSOLICITED_TEXT_QUEUE_TREE="$1"} bash "$LOADER" 2>/dev/null
}

for shape in "" on-switch-only; do
  printf '%s' "$(shape_of "$shape")" | grep --quiet --fixed-strings 'Draw the queue as a list, and as a tree in the one reply'
  assert "${shape:-unset} draws a list until a switch is raised" "$?" "the rules say otherwise"

  printf '%s' "$(shape_of "$shape")" | grep --quiet --fixed-strings 'The tree is drawn inside a fenced block'
  assert "${shape:-unset} carries the drawing it switches to" "$?" "the tree has no description to follow"

  printf '%s' "$(shape_of "$shape")" | grep --quiet --fixed-strings 'Show every item of the queue'
  assert "${shape:-unset} keeps the list rule" "$?" "the shape it goes back to is undescribed"
done

printf '%s' "$(shape_of off)" | grep --quiet --extended-regexp 'queue as a tree|tree is drawn'
[ "$?" = "1" ]
assert "off never mentions a tree" "$?" "a session is told about one it will not draw"

printf '%s' "$(shape_of always-on)" | grep --quiet --fixed-strings 'Draw the queue as a tree in every reply'
assert "always-on draws it every reply" "$?" "the rules do not say so"

printf '%s' "$(shape_of always-on)" | grep --quiet --fixed-strings 'Show every item of the queue'
[ "$?" = "1" ]
assert "and the list rule is gone when it is always on" "$?" "a session is told to draw both"

printf "\nTest group: a rule that goes takes the example written under it\n"

for shape in always-on on-switch-only; do
  printf '%s' "$(shape_of "$shape")" | grep --quiet --fixed-strings '├── queue marks (3 pending)'
  assert "$shape shows the drawing it asks for" "$?" "the tree is described and never shown"
done

printf '%s' "$(shape_of off)" | grep --quiet --extended-regexp '├──|└──|@@drop@@'
[ "$?" = "1" ]
assert "off carries neither the example nor the mark that dropped it" "$?" \
  "a session is handed rows of a drawing it will not draw"

printf '%s' "$(shape_of off)" | grep --quiet --extended-regexp '^  1\. (❓ )?Question: \.\.\.\?$'
assert "and the example under an untagged rule stays" "$?" "the queue has no layout to follow"

printf "\nTest group: the first session on a machine starts with two queue items\n"

fresh="$TMPDIR/fresh"
first="$(printf '%s' "$payload" | env HOME="$fresh" bash "$LOADER" 2>/dev/null)"
second="$(printf '%s' "$payload" | env HOME="$fresh" bash "$LOADER" 2>/dev/null)"

printf '%s' "$first" | grep --quiet --fixed-strings 'try the settings skill'
assert "the first run seeds the settings item" "$?" "a new install is told nothing"

printf '%s' "$first" | grep --quiet --fixed-strings 'try the update skill'
assert "and the update item" "$?" "a new install cannot find the update skill"

printf '%s' "$second" | grep --quiet --fixed-strings 'try the settings skill'
[ "$?" = "1" ]
assert "the run after it seeds nothing" "$?" "every session pays for the demo"

opted_out="$(printf '%s' "$payload" | env HOME="$TMPDIR/opted-out" \
  UNSOLICITED_TEXT_ONBOARDING=off bash "$LOADER" 2>/dev/null)"
printf '%s' "$opted_out" | grep --quiet --fixed-strings 'try the settings skill'
[ "$?" = "1" ]
assert "off seeds nothing at all" "$?" "the setting does not hold"

printf "\nTest group: the breadcrumb is written only when it is asked for\n"

off="$(printf '%s' "$payload" | env HOME="$TMPDIR/home" bash "$LOADER" 2>/dev/null)"
printf '%s' "$off" | grep --quiet --fixed-strings 'Do not write a breadcrumb.'
assert "unset tells the reader to write none" "$?" "the rules ask for one by default"

on="$(printf '%s' "$payload" | env HOME="$TMPDIR/home" \
  UNSOLICITED_TEXT_BREADCRUMB=on bash "$LOADER" 2>/dev/null)"
printf '%s' "$on" | grep --quiet --fixed-strings 'Open every reply with the thread you are on'
assert "on asks for one" "$?" "the rules do not describe it"

printf '%s' "$on" | grep --quiet --fixed-strings 'Do not write a breadcrumb.'
[ "$?" = "1" ]
assert "and the refusal is gone when it is on" "$?" "both rules are printed"

printf "\nTest group: the emoji are handed over only when they are asked for\n"

emoji_in() {
  python3 -c '
import sys, unicodedata
print("".join(sorted({c for c in open(sys.argv[1]).read() if unicodedata.east_asian_width(c) == "W"})))' "$1"
}

written="$(emoji_in "$REPOSITORY/rules/reply-shape.md")"
[ -n "$written" ]
assert "the rules on disk carry emoji at all" "$?" "rules/reply-shape.md has none, so there is nothing to strip"

printed="$TMPDIR/printed"
printf '%s' "$payload" | env HOME="$TMPDIR/home" bash "$LOADER" > "$printed" 2>/dev/null
[ -z "$(emoji_in "$printed")" ]
assert "none of them reaches a session by default" "$?" "the rules printed $(emoji_in "$printed")"

printf '%s' "$payload" | env HOME="$TMPDIR/home" UNSOLICITED_TEXT_QUEUE_EMOJI=on bash "$LOADER" > "$printed" 2>/dev/null
[ "$(emoji_in "$printed")" = "$written" ]
assert "and every one of them does when it is on" "$?" \
  "rules/reply-shape.md has $written and the session got $(emoji_in "$printed")"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
