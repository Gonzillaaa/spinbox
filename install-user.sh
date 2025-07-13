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
    
    # Create centralized source directory
    mkdir -p "$CONFIG_DIR/source"
    
    # Copy all needed directories to centralized source
    print_status "Setting up configuration..."
    cp -r lib "$CONFIG_DIR/source/"
    if [ -d "generators" ]; then
        cp -r generators "$CONFIG_DIR/source/"
    fi
    if [ -d "templates" ]; then
        cp -r templates "$CONFIG_DIR/source/"
    fi
    
    # Install binary to user location (uses centralized source via detection)
    print_status "Installing to $INSTALL_DIR..."
    cp bin/spinbox "$INSTALL_DIR/spinbox"
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

# Add ~/.local/bin to PATH if needed
check_and_add_path() {
    if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
        print_status "~/.local/bin is already in your PATH"
        return
    fi
    
    print_warning "~/.local/bin is not in your PATH"
    
    # Detect shell and profile file
    local shell_profile=""
    local shell_name="$(basename "$SHELL")"
    
    case "$shell_name" in
        "zsh")
            if [ -f "$HOME/.zshrc" ]; then
                shell_profile="$HOME/.zshrc"
            elif [ -f "$HOME/.zshenv" ]; then
                shell_profile="$HOME/.zshenv"
            fi
            ;;
        "bash")
            if [ -f "$HOME/.bashrc" ]; then
                shell_profile="$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                shell_profile="$HOME/.bash_profile"
            elif [ -f "$HOME/.profile" ]; then
                shell_profile="$HOME/.profile"
            fi
            ;;
        *)
            # For other shells, try common profile files
            if [ -f "$HOME/.profile" ]; then
                shell_profile="$HOME/.profile"
            fi
            ;;
    esac
    
    # Automatically add PATH or ask user permission
    if [ -n "$shell_profile" ]; then
        # Check if we're in interactive mode
        if [ -t 0 ]; then
            # Interactive mode - ask user
            echo ""
            echo "Would you like to automatically add ~/.local/bin to your PATH?"
            echo "This will add the following line to $shell_profile:"
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
            echo ""
            read -p "Add to PATH automatically? [Y/n]: " -r
            
            if [[ $REPLY =~ ^[Nn]$ ]]; then
                print_warning "Skipping automatic PATH setup."
                manual_path_instructions
                return
            fi
        else
            # Non-interactive mode (like curl | bash) - do it automatically
            print_status "Adding ~/.local/bin to PATH automatically (non-interactive mode)"
            print_status "This will add a line to $shell_profile"
        fi
        
        # Check if the export already exists (but not effective due to shell restart needed)
        if grep -q 'export PATH.*\.local/bin' "$shell_profile" 2>/dev/null; then
            print_status "PATH export already exists in $shell_profile"
            print_status "You may need to restart your shell or run: source $shell_profile"
        else
            # Add the PATH export
            echo "" >> "$shell_profile"
            echo "# Added by Spinbox installer" >> "$shell_profile"
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$shell_profile"
            print_status "Added ~/.local/bin to PATH in $shell_profile"
            print_status "Restart your shell or run: source $shell_profile"
        fi
        
        # Set PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
        print_status "PATH updated for current session"
    else
        print_warning "Could not detect shell profile file."
        manual_path_instructions
    fi
}

# Show manual PATH instructions
manual_path_instructions() {
    print_warning "Please manually add this line to your shell profile:"
    echo ""
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    print_warning "Common profile files:"
    echo "  - Zsh: ~/.zshrc or ~/.zshenv"
    echo "  - Bash: ~/.bashrc or ~/.bash_profile"
    echo "  - Other: ~/.profile"
    echo ""
    print_status "For this session, you can run:"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
}

# Main installation function
main() {
    echo "Spinbox User-Space Installation Script"
    echo "====================================="
    echo "Installing to: $INSTALL_DIR"
    echo ""
    
    check_prerequisites
    install_spinbox
    check_and_add_path
    
    echo ""
    echo "Installation complete!"
    echo "Try: spinbox --help"
    echo ""
    echo "To uninstall Spinbox:"
    echo "  spinbox uninstall                # Remove binary only"
    echo "  spinbox uninstall --config       # Remove binary and config"
    echo "  Or manually: rm ~/.local/bin/spinbox && rm -rf ~/.spinbox"
}

# Run main function
main "$@"