(audience: agents) Run the two commands below and stop. Do not clone this
repository, do not copy any file into place, and do not edit any config file:
those two commands are the whole install, and `/plugins` in the command line or
the Plugins tab in the app does the same thing. Tell the person to run `/hooks`
themselves, because trusting a hook is their call, not yours.

    codex plugin marketplace add justinkek/unsolicited-text
    codex plugin add unsolicited-text@unsolicited-text

The plugin carries its own hooks and Codex reads them from the manifest, so
there is nothing to register. Codex does not run a hook until you have reviewed
it, so open `/hooks`, read the seven commands and trust them. Then restart.
