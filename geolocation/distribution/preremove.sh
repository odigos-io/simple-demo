if command -v systemctl >/dev/null 2>&1; then
    systemctl stop odigos-demo-geolocation.service
    systemctl disable odigos-demo-geolocation.service
fi
