#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
ADAPTERS="$REPOSITORY/harness-adapters"

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

commands_of() {
  jq --raw-output '.hooks | to_entries[] | .value[] | .hooks[] | .command' "$1"
}

printf "Test group: every manifest is readable JSON\n"

for manifest in \
  "$ADAPTERS/claude-code/.claude-plugin/marketplace.json" \
  "$ADAPTERS/claude-code/plugins/unsolicited-text/.claude-plugin/plugin.json" \
  "$ADAPTERS/claude-code/plugins/unsolicited-text/hooks/hooks.json" \
  "$ADAPTERS/codex/.agents/plugins/marketplace.json" \
  "$ADAPTERS/codex/plugins/unsolicited-text/.codex-plugin/plugin.json" \
  "$ADAPTERS/codex/plugins/unsolicited-text/hooks/hooks.json" \
  "$ADAPTERS/pi/package.json"
do
  jq --exit-status . "$manifest" >/dev/null 2>&1
  assert "${manifest#$REPOSITORY/} parses" "$?" "not readable as JSON"
done

printf "\nTest group: every command a manifest names is a script this repository carries\n"

check_reachable() {
  local manifest="$1" root="$2" variable="$3" command resolved adapter
  adapter="${manifest#$ADAPTERS/}"
  adapter="${adapter%%/*}"
  while read -r command; do
    [ -n "$command" ] || continue
    resolved="${command/\$\{$variable\}/$root}"
    [ -x "$resolved" ]
    assert "$adapter reaches $(basename "$resolved")" "$?" "$command is not an executable file"
  done < <(commands_of "$manifest")
}

CLAUDE_CODE_PLUGIN="$ADAPTERS/claude-code/plugins/unsolicited-text"
CODEX_PLUGIN="$ADAPTERS/codex/plugins/unsolicited-text"

check_reachable "$CLAUDE_CODE_PLUGIN/hooks/hooks.json" "$CLAUDE_CODE_PLUGIN" CLAUDE_PLUGIN_ROOT
check_reachable "$CODEX_PLUGIN/hooks/hooks.json" "$CODEX_PLUGIN" PLUGIN_ROOT

printf "\nTest group: each marketplace points at a plugin directory it carries\n"

source_of() { jq --raw-output "$2" "$1"; }

claude_source="$(source_of "$ADAPTERS/claude-code/.claude-plugin/marketplace.json" '.plugins[0].source')"
[ -f "$ADAPTERS/claude-code/${claude_source#./}/.claude-plugin/plugin.json" ]
assert "the claude code marketplace names its plugin" "$?" "no plugin at $claude_source"

codex_source="$(source_of "$ADAPTERS/codex/.agents/plugins/marketplace.json" '.plugins[0].source.path')"
[ -f "$ADAPTERS/codex/${codex_source#./}/.codex-plugin/plugin.json" ]
assert "the codex marketplace names its plugin" "$?" "no plugin at $codex_source"

printf "\nTest group: every script the install steps name is one this repository carries\n"

while read -r script; do
  [ -n "$script" ] || continue
  [ -x "$REPOSITORY/hooks/$script" ]
  assert "the readme names $script" "$?" "hooks/$script is not an executable file"
done < <(grep --only-matching --extended-regexp 'hooks/[a-z-]+\.sh' "$REPOSITORY/README.md" \
  | sed 's#^hooks/##' | sort --unique)

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
