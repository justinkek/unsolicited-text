#!/usr/bin/env bash

REPOSITORY="$(cd "$(dirname "$0")/.." && pwd)"
ADAPTER="$REPOSITORY/harness-adapters/claude-code"
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

printf "Test group: the update instructions name a script that installs what it pulls\n"

named="$(grep --only-matching --extended-regexp '[a-z-]+\.sh' "$REPOSITORY/UPDATING.md" | sort --unique)"

printf '%s' "$named" | grep --quiet --line-regexp --fixed-strings refresh-cloud.sh
assert "UPDATING.md names refresh-cloud.sh" "$?" \
  "it names $(printf '%s' "$named" | tr '\n' ' '), none of which installs what it pulls"

for script in $named; do
  [ -x "$ADAPTER/$script" ] || [ -x "$REPOSITORY/hooks/$script" ]
  assert "and $script is a script this repository carries" "$?" "there is nothing to run"
done

grep --quiet --fixed-strings install-cloud.sh "$ADAPTER/refresh-cloud.sh"
assert "the script it names runs the install" "$?" \
  "an update pulls the checkout and copies none of it, so a new skill waits for the next session"

grep --quiet --fixed-strings refresh-cloud.sh "$REPOSITORY/skills/update/SKILL.md"
outcome="$?"
[ "$outcome" != "0" ]
assert "the update skill names no script itself" "$?" \
  "it holds a copy of what UPDATING.md says, and the two drift apart"

printf "\nTest group: an update in a session hands it what the new version added\n"

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

running="$TMPDIR/running"
git clone --quiet --depth 1 "$origin" "$running" 2>/dev/null

home="$TMPDIR/home"
env HOME="$home" bash "$running/harness-adapters/claude-code/install-cloud.sh"

mkdir -p "$work/skills/newcomer"
printf -- '---\nname: newcomer\ndescription: added by the new version\n---\n' \
  > "$work/skills/newcomer/SKILL.md"
printf -- '---\ndescription: added by the new version\n---\n\nInvoke it.\n' \
  > "$work/commands/newcomer.md"
publish 0.0.2

said="$(printf '{}' | env HOME="$home" bash "$running/harness-adapters/claude-code/refresh-cloud.sh" 2>/dev/null)"
status="$?"

[ "$status" = "0" ]
assert "the update exits 0" "$?" "exited $status"

printf '%s' "$said" | grep --quiet --fixed-strings '0.0.2 replaces 0.0.1'
assert "it says which version replaces which" "$?" "it said '$said'"

[ -f "$home/.claude/skills/newcomer/SKILL.md" ]
assert "a skill the new version added is in place" "$?" \
  "it waits for the next session, and the update said it was done"

[ -f "$home/.claude/commands/unsolicited-text-newcomer.md" ]
assert "so is a command it added" "$?" "the menu entry waits for the next session"

printf "\n%d passed, %d failed\n" "$pass" "$fail"
[ "$fail" -eq 0 ]
