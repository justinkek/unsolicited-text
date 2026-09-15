# unsolicited-text for Claude Chat and Cowork

(audience: humans)

Everything this install needs is in this folder. It is built from the
repository root by `build`, so edit the sources there rather than these files.

## Installing

Open the plus menu beside the message box, then Plugins, then Browse plugins,
and install unsolicited-text. Its skills appear under the plugin's own entry
in that menu.

No hook runs on either, so the reply rules never reach a session and a setting
changes nothing. Ask for the reload skill in your first message and it prints
the rules; a preference or a custom style holding `rules/reply-shape.md` does it
without asking.
Nothing is installed from this folder. The client copies these skills out of the plugin, and they are all a session there receives.
