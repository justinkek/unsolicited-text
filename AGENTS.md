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
| what the settings skill tells the user | `skills/settings/body.md` |
| which hooks a distribution registers | `adapters/<distribution>/` |
| how each install method works | `clients/<client>/install.md`, with `update.md`, `uninstall.md`, `reload.md`, `settings.md` and `support.md` beside it. Each builds a section of that distribution's README; `INSTALL.md` is the table pointing at them |
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

One folder under `clients/` holds everything about one name: its pages, its
`signature.md` where a session has to recognise itself, and its `adapter/` where
the harness needs one. The prose around the table in `INSTALL.md` is the one
thing that belongs to no client, and it is in `install-page/`.

A folder under `clients/` is a client, and nothing else: its pages, its
`signature.md`, and `client.json` holding its name. A page that would be a copy
of another client's holds one line instead, `{same as claude-code-local}`, and
the build reads that client's page in its place. A test fails on a copy that
does not say so. A folder under `adapters/`
is a distribution's, and holds what registers the hooks with that harness.

Every key in `distributions.json` builds a folder under `distributions/`, says
which parts it `ships`, and lists the clients it `serves`, itself included. One
install serves every Claude client that reads the marketplace, so its skills and
its README carry a section per client, and a session follows the branch whose
signature matches what it can see. Such a distribution says its own `name`; one
serving a single client is called what that client is called. A key with
`same-as` installs from another distribution's folder. A test holds every folder
to it, so a part nothing there reads cannot ship by accident.

Raise the version in `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`
and `package.json` together when a change has to reach an installed copy: an
install caches by version. Then run `skills/reload/render`, which stamps
the version it was built from into the skill.

## What not to hand-edit

Skills are written as `skills/<name>/body.md` and built into every distribution
by `./build`, which appends that distribution's own page: `update.md` for the
update skill, `uninstall.md` for uninstall, `settings.md` for settings,
`reload.md` for reload. The reload
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
