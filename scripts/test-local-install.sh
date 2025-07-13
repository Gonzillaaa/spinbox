#!/bin/bash
#Test Local Installation (User-space)

# From your spinbox directory
cd /Users/gonzalo/code/spinbox

# Install using local user installation script
bash install-user.sh

# Test the local installation:

# Update PATH for current session (avoid shell-specific config issues)
export PATH="$HOME/.local/bin:$PATH"

# Verify installation
which spinbox  # Should show: /Users/gonzalo/.local/bin/spinbox

# Test version
spinbox --version

# Test update command (may show version parsing error until PR #11 is merged)
spinbox update --check

# Create a test project
spinbox create test-local-project --nextjs --python

# Test update with dry-run
DRY_RUN=true spinbox update

#   5. Clean up local installation:

# Use spinbox uninstall
spinbox uninstall --config

# Or manually
rm -f ~/.local/bin/spinbox
rm -rf ~/.spinbox
rm -rf test-local-project