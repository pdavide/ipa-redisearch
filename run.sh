#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


export REDIS_ARGS="$@"

/setup.sh

exec /usr/bin/supervisord -n -c /etc/supervisord.conf
