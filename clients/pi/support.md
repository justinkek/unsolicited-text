The adapter runs the same hooks as everywhere else: the rules are printed when
the first turn of a session starts, a long reply is noted and the note is
replayed on the next prompt, and a new version is announced. Settings are kept
in `~/.unsolicited-text` and outlive the session.

Last verified at 0.3.14: a new session opened with the rules, each turn carried
the reminder, a ten-line reply came back as a note naming the ceiling, and the
settings written by an earlier session were still in force.

The skills arrive as well: `package.json` names them under `pi.skills`, beside
the extension. Verified at 0.6.5: `/skill:settings` was listed as coming from
this package, and running it printed the settings table, with a setting written
earlier shown as set.

A session there cannot say which version it is running, and the pages for
updating and uninstalling say what to run by hand.
