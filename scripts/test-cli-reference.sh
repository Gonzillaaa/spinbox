#!/bin/bash
# Test script for CLI Reference Documentation
# Tests ALL functionality described in docs/user/cli-reference.md
# Follows CLAUDE.md testing philosophy: Simple, Fast, Essential

set -e

# Colors for output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SPINBOX_BIN="$PROJECT_ROOT/bin/spinbox"

# Create temporary directory and cleanup function
TEST_TEMP_DIR="/tmp/spinbox-test-$$"
cleanup() {
    rm -rf "$TEST_TEMP_DIR"
}
trap cleanup EXIT

# Create and change to temp directory for tests
mkdir -p "$TEST_TEMP_DIR"
cd "$TEST_TEMP_DIR"

# Generate unique suffix for test project names
TEST_SUFFIX="$$$(date +%s)"

echo "============================================="
echo "Spinbox CLI Reference Documentation Tests"
echo "Testing ALL functionality from docs/user/cli-reference.md"
echo "============================================="
echo "Working in: $TEST_TEMP_DIR"
echo ""

# Test execution function following CLAUDE.md principles
test_command() {
    local test_name="$1"
    local command="$2"
    local expected_exit_code="${3:-0}"
    local description="${4:-}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    echo -n "[$TESTS_RUN] Testing $test_name: "
    
    # Execute command and capture exit code
    local output
    local exit_code
    
    if output=$(eval "$command" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi
    
    # Check if exit code matches expected
    if [ $exit_code -eq $expected_exit_code ]; then
        echo -e "${GREEN}✅ PASS${NC}"
        [ -n "$description" ] && echo "   └─ $description"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌ FAIL${NC} (exit code: $exit_code, expected: $expected_exit_code)"
        [ -n "$description" ] && echo "   └─ $description"
        echo "   └─ Command: $command"
        [ -n "$output" ] && echo "   └─ Output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test command output contains expected string
test_output_contains() {
    local test_name="$1"
    local command="$2"
    local expected_string="$3"
    local description="${4:-}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    echo -n "[$TESTS_RUN] Testing $test_name: "
    
    local output
    if output=$(eval "$command" 2>&1); then
        if echo "$output" | grep -q "$expected_string"; then
            echo -e "${GREEN}✅ PASS${NC}"
            [ -n "$description" ] && echo "   └─ $description"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "${RED}❌ FAIL${NC} (output does not contain: '$expected_string')"
            [ -n "$description" ] && echo "   └─ $description"
            echo "   └─ Command: $command"
            echo "   └─ Output: $output"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        echo -e "${RED}❌ FAIL${NC} (command failed)"
        [ -n "$description" ] && echo "   └─ $description"
        echo "   └─ Command: $command"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

echo -e "${BLUE}=== 1. Basic Command Structure Tests ===${NC}"

# Test version command
test_output_contains "version_command" "$SPINBOX_BIN --version" "Spinbox v" "Version command shows version info"
test_output_contains "version_alt" "$SPINBOX_BIN version" "Spinbox v" "Alternative version syntax works"

# Test help system
test_command "help_command" "$SPINBOX_BIN --help" 0 "Main help command works"
test_command "help_alt" "$SPINBOX_BIN help" 0 "Alternative help syntax works"

# Test global options
test_command "verbose_help" "$SPINBOX_BIN --help --verbose" 0 "Verbose option doesn't break help"
test_command "dry_run_help" "$SPINBOX_BIN --help --dry-run" 0 "Dry-run option doesn't break help"

echo ""
echo -e "${BLUE}=== 2. Create Command Tests ===${NC}"

# Profile-based creation tests (using --dry-run to avoid file operations)
test_command "create_web_app" "$SPINBOX_BIN create test-web-$TEST_SUFFIX --profile web-app --dry-run" 0 "Web-app profile creation"
test_command "create_api_only" "$SPINBOX_BIN create test-api-$TEST_SUFFIX --profile api-only --dry-run" 0 "API-only profile creation"
test_command "create_data_science" "$SPINBOX_BIN create test-data-$TEST_SUFFIX --profile data-science --dry-run" 0 "Data-science profile creation"
test_command "create_ai_llm" "$SPINBOX_BIN create test-ai-$TEST_SUFFIX --profile ai-llm --dry-run" 0 "AI-LLM profile creation"
test_command "create_python" "$SPINBOX_BIN create test-python-$TEST_SUFFIX --profile python --dry-run" 0 "Python profile creation"

# Component-based creation tests
test_command "create_simple_python" "$SPINBOX_BIN create test-simple-$TEST_SUFFIX --python --dry-run" 0 "Simple Python project creation"
test_command "create_fastapi_redis" "$SPINBOX_BIN create test-api2-$TEST_SUFFIX --fastapi --redis --dry-run" 0 "FastAPI + Redis creation"
test_command "create_nextjs_mongo" "$SPINBOX_BIN create test-frontend-$TEST_SUFFIX --nextjs --mongodb --dry-run" 0 "Next.js + MongoDB creation"
test_command "create_full_stack" "$SPINBOX_BIN create test-full-$TEST_SUFFIX --python --node --postgresql --redis --dry-run" 0 "Full stack creation"

# Version customization tests
test_command "create_python_version" "$SPINBOX_BIN create test-legacy-$TEST_SUFFIX --fastapi --python-version 3.10 --dry-run" 0 "Python version override"
test_command "create_node_version" "$SPINBOX_BIN create test-old-node-$TEST_SUFFIX --nextjs --node-version 18 --dry-run" 0 "Node.js version override"
test_command "create_multi_version" "$SPINBOX_BIN create test-custom-$TEST_SUFFIX --profile web-app --python-version 3.11 --node-version 19 --dry-run" 0 "Multiple version overrides"

# Path-based creation tests (create directory first)
mkdir -p code
test_command "create_subdir" "$SPINBOX_BIN create code/test-project-$TEST_SUFFIX --python --dry-run" 0 "Subdirectory creation"
test_command "create_absolute" "$SPINBOX_BIN create /tmp/spinbox-test-abs-$TEST_SUFFIX --python --dry-run" 0 "Absolute path creation"

# Template tests
test_command "create_template" "$SPINBOX_BIN create test-template-$TEST_SUFFIX --python --template data-science --dry-run" 0 "Requirements template selection"

# Create command help
test_command "create_help" "$SPINBOX_BIN create --help" 0 "Create command help works"

echo ""
echo -e "${BLUE}=== 3. Add Command Tests ===${NC}"

# Add command help
test_command "add_help" "$SPINBOX_BIN add --help" 0 "Add command help works"

# Add command error (should fail when not in project directory)
test_command "add_no_project" "$SPINBOX_BIN add --postgresql" 1 "Add fails outside project directory"
test_output_contains "add_error_message" "($SPINBOX_BIN add --postgresql 2>&1 || true)" "Not in a Spinbox project directory" "Correct error message when not in project"

echo ""
echo -e "${BLUE}=== 4. Status Command Tests ===${NC}"

# Status command tests
test_command "status_help" "$SPINBOX_BIN status --help" 0 "Status command help works"
test_command "status_config" "$SPINBOX_BIN status --config" 0 "Status config display works"
test_command "status_components" "$SPINBOX_BIN status --components" 0 "Status components display works"
test_command "status_all" "$SPINBOX_BIN status --all" 0 "Status all display works"
test_command "status_default" "$SPINBOX_BIN status" 0 "Status default (all) works"

echo ""
echo -e "${BLUE}=== 5. Config Command Tests ===${NC}"

# Config command tests
test_command "config_help" "$SPINBOX_BIN config --help" 0 "Config command help works"
test_command "config_list" "$SPINBOX_BIN config --list" 0 "Config list works"
test_command "config_get" "$SPINBOX_BIN config --get PYTHON_VERSION" 0 "Config get works"
test_output_contains "config_get_value" "$SPINBOX_BIN config --get PYTHON_VERSION" "3.9" "Config get returns expected default"

echo ""
echo -e "${BLUE}=== 6. Profiles Command Tests ===${NC}"

# Profiles command tests
test_command "profiles_help" "$SPINBOX_BIN profiles --help" 0 "Profiles command help works"
test_command "profiles_list" "$SPINBOX_BIN profiles --list" 0 "Profiles list works"
test_command "profiles_default" "$SPINBOX_BIN profiles" 0 "Profiles default (list) works"
test_command "profiles_show_web" "$SPINBOX_BIN profiles web-app" 0 "Show web-app profile works"
test_command "profiles_show_api" "$SPINBOX_BIN profiles --show api-only" 0 "Show api-only profile works"

# Verify expected profiles exist
test_output_contains "profiles_web_app" "$SPINBOX_BIN profiles" "web-app" "Web-app profile is listed"
test_output_contains "profiles_api_only" "$SPINBOX_BIN profiles" "api-only" "API-only profile is listed"
test_output_contains "profiles_data_science" "$SPINBOX_BIN profiles" "data-science" "Data-science profile is listed"

echo ""
echo -e "${BLUE}=== 7. Update Command Tests ===${NC}"

# Update command tests
test_command "update_help" "$SPINBOX_BIN update --help" 0 "Update command help works"
test_command "update_check" "$SPINBOX_BIN update --check" 0 "Update check works"
test_command "update_dry_run" "$SPINBOX_BIN update --dry-run" 1 "Update dry-run fails when no installation detected (expected)"

echo ""
echo -e "${BLUE}=== 8. Uninstall Command Tests ===${NC}"

# Uninstall command tests
test_command "uninstall_help" "$SPINBOX_BIN uninstall --help" 0 "Uninstall command help works"
test_command "uninstall_dry_run" "$SPINBOX_BIN uninstall --dry-run" 0 "Uninstall dry-run works"
test_command "uninstall_config_dry_run" "$SPINBOX_BIN uninstall --config --dry-run" 0 "Uninstall with config dry-run works"

echo ""
echo -e "${BLUE}=== 9. Start Command Tests ===${NC}"

# Start command tests (these should fail when not in project directory)
test_command "start_help" "$SPINBOX_BIN start --help" 0 "Start command help works"
test_command "start_no_project" "$SPINBOX_BIN start" 1 "Start fails outside project directory"

echo ""
echo -e "${BLUE}=== 10. Help System Tests ===${NC}"

# Help system tests for all commands
test_command "help_create" "$SPINBOX_BIN help create" 0 "Help for create command works"
test_command "help_add" "$SPINBOX_BIN help add" 0 "Help for add command works"
test_command "help_config" "$SPINBOX_BIN help config" 0 "Help for config command works"
test_command "help_status" "$SPINBOX_BIN help status" 0 "Help for status command works"
test_command "help_profiles" "$SPINBOX_BIN help profiles" 0 "Help for profiles command works"
test_command "help_update" "$SPINBOX_BIN help update" 0 "Help for update command works"
test_command "help_uninstall" "$SPINBOX_BIN help uninstall" 0 "Help for uninstall command works"
test_command "help_start" "$SPINBOX_BIN help start" 0 "Help for start command works"

# Alternative help syntax
test_command "create_help_flag" "$SPINBOX_BIN create --help" 0 "Create --help flag works"
test_command "add_help_flag" "$SPINBOX_BIN add --help" 0 "Add --help flag works"
test_command "config_help_flag" "$SPINBOX_BIN config --help" 0 "Config --help flag works"

echo ""
echo -e "${BLUE}=== 11. Error Conditions and Exit Codes ===${NC}"

# Test invalid commands (actual behavior is exit code 1)
test_command "invalid_command" "$SPINBOX_BIN nonexistent-command" 1 "Invalid command returns error"
test_command "invalid_option" "$SPINBOX_BIN --nonexistent-option" 1 "Invalid option returns error"

# Test invalid create syntax
test_command "create_no_args" "$SPINBOX_BIN create" 1 "Create without project name fails"
test_command "create_invalid_profile" "$SPINBOX_BIN create test --profile nonexistent --dry-run" 1 "Invalid profile fails"

echo ""
echo "============================================="
echo "Test Results Summary"
echo "============================================="
echo -e "Total tests run: ${BLUE}$TESTS_RUN${NC}"
echo -e "Tests passed:    ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed:    ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 All tests passed! CLI reference documentation is accurate.${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed. CLI behavior may not match documentation.${NC}"
    exit 1
fi