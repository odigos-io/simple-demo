# App dir owned by odigos so the service (User=odigos) and pool workers can read it
chown -R odigos:odigos /opt/odigos-demo-currency
if command -v systemctl >/dev/null 2>&1; then
    systemctl enable odigos-demo-currency.service
    systemctl start odigos-demo-currency.service
fi
