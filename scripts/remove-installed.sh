#!/bin/bash
# Remove Spinbox installations using the modern uninstall script
# This script provides a comprehensive cleanup of all Spinbox installations

set -e

echo "======================================"
echo "Spinbox Complete Removal Script"
echo "======================================"
echo ""
echo "This script will remove ALL Spinbox installations:"
echo "  - System installation (/usr/local/bin/spinbox)"
echo "  - User installation (~/.local/bin/spinbox)"
echo "  - Configuration and source (~/.spinbox/)"
echo "  - Old library directories"
echo "  - Test projects"
echo ""

# Navigate to spinbox directory if available
if [[ -d "/Users/gonzalo/code/spinbox" ]]; then
    cd /Users/gonzalo/code/spinbox
fi

# Use the modern uninstall script if available
if [[ -f "./uninstall.sh" ]]; then
    echo "[INFO] Using modern uninstall script..."
    sudo ./uninstall.sh --config --force || echo "Uninstall script failed, proceeding with manual cleanup"
else
    echo "[INFO] Uninstall script not found, using manual cleanup..."
fi

# Manual cleanup as fallback or additional cleanup
echo ""
echo "[INFO] Performing comprehensive cleanup..."

# Remove system installation
if [[ -f "/usr/local/bin/spinbox" ]]; then
    echo "Removing system binary: /usr/local/bin/spinbox"
    sudo rm -f /usr/local/bin/spinbox
fi

# Remove old library directory (pre-centralized architecture)
if [[ -d "/usr/local/lib/spinbox" ]]; then
    echo "Removing old library directory: /usr/local/lib/spinbox"
    sudo rm -rf /usr/local/lib/spinbox
fi

# Remove user installation
if [[ -f "$HOME/.local/bin/spinbox" ]]; then
    echo "Removing user binary: ~/.local/bin/spinbox"
    rm -f "$HOME/.local/bin/spinbox"
fi

# Remove old user library directory (pre-centralized architecture)
if [[ -d "$HOME/.local/lib/spinbox" ]]; then
    echo "Removing old user library: ~/.local/lib/spinbox"
    rm -rf "$HOME/.local/lib/spinbox"
fi

# Remove configuration and centralized source
if [[ -d "$HOME/.spinbox" ]]; then
    echo "Removing configuration and source: ~/.spinbox"
    rm -rf "$HOME/.spinbox"
fi

# Remove any test projects or directories
echo "[INFO] Cleaning up test projects..."
rm -rf ~/test-spinbox-* 2>/dev/null || true
rm -rf ~/code/spinbox/test-spinbox* 2>/dev/null || true
rm -rf ~/test-local-project 2>/dev/null || true
rm -rf ~/test-python-* 2>/dev/null || true
rm -rf ~/test-node-* 2>/dev/null || true

# Verify everything is removed
echo ""
echo "[INFO] Verifying removal..."
echo ""

# Check if spinbox command exists
if command -v spinbox &> /dev/null; then
    echo "⚠️  WARNING: spinbox command still found at: $(which spinbox)"
    echo "   You may need to restart your terminal or update your PATH"
else
    echo "✓ Spinbox command not found (successfully removed)"
fi

# Check for remaining files
remaining_files=0

if [[ -f "/usr/local/bin/spinbox" ]]; then
    echo "✗ System binary still exists: /usr/local/bin/spinbox"
    ((remaining_files++))
else
    echo "✓ System binary removed"
fi

if [[ -f "$HOME/.local/bin/spinbox" ]]; then
    echo "✗ User binary still exists: ~/.local/bin/spinbox"
    ((remaining_files++))
else
    echo "✓ User binary removed"
fi

if [[ -d "$HOME/.spinbox" ]]; then
    echo "✗ Configuration directory still exists: ~/.spinbox"
    ((remaining_files++))
else
    echo "✓ Configuration directory removed"
fi

if [[ -d "/usr/local/lib/spinbox" ]]; then
    echo "✗ Old system library still exists: /usr/local/lib/spinbox"
    ((remaining_files++))
else
    echo "✓ Old system library removed"
fi

if [[ -d "$HOME/.local/lib/spinbox" ]]; then
    echo "✗ Old user library still exists: ~/.local/lib/spinbox"
    ((remaining_files++))
else
    echo "✓ Old user library removed"
fi

echo ""
if [[ $remaining_files -eq 0 ]]; then
    echo "======================================"
    echo "✓ All Spinbox files successfully removed!"
    echo "======================================"
    echo ""
    echo "Note: If 'which spinbox' still shows a result, you may need to:"
    echo "  - Restart your terminal"
    echo "  - Run: hash -r"
    echo "  - Check your PATH configuration in ~/.bashrc or ~/.zshrc"
else
    echo "======================================"
    echo "⚠️  Some files could not be removed"
    echo "======================================"
    echo ""
    echo "You may need to run with sudo or manually remove remaining files"
    exit 1
fi