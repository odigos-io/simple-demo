if command -v systemctl >/dev/null 2>&1; then
    systemctl stop membership.service
    systemctl disable membership.service
fi
