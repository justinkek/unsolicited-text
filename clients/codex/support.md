Every hook runs. The plugin carries its own hook registrations and Codex reads
them from the manifest, so nothing is written into the config file by hand. The
settings are kept in `~/.unsolicited-text` and outlive the session.

Codex runs no hook until it has been reviewed, so the rules do not arrive until
`/hooks` has been opened and the seven commands trusted.

Last verified at 0.3.14, in the command line: a session held to the ceiling in
the settings file rather than the default, and a one-line reply against a
ceiling of zero was written to
`~/.unsolicited-text/state/notes/<session>.stop-notes` as
`[reply-shape] The last reply ran 1 line of prose against a ceiling of 0.`

A session there will not quote what a hook gave it, calling that a developer
instruction, and it will not write past the ceiling even when told to. Neither
is a fault: it is the rules working. It does mean a check has to lower the
ceiling rather than ask for a long reply.
