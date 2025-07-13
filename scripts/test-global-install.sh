#! /bin/bash
# Test System Installation (Global)

# From your spinbox directory
cd /Users/gonzalo/code/spinbox

# Install using system installation script
sudo bash install.sh

# Test the system installation:

# Verify installation
which spinbox  # Should show: /usr/local/bin/spinbox

# Test version
spinbox --version

# Test update command
spinbox update --check

# Create a test project
spinbox create test-spinbox-system --fastapi --postgresql

# Test update with dry-run
DRY_RUN=true spinbox update

# Clean up system installation:

# Use spinbox uninstall
sudo spinbox uninstall --config

# Or manually
sudo rm -f /usr/local/bin/spinbox
sudo rm -rf /usr/local/lib/spinbox
rm -rf ~/.spinbox
rm -rf test-spinbox-system

#Test Remote Installation (After PR merge)

# User installation from GitHub
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install-user.sh | bash

# Test update
spinbox update --check

# Clean up
spinbox uninstall --config

# System installation from GitHub
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | sudo bash

# Test update
spinbox update --check

# Clean up
sudo spinbox uninstall --config