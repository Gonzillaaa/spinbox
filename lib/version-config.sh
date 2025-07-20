#!/bin/bash
# Version configuration system for Spinbox
# Handles CLI flag overrides and version management with hierarchy

# Source the utilities and config libraries
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# CLI override variables (highest priority)
# Only initialize if not already set (preserve values from parent process)
: "${CLI_PYTHON_VERSION:=""}"
: "${CLI_NODE_VERSION:=""}"
: "${CLI_POSTGRES_VERSION:=""}"
: "${CLI_REDIS_VERSION:=""}"
: "${CLI_USE_DOCKER_HUB:=""}"

# Configuration override hierarchy: CLI flags > config file > defaults
function get_effective_python_version() {
    if [[ -n "$CLI_PYTHON_VERSION" ]]; then
        echo "$CLI_PYTHON_VERSION"
    elif [[ -n "$PYTHON_VERSION" ]]; then
        echo "$PYTHON_VERSION"
    else
        echo "$DEFAULT_PYTHON_VERSION"
    fi
}

function get_effective_node_version() {
    if [[ -n "$CLI_NODE_VERSION" ]]; then
        echo "$CLI_NODE_VERSION"
    elif [[ -n "$NODE_VERSION" ]]; then
        echo "$NODE_VERSION"
    else
        echo "$DEFAULT_NODE_VERSION"
    fi
}

function get_effective_postgres_version() {
    if [[ -n "$CLI_POSTGRES_VERSION" ]]; then
        echo "$CLI_POSTGRES_VERSION"
    elif [[ -n "$POSTGRES_VERSION" ]]; then
        echo "$POSTGRES_VERSION"
    else
        echo "$DEFAULT_POSTGRES_VERSION"
    fi
}

function get_effective_redis_version() {
    if [[ -n "$CLI_REDIS_VERSION" ]]; then
        echo "$CLI_REDIS_VERSION"
    elif [[ -n "$REDIS_VERSION" ]]; then
        echo "$REDIS_VERSION"
    else
        echo "$DEFAULT_REDIS_VERSION"
    fi
}

# Docker Hub configuration getters (configurable hierarchy)
function get_effective_docker_hub_username() {
    if [[ -n "$DOCKER_HUB_USERNAME" ]]; then
        echo "$DOCKER_HUB_USERNAME"
    else
        echo "$DEFAULT_DOCKER_HUB_USERNAME"
    fi
}

function get_effective_docker_hub_registry() {
    if [[ -n "$DOCKER_HUB_REGISTRY" ]]; then
        echo "$DOCKER_HUB_REGISTRY"
    else
        echo "$DEFAULT_DOCKER_HUB_REGISTRY"
    fi
}

function get_effective_python_base_image() {
    if [[ -n "$SPINBOX_PYTHON_BASE_IMAGE" ]]; then
        echo "$SPINBOX_PYTHON_BASE_IMAGE"
    else
        echo "$DEFAULT_SPINBOX_PYTHON_BASE_IMAGE"
    fi
}

function get_effective_node_base_image() {
    if [[ -n "$SPINBOX_NODE_BASE_IMAGE" ]]; then
        echo "$SPINBOX_NODE_BASE_IMAGE"
    else
        echo "$DEFAULT_SPINBOX_NODE_BASE_IMAGE"
    fi
}

# Set version from CLI flags (called by main CLI parser)
function set_cli_python_version() {
    CLI_PYTHON_VERSION="$1"
    validate_python_version "$CLI_PYTHON_VERSION"
}

function set_cli_node_version() {
    CLI_NODE_VERSION="$1"
    validate_node_version "$CLI_NODE_VERSION"
}

function set_cli_postgres_version() {
    CLI_POSTGRES_VERSION="$1"
    validate_postgres_version "$CLI_POSTGRES_VERSION"
}

function set_cli_redis_version() {
    CLI_REDIS_VERSION="$1"
    validate_redis_version "$CLI_REDIS_VERSION"
}

# Set Docker Hub flag from CLI
function set_cli_docker_hub() {
    CLI_USE_DOCKER_HUB="true"
    export USE_DOCKER_HUB="true"
    print_debug "Docker Hub mode enabled via CLI flag"
}

# Get effective Docker Hub setting
function get_effective_docker_hub() {
    if [[ "$CLI_USE_DOCKER_HUB" == "true" ]]; then
        echo "true"
    elif [[ "${USE_DOCKER_HUB:-false}" == "true" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Version validation functions
function validate_python_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid Python version format: $version (expected: x.y)"
        return 1
    fi
    
    # Check if major version is reasonable (3.8+)
    local major="${version%.*}"
    local minor="${version#*.}"
    if [[ $major -lt 3 ]] || [[ $major -eq 3 && $minor -lt 8 ]]; then
        print_warning "Python version $version is quite old. Consider using 3.10 or later."
    fi
    
    print_debug "Python version $version validated"
    return 0
}

function validate_node_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+$ ]] && [[ ! "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid Node.js version format: $version (expected: x or x.y)"
        return 1
    fi
    
    # Check if version is reasonable (16+)
    local major="${version%%.*}"
    if [[ $major -lt 16 ]]; then
        print_warning "Node.js version $version is quite old. Consider using 18 or later."
    fi
    
    print_debug "Node.js version $version validated"
    return 0
}

function validate_postgres_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+$ ]] && [[ ! "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid PostgreSQL version format: $version (expected: x or x.y)"
        return 1
    fi
    
    # Check if version is reasonable (12+)
    local major="${version%%.*}"
    if [[ $major -lt 12 ]]; then
        print_warning "PostgreSQL version $version is quite old. Consider using 14 or later."
    fi
    
    print_debug "PostgreSQL version $version validated"
    return 0
}

function validate_redis_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+$ ]] && [[ ! "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid Redis version format: $version (expected: x or x.y)"
        return 1
    fi
    
    # Check if version is reasonable (6+)
    local major="${version%%.*}"
    if [[ $major -lt 6 ]]; then
        print_warning "Redis version $version is quite old. Consider using 7 or later."
    fi
    
    print_debug "Redis version $version validated"
    return 0
}

# Get all effective versions for configuration display
function get_all_effective_versions() {
    local python_ver=$(get_effective_python_version)
    local node_ver=$(get_effective_node_version)
    local postgres_ver=$(get_effective_postgres_version)
    local redis_ver=$(get_effective_redis_version)
    
    echo "Python $python_ver, Node $node_ver, PostgreSQL $postgres_ver, Redis $redis_ver"
}

# Show version configuration with sources (only for selected components)
function show_version_configuration() {
    print_info "Version Configuration:"
    
    # Only show Python version if Python is being used
    if [[ "${USE_PYTHON:-false}" == "true" ]]; then
        local python_ver=$(get_effective_python_version)
        local python_source=""
        if [[ -n "$CLI_PYTHON_VERSION" ]]; then
            python_source=" (from CLI flag)"
        elif [[ -n "$PYTHON_VERSION" ]]; then
            python_source=" (from config file)"
        else
            python_source=" (default)"
        fi
        echo "  Python: $python_ver$python_source"
    fi
    
    # Only show Node version if Node is being used
    if [[ "${USE_NODE:-false}" == "true" ]]; then
        local node_ver=$(get_effective_node_version)
        local node_source=""
        if [[ -n "$CLI_NODE_VERSION" ]]; then
            node_source=" (from CLI flag)"
        elif [[ -n "$NODE_VERSION" ]]; then
            node_source=" (from config file)"
        else
            node_source=" (default)"
        fi
        echo "  Node.js: $node_ver$node_source"
    fi
    
    # Only show PostgreSQL version if PostgreSQL is being used
    if [[ "${USE_POSTGRESQL:-false}" == "true" ]]; then
        local postgres_ver=$(get_effective_postgres_version)
        local postgres_source=""
        if [[ -n "$CLI_POSTGRES_VERSION" ]]; then
            postgres_source=" (from CLI flag)"
        elif [[ -n "$POSTGRES_VERSION" ]]; then
            postgres_source=" (from config file)"
        else
            postgres_source=" (default)"
        fi
        echo "  PostgreSQL: $postgres_ver$postgres_source"
    fi
    
    # Only show Redis version if Redis is being used
    if [[ "${USE_REDIS:-false}" == "true" ]]; then
        local redis_ver=$(get_effective_redis_version)
        local redis_source=""
        if [[ -n "$CLI_REDIS_VERSION" ]]; then
            redis_source=" (from CLI flag)"
        elif [[ -n "$REDIS_VERSION" ]]; then
            redis_source=" (from config file)"
        else
            redis_source=" (default)"
        fi
        echo "  Redis: $redis_ver$redis_source"
    fi
}

# Apply CLI version overrides to global configuration variables
function apply_version_overrides() {
    local python_ver=$(get_effective_python_version)
    local node_ver=$(get_effective_node_version)
    local postgres_ver=$(get_effective_postgres_version)
    local redis_ver=$(get_effective_redis_version)
    
    # Update global variables
    PYTHON_VERSION="$python_ver"
    NODE_VERSION="$node_ver"
    POSTGRES_VERSION="$postgres_ver"
    REDIS_VERSION="$redis_ver"
    
    print_debug "Applied version overrides: $(get_all_effective_versions)"
}

# Parse version flags from command line arguments
function parse_version_overrides() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --python-version)
                if [[ -z "$2" ]]; then
                    print_error "--python-version requires a value"
                    return 1
                fi
                set_cli_python_version "$2"
                shift 2
                ;;
            --node-version)
                if [[ -z "$2" ]]; then
                    print_error "--node-version requires a value"
                    return 1
                fi
                set_cli_node_version "$2"
                shift 2
                ;;
            --postgres-version)
                if [[ -z "$2" ]]; then
                    print_error "--postgres-version requires a value"
                    return 1
                fi
                set_cli_postgres_version "$2"
                shift 2
                ;;
            --redis-version)
                if [[ -z "$2" ]]; then
                    print_error "--redis-version requires a value"
                    return 1
                fi
                set_cli_redis_version "$2"
                shift 2
                ;;
            --docker-hub)
                set_cli_docker_hub
                shift
                ;;
            *)
                # Unknown flag, return remaining arguments
                break
                ;;
        esac
    done
    
    # Return remaining arguments
    return 0
}

# Get Docker image tags based on effective versions
function get_python_image_tag() {
    local version=$(get_effective_python_version)
    echo "python:${version}-slim"
}

function get_node_image_tag() {
    local version=$(get_effective_node_version)
    echo "node:${version}-alpine"
}

function get_postgres_image_tag() {
    local version=$(get_effective_postgres_version)
    echo "postgres:${version}"
}

function get_redis_image_tag() {
    local version=$(get_effective_redis_version)
    echo "redis:${version}-alpine"
}

# Generate version-specific configuration for templates
function generate_version_config() {
    cat << EOF
# Version configuration generated by Spinbox
# Generated on $(date)

# Effective versions (including CLI overrides)
PYTHON_VERSION="$(get_effective_python_version)"
NODE_VERSION="$(get_effective_node_version)"
POSTGRES_VERSION="$(get_effective_postgres_version)"
REDIS_VERSION="$(get_effective_redis_version)"

# Docker image tags
PYTHON_IMAGE="$(get_python_image_tag)"
NODE_IMAGE="$(get_node_image_tag)"
POSTGRES_IMAGE="$(get_postgres_image_tag)"
REDIS_IMAGE="$(get_redis_image_tag)"

# Configuration sources
$(if [[ -n "$CLI_PYTHON_VERSION" || -n "$CLI_NODE_VERSION" || -n "$CLI_POSTGRES_VERSION" || -n "$CLI_REDIS_VERSION" ]]; then
    echo "# CLI overrides were applied"
fi)
EOF
}

# Reset CLI overrides (useful for testing or re-parsing)
function reset_cli_overrides() {
    CLI_PYTHON_VERSION=""
    CLI_NODE_VERSION=""
    CLI_POSTGRES_VERSION=""
    CLI_REDIS_VERSION=""
    CLI_USE_DOCKER_HUB=""
    USE_DOCKER_HUB="false"
    print_debug "Reset all CLI version overrides"
}

# Export functions for use in other scripts
export -f get_effective_python_version get_effective_node_version
export -f get_effective_postgres_version get_effective_redis_version
export -f get_effective_docker_hub_username get_effective_docker_hub_registry
export -f get_effective_python_base_image get_effective_node_base_image
export -f set_cli_python_version set_cli_node_version
export -f set_cli_postgres_version set_cli_redis_version
export -f set_cli_docker_hub get_effective_docker_hub
export -f validate_python_version validate_node_version
export -f validate_postgres_version validate_redis_version
export -f get_all_effective_versions show_version_configuration
export -f apply_version_overrides parse_version_overrides
export -f get_python_image_tag get_node_image_tag
export -f get_postgres_image_tag get_redis_image_tag
export -f generate_version_config reset_cli_overrides