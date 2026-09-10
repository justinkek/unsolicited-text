#!/usr/bin/env bash

cat >/dev/null

. "$(dirname "$0")/hook-settings-lib.sh"

apply_migrations

exit 0
