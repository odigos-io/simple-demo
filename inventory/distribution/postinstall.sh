if command -v systemctl >/dev/null 2>&1; then
    systemctl enable odigos-demo-inventory.service
    systemctl start odigos-demo-inventory.service
fi
