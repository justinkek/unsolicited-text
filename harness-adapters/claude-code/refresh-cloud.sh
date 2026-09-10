#!/usr/bin/env bash

cat >/dev/null

checkout="$(cd "$(dirname "$0")/../.." && pwd)"
[ -d "$checkout/.git" ] || exit 0

. "$checkout/hooks/hook-settings-lib.sh"

before="$(installed_version)"

git -C "$checkout" fetch --quiet --depth 1 origin main 2>/dev/null || exit 0
git -C "$checkout" reset --quiet --hard FETCH_HEAD 2>/dev/null || exit 0

after="$(installed_version)"
[ "$before" = "$after" ] && exit 0

"$checkout/harness-adapters/claude-code/install-cloud.sh" >/dev/null 2>&1

printf 'unsolicited-text %s replaces %s. Its skills and commands are in place from your next message.\n' \
  "$after" "$before"

exit 0
