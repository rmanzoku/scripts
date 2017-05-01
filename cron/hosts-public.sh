#!/bin/bash

set -u

export AWS_SHARED_CREDENTIALS_FILE=${AWS_SHARED_CREDENTIALS_FILE:-/etc/boto.cfg}
PROFILE_PREFIX="profile "

AWSCLI="/usr/local/bin/aws"
JQ="/usr/bin/jq"

CACHE_DIR="/tmp/cache"
CACHE_FILE="$CACHE_DIR/hosts.public"

if [ ! -e $CACHE_DIR ]; then
    mkdir -p $CACHE_DIR
fi

echo "" > "$CACHE_FILE.tmp"

PROFILES=$(sed -n -e "s/^\[$PROFILE_PREFIX\(.*\)\]/\1/p" < "$AWS_SHARED_CREDENTIALS_FILE")


for p in $PROFILES
do
    $AWSCLI --profile "$p" ec2 describe-instances \
	    --filters \
	    'Name=instance-state-name,Values=running' \
	    'Name=tag:Name,Values=*' \
	    'Name=ip-address,Values=*' \
	| $JQ -r '.Reservations[].Instances[] | [.PublicIpAddress,(.Tags[] | select(.Key == "Name") | .Value // ""),"# "+.InstanceId] | join(" ")' \
	      >> "$CACHE_FILE.tmp"

done

sort -t" " -k2 "$CACHE_FILE.tmp" | column -t > "$CACHE_FILE"
