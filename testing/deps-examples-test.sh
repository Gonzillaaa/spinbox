#!/bin/bash
# Simple Tests for --with-deps and --with-examples flags
# Self-contained test following CLAUDE.md simplicity philosophy

set -e

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Project root
PROJECT_ROOT="$(dirname "$(dirname "$(realpath "$0")")")"

# Simple test function
test_command() {
    local cmd="$1"
    local description="$2"
    ((TESTS_RUN++))
    
    echo -e "${BLUE}Testing: $description${NC}"
    
    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS: $description${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL: $description${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "Testing --with-deps and --with-examples functionality..."
echo ""

# Essential tests only - focus on what users actually need

# Test 1: Help text includes new flags
test_command "$PROJECT_ROOT/bin/spinbox create --help | grep -q 'with-deps'" \
    "Help includes --with-deps flag"

test_command "$PROJECT_ROOT/bin/spinbox create --help | grep -q 'with-examples'" \
    "Help includes --with-examples flag"

# Test 2: Core functions exist
source "$PROJECT_ROOT/lib/dependency-manager.sh"
source "$PROJECT_ROOT/lib/examples-generator.sh"

test_command "type -t add_dependencies_for_components | grep -q function" \
    "Dependency manager functions exist"

test_command "type -t generate_examples_for_components | grep -q function" \
    "Examples generator functions exist"

# Test 3: Basic dry-run functionality (most important)
TEST_DIR="/tmp/spinbox-test-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

test_command "$PROJECT_ROOT/bin/spinbox create test-api --fastapi --with-deps --with-examples --dry-run" \
    "FastAPI project with both flags (dry-run)"

test_command "$PROJECT_ROOT/bin/spinbox create test-basic --fastapi --dry-run" \
    "Basic project creation (backwards compatibility)"

# Test 4: Module integration
test_command "grep -q 'dependency-manager.sh' '$PROJECT_ROOT/lib/project-generator.sh'" \
    "Project generator sources dependency manager"

test_command "grep -q 'examples-generator.sh' '$PROJECT_ROOT/lib/project-generator.sh'" \
    "Project generator sources examples generator"

# Cleanup
cd - >/dev/null 2>&1
rm -rf "$TEST_DIR"

# Test summary
echo ""
echo "================================================="
echo "Test Results:"
echo "================================================="
echo "Tests run:    $TESTS_RUN"
echo -e "${GREEN}Passed:       $TESTS_PASSED${NC}"

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Failed:       $TESTS_FAILED${NC}"
    echo ""
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
else
    echo -e "${GREEN}Failed:       $TESTS_FAILED${NC}"
    echo ""
    echo -e "${GREEN}All tests passed! 🎉${NC}"
    exit 0
fi