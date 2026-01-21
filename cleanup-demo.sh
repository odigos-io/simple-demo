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

# Function to stop all services
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

# Function to wait for dpkg lock
wait_for_dpkg_lock() {
    local max_wait=30
    local wait_time=0

    while [ $wait_time -lt $max_wait ]; do
        if ! lsof /var/lib/dpkg/lock-frontend >/dev/null 2>&1; then
            return 0
        fi
        print_status "Waiting for dpkg lock to be released... ($wait_time/$max_wait)"
        sleep 2
        wait_time=$((wait_time + 2))
    done

    print_warning "dpkg lock not released after $max_wait seconds, proceeding anyway..."
}

# Function to remove packages
remove_packages() {
    local package_type="$1"

    print_status "Removing Odigos demo packages..."

    if [ "$package_type" = "deb" ]; then
        # Wait for dpkg lock if needed
        wait_for_dpkg_lock

        # Remove packages in reverse dependency order
        local services=("frontend" "coupon" "currency" "geolocation" "inventory" "membership" "pricing")

        for service in "${services[@]}"; do
            if dpkg -l | grep -q "odigos-demo-$service"; then
                print_status "Removing odigos-demo-$service..."
                sudo dpkg -r "odigos-demo-$service" || true
            fi
        done

        # Clean up any remaining packages
        sudo apt-get autoremove -y || true
        sudo apt-get autoclean || true

    else
        # For RPM-based systems
        local services=("frontend" "coupon" "currency" "geolocation" "inventory" "membership" "pricing")

        for service in "${services[@]}"; do
            if rpm -qa | grep -q "odigos-demo-$service"; then
                print_status "Removing odigos-demo-$service..."
                sudo rpm -e "odigos-demo-$service" || true
            fi
        done
    fi
}

# Function to clean up systemd files
cleanup_systemd() {
    print_status "Cleaning up systemd service files..."

    local services=("frontend" "coupon" "currency" "geolocation" "inventory" "membership" "pricing")

    for service in "${services[@]}"; do
        if [ -f "/lib/systemd/system/odigos-demo-$service.service" ]; then
            print_status "Removing systemd service: odigos-demo-$service.service"
            sudo rm -f "/lib/systemd/system/odigos-demo-$service.service"
        fi
    done

    # Reload systemd
    sudo systemctl daemon-reload
}

# Function to clean up application files
cleanup_app_files() {
    print_status "Cleaning up application files..."

    sudo rm -rf /opt/odigos-demo-*
    sudo rm -rf /etc/nginx/sites-available/odigos-demo-*
    sudo rm -rf /etc/nginx/sites-enabled/odigos-demo-*
    sudo rm -rf /etc/nginx/conf.d/odigos-demo-*
}

# Function to clean up user
cleanup_user() {
    print_status "Cleaning up odigos user..."

    if id "odigos" &>/dev/null; then
        sudo userdel odigos || true
        print_status "Removed odigos user"
    fi
}

# Main cleanup function
main() {
    print_status "Cleaning up Odigos Demo Installation"
    print_status "===================================="

    # Detect package manager
    local package_type=$(detect_package_manager)
    print_status "Detected package manager: $package_type"

    # Stop all services first
    stop_services

    # Remove packages
    remove_packages "$package_type"

    # Clean up systemd files
    cleanup_systemd

    # Clean up application files
    cleanup_app_files

    # Clean up user
    cleanup_user

    print_success "Odigos Demo cleanup completed!"
    print_status "All services, packages, and files have been removed."
}

# Handle command line arguments
case "${1:-}" in
    "status")
        print_status "Checking Odigos demo installation status..."

        local services=("frontend" "coupon" "currency" "geolocation" "inventory" "membership" "pricing")
        local package_type=$(detect_package_manager)

        print_status "Service status:"
        for service in "${services[@]}"; do
            if systemctl is-active --quiet "odigos-demo-$service"; then
                echo -e "  ${GREEN}● active${NC}   odigos-demo-$service"
            else
                echo -e "  ${RED}○ inactive${NC} odigos-demo-$service"
            fi
        done

        print_status "Package status:"
        if [ "$package_type" = "deb" ]; then
            dpkg -l | grep odigos-demo || print_warning "No Odigos demo packages found"
        else
            rpm -qa | grep odigos-demo || print_warning "No Odigos demo packages found"
        fi
        ;;
    "force")
        print_warning "Force cleanup mode - removing everything..."
        main
        ;;
    "help")
        echo "Usage: $0 [status|force|help]"
        echo ""
        echo "This script completely removes the Odigos Demo installation."
        echo ""
        echo "Commands:"
        echo "  (no args) - Remove all Odigos demo packages and files"
        echo "  status     - Check what's currently installed"
        echo "  force      - Force remove everything"
        echo "  help       - Show this help"
        ;;
    *)
        main
        ;;
esac
