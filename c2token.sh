#!/usr/bin/sh

C2_SETTINGS="$HOME/.local/share/chatterino/Settings/settings.json"
USER="$1"
if [ -z $USER ]; then
	USER=$(jq -r '.accounts.current' "$C2_SETTINGS")
fi

grep -A3 "\"username\": \"$USER\"," "$C2_SETTINGS" | grep oauthToken | sed -r 's/.+: "(.{30})",?/\1/g'
