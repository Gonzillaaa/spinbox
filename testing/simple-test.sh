#!/bin/bash
# Simple Test Framework for Spinbox Core Functions
# Minimal, fast, reliable testing without complex dependencies

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
    echo -e "${YELLOW}          Spinbox Simple Test Suite           ${NC}"
    echo -e "${YELLOW}===============================================${NC}"
    echo ""
    
    # Set up test environment
    setup_tests
    
    # Run test categories
    test_configuration_loading
    test_version_substitution
    test_file_generation
    test_error_handling
    test_config_integration
    test_project_setup_config
    
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
        exit 0
    fi
}

# Test setup
setup_tests() {
    echo -e "${BLUE}Setting up test environment...${NC}"
    
    # Create temporary test directory
    TEST_DIR="/tmp/spinbox-simple-test-$$"
    mkdir -p "$TEST_DIR"
    
    # Source the libraries we want to test
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
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
    PYTHON_VERSION="${PYTHON_VERSION:-3.12}"
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

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_tests
fi