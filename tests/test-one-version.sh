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

declared="$(jq --raw-output '.version' "$REPOSITORY/plugin.json")"

# The build reads plugin.json. package.json stays for the Pi extension pointer
# and for the update check, which fetches it from the repository, so the two
# have to agree or a session is told a version nothing else is running.
[ "$(jq --raw-output '.version' "$REPOSITORY/package.json")" = "$declared" ]
assert "package.json states the same version as plugin.json" "$?" \
  "the update check fetches package.json and the build reads plugin.json"

[ "$(jq --raw-output '.description' "$REPOSITORY/package.json")" \
  = "$(jq --raw-output '.description' "$REPOSITORY/plugin.json")" ]
assert "and the same description" "$?" "the two manifests describe the plugin differently"

for manifest in distributions/claude/.claude-plugin/plugin.json distributions/codex/.codex-plugin/plugin.json; do
  stated="$(jq --raw-output '.version' "$REPOSITORY/$manifest")"
  [ "$stated" = "$declared" ]
  assert "$manifest states $declared" "$?" \
    "it states $stated, and an install caches by version, so the two disagree about what a reader is running"
done

for skill in "$REPOSITORY"/distributions/*/skills/*/SKILL.md; do
  grep --quiet --fixed-strings "unsolicited-text $declared" "$skill"
  assert "${skill#$REPOSITORY/} was rendered from $declared" "$?" \
    "it names another version, and a session asked which one is installed would report that one - run ./build"
done

printf "\nTest group: every manifest carries the same description\n"

said="$(jq --raw-output '.description' "$REPOSITORY/package.json")"

for manifest in distributions/claude/.claude-plugin/plugin.json distributions/codex/.codex-plugin/plugin.json .claude-plugin/marketplace.json; do
  stated="$(jq --raw-output '.description' "$REPOSITORY/$manifest")"
  [ "$stated" = "$said" ]
  assert "$manifest says \"$said\"" "$?" "it says \"$stated\""
done

for manifest in distributions/codex/.codex-plugin/plugin.json .agents/plugins/marketplace.json; do
  stated="$(jq --raw-output '.interface.shortDescription' "$REPOSITORY/$manifest")"
  [ "$stated" = "$said" ]
  assert "$manifest shows the same to a browsing user" "$?" "it shows \"$stated\""
done

stated="$(jq --raw-output '.plugins[0].description' "$REPOSITORY/.claude-plugin/marketplace.json")"
[ "$stated" = "$said" ]
assert "and so does the marketplace listing" "$?" "it says \"$stated\""

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
