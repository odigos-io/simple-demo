if command -v systemctl >/dev/null 2>&1; then
    systemctl enable odigos-demo-pricing.service
    systemctl start odigos-demo-pricing.service
fi
