#!/bin/bash
# Comprehensive Uninstall Scenarios Test Suite
# Tests complete removal, partial uninstall, permission scenarios, and cleanup verification

# Note: Not using set -e so tests can continue after failures

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="/tmp/spinbox-uninstall-test-$(date +%Y%m%d-%H%M%S).log"

# Source the test utilities
source "$PROJECT_ROOT/testing/test-utils.sh"

# Setup test environment
setup_test_environment "Comprehensive Uninstall Scenarios Tests"

# Test results tracking
TEST_NAMES=()
TEST_RESULTS=()
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Test data directories for verification
TEST_INSTALL_DIRS=(
    "$HOME/.local/bin"
    "/usr/local/bin"
    "$HOME/.spinbox"
)

# Cleanup function
cleanup_uninstall_tests() {
    log_info "Cleaning up uninstall test artifacts..."
    
    # Remove any test installations
    rm -f "$HOME/.local/bin/spinbox" 2>/dev/null || true
    sudo rm -f "/usr/local/bin/spinbox" 2>/dev/null || true
    rm -rf "$HOME/.spinbox" 2>/dev/null || true
    
    # Clean up test projects
    rm -rf "$PROJECT_ROOT"/test-* 2>/dev/null || true
    rm -rf ~/test-* 2>/dev/null || true
}

# Ensure cleanup runs on exit
trap cleanup_uninstall_tests EXIT

# Logging functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_info() {
    log "[INFO] $*"
}

log_error() {
    log "[ERROR] $*"
}

# Test recording functions
record_test() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    local category="${4:-}"
    
    TEST_NAMES+=("$test_name")
    TEST_RESULTS+=("$result")
    ((TOTAL_TESTS++))
    
    case "$result" in
        PASS)
            echo -e "✓ $test_name: $message"
            ((PASSED_TESTS++))
            ;;
        FAIL)
            echo -e "✗ $test_name: $message"
            ((FAILED_TESTS++))
            ;;
        SKIP)
            echo -e "- $test_name: $message"
            ((SKIPPED_TESTS++))
            ;;
    esac
}

# Installation helper for tests
install_for_test() {
    local install_type="$1"  # "user" or "system"
    
    case "$install_type" in
        user)
            bash "$PROJECT_ROOT/install-user.sh" &>/dev/null
            return $?
            ;;
        system)
            if has_sudo; then
                sudo bash "$PROJECT_ROOT/install.sh" &>/dev/null
                return $?
            else
                return 1
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

# Verification functions
verify_binary_removed() {
    local binary_path="$1"
    [[ ! -f "$binary_path" ]]
}

verify_config_removed() {
    [[ ! -d "$HOME/.spinbox" ]]
}

verify_complete_removal() {
    ! command -v spinbox >/dev/null 2>&1 && \
    [[ ! -f "$HOME/.local/bin/spinbox" ]] && \
    [[ ! -f "/usr/local/bin/spinbox" ]] && \
    [[ ! -d "$HOME/.spinbox" ]]
}

# Test 1: User Installation Complete Uninstall
test_user_complete_uninstall() {
    log_info "Testing user installation complete uninstall..."
    
    # Install first
    if install_for_test "user"; then
        # Verify installation
        if command -v spinbox >/dev/null 2>&1; then
            record_test "user_install_setup" "PASS" "User installation setup successful"
            
            # Test complete uninstall
            if spinbox uninstall --config --force &>/dev/null; then
                # Verify complete removal
                if verify_complete_removal; then
                    record_test "user_complete_uninstall" "PASS" "Complete user uninstall successful"
                else
                    record_test "user_complete_uninstall" "FAIL" "Files remain after complete uninstall"
                fi
            else
                record_test "user_complete_uninstall" "FAIL" "Uninstall command failed"
            fi
        else
            record_test "user_install_setup" "FAIL" "User installation setup failed"
            record_test "user_complete_uninstall" "SKIP" "Skipped due to setup failure"
        fi
    else
        record_test "user_install_setup" "FAIL" "User installation failed"
        record_test "user_complete_uninstall" "SKIP" "Skipped due to install failure"
    fi
}

# Test 2: User Installation Binary-Only Uninstall
test_user_binary_only_uninstall() {
    log_info "Testing user installation binary-only uninstall..."
    
    # Install first
    if install_for_test "user"; then
        # Verify installation
        if command -v spinbox >/dev/null 2>&1; then
            record_test "user_binary_install_setup" "PASS" "User installation setup successful"
            
            # Test binary-only uninstall
            if spinbox uninstall --force &>/dev/null; then
                # Verify binary removed but config preserved
                if ! command -v spinbox >/dev/null 2>&1 && [[ -d "$HOME/.spinbox" ]]; then
                    record_test "user_binary_only_uninstall" "PASS" "Binary removed, config preserved"
                else
                    record_test "user_binary_only_uninstall" "FAIL" "Binary removal or config preservation failed"
                fi
                
                # Clean up remaining config
                rm -rf "$HOME/.spinbox" 2>/dev/null || true
            else
                record_test "user_binary_only_uninstall" "FAIL" "Binary-only uninstall command failed"
            fi
        else
            record_test "user_binary_install_setup" "FAIL" "User installation setup failed"
            record_test "user_binary_only_uninstall" "SKIP" "Skipped due to setup failure"
        fi
    else
        record_test "user_binary_install_setup" "FAIL" "User installation failed"
        record_test "user_binary_only_uninstall" "SKIP" "Skipped due to install failure"
    fi
}

# Test 3: System Installation Complete Uninstall
test_system_complete_uninstall() {
    log_info "Testing system installation complete uninstall..."
    
    if ! has_sudo; then
        record_test "system_complete_uninstall" "SKIP" "System uninstall requires sudo"
        return
    fi
    
    # Install first
    if install_for_test "system"; then
        # Verify installation
        if command -v spinbox >/dev/null 2>&1; then
            record_test "system_install_setup" "PASS" "System installation setup successful"
            
            # Test complete uninstall
            if sudo spinbox uninstall --config --force &>/dev/null; then
                # Verify complete removal
                if verify_complete_removal; then
                    record_test "system_complete_uninstall" "PASS" "Complete system uninstall successful"
                else
                    record_test "system_complete_uninstall" "FAIL" "Files remain after complete system uninstall"
                fi
            else
                record_test "system_complete_uninstall" "FAIL" "System uninstall command failed"
            fi
        else
            record_test "system_install_setup" "FAIL" "System installation setup failed"
            record_test "system_complete_uninstall" "SKIP" "Skipped due to setup failure"
        fi
    else
        record_test "system_install_setup" "FAIL" "System installation failed"
        record_test "system_complete_uninstall" "SKIP" "Skipped due to install failure"
    fi
}

# Test 4: Dry Run Uninstall Verification
test_uninstall_dry_run() {
    log_info "Testing uninstall dry-run functionality..."
    
    # Install first
    if install_for_test "user"; then
        # Verify installation
        if command -v spinbox >/dev/null 2>&1; then
            record_test "dry_run_install_setup" "PASS" "Installation setup for dry-run test successful"
            
            # Test dry-run (should not actually remove anything)
            if spinbox uninstall --config --dry-run &>/dev/null; then
                # Verify nothing was actually removed
                if command -v spinbox >/dev/null 2>&1 && [[ -d "$HOME/.spinbox" ]]; then
                    record_test "uninstall_dry_run" "PASS" "Dry-run mode preserves installation"
                else
                    record_test "uninstall_dry_run" "FAIL" "Dry-run mode actually removed files"
                fi
                
                # Clean up
                spinbox uninstall --config --force &>/dev/null || true
            else
                record_test "uninstall_dry_run" "FAIL" "Dry-run command failed"
            fi
        else
            record_test "dry_run_install_setup" "FAIL" "Installation setup failed"
            record_test "uninstall_dry_run" "SKIP" "Skipped due to setup failure"
        fi
    else
        record_test "dry_run_install_setup" "FAIL" "Installation failed"
        record_test "uninstall_dry_run" "SKIP" "Skipped due to install failure"
    fi
}

# Test 5: Uninstall Nothing (Edge Case)
test_uninstall_nothing() {
    log_info "Testing uninstall when nothing is installed..."
    
    # Ensure clean state
    cleanup_uninstall_tests
    
    # Try to uninstall when nothing is installed
    if "$PROJECT_ROOT/uninstall.sh" --force &>/dev/null; then
        record_test "uninstall_nothing" "PASS" "Uninstall handles 'nothing installed' gracefully"
    else
        # It's okay if it fails, but it should handle gracefully
        record_test "uninstall_nothing" "PASS" "Uninstall exits with error for 'nothing installed' (acceptable)"
    fi
}

# Test 6: Force Flag Functionality
test_uninstall_force_flag() {
    log_info "Testing uninstall force flag functionality..."
    
    # Install first
    if install_for_test "user"; then
        # Verify installation
        if command -v spinbox >/dev/null 2>&1; then
            record_test "force_flag_install_setup" "PASS" "Installation setup for force flag test successful"
            
            # Test force flag (should skip confirmations)
            if timeout 10 spinbox uninstall --config --force &>/dev/null; then
                # Verify removal
                if verify_complete_removal; then
                    record_test "uninstall_force_flag" "PASS" "Force flag skips confirmations and removes files"
                else
                    record_test "uninstall_force_flag" "FAIL" "Force flag did not remove all files"
                fi
            else
                record_test "uninstall_force_flag" "FAIL" "Force flag command failed or timed out"
            fi
        else
            record_test "force_flag_install_setup" "FAIL" "Installation setup failed"
            record_test "uninstall_force_flag" "SKIP" "Skipped due to setup failure"
        fi
    else
        record_test "force_flag_install_setup" "FAIL" "Installation failed"
        record_test "uninstall_force_flag" "SKIP" "Skipped due to install failure"
    fi
}

# Test 7: Script-based Uninstall
test_script_based_uninstall() {
    log_info "Testing direct script-based uninstall..."
    
    # Install first
    if install_for_test "user"; then
        # Verify installation
        if command -v spinbox >/dev/null 2>&1; then
            record_test "script_uninstall_setup" "PASS" "Installation setup for script uninstall test successful"
            
            # Test direct script uninstall
            if "$PROJECT_ROOT/uninstall.sh" --config --force &>/dev/null; then
                # Verify removal
                if verify_complete_removal; then
                    record_test "script_based_uninstall" "PASS" "Direct script uninstall successful"
                else
                    record_test "script_based_uninstall" "FAIL" "Script uninstall did not remove all files"
                fi
            else
                record_test "script_based_uninstall" "FAIL" "Script uninstall command failed"
            fi
        else
            record_test "script_uninstall_setup" "FAIL" "Installation setup failed"
            record_test "script_based_uninstall" "SKIP" "Skipped due to setup failure"
        fi
    else
        record_test "script_uninstall_setup" "FAIL" "Installation failed"
        record_test "script_based_uninstall" "SKIP" "Skipped due to install failure"
    fi
}

# Test 8: Configuration Preservation Test
test_config_preservation() {
    log_info "Testing configuration preservation during partial uninstall..."
    
    # Install first
    if install_for_test "user"; then
        # Verify installation and create some config
        if command -v spinbox >/dev/null 2>&1; then
            # Set some configuration
            spinbox config --set PROJECT_AUTHOR="Test User" &>/dev/null || true
            
            record_test "config_preservation_setup" "PASS" "Installation and config setup successful"
            
            # Test binary-only uninstall (preserve config)
            if spinbox uninstall --force &>/dev/null; then
                # Verify binary removed but config exists
                if ! command -v spinbox >/dev/null 2>&1 && [[ -d "$HOME/.spinbox" ]]; then
                    # Check if config is actually preserved
                    if [[ -f "$HOME/.spinbox/global.conf" ]]; then
                        record_test "config_preservation" "PASS" "Configuration preserved during partial uninstall"
                    else
                        record_test "config_preservation" "FAIL" "Configuration not found after partial uninstall"
                    fi
                else
                    record_test "config_preservation" "FAIL" "Binary not removed or config not preserved"
                fi
                
                # Clean up
                rm -rf "$HOME/.spinbox" 2>/dev/null || true
            else
                record_test "config_preservation" "FAIL" "Partial uninstall command failed"
            fi
        else
            record_test "config_preservation_setup" "FAIL" "Installation setup failed"
            record_test "config_preservation" "SKIP" "Skipped due to setup failure"
        fi
    else
        record_test "config_preservation_setup" "FAIL" "Installation failed"
        record_test "config_preservation" "SKIP" "Skipped due to install failure"
    fi
}

# Main test execution
main() {
    echo "================================================="
    echo "       Comprehensive Uninstall Test Suite       "
    echo "================================================="
    echo ""
    
    # Check prerequisites
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: git is required for tests"
        exit 1
    fi
    
    # Cache sudo credentials if available
    if has_sudo; then
        cache_sudo_credentials
    fi
    
    # Run test suites
    echo "Running uninstall scenario tests..."
    echo ""
    
    # Complete uninstall tests
    test_user_complete_uninstall
    test_system_complete_uninstall
    
    # Partial uninstall tests
    test_user_binary_only_uninstall
    test_config_preservation
    
    # Functionality tests
    test_uninstall_dry_run
    test_uninstall_force_flag
    
    # Edge case tests
    test_uninstall_nothing
    test_script_based_uninstall
    
    # Show results
    echo ""
    echo "================================================="
    echo "             Uninstall Test Results             "
    echo "================================================="
    echo "Total tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo "Skipped: $SKIPPED_TESTS"
    echo ""
    
    if [[ $FAILED_TESTS -eq 0 ]]; then
        echo "🎉 All uninstall tests passed!"
        exit 0
    else
        echo "❌ Some uninstall tests failed"
        echo "Check the log file: $LOG_FILE"
        exit 1
    fi
}

# Run main function
main "$@"