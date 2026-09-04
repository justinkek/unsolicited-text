#!/usr/bin/env bash

. "$(dirname "${BASH_SOURCE[0]}")/hook-config-lib.sh"

STOP_NOTE_DIRECTORY="$(config_value STOP_NOTE_DIRECTORY "$UNSOLICITED_TEXT_STATE/notes")"

stop_note_record() {
  local session_id="$1" note="$2" notes_file
  [ -n "$session_id" ] && [ -n "$note" ] || return 0
  notes_file="$STOP_NOTE_DIRECTORY/$session_id.stop-notes"
  mkdir -p "$STOP_NOTE_DIRECTORY"
  printf '%s\n' "$note" >> "$notes_file"
}

stop_note_take() {
  local session_id="$1" notes_file
  notes_file="$STOP_NOTE_DIRECTORY/$session_id.stop-notes"
  [ -f "$notes_file" ] || return 0
  cat "$notes_file"
  rm -f "$notes_file"
}
