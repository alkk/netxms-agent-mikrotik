#!/usr/bin/dumb-init /bin/sh

set -e

if [[ `id -u` -eq 0 ]]; then
   exec su-exec netxms "$@"
else
   exec "$@"
fi
