#!/usr/bin/env bash

UNSOLICITED_TEXT_HOME="${UNSOLICITED_TEXT_HOME:-$HOME/.unsolicited-text}"
UNSOLICITED_TEXT_CONFIG="$UNSOLICITED_TEXT_HOME/config"
UNSOLICITED_TEXT_STATE="$UNSOLICITED_TEXT_HOME/state"

PROSE_LINE_CEILING_DEFAULT=8

config_file_value() {
  local key="$1" value
  [ -f "$UNSOLICITED_TEXT_CONFIG" ] || return 1
  value="$(sed -n "s/^[[:space:]]*$key[[:space:]]*=[[:space:]]*//p" "$UNSOLICITED_TEXT_CONFIG" \
    | sed 's/[[:space:]]*$//' | tail -n 1)"
  [ -n "$value" ] || return 1
  printf '%s' "$value"
}

# The environment wins, then the config file, then the default the caller names.
config_value() {
  local key="$1" default="$2" value="${!1-}"
  [ -n "$value" ] || value="$(config_file_value "$key")"
  printf '%s' "${value:-$default}"
}

prose_line_ceiling() {
  config_value PROSE_LINE_CEILING "$PROSE_LINE_CEILING_DEFAULT"
}
