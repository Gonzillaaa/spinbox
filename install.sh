#!/bin/bash
# Spinbox installation script

set -e

# Configuration
REPO_URL="https://github.com/Gonzillaaa/spinbox.git"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="$HOME/.spinbox"
TEMP_DIR="/tmp/spinbox-install"
SPINBOX_LIB_DIR="/usr/local/lib/spinbox"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check for git
    if ! command -v git &> /dev/null; then
        print_error "Git is required but not installed. Please install git first."
        exit 1
    fi
    
    # Check for bash
    if ! command -v bash &> /dev/null; then
        print_error "Bash is required but not installed."
        exit 1
    fi
    
    # Check if we can write to install directory
    if [ ! -w "$INSTALL_DIR" ] && [ ! -w "$(dirname "$INSTALL_DIR")" ]; then
        print_error "Cannot write to $INSTALL_DIR. Please run with sudo:"
        print_error "  sudo bash <(curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh)"
        print_error ""
        print_error "Or use the user installation script (no sudo required):"
        print_error "  curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install-user.sh | bash"
        exit 1
    fi
    
    # Check for Docker (recommended but not required)
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not installed. Some features will be limited."
        print_warning "Install Docker for full functionality: https://docs.docker.com/get-docker/"
    fi
    
    print_status "Prerequisites check passed."
}

# Download and install Spinbox
install_spinbox() {
    print_status "Downloading Spinbox..."
    
    # Clean up any existing temp directory
    rm -rf "$TEMP_DIR"
    
    # Clone repository
    git clone "$REPO_URL" "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Make spinbox executable
    chmod +x bin/spinbox
    
    # Install libraries to system location
    print_status "Installing libraries to $SPINBOX_LIB_DIR..."
    sudo mkdir -p "$SPINBOX_LIB_DIR"
    sudo cp -r lib "$SPINBOX_LIB_DIR/"
    sudo cp -r generators "$SPINBOX_LIB_DIR/"
    if [ -d "templates" ]; then
        sudo cp -r templates "$SPINBOX_LIB_DIR/"
    fi
    
    # Modify the binary to look in system lib directory
    print_status "Installing to $INSTALL_DIR..."
    sed -e 's|SPINBOX_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"|# System installation - libraries in /usr/local/lib/spinbox|' \
        -e 's|SPINBOX_PROJECT_ROOT="$(dirname "$SPINBOX_SCRIPT_DIR")"|SPINBOX_PROJECT_ROOT="/usr/local/lib/spinbox"|' \
        -e 's|source "$SPINBOX_PROJECT_ROOT/lib/|source "/usr/local/lib/spinbox/lib/|g' \
        bin/spinbox > "/tmp/spinbox"
    sudo mv "/tmp/spinbox" "$INSTALL_DIR/spinbox"
    sudo chmod +x "$INSTALL_DIR/spinbox"
    
    # Create user configuration directory
    mkdir -p "$CONFIG_DIR"
    
    # Make sure the binary was installed correctly
    if [ -x "$INSTALL_DIR/spinbox" ]; then
        print_status "Spinbox installed successfully!"
    else
        print_error "Installation failed. Could not install binary."
        exit 1
    fi
    
    print_status "Configuration directory created at $CONFIG_DIR"
    
    # Cleanup
    cd /
    rm -rf "$TEMP_DIR"
    
    print_status "You can now use: spinbox <projectname>"
}

# Main installation function
main() {
    echo "Spinbox Installation Script"
    echo "=========================="
    echo
    
    check_prerequisites
    install_spinbox
    
    echo
    echo "Installation complete!"
    echo "Try: spinbox --help"
    echo ""
    echo "To uninstall Spinbox:"
    echo "  spinbox uninstall                # Remove binary only"
    echo "  spinbox uninstall --config       # Remove binary and config"
    echo "  Or use: curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/uninstall.sh | bash"
}

# Run main function
main "$@"