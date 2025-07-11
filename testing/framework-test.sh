#!/bin/bash
# Framework Generators Test Suite
# Tests for new data-science and ai-ml framework generators

# Don't use set -e here as it interferes with test functions
# set -e

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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
        echo -e "${RED}  Should contain: '$needle'${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo -e "${YELLOW}===============================================${NC}"
echo -e "${YELLOW}     Framework Generators Test Suite         ${NC}"
echo -e "${YELLOW}===============================================${NC}"
echo ""

# Test 1: Framework generator files exist
echo -e "${YELLOW}=== Generator Files Tests ===${NC}"

test_file_exists "$PROJECT_ROOT/generators/data-science.sh" "Data Science generator exists"
test_file_exists "$PROJECT_ROOT/generators/ai-ml.sh" "AI/ML generator exists"

# Test 2: Framework generators are executable
test_command "test -x '$PROJECT_ROOT/generators/data-science.sh'" \
    "Data Science generator is executable"

test_command "test -x '$PROJECT_ROOT/generators/ai-ml.sh'" \
    "AI/ML generator is executable"

# Test 3: Framework generators have required functions
echo ""
echo -e "${YELLOW}=== Generator Functions Tests ===${NC}"

test_command "grep -q 'generate_data_science_component' '$PROJECT_ROOT/generators/data-science.sh'" \
    "Data Science generator has main function"

test_command "grep -q 'generate_ai_ml_component' '$PROJECT_ROOT/generators/ai-ml.sh'" \
    "AI/ML generator has main function"

# Test 4: CLI parsing supports new flags
echo ""
echo -e "${YELLOW}=== CLI Integration Tests ===${NC}"

test_command "$PROJECT_ROOT/bin/spinbox create --help | grep -q 'data-science'" \
    "CLI help includes --data-science flag"

test_command "$PROJECT_ROOT/bin/spinbox create --help | grep -q 'ai-ml'" \
    "CLI help includes --ai-ml flag"

# Test 5: Project generator integration
echo ""
echo -e "${YELLOW}=== Project Generator Integration Tests ===${NC}"

test_command "grep -q 'USE_DATA_SCIENCE' '$PROJECT_ROOT/lib/project-generator.sh'" \
    "Project generator defines USE_DATA_SCIENCE flag"

test_command "grep -q 'USE_AI_ML' '$PROJECT_ROOT/lib/project-generator.sh'" \
    "Project generator defines USE_AI_ML flag"

test_command "grep -q 'data-science.sh' '$PROJECT_ROOT/lib/project-generator.sh'" \
    "Project generator sources data-science generator"

test_command "grep -q 'ai-ml.sh' '$PROJECT_ROOT/lib/project-generator.sh'" \
    "Project generator sources ai-ml generator"

# Test 6: Examples generator integration
echo ""
echo -e "${YELLOW}=== Examples Generator Integration Tests ===${NC}"

test_command "grep -q 'generate_data_science_example' '$PROJECT_ROOT/lib/examples-generator.sh'" \
    "Examples generator has data-science function"

test_command "grep -q 'generate_ai_ml_example' '$PROJECT_ROOT/lib/examples-generator.sh'" \
    "Examples generator has ai-ml function"

test_command "grep -q '\"data-science\"' '$PROJECT_ROOT/lib/examples-generator.sh'" \
    "Examples generator handles data-science case"

test_command "grep -q '\"ai-ml\"' '$PROJECT_ROOT/lib/examples-generator.sh'" \
    "Examples generator handles ai-ml case"

# Test 7: Profile integration
echo ""
echo -e "${YELLOW}=== Profile Integration Tests ===${NC}"

test_file_exists "$PROJECT_ROOT/templates/profiles/data-science.toml" "Data Science profile exists"
test_file_exists "$PROJECT_ROOT/templates/profiles/ai-llm.toml" "AI/LLM profile exists"

test_command "grep -q 'data_science.*true' '$PROJECT_ROOT/templates/profiles/data-science.toml'" \
    "Data Science profile uses data_science component"

test_command "grep -q 'ai_ml.*true' '$PROJECT_ROOT/templates/profiles/ai-llm.toml'" \
    "AI/LLM profile uses ai_ml component"

# Test 8: Dry-run project creation
echo ""
echo -e "${YELLOW}=== Dry-run Project Creation Tests ===${NC}"

# Create temp directory for testing
TEST_DIR="/tmp/spinbox-framework-test-$$"
mkdir -p "$TEST_DIR"
OLD_DIR="$(pwd)"
cd "$TEST_DIR"

test_command "$PROJECT_ROOT/bin/spinbox create test-ds --data-science --dry-run" \
    "Data Science project creation (dry-run)"

test_command "$PROJECT_ROOT/bin/spinbox create test-ai --ai-ml --dry-run" \
    "AI/ML project creation (dry-run)"

test_command "$PROJECT_ROOT/bin/spinbox create test-ds-ex --data-science --with-examples --dry-run" \
    "Data Science with examples (dry-run)"

test_command "$PROJECT_ROOT/bin/spinbox create test-ai-ex --ai-ml --with-examples --dry-run" \
    "AI/ML with examples (dry-run)"

test_command "$PROJECT_ROOT/bin/spinbox create test-ds-prof --profile data-science --dry-run" \
    "Data Science profile (dry-run)"

test_command "$PROJECT_ROOT/bin/spinbox create test-ai-prof --profile ai-llm --dry-run" \
    "AI/LLM profile (dry-run)"

# Test 9: Combined components (dry-run)
echo ""
echo -e "${YELLOW}=== Combined Components Tests ===${NC}"

test_command "$PROJECT_ROOT/bin/spinbox create test-ds-db --data-science --postgresql --dry-run" \
    "Data Science with PostgreSQL (dry-run)"

test_command "$PROJECT_ROOT/bin/spinbox create test-ai-vec --ai-ml --chroma --dry-run" \
    "AI/ML with Chroma (dry-run)"

test_command "$PROJECT_ROOT/bin/spinbox create test-complex --data-science --ai-ml --chroma --postgresql --dry-run" \
    "Complex multi-framework project (dry-run)"

# Cleanup
cd "$OLD_DIR"
rm -rf "$TEST_DIR"

# Test summary
echo ""
echo -e "${YELLOW}===============================================${NC}"
echo -e "${YELLOW}                Test Results                  ${NC}"
echo -e "${YELLOW}===============================================${NC}"
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
    echo -e "${GREEN}All framework tests passed! 🎉${NC}"
    exit 0
fi