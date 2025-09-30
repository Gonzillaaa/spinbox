#!/bin/bash
# Workflow Scenarios Test Suite - Critical User Workflows
# Tests real-world usage scenarios end-to-end

# Note: Not using set -e so tests can continue after failures

echo "================================"
echo "Spinbox Workflow Scenarios Test Suite"
echo "================================"

# Set up test environment
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Source the test utilities
source testing/test-utils.sh

# Setup test environment and cleanup
setup_test_environment "Workflow Scenarios Tests"

# Cleanup function
cleanup_integration_test() {
    echo "[Cleanup] Cleaning up test artifacts..."
    rm -rf test-* 2>/dev/null || true
    rm -rf ~/test-* 2>/dev/null || true
    rm -rf /tmp/test-* 2>/dev/null || true
    ./uninstall.sh --config --force &>/dev/null || true
    sudo ./uninstall.sh --config --force &>/dev/null || true
}

# Ensure cleanup runs on exit
trap cleanup_integration_test EXIT

# Test function
test_scenario() {
    local name="$1"
    local description="$2"
    local command="$3"
    
    log_section "$name"
    log_info "$description"
    
    # Capture command output for better error reporting
    local output
    local exit_code
    output=$(eval "$command" 2>&1)
    exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        record_test_result "$name" "PASS" "$description"
        return 0
    else
        local error_msg="$description"
        if [[ -n "$output" ]]; then
            error_msg="$error_msg\n  Output: $output"
        fi
        record_test_result "$name" "FAIL" "$error_msg"
        return 1
    fi
}

# Initial cleanup
log_info "Cleaning previous installations..."
"$PROJECT_ROOT/uninstall.sh" --config --force &>/dev/null || true
# Only use sudo if explicitly enabled and available
if [[ "$ENABLE_SUDO" == "true" ]] && has_sudo; then
    sudo "$PROJECT_ROOT/uninstall.sh" --config --force &>/dev/null || true
fi

# Scenario 1: Developer Workflow
test_scenario "Developer Workflow" \
    "Developer clones repo and runs spinbox directly without installation" \
    '
    # Run from development directory
    ./bin/spinbox --version &&
    [[ $(./bin/spinbox profiles | grep -E "^  [a-z-]+" | wc -l) -eq 6 ]] &&
    cd /tmp && /Users/gonzalo/code/spinbox/bin/spinbox create test-dev-project --profile python --dry-run && cd - >/dev/null &&
    echo "Development workflow works correctly"
    '

# Scenario 2: New User Installation
test_scenario "New User Installation" \
    "User installs spinbox locally and creates first project" \
    '
    # Install locally
    ./install-user.sh &&
    export PATH="$HOME/.local/bin:$PATH" &&

    # Verify installation
    which spinbox | grep -q ".local/bin" &&
    [[ -d "$HOME/.spinbox/runtime" ]] &&
    
    # Create first project
    cd /tmp && spinbox create test-first-project --profile python --dry-run && cd - >/dev/null &&
    
    # Check profiles
    spinbox profiles | grep -q "Python development environment with essential tools" &&
    
    # Cleanup
    spinbox uninstall --config --force
    '

# Scenario 3: System Administrator Installation
test_scenario "System Administrator" \
    "Admin installs spinbox system-wide for all users" \
    '
    # Install globally
    if [[ "$ENABLE_SUDO" == "true" ]] && has_sudo; then 
        sudo ./install.sh &&
        # Verify global installation
        which spinbox | grep -q "/usr/local/bin" &&
        [[ -d "$HOME/.spinbox/runtime" ]] &&
        # Test as regular user
        spinbox --version &&
        [[ $(spinbox profiles | grep -E "^  [a-z-]+" | wc -l) -eq 6 ]] &&
        # Cleanup
        sudo spinbox uninstall --config --force
    else 
        echo "Skipping global installation test (sudo disabled by default)" &&
        true  # Return success when skipping
    fi
    '

# Scenario 4: Profile Migration
test_scenario "Profile Migration" \
    "User migrates from old minimal profile to new python/node profiles" \
    '
    # Install fresh
    ./install-user.sh &&
    export PATH="$HOME/.local/bin:$PATH" &&
    
    # Verify minimal is gone
    ! spinbox profiles | grep -q "minimal" &&
    
    # Verify python and node exist
    spinbox profiles | grep -q "python" &&
    spinbox profiles | grep -q "node" &&
    
    # Test creating with new profiles
    cd /tmp && spinbox create test-python --profile python --dry-run && cd - >/dev/null &&
    cd /tmp && spinbox create test-node --profile node --dry-run && cd - >/dev/null &&
    
    # Test base options work
    cd /tmp && spinbox create test-base-py --python --dry-run && cd - >/dev/null &&
    cd /tmp && spinbox create test-base-nd --node --dry-run && cd - >/dev/null &&
    
    # Cleanup
    spinbox uninstall --config --force
    '

# Scenario 5: Update Workflow
test_scenario "Update Workflow" \
    "User checks for updates and verifies current version" \
    '
    # Install locally
    ./install-user.sh &&
    export PATH="$HOME/.local/bin:$PATH" &&
    
    # Check version
    spinbox --version | grep -q "0.1.0" &&
    
    # Check for updates (should not fail even if no updates)
    spinbox update --check || true &&
    
    # Cleanup
    spinbox uninstall --config --force
    '

# Scenario 6: Multiple Installation Cleanup
test_scenario "Multiple Installation Cleanup" \
    "User cleans up both old and new installation formats" \
    '
    # Create fake old installations
    if [[ "$ENABLE_SUDO" == "true" ]] && has_sudo; then sudo mkdir -p /usr/local/lib/spinbox; else echo "Skipping sudo directory creation (sudo disabled by default)"; fi &&
    mkdir -p "$HOME/.local/lib/spinbox" &&
    
    # Install new version
    ./install-user.sh &&
    
    # Run comprehensive cleanup
    ./uninstall.sh --config --force &&
    
    # Verify everything is gone
    [[ ! -f /usr/local/bin/spinbox ]] &&
    [[ ! -f "$HOME/.local/bin/spinbox" ]] &&
    [[ ! -d /usr/local/lib/spinbox ]] &&
    [[ ! -d "$HOME/.local/lib/spinbox" ]] &&
    [[ ! -d "$HOME/.spinbox" ]] &&
    echo "All installations cleaned successfully"
    '

# Scenario 7: Cross-Mode Consistency
test_scenario "Cross-Mode Consistency" \
    "Verify development and installed versions produce identical output" \
    '
    # Get development output
    DEV_PROFILES=$(./bin/spinbox profiles 2>/dev/null) &&
    DEV_VERSION=$(./bin/spinbox --version 2>/dev/null) &&
    
    # Ensure spinbox is in PATH
    export PATH="$HOME/.local/bin:$PATH" &&
    
    # Install if not available (cleanup from previous tests may have removed it)
    if ! command -v spinbox &>/dev/null; then
        ./install-user.sh >/dev/null 2>&1 || true
    fi &&
    
    # Now check if spinbox is available
    if command -v spinbox &>/dev/null; then
        # Get production output
        PROD_PROFILES=$(spinbox profiles 2>/dev/null) &&
        PROD_VERSION=$(spinbox --version 2>/dev/null) &&
        
        # Compare outputs
        if [[ "$DEV_PROFILES" == "$PROD_PROFILES" ]] && [[ "$DEV_VERSION" == "$PROD_VERSION" ]]; then
            echo "Development and production modes are consistent" &&
            spinbox uninstall --config --force >/dev/null 2>&1 || true &&
            true
        else
            echo "Outputs differ between development and production modes" &&
            false
        fi
    else
        echo "Could not install spinbox for comparison" &&
        false
    fi
    '

# Scenario 8: Error Recovery
test_scenario "Error Recovery" \
    "System handles and recovers from common errors gracefully" \
    '
    # Test invalid profile
    ! ./bin/spinbox create test --profile invalid 2>/dev/null &&
    
    # Test missing project name
    ! ./bin/spinbox create 2>/dev/null &&
    
    # Test double installation
    ./install-user.sh &&
    ./install-user.sh &&  # Should not fail
    
    # Test uninstall when already clean
    spinbox uninstall --config --force &&
    ./uninstall.sh --force &&  # Should not fail
    
    echo "Error handling works correctly"
    '

# Show final results using shared utilities
show_test_summary "Workflow Scenarios Tests"