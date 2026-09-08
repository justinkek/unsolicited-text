# Working in this repository

The rules this plugin prints into a session are not this file. They are
`rules/reply-shape.md`, and a session never reads that file as it sits on disk:
`hooks/load-agents-md.sh` rewrites the ceilings, strips the queue emoji unless
they are turned on, and caps the queue length, then prints the result. Run the
hook to see what a session gets:

    printf '{}' | hooks/load-agents-md.sh

This file is what a session working *on* the plugin reads.

## Before you push

    tests/run-tests

`test-logo-is-current.sh` and `test-readme-demo-holds.sh` compare file times, so
they fail on a fresh clone where git wrote everything at once. On a checkout you
have been editing, they mean what they say: run `logo/render` or `demo/record`.

## Where a change belongs

| Change | File |
| --- | --- |
| a rule a session must follow | `rules/reply-shape.md` |
| a setting, and its default | `hooks/hook-settings-lib.sh` |
| what the settings skill tells the user | `skills/settings/SKILL.md` |
| which hooks a harness registers | `hooks/hooks.json`, and the adapter under `harness-adapters/` |
| how a route is installed | `INSTALL.md`, and `UNINSTALL.md` for taking it back off |

Every setting is read through `setting_value`, takes the `UNSOLICITED_TEXT_`
prefix, and is named in the settings skill. A test holds all three together.

Raise the version in `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`
and `package.json` together when a change has to reach an installed copy: an
install caches by version.

## What not to hand-edit

The recordings under `demo/` are generated. Edit the prompt and the two reply
files beside them, then run `demo/record`. The logo is drawn in `logo/logo.svg`
and rendered by `logo/render`.

Write documentation the way the rules ask for a reply: plain English, no
metaphors, and a worked example instead of a description of one.
