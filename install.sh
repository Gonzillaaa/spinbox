#!/bin/bash
# Spinbox installation script

set -e

# Configuration
REPO_URL="https://github.com/Gonzillaaa/spinbox.git"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="$HOME/.spinbox"
TEMP_DIR="/tmp/spinbox-install"

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
    
    # Install libraries to centralized user location
    print_status "Installing libraries to $CONFIG_DIR/source..."
    if [[ -n "${SUDO_USER:-}" ]]; then
        # Running with sudo - create directory as the actual user
        sudo -u "$SUDO_USER" mkdir -p "$CONFIG_DIR/source"
        sudo -u "$SUDO_USER" cp -r lib "$CONFIG_DIR/source/"
        sudo -u "$SUDO_USER" cp -r generators "$CONFIG_DIR/source/"
        if [ -d "templates" ]; then
            sudo -u "$SUDO_USER" cp -r templates "$CONFIG_DIR/source/"
        fi
    else
        # Running directly as user
        mkdir -p "$CONFIG_DIR/source"
        cp -r lib "$CONFIG_DIR/source/"
        cp -r generators "$CONFIG_DIR/source/"
        if [ -d "templates" ]; then
            cp -r templates "$CONFIG_DIR/source/"
        fi
    fi
    
    # Install binary to system location (uses centralized source via detection)
    print_status "Installing to $INSTALL_DIR..."
    sudo cp bin/spinbox "$INSTALL_DIR/spinbox"
    sudo chmod +x "$INSTALL_DIR/spinbox"
    
    # Create user configuration directory with proper ownership
    if [[ -n "${SUDO_USER:-}" ]]; then
        # Running with sudo - create directory as the actual user
        sudo -u "$SUDO_USER" mkdir -p "$CONFIG_DIR"
    else
        # Running directly as user
        mkdir -p "$CONFIG_DIR"
    fi
    
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