#!/bin/bash
# Configuration management for project template
# This script handles loading, saving, and managing project configurations

# Source the utilities library
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Configuration file paths (dynamic to support test environments)
function get_global_config_path() { echo "$CONFIG_DIR/global.conf"; }
function get_project_config_path() { echo "$CONFIG_DIR/project.conf"; }
function get_user_config_path() { echo "$CONFIG_DIR/user.conf"; }

# Default configuration values
DEFAULT_PYTHON_VERSION="3.11"
DEFAULT_NODE_VERSION="20"
DEFAULT_POSTGRES_VERSION="15"
DEFAULT_REDIS_VERSION="7"
DEFAULT_N8N_VERSION="latest"

# Docker Hub configuration (configurable via global.conf)
DEFAULT_DOCKER_HUB_USERNAME="gonzillaaa"
DEFAULT_DOCKER_HUB_REGISTRY="registry-1.docker.io/v2"
DEFAULT_SPINBOX_PYTHON_BASE_IMAGE="${DEFAULT_DOCKER_HUB_USERNAME}/spinbox-python-base"
DEFAULT_SPINBOX_NODE_BASE_IMAGE="${DEFAULT_DOCKER_HUB_USERNAME}/spinbox-node-base"

# Global configuration variables
# Only initialize if not already set (preserve values from parent process)
: "${PYTHON_VERSION:=""}"
: "${NODE_VERSION:=""}"
: "${POSTGRES_VERSION:=""}"
: "${REDIS_VERSION:=""}"
: "${DOCKER_REGISTRY:=""}"
: "${PROJECT_AUTHOR:=""}"
: "${PROJECT_EMAIL:=""}"
: "${PROJECT_LICENSE:="MIT"}"

# Docker Hub configuration variables (configurable via global.conf)
: "${DOCKER_HUB_USERNAME:=""}"
: "${DOCKER_HUB_REGISTRY:=""}"
: "${SPINBOX_PYTHON_BASE_IMAGE:=""}"
: "${SPINBOX_NODE_BASE_IMAGE:=""}"

DEFAULT_COMPONENTS=""

# Project-specific configuration variables (preserve existing values)
: "${PROJECT_NAME:=""}"
: "${PROJECT_DESCRIPTION:=""}"
: "${USE_BACKEND:=""}"
: "${USE_FRONTEND:=""}"
: "${USE_DATABASE:=""}"
: "${USE_REDIS:=""}"
: "${BACKEND_PORT:="8000"}"
: "${FRONTEND_PORT:="3000"}"
: "${DATABASE_PORT:="5432"}"
: "${REDIS_PORT:="6379"}"

# User preferences
PREFERRED_EDITOR="code"
TERMINAL_THEME="powerlevel10k"
AUTO_START_SERVICES="true"
SKIP_CONFIRMATIONS="false"

# Initialize configuration system
function init_config() {
  safe_create_dir "$CONFIG_DIR"
  
  # Create default global config if it doesn't exist
  if [[ ! -f "$(get_global_config_path)" ]]; then
    create_default_global_config
  fi
  
  # Load existing configurations
  load_global_config
  load_user_config
}

# Create default global configuration
function create_default_global_config() {
  cat > "$(get_global_config_path)" << EOF
# Global configuration for project template
# This file contains default values used across all projects

# Software versions
PYTHON_VERSION="$DEFAULT_PYTHON_VERSION"
NODE_VERSION="$DEFAULT_NODE_VERSION"
POSTGRES_VERSION="$DEFAULT_POSTGRES_VERSION"
REDIS_VERSION="$DEFAULT_REDIS_VERSION"

# Docker configuration
DOCKER_REGISTRY=""

# Default project settings
PROJECT_AUTHOR=""
PROJECT_EMAIL=""
PROJECT_LICENSE="MIT"
DEFAULT_COMPONENTS=""

# Generated on $(date)
EOF

  print_debug "Created default global configuration"
}

# Load global configuration
function load_global_config() {
  if load_config "$(get_global_config_path)"; then
    print_debug "Loaded global configuration"
  else
    print_warning "Could not load global configuration, using defaults"
  fi
}

# Save global configuration
function save_global_config() {
  local vars=(
    "PYTHON_VERSION"
    "NODE_VERSION" 
    "POSTGRES_VERSION"
    "REDIS_VERSION"
    "DOCKER_REGISTRY"
    "PROJECT_AUTHOR"
    "PROJECT_EMAIL"
    "PROJECT_LICENSE"
    "DEFAULT_COMPONENTS"
  )
  
  save_config "$(get_global_config_path)" "${vars[@]}"
  print_status "Saved global configuration"
}

# Load user configuration
function load_user_config() {
  if load_config "$(get_user_config_path)"; then
    print_debug "Loaded user configuration"
  else
    print_debug "No user configuration found"
  fi
}

# Save user configuration
function save_user_config() {
  local vars=(
    "PREFERRED_EDITOR"
    "TERMINAL_THEME"
    "AUTO_START_SERVICES"
    "SKIP_CONFIRMATIONS"
  )
  
  save_config "$(get_user_config_path)" "${vars[@]}"
  print_status "Saved user configuration"
}

# Load project configuration
function load_project_config() {
  local project_dir="${1:-.}"
  local config_file="$project_dir/.config/project.conf"
  
  if load_config "$config_file"; then
    print_debug "Loaded project configuration from $config_file"
    return 0
  else
    print_debug "No project configuration found"
    return 1
  fi
}

# Save project configuration
function save_project_config() {
  local project_dir="${1:-.}"
  local config_file="$project_dir/.config/project.conf"
  
  safe_create_dir "$(dirname "$config_file")"
  
  local vars=(
    "PROJECT_NAME"
    "PROJECT_DESCRIPTION"
    "USE_BACKEND"
    "USE_FRONTEND"
    "USE_DATABASE"
    "USE_REDIS"
    "BACKEND_PORT"
    "FRONTEND_PORT"
    "DATABASE_PORT"
    "REDIS_PORT"
  )
  
  save_config "$config_file" "${vars[@]}"
  print_status "Saved project configuration to $config_file"
}

# Interactive configuration setup
function setup_global_config() {
  print_status "Setting up global configuration..."
  
  # Author information
  if [[ -z "$PROJECT_AUTHOR" ]]; then
    read -r -p "Enter your name (for project metadata): " PROJECT_AUTHOR
  fi
  
  if [[ -z "$PROJECT_EMAIL" ]]; then
    while true; do
      read -r -p "Enter your email: " PROJECT_EMAIL
      if validate_email "$PROJECT_EMAIL"; then
        break
      fi
    done
  fi
  
  # Default license
  echo "Available licenses: MIT, Apache-2.0, GPL-3.0, BSD-3-Clause, Unlicense"
  read -r -p "Default license for projects [$PROJECT_LICENSE]: " license_input
  PROJECT_LICENSE="${license_input:-$PROJECT_LICENSE}"
  
  # Software versions
  read -r -p "Python version [$PYTHON_VERSION]: " python_input
  PYTHON_VERSION="${python_input:-$PYTHON_VERSION}"
  
  read -r -p "Node.js version [$NODE_VERSION]: " node_input
  NODE_VERSION="${node_input:-$NODE_VERSION}"
  
  # Default components
  echo "Default components to include (comma-separated):"
  echo "  backend, frontend, database, redis"
  read -r -p "Default components []: " DEFAULT_COMPONENTS
  
  save_global_config
}

# Interactive user preferences setup
function setup_user_config() {
  print_status "Setting up user preferences..."
  
  # Preferred editor
  echo "Available editors: code, vim, nano, emacs"
  read -r -p "Preferred editor [$PREFERRED_EDITOR]: " editor_input
  PREFERRED_EDITOR="${editor_input:-$PREFERRED_EDITOR}"
  
  # Auto-start services
  if confirm "Auto-start services when opening projects?" "y"; then
    AUTO_START_SERVICES="true"
  else
    AUTO_START_SERVICES="false"
  fi
  
  # Skip confirmations
  if confirm "Skip confirmation prompts for routine operations?" "n"; then
    SKIP_CONFIRMATIONS="true"
  else
    SKIP_CONFIRMATIONS="false"
  fi
  
  save_user_config
}

# Get configuration value with fallback
function get_config_value() {
  local key="$1"
  local default_value="$2"
  local value="${!key}"
  
  if [[ -n "$value" ]]; then
    echo "$value"
  else
    echo "$default_value"
  fi
}

# Set configuration value
function set_config_value() {
  local key="$1"
  local value="$2"
  local scope="${3:-global}" # global, user, or project
  
  # Validate the key exists
  case "$scope" in
    global)
      if [[ " PYTHON_VERSION NODE_VERSION POSTGRES_VERSION REDIS_VERSION DOCKER_REGISTRY PROJECT_AUTHOR PROJECT_EMAIL PROJECT_LICENSE DEFAULT_COMPONENTS " =~ " $key " ]]; then
        # Set the variable globally (compatible with older bash versions)
        eval "$key=\"\$value\""
        save_global_config
      else
        print_error "Invalid global configuration key: $key"
        return 1
      fi
      ;;
    user)
      if [[ " PREFERRED_EDITOR TERMINAL_THEME AUTO_START_SERVICES SKIP_CONFIRMATIONS " =~ " $key " ]]; then
        # Set the variable globally (compatible with older bash versions)
        eval "$key=\"\$value\""
        save_user_config
      else
        print_error "Invalid user configuration key: $key"
        return 1
      fi
      ;;
    project)
      if [[ " PROJECT_NAME PROJECT_DESCRIPTION USE_BACKEND USE_FRONTEND USE_DATABASE USE_REDIS BACKEND_PORT FRONTEND_PORT DATABASE_PORT REDIS_PORT " =~ " $key " ]]; then
        # Set the variable globally (compatible with older bash versions)
        eval "$key=\"\$value\""
        save_project_config
      else
        print_error "Invalid project configuration key: $key"
        return 1
      fi
      ;;
    *)
      print_error "Invalid configuration scope: $scope"
      return 1
      ;;
  esac
  
  print_status "Set $key=$value in $scope configuration"
}

# List configuration values
function list_config() {
  local scope="${1:-all}"
  
  case "$scope" in
    global|all)
      print_info "Global Configuration:"
      echo "  PYTHON_VERSION=$PYTHON_VERSION" 2>/dev/null || true
      echo "  NODE_VERSION=$NODE_VERSION" 2>/dev/null || true
      echo "  POSTGRES_VERSION=$POSTGRES_VERSION" 2>/dev/null || true
      echo "  REDIS_VERSION=$REDIS_VERSION" 2>/dev/null || true
      echo "  DOCKER_REGISTRY=$DOCKER_REGISTRY" 2>/dev/null || true
      echo "  PROJECT_AUTHOR=$PROJECT_AUTHOR" 2>/dev/null || true
      echo "  PROJECT_EMAIL=$PROJECT_EMAIL" 2>/dev/null || true
      echo "  PROJECT_LICENSE=$PROJECT_LICENSE" 2>/dev/null || true
      echo "  DEFAULT_COMPONENTS=$DEFAULT_COMPONENTS" 2>/dev/null || true
      ;;
  esac
  
  if [[ "$scope" == "all" ]]; then
    echo "" 2>/dev/null || true
  fi
  
  case "$scope" in
    user|all)
      print_info "User Configuration:"
      echo "  PREFERRED_EDITOR=$PREFERRED_EDITOR" 2>/dev/null || true
      echo "  TERMINAL_THEME=$TERMINAL_THEME" 2>/dev/null || true
      echo "  AUTO_START_SERVICES=$AUTO_START_SERVICES" 2>/dev/null || true
      echo "  SKIP_CONFIRMATIONS=$SKIP_CONFIRMATIONS"
      ;;
  esac
  
  if [[ "$scope" == "all" && -n "$PROJECT_NAME" ]]; then
    echo ""
    print_info "Project Configuration:"
    echo "  PROJECT_NAME=$PROJECT_NAME"
    echo "  PROJECT_DESCRIPTION=$PROJECT_DESCRIPTION"
    echo "  USE_BACKEND=$USE_BACKEND"
    echo "  USE_FRONTEND=$USE_FRONTEND"
    echo "  USE_DATABASE=$USE_DATABASE"
    echo "  USE_REDIS=$USE_REDIS"
    echo "  BACKEND_PORT=$BACKEND_PORT"
    echo "  FRONTEND_PORT=$FRONTEND_PORT"
    echo "  DATABASE_PORT=$DATABASE_PORT"
    echo "  REDIS_PORT=$REDIS_PORT"
  fi
}

# Reset configuration to defaults
function reset_config() {
  local scope="$1"
  
  case "$scope" in
    global)
      if confirm "Reset global configuration to defaults?" "n"; then
        rm -f "$(get_global_config_path)"
        create_default_global_config
        load_global_config
        print_status "Global configuration reset to defaults"
      fi
      ;;
    user)
      if confirm "Reset user configuration to defaults?" "n"; then
        rm -f "$(get_user_config_path)"
        # Reset variables to defaults
        PREFERRED_EDITOR="code"
        TERMINAL_THEME="powerlevel10k"
        AUTO_START_SERVICES="true"
        SKIP_CONFIRMATIONS="false"
        print_status "User configuration reset to defaults"
      fi
      ;;
    project)
      local project_dir="${2:-.}"
      local config_file="$project_dir/.config/project.conf"
      if confirm "Reset project configuration?" "n"; then
        rm -f "$config_file"
        print_status "Project configuration reset"
      fi
      ;;
    *)
      print_error "Invalid scope. Use: global, user, or project"
      return 1
      ;;
  esac
}

# Import configuration from file
function import_config() {
  local file_path="$1"
  local scope="$2"
  
  if [[ ! -f "$file_path" ]]; then
    print_error "Configuration file not found: $file_path"
    return 1
  fi
  
  case "$scope" in
    global)
      cp "$file_path" "$(get_global_config_path)"
      load_global_config
      print_status "Imported global configuration from $file_path"
      ;;
    user)
      cp "$file_path" "$(get_user_config_path)"
      load_user_config
      print_status "Imported user configuration from $file_path"
      ;;
    *)
      print_error "Invalid scope for import. Use: global or user"
      return 1
      ;;
  esac
}

# Export configuration to file
function export_config() {
  local scope="$1"
  local file_path="$2"
  
  case "$scope" in
    global)
      cp "$(get_global_config_path)" "$file_path"
      print_status "Exported global configuration to $file_path"
      ;;
    user)
      cp "$(get_user_config_path)" "$file_path"
      print_status "Exported user configuration to $file_path"
      ;;
    *)
      print_error "Invalid scope for export. Use: global or user"
      return 1
      ;;
  esac
}

# Validate configuration
function validate_config() {
  local errors=0
  
  # Validate email if set
  if [[ -n "$PROJECT_EMAIL" ]] && ! validate_email "$PROJECT_EMAIL"; then
    ((errors++))
  fi
  
  # Validate version formats
  if [[ ! "$PYTHON_VERSION" =~ ^[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid Python version format: $PYTHON_VERSION"
    ((errors++))
  fi
  
  if [[ ! "$NODE_VERSION" =~ ^[0-9]+$ ]]; then
    print_error "Invalid Node.js version format: $NODE_VERSION"
    ((errors++))
  fi
  
  # Validate ports
  for port_var in BACKEND_PORT FRONTEND_PORT DATABASE_PORT REDIS_PORT; do
    local port="${!port_var}"
    if [[ -n "$port" ]] && [[ ! "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 || "$port" -gt 65535 ]]; then
      print_error "Invalid port number for $port_var: $port"
      ((errors++))
    fi
  done
  
  if [[ $errors -eq 0 ]]; then
    print_status "Configuration validation passed"
    return 0
  else
    print_error "Configuration validation failed with $errors errors"
    return 1
  fi
}

# Note: Configuration must be explicitly initialized with init_config