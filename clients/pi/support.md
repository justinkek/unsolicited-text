The adapter runs the same hooks as everywhere else: the rules are printed when
the first turn of a session starts, a long reply is noted and the note is
replayed on the next prompt, and a new version is announced. Settings are kept
in `~/.unsolicited-text` and outlive the session.

Last verified at 0.3.14: a new session opened with the rules, each turn carried
the reminder, a ten-line reply came back as a note naming the ceiling, and the
settings written by an earlier session were still in force.

Pi loads its own skills from `~/.agents/skills`, and installing the extension
puts nothing there, so the four skills every other client gets are missing. A
session there cannot say which version it is running, and the pages for
changing a setting, updating and uninstalling say what to run by hand.
