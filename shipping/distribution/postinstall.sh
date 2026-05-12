if command -v systemctl >/dev/null 2>&1; then
    systemctl enable odigos-demo-shipping.service
    systemctl start odigos-demo-shipping.service
fi
