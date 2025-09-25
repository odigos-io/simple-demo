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

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_VERSION="${PACKAGE_VERSION:-1.0.0}"
PACKAGE_FILE="$PROJECT_DIR/release/odigos-demo-packages-$PACKAGE_VERSION.tar.gz"
PACKAGE_FILE_DEB="$PROJECT_DIR/release/odigos-demo-packages-$PACKAGE_VERSION-deb.tar.gz"

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

# Function to install packages
install_packages() {
    local package_type="$1"
    local temp_dir="/tmp/odigos-install-$$"

    print_status "Extracting packages to $temp_dir..."
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    tar -xzf "$PACKAGE_FILE"

    if [ "$package_type" = "deb" ]; then
        print_status "Installing DEB packages..."
        sudo dpkg -i *.deb || sudo apt-get install -f
    else
        print_status "Installing RPM packages..."
        sudo rpm -i *.rpm
    fi

    # Cleanup
    cd /
    rm -rf "$temp_dir"
}

# Function to check service status
check_services() {
    print_status "Checking service status..."
    local services=("membership" "inventory" "pricing" "coupon" "currency" "geolocation" "frontend")

    for service in "${services[@]}"; do
        if systemctl is-active --quiet "odigos-demo-$service"; then
            print_success "$service service is running"
        else
            print_warning "$service service is not running"
        fi
    done
}

# Main installation process
main() {
    print_status "Installing Odigos Demo from Package"
    print_status "===================================="

    # Check if package exists (try DEB-only first, then full package)
    if [ -f "$PACKAGE_FILE_DEB" ]; then
        PACKAGE_FILE="$PACKAGE_FILE_DEB"
        print_status "Found DEB-only package: $PACKAGE_FILE"
    elif [ -f "$PACKAGE_FILE" ]; then
        print_status "Found full package: $PACKAGE_FILE"
    else
        print_error "Package not found: $PACKAGE_FILE or $PACKAGE_FILE_DEB"
        print_status "Run 'make package-local-deb' or 'make package-local' first to create the package"
        exit 1
    fi

    ls -lh "$PACKAGE_FILE"

    # Detect package manager
    local package_type=$(detect_package_manager)
    print_status "Detected package manager: $package_type"

    # Install packages
    install_packages "$package_type"

    # Check services
    check_services

    # Show access information
    print_success "Installation completed!"
    print_status ""
    print_status "🌐 Demo is now available at: http://localhost:8080"
    print_status ""
    print_status "📋 Service URLs:"
    print_status "  Frontend:     http://localhost:8080"
    print_status "  Membership:   http://localhost:8081"
    print_status "  Inventory:    http://localhost:8082"
    print_status "  Pricing:      http://localhost:8083"
    print_status "  Coupon:       http://localhost:8084"
    print_status "  Currency:     http://localhost:8085"
    print_status "  Geolocation:  http://localhost:8086"
    print_status ""
    print_status "🔧 Management commands:"
    print_status "  Check status: systemctl status odigos-demo-*"
    print_status "  View logs:    journalctl -u odigos-demo-frontend -f"
    print_status "  Remove all:   sudo apt remove odigos-demo-frontend"
}

# Handle command line arguments
case "${1:-}" in
    "status")
        check_services
        ;;
    "help")
        echo "Usage: $0 [status|help]"
        echo ""
        echo "Commands:"
        echo "  (no args) - Install packages from release"
        echo "  status    - Check service status"
        echo "  help      - Show this help"
        echo ""
        echo "Variables:"
        echo "  PACKAGE_VERSION - Package version (default: 1.0.0)"
        ;;
    *)
        main
        ;;
esac
