#!/usr/bin/env bash

# The hooks a test runs are the ones an install copies, so a test builds first
# and runs what came out. Sourcing this sets BUILT_HOOKS to that directory.
#
# It builds once per run of the suite: run-tests sets UNSOLICITED_TEXT_BUILT,
# and a test run on its own builds its own.

if [ -n "${UNSOLICITED_TEXT_BUILT-}" ] && [ -d "$UNSOLICITED_TEXT_BUILT/claude/hooks" ]; then
  BUILT_HOOKS="$UNSOLICITED_TEXT_BUILT/claude/hooks"
else
  BUILT_ROOT="$(mktemp -d)"
  trap 'rm -rf "$BUILT_ROOT"' EXIT
  "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/build" \
    "$BUILT_ROOT/distributions" "$BUILT_ROOT/INSTALL.md" >/dev/null
  BUILT_HOOKS="$BUILT_ROOT/distributions/claude/hooks"
fi
