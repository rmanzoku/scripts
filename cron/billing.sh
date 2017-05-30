#!/bin/bash

set -e #u

AWS_SHARED_CREDENTIALS_FILE=${AWS_SHARED_CREDENTIALS_FILE:-/etc/boto.cfg}
PROFILE_PREFIX="account "

AWSCLI="/usr/local/bin/aws"
JQ="/usr/bin/jq"

FIRSTDAY=$(date -d "$(date '+%m')/01/$(date '+%Y')" '+%s')
LASTDAY=$(date -d "$(date '+%m')/01/$(date '+%Y')-1days+1month" '+%s')

RESULTS=()
RESULTS+=("Account@Billing@Forecast@Timestamp")
RESULTS+=("-------@-------@--------@---------")

PROFILES=$(sed -n -e "s/^\[$PROFILE_PREFIX\(.*\)\]/\1/p" < "$AWS_SHARED_CREDENTIALS_FILE")

for p in $PROFILES
do
    RESPONCE=$($AWSCLI --profile "$p" --region us-east-1 \
	    cloudwatch get-metric-statistics \
	    --namespace "AWS/Billing" \
	    --metric-name "EstimatedCharges" \
	    --start-time "$(date -d "12 hours ago" --iso-8601="seconds")" \
	    --end-time "$(date --iso-8601="seconds")" \
	    --period 60 \
	    --statistics "Sum" \
	    --dimensions '{"Name":"Currency", "Value": "USD"}' \
		     | jq '.Datapoints | sort_by(.Timestamp) | reverse | .[0]')
    BILLING=$(echo "$RESPONCE" | $JQ -r '.Sum')
    TIMESTAMP=$(date -d "$(echo "$RESPONCE" | $JQ -r '.Timestamp')" '+%s')

    ELAPSE=$(($TIMESTAMP - $FIRSTDAY))
    PERIOD=$(($LASTDAY - $FIRSTDAY))
    FORECAST=$(echo "$BILLING $PERIOD $ELAPSE" | awk '{printf ("%0.3f", $1*$2/$3)}')

    TIMESTAMP_RESULT=$(date -d "$(echo "$RESPONCE" | $JQ -r '.Timestamp')" '+%m/%d %H:%m %Z')
    RESULTS+=("$p@\$ $BILLING@\$ $FORECAST@$TIMESTAMP_RESULT")
done

IFS=$'\n'
echo "${RESULTS[*]}" | column -t -s"@" | post2slack --emoji :dollar: -u Billing -m "*AWS Billing report $(TZ=Asia/Tokyo date +"%Y/%m/%d")*"
