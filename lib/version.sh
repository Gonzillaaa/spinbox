#!/bin/bash
# Version detection and management for Spinbox CLI tool

# Get current installed version
get_current_version() {
    echo "$VERSION"
}

# Get latest version from GitHub releases
get_latest_version() {
    local repo_url="https://api.github.com/repos/Gonzillaaa/spinbox/releases/latest"
    local latest_version
    
    # Try to get latest version from GitHub API
    if command -v curl &> /dev/null; then
        latest_version=$(curl -s "$repo_url" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    elif command -v wget &> /dev/null; then
        latest_version=$(wget -qO- "$repo_url" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    else
        print_error "Neither curl nor wget is available. Cannot check for updates."
        return 1
    fi
    
    # If no releases found, fallback to current version (development mode)
    if [[ -z "$latest_version" ]]; then
        print_warning "No releases found. Using current version as latest."
        latest_version="$VERSION"
    fi
    
    echo "$latest_version"
}

# Compare two semantic versions
# Returns: 0 if equal, 1 if first > second, 2 if first < second
compare_versions() {
    local version1="$1"
    local version2="$2"
    
    # Remove 'v' prefix if present
    version1=$(echo "$version1" | sed 's/^v//')
    version2=$(echo "$version2" | sed 's/^v//')
    
    # Split versions into components
    IFS='.' read -ra v1_parts <<< "$version1"
    IFS='.' read -ra v2_parts <<< "$version2"
    
    # Pad arrays to same length
    local max_len=${#v1_parts[@]}
    if [[ ${#v2_parts[@]} -gt $max_len ]]; then
        max_len=${#v2_parts[@]}
    fi
    
    # Compare each component
    for ((i=0; i<max_len; i++)); do
        local v1_part=${v1_parts[i]:-0}
        local v2_part=${v2_parts[i]:-0}
        
        if [[ $v1_part -gt $v2_part ]]; then
            return 1
        elif [[ $v1_part -lt $v2_part ]]; then
            return 2
        fi
    done
    
    return 0
}

# Check if update is available
check_update_available() {
    local current_version
    local latest_version
    local comparison_result
    
    current_version=$(get_current_version)
    latest_version=$(get_latest_version)
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    compare_versions "$current_version" "$latest_version"
    comparison_result=$?
    
    if [[ $comparison_result -eq 2 ]]; then
        return 0  # Update available
    else
        return 1  # No update available
    fi
}

# Display version comparison information
show_version_info() {
    local current_version
    local latest_version
    local comparison_result
    
    current_version=$(get_current_version)
    print_info "Current version: $current_version"
    
    print_info "Checking for updates..."
    if ! latest_version=$(get_latest_version); then
        print_error "Failed to check for updates."
        return 1
    fi
    
    print_info "Latest version: $latest_version"
    
    compare_versions "$current_version" "$latest_version"
    comparison_result=$?
    
    case $comparison_result in
        0)
            print_success "You are running the latest version."
            ;;
        1)
            print_warning "You are running a newer version than the latest release."
            ;;
        2)
            print_warning "An update is available: $current_version → $latest_version"
            echo "Run 'spinbox update' to update to the latest version."
            ;;
    esac
    
    return $comparison_result
}

# Get download URL for latest version
get_download_url() {
    local version="${1:-latest}"
    
    if [[ "$version" == "latest" ]]; then
        echo "https://github.com/Gonzillaaa/spinbox/archive/refs/heads/main.tar.gz"
    else
        # Remove 'v' prefix if present for URL
        version=$(echo "$version" | sed 's/^v//')
        echo "https://github.com/Gonzillaaa/spinbox/archive/refs/tags/v${version}.tar.gz"
    fi
}

# Validate version format
validate_version() {
    local version="$1"
    
    # Remove 'v' prefix if present
    version=$(echo "$version" | sed 's/^v//')
    
    # Check if version matches semantic version pattern
    if [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}