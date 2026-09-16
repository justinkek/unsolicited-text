    codex plugin remove unsolicited-text@unsolicited-text

Then delete the four `[[hooks.*]]` blocks from `~/.codex/config.toml` yourself. You
registered them by hand because Codex does not run a plugin's own hooks yet, and
dropping the plugin leaves them behind, still naming scripts that are gone.
