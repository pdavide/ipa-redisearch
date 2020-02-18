#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


export REDIS_ARGS="$@"

/setup.sh

sed -i -e s/@REDIS_PASSWORD@/"$REDIS_PASSWORD"/g /update-index.sh

exec /usr/bin/supervisord -n -c /etc/supervisord.conf
