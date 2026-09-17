# unsolicited-text for Claude

(audience: humans)

## What works

### Claude Code, on your machine

Every hook runs: the rules are printed when a session starts, a long reply is
noted and the note is replayed on the next prompt, and a new version is
announced. Settings are kept in `~/.unsolicited-text` and outlive the session.

### ZCode

Every hook runs, as on Claude Code, since it is the same install. Settings are
kept in `~/.unsolicited-text` and outlive the session.

Last verified at 0.3.7: installed through Settings, Plugin Management, and the
bundled command line lists it as enabled, with seven hooks and four skills on
disk under `~/.zcode`. A session already running does not have the hooks, so
the rules arrive in the next one. Nothing else has been checked here yet.

### Claude Chat

No hook runs. The rules arrive only when the reload skill prints them, so
nothing prints them again once they fall out of the conversation, nothing notes
a long reply, and a new version goes unannounced. A setting holds for the
conversation it is asked for and no longer.

Last verified at 0.3.4, on the mobile app, on the web and in the desktop app: the four skills are there, the
reload skill prints the rules, a setting holds for the conversation, and
nothing has written `~/.unsolicited-text`. A session cannot tell the three
surfaces apart, so the signature names the client and stops there.

### Cowork

Every hook but one runs: a long reply is noted and the note is replayed on the
next prompt, a new version is announced, and a setting takes effect at once.
The settings are written inside the session's container, which is discarded
when the session ends.

The rules are not printed when a conversation starts. Ask for the reload skill
in your first message, or put them in a preference or a custom style.

Last verified at 0.3.5 on the mobile app: a new conversation carried the reply reminder
and no rules, the reload skill printed them, a ceiling written to the settings
file was enforced, and the note about a long reply came back on the next
message naming that ceiling.

## Installing

### Claude Code, on your machine

    claude plugin marketplace add justinkek/unsolicited-text
    claude plugin install unsolicited-text@unsolicited-text

(audience: agents) Check whether `SKIP_PLUGIN_MARKETPLACE` is set before using the install instructions above. If it is set, the session is a cloud one: say so, and use the cloud install instructions at 🔗 [distributions/claude-code-cloud](https://github.com/justinkek/unsolicited-text/tree/main/distributions/claude-code-cloud) instead.

### ZCode

Open Settings, then Plugin Management, then Discover, and add
`justinkek/unsolicited-text` with the `+` button. It installs the same plugin
as Claude Code does.

The hooks load when a session starts, so the session you installed from does
not have them: open a new one, or reload the plugins in this one.

The bundled command line cannot install a plugin, but it does say what is
installed:

    node /Applications/ZCode.app/Contents/Resources/glm/zcode.cjs plugins list

### Claude Chat

Open the plus menu beside the message box, then Plugins, then Browse plugins,
and install unsolicited-text. Its skills appear under the plugin's own entry
in that menu.

No hook runs in Chat, so the rules never reach a session on their own. Ask for
the reload skill in your first message and it prints them; a preference or a
custom style holding `rules/reply-shape.md` does it without asking.

Nothing reads a settings file either, so a setting you ask for lasts as long as
that conversation does.

### Cowork

Open the plus menu beside the message box, then Plugins, then Browse plugins,
and install unsolicited-text. Its skills appear under the plugin's own entry
in that menu.

The hooks run here, but the rules are not printed when a conversation starts,
so ask for the reload skill in your first message.

Settings are written inside the session's container, which is discarded when the
session ends.

## Updating

### Claude Code, on your machine

    claude plugin marketplace update unsolicited-text
    claude plugin update unsolicited-text@unsolicited-text

Load the new copy into a session already running by restarting it or running
`/reload-plugins`.

If the version does not move, the marketplace snapshot is stale: the first of
the two commands failed or was skipped.

Your settings are in `~/.unsolicited-text` and no install touches them.

### ZCode

Update it under Settings, Plugin Management, where it was added. The bundled
command line cannot install or update a plugin, so the only way in is the
window.

Your settings are in `~/.unsolicited-text` and no update touches them.

### Claude Chat

Open the plus menu, then Plugins, then Manage plugins, and update it there.

### Cowork

Open the plus menu, then Plugins, then Manage plugins, and update it there.

## Uninstalling

### Claude Code, on your machine

    claude plugin uninstall unsolicited-text@unsolicited-text
    claude plugin marketplace remove unsolicited-text
    rm -rf ~/.unsolicited-text

The last of the three takes the settings and the state with it, so nothing is
left.

### ZCode

Remove it under Settings, Plugin Management, where it was added.

    rm -rf ~/.unsolicited-text

That takes the settings and the state with it, so nothing is left.

### Claude Chat

Open the plus menu, then Plugins, then Manage plugins, and remove it there.

Nothing here writes `~/.unsolicited-text`, so the removal leaves nothing behind.

### Cowork

Open the plus menu, then Plugins, then Manage plugins, and remove it there.

`~/.unsolicited-text` is inside the session's container, which is discarded when
the session ends, so nothing is left after that.

## Note

Generated by ./build. Edit the sources at the repository root instead.
