#!/bin/bash
# Spinbox uninstallation script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_debug() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# Default options
REMOVE_CONFIG=false
FORCE=false
VERBOSE=false
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --config|--all)
            REMOVE_CONFIG=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            cat << EOF
Spinbox Uninstallation Script

USAGE:
    uninstall.sh [OPTIONS]

OPTIONS:
    --config, --all     Also remove configuration files (~/.spinbox)
    -f, --force         Skip confirmation prompts
    -v, --verbose       Enable verbose output
    -d, --dry-run      Show what would be removed without making changes
    -h, --help         Show this help message

EXAMPLES:
    curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/uninstall.sh | bash
    curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/uninstall.sh | bash -s -- --config
    curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/uninstall.sh | bash -s -- --force

EOF
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "Spinbox Uninstallation Script"
echo "============================="
echo ""

# Detect installation locations
BINARY_LOCATIONS=(
    "/usr/local/bin/spinbox"
    "$HOME/.local/bin/spinbox"
    "/opt/homebrew/bin/spinbox"
    "/usr/bin/spinbox"
)

CONFIG_DIR="$HOME/.spinbox"
HOMEBREW_FORMULA=""

# Check for Homebrew installation
if command -v brew &> /dev/null; then
    if brew list spinbox &> /dev/null 2>&1; then
        HOMEBREW_FORMULA="spinbox"
        print_warning "Homebrew installation detected"
        print_info "Recommendation: Use 'brew uninstall spinbox' instead"
        if [[ "$FORCE" == "false" ]]; then
            read -p "Continue with manual uninstall anyway? [y/N]: " -r
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_info "Uninstall cancelled. Use: brew uninstall spinbox"
                exit 0
            fi
        fi
    fi
fi

# Find installed binaries
FOUND_BINARIES=()
for location in "${BINARY_LOCATIONS[@]}"; do
    if [[ -f "$location" ]]; then
        FOUND_BINARIES+=("$location")
    fi
done

# Check what will be removed
ITEMS_TO_REMOVE=()

for binary in "${FOUND_BINARIES[@]}"; do
    ITEMS_TO_REMOVE+=("Spinbox binary: $binary")
done

if [[ "$REMOVE_CONFIG" == "true" && -d "$CONFIG_DIR" ]]; then
    ITEMS_TO_REMOVE+=("Configuration directory: $CONFIG_DIR")
fi

# Check if anything found
if [[ ${#ITEMS_TO_REMOVE[@]} -eq 0 ]]; then
    print_warning "No Spinbox installation found"
    
    # Check for config directory even if no binary found
    if [[ -d "$CONFIG_DIR" ]]; then
        print_info "Configuration directory exists: $CONFIG_DIR"
        if [[ "$REMOVE_CONFIG" == "true" ]]; then
            if [[ "$FORCE" == "false" ]]; then
                read -p "Remove configuration directory? [y/N]: " -r
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    ITEMS_TO_REMOVE+=("Configuration directory: $CONFIG_DIR")
                fi
            else
                ITEMS_TO_REMOVE+=("Configuration directory: $CONFIG_DIR")
            fi
        else
            print_info "Use --config option to remove it"
        fi
    fi
    
    if [[ ${#ITEMS_TO_REMOVE[@]} -eq 0 ]]; then
        print_info "Nothing to remove"
        exit 0
    fi
fi

# Show what will be removed
print_info "The following will be removed:"
for item in "${ITEMS_TO_REMOVE[@]}"; do
    echo "  - $item"
done

if [[ "$REMOVE_CONFIG" == "false" && -d "$CONFIG_DIR" ]]; then
    print_info "Configuration files will be preserved (use --config to remove)"
fi

# Dry run mode
if [[ "$DRY_RUN" == "true" ]]; then
    print_info "Dry run: No files would be removed"
    exit 0
fi

# Confirmation unless force mode
if [[ "$FORCE" == "false" ]]; then
    echo ""
    read -p "Do you want to continue? [y/N]: " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Uninstall cancelled"
        exit 0
    fi
fi

echo ""
print_status "Starting uninstallation..."

# Track errors
ERRORS=0

# Remove binaries
for binary in "${FOUND_BINARIES[@]}"; do
    print_debug "Removing: $binary"
    
    if rm -f "$binary" 2>/dev/null; then
        print_status "Removed: $binary"
    else
        # Try with sudo if initial removal failed
        if sudo rm -f "$binary" 2>/dev/null; then
            print_status "Removed: $binary (with sudo)"
        else
            print_error "Failed to remove: $binary"
            ((ERRORS++))
        fi
    fi
done

# Remove configuration if requested
if [[ "$REMOVE_CONFIG" == "true" && -d "$CONFIG_DIR" ]]; then
    print_debug "Removing: $CONFIG_DIR"
    
    if rm -rf "$CONFIG_DIR" 2>/dev/null; then
        print_status "Removed configuration directory"
    else
        print_error "Failed to remove: $CONFIG_DIR"
        ((ERRORS++))
    fi
fi

# Final results
echo ""
if [[ $ERRORS -eq 0 ]]; then
    print_status "Spinbox uninstalled successfully!"
    echo ""
    print_info "Thank you for using Spinbox!"
    
    if [[ "$REMOVE_CONFIG" == "false" && -d "$CONFIG_DIR" ]]; then
        print_info "Your configuration is preserved at $CONFIG_DIR"
        print_info "To remove it later: rm -rf $CONFIG_DIR"
    fi
    
    # Cleanup PATH mentions (informational only)
    echo ""
    print_info "If you manually added Spinbox to PATH, you may want to:"
    print_info "- Edit ~/.bashrc, ~/.zshrc, or ~/.profile"
    print_info "- Remove any Spinbox-related PATH entries"
    
else
    print_error "Uninstallation completed with $ERRORS errors"
    print_info "Some files may require manual removal or sudo access"
    exit 1
fi