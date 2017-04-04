#!/bin/bash

set -eu

AWS_SHARED_CREDENTIALS_FILE="$HOME/.aws/credentials"
PROFILE_PREFIX="profile "

GET_BILLING="/home/rmanzoku/src/github.com/rmanzoku/pypractice/billing.py"
JQ="/usr/bin/jq"

NUMOFDAYS=$(date -d "$(date '+%m')/01/$(date '+%Y')-1days+1month" '+%d')
TODAY=$(date '+%d')

RESULTS=()
RESULTS+=("Account:Billing:Forecast")
RESULTS+=("-------:-------:--------")

PROFILES=$(sed -n -e "s/\[$PROFILE_PREFIX\(.*\)\]/\1/p" < "$AWS_SHARED_CREDENTIALS_FILE")


for p in $PROFILES
do
    BILLING=$($GET_BILLING "$PROFILE_PREFIX$p" | $JQ -r '.billing')
    FORECAST=$(echo "$BILLING $NUMOFDAYS $TODAY" | awk '{printf ("%0.3f", $1*$2/$3)}')
    RESULTS+=("$p:\$ $BILLING: \$ $FORECAST")
done

IFS=$'\n'
echo "${RESULTS[*]}" | column -t -s":" | post2slack --emoji dollar -u Billing -m "AWS Billing on $(TZ=Asia/Tokyo date +"%Y/%m/%d %H:%M %Z")"
