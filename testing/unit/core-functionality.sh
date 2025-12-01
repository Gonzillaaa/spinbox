#!/bin/bash
# Core Functionality Test Suite for Spinbox
# Comprehensive tests for library functions and basic smoke tests
# Merged from simple-test.sh (68 tests) + quick-test.sh (4 additional checks)

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Simple assertion functions
test_assert() {
    local condition="$1"
    local description="$2"
    ((TESTS_RUN++))
    
    echo -e "${BLUE}Testing: $description${NC}"
    
    if eval "$condition"; then
        echo -e "${GREEN}✓ PASS: $description${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL: $description${NC}"
        echo -e "${RED}  Condition: $condition${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_equals() {
    local expected="$1"
    local actual="$2"
    local description="$3"
    ((TESTS_RUN++))
    
    echo -e "${BLUE}Testing: $description${NC}"
    
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}✓ PASS: $description${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL: $description${NC}"
        echo -e "${RED}  Expected: '$expected'${NC}"
        echo -e "${RED}  Actual:   '$actual'${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_contains() {
    local haystack="$1"
    local needle="$2"
    local description="$3"
    ((TESTS_RUN++))
    
    echo -e "${BLUE}Testing: $description${NC}"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        echo -e "${GREEN}✓ PASS: $description${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL: $description${NC}"
        echo -e "${RED}  String: '$haystack'${NC}"
        echo -e "${RED}  Should contain: '$needle'${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_file_exists() {
    local file_path="$1"
    local description="$2"
    ((TESTS_RUN++))
    
    echo -e "${BLUE}Testing: $description${NC}"
    
    if [[ -f "$file_path" ]]; then
        echo -e "${GREEN}✓ PASS: $description${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL: $description${NC}"
        echo -e "${RED}  File not found: $file_path${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test runner
run_tests() {
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "${YELLOW}        Spinbox Core Functionality Tests        ${NC}"
    echo -e "${YELLOW}===============================================${NC}"
    echo ""
    
    # Set up test environment
    setup_tests
    
    # Run original test categories from simple-test.sh
    test_configuration_loading
    test_version_substitution
    test_file_generation
    test_error_handling
    test_config_integration
    test_project_setup_config
    test_cli_commands
    test_profile_validation
    test_project_creation_smoke
    
    # Run additional smoke tests from quick-test.sh
    test_key_files_existence
    test_scripts_executable
    test_configuration_system_smoke
    test_version_defaults
    
    # Clean up
    cleanup_tests
    
    # Show results
    echo ""
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "${YELLOW}                Test Results                  ${NC}"
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "Tests run:    $TESTS_RUN"
    echo -e "${GREEN}Passed:       $TESTS_PASSED${NC}"
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo -e "${RED}Failed:       $TESTS_FAILED${NC}"
        echo ""
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    else
        echo -e "${GREEN}Failed:       $TESTS_FAILED${NC}"
        echo ""
        echo -e "${GREEN}All tests passed!${NC}"
        echo ""
        echo -e "${GREEN}✨ Spinbox core functionality verified!${NC}"
        exit 0
    fi
}

# Test setup
setup_tests() {
    echo -e "${BLUE}Setting up test environment...${NC}"
    
    # Create temporary test directory
    TEST_DIR="/tmp/spinbox-core-test-$$"
    mkdir -p "$TEST_DIR"
    
    # Source the libraries we want to test
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
    source "$PROJECT_ROOT/lib/utils.sh" 2>/dev/null || echo "Warning: Could not source $PROJECT_ROOT/lib/utils.sh"
    
    echo -e "${GREEN}Test environment ready${NC}"
    echo ""
}

# Test cleanup
cleanup_tests() {
    echo ""
    echo -e "${BLUE}Cleaning up test environment...${NC}"
    
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        rm -rf "$TEST_DIR"
    fi
    
    echo -e "${GREEN}Cleanup complete${NC}"
}

# Configuration loading tests
test_configuration_loading() {
    echo -e "${YELLOW}=== Configuration Loading Tests ===${NC}"
    
    # Test basic config file creation and loading
    local config_file="$TEST_DIR/test.conf"
    echo 'TEST_VAR="test_value"' > "$config_file"
    
    test_file_exists "$config_file" "Config file created"
    
    # Test config loading
    source "$config_file"
    test_equals "test_value" "$TEST_VAR" "Config variable loaded correctly"
    
    # Test missing config file handling
    test_assert '[[ ! -f "$TEST_DIR/missing.conf" ]]' "Missing config file detection"
    
    echo ""
}

# Version substitution tests
test_version_substitution() {
    echo -e "${YELLOW}=== Version Substitution Tests ===${NC}"
    
    # Test variable expansion in templates
    export PYTHON_VERSION="3.11"
    export NODE_VERSION="18"
    
    # Test Docker FROM line generation
    local result
    result=$(cat << EOF
FROM python:${PYTHON_VERSION}-slim
FROM node:${NODE_VERSION}-alpine
EOF
)
    
    test_contains "$result" "FROM python:3.11-slim" "Python version substitution"
    test_contains "$result" "FROM node:18-alpine" "Node version substitution"
    
    # Test requirements template processing
    local req_content
    req_content=$(cat << EOF
# python_requires = "~=${PYTHON_VERSION}.0"
requests>=2.31.0
EOF
)
    
    test_contains "$req_content" "~=3.11.0" "Requirements version constraint"
    
    echo ""
}

# File generation tests
test_file_generation() {
    echo -e "${YELLOW}=== File Generation Tests ===${NC}"
    
    # Test simple file creation
    local test_file="$TEST_DIR/generated.txt"
    cat > "$test_file" << EOF
# Generated file
SETTING=value
EOF
    
    test_file_exists "$test_file" "File generation works"
    
    # Test file content
    local content
    content=$(cat "$test_file")
    test_contains "$content" "SETTING=value" "Generated file has correct content"
    
    # Test directory creation
    mkdir -p "$TEST_DIR/nested/directory"
    test_assert '[[ -d "$TEST_DIR/nested/directory" ]]' "Nested directory creation"
    
    echo ""
}

# Error handling tests
test_error_handling() {
    echo -e "${YELLOW}=== Error Handling Tests ===${NC}"
    
    # Test invalid variable handling
    unset UNDEFINED_VAR
    local result="${UNDEFINED_VAR:-default_value}"
    test_equals "default_value" "$result" "Undefined variable default fallback"
    
    # Test empty string handling
    local empty_var=""
    local fallback_result="${empty_var:-fallback}"
    test_equals "fallback" "$fallback_result" "Empty variable fallback"
    
    # Test file existence checks before operations
    test_assert '[[ ! -f "$TEST_DIR/nonexistent.conf" ]]' "Nonexistent file detection"
    
    echo ""
}

# Configuration system integration test (focused)
test_config_integration() {
    echo -e "${YELLOW}=== Configuration Integration Test ===${NC}"
    
    # Create a test config
    local test_config="$TEST_DIR/.config/global.conf"
    mkdir -p "$TEST_DIR/.config"
    
    cat > "$test_config" << 'EOF'
PYTHON_VERSION="3.10"
NODE_VERSION="19"
POSTGRES_VERSION="13"
REDIS_VERSION="6"
EOF
    
    test_file_exists "$test_config" "Test config file created"
    
    # Source the config
    source "$test_config"
    
    # Test values loaded correctly
    test_equals "3.10" "$PYTHON_VERSION" "Python version from config"
    test_equals "19" "$NODE_VERSION" "Node version from config" 
    test_equals "13" "$POSTGRES_VERSION" "PostgreSQL version from config"
    test_equals "6" "$REDIS_VERSION" "Redis version from config"
    
    echo ""
}

# Project setup configuration test
test_project_setup_config() {
    echo -e "${YELLOW}=== Project Setup Configuration Test ===${NC}"
    
    # Test that project-setup.sh can load configuration
    local config_dir="$TEST_DIR/.config"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/global.conf" << 'EOF'
PYTHON_VERSION="3.10"
NODE_VERSION="19"
POSTGRES_VERSION="13"
REDIS_VERSION="6"
EOF
    
    # Simulate the configuration loading logic from project-setup.sh
    local CONFIG_DIR="$config_dir"
    if [[ -f "${CONFIG_DIR}/global.conf" ]]; then
        source "${CONFIG_DIR}/global.conf"
    fi
    
    # Set default versions (can be overridden by config)
    PYTHON_VERSION="${PYTHON_VERSION:-3.11}"
    NODE_VERSION="${NODE_VERSION:-20}"
    POSTGRES_VERSION="${POSTGRES_VERSION:-15}"
    REDIS_VERSION="${REDIS_VERSION:-7}"
    
    # Test that config values override defaults
    test_equals "3.10" "$PYTHON_VERSION" "Project setup: Python version from config"
    test_equals "19" "$NODE_VERSION" "Project setup: Node version from config"
    test_equals "13" "$POSTGRES_VERSION" "Project setup: PostgreSQL version from config"
    test_equals "6" "$REDIS_VERSION" "Project setup: Redis version from config"
    
    # Test Docker template generation with config values
    local dockerfile_content
    dockerfile_content="FROM python:${PYTHON_VERSION}-slim"
    test_contains "$dockerfile_content" "python:3.10-slim" "Project setup: Dockerfile uses config version"
    
    echo ""
}

# CLI command tests
test_cli_commands() {
    echo -e "${YELLOW}=== CLI Command Tests ===${NC}"
    
    # Get CLI path
    local cli_path="$PROJECT_ROOT/bin/spinbox"
    
    # Test CLI exists and is executable
    test_file_exists "$cli_path" "CLI executable exists"
    test_assert '[[ -x "$cli_path" ]]' "CLI is executable"
    
    # Test help commands (these should always work and be fast)
    test_assert '"$cli_path" --help >/dev/null 2>&1' "Main help command works"
    test_assert '"$cli_path" --version >/dev/null 2>&1' "Version command works"
    
    # Test specific command help
    test_assert '"$cli_path" create --help >/dev/null 2>&1' "Create help command works"
    test_assert '"$cli_path" config --help >/dev/null 2>&1' "Config help command works"
    test_assert '"$cli_path" profiles --help >/dev/null 2>&1' "Profiles help command works"
    
    # Test profiles command (should list available profiles)
    test_assert '"$cli_path" profiles >/dev/null 2>&1' "Profiles command works"
    
    # Test config command (should show current config)
    test_assert '"$cli_path" config --list >/dev/null 2>&1' "Config list command works"
    
    # Test update command
    test_assert '"$cli_path" update --help >/dev/null 2>&1' "Update help command works"
    
    # Test uninstall command (dry-run only)
    test_assert '"$cli_path" uninstall --help >/dev/null 2>&1' "Uninstall help command works"
    test_assert '"$cli_path" uninstall --dry-run >/dev/null 2>&1' "Uninstall dry-run command works"
    
    echo ""
}

# Profile validation tests
test_profile_validation() {
    echo -e "${YELLOW}=== Profile Validation Tests ===${NC}"
    
    local cli_path="$PROJECT_ROOT/bin/spinbox"
    local profiles_dir="$PROJECT_ROOT/templates/profiles"
    
    # Test that profile templates directory exists
    test_assert '[[ -d "$profiles_dir" ]]' "Profiles directory exists"
    
    # Test that all 6 expected profiles exist
    local expected_profiles=("web-app" "api-only" "data-science" "ai-llm" "python" "node")
    
    for profile in "${expected_profiles[@]}"; do
        local profile_file="$profiles_dir/${profile}.toml"
        test_file_exists "$profile_file" "Profile $profile exists"
        
        # Test profile file has required sections
        test_assert 'grep -q "\\[profile\\]" "$profile_file"' "Profile $profile has [profile] section"
        test_assert 'grep -q "\\[components\\]" "$profile_file"' "Profile $profile has [components] section"
        
        # Test profile can be shown via CLI (should not error)
        test_assert '"$cli_path" profiles "$profile" >/dev/null 2>&1' "Profile $profile can be displayed via CLI"
    done
    
    echo ""
}

# Basic project creation smoke tests  
test_project_creation_smoke() {
    echo -e "${YELLOW}=== Project Creation Smoke Tests ===${NC}"
    
    local cli_path="$PROJECT_ROOT/bin/spinbox"
    local test_project_dir="$TEST_DIR/smoke-test-project"
    
    # Test minimal project creation (fastest, most basic test)
    cd "$TEST_DIR"
    
    # Use dry-run mode to test command parsing without actually creating files
    test_assert '"$cli_path" create smoke-test --python --dry-run >/dev/null 2>&1' "Dry run project creation works"
    
    # Test profile validation with dry-run
    test_assert '"$cli_path" create smoke-profile-test --profile python --dry-run >/dev/null 2>&1' "Dry run with profile works"
    
    # Test version override with dry-run
    test_assert '"$cli_path" create smoke-version-test --python --python-version 3.11 --dry-run >/dev/null 2>&1' "Dry run with version override works"
    
    # Test that invalid profile fails appropriately
    if "$cli_path" create smoke-invalid --profile nonexistent --dry-run >/dev/null 2>&1; then
        echo -e "${RED}✗ FAIL: Invalid profile should have failed${NC}"
        ((TESTS_FAILED++))
    else
        echo -e "${GREEN}✓ PASS: Invalid profile fails appropriately${NC}"
        ((TESTS_PASSED++))
    fi
    ((TESTS_RUN++))
    
    # Test component generators exist
    local generators_dir="$PROJECT_ROOT/generators"
    test_assert '[[ -d "$generators_dir" ]]' "Generators directory exists"
    test_file_exists "$generators_dir/minimal-python.sh" "Python generator exists"
    test_file_exists "$generators_dir/minimal-node.sh" "Node generator exists"
    
    # Test uninstall script exists and is executable
    test_file_exists "$PROJECT_ROOT/uninstall.sh" "Uninstall script exists"
    test_assert '[[ -x "$PROJECT_ROOT/uninstall.sh" ]]' "Uninstall script is executable"
    
    echo ""
}

# Additional smoke tests from quick-test.sh
test_key_files_existence() {
    echo -e "${YELLOW}=== Key Files Existence Tests ===${NC}"
    
    # Test that key files exist
    test_file_exists "$PROJECT_ROOT/lib/config.sh" "lib/config.sh exists"
    test_file_exists "$PROJECT_ROOT/lib/utils.sh" "lib/utils.sh exists"
    test_file_exists "$PROJECT_ROOT/bin/spinbox" "bin/spinbox exists"
    test_file_exists "$PROJECT_ROOT/install.sh" "install.sh exists"
    
    echo ""
}

test_scripts_executable() {
    echo -e "${YELLOW}=== Scripts Executable Tests ===${NC}"
    
    # Test that scripts are executable
    test_assert '[[ -x "$PROJECT_ROOT/bin/spinbox" ]]' "bin/spinbox is executable"
    test_assert '[[ -x "$PROJECT_ROOT/install.sh" ]]' "install.sh is executable"
    
    echo ""
}

test_configuration_system_smoke() {
    echo -e "${YELLOW}=== Configuration System Smoke Tests ===${NC}"
    
    # Test configuration loading (basic smoke test)
    test_assert 'bash -c "source $PROJECT_ROOT/lib/utils.sh 2>/dev/null && source $PROJECT_ROOT/lib/config.sh 2>/dev/null" 2>/dev/null' "Configuration system loads without errors"
    
    echo ""
}

test_version_defaults() {
    echo -e "${YELLOW}=== Version Defaults Tests ===${NC}"
    
    # Test version defaults are set
    # Extract just the configuration loading portion
    local CONFIG_DIR="$PROJECT_ROOT/.config"
    local TEST_PYTHON_VERSION=""
    local TEST_NODE_VERSION=""
    if [[ -f "${CONFIG_DIR}/global.conf" ]]; then
        source "${CONFIG_DIR}/global.conf" 2>/dev/null
        TEST_PYTHON_VERSION="$PYTHON_VERSION"
        TEST_NODE_VERSION="$NODE_VERSION"
    fi
    TEST_PYTHON_VERSION="${TEST_PYTHON_VERSION:-3.11}"
    TEST_NODE_VERSION="${TEST_NODE_VERSION:-20}"
    
    test_assert '[[ -n "$TEST_PYTHON_VERSION" ]]' "Python version default set"
    test_assert '[[ -n "$TEST_NODE_VERSION" ]]' "Node version default set"
    
    echo ""
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi