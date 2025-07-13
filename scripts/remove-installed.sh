#!/bin/bash
# Remove system installation
sudo rm -f /usr/local/bin/spinbox
sudo rm -rf /usr/local/lib/spinbox

# Remove user installation
rm -f ~/.local/bin/spinbox
rm -rf ~/.spinbox

# Remove any test projects or directories
rm -rf ~/test-spinbox-*
rm -rf ~/code/spinbox/test-spinbox*

# Verify everything is removed:

# Should return "command not found"
which spinbox

# Should show no spinbox files
ls -la /usr/local/bin/spinbox
ls -la ~/.local/bin/spinbox
ls -la ~/.spinbox