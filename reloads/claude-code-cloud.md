    printf '{}' | /opt/unsolicited-text/distributions/claude-code-cloud/hooks/load-rules.sh

The container is rebuilt for every session, so a setting written to the file
lasts as long as this session does. To keep one, set an `UNSOLICITED_TEXT_`
environment variable on the cloud environment, see
[the docs](https://code.claude.com/docs/en/cloud-environments#set-environment-variables).
