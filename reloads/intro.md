# Reloading the rules into a running session

(audience: humans)

This only applies where the plugin's hooks run. Check 🔗
[product compatibility](COMPATIBILITY.md) for your product and surface.

The rules are printed once, at session start. A change to a setting or a newer
version installed mid-session reaches the session only when they are printed
again, from the same script:

    printf '{}' | <path to load-rules.sh>

The script reads a line on standard input and prints nothing without one, so it
waits forever if the pipe is left off. The print opens by saying it replaces the
unsolicited-text rules the session already read, and nothing else.
