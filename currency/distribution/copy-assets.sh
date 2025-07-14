#!/usr/bin/env bash
set -e

mkdir -p ./dist/app
# Copy source files + vendor tree that were built in the container
docker cp tc:/app/index.php          ./dist/app/
docker cp tc:/app/dice.php           ./dist/app/
docker cp tc:/app/vendor             ./dist/app/vendor
# Make sure file permissions are sane
find ./dist/app -type f -exec chmod 0644 {} \;
find ./dist/app -type d -exec chmod 0755 {} \;
