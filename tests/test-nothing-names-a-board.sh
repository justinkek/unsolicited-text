#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
SELF="tests/$(basename "$0")"

pass=0
fail=0

WORDS='ticket|epic|sprint|cockpit|board'
ABBREVIATIONS='BR|TR|CR'

report() {
  local label="$1" hits="$2"
  if [ -z "$hits" ]; then
    printf "  OK  %s\n" "$label"
    pass=$((pass + 1))
  else
    printf "  KO  %s\n" "$label"
    printf '%s\n' "$hits" | sed 's/^/        /'
    fail=$((fail + 1))
  fi
}

tracked() { git -C "$REPOSITORY" ls-files --cached --others --exclude-standard | grep --invert-match --line-regexp --fixed-strings "$SELF"; }

printf "Test group: nothing here knows a ticket board exists\n"

report "no file names one of: $WORDS" \
  "$(tracked | xargs grep --line-number --ignore-case --extended-regexp "\b($WORDS)\b" 2>/dev/null)"

report "no file names one of: $ABBREVIATIONS" \
  "$(tracked | xargs grep --line-number --extended-regexp "\b($ABBREVIATIONS)\b" 2>/dev/null)"

report "no file name holds one of them" \
  "$(tracked | grep --ignore-case --extended-regexp "($WORDS)")"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
