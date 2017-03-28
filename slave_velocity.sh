#!/bin/bash

set -eu

LOGFILE="$HOME/velocity.log"
SAMPLES=5

mysql -u "$USER" -e "show slave status\G" | grep -e Seconds_Behind_Master | cut -d":" -f2 | xargs -I{} echo "$(date +"%s") {}" >> $LOGFILE

OLD=$(tail -n $SAMPLES "$LOGFILE" | head -n 1)
LATEST=$(tail -n $SAMPLES "$LOGFILE" | tail -n 1)

OLD_TIME=$(echo "$OLD" | cut -d" " -f1)
OLD_BEHIND=$(echo "$OLD" | cut -d" " -f2)

LATEST_TIME=$(echo "$LATEST" | cut -d" " -f1)
LATEST_BEHIND=$(echo "$LATEST" | cut -d" " -f2)

PERIOD=$(($LATEST_TIME - $OLD_TIME))
DISTANCE=$(($OLD_BEHIND - $LATEST_BEHIND))

VELOCITY=$(echo "$DISTANCE $PERIOD" | awk '{printf ("%f", $1/$2)}')
REMAIN=$(echo "$LATEST_BEHIND $VELOCITY" | awk '{printf ("%d", $1/$2)}')

echo Decrease Seconds_Behind_Master $VELOCITY / sec
echo Forecast $REMAIN sec
echo Finish at $(TZ="Asia/Tokyo" date --date "$REMAIN seconds")
