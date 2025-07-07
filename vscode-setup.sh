#!/bin/bash
# VS Code setup script for macOS

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function print_status() {
  echo -e "${GREEN}[+] $1${NC}"
}

function print_warning() {
  echo -e "${YELLOW}[!] $1${NC}"
}

function print_error() {
  echo -e "${RED}[-] $1${NC}"
}

# Install VS Code
function install_vscode() {
  print_status "Checking for Visual Studio Code..."
  if ! command -v code &> /dev/null; then
    print_status "Installing VS Code..."
    brew install --cask visual-studio-code
    if [ $? -ne 0 ]; then
      print_error "Failed to install VS Code. Please install manually and run this script again."
      exit 1
    fi
  else
    print_status "VS Code is already installed."
  fi
}

# Install VS Code extensions
function install_vscode_extensions() {
  print_status "Installing VS Code extensions..."
  extensions=(
    "ms-vscode-remote.remote-containers"
    "ms-azuretools.vscode-docker"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "dbaeumer.vscode-eslint"
    "esbenp.prettier-vscode"
    "mtxr.sqltools"
    "mtxr.sqltools-driver-pg"
  )
  for extension in "${extensions[@]}"; do
    print_status "Installing $extension..."
    code --install-extension "$extension" || print_warning "Failed to install $extension"
  done
  print_status "VS Code extensions installed."
}

# Configure VS Code settings for terminal
function configure_vscode_settings() {
  print_status "Configuring VS Code settings for terminals..."
  # Create VS Code settings directory if it doesn't exist
  mkdir -p "$HOME/Library/Application Support/Code/User"
  # Create or update settings.json
  settings_file="$HOME/Library/Application Support/Code/User/settings.json"
  if [ ! -f "$settings_file" ]; then
    echo '{
  "terminal.integrated.defaultProfile.osx": "zsh",
  "terminal.integrated.fontFamily": "MesloLGS NF",
  "terminal.integrated.fontSize": 12
}' > "$settings_file"
  else
    # Use Python to merge settings
    python3 -c "
import json
import os
file_path = os.path.expanduser('$settings_file')
with open(file_path, 'r') as f:
    try:
        settings = json.load(f)
    except json.JSONDecodeError:
        settings = {}
settings['terminal.integrated.defaultProfile.osx'] = 'zsh'
settings['terminal.integrated.fontFamily'] = 'MesloLGS NF'
settings['terminal.integrated.fontSize'] = 12
with open(file_path, 'w') as f:
    json.dump(settings, f, indent=2)
"
  fi
  print_status "VS Code settings configured."
}

function main() {
  print_status "Starting VS Code setup..."
  install_vscode
  install_vscode_extensions
  configure_vscode_settings
  print_status "VS Code setup completed!"
}

main 