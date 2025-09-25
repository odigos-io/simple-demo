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

# Function to install system dependencies
install_system_dependencies() {
    local package_type="$1"

    print_status "Installing system dependencies for Odigos Demo..."

    if [ "$package_type" = "deb" ]; then
        # Update package lists
        print_status "Updating package lists..."
        sudo apt-get update

        # Install required system packages
        print_status "Installing Java, Node.js, PHP, Python, .NET, Ruby..."
        sudo apt-get install -y \
            openjdk-17-jre-headless \
            nodejs \
            npm \
            php-cli \
            python3 \
            python3-pip \
            dotnet-sdk-8.0 \
            ruby \
            ruby-dev \
            build-essential

        # Install Ruby gems for geolocation service
        print_status "Installing Ruby bundler..."
        sudo gem install bundler

    else
        # For RPM-based systems
        print_status "Installing packages for RPM-based system..."
        sudo dnf install -y \
            java-17-openjdk-headless \
            nodejs \
            npm \
            php-cli \
            python3 \
            python3-pip \
            dotnet-sdk-8.0 \
            ruby \
            ruby-devel \
            gcc \
            make

        # Install Ruby gems for geolocation service
        print_status "Installing Ruby bundler..."
        sudo gem install bundler
    fi

    print_success "System dependencies installed successfully!"
}

# Function to create odigos user
create_odigos_user() {
    print_status "Creating odigos user..."

    if ! id "odigos" &>/dev/null; then
        sudo useradd -r -s /bin/false -d /opt/odigos-demo odigos
        print_success "Created odigos user"
    else
        print_status "odigos user already exists"
    fi
}

# Main function
main() {
    print_status "Installing System Dependencies for Odigos Demo"
    print_status "==============================================="

    # Detect package manager
    local package_type=$(detect_package_manager)
    print_status "Detected package manager: $package_type"

    # Install system dependencies
    install_system_dependencies "$package_type"

    # Create odigos user
    create_odigos_user

    print_success "All system dependencies are now installed!"
    print_status "You can now run: ./install-from-package.sh"
}

# Handle command line arguments
case "${1:-}" in
    "help")
        echo "Usage: $0 [help]"
        echo ""
        echo "This script installs all system dependencies required for the Odigos Demo."
        echo "Run this before installing the demo packages."
        echo ""
        echo "Commands:"
        echo "  (no args) - Install all system dependencies"
        echo "  help      - Show this help"
        ;;
    *)
        main
        ;;
esac
