    claude plugin marketplace update unsolicited-text
    claude plugin update unsolicited-text@unsolicited-text

A session already running holds the old copy, so restart it or run
`/reload-plugins`.

If the version does not move, the marketplace snapshot is stale: the first of
the two commands failed or was skipped.

If the version does not move, the marketplace snapshot still names where the
plugin used to live. Install it again from the refreshed one:

    claude plugin uninstall unsolicited-text@unsolicited-text
    claude plugin install unsolicited-text@unsolicited-text

Your settings are in `~/.unsolicited-text` and no install touches them.

<!-- The paragraph above, from "If the version does not move", exists for the
move in 0.2.0. Delete it at 0.3.0. -->
