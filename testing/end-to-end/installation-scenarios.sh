#!/bin/bash
# End-to-End Installation Scenarios Test Suite
# Tests development mode, local/global installations, remote installations, and edge cases

# Note: Not using set -e so tests can continue after failures

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_FILE="/tmp/spinbox-test-$(date +%Y%m%d-%H%M%S).log"
GITHUB_RAW_URL="https://raw.githubusercontent.com/Gonzillaaa/spinbox/main"

# Source the test utilities
source "$PROJECT_ROOT/testing/test-utils.sh"

# Setup test environment and cleanup
setup_test_environment "End-to-End Installation Scenarios Tests"

# Test results tracking
# Using simple arrays instead of associative arrays for compatibility
TEST_NAMES=()
TEST_RESULTS=()
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Cleanup function
cleanup_all_scenarios() {
    log_info "Cleaning up all test artifacts..."
    rm -rf "$PROJECT_ROOT"/test-* 2>/dev/null || true
    rm -rf ~/test-* 2>/dev/null || true
    rm -rf /tmp/test-* 2>/dev/null || true
    
    # Run non-sudo uninstall first
    "$PROJECT_ROOT/uninstall.sh" --config --force &>/dev/null || true
    
    # Only run sudo uninstall if sudo is available and we have credentials
    if has_sudo; then
        sudo "$PROJECT_ROOT/uninstall.sh" --config --force &>/dev/null || true
    fi
}

# Ensure cleanup runs on exit
trap cleanup_all_scenarios EXIT

# Logging functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}✗${NC} $*" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*" | tee -a "$LOG_FILE"
}

# Test result tracking
record_test() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    ((TOTAL_TESTS++))
    TEST_NAMES+=("$test_name")
    TEST_RESULTS+=("$result")
    
    if [[ "$result" == "PASS" ]]; then
        ((PASSED_TESTS++))
        log_success "$test_name: $message"
    elif [[ "$result" == "SKIP" ]]; then
        ((SKIPPED_TESTS++))
        log_warning "$test_name: $message"
    else
        ((FAILED_TESTS++))
        log_error "$test_name: $message"
    fi
}

# Test execution wrapper
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="${3:-0}"
    
    log_info "Running: $test_name"
    
    if eval "$test_command" >> "$LOG_FILE" 2>&1; then
        if [[ "$expected_result" == "0" ]]; then
            record_test "$test_name" "PASS" "Command succeeded as expected"
            return 0
        else
            record_test "$test_name" "FAIL" "Command succeeded but failure was expected"
            return 1
        fi
    else
        local exit_code=$?
        if [[ "$expected_result" != "0" ]]; then
            record_test "$test_name" "PASS" "Command failed as expected"
            return 0
        else
            record_test "$test_name" "FAIL" "Command failed with exit code $exit_code"
            return 1
        fi
    fi
}

# Profile validation function
validate_profiles() {
    local mode="$1"
    local profile_output="$2"
    
    # Check enhanced AI/LLM profile
    if echo "$profile_output" | grep -q "OpenAI, Anthropic, LangChain"; then
        record_test "${mode}_ai_profile" "PASS" "Enhanced AI/LLM profile found"
    else
        record_test "${mode}_ai_profile" "FAIL" "Enhanced AI/LLM profile missing"
    fi
    
    # Check enhanced data-science profile
    if echo "$profile_output" | grep -q "pandas, numpy, matplotlib"; then
        record_test "${mode}_data_science_profile" "PASS" "Enhanced data-science profile found"
    else
        record_test "${mode}_data_science_profile" "FAIL" "Enhanced data-science profile missing"
    fi
    
    # Check minimal profile removed
    if echo "$profile_output" | grep -q "minimal"; then
        record_test "${mode}_minimal_removed" "FAIL" "Minimal profile still exists"
    else
        record_test "${mode}_minimal_removed" "PASS" "Minimal profile correctly removed"
    fi
    
    # Check profile count
    local profile_count=$(echo "$profile_output" | grep -E "^  [a-z-]+$" | wc -l | tr -d ' ')
    if [[ "$profile_count" == "6" ]]; then
        record_test "${mode}_profile_count" "PASS" "Correct profile count: $profile_count"
    else
        record_test "${mode}_profile_count" "FAIL" "Incorrect profile count: $profile_count (expected 6)"
    fi
    
    # Check new profiles exist
    if echo "$profile_output" | grep -q "python" && echo "$profile_output" | grep -q "node"; then
        record_test "${mode}_new_profiles" "PASS" "Python and node profiles found"
    else
        record_test "${mode}_new_profiles" "FAIL" "Python or node profile missing"
    fi
}

# Cleanup function
cleanup_installation() {
    log_info "Cleaning up existing installations..."
    
    # Try modern uninstall first
    if [[ -f "$PROJECT_ROOT/uninstall.sh" ]]; then
        "$PROJECT_ROOT/uninstall.sh" --config --force >> "$LOG_FILE" 2>&1 || true
        # Only use sudo if available
        if has_sudo; then
            sudo "$PROJECT_ROOT/uninstall.sh" --config --force >> "$LOG_FILE" 2>&1 || true
        fi
    fi
    
    # Manual cleanup as fallback - only with sudo if available
    if has_sudo; then
        sudo rm -f /usr/local/bin/spinbox >> "$LOG_FILE" 2>&1 || true
    fi
    rm -f "$HOME/.local/bin/spinbox" >> "$LOG_FILE" 2>&1 || true
    rm -rf "$HOME/.spinbox" >> "$LOG_FILE" 2>&1 || true
    if has_sudo; then
        sudo rm -rf /usr/local/lib/spinbox >> "$LOG_FILE" 2>&1 || true
    fi
    rm -rf "$HOME/.local/lib/spinbox" >> "$LOG_FILE" 2>&1 || true
    
    # Clean test projects
    rm -rf ~/test-* >> "$LOG_FILE" 2>&1 || true
    rm -rf "$PROJECT_ROOT"/test-* >> "$LOG_FILE" 2>&1 || true
}

# Parse command line arguments
RUN_ALL=true
RUN_DEV=false
RUN_LOCAL=false
RUN_GLOBAL=false
RUN_REMOTE=false
RUN_EDGE=false
SKIP_CLEANUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dev) RUN_ALL=false; RUN_DEV=true; shift ;;
        --local) RUN_ALL=false; RUN_LOCAL=true; shift ;;
        --global) RUN_ALL=false; RUN_GLOBAL=true; shift ;;
        --remote) RUN_ALL=false; RUN_REMOTE=true; shift ;;
        --edge) RUN_ALL=false; RUN_EDGE=true; shift ;;
        --skip-cleanup) SKIP_CLEANUP=true; shift ;;
        --help)
            cat << EOF
Spinbox Comprehensive Test Suite

USAGE:
    $(basename "$0") [OPTIONS]

OPTIONS:
    --dev           Test only development mode
    --local         Test only local installation
    --global        Test only global installation
    --remote        Test only remote installations
    --edge          Test only edge cases
    --skip-cleanup  Skip cleanup between tests
    --help          Show this help message

EXAMPLES:
    $(basename "$0")              # Run all tests
    $(basename "$0") --local      # Test only local installation
    $(basename "$0") --dev --edge # Test development mode and edge cases

NOTES:
    - Requires sudo for global installation tests
    - Creates log file at: $LOG_FILE
    - Tests are modular and can be run independently

EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Main test execution
echo "============================================="
echo "Spinbox Comprehensive Test Suite"
echo "============================================="
echo "Log file: $LOG_FILE"
echo ""

cd "$PROJECT_ROOT"

# Phase 1: Development Mode Tests
if [[ "$RUN_ALL" == "true" || "$RUN_DEV" == "true" ]]; then
    echo "=== Phase 1: Development Mode Tests ==="
    
    # Test development binary exists
    if [[ -f "$PROJECT_ROOT/bin/spinbox" ]]; then
        record_test "dev_binary_exists" "PASS" "Development binary found"
        
        # Test version command
        run_test "dev_version" "$PROJECT_ROOT/bin/spinbox --version"
        
        # Test profiles
        dev_profiles=$("$PROJECT_ROOT/bin/spinbox" profiles 2>&1)
        validate_profiles "dev" "$dev_profiles"
        
        # Test project creation commands
        run_test "dev_create_python" "$PROJECT_ROOT/bin/spinbox create test-dev-python --python --dry-run"
        run_test "dev_create_node" "$PROJECT_ROOT/bin/spinbox create test-dev-node --node --dry-run"
        run_test "dev_create_profile_python" "$PROJECT_ROOT/bin/spinbox create test-dev-profile --profile python --dry-run"
        
        # Test help commands
        run_test "dev_help_main" "$PROJECT_ROOT/bin/spinbox --help"
        run_test "dev_help_create" "$PROJECT_ROOT/bin/spinbox create --help"
        run_test "dev_help_profiles" "$PROJECT_ROOT/bin/spinbox profiles --help"
    else
        record_test "dev_binary_exists" "FAIL" "Development binary not found"
    fi
    
    echo ""
fi

# Phase 2: Local Installation Tests
if [[ "$RUN_ALL" == "true" || "$RUN_LOCAL" == "true" ]]; then
    echo "=== Phase 2: Local Installation Tests ==="
    
    [[ "$SKIP_CLEANUP" != "true" ]] && cleanup_installation
    
    # Install locally
    run_test "local_install" "$PROJECT_ROOT/install-user.sh"
    
    # Update PATH for testing
    export PATH="$HOME/.local/bin:$PATH"
    hash -r
    
    # Verify installation
    if [[ -f "$HOME/.local/bin/spinbox" ]]; then
        record_test "local_binary_installed" "PASS" "Local binary installed"
    else
        record_test "local_binary_installed" "FAIL" "Local binary not found"
    fi
    
    if [[ -d "$HOME/.spinbox/runtime" ]]; then
        record_test "local_runtime_created" "PASS" "Centralized runtime created"

        # Check runtime contents
        for dir in lib generators templates; do
            if [[ -d "$HOME/.spinbox/runtime/$dir" ]]; then
                record_test "local_runtime_${dir}" "PASS" "$dir directory exists in runtime"
            else
                record_test "local_runtime_${dir}" "FAIL" "$dir directory missing from runtime"
            fi
        done
    else
        record_test "local_runtime_created" "FAIL" "Centralized runtime missing"
    fi
    
    # Test installed binary
    run_test "local_version" "spinbox --version"
    
    # Test profiles
    local_profiles=$(spinbox profiles 2>&1)
    validate_profiles "local" "$local_profiles"
    
    # Test base options
    run_test "local_base_python" "spinbox create test-local-python --python --dry-run"
    run_test "local_base_node" "spinbox create test-local-node --node --dry-run"
    
    # Test profile options
    run_test "local_profile_python" "spinbox create test-local-profile-py --profile python --dry-run"
    run_test "local_profile_node" "spinbox create test-local-profile-nd --profile node --dry-run"
    run_test "local_profile_web" "spinbox create test-local-web --profile web-app --dry-run"
    
    # Test update command
    run_test "local_update_check" "spinbox update --check"
    
    # Test uninstall
    run_test "local_uninstall" "spinbox uninstall --config --force"
    
    echo ""
fi

# Phase 3: Global Installation Tests
if [[ "$RUN_ALL" == "true" || "$RUN_GLOBAL" == "true" ]]; then
    echo "=== Phase 3: Global Installation Tests ==="
    
    # Check sudo availability
    if ! has_sudo; then
        log_warning "Skipping global installation tests (sudo not available or not enabled)"
        record_test "global_install" "SKIP" "Global installation requires sudo"
        record_test "global_binary_installed" "SKIP" "Global binary test skipped"
        record_test "global_source_created" "SKIP" "Global source test skipped"
        record_test "global_version" "SKIP" "Global version test skipped"
        record_test "global_ai_profile" "SKIP" "Global AI profile test skipped"
        record_test "global_data_science_profile" "SKIP" "Global data science profile test skipped"
        record_test "global_minimal_removed" "SKIP" "Global minimal profile test skipped"
        record_test "global_create_project" "SKIP" "Global create project test skipped"
        record_test "global_config_list" "SKIP" "Global config list test skipped"
        record_test "global_config_get" "SKIP" "Global config get test skipped"
        record_test "global_uninstall" "SKIP" "Global uninstall test skipped"
        echo ""
    else
        [[ "$SKIP_CLEANUP" != "true" ]] && cleanup_installation
        
        # Install globally
        run_test "global_install" "sudo $PROJECT_ROOT/install.sh"
        
        # Clear hash table
        hash -r
        
        # Verify installation
        if [[ -f "/usr/local/bin/spinbox" ]]; then
            record_test "global_binary_installed" "PASS" "Global binary installed"
        else
            record_test "global_binary_installed" "FAIL" "Global binary not found"
        fi
        
        if [[ -d "$HOME/.spinbox/runtime" ]]; then
            record_test "global_runtime_created" "PASS" "Centralized runtime created"
        else
            record_test "global_runtime_created" "FAIL" "Centralized runtime missing"
        fi
        
        # Test installed binary
        run_test "global_version" "spinbox --version"
        
        # Test profiles
        global_profiles=$(spinbox profiles 2>&1)
        validate_profiles "global" "$global_profiles"
        
        # Test project creation
        run_test "global_create_project" "spinbox create test-global-project --profile data-science --dry-run"
        
        # Test config commands
        run_test "global_config_list" "spinbox config --list"
        run_test "global_config_get" "spinbox config --get PYTHON_VERSION"
        
        # Test uninstall
        run_test "global_uninstall" "sudo spinbox uninstall --config --force"
        
        echo ""
    fi
fi

# Phase 4: Remote Installation Tests (requires network)
if [[ "$RUN_ALL" == "true" || "$RUN_REMOTE" == "true" ]]; then
    echo "=== Phase 4: Remote Installation Tests ==="
    
    log_warning "Remote tests require network access and will install from GitHub"
    
    [[ "$SKIP_CLEANUP" != "true" ]] && cleanup_installation
    
    # Test user installation from GitHub
    run_test "remote_user_install" "curl -sSL $GITHUB_RAW_URL/install-user.sh | bash"
    
    # Update PATH
    export PATH="$HOME/.local/bin:$PATH"
    hash -r
    
    if command -v spinbox &> /dev/null; then
        record_test "remote_user_command" "PASS" "Remote user installation successful"
        
        # Quick profile check
        remote_profiles=$(spinbox profiles 2>&1)
        if echo "$remote_profiles" | grep -iq "profiles"; then
            record_test "remote_user_profiles" "PASS" "Remote installation shows profiles"
        else
            record_test "remote_user_profiles" "FAIL" "Remote installation profiles issue"
        fi
    else
        record_test "remote_user_command" "FAIL" "Remote user installation failed"
    fi
    
    # Cleanup user installation
    run_test "remote_user_cleanup" "spinbox uninstall --config --force || true"
    
    # Test system installation from GitHub
    if ! has_sudo; then
        record_test "remote_system_install" "SKIP" "Remote system installation requires sudo"
        record_test "remote_system_command" "SKIP" "Remote system command test skipped"
        record_test "remote_system_cleanup" "SKIP" "Remote system cleanup test skipped"
    else
        run_test "remote_system_install" "curl -sSL $GITHUB_RAW_URL/install.sh | sudo bash"
        
        hash -r
        
        if command -v spinbox &> /dev/null; then
            record_test "remote_system_command" "PASS" "Remote system installation successful"
        else
            record_test "remote_system_command" "FAIL" "Remote system installation failed"
        fi
        
        # Cleanup system installation
        run_test "remote_system_cleanup" "sudo spinbox uninstall --config --force || true"
    fi
    
    echo ""
fi

# Phase 5: Edge Cases and Error Handling
if [[ "$RUN_ALL" == "true" || "$RUN_EDGE" == "true" ]]; then
    echo "=== Phase 5: Edge Cases and Error Handling ==="
    
    [[ "$SKIP_CLEANUP" != "true" ]] && cleanup_installation
    
    # Test invalid commands
    run_test "edge_invalid_command" "$PROJECT_ROOT/bin/spinbox invalid-command" 1
    run_test "edge_invalid_profile" "$PROJECT_ROOT/bin/spinbox create test --profile invalid" 1
    
    # Test missing project name
    run_test "edge_missing_project" "$PROJECT_ROOT/bin/spinbox create" 1
    
    # Test conflicting options - currently spinbox accepts multiple profiles and uses the last one
    # This behavior might change in the future, for now we expect it to succeed
    run_test "edge_conflicting_profiles" "$PROJECT_ROOT/bin/spinbox create test-conflict --profile python --profile node --dry-run" 0
    
    # Test permission issues (create read-only directory)
    mkdir -p /tmp/readonly-test && chmod 444 /tmp/readonly-test
    run_test "edge_readonly_dir" "$PROJECT_ROOT/bin/spinbox create /tmp/readonly-test/project --python" 1
    rm -rf /tmp/readonly-test
    
    # Test double installation
    if [[ "$RUN_ALL" == "true" ]]; then
        $PROJECT_ROOT/install-user.sh >> "$LOG_FILE" 2>&1
        run_test "edge_double_install" "$PROJECT_ROOT/install-user.sh"
        cleanup_installation
    fi
    
    # Test uninstall when nothing installed
    run_test "edge_uninstall_nothing" "$PROJECT_ROOT/uninstall.sh --force"
    
    echo ""
fi

# Phase 6: Architecture Consistency Tests
if [[ "$RUN_ALL" == "true" ]]; then
    echo "=== Phase 6: Architecture Consistency Tests ==="
    
    cleanup_installation
    
    # Get development mode output
    dev_output=$("$PROJECT_ROOT/bin/spinbox" profiles 2>&1)
    
    # Install locally and get output
    $PROJECT_ROOT/install-user.sh >> "$LOG_FILE" 2>&1
    export PATH="$HOME/.local/bin:$PATH"
    hash -r
    local_output=$(spinbox profiles 2>&1)
    
    # Compare outputs
    if diff <(echo "$dev_output") <(echo "$local_output") >> "$LOG_FILE" 2>&1; then
        record_test "consistency_dev_local" "PASS" "Development and local outputs identical"
    else
        record_test "consistency_dev_local" "FAIL" "Development and local outputs differ"
    fi
    
    # Cleanup and install globally
    cleanup_installation
    if ! has_sudo; then
        record_test "consistency_dev_global" "SKIP" "Global installation consistency test requires sudo"
    else
        sudo $PROJECT_ROOT/install.sh >> "$LOG_FILE" 2>&1
        hash -r
        global_output=$(spinbox profiles 2>&1)
        
        # Compare outputs
        if diff <(echo "$dev_output") <(echo "$global_output") >> "$LOG_FILE" 2>&1; then
            record_test "consistency_dev_global" "PASS" "Development and global outputs identical"
        else
            record_test "consistency_dev_global" "FAIL" "Development and global outputs differ"
        fi
    fi
    
    cleanup_installation
    echo ""
fi

# Test: Production Mode Architecture Verification
echo "Testing Production Mode Architecture (Simplified Installation)..."
echo ""

# Test that installations always use production mode architecture
test_production_mode_architecture() {
    log_info "Testing production mode architecture consistency..."
    
    # Test user installation
    run_test "user_production_install" "$PROJECT_ROOT/install-user.sh"
    
    if command -v spinbox >/dev/null 2>&1; then
        # Check that binary uses production mode paths
        if [[ -d "$HOME/.spinbox/runtime/lib" ]]; then
            record_test "user_production_mode" "PASS" "User installation uses production mode architecture"
            
            # Verify Python 3.11 default
            python_version=$(spinbox config --get PYTHON_VERSION 2>/dev/null || echo "unknown")
            if [[ "$python_version" == "3.11" ]]; then
                record_test "python_3_11_default" "PASS" "Python 3.11 is default version"
            else
                record_test "python_3_11_default" "FAIL" "Python version is $python_version, expected 3.11"
            fi
            
            # Test Docker Hub functionality with simplified architecture
            if spinbox create test-arch --python --docker-hub --dry-run >/dev/null 2>&1; then
                record_test "docker_hub_simplified" "PASS" "Docker Hub works with simplified architecture"
            else
                record_test "docker_hub_simplified" "FAIL" "Docker Hub fails with simplified architecture"
            fi
            
            # Clean up test project
            rm -rf test-arch 2>/dev/null || true
            
        else
            record_test "user_production_mode" "FAIL" "User installation missing production mode files"
            record_test "python_3_11_default" "SKIP" "Skipped due to architecture failure"
            record_test "docker_hub_simplified" "SKIP" "Skipped due to architecture failure"
        fi
        
        # Clean up
        spinbox uninstall --config --force >/dev/null 2>&1 || true
    else
        record_test "user_production_mode" "FAIL" "User installation failed"
        record_test "python_3_11_default" "SKIP" "Skipped due to install failure"
        record_test "docker_hub_simplified" "SKIP" "Skipped due to install failure"
    fi
}

test_production_mode_architecture
echo ""

# Final Report
echo "============================================="
echo "Test Suite Results"
echo "============================================="
echo ""
echo "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"
echo -e "${YELLOW}Skipped: $SKIPPED_TESTS${NC}"
echo ""

if [[ $FAILED_TESTS -eq 0 ]]; then
    if [[ $SKIPPED_TESTS -eq 0 ]]; then
        echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
    else
        echo -e "${GREEN}✓ ALL TESTS PASSED (some skipped)!${NC}"
    fi
    exit_code=0
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    echo ""
    echo "Failed tests:"
    for i in "${!TEST_NAMES[@]}"; do
        if [[ "${TEST_RESULTS[$i]}" == "FAIL" ]]; then
            echo "  - ${TEST_NAMES[$i]}"
        fi
    done
    exit_code=1
fi

echo ""
echo "Full test log available at: $LOG_FILE"
echo ""

# Cleanup temporary files
rm -f /tmp/dev_profiles.txt /tmp/local_profiles.txt /tmp/global_profiles.txt

exit $exit_code