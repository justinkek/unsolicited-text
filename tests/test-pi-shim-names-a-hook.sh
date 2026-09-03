#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
SHIM="$REPOSITORY/harness-adapters/pi/src/index.ts"

pass=0
fail=0

assert() {
  local label="$1" outcome="$2" detail="$3"
  if [ "$outcome" = "0" ]; then
    printf "  OK  %s\n" "$label"
    pass=$((pass + 1))
  else
    printf "  KO  %s — %s\n" "$label" "$detail"
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

printf "\nTest group: the shim reaches them through the one hooks directory\n"

grep --quiet --fixed-strings '"..", "..", "..", "hooks"' "$SHIM"
assert "the shim resolves the hooks directory from its own file" "$?" \
  "the shim does not build a path back to hooks/"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
