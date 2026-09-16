    printf '{}' | /opt/unsolicited-text/distributions/claude-code-cloud/hooks/load-rules.sh

The container is rebuilt for every session, so a setting you want to keep goes
in an `UNSOLICITED_TEXT_` environment variable on the cloud environment.
