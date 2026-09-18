#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
CODEX="$REPOSITORY/clients/codex/install.md"
CODEX_MANIFEST="$REPOSITORY/distributions/codex/.codex-plugin/plugin.json"
CODEX_HOOKS="$REPOSITORY/distributions/codex/hooks/hooks.json"
CLOUD_STEPS="$REPOSITORY/clients/claude-code-cloud/install.md"
MARKETPLACE="$REPOSITORY/clients/claude-code-local/install.md"
CLOUD="$REPOSITORY/distributions/claude-code-cloud/settings.json"

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

printf "Test group: every block on the page registers every hook the plugin does\n"

registered=0
while read -r script; do
  [ -n "$script" ] || continue
  registered=$((registered + 1))

  grep --quiet --fixed-strings "/opt/unsolicited-text/distributions/claude-code-cloud/hooks/$script" "$CLOUD"
  assert "the cloud settings name $script" "$?" \
    "hooks.json registers it and a cloud session would not run it"

  grep --quiet --fixed-strings "/hooks/$script" "$CODEX_HOOKS"
  assert "the codex hooks file names $script" "$?" \
    "the Claude adapter registers it and a Codex session would not run it"
done < <(jq --raw-output '.hooks | to_entries[] | .value[] | .hooks[] | .command' \
  "$REPOSITORY/adapters/claude/hooks.json" | sed -e 's/"$//' -e 's#.*/##' | sort --unique)

[ "$registered" -gt 0 ]
assert "hooks.json registers anything at all" "$?" "no commands read out of the Claude adapter's hooks.json"

[ "$(jq --raw-output '.hooks // empty' "$CODEX_MANIFEST")" = "./hooks/hooks.json" ]
assert "the codex manifest points at that hooks file" "$?" \
  "Codex reads hooks from the manifest, and this one names something else"

grep --quiet --fixed-strings '/hooks' "$CODEX"
assert "the codex page says to trust them" "$?" \
  "Codex skips a hook until it has been reviewed, and the page never says so"

! grep --quiet --fixed-strings '[[hooks.' "$CODEX"
assert "and no longer asks for a config file to be edited by hand" "$?" \
  "the plugin registers its own hooks, so a pasted block would run each one twice"

printf "\nTest group: the setup script is one a container can run\n"

script="$(sed -n '/^```bash$/,/^```$/p' "$CLOUD_STEPS" | sed '1d;$d')"

printf '%s' "$script" | bash -n
assert "it parses as bash" "$?" "the fenced bash block in $CLOUD_STEPS is not a runnable script"

printf '%s' "$script" | grep --quiet --fixed-strings '|| true'
assert "a failed clone does not stop the session starting" "$?" \
  "a setup script that exits non-zero refuses the session"

python3 -c '
import json, sys
raise SystemExit(0 if json.load(open(sys.argv[1])).get("hooks") else 1)' "$CLOUD"
assert "and the settings it copies are readable JSON" "$?" "the block writes something a harness cannot read"

printf "\nTest group: the pasted script hands the work to the checkout\n"

INSTALLER="$REPOSITORY/distributions/claude-code-cloud/install.sh"

[ -x "$INSTALLER" ]
assert "the cloud install script is there and runnable" "$?" "the pasted script would run nothing"

printf '%s' "$script" | grep --quiet --fixed-strings 'distributions/claude-code-cloud/install.sh'
assert "the pasted script runs it" "$?" "it copies files itself, and a later version cannot change what is copied"

bash -n "$INSTALLER"
assert "and it parses as bash" "$?" "the setup script would fail on a fresh container"

installed="$(mktemp -d)"
HOME="$installed" bash "$INSTALLER" >/dev/null 2>&1
for wanted in .claude/settings.json .claude/skills/settings/SKILL.md .claude/commands/unsolicited-text-update.md; do
  [ -f "$installed/$wanted" ]
  assert "it installs $wanted" "$?" "a cloud session would not have it"
done
rm -rf "$installed"

printf "\nTest group: the page says what a reader has to know before running it\n"

grep --quiet --fixed-strings 'SKIP_PLUGIN_MARKETPLACE' "$MARKETPLACE"
assert "why the install above does nothing in a container" "$?" "no detection signal in $MARKETPLACE"

grep --quiet --extended-regexp 'reload skill|load-rules\.sh' "$CLOUD_STEPS"
assert "and how to load the rules in a session already going" "$?" \
  "session start has passed, so the rules have to be printed by hand"

grep --quiet --fixed-strings 'reload skill' "$REPOSITORY/clients/claude-chat/install.md"
assert "and what to do on a harness that runs no hooks" "$?" \
  "a reader on such a harness is told nothing works and nothing else"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
