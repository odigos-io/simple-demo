if command -v systemctl >/dev/null 2>&1; then
    systemctl enable odigos-demo-currency.service
    systemctl start odigos-demo-currency.service
fi
