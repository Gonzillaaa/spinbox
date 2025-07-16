#!/bin/bash
# Test Utilities - Shared functionality for all test scripts
# Common patterns for cleanup, logging, and assertions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test result tracking
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Simple sudo check function
has_sudo() {
    # Check if sudo is available and user has privileges
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Common cleanup function
cleanup_test_env() {
    echo -e "${BLUE}[Cleanup] Cleaning up test artifacts...${NC}"
    
    # Remove test directories from project root
    echo -e "${BLUE}[Cleanup] Removing test directories from project root...${NC}"
    rm -rf "$PROJECT_ROOT"/test-* 2>/dev/null || true
    rm -rf "$PROJECT_ROOT"/perf-test* 2>/dev/null || true
    rm -rf "$PROJECT_ROOT"/smoke-* 2>/dev/null || true
    
    # Remove test directories from home
    echo -e "${BLUE}[Cleanup] Removing test directories from home...${NC}"
    rm -rf ~/test-* 2>/dev/null || true
    rm -rf ~/perf-test* 2>/dev/null || true
    rm -rf ~/smoke-* 2>/dev/null || true
    
    # Remove test directories from tmp
    echo -e "${BLUE}[Cleanup] Removing test directories from tmp...${NC}"
    rm -rf /tmp/test-* 2>/dev/null || true
    rm -rf /tmp/spinbox-* 2>/dev/null || true
    rm -rf /tmp/perf-test* 2>/dev/null || true
    rm -rf /tmp/smoke-* 2>/dev/null || true
    
    # Remove temporary test directory if set
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        echo -e "${BLUE}[Cleanup] Removing temporary test directory...${NC}"
        rm -rf "$TEST_DIR" 2>/dev/null || true
    fi
    
    # Clean up any installations (only if uninstall script exists)
    if [[ -f "$PROJECT_ROOT/uninstall.sh" ]]; then
        echo -e "${BLUE}[Cleanup] Cleaning up installations...${NC}"
        "$PROJECT_ROOT/uninstall.sh" --config --force &>/dev/null || true
        # Only use sudo if explicitly enabled and available
        if [[ "$ENABLE_SUDO" == "true" ]] && has_sudo; then
            sudo "$PROJECT_ROOT/uninstall.sh" --config --force &>/dev/null || true
        fi
    fi
    
    echo -e "${GREEN}[Cleanup] Test cleanup completed${NC}"
}

# Set up trap for cleanup on exit
setup_cleanup_trap() {
    trap cleanup_test_env EXIT
}

# Common logging functions
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

log_section() {
    echo ""
    echo -e "${YELLOW}=== $* ===${NC}"
}

# Test result functions
record_test_result() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    ((TESTS_RUN++))
    
    if [[ "$result" == "PASS" ]]; then
        ((TESTS_PASSED++))
        log_success "$test_name: $message"
    else
        ((TESTS_FAILED++))
        log_error "$test_name: $message"
    fi
}

# Test execution wrapper with timeout
run_test_with_timeout() {
    local test_name="$1"
    local test_command="$2"
    local timeout_seconds="${3:-30}"
    local expected_result="${4:-0}"
    
    log_info "Running: $test_name"
    
    # Record start time
    local start_time=$(date +%s)
    
    # Run command with timeout
    if timeout "$timeout_seconds" bash -c "$test_command" >/dev/null 2>&1; then
        local exit_code=$?
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        if [[ "$expected_result" == "0" ]]; then
            record_test_result "$test_name" "PASS" "Command succeeded as expected (${duration}s)"
            return 0
        else
            record_test_result "$test_name" "FAIL" "Command succeeded but failure was expected (${duration}s)"
            return 1
        fi
    else
        local exit_code=$?
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        if [[ "$expected_result" != "0" ]]; then
            record_test_result "$test_name" "PASS" "Command failed as expected (${duration}s)"
            return 0
        else
            record_test_result "$test_name" "FAIL" "Command failed or timed out (exit code: $exit_code, ${duration}s)"
            return 1
        fi
    fi
}

# Enhanced assertion functions
assert_true() {
    local condition="$1"
    local description="$2"
    
    if eval "$condition"; then
        record_test_result "$description" "PASS" "Condition true"
        return 0
    else
        # Capture command output for better error reporting
        local output
        output=$(eval "$condition" 2>&1 || true)
        local error_msg="Condition false: $condition"
        if [[ -n "$output" ]]; then
            error_msg="$error_msg\n  Output: $output"
        fi
        record_test_result "$description" "FAIL" "$error_msg"
        return 1
    fi
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local description="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        record_test_result "$description" "PASS" "Values match"
        return 0
    else
        record_test_result "$description" "FAIL" "Expected: '$expected', Actual: '$actual'"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local description="$3"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        record_test_result "$description" "PASS" "String contains expected text"
        return 0
    else
        record_test_result "$description" "FAIL" "String '$haystack' does not contain '$needle'"
        return 1
    fi
}

assert_file_exists() {
    local file_path="$1"
    local description="$2"
    
    if [[ -f "$file_path" ]]; then
        record_test_result "$description" "PASS" "File exists"
        return 0
    else
        record_test_result "$description" "FAIL" "File not found: $file_path"
        return 1
    fi
}

assert_directory_exists() {
    local dir_path="$1"
    local description="$2"
    
    if [[ -d "$dir_path" ]]; then
        record_test_result "$description" "PASS" "Directory exists"
        return 0
    else
        record_test_result "$description" "FAIL" "Directory not found: $dir_path"
        return 1
    fi
}

assert_executable() {
    local file_path="$1"
    local description="$2"
    
    if [[ -x "$file_path" ]]; then
        record_test_result "$description" "PASS" "File is executable"
        return 0
    else
        record_test_result "$description" "FAIL" "File is not executable: $file_path"
        return 1
    fi
}

# Test suite summary
show_test_summary() {
    local suite_name="$1"
    
    echo ""
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "${YELLOW}           $suite_name Results              ${NC}"
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "Tests run:    $TESTS_RUN"
    echo -e "${GREEN}Passed:       $TESTS_PASSED${NC}"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}Failed:       $TESTS_FAILED${NC}"
        echo ""
        echo -e "${RED}Some tests failed!${NC}"
        return 1
    else
        echo -e "${GREEN}Failed:       $TESTS_FAILED${NC}"
        echo ""
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    fi
}

# Common setup for test environment
setup_test_environment() {
    local test_name="$1"
    
    # Set up project root - find the spinbox directory
    local calling_script="${BASH_SOURCE[1]}"
    SCRIPT_DIR="$(cd "$(dirname "$calling_script")" && pwd)"
    
    # Find the project root by looking for the spinbox directory
    PROJECT_ROOT="$SCRIPT_DIR"
    while [[ "$PROJECT_ROOT" != "/" && ! -f "$PROJECT_ROOT/bin/spinbox" ]]; do
        PROJECT_ROOT="$(cd "$PROJECT_ROOT/.." && pwd)"
    done
    
    if [[ ! -f "$PROJECT_ROOT/bin/spinbox" ]]; then
        echo "Error: Could not find spinbox project root"
        exit 1
    fi
    
    # Create temporary test directory
    TEST_DIR="/tmp/spinbox-test-$$"
    mkdir -p "$TEST_DIR"
    
    # Setup cleanup trap
    setup_cleanup_trap
    
    log_info "Test environment setup for: $test_name"
    log_info "Project root: $PROJECT_ROOT"
    log_info "Test directory: $TEST_DIR"
}

# Validate CLI binary exists and is executable
validate_cli_binary() {
    local cli_path="$PROJECT_ROOT/bin/spinbox"
    
    assert_file_exists "$cli_path" "CLI binary exists"
    assert_executable "$cli_path" "CLI binary is executable"
    
    return $?
}

# Test profile validation helper
validate_profile() {
    local profile_name="$1"
    local cli_path="$PROJECT_ROOT/bin/spinbox"
    local profiles_dir="$PROJECT_ROOT/templates/profiles"
    
    # Test profile file exists
    local profile_file="$profiles_dir/${profile_name}.toml"
    assert_file_exists "$profile_file" "Profile $profile_name file exists"
    
    # Test profile has required sections
    assert_true 'grep -q "\\[profile\\]" "$profile_file"' "Profile $profile_name has [profile] section"
    assert_true 'grep -q "\\[components\\]" "$profile_file"' "Profile $profile_name has [components] section"
    
    # Test profile can be displayed via CLI
    assert_true '"$cli_path" profiles "$profile_name" >/dev/null 2>&1' "Profile $profile_name displays via CLI"
}

# Common component generator validation
validate_component_generator() {
    local component_name="$1"
    local generators_dir="$PROJECT_ROOT/generators"
    
    assert_file_exists "$generators_dir/${component_name}.sh" "Component generator $component_name exists"
    assert_executable "$generators_dir/${component_name}.sh" "Component generator $component_name is executable"
}

# Reset test counters (for scripts that run multiple test suites)
reset_test_counters() {
    TESTS_RUN=0
    TESTS_PASSED=0
    TESTS_FAILED=0
}

# Export common variables and functions for use in other scripts
export -f cleanup_test_env setup_cleanup_trap
export -f log_info log_success log_error log_warning log_section
export -f record_test_result run_test_with_timeout
export -f assert_true assert_equals assert_contains assert_file_exists assert_directory_exists assert_executable
export -f show_test_summary setup_test_environment validate_cli_binary validate_profile validate_component_generator
export -f reset_test_counters