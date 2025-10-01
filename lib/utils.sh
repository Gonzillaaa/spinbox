#!/bin/bash
# Shared utilities library for project template scripts
# This library provides common functionality used across all scripts

# Constants (avoid conflicts with multiple sourcing)
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
if [[ -z "${PROJECT_ROOT:-}" ]]; then
    readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
fi
# Allow CONFIG_DIR to be overridden for testing
: "${CONFIG_DIR:=$HOME/.spinbox}"
if [[ -z "${LOG_DIR:-}" ]]; then
    readonly LOG_DIR="$PROJECT_ROOT/.logs"
fi
if [[ -z "${BACKUP_DIR:-}" ]]; then
    readonly BACKUP_DIR="$PROJECT_ROOT/.backups"
fi

# Installation stability constants (avoid conflicts with multiple sourcing)
if [[ -z "${SPINBOX_LOCK_FILE:-}" ]]; then
    readonly SPINBOX_LOCK_FILE="$CONFIG_DIR/.spinbox.lock"
fi
if [[ -z "${RUNTIME_DIR:-}" ]]; then
    readonly RUNTIME_DIR="$CONFIG_DIR/runtime"
fi
if [[ -z "${CACHE_DIR:-}" ]]; then
    readonly CACHE_DIR="$CONFIG_DIR/cache"
fi

# Color codes for output (avoid conflicts with multiple sourcing)
if [[ -z "${GREEN:-}" ]]; then
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly RED='\033[0;31m'
    readonly BLUE='\033[0;34m'
    readonly PURPLE='\033[0;35m'
    readonly NC='\033[0m' # No Color
fi

# Global variables (use conditional assignment to preserve existing values)
: "${VERBOSE:=false}"
: "${DRY_RUN:=false}"
LOG_FILE=""
ROLLBACK_ACTIONS=()

# Initialize logging
function init_logging() {
  local script_name="${1:-unknown}"
  mkdir -p "$LOG_DIR"
  LOG_FILE="$LOG_DIR/${script_name}_$(date +%Y%m%d_%H%M%S).log"
  touch "$LOG_FILE"
}

# Logging functions
function log_message() {
  local level="$1"
  local message="$2"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  # Only log to file if LOG_FILE is set and exists
  if [[ -n "${LOG_FILE:-}" && -f "$LOG_FILE" ]]; then
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
  fi
  
  if [[ "$VERBOSE" == true ]]; then
    echo "[$level] $message" >&2
  fi
}

function log_info() {
  log_message "INFO" "$1"
}

function log_warn() {
  log_message "WARN" "$1"
}

function log_error() {
  log_message "ERROR" "$1"
}

function log_debug() {
  if [[ "$VERBOSE" == true ]]; then
    log_message "DEBUG" "$1"
  fi
}

# Print colored status messages
function print_status() {
  echo -e "${GREEN}[+] $1${NC}"
  log_info "$1"
}

function print_warning() {
  echo -e "${YELLOW}[!] $1${NC}"
  log_warn "$1"
}

function print_error() {
  echo -e "${RED}[-] $1${NC}"
  log_error "$1"
}

function print_info() {
  echo -e "${BLUE}[i] $1${NC}" 2>/dev/null || true
  log_info "$1"
}

function print_debug() {
  if [[ "$VERBOSE" == true ]]; then
    echo -e "${PURPLE}[d] $1${NC}"
    log_debug "$1"
  fi
}

# Progress indicator functions
function show_progress() {
  local current="$1"
  local total="$2"
  local description="$3"
  local percent=$((current * 100 / total))
  local filled=$((percent / 2))
  local empty=$((50 - filled))
  
  printf "\r${BLUE}[%s%s] %d%% %s${NC}" \
    "$(printf "%*s" "$filled" | tr ' ' '=')" \
    "$(printf "%*s" "$empty")" \
    "$percent" \
    "$description"
  
  if [[ "$current" -eq "$total" ]]; then
    echo ""
  fi
}

function spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}

# Input validation functions
function validate_project_name() {
  local name="$1"

  # Check for empty name
  if [[ -z "$name" ]]; then
    print_error "Project name cannot be empty"
    print_info "Usage: spinbox create <PROJECT_NAME> [OPTIONS]"
    print_info "Example: spinbox create myproject --python"
    return 1
  fi

  # Check length (max 50 characters for filesystem compatibility)
  if [[ ${#name} -gt 50 ]]; then
    print_error "Project name too long: '$name' (${#name} characters)"
    print_info "Project names must be 50 characters or less"
    print_info "Current length: ${#name} characters"
    print_info "Try a shorter name like: ${name:0:50}"
    return 1
  fi

  # Check format
  if [[ ! "$name" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
    print_error "Invalid project name: '$name'"
    print_info "Project names must:"
    print_info "  • Start with a lowercase letter or number"
    print_info "  • Contain only lowercase letters, numbers, hyphens (-) and underscores (_)"
    print_info "Valid examples: myproject, my-app, web_app_v2"
    return 1
  fi
  return 0
}

function validate_email() {
  local email="$1"
  if [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    print_error "Invalid email format."
    return 1
  fi
  return 0
}

function validate_url() {
  local url="$1"
  if [[ ! "$url" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/.*)?$ ]]; then
    print_error "Invalid URL format."
    return 1
  fi
  return 0
}

# Dependency checking functions
function check_command() {
  local cmd="$1"
  local package_name="${2:-$cmd}"
  
  if ! command -v "$cmd" &> /dev/null; then
    print_error "$cmd is not installed. Please install $package_name and try again."
    return 1
  fi
  print_debug "$cmd is available"
  return 0
}

function check_dependencies() {
  local deps=("$@")
  local missing=()
  
  for dep in "${deps[@]}"; do
    if ! check_command "$dep"; then
      missing+=("$dep")
    fi
  done
  
  if [[ ${#missing[@]} -gt 0 ]]; then
    print_error "Missing dependencies: ${missing[*]}"
    return 1
  fi
  
  print_status "All dependencies are satisfied"
  return 0
}

# File operations with rollback support
function backup_file() {
  local file_path="$1"
  local backup_name="${2:-$(basename "$file_path").backup.$(date +%s)}"
  
  if [[ -f "$file_path" ]]; then
    mkdir -p "$BACKUP_DIR"
    local backup_path="$BACKUP_DIR/$backup_name"
    cp "$file_path" "$backup_path"
    ROLLBACK_ACTIONS+=("restore_file '$backup_path' '$file_path'")
    print_debug "Backed up $file_path to $backup_path"
    return 0
  fi
  return 1
}

function restore_file() {
  local backup_path="$1"
  local original_path="$2"
  
  if [[ -f "$backup_path" ]]; then
    cp "$backup_path" "$original_path"
    print_debug "Restored $original_path from $backup_path"
    return 0
  fi
  return 1
}

function safe_write_file() {
  local file_path="$1"
  local content="$2"
  
  if [[ "$DRY_RUN" == true ]]; then
    print_info "DRY RUN: Would write to $file_path"
    return 0
  fi
  
  backup_file "$file_path"
  echo "$content" > "$file_path"
  ROLLBACK_ACTIONS+=("rm -f '$file_path'")
  print_debug "Wrote to $file_path"
}

function safe_create_dir() {
  local dir_path="$1"
  
  if [[ "$DRY_RUN" == true ]]; then
    print_info "DRY RUN: Would create directory $dir_path"
    return 0
  fi
  
  if [[ ! -d "$dir_path" ]]; then
    mkdir -p "$dir_path"
    ROLLBACK_ACTIONS+=("rmdir '$dir_path' 2>/dev/null || true")
    print_debug "Created directory $dir_path"
  fi
}

# Error handling and rollback
function handle_error() {
  local exit_code="$1"
  local line_number="$2"
  local command="$3"
  
  print_error "Error occurred at line $line_number: command '$command' exited with code $exit_code"
  
  if [[ ${#ROLLBACK_ACTIONS[@]} -gt 0 ]]; then
    print_warning "Attempting to rollback changes..."
    rollback
  fi
  
  exit "$exit_code"
}

function rollback() {
  local action
  for ((i=${#ROLLBACK_ACTIONS[@]}-1; i>=0; i--)); do
    action="${ROLLBACK_ACTIONS[i]}"
    print_debug "Rollback: $action"
    eval "$action" || print_warning "Failed to rollback: $action"
  done
  ROLLBACK_ACTIONS=()
  print_status "Rollback completed"
}

# Configuration management
function load_config() {
  local config_file="$1"
  
  if [[ -f "$config_file" ]]; then
    # shellcheck source=/dev/null
    source "$config_file"
    print_debug "Loaded configuration from $config_file"
    return 0
  else
    print_debug "Configuration file not found: $config_file"
    return 1
  fi
}

function save_config() {
  local config_file="$1"
  shift
  local variables=("$@")
  
  mkdir -p "$(dirname "$config_file")"
  
  {
    echo "# Auto-generated configuration file"
    echo "# Generated on $(date)"
    echo ""
    
    for var in "${variables[@]}"; do
      if [[ -n "${!var:-}" ]]; then
        echo "$var=\"${!var}\""
      fi
    done
  } > "$config_file"
  
  print_debug "Saved configuration to $config_file"
}

# Utility functions
function confirm() {
  local prompt="$1"
  local default="${2:-n}"
  local response
  
  if [[ "$default" == "y" ]]; then
    prompt="$prompt [Y/n]: "
  else
    prompt="$prompt [y/N]: "
  fi
  
  read -r -p "$prompt" response
  response="${response:-$default}"
  
  case "$response" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

function retry() {
  local max_attempts="$1"
  local delay="$2"
  shift 2
  local command=("$@")
  
  local attempt=1
  while [[ $attempt -le $max_attempts ]]; do
    if "${command[@]}"; then
      return 0
    fi
    
    if [[ $attempt -lt $max_attempts ]]; then
      print_warning "Attempt $attempt failed. Retrying in ${delay}s..."
      sleep "$delay"
    fi
    
    ((attempt++))
  done
  
  print_error "Command failed after $max_attempts attempts"
  return 1
}

function cleanup() {
  print_debug "Cleaning up temporary files"
  # Add cleanup logic here
}

# Set up error handling
function setup_error_handling() {
  set -eE
  trap 'handle_error $? $LINENO "$BASH_COMMAND"' ERR
  trap cleanup EXIT
}

# Parse common command line arguments
function parse_common_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -v|--verbose)
        VERBOSE=true
        shift
        ;;
      -d|--dry-run)
        DRY_RUN=true
        shift
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        # Unknown option, let the calling script handle it
        break
        ;;
    esac
  done
}

# Default help function (can be overridden)
function show_help() {
  echo "Common options:"
  echo "  -v, --verbose    Enable verbose output"
  echo "  -d, --dry-run    Show what would be done without making changes"
  echo "  -h, --help       Show this help message"
}

# Installation state validation and locking functions
function validate_installation_state() {
    local operation="${1:-operation}"
    
    # Check basic installation structure
    if [[ ! -d "$RUNTIME_DIR" ]]; then
        print_error "Runtime directory missing: $RUNTIME_DIR"
        print_info "Please reinstall Spinbox or run migration"
        return 1
    fi
    
    # Check critical runtime files
    if [[ ! -d "$RUNTIME_DIR/lib" ]]; then
        print_error "Runtime libraries missing: $RUNTIME_DIR/lib"
        return 1
    fi
    
    # Check binary exists and is executable
    local binary_paths=("$HOME/.local/bin/spinbox" "/usr/local/bin/spinbox")
    local binary_found=false
    
    for path in "${binary_paths[@]}"; do
        if [[ -x "$path" ]]; then
            binary_found=true
            break
        fi
    done
    
    if [[ "$binary_found" != true ]]; then
        print_error "Spinbox binary not found or not executable"
        return 1
    fi
    
    print_debug "Installation state validation passed for: $operation"
    return 0
}

function acquire_spinbox_lock() {
    local operation="${1:-operation}"
    local timeout="${2:-30}"
    local waited=0
    
    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"
    
    # Wait for existing lock to clear
    while [[ -f "$SPINBOX_LOCK_FILE" ]] && [[ $waited -lt $timeout ]]; do
        if [[ $waited -eq 0 ]]; then
            print_info "Waiting for concurrent Spinbox operation to complete..."
        fi
        sleep 1
        ((waited++))
    done
    
    # Check if we timed out
    if [[ -f "$SPINBOX_LOCK_FILE" ]] && [[ $waited -ge $timeout ]]; then
        print_error "Timeout waiting for lock. Another Spinbox operation may be stuck."
        print_info "If no other operations are running, remove: $SPINBOX_LOCK_FILE"
        return 1
    fi
    
    # Create lock file with process info
    echo "$$:$operation:$(date)" > "$SPINBOX_LOCK_FILE"
    
    # Verify we got the lock (handle race conditions)
    local lock_content
    lock_content=$(cat "$SPINBOX_LOCK_FILE" 2>/dev/null || echo "")
    if [[ "$lock_content" != "$$:$operation:"* ]]; then
        print_error "Failed to acquire lock (race condition)"
        return 1
    fi
    
    print_debug "Acquired lock for: $operation (PID: $$)"
    return 0
}

function release_spinbox_lock() {
    if [[ -f "$SPINBOX_LOCK_FILE" ]]; then
        local lock_content
        lock_content=$(cat "$SPINBOX_LOCK_FILE" 2>/dev/null || echo "")
        if [[ "$lock_content" == "$$:"* ]]; then
            rm -f "$SPINBOX_LOCK_FILE"
            print_debug "Released lock (PID: $$)"
        else
            print_warning "Lock file not owned by this process, not removing"
        fi
    fi
}

function validate_path_safety() {
    local target_path="$1"
    local operation="${2:-operation}"
    
    # Resolve absolute path
    local abs_path
    abs_path=$(cd "$(dirname "$target_path")" 2>/dev/null && pwd)/$(basename "$target_path") || return 1
    
    # Protected directories that should never be removed
    local protected_dirs=(
        "$HOME/.local/bin"
        "/usr/local/bin"
        "$HOME/.spinbox/runtime"
        "$HOME/.local"
        "$HOME"
        "/"
        "/usr"
        "/usr/local"
    )
    
    for protected in "${protected_dirs[@]}"; do
        if [[ "$abs_path" == "$protected" ]] || [[ "$abs_path" == "$protected"/* ]]; then
            print_error "Refusing $operation on protected directory: $abs_path"
            print_info "Protected path detected: $protected"
            return 1
        fi
    done
    
    print_debug "Path safety validation passed: $abs_path"
    return 0
}

# Auto-cleanup lock on script exit
function cleanup_lock_on_exit() {
    release_spinbox_lock
}

# Check if sufficient disk space is available
# Usage: check_disk_space <path> <required_kb>
# Returns: 0 if sufficient space, 1 if insufficient
function check_disk_space() {
    local target_path="$1"
    local required_kb="${2:-10240}"  # Default: 10MB minimum

    # Get parent directory if path doesn't exist yet
    local check_path="$target_path"
    if [[ ! -d "$check_path" ]]; then
        check_path=$(dirname "$target_path")
    fi

    # Get available space in KB
    local available_kb
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: df -k returns KB
        available_kb=$(df -k "$check_path" | awk 'NR==2 {print $4}')
    else
        # Linux: df -k returns KB
        available_kb=$(df -k "$check_path" | awk 'NR==2 {print $4}')
    fi

    # Check if we got a valid number
    if [[ ! "$available_kb" =~ ^[0-9]+$ ]]; then
        print_warning "Could not determine available disk space"
        return 0  # Don't block on error
    fi

    # Compare available vs required
    if [[ $available_kb -lt $required_kb ]]; then
        local available_mb=$((available_kb / 1024))
        local required_mb=$((required_kb / 1024))
        print_error "Insufficient disk space"
        print_info "Available: ${available_mb}MB"
        print_info "Required: ${required_mb}MB (minimum)"
        print_info "Free up space and try again"
        return 1
    fi

    return 0
}

# Install exit trap for lock cleanup
trap cleanup_lock_on_exit EXIT

# Export functions for use in other scripts
export -f print_status print_warning print_error print_info print_debug
export -f log_info log_warn log_error log_debug
export -f show_progress spinner
export -f validate_project_name validate_email validate_url
export -f check_command check_dependencies
export -f backup_file restore_file safe_write_file safe_create_dir
export -f handle_error rollback
export -f load_config save_config
export -f confirm retry cleanup
export -f setup_error_handling parse_common_args show_help
export -f validate_installation_state acquire_spinbox_lock release_spinbox_lock
export -f validate_path_safety cleanup_lock_on_exit check_disk_space