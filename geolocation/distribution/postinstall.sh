#!/usr/bin/env bash
set -e

APP=/opt/odigos-demo-geolocation/embedded-ruby

# --- make Ruby’s original prefix visible -------------------------------
ln -sfn "${APP}/bin"  /usr/local/bin
ln -sfn "${APP}/lib"  /usr/local/lib
ln -sfn "${APP}/lib/ruby" /usr/local/lib/ruby

# create a harmless home so Bundler stops warning
mkdir -p /home/odigos
chown odigos:odigos /home/odigos

# reload unit files on upgrade
command -v systemctl >/dev/null && systemctl daemon-reload
