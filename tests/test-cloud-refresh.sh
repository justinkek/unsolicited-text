#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
CLOUD="$REPOSITORY/harness-adapters/claude-code/cloud-settings.json"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

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

payload='{"hook_event_name":"SessionStart","session_id":"test-refresh"}'

printf "Test group: a session start refreshes the checkout before it reads it\n"

python3 -c '
import json, sys
commands = [h["command"] for group in json.load(open(sys.argv[1]))["hooks"]["SessionStart"]
            for h in group["hooks"]]
raise SystemExit(0 if commands and "refresh-cloud.sh" in commands[0] else 1)' "$CLOUD"
assert "the refresh runs first at session start" "$?" \
  "the rules are printed from whatever the snapshot held"

python3 -c '
import json, sys
commands = [h["command"] for group in json.load(open(sys.argv[1]))["hooks"]["SessionStart"]
            for h in group["hooks"]]
raise SystemExit(0 if any("load-rules.sh" in c for c in commands) else 1)' "$CLOUD"
assert "and the rules are still printed after it" "$?" "a cloud session would be handed no rules"

printf "\nTest group: a checkout left behind catches up\n"

origin="$TMPDIR/origin"
git init --quiet --bare --initial-branch=main "$origin"

work="$TMPDIR/work"
git clone --quiet "$origin" "$work" 2>/dev/null
cp -R "$REPOSITORY/harness-adapters" "$REPOSITORY/hooks" "$REPOSITORY/skills" \
  "$REPOSITORY/commands" "$REPOSITORY/rules" "$work/"
cp "$REPOSITORY/package.json" "$work/package.json"

publish() {
  python3 -c '
import json, sys
p = sys.argv[1] + "/package.json"
package = json.load(open(p))
package["version"] = sys.argv[2]
json.dump(package, open(p, "w"), indent="\t")' "$work" "$1"
  git -C "$work" add --all
  git -C "$work" -c user.email=test -c user.name=test commit --quiet --message "version $1"
  git -C "$work" push --quiet origin HEAD:main 2>/dev/null
}

publish 0.0.1

behind="$TMPDIR/behind"
git clone --quiet --depth 1 "$origin" "$behind" 2>/dev/null

publish 0.0.2

said="$(printf '%s' "$payload" | env HOME="$TMPDIR/home" \
  bash "$behind/harness-adapters/claude-code/refresh-cloud.sh" 2>/dev/null)"
status="$?"

[ "$status" = "0" ]
assert "the refresh exits 0" "$?" "exited $status, and a session start would fail"

grep --quiet --fixed-strings '"version": "0.0.2"' "$behind/package.json"
assert "the checkout moves to the published version" "$?" \
  "it stays where the snapshot left it, however old that is"

printf '%s' "$said" | grep --quiet --fixed-strings '0.0.2 replaces 0.0.1'
assert "and the session is told what changed" "$?" "it said '$said'"

[ -f "$TMPDIR/home/.claude/settings.json" ]
assert "the new version installs itself" "$?" "the skills and registrations stay as they were"

printf "\nTest group: a refresh that cannot reach the remote changes nothing\n"

said="$(printf '%s' "$payload" | env HOME="$TMPDIR/home" \
  bash "$behind/harness-adapters/claude-code/refresh-cloud.sh" 2>/dev/null)"
[ -z "$said" ]
assert "a checkout already current says nothing" "$?" "it said '$said'"

git -C "$behind" remote set-url origin "$TMPDIR/gone"
said="$(printf '%s' "$payload" | env HOME="$TMPDIR/home" \
  bash "$behind/harness-adapters/claude-code/refresh-cloud.sh" 2>/dev/null)"
status="$?"

[ "$status" = "0" ]
assert "an unreachable remote exits 0" "$?" "exited $status, and the session would not start"

grep --quiet --fixed-strings '"version": "0.0.2"' "$behind/package.json"
assert "and leaves the checkout it had" "$?" "the checkout was emptied by a failed refresh"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
