#!/bin/bash
# Spinbox user-space installation script (no sudo required)

set -e

# Configuration - Modified for user installation
REPO_URL="https://github.com/Gonzillaaa/spinbox.git"
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.spinbox"
TEMP_DIR="$HOME/.spinbox/source"

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
    
    # Create install directory if it doesn't exist
    if [ ! -d "$INSTALL_DIR" ]; then
        print_status "Creating install directory: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
    fi
    
    # Check if install directory is writable (should be since it's in user space)
    if [ ! -w "$INSTALL_DIR" ]; then
        print_error "Cannot write to $INSTALL_DIR. Please check permissions."
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
    
    # Clean up any existing source directory
    if [ -d "$TEMP_DIR" ]; then
        chmod -R u+w "$TEMP_DIR" 2>/dev/null || true
        rm -rf "$TEMP_DIR" 2>/dev/null || true
    fi
    
    # Clone repository
    git clone "$REPO_URL" "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Make spinbox executable
    chmod +x bin/spinbox
    
    # Create configuration directory first
    mkdir -p "$CONFIG_DIR"
    
    # Copy all needed directories to config
    print_status "Setting up configuration..."
    cp -r lib "$CONFIG_DIR/"
    if [ -d "generators" ]; then
        cp -r generators "$CONFIG_DIR/"
    fi
    if [ -d "templates" ]; then
        cp -r templates "$CONFIG_DIR/"
    fi
    
    # Modify the binary to look in config directory for libs
    print_status "Installing to $INSTALL_DIR..."
    sed 's|source "$SPINBOX_PROJECT_ROOT/lib/|source "$HOME/.spinbox/lib/|g' bin/spinbox > "$INSTALL_DIR/spinbox"
    chmod +x "$INSTALL_DIR/spinbox"
    
    # Make sure the binary was installed correctly
    if [ -x "$INSTALL_DIR/spinbox" ]; then
        print_status "Spinbox installed successfully!"
    else
        print_error "Installation failed. Could not install binary."
        exit 1
    fi
    
    print_status "Configuration directory created at $CONFIG_DIR"
}

# Check if ~/.local/bin is in PATH
check_path() {
    if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
        print_status "~/.local/bin is already in your PATH"
    else
        print_warning "~/.local/bin is not in your PATH"
        print_warning "Add this line to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
        echo ""
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
        print_warning "Then reload your shell or run: source ~/.bashrc (or ~/.zshrc)"
        echo ""
        print_status "For this session, you can run:"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

# Main installation function
main() {
    echo "Spinbox User-Space Installation Script"
    echo "====================================="
    echo "Installing to: $INSTALL_DIR"
    echo ""
    
    check_prerequisites
    install_spinbox
    check_path
    
    echo ""
    echo "Installation complete!"
    echo "Try: spinbox --help"
    echo ""
    echo "If spinbox command is not found, make sure ~/.local/bin is in your PATH:"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "To uninstall Spinbox:"
    echo "  spinbox uninstall                # Remove binary only"
    echo "  spinbox uninstall --config       # Remove binary and config"
    echo "  Or manually: rm ~/.local/bin/spinbox && rm -rf ~/.spinbox"
}

# Run main function
main "$@"