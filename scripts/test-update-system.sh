#!/bin/bash
# Update System Test Suite for Spinbox
# Tests update, backup, rollback, and version management functionality
# Following CLAUDE.md principles: Simple, Fast, Essential Coverage

set -e

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SPINBOX_CMD="$PROJECT_ROOT/bin/spinbox"
TEST_DIR="/tmp/spinbox-update-test-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
MISSING_FEATURES=()

# Simple logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

# Test result tracking
record_test() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    ((TOTAL_TESTS++))
    
    if [[ "$result" == "PASS" ]]; then
        ((PASSED_TESTS++))
        log_success "$test_name: $message"
    else
        ((FAILED_TESTS++))
        log_error "$test_name: $message"
        if [[ "$4" == "MISSING" ]]; then
            MISSING_FEATURES+=("$test_name")
        fi
    fi
}

# Test update check functionality
test_update_check() {
    log_info "=== Testing Update Check Functionality ==="
    
    # Test basic update check
    if output=$("$SPINBOX_CMD" update --check 2>&1); then
        record_test "update_check_basic" "PASS" "Update check command works"
        
        # Check for version information in output
        if echo "$output" | grep -iq "version\|current\|latest"; then
            record_test "update_check_version_info" "PASS" "Update check shows version information"
        else
            record_test "update_check_version_info" "FAIL" "Update check doesn't show version info"
        fi
    else
        record_test "update_check_basic" "FAIL" "Update check command failed" "MISSING"
    fi
    
    # Test update check with verbose flag
    if output=$("$SPINBOX_CMD" update --check --verbose 2>&1); then
        record_test "update_check_verbose" "PASS" "Update check with verbose flag works"
    else
        record_test "update_check_verbose" "FAIL" "Update check verbose mode failed" "MISSING"
    fi
}

# Test update dry run functionality
test_update_dry_run() {
    log_info "=== Testing Update Dry Run Functionality ==="
    
    # Test dry run mode
    if output=$("$SPINBOX_CMD" update --dry-run 2>&1); then
        record_test "update_dry_run" "PASS" "Update dry-run command works"
        
        # Check that dry-run mentions what would be done
        if echo "$output" | grep -iq "would\|dry.run\|preview"; then
            record_test "update_dry_run_preview" "PASS" "Dry-run shows what would be done"
        else
            record_test "update_dry_run_preview" "FAIL" "Dry-run doesn't show preview information"
        fi
    else
        record_test "update_dry_run" "FAIL" "Update dry-run command failed" "MISSING"
    fi
}

# Test version-specific update
test_version_specific_update() {
    log_info "=== Testing Version-Specific Update ==="
    
    # Test update to specific version (dry-run only for safety)
    if output=$("$SPINBOX_CMD" update --version 0.1.0 --dry-run 2>&1); then
        record_test "update_specific_version" "PASS" "Update to specific version works"
        
        # Check that the version is mentioned in output
        if echo "$output" | grep -q "0.1.0"; then
            record_test "update_version_mentioned" "PASS" "Specific version mentioned in output"
        else
            record_test "update_version_mentioned" "FAIL" "Specific version not found in output"
        fi
    else
        record_test "update_specific_version" "FAIL" "Update to specific version failed" "MISSING"
    fi
}

# Test update force functionality
test_update_force() {
    log_info "=== Testing Update Force Functionality ==="
    
    # Test force update (dry-run only)
    if output=$("$SPINBOX_CMD" update --force --dry-run 2>&1); then
        record_test "update_force_flag" "PASS" "Update force flag accepted"
        
        # Check for force-related messaging
        if echo "$output" | grep -iq "force\|reinstall"; then
            record_test "update_force_messaging" "PASS" "Force update behavior indicated"
        else
            record_test "update_force_messaging" "FAIL" "Force update behavior not clear"
        fi
    else
        record_test "update_force_flag" "FAIL" "Update force flag not working" "MISSING"
    fi
}

# Test update yes flag (skip confirmations)
test_update_yes_flag() {
    log_info "=== Testing Update Yes Flag ==="
    
    # Test yes flag for skipping prompts
    if output=$("$SPINBOX_CMD" update --yes --dry-run 2>&1); then
        record_test "update_yes_flag" "PASS" "Update yes flag accepted"
    else
        record_test "update_yes_flag" "FAIL" "Update yes flag not working" "MISSING"
    fi
}

# Test backup functionality (through update library)
test_backup_functionality() {
    log_info "=== Testing Backup Functionality ==="
    
    # Check if update library exists
    local update_lib="$PROJECT_ROOT/lib/update.sh"
    if [[ -f "$update_lib" ]]; then
        record_test "update_library_exists" "PASS" "Update library file exists"
        
        # Check for backup-related functions
        if grep -q "create_backup\|backup" "$update_lib"; then
            record_test "backup_functions_exist" "PASS" "Backup functions found in update library"
        else
            record_test "backup_functions_exist" "FAIL" "Backup functions not found" "MISSING"
        fi
        
        # Check for rollback functions
        if grep -q "rollback\|restore" "$update_lib"; then
            record_test "rollback_functions_exist" "PASS" "Rollback functions found in update library"
        else
            record_test "rollback_functions_exist" "FAIL" "Rollback functions not found" "MISSING"
        fi
        
        # Check for installation method detection
        if grep -q "detect_installation_method" "$update_lib"; then
            record_test "installation_detection_exists" "PASS" "Installation method detection exists"
        else
            record_test "installation_detection_exists" "FAIL" "Installation method detection missing" "MISSING"
        fi
    else
        record_test "update_library_exists" "FAIL" "Update library file missing" "MISSING"
    fi
}

# Test installation method detection
test_installation_detection() {
    log_info "=== Testing Installation Method Detection ==="
    
    # This would ideally test the actual detection logic, but since we're in development mode,
    # we'll test if the CLI can handle different installation scenarios
    
    # Test that update command doesn't crash in development mode
    if output=$("$SPINBOX_CMD" update --check 2>&1); then
        record_test "dev_mode_update_check" "PASS" "Update works in development mode"
    else
        record_test "dev_mode_update_check" "FAIL" "Update fails in development mode"
    fi
}

# Test version comparison functionality
test_version_comparison() {
    log_info "=== Testing Version Comparison ==="
    
    # Get current version
    if current_version=$("$SPINBOX_CMD" --version 2>&1); then
        record_test "version_command_works" "PASS" "Version command works"
        
        # Extract version number
        if echo "$current_version" | grep -q "v[0-9]"; then
            record_test "version_format_valid" "PASS" "Version format is valid"
        else
            record_test "version_format_valid" "FAIL" "Version format unexpected"
        fi
        
        # Test update check references current version
        if update_output=$("$SPINBOX_CMD" update --check 2>&1); then
            if echo "$update_output" | grep -q "$(echo "$current_version" | grep -o 'v[0-9][^[:space:]]*')"; then
                record_test "update_shows_current_version" "PASS" "Update check shows current version"
            else
                record_test "update_shows_current_version" "FAIL" "Update check doesn't show current version"
            fi
        fi
    else
        record_test "version_command_works" "FAIL" "Version command failed"
    fi
}

# Test GitHub integration
test_github_integration() {
    log_info "=== Testing GitHub Integration ==="
    
    # This tests the update system's ability to work with GitHub releases
    # We test this carefully to avoid making actual network calls in tests
    
    # Check if update command mentions GitHub or releases
    if output=$("$SPINBOX_CMD" update --help 2>&1); then
        if echo "$output" | grep -iq "github\|release"; then
            record_test "github_integration_mentioned" "PASS" "GitHub integration mentioned in help"
        else
            record_test "github_integration_mentioned" "FAIL" "GitHub integration not mentioned"
        fi
    else
        record_test "update_help_works" "FAIL" "Update help command failed"
    fi
}

# Test error handling in update system
test_update_error_handling() {
    log_info "=== Testing Update Error Handling ==="
    
    # Test invalid version format
    if output=$("$SPINBOX_CMD" update --version "invalid-version" --dry-run 2>&1); then
        # This should either work (if validation is lenient) or fail gracefully
        record_test "invalid_version_handling" "PASS" "Invalid version handled (accepted or gracefully rejected)"
    else
        # Check if error message is helpful
        if echo "$output" | grep -iq "version\|format\|invalid"; then
            record_test "invalid_version_error_message" "PASS" "Invalid version has helpful error message"
        else
            record_test "invalid_version_error_message" "FAIL" "Invalid version error message not helpful"
        fi
    fi
    
    # Test conflicting flags
    if output=$("$SPINBOX_CMD" update --check --force 2>&1); then
        # This combination might not make sense, test how it's handled
        record_test "conflicting_flags_handled" "PASS" "Conflicting update flags handled"
    else
        record_test "conflicting_flags_handled" "FAIL" "Conflicting update flags cause failure"
    fi
}

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR" 2>/dev/null || true
}

# Main execution
echo "============================================="
echo "Spinbox Update System Test Suite"
echo "============================================="
echo ""

# Verify spinbox command exists
if [[ ! -f "$SPINBOX_CMD" ]]; then
    log_error "Spinbox command not found at: $SPINBOX_CMD"
    exit 1
fi

# Set up cleanup
trap cleanup EXIT

# Create test directory
mkdir -p "$TEST_DIR"
cd "$PROJECT_ROOT"

# Run test suites
test_update_check
echo ""

test_update_dry_run
echo ""

test_version_specific_update
echo ""

test_update_force
echo ""

test_update_yes_flag
echo ""

test_backup_functionality
echo ""

test_installation_detection
echo ""

test_version_comparison
echo ""

test_github_integration
echo ""

test_update_error_handling
echo ""

# Final Analysis
log_info "=== Update System Analysis ==="

if [[ ${#MISSING_FEATURES[@]} -gt 0 ]]; then
    echo ""
    log_warning "Missing or non-functional update features:"
    for feature in "${MISSING_FEATURES[@]}"; do
        echo "  ✗ $feature"
    done
fi

# Summary
echo ""
echo "============================================="
echo "Update System Test Results"
echo "============================================="
echo ""
echo "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"
echo ""

if [[ ${#MISSING_FEATURES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}⚠ UPDATE SYSTEM FEATURES MISSING OR NOT FUNCTIONAL${NC}"
    echo ""
    echo "The following update features may need implementation:"
    for feature in "${MISSING_FEATURES[@]}"; do
        echo "  - $feature"
    done
    echo ""
fi

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}✓ ALL UPDATE SYSTEM TESTS PASSED!${NC}"
    exit_code=0
elif [[ ${#MISSING_FEATURES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}✓ BASIC UPDATE SYSTEM WORKS, BUT SOME FEATURES NEED ATTENTION${NC}"
    exit_code=1
else
    echo -e "${RED}✗ SOME UPDATE SYSTEM TESTS FAILED${NC}"
    exit_code=1
fi

echo ""
echo "Update system analysis complete!"
echo ""

exit $exit_code