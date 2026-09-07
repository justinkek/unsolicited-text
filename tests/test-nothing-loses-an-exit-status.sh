#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"

pass=0
fail=0

# Bash expands arguments left to right, so a command substitution standing
# before "$?" runs first and leaves its own status there. The assertion then
# reads 0 whatever it was measuring, and can never fail.
lost_status_in() {
  awk '
    { joined = joined $0 }
    joined ~ /\\$/ { sub(/\\$/, "", joined); next }
    {
      at = index(joined, "\"$?\"")
      if (at > 0 && index(substr(joined, 1, at), "$(")) printf "%s:%d: %s\n", FILENAME, NR, joined
      joined = ""
    }
  ' "$1"
}

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

printf "Test group: no exit status is read after something else has overwritten it\n"

found=""
while read -r script; do
  found="$found$(lost_status_in "$REPOSITORY/$script")"
done < <(git -C "$REPOSITORY" ls-files '*.sh' 'demo/record' 'demo/type' 'logo/render' 'tests/run-tests')

report "no shell file reads a status a substitution already replaced" "$found"

printf "\nTest group: and the check catches one when it is there\n"

planted="$(mktemp)"
trap 'rm -f "$planted"' EXIT
printf '%s\n' '#!/usr/bin/env bash' '[ 1 -eq 2 ]' 'assert "$(basename x) is fine" "$?" "detail"' > "$planted"
[ -n "$(lost_status_in "$planted")" ]
outcome="$?"
if [ "$outcome" = "0" ]; then
  printf "  OK  a planted one is refused\n"
  pass=$((pass + 1))
else
  printf "  KO  a planted one is refused — the check saw nothing wrong with it\n"
  fail=$((fail + 1))
fi

printf '%s\n' '#!/usr/bin/env bash' '[ 1 -eq 2 ]' 'assert "label" "$?" "detail $(basename x)"' > "$planted"
[ -z "$(lost_status_in "$planted")" ]
outcome="$?"
if [ "$outcome" = "0" ]; then
  printf "  OK  and a substitution standing after it is left alone\n"
  pass=$((pass + 1))
else
  printf "  KO  and a substitution standing after it is left alone — it was refused too\n"
  fail=$((fail + 1))
fi

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
