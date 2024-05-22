if command -v systemctl >/dev/null 2>&1; then
    systemctl enable membership.service
    systemctl start membership.service
fi
