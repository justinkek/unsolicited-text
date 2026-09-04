#!/usr/bin/env bash

cat >/dev/null

. "$(dirname "$0")/hook-settings-lib.sh"

notice="$UNSOLICITED_TEXT_STATE/new-version"
checked="$UNSOLICITED_TEXT_STATE/version-checked"

if [ -f "$notice" ]; then
  cat "$notice"
  rm -f "$notice"
fi

[ "$(setting_value UNSOLICITED_TEXT_UPDATE_CHECK on)" = "on" ] || exit 0
command -v curl >/dev/null 2>&1 || exit 0

interval="$(setting_value UNSOLICITED_TEXT_UPDATE_CHECK_INTERVAL 86400)"
now="$(date +%s)"
[ -f "$checked" ] && [ "$((now - $(cat "$checked")))" -lt "$interval" ] && exit 0

installed="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  "$(dirname "$0")/../package.json" | head -1)"
[ -n "$installed" ] || exit 0

published="$(setting_value UNSOLICITED_TEXT_VERSION_SOURCE \
  https://raw.githubusercontent.com/justinkek/unsolicited-text/main/package.json)"

mkdir -p "$UNSOLICITED_TEXT_STATE"
printf '%s' "$now" > "$checked"

(
  latest="$(curl --silent --fail --max-time 5 "$published" 2>/dev/null \
    | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$latest" ] || exit 0
  [ "$latest" = "$installed" ] && exit 0
  [ "$(printf '%s\n%s\n' "$installed" "$latest" | sort --version-sort | tail -1)" = "$latest" ] || exit 0
  printf '[unsolicited-text] version %s is now available (current: %s). Update with unsolicited-text:update\nTo stop being told, use unsolicited-text:settings\n' \
    "$latest" "$installed" > "$notice"
) >/dev/null 2>&1 &

exit 0
