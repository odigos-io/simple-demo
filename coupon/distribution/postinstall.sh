if command -v systemctl >/dev/null 2>&1; then
    systemctl enable odigos-demo-coupon.service
    systemctl start odigos-demo-coupon.service
fi
