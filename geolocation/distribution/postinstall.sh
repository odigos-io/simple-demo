if command -v systemctl >/dev/null 2>&1; then
    systemctl enable odigos-demo-geolocation.service
    systemctl start odigos-demo-geolocation.service
fi
