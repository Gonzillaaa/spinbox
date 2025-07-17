#!/bin/bash
# Component Generator Test Suite for Spinbox
# Tests all component generators and identifies missing implementations
# Following CLAUDE.md principles: Simple, Fast, Essential Coverage

# Note: Not using set -e so tests can continue after failures

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SPINBOX_CMD="$PROJECT_ROOT/bin/spinbox"
TEST_DIR="/tmp/spinbox-component-test-$$"

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
MISSING_GENERATORS=()
EXISTING_GENERATORS=()

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
    fi
}

# Test if generator file exists
test_generator_exists() {
    local component="$1"
    local generator_file="$PROJECT_ROOT/generators/${component}.sh"
    
    if [[ -f "$generator_file" ]]; then
        record_test "${component}_generator_exists" "PASS" "Generator file exists"
        EXISTING_GENERATORS+=("$component")
        
        # Test if generator is executable/readable
        if [[ -r "$generator_file" ]]; then
            record_test "${component}_generator_readable" "PASS" "Generator file is readable"
        else
            record_test "${component}_generator_readable" "FAIL" "Generator file is not readable"
        fi
        
        return 0
    else
        record_test "${component}_generator_exists" "FAIL" "Generator file missing: $generator_file"
        MISSING_GENERATORS+=("$component")
        return 1
    fi
}

# Test component via CLI (dry-run mode)
test_component_cli() {
    local component="$1"
    local cli_flag="--${component}"
    local test_project="test-${component}-$$"
    
    log_info "Testing component: $component via CLI"
    
    # Test component creation with dry-run
    if output=$("$SPINBOX_CMD" create "$test_project" "$cli_flag" --dry-run 2>&1); then
        record_test "${component}_cli_dry_run" "PASS" "CLI accepts $cli_flag flag"
        
        # Check if component appears in output
        if echo "$output" | grep -q "$component"; then
            record_test "${component}_cli_component_listed" "PASS" "Component appears in dry-run output"
        else
            record_test "${component}_cli_component_listed" "FAIL" "Component not found in dry-run output"
        fi
    else
        record_test "${component}_cli_dry_run" "FAIL" "CLI rejects $cli_flag flag or command failed"
    fi
}

# Test component combinations
test_component_combinations() {
    log_info "Testing component combinations"
    
    # Test common combinations
    local combinations=(
        "python fastapi"
        "node nextjs"
        "fastapi postgresql"
        "nextjs mongodb"
        "python postgresql redis"
        "fastapi nextjs postgresql redis"
    )
    
    for combo in "${combinations[@]}"; do
        local flags=""
        for component in $combo; do
            flags="$flags --${component}"
        done
        
        local test_project="test-combo-$(echo "$combo" | tr ' ' '-')-$$"
        
        if output=$("$SPINBOX_CMD" create "$test_project" $flags --dry-run 2>&1); then
            record_test "combo_${combo// /_}" "PASS" "Combination works: $combo"
        else
            record_test "combo_${combo// /_}" "FAIL" "Combination failed: $combo"
        fi
    done
}

# Test minimal generators specifically
test_minimal_generators() {
    log_info "Testing minimal generators"
    
    # These should exist as they're core functionality
    local minimal_generators=("minimal-python" "minimal-node")
    
    for generator in "${minimal_generators[@]}"; do
        test_generator_exists "$generator"
    done
}

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR" 2>/dev/null || true
    rm -rf "$PROJECT_ROOT"/test-* 2>/dev/null || true
}

# Main execution
echo "============================================="
echo "Spinbox Component Generator Test Suite"
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

# Test 1: Check for existing generator files
log_info "=== Testing Generator File Existence ==="

# Core component generators from CLI reference
declare -a DOCUMENTED_COMPONENTS=(
    "fastapi"
    "nextjs" 
    "postgresql"
    "mongodb"
    "redis"
    "chroma"
)

for component in "${DOCUMENTED_COMPONENTS[@]}"; do
    test_generator_exists "$component"
done

# Test minimal generators
test_minimal_generators

echo ""

# Test 2: Test CLI component flags
log_info "=== Testing CLI Component Flags ==="

for component in "${DOCUMENTED_COMPONENTS[@]}"; do
    test_component_cli "$component"
done

# Also test base flags
test_component_cli "python"
test_component_cli "node"

echo ""

# Test 3: Test component combinations
log_info "=== Testing Component Combinations ==="
test_component_combinations

echo ""

# Final Analysis
log_info "=== Component Generator Analysis ==="

echo ""
log_info "Existing generators found:"
for generator in "${EXISTING_GENERATORS[@]}"; do
    echo "  ✓ $generator"
done

echo ""
log_warning "Missing generators identified:"
for generator in "${MISSING_GENERATORS[@]}"; do
    echo "  ✗ $generator"
done

# Summary and recommendations
echo ""
echo "============================================="
echo "Component Generator Test Results"
echo "============================================="
echo ""
echo "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"
echo ""

if [[ ${#MISSING_GENERATORS[@]} -gt 0 ]]; then
    echo -e "${YELLOW}⚠ MISSING GENERATORS DETECTED${NC}"
    echo ""
    echo "The following generators need to be implemented:"
    for generator in "${MISSING_GENERATORS[@]}"; do
        echo "  - $generator.sh"
    done
    echo ""
    echo "These generators are documented in docs/user/cli-reference.md"
    echo "but the actual generator files do not exist in generators/"
    echo ""
fi

if [[ $FAILED_TESTS -eq 0 ]]; then
    if [[ ${#MISSING_GENERATORS[@]} -eq 0 ]]; then
        echo -e "${GREEN}✓ ALL COMPONENT GENERATORS WORKING!${NC}"
        exit_code=0
    else
        echo -e "${YELLOW}✓ EXISTING GENERATORS WORK, BUT SOME ARE MISSING${NC}"
        exit_code=1
    fi
else
    echo -e "${RED}✗ SOME COMPONENT GENERATOR TESTS FAILED${NC}"
    exit_code=1
fi

echo ""
echo "Component generator analysis complete!"
echo ""

exit $exit_code