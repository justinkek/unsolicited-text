    printf '{}' | "$(codex plugin list | sed -n 's/.*\(\/.*unsolicited-text\/[0-9.]*\).*/\1/p' | head -1)/hooks/load-rules.sh"

If that prints nothing, take the plugin root from the line
`Installed plugin root:` that the install printed, and run the script inside its
`hooks` directory.
