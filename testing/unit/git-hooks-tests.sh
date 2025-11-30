#!/bin/bash
# Git Hooks Tests - Test git hooks installation and configuration
# Tests the git hooks functionality for Python projects

# Note: Not using set -e so tests can continue after failures
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Source the test utilities
source testing/test-utils.sh

# Test configuration
TEST_PROJECT_NAME="test-git-hooks"
CLI_PATH="$PROJECT_ROOT/bin/spinbox"

# Setup test environment and cleanup
setup_test_environment "Git Hooks Tests"

# Cleanup test environment
cleanup_test_env() {
    rm -rf "$TEST_DIR" 2>/dev/null || true
    rm -rf "/tmp/$TEST_PROJECT_NAME" 2>/dev/null || true
    rm -rf "/tmp/test-no-hooks" 2>/dev/null || true
    rm -rf "/tmp/test-no-git" 2>/dev/null || true
    rm -rf "/tmp/test-dryrun-hooks" 2>/dev/null || true
    rm -rf "/tmp/test-db-only" 2>/dev/null || true
}

# Ensure cleanup runs on exit
trap cleanup_test_env EXIT

# Test 1: Hooks installed for Python project
test_hooks_installed() {
    echo -e "\n${YELLOW}=== Test: Hooks Installed for Python Project ===${NC}"

    # Create a real Python project (not dry-run)
    "$CLI_PATH" create "/tmp/$TEST_PROJECT_NAME" --python > /dev/null 2>&1

    assert_true \
        "[[ -f \"/tmp/$TEST_PROJECT_NAME/.git/hooks/pre-commit\" ]]" \
        "Pre-commit hook file created"

    assert_true \
        "[[ -f \"/tmp/$TEST_PROJECT_NAME/.git/hooks/pre-push\" ]]" \
        "Pre-push hook file created"
}

# Test 2: Hooks are executable
test_hooks_executable() {
    echo -e "\n${YELLOW}=== Test: Hooks Are Executable ===${NC}"

    assert_true \
        "[[ -x \"/tmp/$TEST_PROJECT_NAME/.git/hooks/pre-commit\" ]]" \
        "Pre-commit hook is executable"

    assert_true \
        "[[ -x \"/tmp/$TEST_PROJECT_NAME/.git/hooks/pre-push\" ]]" \
        "Pre-push hook is executable"
}

# Test 3: Hook content matches template
test_hook_content() {
    echo -e "\n${YELLOW}=== Test: Hook Content Matches Template ===${NC}"

    # Check pre-commit hook contains expected content
    assert_true \
        "grep -q 'Pre-commit hook for Python projects' \"/tmp/$TEST_PROJECT_NAME/.git/hooks/pre-commit\"" \
        "Pre-commit hook has correct header"

    assert_true \
        "grep -q 'black' \"/tmp/$TEST_PROJECT_NAME/.git/hooks/pre-commit\"" \
        "Pre-commit hook includes black check"

    assert_true \
        "grep -q 'isort' \"/tmp/$TEST_PROJECT_NAME/.git/hooks/pre-commit\"" \
        "Pre-commit hook includes isort check"

    assert_true \
        "grep -q 'flake8' \"/tmp/$TEST_PROJECT_NAME/.git/hooks/pre-commit\"" \
        "Pre-commit hook includes flake8 check"

    # Check pre-push hook contains expected content
    assert_true \
        "grep -q 'Pre-push hook for Python projects' \"/tmp/$TEST_PROJECT_NAME/.git/hooks/pre-push\"" \
        "Pre-push hook has correct header"

    assert_true \
        "grep -q 'pytest' \"/tmp/$TEST_PROJECT_NAME/.git/hooks/pre-push\"" \
        "Pre-push hook includes pytest"
}

# Test 4: --no-hooks flag prevents installation but keeps Git
test_no_hooks_flag() {
    echo -e "\n${YELLOW}=== Test: --no-hooks Flag Prevents Hook Installation (Git Still Initialized) ===${NC}"

    # Create project with --no-hooks flag
    "$CLI_PATH" create "/tmp/test-no-hooks" --python --no-hooks > /dev/null 2>&1

    # Git should still be initialized
    assert_true \
        "[[ -d \"/tmp/test-no-hooks/.git\" ]]" \
        "Git repository still initialized with --no-hooks"

    assert_true \
        "[[ ! -f \"/tmp/test-no-hooks/.git/hooks/pre-commit\" ]]" \
        "Pre-commit hook NOT created with --no-hooks"

    assert_true \
        "[[ ! -f \"/tmp/test-no-hooks/.git/hooks/pre-push\" ]]" \
        "Pre-push hook NOT created with --no-hooks"

    # Cleanup
    rm -rf "/tmp/test-no-hooks" 2>/dev/null || true
}

# Test 4b: --no-git flag prevents Git initialization
test_no_git_flag() {
    echo -e "\n${YELLOW}=== Test: --no-git Flag Prevents Git Initialization ===${NC}"

    # Create project with --no-git flag
    "$CLI_PATH" create "/tmp/test-no-git" --python --no-git > /dev/null 2>&1

    # Git should NOT be initialized
    assert_true \
        "[[ ! -d \"/tmp/test-no-git/.git\" ]]" \
        "Git repository NOT initialized with --no-git"

    # Project should still exist
    assert_true \
        "[[ -d \"/tmp/test-no-git\" ]]" \
        "Project directory created with --no-git"

    # Cleanup
    rm -rf "/tmp/test-no-git" 2>/dev/null || true
}

# Test 5: Dry-run doesn't create actual hooks
test_dryrun_no_hooks() {
    echo -e "\n${YELLOW}=== Test: Dry-run Doesn't Create Actual Hooks ===${NC}"

    # Run dry-run
    "$CLI_PATH" create "/tmp/test-dryrun-hooks" --python --dry-run > /dev/null 2>&1

    # Verify hooks aren't actually created in dry-run mode
    assert_true \
        "[[ ! -f \"/tmp/test-dryrun-hooks/.git/hooks/pre-commit\" ]]" \
        "Dry-run doesn't create actual hook files"

    assert_true \
        "[[ ! -d \"/tmp/test-dryrun-hooks\" ]]" \
        "Dry-run doesn't create project directory"
}

# Test 6: Git repo initialized if needed
test_git_init() {
    echo -e "\n${YELLOW}=== Test: Git Repo Initialized if Needed ===${NC}"

    # The project should have .git directory
    assert_true \
        "[[ -d \"/tmp/$TEST_PROJECT_NAME/.git\" ]]" \
        "Git repository initialized"
}

# Test 7: check_git_hooks function works
test_check_function() {
    echo -e "\n${YELLOW}=== Test: check_git_hooks Function Works ===${NC}"

    # Source git-hooks library
    source "$PROJECT_ROOT/lib/utils.sh"
    source "$PROJECT_ROOT/lib/git-hooks.sh"

    # Check hooks in test project
    output=$(check_git_hooks "/tmp/$TEST_PROJECT_NAME" 2>&1)

    assert_true \
        "echo \"$output\" | grep -q 'pre-commit hook: installed'" \
        "check_git_hooks shows pre-commit installed"

    assert_true \
        "echo \"$output\" | grep -q 'pre-push hook: installed'" \
        "check_git_hooks shows pre-push installed"
}

# Test 8: Hooks not installed for non-Python projects
test_hooks_only_python() {
    echo -e "\n${YELLOW}=== Test: Hooks Only Installed for Python Projects ===${NC}"

    # Create a Node.js project
    "$CLI_PATH" create "/tmp/test-node-hooks" --node > /dev/null 2>&1

    # Node projects currently don't get hooks (feature not implemented yet)
    # This test verifies current behavior
    assert_true \
        "[[ ! -f \"/tmp/test-node-hooks/.git/hooks/pre-commit\" ]]" \
        "Hooks not installed for Node.js projects (expected behavior)"

    # Cleanup
    rm -rf "/tmp/test-node-hooks" 2>/dev/null || true
}

# Test 9: Git initialized for database-only projects
test_git_init_db_only() {
    echo -e "\n${YELLOW}=== Test: Git Initialized for Database-Only Projects ===${NC}"

    # Create a PostgreSQL-only project
    "$CLI_PATH" create "/tmp/test-db-only" --postgresql > /dev/null 2>&1

    # Git should be initialized even without Python/Node
    assert_true \
        "[[ -d \"/tmp/test-db-only/.git\" ]]" \
        "Git repository initialized for database-only project"

    # But no hooks since no Python/Node
    assert_true \
        "[[ ! -f \"/tmp/test-db-only/.git/hooks/pre-commit\" ]]" \
        "No hooks for database-only project (expected)"

    # Cleanup
    rm -rf "/tmp/test-db-only" 2>/dev/null || true
}

# Main test execution
main() {
    echo -e "${BLUE}Starting Spinbox Git Hooks Tests${NC}"
    echo "Testing git hooks installation and configuration"

    # Setup and cleanup any existing test artifacts
    cleanup_test_env

    # Record start time
    start_time=$(date +%s.%N)

    # Run test suites
    test_hooks_installed
    test_hooks_executable
    test_hook_content
    test_no_hooks_flag
    test_no_git_flag
    test_dryrun_no_hooks
    test_git_init
    test_check_function
    test_hooks_only_python
    test_git_init_db_only

    # Record end time
    end_time=$(date +%s.%N)
    total_duration=$(echo "$end_time - $start_time" | bc)

    # Cleanup
    cleanup_test_env

    # Performance check
    echo ""
    if [[ $(echo "$total_duration < 5.0" | bc) -eq 1 ]]; then
        log_success "Performance target met (${total_duration}s < 5s)"
    else
        log_warning "Performance target missed (${total_duration}s > 5s)"
    fi

    # Show final results using shared utilities
    show_test_summary "Git Hooks Tests"
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
