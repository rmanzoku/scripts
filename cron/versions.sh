#!/bin/bash

set -eu
TMPDIR=$HOME/log/versions

if [ ! -d "$TMPDIR" ]; then
    mkdir -p "$TMPDIR"
fi

for i in $(check-versions)
do

    touch "$TMPDIR/$i"
    check-versions "$i" | head -n 2 > "$TMPDIR/$i.new"

    if ! diff -q "$TMPDIR/$i" "$TMPDIR/$i.new" > /dev/null; then
	post2slack --emoji :white_check_mark: -u VersionCheck -m "$i" < "$TMPDIR/$i.new"
    fi

    mv "$TMPDIR/$i.new" "$TMPDIR/$i"
done
