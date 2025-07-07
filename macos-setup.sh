#!/bin/bash
# macOS development environment setup script
# This script sets up the necessary tools and configurations on macOS

# Set color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print colored status messages
function print_status() {
  echo -e "${GREEN}[+] $1${NC}"
}

function print_warning() {
  echo -e "${YELLOW}[!] $1${NC}"
}

function print_error() {
  echo -e "${RED}[-] $1${NC}"
}

# Check if Homebrew is installed, install if not
function install_homebrew() {
  print_status "Checking for Homebrew..."
  if ! command -v brew &> /dev/null; then
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    if [ $? -ne 0 ]; then
      print_error "Failed to install Homebrew. Please install manually and run this script again."
      exit 1
    fi
  else
    print_status "Homebrew is already installed."
  fi
  
  # Make sure Homebrew is up to date
  print_status "Updating Homebrew..."
  brew update
}

# Install Docker Desktop
function install_docker() {
  print_status "Checking for Docker Desktop..."
  if ! command -v docker &> /dev/null; then
    print_status "Installing Docker Desktop..."
    print_warning "Docker Desktop requires manual installation. Opening download page..."
    open "https://www.docker.com/products/docker-desktop"
    
    read -p "Press Enter once you've installed Docker Desktop..." 
    
    if ! command -v docker &> /dev/null; then
      print_error "Docker doesn't seem to be installed. Please install Docker Desktop and run this script again."
      exit 1
    fi
  else
    print_status "Docker is already installed."
  fi
}

# Install Git
function install_git() {
  print_status "Checking for Git..."
  if ! command -v git &> /dev/null; then
    print_status "Installing Git..."
    brew install git
    
    if [ $? -ne 0 ]; then
      print_error "Failed to install Git. Please install manually and run this script again."
      exit 1
    fi
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
    sed -i '' 's/^plugins=.*/plugins=(git docker docker-compose npm node python pip vscode zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
  else
    echo 'plugins=(git docker docker-compose npm node python pip vscode zsh-autosuggestions zsh-syntax-highlighting)' >> "$HOME/.zshrc"
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

# Main function
function main() {
  print_status "Starting macOS development environment setup..."
  
  install_homebrew
  install_docker
  install_git
  setup_zsh
  install_pyenv
  
  print_status "Setup completed successfully!"
  print_warning "Some changes may require you to restart your terminal or applications."
  print_warning "Don't forget to allocate enough resources to Docker Desktop in its preferences."
  
  print_status "Next steps:"
  echo "1. Run the project setup script to create your development project"
  echo "2. Open the project in VS Code and start developing!"
}

# Run the main function
main
