# Product compatibility

(audience: humans)

## Anthropic

| Product | Surface | Harness execution environment | Installation | Support |
| --- | --- | --- | --- | --- |
| Claude Chat | Web GUI | Hosted | Install or upload the plugin through Customize | Partial. The settings and update skills can appear, but Chat does not run the hooks that load the reply rules or catch drift. There are no rules to reload, and hook settings have no effect. Put `rules/reply-shape.md` in a preference or custom style for reply shaping without drift checks. |
|  | Desktop GUI | Hosted | Install or upload the plugin through Customize | Partial, for the same reason as the web GUI. There are no rules to reload, and hook settings have no effect. |
|  | Mobile GUI | Hosted | No installation method is documented here | Not verified. |
| Cowork | Web GUI | Hosted | Install or upload the plugin through Customize | Not verified. Cowork supports plugin skills and hooks, but unsolicited-text, its reload, and its settings have not been tested there. |
|  | Desktop GUI | Local | Install or upload the plugin through Customize | Not verified. Cowork supports plugin skills and hooks, but unsolicited-text, its reload, and its settings have not been tested there. |
|  | Desktop GUI | Hosted | Install or upload the plugin through Customize | Not verified. Cowork supports plugin skills and hooks, but unsolicited-text, its reload, and its settings have not been tested there. |
|  | Mobile GUI | Hosted | Install the plugin from another supported surface | Not verified. Cowork supports plugin skills and hooks, but unsolicited-text, its reload, and its settings have not been tested there. |
| Claude Code | Web GUI | Hosted | Use the setup script in [INSTALL.md](INSTALL.md#cloud-sessions) | Supported. Every-session installs load all rules and drift checks at session start, and refresh the checkout to the published version first, so a container built from an older environment is not held at the version it was built with. The pasted setup script clones and hands the rest to the checkout, so it never needs pasting again. A this-session install needs the [manual rule reload](RELOAD.md) and `/reload-skills`. Persistent settings use `UNSOLICITED_TEXT_*` environment variables because the container is rebuilt, and `~/.claude/settings.json` is overwritten by the install, so hooks registered there by anything else are lost. |
|  | Desktop GUI | Local | No installation method is documented here | Not verified, including reload and settings behavior. |
|  | Desktop GUI | Hosted | No installation method is documented here | Not verified, including reload and settings behavior. |
|  | Mobile GUI | Hosted | Configure the cloud environment from the web GUI | Supported as access to a Claude Code cloud session. The plugin runs in the session container, not on the phone. Reload and settings behave as in the web GUI row. A queue drawn as a tree wraps where the phone chooses, since a fenced block does not scroll there. |
|  | CLI | Local | Use the Claude marketplace commands in [INSTALL.md](INSTALL.md#1-claude-code-zcode) | Supported. The plugin supplies the rules, reminders, drift checks, settings skill, and update skill. Start a new session after installation, or use the [manual rule reload](RELOAD.md) in the current one. Settings live in `~/.unsolicited-text/settings`. |

## OpenAI

| Product | Surface | Harness execution environment | Installation | Support |
| --- | --- | --- | --- | --- |
| ChatGPT Chat | Web GUI | Hosted | No installation method is documented here | Partial in principle. Chat can use plugin skills, but it does not run the Codex lifecycle hooks that provide unsolicited-text's reply rules and drift checks. There are no rules to reload, and hook settings have no effect. This plugin has not been tested in Chat. |
|  | Desktop GUI | Hosted | No installation method is documented here | Partial in principle, for the same reason as the web GUI. There are no rules to reload, and hook settings have no effect. This plugin has not been tested in Chat. |
|  | Mobile GUI | Hosted | Install the plugin from another supported surface | Partial in principle, for the same reason as the web GUI. There are no rules to reload, and hook settings have no effect. This plugin has not been tested in Chat. |
| ChatGPT Work | Web GUI | Hosted | No installation method is documented here | Not yet supported. Work can run hooks, but installing on the web does not deploy this plugin's hook scripts into the execution environment. There are therefore no rules or settings to reload. |
|  | Desktop GUI | Local | No installation method is documented here | Not verified. Work can run hooks, but this repository does not yet install or register their scripts for Work, so reload and settings behavior is also unverified. |
|  | Desktop GUI | Hosted | No installation method is documented here | Not yet supported. This repository does not deploy the hook scripts into a hosted session, so there are no rules or settings to reload. |
|  | Mobile GUI | Hosted | Install the plugin from another supported surface | Not yet supported. The required hook scripts are not deployed into the cloud execution environment, so there are no rules or settings to reload. |
| Codex | Web GUI | Hosted | No installation method is documented here | Not supported. OpenAI documents plugin use for Codex in the ChatGPT desktop app and Codex CLI, not Codex cloud. There are no rules or settings to reload. |
|  | Desktop GUI | Local | Use the Codex marketplace commands and manual hook registration in [INSTALL.md](INSTALL.md#2-codex) | Supported after the hooks are registered. A new session loads the rules automatically; the current session needs the [manual rule reload](RELOAD.md). Settings live in `~/.unsolicited-text/settings`. |
|  | Desktop GUI | Hosted | No installation method is documented here | Not yet supported. This repository does not install or register the hook scripts into a hosted session, so there are no rules or settings to reload. |
|  | CLI | Local | Use the Codex marketplace commands and manual hook registration in [INSTALL.md](INSTALL.md#2-codex) | Supported after the hooks are registered. A new session loads the rules automatically; the current session needs the [manual rule reload](RELOAD.md). Settings live in `~/.unsolicited-text/settings`. |
|  | IDE extension | Local | None | Not supported. The IDE extension does not support plugins, so there are no rules or settings to reload. |

## ZCode

| Product | Surface | Harness execution environment | Installation | Support |
| --- | --- | --- | --- | --- |
| ZCode | Desktop GUI | Local | Add `justinkek/unsolicited-text` through Settings, Marketplace | Supported through its Claude Code plugin compatibility. Start a new session after installation, or use the [manual rule reload](RELOAD.md) in the current one. Settings live in `~/.unsolicited-text/settings`. |

## Pi

| Product | Surface | Harness execution environment | Installation | Support |
| --- | --- | --- | --- | --- |
| Pi | CLI | Local | Run the Pi command in [INSTALL.md](INSTALL.md#3-pi) | Partial. The adapter supplies the short reply reminder and carries drift notes into the next prompt, but Pi has no session-start hook here to load or reload the full rules automatically. Its hooks read settings from `~/.unsolicited-text/settings` or `UNSOLICITED_TEXT_*` environment variables. |
