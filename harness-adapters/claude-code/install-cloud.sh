#!/usr/bin/env bash

checkout="$(cd "$(dirname "$0")/../.." && pwd)"
settings="$HOME/.claude/settings.json"
registrations="$checkout/harness-adapters/claude-code/cloud-settings.json"

mkdir -p "$HOME/.claude/skills" "$HOME/.claude/commands"
cp -R "$checkout/skills/." "$HOME/.claude/skills/"

for command in "$checkout"/commands/*.md; do
  cp "$command" "$HOME/.claude/commands/unsolicited-text-$(basename "$command")"
done

if [ ! -f "$settings" ]; then
  sed "s#/opt/unsolicited-text#$checkout#g" "$registrations" > "$settings"
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  printf 'unsolicited-text: no python3 to merge with, so %s was left as it was and no hooks are registered\n' \
    "$settings" >&2
  exit 1
fi

python3 - "$registrations" "$settings" "$checkout" <<'MERGE'
import json, os, sys

registrations, settings, checkout = sys.argv[1], sys.argv[2], sys.argv[3]

ours = json.loads(open(registrations).read().replace("/opt/unsolicited-text", checkout))

def set_aside(why):
    os.replace(settings, settings + ".unreadable")
    sys.stderr.write(
        "unsolicited-text: %s %s, so it was kept as %s.unreadable and written fresh\n"
        % (settings, why, settings))

try:
    theirs = json.load(open(settings))
except (ValueError, OSError):
    set_aside("did not parse")
    theirs = {}

if not isinstance(theirs, dict):
    set_aside("does not hold an object")
    theirs = {}

if not isinstance(theirs.get("hooks"), dict):
    theirs["hooks"] = {}

def is_ours(hook):
    return (isinstance(hook, dict)
            and str(hook.get("command", "")).startswith(checkout + "/"))

for event, groups in ours["hooks"].items():
    kept = []
    for group in theirs["hooks"].get(event) or []:
        if not isinstance(group, dict):
            kept.append(group)
            continue
        group["hooks"] = [h for h in group.get("hooks") or [] if not is_ours(h)]
        if group["hooks"]:
            kept.append(group)
    theirs["hooks"][event] = kept + groups

with open(settings, "w") as written:
    json.dump(theirs, written, indent="\t")
    written.write("\n")
MERGE
