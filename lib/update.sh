#!/bin/bash
# Update engine for Spinbox CLI tool

# Detect installation method
detect_installation_method() {
    if command -v brew &> /dev/null && brew list spinbox &> /dev/null; then
        echo "homebrew"
    elif [[ -L "$(which spinbox)" ]]; then
        echo "manual"
    else
        echo "unknown"
    fi
}

# Create backup of current installation
create_backup() {
    local backup_dir="$HOME/.spinbox/backup/$(date +%Y%m%d_%H%M%S)"
    
    print_info "Creating backup at $backup_dir..."
    
    mkdir -p "$backup_dir"
    
    # Backup the main executable
    if [[ -f "$(which spinbox)" ]]; then
        cp "$(which spinbox)" "$backup_dir/spinbox"
    fi
    
    # Backup support files
    if [[ -d "$HOME/.spinbox/lib" ]]; then
        cp -r "$HOME/.spinbox/lib" "$backup_dir/"
    fi
    
    if [[ -d "$HOME/.spinbox/generators" ]]; then
        cp -r "$HOME/.spinbox/generators" "$backup_dir/"
    fi
    
    if [[ -d "$HOME/.spinbox/templates" ]]; then
        cp -r "$HOME/.spinbox/templates" "$backup_dir/"
    fi
    
    # Store backup location for potential rollback
    echo "$backup_dir" > "$HOME/.spinbox/last_backup"
    
    print_success "Backup created successfully."
    echo "$backup_dir"
}

# Rollback to previous version
rollback_update() {
    local backup_dir="$1"
    
    if [[ -z "$backup_dir" && -f "$HOME/.spinbox/last_backup" ]]; then
        backup_dir=$(cat "$HOME/.spinbox/last_backup")
    fi
    
    if [[ -z "$backup_dir" || ! -d "$backup_dir" ]]; then
        print_error "No backup found for rollback."
        return 1
    fi
    
    print_info "Rolling back to previous version..."
    
    # Restore main executable
    if [[ -f "$backup_dir/spinbox" ]]; then
        cp "$backup_dir/spinbox" "$(which spinbox)"
    fi
    
    # Restore support files
    if [[ -d "$backup_dir/lib" ]]; then
        rm -rf "$HOME/.spinbox/lib"
        cp -r "$backup_dir/lib" "$HOME/.spinbox/"
    fi
    
    if [[ -d "$backup_dir/generators" ]]; then
        rm -rf "$HOME/.spinbox/generators"
        cp -r "$backup_dir/generators" "$HOME/.spinbox/"
    fi
    
    if [[ -d "$backup_dir/templates" ]]; then
        rm -rf "$HOME/.spinbox/templates"
        cp -r "$backup_dir/templates" "$HOME/.spinbox/"
    fi
    
    print_success "Rollback completed successfully."
}

# Download and extract update
download_update() {
    local version="$1"
    local temp_dir="/tmp/spinbox-update-$$"
    local download_url
    
    download_url=$(get_download_url "$version")
    
    print_info "Downloading Spinbox $version..."
    
    # Create temporary directory
    mkdir -p "$temp_dir"
    
    # Download the update
    if command -v curl &> /dev/null; then
        curl -sL "$download_url" | tar -xz -C "$temp_dir" --strip-components=1
    elif command -v wget &> /dev/null; then
        wget -qO- "$download_url" | tar -xz -C "$temp_dir" --strip-components=1
    else
        print_error "Neither curl nor wget is available. Cannot download update."
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Verify download
    if [[ ! -f "$temp_dir/bin/spinbox" ]]; then
        print_error "Download failed or incomplete. Missing main executable."
        rm -rf "$temp_dir"
        return 1
    fi
    
    print_success "Download completed successfully."
    echo "$temp_dir"
}

# Install update from temporary directory
install_update() {
    local temp_dir="$1"
    local spinbox_path
    
    spinbox_path=$(which spinbox)
    
    if [[ -z "$spinbox_path" ]]; then
        print_error "Cannot find current Spinbox installation."
        return 1
    fi
    
    print_info "Installing update..."
    
    # Make new executable executable
    chmod +x "$temp_dir/bin/spinbox"
    
    # Replace main executable
    cp "$temp_dir/bin/spinbox" "$spinbox_path"
    
    # Update support files
    if [[ -d "$temp_dir/lib" ]]; then
        rm -rf "$HOME/.spinbox/lib"
        cp -r "$temp_dir/lib" "$HOME/.spinbox/"
    fi
    
    if [[ -d "$temp_dir/generators" ]]; then
        rm -rf "$HOME/.spinbox/generators"
        cp -r "$temp_dir/generators" "$HOME/.spinbox/"
    fi
    
    if [[ -d "$temp_dir/templates" ]]; then
        rm -rf "$HOME/.spinbox/templates"
        cp -r "$temp_dir/templates" "$HOME/.spinbox/"
    fi
    
    print_success "Update installed successfully."
}

# Verify installation after update
verify_update() {
    local expected_version="$1"
    
    print_info "Verifying update..."
    
    # Test basic functionality
    if ! command -v spinbox &> /dev/null; then
        print_error "Spinbox command not found after update."
        return 1
    fi
    
    # Test version command
    if ! spinbox --version &> /dev/null; then
        print_error "Spinbox version command failed after update."
        return 1
    fi
    
    # Test help command
    if ! spinbox --help &> /dev/null; then
        print_error "Spinbox help command failed after update."
        return 1
    fi
    
    # If specific version expected, verify it
    if [[ -n "$expected_version" ]]; then
        local actual_version
        actual_version=$(spinbox --version | grep -o 'v[0-9.]*' | head -1)
        if [[ "$actual_version" != "$expected_version" ]]; then
            print_warning "Version mismatch: expected $expected_version, got $actual_version"
        fi
    fi
    
    print_success "Update verification completed."
}

# Main update function
perform_update() {
    local target_version="$1"
    local force_update="$2"
    local skip_confirmation="$3"
    local installation_method
    local current_version
    local latest_version
    local backup_dir
    local temp_dir
    
    # Detect installation method
    installation_method=$(detect_installation_method)
    
    # Handle Homebrew installations
    if [[ "$installation_method" == "homebrew" ]]; then
        print_info "Detected Homebrew installation."
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "Would run: brew upgrade spinbox"
        else
            print_info "Updating via Homebrew..."
            if brew upgrade spinbox; then
                print_success "Homebrew update completed successfully."
            else
                print_error "Homebrew update failed."
                return 1
            fi
        fi
        return 0
    fi
    
    # Handle manual installations
    if [[ "$installation_method" == "unknown" ]]; then
        print_error "Cannot detect installation method. Manual intervention required."
        return 1
    fi
    
    # Get version information
    current_version=$(get_current_version)
    
    if [[ -z "$target_version" ]]; then
        latest_version=$(get_latest_version)
        if [[ $? -ne 0 ]]; then
            print_error "Failed to get latest version information."
            return 1
        fi
        target_version="$latest_version"
    fi
    
    # Check if update is needed
    if [[ "$force_update" != "true" ]]; then
        compare_versions "$current_version" "$target_version"
        local comparison_result=$?
        
        if [[ $comparison_result -eq 0 ]]; then
            print_info "Already on version $current_version."
            if [[ "$force_update" != "true" ]]; then
                print_info "Use --force to reinstall the same version."
                return 0
            fi
        elif [[ $comparison_result -eq 1 ]]; then
            print_warning "Current version ($current_version) is newer than target ($target_version)."
            if [[ "$force_update" != "true" ]]; then
                print_info "Use --force to downgrade."
                return 0
            fi
        fi
    fi
    
    # Show update information
    print_info "Update plan:"
    print_info "  Current version: $current_version"
    print_info "  Target version:  $target_version"
    print_info "  Installation:    $installation_method"
    
    # Confirm update
    if [[ "$skip_confirmation" != "true" && "$DRY_RUN" != "true" ]]; then
        echo
        read -p "Proceed with update? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Update cancelled."
            return 0
        fi
    fi
    
    # Dry run mode
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "Dry run mode - would perform the following actions:"
        print_info "  1. Create backup of current installation"
        print_info "  2. Download version $target_version"
        print_info "  3. Install update"
        print_info "  4. Verify installation"
        print_info "  5. Clean up temporary files"
        return 0
    fi
    
    # Perform update
    print_info "Starting update process..."
    
    # Create backup
    backup_dir=$(create_backup)
    if [[ $? -ne 0 ]]; then
        print_error "Failed to create backup."
        return 1
    fi
    
    # Download update
    temp_dir=$(download_update "$target_version")
    if [[ $? -ne 0 ]]; then
        print_error "Failed to download update."
        return 1
    fi
    
    # Install update
    if ! install_update "$temp_dir"; then
        print_error "Failed to install update. Rolling back..."
        rollback_update "$backup_dir"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Verify update
    if ! verify_update "$target_version"; then
        print_error "Update verification failed. Rolling back..."
        rollback_update "$backup_dir"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    
    print_success "Update completed successfully!"
    print_info "Updated from $current_version to $target_version"
    
    return 0
}

# Check for updates without installing
check_for_updates() {
    print_info "Checking for updates..."
    
    show_version_info
    local result=$?
    
    case $result in
        0)
            print_info "You are up to date."
            ;;
        1)
            print_info "You are running a development version."
            ;;
        2)
            print_info "Update available. Run 'spinbox update' to install."
            ;;
    esac
    
    return $result
}