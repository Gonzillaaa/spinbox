#!/bin/bash
# VS Code setup script for macOS

# Source the utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

# Initialize error handling and logging
setup_error_handling
init_logging "vscode_setup"
parse_common_args "$@"

# Install VS Code
function install_vscode() {
  print_status "Checking for Visual Studio Code..."
  
  if ! check_command "code" "Visual Studio Code"; then
    print_status "Installing VS Code..."
    
    if [[ "$DRY_RUN" == true ]]; then
      print_info "DRY RUN: Would install VS Code via Homebrew"
      return 0
    fi
    
    if ! retry 3 5 brew install --cask visual-studio-code; then
      print_error "Failed to install VS Code after 3 attempts"
      return 1
    fi
    
    ROLLBACK_ACTIONS+=("brew uninstall --cask visual-studio-code")
  else
    print_status "VS Code is already installed."
  fi
}

# Install VS Code extensions
function install_vscode_extensions() {
  print_status "Installing VS Code extensions..."
  
  local extensions=(
    "ms-vscode-remote.remote-containers"
    "ms-azuretools.vscode-docker"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "dbaeumer.vscode-eslint"
    "esbenp.prettier-vscode"
    "mtxr.sqltools"
    "mtxr.sqltools-driver-pg"
  )
  
  if [[ "$DRY_RUN" == true ]]; then
    print_info "DRY RUN: Would install ${#extensions[@]} VS Code extensions"
    return 0
  fi
  
  local current=0
  local total=${#extensions[@]}
  
  for extension in "${extensions[@]}"; do
    ((current++))
    show_progress "$current" "$total" "Installing $extension"
    
    if ! retry 2 1 code --install-extension "$extension"; then
      print_warning "Failed to install $extension"
    fi
  done
  
  echo ""
  print_status "VS Code extensions installation completed."
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

# Show help for this script
function show_help() {
  cat << EOF
VS Code Setup Script

This script installs VS Code and essential extensions for development.

Usage: $0 [options]

Options:
  -v, --verbose    Enable verbose output
  -d, --dry-run    Show what would be done without making changes
  -h, --help       Show this help message

Components installed:
  - Visual Studio Code
  - Development extensions (Python, Docker, ESLint, etc.)
  - Terminal and font configurations

Examples:
  $0                # Run full VS Code setup
  $0 --dry-run      # Preview what would be installed
  $0 --verbose      # Show detailed output
EOF
}

# Validate prerequisites
function validate_prerequisites() {
  print_status "Validating prerequisites..."
  
  # Check for Homebrew
  if ! check_command "brew" "Homebrew"; then
    print_error "Homebrew is required for VS Code installation"
    print_info "Please run ./macos-setup.sh first"
    return 1
  fi
  
  print_status "Prerequisites validation passed"
}

function main() {
  print_status "Starting VS Code setup..."
  
  # Validate prerequisites
  if ! validate_prerequisites; then
    print_error "Prerequisites validation failed"
    exit 1
  fi
  
  # Run setup steps
  local steps=(
    "install_vscode"
    "install_vscode_extensions"
    "configure_vscode_settings"
  )
  
  local current=0
  local total=${#steps[@]}
  
  for step in "${steps[@]}"; do
    ((current++))
    show_progress "$current" "$total" "$step"
    
    if ! "$step"; then
      print_error "Step '$step' failed"
      if [[ "$DRY_RUN" != true ]]; then
        print_warning "Rolling back changes..."
        rollback
      fi
      exit 1
    fi
  done
  
  echo ""
  print_status "VS Code setup completed!"
  
  if [[ "$VERBOSE" == true ]]; then
    print_debug "Log file available at: $LOG_FILE"
  fi
}

# Execute main function with error handling
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi 