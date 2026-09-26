Every hook runs: the rules are printed when a session starts, a long reply is
noted and the note is replayed on the next prompt, and a new version is
announced. The settings are written inside the container, which is rebuilt for
every session, so a setting you want to keep goes in an `UNSOLICITED_TEXT_`
environment variable on the cloud environment.

Last verified at 0.3.6: the install script left the skills under
`~/.claude/skills`, a command with the `unsolicited-text-` prefix for each, the
hooks registered once each, and `~/.unsolicited-text/state` written.
