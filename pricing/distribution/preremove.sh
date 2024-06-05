if command -v systemctl >/dev/null 2>&1; then
    systemctl stop odigos-demo-pricing.service
    systemctl disable odigos-demo-pricing.service
fi
