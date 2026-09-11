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
    printf "  FAIL  %s — %s\n" "$label" "$detail"
    fail=$((fail + 1))
  fi
}

marker='^\(audience: (humans|agents)\)'

printf "Test group: every page opens by saying who it is for\n"

for page in $(git -C "$REPOSITORY" ls-files '*.md' | grep -v /); do
  first="$(grep --extended-regexp --only-matching "$marker" "$REPOSITORY/$page" | head -1)"
  [ -n "$first" ]
  assert "$page says who it is for" "$?" \
    "a reader cannot tell whether the instructions are theirs to follow or an agent's"

  named="$(grep --extended-regexp --line-number --only-matching "$marker" "$REPOSITORY/$page" \
    | head -1 | cut -d: -f1)"
  heading="$(grep --line-number --extended-regexp '^(# |<h[12])' "$REPOSITORY/$page" | head -1 | cut -d: -f1)"
  [ -n "$named" ] && [ -n "$heading" ] && [ "$named" -gt "$heading" ] && [ "$named" -lt "$((heading + 4))" ]
  assert "and says it under the heading, not further down" "$?" \
    "it is at line $named, with the heading at line $heading, so a reader meets the page before its audience"
done

printf "\nTest group: nothing marks an audience that is not one of the two\n"

wrong="$(git -C "$REPOSITORY" ls-files '*.md' \
  | xargs -I {} grep --only-matching --extended-regexp '\(audience: [a-z]+\)' "$REPOSITORY/{}" \
  | sort --unique | grep --extended-regexp --invert-match '\(audience: (humans|agents)\)')"
[ -z "$wrong" ]
assert "every mark reads humans or agents" "$?" \
  "$(printf '%s' "$wrong" | tr '\n' ' ')is neither, so nothing can be held to it"

printf "\nTest group: a page whose audience changes says where\n"

for page in INSTALL.md UPDATE.md; do
  grep --quiet --fixed-strings '(audience: agents)' "$REPOSITORY/$page"
  assert "$page marks the paragraph written for an agent" "$?" \
    "it is written for a reader and holds a paragraph only an agent acts on, with nothing saying so"
done

printf "\nTest group: the rules a session is handed carry no mark\n"

grep --quiet --fixed-strings '(audience:' "$REPOSITORY/rules/reply-shape.md"
outcome="$?"
[ "$outcome" != "0" ]
assert "rules/reply-shape.md is unmarked" "$?" \
  "the hook prints it into a session, so the mark would be printed with it"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
