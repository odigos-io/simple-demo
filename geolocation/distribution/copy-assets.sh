#!/usr/bin/env bash
set -e

IMAGE_TAG="geolocation:release"
PLATFORM="linux/amd64"

echo "⇢ Building $IMAGE_TAG ($PLATFORM)…"
docker buildx build --no-cache --load --platform "$PLATFORM" -t "$IMAGE_TAG" .

CID=$(docker create --platform "$PLATFORM" "$IMAGE_TAG")
echo "⇢ Extracting /rails and /usr/local …"
rm -rf dist/odigos-demo-geolocation
docker cp "$CID":/rails      dist/odigos-demo-geolocation      # app + gems
docker cp "$CID":/usr/local  dist/odigos-demo-geolocation/embedded-ruby
docker rm "$CID"

echo "✓ dist/odigos-demo-geolocation ready"
