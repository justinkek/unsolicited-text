#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
ADAPTER="$REPOSITORY/adapters/pi/src/index.ts"

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

printf "Test group: every script the adapter spawns is one this repository carries\n"

named="$(grep --only-matching --extended-regexp '[a-z-]+\.sh' "$ADAPTER" | sort --unique)"

[ -n "$named" ]
assert "the adapter spawns a script at all" "$?" "no script name in $ADAPTER"

while read -r script; do
  [ -n "$script" ] || continue
  [ -x "$REPOSITORY/hooks/$script" ]
  assert "the adapter spawns $script" "$?" "hooks/$script is not an executable file"
done <<< "$named"

printf "\nTest group: a session there is given the rules, once\n"

grep --quiet --fixed-strings 'load-rules.sh' "$ADAPTER"
assert "the adapter loads the rules" "$?" \
  "every other hook runs and a session there is never told the rules"

grep --quiet --extended-regexp 'started \? "" :' "$ADAPTER"
assert "and prints them once, not before every turn" "$?" \
  "the rules would be repeated in full at the top of every prompt"

printf "\nTest group: what a hook answers in JSON is read before it is shown\n"

grep --quiet --fixed-strings 'JSON.parse' "$ADAPTER"
assert "the adapter reads a JSON answer" "$?" \
  "the version notice reaches a reader there as the raw JSON the hook printed"

printf "\nTest group: the adapter reaches them through the one hooks directory\n"

grep --quiet --fixed-strings '"..", "hooks"' "$ADAPTER"
assert "the adapter resolves the hooks directory from its own file" "$?" \
  "the adapter does not build a path back to hooks/"

printf "\nTest group: the package the adapter installs with names it\n"

while read -r entry; do
  [ -n "$entry" ] || continue
  [ -f "$REPOSITORY/${entry#./}" ]
  assert "package.json names $entry" "$?" "no file there"
done < <(jq --raw-output '.pi.extensions[]' "$REPOSITORY/package.json")

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
