#!/bin/bash

AWS="/usr/local/bin/aws"

for bucket in $($AWS s3 ls | cut -d" " -f3)
do
    echo "  Bucket Name: $bucket"
    $AWS s3 ls "$bucket" --recursive --human-readable --summarize | tail -n2
done
