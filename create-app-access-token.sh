#!/bin/sh

if [ -z $2 ]; then
	echo "Usage: $(basename $0) <Client ID> <Client secret>"
	exit 1
fi

curl -s -X POST https://id.twitch.tv/oauth2/token -d 'grant_type=client_credentials' -d "client_id=$1" -d "client_secret=$2" | jq
