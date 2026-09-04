#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"

pass=0
fail=0

HARNESSES='claude|codex|zcode|pi'

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

printf "Test group: what every harness shares names none of them\n"

report "no hook script names one of: $HARNESSES" \
  "$(grep --line-number --ignore-case --extended-regexp "\b($HARNESSES)\b" "$REPOSITORY"/hooks/*.sh)"

report "the rules name none of them either" \
  "$(grep --line-number --ignore-case --extended-regexp "\b($HARNESSES)\b" "$REPOSITORY/AGENTS.md")"

printf "\nTest group: only the skill whose subject is the difference may name one\n"

report "no other skill names one" \
  "$(find "$REPOSITORY/skills" -name SKILL.md -not -path '*/update/*' -print0 \
    | xargs -0 grep --line-number --ignore-case --extended-regexp "\b($HARNESSES)\b")"

named=0
while read -r harness; do
  grep --quiet --ignore-case --fixed-strings "$harness" "$REPOSITORY/skills/update/SKILL.md" && named=$((named + 1))
done < <(printf '%s\n' claude codex pi)
[ "$named" -eq 3 ]
if [ "$?" = "0" ]; then
  printf "  OK  and the one that may, names all three\n"
  pass=$((pass + 1))
else
  printf "  KO  skills/update names %s of the three harnesses\n" "$named"
  fail=$((fail + 1))
fi

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
