# Product compatibility

(audience: humans)

## Anthropic

| Product | Surface | Harness execution environment | Installation | Support |
| --- | --- | --- | --- | --- |
| Claude Chat | Web GUI | Hosted | Install or upload the plugin through Customize | Partial. The settings and update skills can appear, but Chat does not run the hooks that load the reply rules or catch drift. There are no rules to reload, and hook settings have no effect. Put `rules/reply-shape.md` in a preference or custom style for reply shaping without drift checks. |
|  | Desktop GUI | Hosted | (as above) | Partial, for the same reason as the web GUI. |
|  | Mobile GUI | Hosted |  | Not verified. |
| Cowork | Web GUI | Hosted | Install or upload the plugin through Customize | Not verified. Cowork supports plugin skills and hooks, but unsolicited-text, its reload, and its settings have not been tested there. |
|  | Desktop GUI | Local | (as above) | Not verified, as in the web GUI row. |
|  | Desktop GUI | Hosted | (as above) | Not verified, as in the web GUI row. |
|  | Mobile GUI | Hosted | Install the plugin from another supported surface | Not verified, as in the web GUI row. |
| Claude Code | Web GUI | Hosted | [INSTALL.md#cloud-sessions](INSTALL.md#cloud-sessions) | Supported. Every session loads the rules and drift checks at session start, after refreshing the checkout to the published version, so an old container is not held at the version it was built with. The setup script is pasted once. A this-session install needs the [manual rule reload](RELOAD.md) and `/reload-skills`. Settings use `UNSOLICITED_TEXT_*` environment variables because the container is rebuilt, and the install overwrites `~/.claude/settings.json`, so hooks registered there by anything else are lost. |
|  | Desktop GUI | Local | [INSTALL.md#1-claude-code-zcode](INSTALL.md#1-claude-code-zcode) | Supported, reported working by a user, and behaves as the CLI row. |
|  | Desktop GUI | Hosted | [INSTALL.md#cloud-sessions](INSTALL.md#cloud-sessions) | Not verified. |
|  | Mobile GUI | Hosted | Configure the cloud environment from the web GUI | Supported as access to a Claude Code cloud session, behaving as the web GUI row. The plugin runs in the session container, not on the phone. A queue drawn as a tree wraps where the phone chooses, since a fenced block does not scroll there. |
|  | CLI | Local | [INSTALL.md#1-claude-code-zcode](INSTALL.md#1-claude-code-zcode) | Supported. The plugin supplies the rules, reminders, drift checks, settings skill, and update skill. Start a new session after installation, or use the [manual rule reload](RELOAD.md) in the current one. Settings live in `~/.unsolicited-text/settings`. |

## OpenAI

| Product | Surface | Harness execution environment | Installation | Support |
| --- | --- | --- | --- | --- |
| ChatGPT Chat | Web GUI | Hosted |  | Partial in principle. Chat can use plugin skills, but it does not run the Codex lifecycle hooks that provide unsolicited-text's reply rules and drift checks. There are no rules to reload, and hook settings have no effect. This plugin has not been tested in Chat. |
|  | Desktop GUI | Hosted |  | Partial in principle, for the same reason as the web GUI. |
|  | Mobile GUI | Hosted | Install the plugin from another supported surface | Partial in principle, for the same reason as the web GUI. |
| ChatGPT Work | Web GUI | Hosted |  | Not yet supported. Work can run hooks, but installing on the web does not deploy this plugin's hook scripts into the execution environment. |
|  | Desktop GUI | Local |  | Not verified. Work can run hooks, but this repository does not yet install or register their scripts for Work. |
|  | Desktop GUI | Hosted |  | Not yet supported. This repository does not deploy the hook scripts into a hosted session. |
|  | Mobile GUI | Hosted | Install the plugin from another supported surface | Not yet supported, as in the web GUI row. |
| Codex | Web GUI | Hosted |  | Not supported. OpenAI documents plugin use for Codex in the ChatGPT desktop app and Codex CLI, not Codex cloud. |
|  | Desktop GUI | Local | [INSTALL.md#2-codex](INSTALL.md#2-codex) | Supported after the hooks are registered. A new session loads the rules automatically; the current session needs the [manual rule reload](RELOAD.md). Settings live in `~/.unsolicited-text/settings`. |
|  | Desktop GUI | Hosted |  | Not yet supported. This repository does not install or register the hook scripts into a hosted session. |
|  | CLI | Local | [INSTALL.md#2-codex](INSTALL.md#2-codex) | Supported, as in the desktop GUI row. |
|  | IDE extension | Local |  | Not supported. The IDE extension does not support plugins. |

## ZCode

| Product | Surface | Harness execution environment | Installation | Support |
| --- | --- | --- | --- | --- |
| ZCode | Desktop GUI | Local | Add `justinkek/unsolicited-text` through Settings, Marketplace | Supported through its Claude Code plugin compatibility. Start a new session after installation, or use the [manual rule reload](RELOAD.md) in the current one. Settings live in `~/.unsolicited-text/settings`. |

## Pi

| Product | Surface | Harness execution environment | Installation | Support |
| --- | --- | --- | --- | --- |
| Pi | CLI | Local | [INSTALL.md#3-pi](INSTALL.md#3-pi) | Partial. The adapter supplies the short reply reminder and carries drift notes into the next prompt, but Pi has no session-start hook here to load or reload the full rules automatically. Its hooks read settings from `~/.unsolicited-text/settings` or `UNSOLICITED_TEXT_*` environment variables. |
