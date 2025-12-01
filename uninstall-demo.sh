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

# Function to detect package manager
detect_package_manager() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "deb"
    elif command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
        echo "rpm"
    else
        print_error "Unsupported package manager."
        exit 1
    fi
}

# Function to remove packages
remove_packages() {
    local package_type="$1"

    if [ "$package_type" = "deb" ]; then
        print_status "Removing DEB packages..."
        # Remove frontend first (this will remove all dependent services)
        sudo apt remove -y odigos-demo-frontend || true
        # Clean up any remaining packages
        sudo apt autoremove -y || true
    else
        print_status "Removing RPM packages..."
        # For RPM, we need to remove packages individually
        local services=("frontend" "coupon" "currency" "geolocation" "inventory" "membership" "pricing")
        for service in "${services[@]}"; do
            sudo rpm -e "odigos-demo-$service" || true
        done
    fi
}

# Function to stop services
stop_services() {
    print_status "Stopping all Odigos demo services..."
    local services=("frontend" "coupon" "currency" "geolocation" "inventory" "membership" "pricing")

    for service in "${services[@]}"; do
        if systemctl is-active --quiet "odigos-demo-$service"; then
            print_status "Stopping odigos-demo-$service..."
            sudo systemctl stop "odigos-demo-$service" || true
            sudo systemctl disable "odigos-demo-$service" || true
        fi
    done
}

# Function to check what's installed
check_installed() {
    print_status "Checking installed packages..."

    if command -v dpkg >/dev/null 2>&1; then
        local installed=$(dpkg -l | grep odigos-demo | wc -l)
        if [ "$installed" -gt 0 ]; then
            print_status "Found $installed Odigos demo packages:"
            dpkg -l | grep odigos-demo
            return 0
        fi
    elif command -v rpm >/dev/null 2>&1; then
        local installed=$(rpm -qa | grep odigos-demo | wc -l)
        if [ "$installed" -gt 0 ]; then
            print_status "Found $installed Odigos demo packages:"
            rpm -qa | grep odigos-demo
            return 0
        fi
    fi

    print_warning "No Odigos demo packages found"
    return 1
}

# Main uninstall process
main() {
    print_status "Uninstalling Odigos Demo"
    print_status "======================="

    # Check what's installed
    if ! check_installed; then
        print_warning "No Odigos demo packages found to remove"
        exit 0
    fi

    # Stop services first
    stop_services

    # Detect package manager
    local package_type=$(detect_package_manager)
    print_status "Detected package manager: $package_type"

    # Remove packages
    remove_packages "$package_type"

    print_success "All Odigos demo services have been removed!"
    print_status "All systemd services have been stopped and disabled."
}

# Handle command line arguments
case "${1:-}" in
    "status")
        check_installed
        ;;
    "force")
        print_warning "Force removing all services..."
        stop_services
        local package_type=$(detect_package_manager)
        remove_packages "$package_type"
        print_success "Force removal completed!"
        ;;
    "help")
        echo "Usage: $0 [status|force|help]"
        echo ""
        echo "Commands:"
        echo "  (no args) - Remove all Odigos demo packages"
        echo "  status    - Check what packages are installed"
        echo "  force     - Force remove all packages"
        echo "  help      - Show this help"
        ;;
    *)
        main
        ;;
esac
