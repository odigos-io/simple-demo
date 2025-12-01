#!/usr/bin/env bash
set -e

# For Go services, we need to copy the binary
mkdir -p ./dist/app
docker cp tc-membership:/membership ./dist/app/odigos-demo-membership
