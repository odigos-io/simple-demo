#!/usr/bin/env bash
set -euo pipefail

# Stop and disable the currency service
if command -v systemctl >/dev/null 2>&1; then
    systemctl stop odigos-demo-currency.service || true
    systemctl disable odigos-demo-currency.service || true
fi
