if command -v systemctl >/dev/null 2>&1; then
    systemctl stop odigos-demo-membership.service
    systemctl disable odigos-demo-membership.service
fi
