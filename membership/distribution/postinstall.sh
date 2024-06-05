if command -v systemctl >/dev/null 2>&1; then
    systemctl enable odigos-demo-membership.service
    systemctl start odigos-demo-membership.service
fi
