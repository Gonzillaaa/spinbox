#!/bin/bash
# Workflow Scenarios Test Suite - Critical User Workflows
# Tests real-world usage scenarios end-to-end

set -e

echo "================================"
echo "Spinbox Workflow Scenarios Test Suite"
echo "================================"

# Set up test environment
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Source the test utilities
source testing/unit/test-utils.sh

# Setup test environment and cleanup
setup_test_environment "Workflow Scenarios Tests"

# Test function
test_scenario() {
    local name="$1"
    local description="$2"
    
    ((TESTS_RUN++))
    echo ""
    echo "Test $TESTS_RUN: $name"
    echo "Description: $description"
    echo "---------------------------------"
    
    if eval "$3"; then
        echo "✓ PASSED"
        ((TESTS_PASSED++))
    else
        echo "✗ FAILED"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Cleanup before starting
echo "[Setup] Cleaning previous installations..."
./uninstall.sh --config --force &>/dev/null || true
sudo ./uninstall.sh --config --force &>/dev/null || true
rm -rf ~/test-* /tmp/test-* &>/dev/null || true

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
    [[ -d "$HOME/.spinbox/source" ]] &&
    
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
    sudo ./install.sh &&
    
    # Verify global installation
    which spinbox | grep -q "/usr/local/bin" &&
    [[ -d "$HOME/.spinbox/source" ]] &&
    
    # Test as regular user
    spinbox --version &&
    [[ $(spinbox profiles | grep -E "^  [a-z-]+" | wc -l) -eq 6 ]] &&
    
    # Cleanup
    sudo spinbox uninstall --config --force
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
    sudo mkdir -p /usr/local/lib/spinbox &&
    mkdir -p "$HOME/.local/lib/spinbox" &&
    
    # Install new version
    ./install-user.sh &&
    
    # Run comprehensive cleanup
    ./scripts/remove-installed.sh &&
    
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
    DEV_PROFILES=$(./bin/spinbox profiles) &&
    DEV_VERSION=$(./bin/spinbox --version) &&
    
    # Install and get production output
    ./install-user.sh &&
    export PATH="$HOME/.local/bin:$PATH" &&
    PROD_PROFILES=$(spinbox profiles) &&
    PROD_VERSION=$(spinbox --version) &&
    
    # Compare outputs
    [[ "$DEV_PROFILES" == "$PROD_PROFILES" ]] &&
    [[ "$DEV_VERSION" == "$PROD_VERSION" ]] &&
    
    # Cleanup
    spinbox uninstall --config --force &&
    echo "Development and production modes are consistent"
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

# Final cleanup
echo ""
echo "[Cleanup] Final cleanup..."
./uninstall.sh --config --force &>/dev/null || true
sudo ./uninstall.sh --config --force &>/dev/null || true
rm -rf ~/test-* /tmp/test-* &>/dev/null || true

# Results
echo ""
echo "================================"
echo "Integration Test Results"
echo "================================"
echo "Tests Run: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "✓ ALL INTEGRATION TESTS PASSED!"
    exit 0
else
    echo "✗ Some tests failed"
    exit 1
fi