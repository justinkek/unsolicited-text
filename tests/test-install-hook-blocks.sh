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

printf "Test group: every settings block registers every hook the plugin does\n"

report="$(python3 - "$INSTALL" "$REPOSITORY/hooks/hooks.json" <<'PY'
import json, re, sys

def scripts(hooks):
    return {
        handler["command"].rsplit("/", 1)[-1]
        for event in hooks.values()
        for group in event
        for handler in group["hooks"]
    }

install = open(sys.argv[1]).read()
registered = scripts(json.load(open(sys.argv[2]))["hooks"])
blocks = re.findall(r"```json\n(.*?)```", install, re.S)

if not blocks:
    print("no settings block in the page at all")
for number, block in enumerate(blocks, 1):
    try:
        named = scripts(json.loads(block)["hooks"])
    except Exception as unreadable:
        print(f"block {number} is not readable settings: {unreadable}")
        continue
    for missing in sorted(registered - named):
        print(f"block {number} never runs {missing}")
    for unknown in sorted(named - registered):
        print(f"block {number} runs {unknown}, which hooks.json does not register")
PY
)"

[ -z "$report" ]
assert "each block runs the six hooks.json names, and nothing else" "$?" "$report"

printf "\nTest group: each route says what it costs the reader\n"

grep --quiet --fixed-strings 'settings.local.json' "$INSTALL"
assert "the session-only route writes the untracked file" "$?" "no settings.local.json in $INSTALL"

grep --quiet --fixed-strings 'SKIP_PLUGIN_MARKETPLACE' "$INSTALL"
assert "and says how to tell a hosted session apart" "$?" "no detection signal in $INSTALL"

grep --quiet --fixed-strings '${CLAUDE_PROJECT_DIR}' "$INSTALL"
assert "the committed route names scripts from the project root" "$?" \
  "a committed settings file with absolute paths breaks on every other checkout"

grep --quiet --fixed-strings 'Everyone who works in the repository' "$INSTALL"
assert "and says who else gets the rules" "$?" \
  "committing a reply shape for a whole repository is not a silent change"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
