#!/bin/sh
# Run after package files are removed so systemd drops the deleted unit
systemctl daemon-reload 2>/dev/null || true
