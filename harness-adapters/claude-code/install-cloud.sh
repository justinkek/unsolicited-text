#!/usr/bin/env bash

checkout="$(cd "$(dirname "$0")/../.." && pwd)"

mkdir -p "$HOME/.claude/skills" "$HOME/.claude/commands"
cp -R "$checkout/skills/." "$HOME/.claude/skills/"

for command in "$checkout"/commands/*.md; do
  cp "$command" "$HOME/.claude/commands/unsolicited-text-$(basename "$command")"
done

"$checkout/harness-adapters/claude-code/merge-settings.sh" \
  "$checkout/harness-adapters/claude-code/cloud-settings.json" \
  "$HOME/.claude/settings.json" \
  "$checkout"
