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
  "$REPOSITORY/.claude-plugin/marketplace.json" \
  "$REPOSITORY/.claude-plugin/plugin.json" \
  "$REPOSITORY/hooks/hooks.json" \
  "$REPOSITORY/.agents/plugins/marketplace.json" \
  "$REPOSITORY/.codex-plugin/plugin.json" \
  "$ADAPTERS/codex/hooks.json" \
  "$REPOSITORY/package.json"
do
  jq --exit-status . "$manifest" >/dev/null 2>&1
  assert "${manifest#$REPOSITORY/} parses" "$?" "not readable as JSON"
done

printf "Test group: every command resolves inside the plugin, from wherever it is installed\n"

check_reachable() {
  local manifest="$1" plugin="$2" variable="$3" label="$4" prefix command inside
  prefix="\${$variable}/"
  while read -r command; do
    [ -n "$command" ] || continue
    inside="${command#"$prefix"}"

    [ "$inside" != "$command" ]
    assert "$label names $(basename "$command") from its own root" "$?" \
      "$command does not start with $prefix"

    case "/$inside/" in
      */../*) false ;;
      *) true ;;
    esac
    assert "$label does not climb out of the plugin to reach it" "$?" \
      "$command escapes the plugin, and an installed copy has nothing above it"

    [ -x "$plugin/$inside" ]
    assert "$label ships $inside" "$?" "no executable file there, so a copy of the plugin cannot run it"
  done < <(commands_of "$manifest")
}

check_reachable "$REPOSITORY/hooks/hooks.json" "$REPOSITORY" CLAUDE_PLUGIN_ROOT "claude-code"
check_reachable "$ADAPTERS/codex/hooks.json" "$REPOSITORY" PLUGIN_ROOT "codex"

printf "\nTest group: each marketplace points at a plugin directory it carries\n"

source_of() { jq --raw-output "$2" "$1"; }

claude_source="$(source_of "$REPOSITORY/.claude-plugin/marketplace.json" '.plugins[0].source')"
[ -f "$REPOSITORY/${claude_source#./}.claude-plugin/plugin.json" ]
assert "the claude code marketplace names its plugin" "$?" "no plugin at $claude_source"

codex_source="$(source_of "$REPOSITORY/.agents/plugins/marketplace.json" '.plugins[0].source.path')"
[ -f "$REPOSITORY/${codex_source#./}.codex-plugin/plugin.json" ]
assert "the codex marketplace names its plugin" "$?" "no plugin at $codex_source"

[ -f "$REPOSITORY/${claude_source#./}AGENTS.md" ]
assert "and the rules ship inside it" "$?" \
  "AGENTS.md sits outside the plugin, so an installed copy has nothing to print"

printf "\nTest group: every script the install steps name is one this repository carries\n"

named=0
while read -r page script; do
  [ -n "$script" ] || continue
  named=$((named + 1))
  [ -x "$REPOSITORY/hooks/$script" ]
  assert "$page names $script" "$?" "hooks/$script is not an executable file"
done < <(for page in README.md INSTALL.md; do
  grep --only-matching --extended-regexp 'hooks/[a-z-]+\.sh' "$REPOSITORY/$page" \
    | sed "s#^hooks/#$page #" | sort --unique
done)

[ "$named" -gt 3 ]
assert "the pages name the scripts at all" "$?" "only $named named between them"

printf "\nTest group: every hook this repository carries is registered somewhere\n"

registered="$(
  for manifest in "$REPOSITORY/hooks/hooks.json" "$ADAPTERS/codex/hooks.json"; do
    commands_of "$manifest"
  done
  grep --only-matching --extended-regexp '[a-z-]+\.sh' "$ADAPTERS/pi/src/index.ts"
)"

for script in "$REPOSITORY"/hooks/*.sh; do
  name="$(basename "$script")"
  case "$name" in *-lib.sh) continue ;; esac
  printf '%s' "$registered" | grep --quiet --fixed-strings "$name"
  assert "$name is registered by an adapter" "$?" \
    "nothing runs it, so it ships and never fires"
done

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
