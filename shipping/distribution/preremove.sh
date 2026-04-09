if command -v systemctl >/dev/null 2>&1; then
    systemctl stop odigos-demo-shipping.service
    systemctl disable odigos-demo-shipping.service
fi
