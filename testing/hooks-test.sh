#!/bin/bash
# Test script for git hooks functionality
# Tests hook installation, removal, and project type detection

set -e

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_DIR="$PROJECT_ROOT/test_hooks_temp"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test result tracking
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

function print_test_header() {
    echo -e "${YELLOW}Testing: $1${NC}"
}

function print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    ((TESTS_PASSED++))
}

function print_failure() {
    echo -e "${RED}✗ $1${NC}"
    ((TESTS_FAILED++))
}

function print_info() {
    echo "  $1"
}

# Setup test environment
function setup_test_env() {
    print_test_header "Setting up test environment"
    
    # Clean up any existing test directory
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
    
    # Create test directory
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    # Initialize git repository
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    print_success "Test environment setup complete"
}

# Cleanup test environment
function cleanup_test_env() {
    print_test_header "Cleaning up test environment"
    
    cd "$PROJECT_ROOT"
    if [[ -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
    
    print_success "Test environment cleanup complete"
}

# Test project type detection
function test_project_type_detection() {
    print_test_header "Testing project type detection"
    ((TOTAL_TESTS++))
    
    cd "$TEST_DIR"
    
    # Test Python project detection
    echo "test" > requirements.txt
    source "$PROJECT_ROOT/lib/git-hooks.sh"
    project_type=$(detect_project_type)
    
    if [[ "$project_type" == "python" ]]; then
        print_success "Python project detection"
    else
        print_failure "Python project detection (got: $project_type)"
    fi
    
    # Test Node.js project detection
    rm requirements.txt
    echo '{"name": "test", "version": "1.0.0"}' > package.json
    project_type=$(detect_project_type)
    
    if [[ "$project_type" == "nodejs" ]]; then
        print_success "Node.js project detection"
    else
        print_failure "Node.js project detection (got: $project_type)"
    fi
    
    # Test full-stack project detection
    echo "test" > requirements.txt
    project_type=$(detect_project_type)
    
    if [[ "$project_type" == "fullstack" ]]; then
        print_success "Full-stack project detection"
    else
        print_failure "Full-stack project detection (got: $project_type)"
    fi
    
    # Test unknown project detection
    rm requirements.txt package.json
    project_type=$(detect_project_type)
    
    if [[ "$project_type" == "unknown" ]]; then
        print_success "Unknown project detection"
    else
        print_failure "Unknown project detection (got: $project_type)"
    fi
}

# Test hook installation
function test_hook_installation() {
    print_test_header "Testing hook installation"
    ((TOTAL_TESTS++))
    
    cd "$TEST_DIR"
    
    # Create a Python project
    echo "pytest>=7.0.0" > requirements.txt
    echo "black>=23.0.0" >> requirements.txt
    
    # Test installing pre-commit hook
    export DRY_RUN=true
    source "$PROJECT_ROOT/lib/git-hooks.sh"
    
    if manage_hooks "add" "pre-commit" "false"; then
        print_success "Pre-commit hook installation (dry run)"
    else
        print_failure "Pre-commit hook installation (dry run)"
    fi
    
    # Test installing all hooks
    if manage_hooks "add" "all" "false"; then
        print_success "All hooks installation (dry run)"
    else
        print_failure "All hooks installation (dry run)"
    fi
    
    # Test with examples
    if manage_hooks "add" "pre-commit" "true"; then
        print_success "Hook installation with examples (dry run)"
    else
        print_failure "Hook installation with examples (dry run)"
    fi
}

# Test hook listing
function test_hook_listing() {
    print_test_header "Testing hook listing"
    ((TOTAL_TESTS++))
    
    cd "$TEST_DIR"
    
    # Test listing hooks
    source "$PROJECT_ROOT/lib/git-hooks.sh"
    
    if manage_hooks "list" "" "false"; then
        print_success "Hook listing"
    else
        print_failure "Hook listing"
    fi
}

# Test hook removal
function test_hook_removal() {
    print_test_header "Testing hook removal"
    ((TOTAL_TESTS++))
    
    cd "$TEST_DIR"
    
    # Test removing hooks
    export DRY_RUN=true
    source "$PROJECT_ROOT/lib/git-hooks.sh"
    
    if manage_hooks "remove" "pre-commit" "false"; then
        print_success "Hook removal (dry run)"
    else
        print_failure "Hook removal (dry run)"
    fi
    
    if manage_hooks "remove" "all" "false"; then
        print_success "All hooks removal (dry run)"
    else
        print_failure "All hooks removal (dry run)"
    fi
}

# Test CLI integration
function test_cli_integration() {
    print_test_header "Testing CLI integration"
    ((TOTAL_TESTS++))
    
    cd "$TEST_DIR"
    
    # Create a Python project
    echo "pytest>=7.0.0" > requirements.txt
    echo "black>=23.0.0" >> requirements.txt
    
    # Test CLI command
    export DRY_RUN=true
    
    if "$PROJECT_ROOT/bin/spinbox" hooks add pre-commit --dry-run; then
        print_success "CLI hooks command"
    else
        print_failure "CLI hooks command"
    fi
    
    # Test CLI help
    if "$PROJECT_ROOT/bin/spinbox" hooks --help > /dev/null 2>&1; then
        print_success "CLI hooks help"
    else
        print_failure "CLI hooks help"
    fi
}

# Test error handling
function test_error_handling() {
    print_test_header "Testing error handling"
    ((TOTAL_TESTS++))
    
    cd "$TEST_DIR"
    
    # Test non-git repository
    rm -rf .git
    source "$PROJECT_ROOT/lib/git-hooks.sh"
    
    if ! manage_hooks "add" "pre-commit" "false" 2>/dev/null; then
        print_success "Non-git repository error handling"
    else
        print_failure "Non-git repository error handling"
    fi
    
    # Re-initialize git for other tests
    git init -q
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Test unknown hook type
    if ! manage_hooks "add" "invalid-hook" "false" 2>/dev/null; then
        print_success "Unknown hook type error handling"
    else
        print_failure "Unknown hook type error handling"
    fi
}

# Test hook template availability
function test_hook_templates() {
    print_test_header "Testing hook template availability"
    ((TOTAL_TESTS++))
    
    local templates_dir="$PROJECT_ROOT/templates/hooks"
    local project_types=("python" "nodejs" "fastapi" "nextjs" "fullstack" "generic")
    local hook_types=("pre-commit" "pre-push")
    
    local templates_found=0
    local expected_templates=12  # 6 project types * 2 hook types
    
    for project_type in "${project_types[@]}"; do
        for hook_type in "${hook_types[@]}"; do
            local template_file="$templates_dir/$project_type/$hook_type"
            if [[ -f "$template_file" && -x "$template_file" ]]; then
                ((templates_found++))
            fi
        done
    done
    
    if [[ $templates_found -eq $expected_templates ]]; then
        print_success "All hook templates found ($templates_found/$expected_templates)"
    else
        print_failure "Missing hook templates ($templates_found/$expected_templates)"
    fi
}

# Test performance
function test_performance() {
    print_test_header "Testing performance"
    ((TOTAL_TESTS++))
    
    cd "$TEST_DIR"
    
    # Create a Python project
    echo "pytest>=7.0.0" > requirements.txt
    echo "black>=23.0.0" >> requirements.txt
    
    # Test that hook operations complete within reasonable time
    export DRY_RUN=true
    source "$PROJECT_ROOT/lib/git-hooks.sh"
    
    local start_time=$(date +%s)
    manage_hooks "add" "all" "true"
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ $duration -lt 5 ]]; then
        print_success "Hook operations complete in under 5 seconds ($duration seconds)"
    else
        print_failure "Hook operations took too long ($duration seconds)"
    fi
}

# Main test execution
function run_tests() {
    echo "Starting git hooks functionality tests..."
    echo "========================================"
    
    setup_test_env
    
    test_project_type_detection
    test_hook_installation
    test_hook_listing
    test_hook_removal
    test_cli_integration
    test_error_handling
    test_hook_templates
    test_performance
    
    cleanup_test_env
    
    echo "========================================"
    echo "Test Results:"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    echo "  Total:  $TOTAL_TESTS"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run tests
run_tests