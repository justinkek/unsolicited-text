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

printf "Test group: every manifest states the same version\n"

declared="$(jq --raw-output '.version' "$REPOSITORY/package.json")"

for manifest in dist/claude-code/.claude-plugin/plugin.json dist/codex/.codex-plugin/plugin.json; do
  stated="$(jq --raw-output '.version' "$REPOSITORY/$manifest")"
  [ "$stated" = "$declared" ]
  assert "$manifest states $declared" "$?" \
    "it states $stated, and an install caches by version, so the two disagree about what a reader is running"
done

grep --quiet --fixed-strings "unsolicited-text $declared" "$REPOSITORY/skills/reload/SKILL.md"
assert "the reload skill was rendered from $declared" "$?" \
  "it names another version, and a session with no checkout would report that one - run skills/reload/render"

printf "\nTest group: every manifest carries the same description\n"

said="$(jq --raw-output '.description' "$REPOSITORY/package.json")"

for manifest in dist/claude-code/.claude-plugin/plugin.json dist/codex/.codex-plugin/plugin.json .claude-plugin/marketplace.json; do
  stated="$(jq --raw-output '.description' "$REPOSITORY/$manifest")"
  [ "$stated" = "$said" ]
  assert "$manifest says \"$said\"" "$?" "it says \"$stated\""
done

for manifest in dist/codex/.codex-plugin/plugin.json .agents/plugins/marketplace.json; do
  stated="$(jq --raw-output '.interface.shortDescription' "$REPOSITORY/$manifest")"
  [ "$stated" = "$said" ]
  assert "$manifest shows the same to a browsing user" "$?" "it shows \"$stated\""
done

stated="$(jq --raw-output '.plugins[0].description' "$REPOSITORY/.claude-plugin/marketplace.json")"
[ "$stated" = "$said" ]
assert "and so does the marketplace listing" "$?" "it says \"$stated\""

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
