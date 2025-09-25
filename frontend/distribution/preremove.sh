#!/bin/bash
set -e

# Stop and disable the frontend service
if command -v systemctl >/dev/null 2>&1; then
    systemctl stop odigos-demo-frontend.service || true
    systemctl disable odigos-demo-frontend.service || true
fi

# Remove all dependent services
SERVICES=("coupon" "currency" "geolocation" "inventory" "membership" "pricing")

for service in "${SERVICES[@]}"; do
    echo "Removing odigos-demo-$service service..."

    # Stop and disable the service
    if command -v systemctl >/dev/null 2>&1; then
        systemctl stop "odigos-demo-$service" || true
        systemctl disable "odigos-demo-$service" || true
    fi

    # Remove the package
    if command -v dpkg >/dev/null 2>&1; then
        # DEB-based system
        dpkg -r "odigos-demo-$service" || true
    elif command -v rpm >/dev/null 2>&1; then
        # RPM-based system
        rpm -e "odigos-demo-$service" || true
    fi
done

echo "All Odigos demo services have been removed."
