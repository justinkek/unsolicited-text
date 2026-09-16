The hook registers the script as `${CLAUDE_PLUGIN_ROOT}/hooks/load-rules.sh`, and
a shell cannot read that variable, so find the file instead:

    find ~ -name load-rules.sh 2>/dev/null
