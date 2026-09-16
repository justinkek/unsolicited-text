# Working in this repository

(audience: agents)

The rules this plugin prints into a session are not this file. They are
`rules/reply-shape.md`, and a session never reads that file as it sits on disk:
`hooks/load-rules.sh` rewrites the ceilings, strips the queue emoji unless
they are turned on, and caps the queue length, then prints the result. Run the
hook to see what a session gets:

    printf '{}' | hooks/load-rules.sh

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
| how each install method works | `installs/<distribution>.md`, with `updates/`, `uninstalls/` and `reloads/` beside it. Each builds a section of that distribution's README; `INSTALL.md` is the table pointing at them |
| what an install copies | nothing by hand - `distributions/` is built by `./build` from the sources above |
| the rules a session without hooks reads | nothing by hand - run the `render` beside the skill after editing its page |

Every setting is read through `setting_value`, takes the `UNSOLICITED_TEXT_`
prefix, and is named in the settings skill. A test holds all three together.

`distributions/` is generated and committed, one folder per distribution, because an install
fetches files from the repository. Run `./build` after changing anything it
copies. A test rebuilds and fails on any difference. Every generated file opens by
saying so, and its diff is reviewed like any other.

The two plugin manifests are generated from `package.json`, which is where the
version, the description and the author are written.

Only the cloud distribution ships `commands/`, because its install renames them
with an `unsolicited-text-` prefix. Where the install registers a plugin, a
command and a skill of the same name both answer to `unsolicited-text:<name>`,
the command wins, and its body only points back at the name it was invoked by.

`distributions.json` says which parts each distribution's folder takes, and its
name: the product, and where it runs in parentheses only where one product has
more than one distribution. An entry with `same-as` installs from another
distribution's folder and builds none of its own. A test holds every
folder to it, so a part nothing there reads cannot ship by accident.

At 0.3.0, delete the stale-snapshot paragraph from `updates/claude-code-local.md`.
It exists for readers crossing the 0.2.0 move.

Raise the version in `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`
and `package.json` together when a change has to reach an installed copy: an
install caches by version. Then run `skills/reload/render`, which stamps
the version it was built from into the skill.

## What not to hand-edit

Skills are written as `skills/<name>/body.md` and built into every distribution
by `./build`, which appends that distribution's own steps: `updates/` for the
update skill, `uninstalls/` for uninstall, `reloads/` for settings. The reload
skill carries `rules/reply-shape.md` with every setting at its default. No
`SKILL.md` is written by hand, and a test fails when one drifts from its sources.

The recordings under `demo/` are generated. Edit the prompt and the two reply
files beside them, then run `demo/record`. The logo is drawn in `logo/logo.svg`
and rendered by `logo/render`.

Write documentation the way the rules ask for a reply: plain English, no
metaphors, and a worked example instead of a description of one.

Every page opens with `(audience: humans)` or `(audience: agents)` under its
heading. Where a page written for one holds a paragraph the other acts on, that
paragraph opens with the mark for whoever acts on it, and it lasts one
paragraph. `rules/reply-shape.md` carries no mark, since a hook prints it into a
session and the mark would go with it.
