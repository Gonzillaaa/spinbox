#!/bin/bash
# Simple Profile Test Script for Spinbox
# Tests all profiles for parsing errors and component generation
# Following CLAUDE.md principles: Simple, Fast, Essential Coverage

# Note: Not using set -e so tests can continue after failures

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SPINBOX_CMD="$PROJECT_ROOT/bin/spinbox"

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
FAILED_PROFILES=()

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
        FAILED_PROFILES+=("$test_name")
    fi
}

# Test a single profile
test_profile() {
    local profile_name="$1"
    local expected_components="$2"
    local expected_template="$3"
    
    log_info "Testing profile: $profile_name"
    
    # Test 1: Profile parsing (show profile info)
    if output=$("$SPINBOX_CMD" profiles --show "$profile_name" 2>&1); then
        record_test "${profile_name}_parsing" "PASS" "Profile parsed successfully"
        
        # Verify template is shown correctly
        if [[ "$expected_template" != "none" ]]; then
            if echo "$output" | grep -q "Python Requirements: $expected_template"; then
                record_test "${profile_name}_template" "PASS" "Template '$expected_template' found"
            else
                record_test "${profile_name}_template" "FAIL" "Template '$expected_template' not found"
                echo "Debug: Actual output:"
                echo "$output" | grep -A5 -B5 "Templates:"
            fi
        fi
    else
        record_test "${profile_name}_parsing" "FAIL" "Profile parsing failed"
        return 1
    fi
    
    # Test 2: Project creation with profile (dry run)
    if output=$("$SPINBOX_CMD" create "test-$profile_name" --profile "$profile_name" --dry-run 2>&1); then
        record_test "${profile_name}_creation" "PASS" "Project creation succeeded"
        
        # Test 3: Verify expected components are present
        if [[ "$expected_components" != "none" ]]; then
            # Extract the components line specifically
            local components_line=$(echo "$output" | grep "Components:" | head -1)
            local components_found=true
            
            IFS=' ' read -ra COMPONENTS <<< "$expected_components"
            for component in "${COMPONENTS[@]}"; do
                if ! echo "$components_line" | grep -q "$component"; then
                    components_found=false
                    break
                fi
            done
            
            if [[ "$components_found" == "true" ]]; then
                record_test "${profile_name}_components" "PASS" "Expected components found: $expected_components"
            else
                record_test "${profile_name}_components" "FAIL" "Missing expected components: $expected_components"
                echo "Debug: Actual components line: $components_line"
                echo "Debug: Expected: $expected_components"
            fi
        fi
    else
        record_test "${profile_name}_creation" "FAIL" "Project creation failed"
    fi
    
    echo ""
}

# Cleanup function
cleanup() {
    # Remove any test directories that might have been created
    rm -rf "$PROJECT_ROOT"/test-* 2>/dev/null || true
}

# Main execution
echo "============================================="
echo "Spinbox Profile Test Suite"
echo "============================================="
echo ""

# Verify spinbox command exists
if [[ ! -f "$SPINBOX_CMD" ]]; then
    log_error "Spinbox command not found at: $SPINBOX_CMD"
    exit 1
fi

# Set up cleanup
trap cleanup EXIT

# Change to project root
cd "$PROJECT_ROOT"

# Test each profile
# Format: profile_name "expected_components" "expected_template"
test_profile "web-app" "python fastapi nextjs postgresql" "api-development"
test_profile "api-only" "python fastapi postgresql redis" "api-development"
test_profile "ai-llm" "python chroma" "ai-llm"
test_profile "python" "python" "minimal"
test_profile "node" "none" "none"  # Node profile doesn't use Python requirements
test_profile "data-science" "python" "data-science"

# Final report
echo "============================================="
echo "Profile Test Results"
echo "============================================="
echo ""
echo "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"
echo ""

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}✓ ALL PROFILE TESTS PASSED!${NC}"
    echo ""
    log_success "All profiles are working correctly"
    exit_code=0
else
    echo -e "${RED}✗ SOME PROFILE TESTS FAILED${NC}"
    echo ""
    echo "Failed profiles:"
    for profile in "${FAILED_PROFILES[@]}"; do
        echo "  - $profile"
    done
    exit_code=1
fi

echo ""
echo "Profile test complete!"
echo ""

exit $exit_code