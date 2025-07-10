#!/bin/bash
# Profile management for Spinbox
# Handles loading and applying predefined project configurations

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Profile system variables
PROFILES_DIR=""
AVAILABLE_PROFILES=()

# Initialize profile system
function init_profiles() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROFILES_DIR="$(dirname "$script_dir")/templates/profiles"
    
    # Load available profiles
    load_available_profiles
}

# Load list of available profiles
function load_available_profiles() {
    AVAILABLE_PROFILES=()
    
    if [[ -d "$PROFILES_DIR" ]]; then
        for profile_file in "$PROFILES_DIR"/*.toml; do
            if [[ -f "$profile_file" ]]; then
                local profile_name=$(basename "$profile_file" .toml)
                AVAILABLE_PROFILES+=("$profile_name")
            fi
        done
    fi
}

# Simple TOML parser for profile files
function parse_profile_toml() {
    local profile_file="$1"
    local section=""
    
    # Clear any existing profile variables
    unset PROFILE_NAME PROFILE_DESCRIPTION
    unset PROFILE_BACKEND PROFILE_FRONTEND PROFILE_DATABASE
    unset PROFILE_REDIS PROFILE_MONGODB PROFILE_CHROMA
    unset PROFILE_PYTHON_VERSION PROFILE_NODE_VERSION PROFILE_POSTGRES_VERSION PROFILE_REDIS_VERSION
    unset PROFILE_PYTHON_REQUIREMENTS
    
    while IFS= read -r line; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Detect sections
        if [[ "$line" =~ ^\[([^\]]+)\] ]]; then
            section="${BASH_REMATCH[1]}"
            # Found section
            continue
        fi
        
        # Parse key-value pairs
        if [[ "$line" =~ ^[[:space:]]*([^=]+)[[:space:]]*=[[:space:]]*(.+) ]]; then
            local key="${BASH_REMATCH[1]// /}"
            local value="${BASH_REMATCH[2]}"
            
            # Remove quotes from value
            value="${value//\"/}"
            value="${value//\'/}"
            
            # Parsing key-value pair
            
            case "$section" in
                "profile")
                    case "$key" in
                        "name") PROFILE_NAME="$value" ;;
                        "description") PROFILE_DESCRIPTION="$value" ;;
                    esac
                    ;;
                "components")
                    case "$key" in
                        "backend") PROFILE_BACKEND="$value" ;;
                        "frontend") PROFILE_FRONTEND="$value" ;;
                        "database") PROFILE_DATABASE="$value" ;;
                        "redis") PROFILE_REDIS="$value" ;;
                        "mongodb") PROFILE_MONGODB="$value" ;;
                        "chroma") PROFILE_CHROMA="$value" ;;
                    esac
                    ;;
                "configuration")
                    case "$key" in
                        "python_version") PROFILE_PYTHON_VERSION="$value" ;;
                        "node_version") PROFILE_NODE_VERSION="$value" ;;
                        "postgres_version") PROFILE_POSTGRES_VERSION="$value" ;;
                        "redis_version") PROFILE_REDIS_VERSION="$value" ;;
                    esac
                    ;;
                "templates")
                    case "$key" in
                        "python_requirements") PROFILE_PYTHON_REQUIREMENTS="$value" ;;
                    esac
                    ;;
            esac
        fi
    done < "$profile_file"
}

# Load profile configuration
function load_profile() {
    local profile_name="$1"
    local profile_file="$PROFILES_DIR/$profile_name.toml"
    
    if [[ ! -f "$profile_file" ]]; then
        print_error "Profile not found: $profile_name"
        print_info "Available profiles: ${AVAILABLE_PROFILES[*]}"
        return 1
    fi
    
    print_debug "Loading profile: $profile_name"
    parse_profile_toml "$profile_file"
    
    # Profile loaded successfully
    
    if [[ -z "$PROFILE_NAME" ]]; then
        print_error "Invalid profile file: $profile_file"
        return 1
    fi
    
    return 0
}

# Apply profile to project configuration
function apply_profile() {
    local profile_name="$1"
    
    if ! load_profile "$profile_name"; then
        return 1
    fi
    
    print_info "Applying profile: $PROFILE_NAME"
    print_info "Description: $PROFILE_DESCRIPTION"
    
    # Apply component flags
    local components=""
    
    # Always include base Python or Node environment
    if [[ "${PROFILE_BACKEND:-}" == "true" || -n "${PROFILE_PYTHON_REQUIREMENTS:-}" ]]; then
        components+=" --python"
    fi
    
    # If no components are explicitly set but we have python requirements, default to python
    if [[ -z "$components" && -n "${PROFILE_PYTHON_REQUIREMENTS:-}" ]]; then
        components+=" --python"
    fi
    
    if [[ "${PROFILE_FRONTEND:-}" == "true" ]]; then
        components+=" --node"
    fi
    
    # Add components based on profile
    [[ "${PROFILE_BACKEND:-}" == "true" ]] && components+=" --backend"
    [[ "${PROFILE_FRONTEND:-}" == "true" ]] && components+=" --frontend"
    [[ "${PROFILE_DATABASE:-}" == "true" ]] && components+=" --database"
    [[ "${PROFILE_REDIS:-}" == "true" ]] && components+=" --redis"
    [[ "${PROFILE_MONGODB:-}" == "true" ]] && components+=" --mongodb"
    [[ "${PROFILE_CHROMA:-}" == "true" ]] && components+=" --chroma"
    
    # Apply version configuration
    [[ -n "${PROFILE_PYTHON_VERSION:-}" ]] && PYTHON_VERSION="$PROFILE_PYTHON_VERSION"
    [[ -n "${PROFILE_NODE_VERSION:-}" ]] && NODE_VERSION="$PROFILE_NODE_VERSION"
    [[ -n "${PROFILE_POSTGRES_VERSION:-}" ]] && POSTGRES_VERSION="$PROFILE_POSTGRES_VERSION"
    [[ -n "${PROFILE_REDIS_VERSION:-}" ]] && REDIS_VERSION="$PROFILE_REDIS_VERSION"
    
    # Apply template configuration
    [[ -n "${PROFILE_PYTHON_REQUIREMENTS:-}" ]] && TEMPLATE="$PROFILE_PYTHON_REQUIREMENTS"
    
    # Export components for use by project generator
    export COMPONENTS="$components"
    
    print_debug "Profile components: $components"
    print_debug "Profile template: ${TEMPLATE:-default}"
    
    return 0
}

# List available profiles
function list_profiles() {
    if [[ ${#AVAILABLE_PROFILES[@]} -eq 0 ]]; then
        print_info "No profiles available"
        return 0
    fi
    
    print_info "Available Profiles:"
    echo ""
    
    for profile_name in "${AVAILABLE_PROFILES[@]}"; do
        if load_profile "$profile_name"; then
            echo "  $PROFILE_NAME"
            echo "    $PROFILE_DESCRIPTION"
            echo ""
        fi
    done
}

# Show detailed profile information
function show_profile() {
    local profile_name="$1"
    
    if ! load_profile "$profile_name"; then
        return 1
    fi
    
    echo "Profile: $PROFILE_NAME"
    echo "Description: $PROFILE_DESCRIPTION"
    echo ""
    echo "Components:"
    echo "  Python: ${PROFILE_BACKEND:-false}"
    echo "  Backend: ${PROFILE_BACKEND:-false}"
    echo "  Frontend: ${PROFILE_FRONTEND:-false}"
    echo "  Database: ${PROFILE_DATABASE:-false}"
    echo "  Redis: ${PROFILE_REDIS:-false}"
    echo "  MongoDB: ${PROFILE_MONGODB:-false}"
    echo "  Chroma: ${PROFILE_CHROMA:-false}"
    echo ""
    echo "Configuration:"
    echo "  Python Version: ${PROFILE_PYTHON_VERSION:-default}"
    echo "  Node Version: ${PROFILE_NODE_VERSION:-default}"
    echo "  PostgreSQL Version: ${PROFILE_POSTGRES_VERSION:-default}"
    echo "  Redis Version: ${PROFILE_REDIS_VERSION:-default}"
    echo ""
    echo "Templates:"
    echo "  Python Requirements: ${PROFILE_PYTHON_REQUIREMENTS:-default}"
}

# Export functions for use in other scripts
export -f init_profiles load_available_profiles parse_profile_toml
export -f load_profile apply_profile list_profiles show_profile