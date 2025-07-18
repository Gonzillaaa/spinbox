#!/bin/bash
# Examples Integration Test Suite for Spinbox
# Tests for --with-examples flag functionality and example template integration

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

# Source test utilities
source "$(dirname "${BASH_SOURCE[0]}")/../test-utils.sh"

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

test_file_contains() {
    local file="$1"
    local content="$2"
    local description="$3"
    ((TESTS_RUN++))
    
    echo -e "${BLUE}Testing: $description${NC}"
    
    if [[ -f "$file" ]] && grep -q "$content" "$file"; then
        echo -e "${GREEN}✓ PASS: $description${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAIL: $description${NC}"
        echo -e "${RED}  File: $file${NC}"
        echo -e "${RED}  Expected content: $content${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test project creation with examples
create_test_project_with_examples() {
    local components="$1"
    local test_name="example-test-$(date +%s)"
    
    # Create test project directory
    mkdir -p "$TEST_DIR/$test_name"
    
    # Set up environment for testing
    PROJECT_NAME="$test_name"
    WITH_EXAMPLES=true
    
    echo "$TEST_DIR/$test_name"
}

cleanup_test_project() {
    if [[ -n "$TEST_PROJECT" ]] && [[ -d "$TEST_PROJECT" ]]; then
        rm -rf "$TEST_PROJECT"
    fi
}

# Setup test environment
setup_test_environment() {
    echo -e "${BLUE}Setting up examples integration test environment...${NC}"
    
    # Set up PROJECT_ROOT if not already set
    if [[ -z "$PROJECT_ROOT" ]]; then
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
    fi
    
    # Set up TEST_DIR if not already set
    if [[ -z "$TEST_DIR" ]]; then
        TEST_DIR="$(mktemp -d)"
    fi
    
    # Ensure we have a clean test directory
    mkdir -p "$TEST_DIR"
    
    # Source required libraries
    source "$PROJECT_ROOT/lib/utils.sh"
    source "$PROJECT_ROOT/lib/config.sh"
    
    echo -e "${GREEN}Test environment ready${NC}"
}

# Main test function
main() {
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "${YELLOW}     Spinbox Examples Integration Tests       ${NC}"
    echo -e "${YELLOW}===============================================${NC}"
    echo ""
    
    setup_test_environment
    
    # === Example Template Structure Tests ===
    echo -e "${YELLOW}=== Example Template Structure Tests ===${NC}"
    
    # Test core component example templates exist
    test_assert "[[ -d \"$PROJECT_ROOT/templates/examples/core-components/fastapi\" ]]" "FastAPI example templates directory exists"
    test_assert "[[ -d \"$PROJECT_ROOT/templates/examples/core-components/nextjs\" ]]" "Next.js example templates directory exists"
    test_assert "[[ -d \"$PROJECT_ROOT/templates/examples/core-components/postgresql\" ]]" "PostgreSQL example templates directory exists"
    test_assert "[[ -d \"$PROJECT_ROOT/templates/examples/core-components/redis\" ]]" "Redis example templates directory exists"
    test_assert "[[ -d \"$PROJECT_ROOT/templates/examples/core-components/mongodb\" ]]" "MongoDB example templates directory exists"
    test_assert "[[ -d \"$PROJECT_ROOT/templates/examples/core-components/chroma\" ]]" "Chroma example templates directory exists"
    
    # Test example files exist
    test_assert "[[ -f \"$PROJECT_ROOT/templates/examples/core-components/fastapi/README.md\" ]]" "FastAPI README example exists"
    test_assert "[[ -f \"$PROJECT_ROOT/templates/examples/core-components/fastapi/example-basic-crud.py\" ]]" "FastAPI CRUD example exists"
    test_assert "[[ -f \"$PROJECT_ROOT/templates/examples/core-components/fastapi/example-auth-simple.py\" ]]" "FastAPI auth example exists"
    test_assert "[[ -f \"$PROJECT_ROOT/templates/examples/core-components/fastapi/example-websocket.py\" ]]" "FastAPI websocket example exists"
    
    test_assert "[[ -f \"$PROJECT_ROOT/templates/examples/core-components/nextjs/README.md\" ]]" "Next.js README example exists"
    test_assert "[[ -f \"$PROJECT_ROOT/templates/examples/core-components/nextjs/example-basic-app.tsx\" ]]" "Next.js basic app example exists"
    test_assert "[[ -f \"$PROJECT_ROOT/templates/examples/core-components/nextjs/example-api-routes.ts\" ]]" "Next.js API routes example exists"
    test_assert "[[ -f \"$PROJECT_ROOT/templates/examples/core-components/nextjs/example-components.tsx\" ]]" "Next.js components example exists"
    
    test_assert "[[ -f \"$PROJECT_ROOT/templates/examples/core-components/postgresql/README.md\" ]]" "PostgreSQL README example exists"
    test_assert "[[ -f \"$PROJECT_ROOT/templates/examples/core-components/postgresql/example-schema.sql\" ]]" "PostgreSQL schema example exists"
    test_assert "[[ -f \"$PROJECT_ROOT/templates/examples/core-components/postgresql/example-queries.sql\" ]]" "PostgreSQL queries example exists"
    test_assert "[[ -f \"$PROJECT_ROOT/templates/examples/core-components/postgresql/example-migrations.sql\" ]]" "PostgreSQL migrations example exists"
    
    # === CLI Integration Tests ===
    echo -e "${YELLOW}=== CLI Integration Tests ===${NC}"
    
    # Test --with-examples flag parsing
    echo -e "${BLUE}Testing: --with-examples flag parsing${NC}"
    output=$("$PROJECT_ROOT/bin/spinbox" create test-examples --fastapi --with-examples --dry-run 2>/dev/null)
    test_assert "[[ \"$output\" == *\"--with-examples\"* ]] || [[ \"$output\" == *\"examples\"* ]]" "--with-examples flag recognized by CLI"
    
    # Test combining --with-examples and --with-deps
    echo -e "${BLUE}Testing: Combined flags parsing${NC}"
    output=$("$PROJECT_ROOT/bin/spinbox" create test-combined --fastapi --with-examples --with-deps --dry-run 2>/dev/null)
    test_assert "[[ $? -eq 0 ]]" "Combined --with-examples and --with-deps flags work together"
    
    # === Profile-Based Examples Tests ===
    echo -e "${YELLOW}=== Profile-Based Examples Tests ===${NC}"
    
    # Test AI/LLM profile examples
    test_assert "[[ -d \"$PROJECT_ROOT/templates/examples/ai-llm\" ]]" "AI/LLM profile examples directory exists"
    test_assert "[[ -f \"$PROJECT_ROOT/templates/examples/ai-llm/openai/example-chat.py\" ]]" "OpenAI chat example exists"
    test_assert "[[ -f \"$PROJECT_ROOT/templates/examples/ai-llm/openai/example-embeddings.py\" ]]" "OpenAI embeddings example exists"
    
    # Test combination examples
    test_assert "[[ -d \"$PROJECT_ROOT/templates/examples/combinations\" ]]" "Combination examples directory exists"
    test_assert "[[ -d \"$PROJECT_ROOT/templates/examples/combinations/two-component\" ]]" "Two-component combinations directory exists"
    test_assert "[[ -f \"$PROJECT_ROOT/templates/examples/combinations/two-component/fastapi-postgresql/example-basic-crud.py\" ]]" "FastAPI-PostgreSQL combination example exists"
    
    # === Example Content Validation Tests ===
    echo -e "${YELLOW}=== Example Content Validation Tests ===${NC}"
    
    # Test that example files contain valid content
    test_file_contains "$PROJECT_ROOT/templates/examples/core-components/fastapi/example-basic-crud.py" "from fastapi import FastAPI" "FastAPI CRUD example contains FastAPI import"
    test_file_contains "$PROJECT_ROOT/templates/examples/core-components/fastapi/example-auth-simple.py" "from fastapi import FastAPI" "FastAPI auth example contains FastAPI import"
    test_file_contains "$PROJECT_ROOT/templates/examples/core-components/fastapi/example-websocket.py" "from fastapi import FastAPI, WebSocket" "FastAPI websocket example contains WebSocket import"
    
    test_file_contains "$PROJECT_ROOT/templates/examples/core-components/nextjs/example-basic-app.tsx" "import React from 'react'" "Next.js basic app example contains React import"
    test_file_contains "$PROJECT_ROOT/templates/examples/core-components/nextjs/example-api-routes.ts" "import { NextRequest, NextResponse }" "Next.js API routes example contains Next.js imports"
    
    test_file_contains "$PROJECT_ROOT/templates/examples/core-components/postgresql/example-schema.sql" "CREATE TABLE" "PostgreSQL schema example contains CREATE TABLE"
    test_file_contains "$PROJECT_ROOT/templates/examples/core-components/postgresql/example-queries.sql" "SELECT" "PostgreSQL queries example contains SELECT"
    test_file_contains "$PROJECT_ROOT/templates/examples/core-components/postgresql/example-migrations.sql" "ALTER TABLE" "PostgreSQL migrations example contains ALTER TABLE"
    
    # === README Content Tests ===
    echo -e "${YELLOW}=== README Content Tests ===${NC}"
    
    # Test that README files contain proper documentation
    test_file_contains "$PROJECT_ROOT/templates/examples/core-components/fastapi/README.md" "# FastAPI Examples" "FastAPI README has proper title"
    test_file_contains "$PROJECT_ROOT/templates/examples/core-components/fastapi/README.md" "## Setup" "FastAPI README has setup section"
    test_file_contains "$PROJECT_ROOT/templates/examples/core-components/fastapi/README.md" "## Usage" "FastAPI README has usage section"
    
    test_file_contains "$PROJECT_ROOT/templates/examples/core-components/nextjs/README.md" "# Next.js Examples" "Next.js README has proper title"
    test_file_contains "$PROJECT_ROOT/templates/examples/core-components/nextjs/README.md" "## Setup" "Next.js README has setup section"
    test_file_contains "$PROJECT_ROOT/templates/examples/core-components/nextjs/README.md" "## Usage" "Next.js README has usage section"
    
    test_file_contains "$PROJECT_ROOT/templates/examples/core-components/postgresql/README.md" "# PostgreSQL Examples" "PostgreSQL README has proper title"
    test_file_contains "$PROJECT_ROOT/templates/examples/core-components/postgresql/README.md" "## Setup" "PostgreSQL README has setup section"
    
    # === Integration with Component Generators Tests ===
    echo -e "${YELLOW}=== Integration with Component Generators Tests ===${NC}"
    
    # Test that component generators have examples support
    test_assert "[[ -f \"$PROJECT_ROOT/generators/fastapi.sh\" ]]" "FastAPI generator exists"
    test_assert "[[ -f \"$PROJECT_ROOT/generators/nextjs.sh\" ]]" "Next.js generator exists"
    test_assert "[[ -f \"$PROJECT_ROOT/generators/postgresql.sh\" ]]" "PostgreSQL generator exists"
    
    # Test that generators have examples integration
    test_file_contains "$PROJECT_ROOT/generators/fastapi.sh" "add_fastapi_examples" "FastAPI generator has examples function"
    test_file_contains "$PROJECT_ROOT/generators/nextjs.sh" "add_nextjs_examples" "Next.js generator has examples function"
    test_file_contains "$PROJECT_ROOT/generators/postgresql.sh" "add_postgresql_examples" "PostgreSQL generator has examples function"
    
    # === Performance Tests ===
    echo -e "${YELLOW}=== Performance Tests ===${NC}"
    
    # Test that example template copying doesn't significantly slow down project creation
    echo -e "${BLUE}Testing: Example template performance${NC}"
    start_time=$(date +%s.%N)
    "$PROJECT_ROOT/bin/spinbox" create perf-test --fastapi --with-examples --dry-run > /dev/null 2>&1
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc -l)
    
    # Should complete within 5 seconds (generous limit)
    test_assert "[[ $(echo \"$duration < 5.0\" | bc -l) -eq 1 ]]" "Example template processing completes under 5 seconds ($duration s)"
    
    # === Edge Cases Tests ===
    echo -e "${YELLOW}=== Edge Cases Tests ===${NC}"
    
    # Test handling of non-existent example templates
    echo -e "${BLUE}Testing: Non-existent example template handling${NC}"
    TEST_PROJECT=$(create_test_project_with_examples "--unknown-component")
    
    # This should not crash the system
    output=$("$PROJECT_ROOT/bin/spinbox" create edge-test --python --with-examples --dry-run 2>&1)
    test_assert "[[ $? -eq 0 ]]" "System handles non-existent example templates gracefully"
    cleanup_test_project
    
    # Test combining multiple components with examples
    echo -e "${BLUE}Testing: Multiple component examples${NC}"
    output=$("$PROJECT_ROOT/bin/spinbox" create multi-test --fastapi --nextjs --postgresql --with-examples --dry-run 2>/dev/null)
    test_assert "[[ $? -eq 0 ]]" "System handles multiple component examples"
    
    echo ""
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "${YELLOW}           Examples Integration Test Results              ${NC}"
    echo -e "${YELLOW}===============================================${NC}"
    echo "Tests run:    $TESTS_RUN"
    if [[ $TESTS_PASSED -eq $TESTS_RUN ]]; then
        echo -e "${GREEN}Passed:       $TESTS_PASSED${NC}"
        echo -e "${GREEN}Failed:       $TESTS_FAILED${NC}"
        echo ""
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${GREEN}Passed:       $TESTS_PASSED${NC}"
        echo -e "${RED}Failed:       $TESTS_FAILED${NC}"
        echo ""
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Only run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi