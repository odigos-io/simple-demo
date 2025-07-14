#!/usr/bin/env bash
set -e

if command -v systemctl >/dev/null 2>&1; then
  systemctl stop    odigos-demo-geolocation.service || true
  systemctl disable odigos-demo-geolocation.service || true
  systemctl daemon-reload
fi
