#!/usr/bin/env bash

cat >/dev/null

rules="$(dirname "$0")/../AGENTS.md"
[ -f "$rules" ] || exit 0

cat "$rules"
