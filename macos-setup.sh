#!/bin/bash
# macOS development environment setup script
# This script sets up the necessary tools and configurations on macOS

# Source the utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

# Initialize error handling and logging
setup_error_handling
init_logging "macos_setup"
parse_common_args "$@"

# Required dependencies for this script
REQUIRED_DEPS=("curl" "git")

# Check if Homebrew is installed, install if not
function install_homebrew() {
  print_status "Checking for Homebrew..."
  
  if ! check_command "brew" "Homebrew"; then
    print_status "Installing Homebrew..."
    
    if [[ "$DRY_RUN" == true ]]; then
      print_info "DRY RUN: Would install Homebrew"
      return 0
    fi
    
    if ! retry 3 5 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
      print_error "Failed to install Homebrew after 3 attempts"
      return 1
    fi
    
    # Add rollback action
    ROLLBACK_ACTIONS+=("echo 'Please manually uninstall Homebrew if needed'")
  else
    print_status "Homebrew is already installed."
  fi
  
  # Make sure Homebrew is up to date
  print_status "Updating Homebrew..."
  if [[ "$DRY_RUN" != true ]]; then
    brew update || print_warning "Failed to update Homebrew"
  fi
}

# Install Docker Desktop
function install_docker() {
  print_status "Checking for Docker Desktop..."
  
  if ! check_command "docker" "Docker Desktop"; then
    print_status "Installing Docker Desktop..."
    print_warning "Docker Desktop requires manual installation. Opening download page..."
    
    if [[ "$DRY_RUN" == true ]]; then
      print_info "DRY RUN: Would open Docker Desktop download page"
      return 0
    fi
    
    open "https://www.docker.com/products/docker-desktop"
    
    if [[ "$SKIP_CONFIRMATIONS" != true ]]; then
      read -p "Press Enter once you've installed Docker Desktop..." 
    else
      print_info "Skipping confirmation - assuming Docker will be installed"
    fi
    
    # Verify installation
    if ! check_command "docker" "Docker Desktop"; then
      print_error "Docker doesn't seem to be installed. Please install Docker Desktop and run this script again."
      return 1
    fi
  else
    print_status "Docker is already installed."
  fi
}

# Install Git
function install_git() {
  print_status "Checking for Git..."
  
  if ! check_command "git" "Git"; then
    print_status "Installing Git..."
    
    if [[ "$DRY_RUN" == true ]]; then
      print_info "DRY RUN: Would install Git via Homebrew"
      return 0
    fi
    
    if ! retry 3 2 brew install git; then
      print_error "Failed to install Git after 3 attempts"
      return 1
    fi
    
    ROLLBACK_ACTIONS+=("brew uninstall git")
  else
    print_status "Git is already installed."
  fi
}

# Setup Zsh with Powerlevel10k
function setup_zsh() {
  print_status "Setting up Zsh with Powerlevel10k..."
  
  # Install MesloLGS NF font
  print_status "Installing MesloLGS NF font..."
  brew tap homebrew/cask-fonts
  brew install --cask font-meslo-lg-nerd-font
  
  # Install Oh My Zsh if not already installed
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    print_status "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  else
    print_status "Oh My Zsh is already installed."
  fi
  
  # Install Powerlevel10k theme if not already installed
  if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    print_status "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
  else
    print_status "Powerlevel10k theme is already installed."
  fi
  
  # Install Zsh plugins
  print_status "Installing Zsh plugins..."
  if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  fi
  
  if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  fi
  
  # Update .zshrc
  print_status "Updating .zshrc configuration..."
  
  # Backup existing .zshrc
  if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%s)"
    print_status "Backed up existing .zshrc"
  fi
  
  # Update ZSH_THEME
  if grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
    sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
  else
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$HOME/.zshrc"
  fi
  
  # Update plugins
  if grep -q '^plugins=' "$HOME/.zshrc"; then
    sed -i '' 's/^plugins=.*/plugins=(git docker docker-compose npm node python pip zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
  else
    echo 'plugins=(git docker docker-compose npm node python pip zsh-autosuggestions zsh-syntax-highlighting)' >> "$HOME/.zshrc"
  fi
  
  # Add Powerlevel10k config reference
  if ! grep -q '\.p10k\.zsh' "$HOME/.zshrc"; then
    echo '# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh' >> "$HOME/.zshrc"
    echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> "$HOME/.zshrc"
  fi
  
  print_status "Zsh setup completed."
  print_warning "Please restart your terminal or run 'source ~/.zshrc' to apply changes."
  print_warning "After restarting, run 'p10k configure' to set up your prompt."
}

# Install pyenv
function install_pyenv() {
  print_status "Checking for pyenv..."
  if ! command -v pyenv &> /dev/null; then
    print_status "Installing pyenv..."
    brew install pyenv
    
    # Add pyenv to shell
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$HOME/.zshrc"
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> "$HOME/.zshrc"
    echo 'eval "$(pyenv init --path)"' >> "$HOME/.zshrc"
    echo 'eval "$(pyenv init -)"' >> "$HOME/.zshrc"
    
    # Load pyenv for current session
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    
    print_status "pyenv installed and configured."
  else
    print_status "pyenv is already installed."
  fi
}

# Show help for this script
function show_help() {
  cat << EOF
macOS Development Environment Setup

This script installs and configures development tools on macOS.

Usage: $0 [options]

Options:
  -v, --verbose    Enable verbose output
  -d, --dry-run    Show what would be done without making changes
  -h, --help       Show this help message

Components installed:
  - Homebrew package manager
  - Docker Desktop
  - Git version control
  - Zsh with Powerlevel10k theme
  - pyenv Python version manager

Examples:
  $0                # Run full setup
  $0 --dry-run      # Preview what would be installed
  $0 --verbose      # Show detailed output
EOF
}

# Validate system requirements
function validate_system() {
  print_status "Validating system requirements..."
  
  # Check macOS version
  if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is designed for macOS only"
    return 1
  fi
  
  # Check for required commands
  if ! check_dependencies "${REQUIRED_DEPS[@]}"; then
    print_error "Missing required dependencies"
    return 1
  fi
  
  # Check for admin privileges
  if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root is not recommended"
    if ! confirm "Continue anyway?"; then
      return 1
    fi
  fi
  
  print_status "System validation passed"
}

# Main function
function main() {
  print_status "Starting macOS development environment setup..."
  
  # Validate system before proceeding
  if ! validate_system; then
    print_error "System validation failed"
    exit 1
  fi
  
  # Run installation steps
  local steps=(
    "install_homebrew"
    "install_docker" 
    "install_git"
    "setup_zsh"
    "install_pyenv"
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
  print_status "Setup completed successfully!"
  print_warning "Some changes may require you to restart your terminal or applications."
  print_warning "Don't forget to allocate enough resources to Docker Desktop in its preferences."
  
  print_status "Next steps:"
  echo "1. Run ./project-setup.sh to create your development project"
  echo "2. Open the project in VS Code and start developing!"
  
  if [[ "$VERBOSE" == true ]]; then
    print_debug "Log file available at: $LOG_FILE"
  fi
}

# Execute main function with error handling
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
