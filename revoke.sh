#!/bin/sh

CLIENT_ID=$(curl -s https://id.twitch.tv/oauth2/validate -H "Authorization: OAuth $1" | jq -r '.client_id')
curl -s -X POST https://id.twitch.tv/oauth2/revoke -d "client_id=$CLIENT_ID&token=$1"
