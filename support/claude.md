Claude Code and ZCode run every hook: the rules are printed when a session
starts, a long reply is noted and the note is replayed on the next prompt, and
a new version is announced. Settings are kept in `~/.unsolicited-text` and
outlive the session.

Cowork runs every hook too, and writes the settings inside the session's
container, which is discarded when the session ends.

Claude Chat runs no hook. The rules arrive only when the reload skill prints
them, so nothing prints them again once they fall out of the conversation,
nothing notes a long reply, and a new version goes unannounced. A setting holds
for the conversation it is asked for and no longer.
