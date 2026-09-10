#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
README="$REPOSITORY/README.md"
LOGO="$REPOSITORY/logo"

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

printf "Test group: the readme shows a logo rendered from the drawing on disk\n"

[ -f "$LOGO/logo.png" ]
assert "logo.png is rendered" "$?" "run logo/render"

[ -f "$LOGO/rendered.sha" ]
assert "rendered.sha names what it was rendered from" "$?" "run logo/render"

grep --quiet --fixed-strings "$(git -C "$LOGO" hash-object logo.svg)  logo.svg" "$LOGO/rendered.sha" 2>/dev/null
assert "logo.png was rendered from the logo.svg on disk" "$?" \
  "the drawing changed since it was rendered, run logo/render"

grep --quiet --fixed-strings 'logo/logo.png' "$README"
assert "the readme shows it" "$?" "no such image in $README"

printf "\nTest group: the drawing carries no text a reader has to have the face for\n"

grep --quiet --extended-regexp '<text[^>]*>' "$LOGO/logo.svg"
assert "the wordmark is text in the source" "$?" "no text element in logo.svg"

grep --quiet --fixed-strings 'src="logo/logo.svg"' "$README"
[ "$?" = "1" ]
assert "and the readme shows the rendering rather than the source" "$?" \
  "$README shows the svg, whose wordmark falls back to whatever face a reader has"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
