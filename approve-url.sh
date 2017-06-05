#!/bin/bash

set -e

# AWS_PROFILE
AWS_SHARED_CREDENTIALS_FILE=${AWS_SHARED_CREDENTIALS_FILE:-/etc/boto.cfg}
AWS_CLI="/usr/local/bin/aws"

if [ "x$AWS_PROFILE" = "x" ]; then
    echo set AWS_PROFILE
    exit
fi

S3_BUCKET=$($AWS_CLI s3 ls | peco | cut -d" " -f3)

for f in $($AWS_CLI s3 ls "s3://$S3_BUCKET" | grep "$(date +%Y-%m-%d)" | cut -d " " -f 9)
do
    $AWS_CLI s3 cp "s3://$S3_BUCKET/$f" - | grep "^https"
done
