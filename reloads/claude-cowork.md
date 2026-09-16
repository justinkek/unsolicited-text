The hooks run here, so the rules are printed at session start. Print them again
with the loader the plugin carries:

    find ~ -name load-rules.sh 2>/dev/null

    printf '{}' | <the path it finds>
