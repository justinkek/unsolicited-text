#!/usr/bin/env bash

STOP_NOTE_DIRECTORY="${STOP_NOTE_DIRECTORY:-$HOME/.local/state/unsolicited-text/notes}"

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
