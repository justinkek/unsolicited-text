#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL="$REPOSITORY/INSTALL.md"

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

printf "Test group: the settings a hosted session writes register every hook the plugin does\n"

registered=0
while read -r script; do
  [ -n "$script" ] || continue
  registered=$((registered + 1))
  grep --quiet --fixed-strings "checkout/hooks/$script" "$INSTALL"
  assert "the session-only block names $script" "$?" \
    "hooks.json registers it and a session written from $INSTALL would not run it"

  grep --quiet --fixed-strings "/opt/unsolicited-text/hooks/$script" "$INSTALL"
  assert "the setup script names $script" "$?" \
    "hooks.json registers it and an environment built from $INSTALL would not run it"

  grep --quiet --fixed-strings "<path to this checkout>/hooks/$script" "$INSTALL"
  assert "the codex block names $script" "$?" \
    "hooks.json registers it and a Codex session registered from $INSTALL would not run it"
done < <(jq --raw-output '.hooks | to_entries[] | .value[] | .hooks[] | .command' \
  "$REPOSITORY/hooks/hooks.json" | sed 's#.*/##' | sort --unique)

[ "$registered" -gt 0 ]
assert "hooks.json registers anything at all" "$?" "no commands read out of hooks/hooks.json"

printf "\nTest group: the block is JSON a harness can read\n"

python3 - "$INSTALL" <<'PY'
import json, re, sys
text = open(sys.argv[1]).read()
block = re.search(r"```json\n(.*?)```", text, re.S)
raise SystemExit(0 if block and json.loads(block.group(1)).get("hooks") else 1)
PY
assert "it parses, and carries a hooks object" "$?" "the fenced json block in $INSTALL is not readable JSON"

printf "\nTest group: the session-only route is named as throwaway\n"

grep --quiet --fixed-strings 'settings.local.json' "$INSTALL"
assert "it writes the untracked settings file" "$?" "no settings.local.json in $INSTALL"

grep --quiet --fixed-strings 'SKIP_PLUGIN_MARKETPLACE' "$INSTALL"
assert "and says how to tell a hosted session apart" "$?" "no detection signal in $INSTALL"

printf "\nTest group: the setup script survives the rules it has to live by\n"

grep --quiet --fixed-strings '|| true' "$INSTALL"
assert "a failed clone does not stop the session starting" "$?" \
  "a setup script that exits non-zero refuses the session, so $INSTALL has to say so"

grep --quiet --fixed-strings 'exit zero' "$INSTALL"
assert "and the page says why that matters" "$?" "no mention of the exit status a setup script owes"

grep --quiet --fixed-strings 'It overwrites `~/.claude/settings.json`' "$INSTALL"
assert "the reader is warned before their own settings go" "$?" \
  "the script replaces a file that may already hold something"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
