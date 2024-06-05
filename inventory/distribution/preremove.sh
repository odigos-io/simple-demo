if command -v systemctl >/dev/null 2>&1; then
    systemctl stop odigos-demo-inventory.service
    systemctl disable odigos-demo-inventory.service
fi
