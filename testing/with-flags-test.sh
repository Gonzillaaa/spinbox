#!/bin/bash
# Simple Tests for --with-deps and --with-examples flags
# Standalone test following simple test framework pattern

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

echo "Testing --with-deps and --with-examples flags..."
echo ""

# Test 1: Help text includes new flags
test_command "$PROJECT_ROOT/bin/spinbox create --help | grep -q 'with-deps'" \
    "Help includes --with-deps flag"

test_command "$PROJECT_ROOT/bin/spinbox create --help | grep -q 'with-examples'" \
    "Help includes --with-examples flag"

# Test 2: Functions exist
source "$PROJECT_ROOT/lib/dependency-manager.sh"
source "$PROJECT_ROOT/lib/examples-generator.sh"

test_command "type -t add_component_dependencies | grep -q function" \
    "Dependency manager functions exist"

test_command "type -t generate_component_examples | grep -q function" \
    "Examples generator functions exist"

# Test 3: Backwards compatibility (projects without new flags work)
# Create temp directory for testing
TEST_DIR="/tmp/spinbox-test-$$"
mkdir -p "$TEST_DIR"
OLD_DIR="$(pwd)"
cd "$TEST_DIR"

test_command "$PROJECT_ROOT/bin/spinbox create test-basic --fastapi --dry-run" \
    "Basic project creation works"

test_command "$PROJECT_ROOT/bin/spinbox create test-python --python --dry-run" \
    "Python project creation works"

# Test 4: New flags are parsed (--with-deps only)
test_command "$PROJECT_ROOT/bin/spinbox create test-deps --fastapi --with-deps --dry-run" \
    "Project with --with-deps only works"

# Cleanup
cd "$OLD_DIR"
rm -rf "$TEST_DIR"

# Test 5: Module integration 
test_command "grep -q 'dependency-manager.sh' '$PROJECT_ROOT/lib/project-generator.sh'" \
    "Project generator sources dependency manager"

test_command "grep -q 'examples-generator.sh' '$PROJECT_ROOT/lib/project-generator.sh'" \
    "Project generator sources examples generator"

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