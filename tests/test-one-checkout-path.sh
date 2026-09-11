#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
ADAPTER="$REPOSITORY/harness-adapters/claude-code"

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

printf "Test group: the install script names the checkout once and for all\n"

cloned="$(sed -n 's/^[[:space:]]*mv [^ ]*\.new \(\/opt\/[A-Za-z0-9._-]*\)$/\1/p' \
  "$REPOSITORY/INSTALL.md" | head -1)"

[ -n "$cloned" ]
assert "the install script says where it clones to" "$?" \
  "nothing in INSTALL.md moves a clone into place, so there is no path to hold the rest to"

printf "the checkout is %s\n\n" "$cloned"

named="$(git -C "$REPOSITORY" ls-files '*.md' '*.sh' '*.json' \
  | xargs -I {} grep --only-matching --extended-regexp '/opt/[A-Za-z0-9._-]+' "$REPOSITORY/{}" \
  | sed 's/\.new$//' | sort --unique)"

[ "$named" = "$cloned" ]
assert "every file naming a path under /opt names that one" "$?" \
  "they name $(printf '%s' "$named" | tr '\n' ' '), and an install writes to one of them while the rest point elsewhere"

printf "\nTest group: the pieces that have to agree on it do\n"

stated="$(sed -n 's/^stated=\(.*\)$/\1/p' "$ADAPTER/merge-settings.sh")"
[ "$stated" = "$cloned" ]
assert "merge-settings.sh rewrites away the path the install clones to" "$?" \
  "it rewrites $stated, so a registration written from another checkout is never recognised as this plugin's"

outside="$(jq --raw-output --arg checkout "$cloned/" \
  '.hooks | to_entries[] | .value[] | .hooks[] | .command | select(startswith($checkout) | not)' \
  "$ADAPTER/cloud-settings.json")"
[ -z "$outside" ]
assert "every registration names a command inside it" "$?" \
  "$(printf '%s' "$outside" | tr '\n' ' ')sits outside the checkout, and nothing is there to run"

grep --quiet --fixed-strings "$cloned/harness-adapters/claude-code/install-cloud.sh" "$REPOSITORY/INSTALL.md"
assert "and the install script runs the install from it" "$?" \
  "it clones to one place and installs from another"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
