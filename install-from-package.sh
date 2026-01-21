#!/bin/bash
set -e

# Handle interruptions gracefully
trap 'handle_interrupted_installation; exit 1' INT TERM

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

# Function to handle interrupted installations
handle_interrupted_installation() {
    print_warning "Installation was interrupted. Attempting to fix dpkg state..."
    sudo dpkg --configure -a
    print_status "Running apt-get install -f to fix any broken dependencies..."
    sudo apt-get install -f -y
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
        # Install packages in dependency order to avoid circular dependency issues
        # Order: independent services first, then frontend last
        local install_order=(
            "*membership*.deb"
            "*inventory*.deb"
            "*pricing*.deb"
            "*coupon*.deb"
            "*currency*.deb"
            "*geolocation*.deb"
            "*frontend*.deb"
        )

        for pattern in "${install_order[@]}"; do
            for deb_file in $pattern; do
                if [ -f "$deb_file" ]; then
                    print_status "Installing $deb_file..."
                    if sudo dpkg -i "$deb_file"; then
                        print_success "✓ Successfully installed $deb_file"
                    else
                        print_warning "⚠ Failed to install $deb_file, trying to fix dependencies..."
                        sudo apt-get install -f -y
                        # Try again after fixing dependencies
                        if sudo dpkg -i "$deb_file"; then
                            print_success "✓ Successfully installed $deb_file after dependency fix"
                        else
                            print_error "✗ Failed to install $deb_file even after dependency fix"
                            # For frontend, try one more time after ensuring all dependencies are installed
                            if [[ "$deb_file" == *"frontend"* ]]; then
                                print_status "Retrying frontend installation after ensuring all dependencies..."
                                sudo apt-get install -f -y
                                sleep 2
                                if sudo dpkg -i "$deb_file"; then
                                    print_success "✓ Frontend installed successfully on retry"
                                else
                                    print_error "✗ Frontend installation failed completely"
                                fi
                            fi
                        fi
                    fi
                fi
            done
        done

        # Final dependency check and fix
        print_status "Performing final dependency check..."
        sudo apt-get install -f -y

        # Verify critical files were installed
        print_status "Verifying installation..."
        if [ -f "/etc/nginx/sites-available/odigos-demo-currency.conf" ]; then
            print_success "✓ Currency nginx configuration installed"
        else
            print_warning "○ Currency nginx configuration missing"
        fi

        # Reload nginx if configuration exists
        if [ -f "/etc/nginx/sites-available/odigos-demo-currency.conf" ]; then
            print_status "Reloading nginx configuration..."
            sudo nginx -t && sudo systemctl reload nginx || true
        fi

    else
        print_status "Installing RPM packages..."
        sudo rpm -i *.rpm
    fi

    # Cleanup
    cd /
    rm -rf "$temp_dir"

    # Final verification
    print_status "Final verification..."
    local services=("membership" "inventory" "pricing" "coupon" "currency" "geolocation" "frontend")
    local installed_count=0

    for service in "${services[@]}"; do
        if dpkg -l | grep -q "odigos-demo-$service"; then
            installed_count=$((installed_count + 1))
        fi
    done

    if [ "$installed_count" -eq "${#services[@]}" ]; then
        print_success "All $installed_count services installed successfully"
    else
        print_warning "Only $installed_count out of ${#services[@]} services installed"
    fi
}

# Function to install system dependencies
install_system_dependencies() {
    local package_type="$1"

    print_status "Installing system dependencies..."

    if [ "$package_type" = "deb" ]; then
        # Update package lists
        sudo apt-get update

        # Install required system packages
        sudo apt-get install -y \
            openjdk-17-jre-headless \
            nodejs \
            npm \
            php-cli \
            nginx \
            python3 \
            python3-pip \
            dotnet-sdk-8.0 \
            ruby \
            ruby-dev \
            build-essential

        # Install Ruby gems for geolocation service
        sudo gem install bundler

    else
        # For RPM-based systems
        sudo dnf install -y \
            java-17-openjdk-headless \
            nodejs \
            npm \
            php-cli \
            nginx \
            python3 \
            python3-pip \
            dotnet-sdk-8.0 \
            ruby \
            ruby-devel \
            gcc \
            make

        # Install Ruby gems for geolocation service
        sudo gem install bundler
    fi
}

# Function to start all services
start_services() {
    print_status "Starting all Odigos demo services..."
    local services=("membership" "inventory" "pricing" "coupon" "currency" "geolocation" "frontend")

    for service in "${services[@]}"; do
        if systemctl is-enabled --quiet "odigos-demo-$service" 2>/dev/null; then
            print_status "Starting $service service..."
            if sudo systemctl start "odigos-demo-$service"; then
                print_success "✓ $service service started"
            else
                print_warning "⚠ Failed to start $service service"
            fi
        else
            print_warning "⚠ $service service is not enabled"
        fi
    done
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

    # Install system dependencies first
    install_system_dependencies "$package_type"

    # Install packages
    install_packages "$package_type"

    # Start services
    start_services

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
    "start")
        start_services
        check_services
        ;;
    "help")
        echo "Usage: $0 [status|start|help]"
        echo ""
        echo "Commands:"
        echo "  (no args) - Install packages from release"
        echo "  status    - Check service status"
        echo "  start     - Start all services"
        echo "  help      - Show this help"
        echo ""
        echo "Variables:"
        echo "  PACKAGE_VERSION - Package version (default: 1.0.0)"
        ;;
    *)
        main
        ;;
esac
