#!/bin/bash

set -eu

SAMPLES=5

VLOG=/tmp/sv.log

mysql -u "$USER" -e "show slave status\G" | grep -e Seconds_Behind_Master | cut -d":" -f2 | xargs -I{} echo "$(date +"%s") {}" >> $VLOG

OLD=$(tail -n $SAMPLES "$VLOG" | head -n 1)
LATEST=$(tail -n $SAMPLES "$VLOG" | tail -n 1)

OLD_TIME=$(echo "$OLD" | cut -d" " -f1)
OLD_BEHIND=$(echo "$OLD" | cut -d" " -f2)

LATEST_TIME=$(echo "$LATEST" | cut -d" " -f1)
LATEST_BEHIND=$(echo "$LATEST" | cut -d" " -f2)

PERIOD=$(($LATEST_TIME - $OLD_TIME))
DISTANCE=$(($OLD_BEHIND - $LATEST_BEHIND))

VELOCITY=$(echo "$DISTANCE $PERIOD" | awk '{printf ("%f", $1/$2)}')
REMAIN=$(echo "$LATEST_BEHIND $VELOCITY" | awk '{printf ("%d", $1/$2)}')

echo Behind $LATEST_BEHIND \($(TZ="Asia/Tokyo" date --date "$LATEST_BEHIND seconds ago")\)
echo Decrease Seconds_Behind_Master $VELOCITY / sec
echo Forecast $REMAIN sec
echo Finish at $(TZ="Asia/Tokyo" date --date "$REMAIN seconds")
