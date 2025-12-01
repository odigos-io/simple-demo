#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to validate package contents
validate_package_contents() {
    local service="$1"
    print_status "Validating $service package contents..."

    case "$service" in
        "frontend")
            # Check Java application files
            if [ -d "/opt/odigos-demo-frontend" ]; then
                print_success "✓ Frontend application directory exists"
                if [ -f "/opt/odigos-demo-frontend/frontend.jar" ]; then
                    print_success "✓ Frontend JAR file exists"
                else
                    print_error "✗ Frontend JAR file missing"
                fi
            else
                print_error "✗ Frontend application directory missing"
            fi

            # Check systemd service
            if [ -f "/lib/systemd/system/odigos-demo-frontend.service" ]; then
                print_success "✓ Frontend systemd service exists"
            else
                print_error "✗ Frontend systemd service missing"
            fi
            ;;

        "currency")
            # Check PHP application files
            if [ -d "/opt/odigos-demo-currency" ]; then
                print_success "✓ Currency application directory exists"
                if [ -f "/opt/odigos-demo-currency/index.php" ]; then
                    print_success "✓ Currency PHP files exist"
                else
                    print_error "✗ Currency PHP files missing"
                fi
            else
                print_error "✗ Currency application directory missing"
            fi

            # Check nginx configuration
            if [ -f "/etc/nginx/sites-available/odigos-demo-currency.conf" ]; then
                print_success "✓ Currency nginx configuration exists"
            else
                print_error "✗ Currency nginx configuration missing"
            fi

            # Check systemd service
            if [ -f "/lib/systemd/system/odigos-demo-currency.service" ]; then
                print_success "✓ Currency systemd service exists"
            else
                print_error "✗ Currency systemd service missing"
            fi
            ;;

        "membership")
            # Check Go binary
            if [ -f "/usr/bin/odigos-demo-membership" ]; then
                print_success "✓ Membership binary exists"
            else
                print_error "✗ Membership binary missing"
            fi

            # Check systemd service
            if [ -f "/lib/systemd/system/odigos-demo-membership.service" ]; then
                print_success "✓ Membership systemd service exists"
            else
                print_error "✗ Membership systemd service missing"
            fi
            ;;

        "inventory")
            # Check Python application files
            if [ -d "/opt/odigos-demo-inventory" ]; then
                print_success "✓ Inventory application directory exists"
                if [ -f "/opt/odigos-demo-inventory/main.py" ]; then
                    print_success "✓ Inventory Python files exist"
                else
                    print_error "✗ Inventory Python files missing"
                fi
            else
                print_error "✗ Inventory application directory missing"
            fi

            # Check systemd service
            if [ -f "/lib/systemd/system/odigos-demo-inventory.service" ]; then
                print_success "✓ Inventory systemd service exists"
            else
                print_error "✗ Inventory systemd service missing"
            fi
            ;;

        "pricing")
            # Check .NET application files
            if [ -d "/opt/odigos-demo-pricing" ]; then
                print_success "✓ Pricing application directory exists"
                if [ -f "/opt/odigos-demo-pricing/pricing.dll" ]; then
                    print_success "✓ Pricing DLL file exists"
                else
                    print_error "✗ Pricing DLL file missing"
                fi
            else
                print_error "✗ Pricing application directory missing"
            fi

            # Check systemd service
            if [ -f "/lib/systemd/system/odigos-demo-pricing.service" ]; then
                print_success "✓ Pricing systemd service exists"
            else
                print_error "✗ Pricing systemd service missing"
            fi
            ;;

        "coupon")
            # Check Node.js application files
            if [ -d "/opt/odigos-demo-coupon" ]; then
                print_success "✓ Coupon application directory exists"
                if [ -f "/opt/odigos-demo-coupon/app.js" ]; then
                    print_success "✓ Coupon JavaScript files exist"
                else
                    print_error "✗ Coupon JavaScript files missing"
                fi
            else
                print_error "✗ Coupon application directory missing"
            fi

            # Check systemd service
            if [ -f "/lib/systemd/system/odigos-demo-coupon.service" ]; then
                print_success "✓ Coupon systemd service exists"
            else
                print_error "✗ Coupon systemd service missing"
            fi
            ;;

        "geolocation")
            # Check Ruby application files
            if [ -d "/opt/odigos-demo-geolocation" ]; then
                print_success "✓ Geolocation application directory exists"
                if [ -f "/opt/odigos-demo-geolocation/config.ru" ]; then
                    print_success "✓ Geolocation Ruby files exist"
                else
                    print_error "✗ Geolocation Ruby files missing"
                fi
            else
                print_error "✗ Geolocation application directory missing"
            fi

            # Check systemd service
            if [ -f "/lib/systemd/system/odigos-demo-geolocation.service" ]; then
                print_success "✓ Geolocation systemd service exists"
            else
                print_error "✗ Geolocation systemd service missing"
            fi
            ;;
    esac
}

# Function to check service status
check_service_status() {
    local service="$1"
    if systemctl is-active --quiet "odigos-demo-$service"; then
        print_success "✓ $service service is running"
    else
        print_warning "○ $service service is not running"
        systemctl status "odigos-demo-$service" --no-pager -l || true
    fi
}

# Main validation function
main() {
    print_status "Validating Odigos Demo Package Installation"
    print_status "==========================================="

    local services=("frontend" "coupon" "currency" "geolocation" "inventory" "membership" "pricing")

    for service in "${services[@]}"; do
        echo ""
        print_status "=== Validating $service service ==="

        # Check if package is installed
        if dpkg -l | grep -q "odigos-demo-$service"; then
            print_success "✓ $service package is installed"
            validate_package_contents "$service"
            check_service_status "$service"
        else
            print_error "✗ $service package is not installed"
        fi
    done

    echo ""
    print_status "=== System Dependencies Check ==="

    # Check system dependencies
    local deps=("java" "node" "php" "python3" "dotnet" "ruby" "nginx")
    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            print_success "✓ $dep is installed"
        else
            print_warning "○ $dep is not installed"
        fi
    done

    echo ""
    print_status "Validation completed!"
}

# Handle command line arguments
case "${1:-}" in
    "help")
        echo "Usage: $0 [help]"
        echo ""
        echo "This script validates the Odigos Demo package installation."
        echo "It checks if all required files and services are properly installed."
        echo ""
        echo "Commands:"
        echo "  (no args) - Validate all packages and services"
        echo "  help      - Show this help"
        ;;
    *)
        main
        ;;
esac
