if command -v systemctl >/dev/null 2>&1; then
    systemctl stop odigos-demo-frontend.service
    systemctl disable odigos-demo-frontend.service
fi
