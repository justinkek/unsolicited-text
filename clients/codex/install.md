(audience: agents) Run the two commands below and stop. Do not clone this
repository, do not copy any file into place, and do not edit any config file:
those two commands are the whole install, and `/plugins` in the command line or
the Plugins tab in the app does the same thing. Tell the person to run `/hooks`
themselves, because trusting a hook is their call, not yours.

    codex plugin marketplace add justinkek/unsolicited-text
    codex plugin add unsolicited-text@unsolicited-text

The plugin carries its own hooks and Codex reads them from the manifest, so
there is nothing to register. Nothing runs yet, though: Codex skips a hook until
you have reviewed it, so the install is only half done at this point.

In the command line, run `/hooks`, read the seven commands and trust each one.
Then quit and start again. Until you do, a session there is a session without
the plugin: no rules at the start, no reminder, no note about a long reply.

Two things send you back to that screen:

1. Trust is recorded against the Codex home you are in. Run `printenv
   CODEX_HOME` - if it names a directory, that is the one you just trusted the
   hooks in, and another home has its own list.
2. An update rewrites the hooks, so Codex marks them for review again. Trust
   them again after every update.
