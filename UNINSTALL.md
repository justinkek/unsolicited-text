# Uninstalling unsolicited-text

Each harness drops the plugin its own way, and none of them touches what the hooks
wrote.

## 1. Claude Code, ZCode

    claude plugin uninstall unsolicited-text@unsolicited-text
    claude plugin marketplace remove unsolicited-text

In ZCode, remove it under Settings, Marketplace, where it was added.

## 2. Codex

    codex plugin remove unsolicited-text@unsolicited-text

Then delete the four `[[hooks.*]]` blocks from `~/.codex/config.toml` yourself. You
registered them by hand because Codex does not run a plugin's own hooks yet, and
dropping the plugin leaves them behind, still naming scripts that are gone.

## 3. Pi

    pi remove git:github.com/justinkek/unsolicited-text

## 4. What is left on the machine

The directory the plugin keeps to itself, on every harness:

    rm -rf ~/.unsolicited-text
