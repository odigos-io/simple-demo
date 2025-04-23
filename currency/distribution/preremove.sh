if command -v systemctl >/dev/null 2>&1; then
    systemctl stop odigos-demo-currency.service
    systemctl disable odigos-demo-currency.service
fi
