#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
HOOKS_DIR="$REPOSITORY/hooks"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

pass=0
fail=0

assert_equal() {
  local label="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then
    printf "  OK  %s\n" "$label"
    pass=$((pass + 1))
  else
    printf "  KO  %s — expected '%s', got '%s'\n" "$label" "$want" "$got"
    fail=$((fail + 1))
  fi
}

read_setting() {
  (
    unset UNSOLICITED_TEXT_PROSE_LINE_CEILING UNSOLICITED_TEXT_STOP_NOTE_DIRECTORY
    env "$@" bash -c '. "$0"/hook-settings-lib.sh; setting_value "$1" "$2"' "$HOOKS_DIR" "$SETTING" "$DEFAULT"
  )
}

printf "Test group: no config file, and the default stands\n"

SETTING=UNSOLICITED_TEXT_PROSE_LINE_CEILING DEFAULT=8
assert_equal "an unwritten setting falls back" \
  "$(HOME="$TMPDIR/empty" read_setting)" "8"

printf "\nTest group: the config file under the plugin's own home\n"

mkdir -p "$TMPDIR/home/.unsolicited-text"
SETTINGS="$TMPDIR/home/.unsolicited-text/settings"
cat > "$SETTINGS" <<'CONF'
# the shape of a reply
UNSOLICITED_TEXT_PROSE_LINE_CEILING = 12
CONF

assert_equal "a value in ~/.unsolicited-text/settings is read" \
  "$(HOME="$TMPDIR/home" read_setting)" "12"

assert_equal "the environment wins over the file" \
  "$(HOME="$TMPDIR/home" read_setting UNSOLICITED_TEXT_PROSE_LINE_CEILING=3)" "3"

printf '%s\n' "#UNSOLICITED_TEXT_PROSE_LINE_CEILING=99" > "$SETTINGS"
assert_equal "a commented-out setting is not a setting" \
  "$(HOME="$TMPDIR/home" read_setting)" "8"

printf '\n\n   \n' > "$SETTINGS"
assert_equal "blank lines leave the default alone" \
  "$(HOME="$TMPDIR/home" read_setting)" "8"

printf 'UNSOLICITED_TEXT_PROSE_LINE_CEILING=4\nUNSOLICITED_TEXT_PROSE_LINE_CEILING=6\n' > "$SETTINGS"
assert_equal "the last assignment is the one that counts" \
  "$(HOME="$TMPDIR/home" read_setting)" "6"

printf "\nTest group: state sits under the same home, and moves with it\n"

SETTING=UNSOLICITED_TEXT_STOP_NOTE_DIRECTORY DEFAULT=""
assert_equal "notes default to the state directory" \
  "$(HOME="$TMPDIR/home" bash -c '. "$0"/hook-settings-lib.sh; printf "%s" "$UNSOLICITED_TEXT_STATE"' "$HOOKS_DIR")" \
  "$TMPDIR/home/.unsolicited-text/state"

assert_equal "UNSOLICITED_TEXT_HOME moves the whole tree" \
  "$(HOME="$TMPDIR/home" UNSOLICITED_TEXT_HOME="$TMPDIR/elsewhere" \
    bash -c '. "$0"/hook-settings-lib.sh; printf "%s" "$UNSOLICITED_TEXT_STATE"' "$HOOKS_DIR")" \
  "$TMPDIR/elsewhere/state"

printf "\nTest group: the ceiling a hook enforces is the ceiling configured\n"

transcript="$TMPDIR/transcript.jsonl"
jq --null-input --compact-output --arg t "$(seq 1 5 | sed 's/^/point /')" \
  '{type:"assistant",message:{content:[{type:"text",text:$t}]}}' > "$transcript"
payload="$(jq --null-input --compact-output --arg p "$transcript" \
  '{hook_event_name:"Stop",session_id:"test-config",transcript_path:$p}')"

run_with_ceiling() {
  local notes="$TMPDIR/notes-$1"
  rm -rf "$notes"
  printf '%s\n' "UNSOLICITED_TEXT_PROSE_LINE_CEILING=$1" > "$SETTINGS"
  (
    unset UNSOLICITED_TEXT_PROSE_LINE_CEILING
    printf '%s' "$payload" \
      | env HOME="$TMPDIR/home" UNSOLICITED_TEXT_STOP_NOTE_DIRECTORY="$notes" \
        bash "$HOOKS_DIR/note-long-reply.sh" >/dev/null 2>&1
  )
  [ -f "$notes/test-config.stop-notes" ] && printf 'recorded' || printf 'silent'
}

assert_equal "five lines against a ceiling of 3 is a note" "$(run_with_ceiling 3)" "recorded"
assert_equal "the note names the configured ceiling" \
  "$(grep --count 'ceiling of 3' "$TMPDIR/notes-3/test-config.stop-notes")" "1"
assert_equal "five lines against a ceiling of 20 is silence" "$(run_with_ceiling 20)" "silent"

printf "\nTest group: every setting carries the plugin's own prefix\n"

unprefixed="$(grep --recursive --only-matching 'setting_value [A-Z_][A-Z_]*' "$HOOKS_DIR" \
  | grep --invert-match 'setting_value UNSOLICITED_TEXT_')"
assert_equal "no setting is read under a bare name" "$unprefixed" ""

printf "\nTest group: the rules reach the session carrying that same ceiling\n"

printf '%s\n' "UNSOLICITED_TEXT_PROSE_LINE_CEILING=12" > "$SETTINGS"
start_payload="$(jq --null-input --compact-output \
  '{hook_event_name:"SessionStart",session_id:"test-config",source:"startup"}')"
printed="$(
  unset UNSOLICITED_TEXT_PROSE_LINE_CEILING
  printf '%s' "$start_payload" \
    | env HOME="$TMPDIR/home" bash "$HOOKS_DIR/load-agents-md.sh" 2>/dev/null
)"

assert_equal "the printed rules state the configured ceiling" \
  "$(printf '%s' "$printed" | grep --count --fixed-strings 'at most 12 non-blank lines of prose')" "1"
assert_equal "and no longer state the default" \
  "$(printf '%s' "$printed" | grep --count --fixed-strings 'at most 8 non-blank lines of prose')" "0"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
