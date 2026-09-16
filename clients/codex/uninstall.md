    codex plugin remove unsolicited-text@unsolicited-text

Then delete the `[[hooks.*]]` blocks you added to `~/.codex/config.toml`. You
registered them by hand because Codex does not run a plugin's own hooks yet, and
dropping the plugin leaves them behind, still naming scripts that are gone.

    rm -rf ~/.unsolicited-text

That takes the settings and the state with it, so nothing is left.
