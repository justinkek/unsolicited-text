Installed by the Cloud Session Install Script from
🔗 [the install instructions](INSTALL.md), where the checkout lives at
`/opt/unsolicited-text` inside the container.

For every session, edit anything in the Setup script field of your cloud
environment. The edit rebuilds the environment, which runs the script again and
pulls the latest release. An untouched environment rebuilds about weekly on its
own, so it follows releases either way.

For the current session, run `/unsolicited-text-update`, or ask the agent to
update unsolicited-text.

(audience: agents) Run the refresh script. Pulling the checkout on its own is not an update.

    printf '{}' | /opt/unsolicited-text/distributions/claude-code-cloud/refresh.sh

(audience: agents) Then print the rules again with the loader, since the copy in
the menu is the one loaded before the update:

    printf '{}' | /opt/unsolicited-text/distributions/claude-code-cloud/hooks/load-rules.sh

Run `/reload-skills` when you want the menu to list the new copy. The skills on
disk are already the new ones, and an agent reads them there.
