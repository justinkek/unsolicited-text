#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"

pass=0
fail=0

assert() {
  local label="$1" outcome="$2" detail="$3"
  if [ "$outcome" = "0" ]; then
    printf "  PASS  %s\n" "$label"
    pass=$((pass + 1))
  else
    printf "  FAIL  %s - %s\n" "$label" "$detail"
    fail=$((fail + 1))
  fi
}

# A support page says what was checked on a client and when. How many hooks,
# skills or commands there are changes without anyone opening that client, so a
# page naming a number goes stale while still reading as verified. The
# generated pages count them from the manifest; these do not count at all.
COUNTED='\b(one|two|three|four|five|six|seven|eight|nine|ten|[0-9]+) (hook|command|skill)'

printf "Test group: a support page names no count of hooks, skills or commands\n"

pages=0
for page in "$REPOSITORY"/clients/*/support.md; do
  [ -f "$page" ] || continue
  pages=$((pages + 1))
  client="$(basename "$(dirname "$page")")"
  said="$(grep --ignore-case --extended-regexp "$COUNTED" "$page" || true)"
  [ -z "$said" ]
  assert "$client counts nothing" "$?" "it says: $said"
done

[ "$pages" -gt 0 ]
assert "there were pages to check" "$?" "the group above checked nothing"

printf "\nTest group: and the check catches one when it is there\n"

planted="$(mktemp)"
trap 'rm -f "$planted"' EXIT
printf 'Last verified: the seven commands were trusted.\n' > "$planted"
grep --quiet --ignore-case --extended-regexp "$COUNTED" "$planted"
assert "a planted count is found" "$?" "the check would miss a number that drifts"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
