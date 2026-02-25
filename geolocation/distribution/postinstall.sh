#!/usr/bin/env bash
set -e

chown -R odigos:odigos /opt/odigos-demo-geolocation
chmod +x /opt/odigos-demo-geolocation/binaries/*

# Install gems for the host's Ruby (package does not ship vendor/bundle; avoids Ruby version mismatch)
if command -v bundle >/dev/null 2>&1; then
  (
    cd /opt/odigos-demo-geolocation
    mkdir -p /opt/odigos-demo-geolocation/vendor/bundle
    mkdir -p /opt/odigos-demo-geolocation/.home
    chown odigos:odigos /opt/odigos-demo-geolocation/vendor/bundle /opt/odigos-demo-geolocation/.home
    export BUNDLE_GEMFILE=/opt/odigos-demo-geolocation/Gemfile
    export BUNDLE_PATH=/opt/odigos-demo-geolocation/vendor/bundle
    export GEM_HOME=/opt/odigos-demo-geolocation/vendor/bundle
    export GEM_PATH=/opt/odigos-demo-geolocation/vendor/bundle
    export BUNDLE_DEPLOYMENT=1
    export BUNDLE_WITHOUT=development:test
    export HOME=/opt/odigos-demo-geolocation/.home
    # Install Bundler 2.6 into app's vendor/bundle so the service (GEM_PATH=vendor/bundle) finds it
    sudo -u odigos env HOME="$HOME" GEM_HOME="$BUNDLE_PATH" GEM_PATH="$BUNDLE_PATH" gem install bundler -v '~> 2.6' --no-document
    sudo -u odigos env HOME="$HOME" BUNDLE_GEMFILE="$BUNDLE_GEMFILE" BUNDLE_PATH="$BUNDLE_PATH" \
      GEM_HOME="$BUNDLE_PATH" GEM_PATH="$BUNDLE_PATH" \
      BUNDLE_DEPLOYMENT=1 BUNDLE_WITHOUT=development:test \
      bundle config set --local deployment true
    sudo -u odigos env HOME="$HOME" BUNDLE_GEMFILE="$BUNDLE_GEMFILE" BUNDLE_PATH="$BUNDLE_PATH" \
      GEM_HOME="$BUNDLE_PATH" GEM_PATH="$BUNDLE_PATH" \
      BUNDLE_DEPLOYMENT=1 BUNDLE_WITHOUT=development:test \
      bundle config set --local without 'development test'
    sudo -u odigos env HOME="$HOME" BUNDLE_GEMFILE="$BUNDLE_GEMFILE" BUNDLE_PATH="$BUNDLE_PATH" \
      GEM_HOME="$BUNDLE_PATH" GEM_PATH="$BUNDLE_PATH" \
      BUNDLE_DEPLOYMENT=1 BUNDLE_WITHOUT=development:test \
      bundle install
  )
fi

if command -v systemctl >/dev/null 2>&1; then
  systemctl daemon-reload
  systemctl enable odigos-demo-geolocation.service
  systemctl start odigos-demo-geolocation.service
fi
