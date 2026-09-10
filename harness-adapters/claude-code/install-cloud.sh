#!/usr/bin/env bash

# Copies this checkout into the places a cloud session reads. The setup script
# pasted into a cloud environment clones and runs this, so what it copies can
# change without that script changing.

checkout="$(cd "$(dirname "$0")/../.." && pwd)"

mkdir -p "$HOME/.claude/skills" "$HOME/.claude/commands"
cp -R "$checkout/skills/." "$HOME/.claude/skills/"

for command in "$checkout"/commands/*.md; do
  cp "$command" "$HOME/.claude/commands/unsolicited-text-$(basename "$command")"
done

cp "$checkout/harness-adapters/claude-code/cloud-settings.json" "$HOME/.claude/settings.json"
