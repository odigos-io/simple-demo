#!/bin/sh
set -e

# Create odigos user for consistency with other Odigos demo packages
getent passwd odigos >/dev/null || useradd --system --user-group --no-create-home --shell /sbin/nologin odigos
