    codex plugin remove unsolicited-text@unsolicited-text

Then delete the `[[hooks.*]]` blocks you added to `~/.codex/config.toml`. You
registered them by hand because Codex does not run a plugin's own hooks yet, and
dropping the plugin leaves them behind, still naming scripts that are gone.

`~/.unsolicited-text` stays, settings and all. Remove it with `rm -rf
~/.unsolicited-text` where nothing should be left.
