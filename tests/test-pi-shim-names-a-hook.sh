#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
SHIM="$REPOSITORY/harness-adapters/pi/src/index.ts"

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

printf "Test group: every script the shim spawns is one this repository carries\n"

named="$(grep --only-matching --extended-regexp '[a-z-]+\.sh' "$SHIM" | sort --unique)"

[ -n "$named" ]
assert "the shim spawns a script at all" "$?" "no script name in $SHIM"

while read -r script; do
  [ -n "$script" ] || continue
  [ -x "$REPOSITORY/hooks/$script" ]
  assert "the shim spawns $script" "$?" "hooks/$script is not an executable file"
done <<< "$named"

printf "\nTest group: a session there is given the rules, once\n"

grep --quiet --fixed-strings 'load-rules.sh' "$SHIM"
assert "the shim loads the rules" "$?" \
  "every other hook runs and a session there is never told the rules"

grep --quiet --extended-regexp 'started \? "" :' "$SHIM"
assert "and prints them once, not before every turn" "$?" \
  "the rules would be repeated in full at the top of every prompt"

printf "\nTest group: what a hook answers in JSON is read before it is shown\n"

grep --quiet --fixed-strings 'JSON.parse' "$SHIM"
assert "the shim reads a JSON answer" "$?" \
  "the version notice reaches a reader there as the raw JSON the hook printed"

printf "\nTest group: the shim reaches them through the one hooks directory\n"

grep --quiet --fixed-strings '"..", "hooks"' "$SHIM"
assert "the shim resolves the hooks directory from its own file" "$?" \
  "the shim does not build a path back to hooks/"

printf "\nTest group: the package the shim installs with names it\n"

while read -r entry; do
  [ -n "$entry" ] || continue
  [ -f "$REPOSITORY/${entry#./}" ]
  assert "package.json names $entry" "$?" "no file there"
done < <(jq --raw-output '.pi.extensions[]' "$REPOSITORY/package.json")

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
