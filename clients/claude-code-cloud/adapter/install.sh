#!/usr/bin/env bash

folder="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$HOME/.claude/skills" "$HOME/.claude/commands"
cp -R "$folder/skills/." "$HOME/.claude/skills/"

for command in "$folder"/commands/*.md; do
  cp "$command" "$HOME/.claude/commands/unsolicited-text-$(basename "$command")"
done

"$folder/merge-settings.sh" "$folder/settings.json" "$HOME/.claude/settings.json" "$folder"
