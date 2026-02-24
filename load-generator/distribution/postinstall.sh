#!/usr/bin/env bash
set -e
# Service is disabled by default and not started; user can enable/start via systemctl or run binary from shell
if command -v systemctl >/dev/null 2>&1; then
  systemctl daemon-reload
fi
