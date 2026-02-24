#!/usr/bin/env bash
set -e
# Meta-package: do not enable or start; user runs systemctl start/stop odigos-demo as needed
if command -v systemctl >/dev/null 2>&1; then
  systemctl daemon-reload
fi
