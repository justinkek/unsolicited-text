#!/usr/bin/env bash

UNSOLICITED_TEXT_HOME="${UNSOLICITED_TEXT_HOME:-$HOME/.unsolicited-text}"
UNSOLICITED_TEXT_SETTINGS="$UNSOLICITED_TEXT_HOME/settings"
UNSOLICITED_TEXT_STATE="$UNSOLICITED_TEXT_HOME/state"

UNSOLICITED_TEXT_PROSE_LINE_CEILING_DEFAULT=8

settings_file_value() {
  local key="$1" value
  [ -f "$UNSOLICITED_TEXT_SETTINGS" ] || return 1
  value="$(sed -n "s/^[[:space:]]*$key[[:space:]]*=[[:space:]]*//p" "$UNSOLICITED_TEXT_SETTINGS" \
    | sed 's/[[:space:]]*$//' | tail -n 1)"
  [ -n "$value" ] || return 1
  printf '%s' "$value"
}

setting_value() {
  local key="$1" default="$2" value="${!1-}"
  [ -n "$value" ] || value="$(settings_file_value "$key")"
  printf '%s' "${value:-$default}"
}

prose_line_ceiling() {
  setting_value UNSOLICITED_TEXT_PROSE_LINE_CEILING "$UNSOLICITED_TEXT_PROSE_LINE_CEILING_DEFAULT"
}

queue_visible_items() {
  local value
  value="$(setting_value UNSOLICITED_TEXT_QUEUE_MAX_VISIBLE_ITEMS "")"
  case "$value" in
    '' | *[!0-9]*) return 0 ;;
  esac
  printf '%s' "$value"
}

discard_notes_from_before_v_0_1_2() {
  local superseded="$HOME/.local/state/unsolicited-text"
  [ -d "$superseded" ] || return 0
  rm -f "$superseded/notes"/*.stop-notes
  rmdir "$superseded/notes" 2>/dev/null
  rmdir "$superseded" 2>/dev/null
  return 0
}

move_settings_from_before_v_0_1_4() {
  local superseded="$UNSOLICITED_TEXT_HOME/config"
  [ -f "$superseded" ] || return 0
  [ -f "$UNSOLICITED_TEXT_SETTINGS" ] && return 0
  mv "$superseded" "$UNSOLICITED_TEXT_SETTINGS"
  return 0
}
