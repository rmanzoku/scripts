#!/bin/bash

set -u

AWS_SHARED_CREDENTIALS_FILE="$HOME/.aws/credentials"
PROFILE_PREFIX="profile "

AWSCLI="/usr/local/bin/aws"
JQ="/usr/bin/jq"

CACHE_FILE="$HOME/.cache/hosts.private"
echo "" > "$CACHE_FILE.tmp"

PROFILES=$(sed -n -e "s/^\[$PROFILE_PREFIX\(.*\)\]/\1/p" < "$AWS_SHARED_CREDENTIALS_FILE")


for p in $PROFILES
do
    $AWSCLI --profile "$p" ec2 describe-instances \
	    --filters \
	    'Name=instance-state-name,Values=running' \
	    'Name=tag:Name,Values=*' \
	    'Name=private-ip-address,Values=*' \
	| $JQ -r '.Reservations[].Instances[] | [.PrivateIpAddress,(.Tags[] | select(.Key == "Name") | .Value // ""),"# "+.InstanceId] | join(" ")' \
	      >> "$CACHE_FILE.tmp"

done

column -t < "$CACHE_FILE.tmp" > "$CACHE_FILE"


