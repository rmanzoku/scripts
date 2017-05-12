#/bin/bash

set -eu

DOMAIN="$1"
ENDDATE=$(openssl s_client -connect "$DOMAIN":443 -servername "$DOMAIN" </dev/null 2>/dev/null \
		 | openssl x509 -enddate -noout \
		 | cut -d'=' -f2 )
LEFT=$(date +"%s" --date="$ENDDATE" | gawk '{printf("%d\n",($0-systime())/86400-1/86400+1)}')

printf "Domain:%s\tEnddate:%s\tLeft:%s\n" "$DOMAIN" "$ENDDATE" "$LEFT"
