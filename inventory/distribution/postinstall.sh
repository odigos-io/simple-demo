# Reload unit, enable on boot, and start/restart so install runs immediately and upgrade runs the new version
if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload
    systemctl enable odigos-demo-inventory.service
    systemctl restart odigos-demo-inventory.service
fi
