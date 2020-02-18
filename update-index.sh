#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

export REDIS_PASSWORD=@REDIS_PASSWORD@

/usr/bin/python3 /opt/build_ipa_index.py
