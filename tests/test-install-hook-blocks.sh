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

printf "Test group: every block on the page registers every hook the plugin does\n"

registered=0
while read -r script; do
  [ -n "$script" ] || continue
  registered=$((registered + 1))

  grep --quiet --fixed-strings "/opt/unsolicited-text/hooks/$script" "$INSTALL"
  assert "the setup script names $script" "$?" \
    "hooks.json registers it and a container set up from $INSTALL would not run it"

  grep --quiet --fixed-strings "<path to this checkout>/hooks/$script" "$INSTALL"
  assert "the codex block names $script" "$?" \
    "hooks.json registers it and a Codex session registered from $INSTALL would not run it"
done < <(jq --raw-output '.hooks | to_entries[] | .value[] | .hooks[] | .command' \
  "$REPOSITORY/hooks/hooks.json" | sed 's#.*/##' | sort --unique)

[ "$registered" -gt 0 ]
assert "hooks.json registers anything at all" "$?" "no commands read out of hooks/hooks.json"

printf "\nTest group: the setup script is one a container can run\n"

script="$(sed -n '/^```bash$/,/^```$/p' "$INSTALL" | sed '1d;$d')"

printf '%s' "$script" | bash -n
assert "it parses as bash" "$?" "the fenced bash block in $INSTALL is not a runnable script"

printf '%s' "$script" | grep --quiet --fixed-strings '|| true'
assert "a failed clone does not stop the session starting" "$?" \
  "a setup script that exits non-zero refuses the session"

printf '%s' "$script" | python3 -c '
import json, re, sys
settings = re.search(r"<<.SETTINGS.\n(.*?)\nSETTINGS", sys.stdin.read(), re.S)
raise SystemExit(0 if settings and json.loads(settings.group(1)).get("hooks") else 1)'
assert "and the settings it writes are readable JSON" "$?" "the block writes something a harness cannot read"

printf "\nTest group: the page says what a reader has to know before running it\n"

grep --quiet --fixed-strings 'SKIP_PLUGIN_MARKETPLACE' "$INSTALL"
assert "why the install above does nothing in a container" "$?" "no detection signal in $INSTALL"

grep --quiet --fixed-strings 'It overwrites `~/.claude/settings.json`' "$INSTALL"
assert "that it replaces a settings file already there" "$?" "no warning before their own settings go"

grep --quiet --fixed-strings 'rules/reply-shape.md' "$INSTALL"
assert "and how to load the rules in a session already going" "$?" \
  "session start has passed, so the rules have to be printed by hand"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
