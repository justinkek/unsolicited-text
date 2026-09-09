# Reloading the rules into a running session

The rules are printed once, at session start. A change to a setting or a newer
version installed mid-session reaches the session only when they are printed
again, from the same script:

    printf '{}' | <path to load-rules.sh>

The script reads a line on standard input and prints nothing without one, so it
waits forever if the pipe is left off. The print opens by saying it replaces the
rules the session already read.

## Where the script is, by install route

| Route | Path |
| --- | --- |
| Cloud session | `/opt/unsolicited-text/hooks/load-rules.sh` |
| Claude Code, ZCode | under the plugin directory - the hook registers it as `${CLAUDE_PLUGIN_ROOT}/hooks/load-rules.sh`, and a shell cannot read that variable |
| Codex | the path written by hand in `~/.codex/config.toml` |
| Pi | the checkout the shim names |

On any route, the file can be found rather than guessed:

    find ~/.claude ~/.codex ~/.pi /opt -name load-rules.sh 2>/dev/null

A restart is the last resort, for a session where the file cannot be found.
