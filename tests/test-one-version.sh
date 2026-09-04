#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"

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

printf "Test group: every manifest states the same version\n"

declared="$(jq --raw-output '.version' "$REPOSITORY/.claude-plugin/plugin.json")"

for manifest in .codex-plugin/plugin.json package.json; do
  stated="$(jq --raw-output '.version' "$REPOSITORY/$manifest")"
  [ "$stated" = "$declared" ]
  assert "$manifest states $declared" "$?" \
    "it states $stated, and an install caches by version, so the two disagree about what a reader is running"
done

printf "\nTest group: every manifest carries the same description\n"

said="$(jq --raw-output '.description' "$REPOSITORY/.claude-plugin/plugin.json")"

for manifest in .codex-plugin/plugin.json package.json .claude-plugin/marketplace.json; do
  stated="$(jq --raw-output '.description' "$REPOSITORY/$manifest")"
  [ "$stated" = "$said" ]
  assert "$manifest says \"$said\"" "$?" "it says \"$stated\""
done

for manifest in .codex-plugin/plugin.json .agents/plugins/marketplace.json; do
  stated="$(jq --raw-output '.interface.shortDescription' "$REPOSITORY/$manifest")"
  [ "$stated" = "$said" ]
  assert "$manifest shows the same to a browsing user" "$?" "it shows \"$stated\""
done

stated="$(jq --raw-output '.plugins[0].description' "$REPOSITORY/.claude-plugin/marketplace.json")"
[ "$stated" = "$said" ]
assert "and so does the marketplace listing" "$?" "it says \"$stated\""

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
