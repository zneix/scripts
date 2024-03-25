#!/bin/sh

# Default options
USER_LOGIN="zneix"
DISABLE_NOTIFICATIONS="true"
FOLLOW=1

# help
usage () {
    echo "Usage: ./$(basename $0) [-fnh] [-u USER_LOGIN] [-o OAUTH] [-t TARGET] [-T TARGET_ID]" 2>&1
    echo 'Follow a user on Twitch from command line through GQL, fuck webchat.'
    echo '  -h              shows help'
    echo '  -f              follows TARGET'
    echo '  -F              unfollows TARGET'
    echo '  -n              enable stream notifications on newly created follow'
    echo '  -N              do not enable stream notifications on newly created follow'
    echo '  -u [USER_LOGIN] if pass(1) is present, USER_LOGIN can be specified to retrieve the OAuth token by invoking $(pass twilight/USER_LOGIN)'
    echo '  -o [OAUTH]      twilight OAuth token used while making GQL requests'
    echo '  -t [TARGET]     Twitch login of the user to follow. It will be first translated to corresponding user ID'
    echo '  -T [TARGET_ID]  Twitch user ID of the user to follow'
}

# Performs a gql query, needs 1 argument
make_query () {
    QUERY=$(echo $1 | sed -E 's/\s+/ /g')

    # use "https://httpbin.org/anything" for debugging
    curl -s -X POST "https://gql.twitch.tv/gql" \
        -H "Client-ID: ue6666qo983tsx6so1t0vnawi233wa" \
        -H "Authorization: OAuth $TWILIGHT_OAUTH" \
        -H "Content-Type: application/json" \
        -d "$QUERY" | jq
}

TEMP=$(getopt -o 'hfFnNu:o:t:T:' -l 'help,follow,unfollow,notifications,disable-notifications,user:,oauth:,target:,target-id:' -n 'follow.sh' -- "$@")
if [ $? -ne 0 ]; then
    echo "Invalid arguments! Check ./$(basename $0) --help"
    exit 1
fi

eval set -- "$TEMP"
unset TEMP
set -e #TODO: What does this do? 4Head

# Parsing arguments
while true; do
    case "$1" in
        '-h'|'--help')
            usage
            exit 0
        ;;
        '-f'|'--follow')
            FOLLOW=1
            shift
            continue
        ;;
        '-F'|'--unfollow')
            FOLLOW=0
            shift
            continue
        ;;
        '-n'|'--notifications') # sets notifications to !DISABLE_NOTIFICATIONS
            DISABLE_NOTIFICATIONS="false"
            shift
            continue
        ;;
        '-N'|'--disable-notifications')
            DISABLE_NOTIFICATIONS="true"
            shift
            continue
        ;;
        '-u'|'--user')
            USER_LOGIN="$2"
            shift 2
            continue
        ;;
        '-o'|'--oauth')
            TWILIGHT_OAUTH="$2"
            shift 2
            continue
        ;;
        '-t'|'--target')
            TARGET_LOGIN="$2"
            shift 2
            continue
        ;;
        '-T'|'--target-id')
            TARGET_ID="$2"
            shift 2
            continue
        ;;
        --) shift; break ;;
        *) break ;;
    esac
done

if [ -z $TWILIGHT_OAUTH ] && command -v pass > /dev/null 2>&1 && [ $USER_LOGIN ]; then
    #echo "--user [USER_LOGIN] has been specified, acquiring OAuth from pass"
    PASS_OAUTH=$(pass twilight/tv/$USER_LOGIN)
    if [ $PASS_OAUTH ]; then
        TWILIGHT_OAUTH="$PASS_OAUTH"
    fi
fi

if [ -z $TWILIGHT_OAUTH ]; then
    echo "--oauth [OAUTH] (or --user [USER_LOGIN] with OAuth under \$(pass twilight/USER_LOGIN)) needs to be set!"
    exit 2
fi

# Query translating $TARGET_LOGIN to their user id
USER_QUERY='{
    "query": "query FetchUserByLogin($login: String) {
        user(login: $login) {
            id login
        }
    }",
    "variables": {
        "login": "'$TARGET_LOGIN'"
    }
}'

# Translate TARGET_LOGIN to TARGET_ID
if [ $TARGET_LOGIN ]; then
    #echo "TARGET has been set, attempting to translate it to corresponding user id"
    #TARGET_ID=$(jq '.data[].id' -j <<< $(make_query "$USER_QUERY"))
    TARGET_ID=$(make_query "$USER_QUERY" | jq '.data[].id' -j)
fi

if [ -z $TARGET_ID ]; then
    echo "TARGET_ID needs to be set!"
    exit 2
fi

# Actual script
echo "user: $USER_LOGIN"
echo "👉 $TARGET_ID ($TARGET_LOGIN) $([ $FOLLOW -eq 1 ] && echo "❤" || echo "💔") $([ $DISABLE_NOTIFICATIONS == "true" ] && echo "🔕" || echo "🔔")"

# Mutation making $USER_LOGIN follow $TARGET_ID on Twitch
FOLLOW_QUERY='{
    "query": "mutation FollowUser($xd: FollowUserInput!) {
        followUser(input: $xd) {
            follow {
                disableNotifications
                followedAt
                user {
                    id
                    login
                }
            }
        }
    }",
    "variables": {
        "xd": {
            "disableNotifications": '$DISABLE_NOTIFICATIONS',
            "targetID": "'$TARGET_ID'"
        }
    }
}'

# Mutation making $USER_LOGIN unfollow $TARGET_ID on Twitch
UNFOLLOW_QUERY='{
    "query": "mutation UnfollowUser($xd: UnfollowUserInput!) {
        unfollowUser(input: $xd) {
            follow {
                disableNotifications
                followedAt
                user {
                    id
                    login
                }
            }
        }
    }",
    "variables": {
        "xd": {
            "targetID": "'$TARGET_ID'"
        }
    }
}'

if [ $FOLLOW -eq 1 ]; then
    #make_query "$FOLLOW_QUERY" | jq '.data.followUser.follow'
	make_query "$FOLLOW_QUERY" | jq '.'
else
    make_query "$UNFOLLOW_QUERY" | jq '.data.unfollowUser.follow'
fi
