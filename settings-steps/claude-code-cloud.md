The hooks read the file every time they run, so a ceiling takes effect at once,
and the reload skill prints the rules again.

The file is written inside the container, which is rebuilt for every session, so
a setting you want to keep goes in an `UNSOLICITED_TEXT_` environment variable on
the cloud environment, see
[the docs](https://code.claude.com/docs/en/cloud-environments#set-environment-variables).
