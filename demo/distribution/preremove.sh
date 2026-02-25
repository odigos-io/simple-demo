#!/usr/bin/env bash
set -euo pipefail
if command -v systemctl >/dev/null 2>&1; then
  systemctl stop odigos-demo.service || true
  systemctl disable odigos-demo.service || true
  systemctl daemon-reload
fi
