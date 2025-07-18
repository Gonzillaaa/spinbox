#!/bin/bash
# Dependency Management Test Suite for Spinbox
# Tests for --with-deps flag functionality and dependency file generation

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
        if [[ -f "$file" ]]; then
            echo -e "${RED}  Actual content:${NC}"
            head -10 "$file" | sed 's/^/    /'
        else
            echo -e "${RED}  File does not exist${NC}"
        fi
        ((TESTS_FAILED++))
        return 1
    fi
}

test_file_executable() {
    local file="$1"
    local description="$2"
    test_assert "[[ -x \"$file\" ]]" "$description"
}

# Test project creation helper
create_test_project_with_deps() {
    local components="$1"
    local test_name="dep-test-$(date +%s)"
    
    # Create test project with dependencies
    "$PROJECT_ROOT/bin/spinbox" create "$test_name" $components --with-deps --dry-run > /dev/null 2>&1
    
    # For real testing, we need to create actual files
    mkdir -p "$TEST_DIR/$test_name"
    echo "$test_name" > "$TEST_DIR/$test_name/.test-marker"
    
    # Source the dependency manager to test functions directly
    WITH_DEPS=true
    source "$PROJECT_ROOT/lib/dependency-manager.sh"
    
    echo "$TEST_DIR/$test_name"
}

cleanup_test_project() {
    if [[ -n "$TEST_PROJECT" ]] && [[ -d "$TEST_PROJECT" ]]; then
        rm -rf "$TEST_PROJECT"
    fi
}

# Setup test environment
setup_test_environment() {
    echo -e "${BLUE}Setting up dependency management test environment...${NC}"
    
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
    source "$PROJECT_ROOT/lib/dependency-manager.sh"
    
    echo -e "${GREEN}Test environment ready${NC}"
}

# Main test function
main() {
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "${YELLOW}     Spinbox Dependency Management Tests      ${NC}"
    echo -e "${YELLOW}===============================================${NC}"
    echo ""
    
    setup_test_environment
    
    # === Python Dependency Tests ===
    echo -e "${YELLOW}=== Python Dependency Tests ===${NC}"
    
    # Test FastAPI dependencies
    echo -e "${BLUE}Testing: FastAPI dependency management${NC}"
    TEST_PROJECT=$(create_test_project_with_deps "--fastapi")
    add_python_dependencies "$TEST_PROJECT" "fastapi"
    test_file_contains "$TEST_PROJECT/requirements.txt" "fastapi>=0.104.0" "FastAPI dependency added"
    test_file_contains "$TEST_PROJECT/requirements.txt" "uvicorn\[standard\]>=0.24.0" "Uvicorn dependency added"
    test_file_contains "$TEST_PROJECT/requirements.txt" "pydantic>=2.5.0" "Pydantic dependency added"
    test_file_contains "$TEST_PROJECT/requirements.txt" "python-dotenv>=1.0.0" "Python-dotenv dependency added"
    cleanup_test_project
    
    # Test PostgreSQL dependencies
    echo -e "${BLUE}Testing: PostgreSQL dependency management${NC}"
    TEST_PROJECT=$(create_test_project_with_deps "--postgresql")
    add_python_dependencies "$TEST_PROJECT" "postgresql"
    test_file_contains "$TEST_PROJECT/requirements.txt" "sqlalchemy>=2.0.0" "SQLAlchemy dependency added"
    test_file_contains "$TEST_PROJECT/requirements.txt" "asyncpg>=0.29.0" "AsyncPG dependency added"
    test_file_contains "$TEST_PROJECT/requirements.txt" "alembic>=1.13.0" "Alembic dependency added"
    test_file_contains "$TEST_PROJECT/requirements.txt" "psycopg2-binary>=2.9.0" "Psycopg2 dependency added"
    cleanup_test_project
    
    # Test Redis dependencies
    echo -e "${BLUE}Testing: Redis dependency management${NC}"
    TEST_PROJECT=$(create_test_project_with_deps "--redis")
    add_python_dependencies "$TEST_PROJECT" "redis"
    test_file_contains "$TEST_PROJECT/requirements.txt" "redis>=5.0.0" "Redis dependency added"
    test_file_contains "$TEST_PROJECT/requirements.txt" "celery>=5.3.0" "Celery dependency added"
    cleanup_test_project
    
    # Test MongoDB dependencies
    echo -e "${BLUE}Testing: MongoDB dependency management${NC}"
    TEST_PROJECT=$(create_test_project_with_deps "--mongodb")
    add_python_dependencies "$TEST_PROJECT" "mongodb"
    test_file_contains "$TEST_PROJECT/requirements.txt" "beanie>=1.24.0" "Beanie dependency added"
    test_file_contains "$TEST_PROJECT/requirements.txt" "motor>=3.3.0" "Motor dependency added"
    cleanup_test_project
    
    # Test Chroma dependencies
    echo -e "${BLUE}Testing: Chroma dependency management${NC}"
    TEST_PROJECT=$(create_test_project_with_deps "--chroma")
    add_python_dependencies "$TEST_PROJECT" "chroma"
    test_file_contains "$TEST_PROJECT/requirements.txt" "chromadb>=0.4.0" "ChromaDB dependency added"
    test_file_contains "$TEST_PROJECT/requirements.txt" "sentence-transformers>=2.2.0" "Sentence transformers dependency added"
    cleanup_test_project
    
    # === Node.js Dependency Tests ===
    echo -e "${YELLOW}=== Node.js Dependency Tests ===${NC}"
    
    # Test Next.js dependencies
    echo -e "${BLUE}Testing: Next.js dependency management${NC}"
    TEST_PROJECT=$(create_test_project_with_deps "--nextjs")
    
    # Create a basic package.json first
    create_basic_package_json "$TEST_PROJECT/package.json"
    add_nodejs_dependencies "$TEST_PROJECT" "nextjs"
    
    test_file_contains "$TEST_PROJECT/package.json" "\"next\":" "Next.js dependency added"
    test_file_contains "$TEST_PROJECT/package.json" "\"react\":" "React dependency added"
    test_file_contains "$TEST_PROJECT/package.json" "\"react-dom\":" "React-DOM dependency added"
    test_file_contains "$TEST_PROJECT/package.json" "\"typescript\":" "TypeScript dev dependency added"
    cleanup_test_project
    
    # === Profile-Based Dependency Tests ===
    echo -e "${YELLOW}=== Profile-Based Dependency Tests ===${NC}"
    
    # Test AI/LLM profile dependencies
    echo -e "${BLUE}Testing: AI/LLM profile dependency management${NC}"
    TEST_PROJECT=$(create_test_project_with_deps "--profile ai-llm")
    add_python_dependencies "$TEST_PROJECT" "ai-llm"
    test_file_contains "$TEST_PROJECT/requirements.txt" "openai>=1.3.0" "OpenAI dependency added"
    test_file_contains "$TEST_PROJECT/requirements.txt" "anthropic>=0.7.0" "Anthropic dependency added"
    test_file_contains "$TEST_PROJECT/requirements.txt" "langchain>=0.0.350" "LangChain dependency added"
    test_file_contains "$TEST_PROJECT/requirements.txt" "llama-index>=0.9.0" "LlamaIndex dependency added"
    cleanup_test_project
    
    # Test Data Science profile dependencies
    echo -e "${BLUE}Testing: Data Science profile dependency management${NC}"
    TEST_PROJECT=$(create_test_project_with_deps "--profile data-science")
    add_python_dependencies "$TEST_PROJECT" "data-science"
    test_file_contains "$TEST_PROJECT/requirements.txt" "pandas>=2.0.0" "Pandas dependency added"
    test_file_contains "$TEST_PROJECT/requirements.txt" "numpy>=1.24.0" "NumPy dependency added"
    test_file_contains "$TEST_PROJECT/requirements.txt" "matplotlib>=3.7.0" "Matplotlib dependency added"
    test_file_contains "$TEST_PROJECT/requirements.txt" "scikit-learn>=1.3.0" "Scikit-learn dependency added"
    cleanup_test_project
    
    # === Component Integration Tests ===
    echo -e "${YELLOW}=== Component Integration Tests ===${NC}"
    
    # Test component type detection
    echo -e "${BLUE}Testing: Component type detection${NC}"
    TEST_PROJECT=$(create_test_project_with_deps "--fastapi --nextjs")
    
    # Test that Python components don't get Node.js treatment
    manage_component_dependencies "$TEST_PROJECT" "fastapi"
    test_file_contains "$TEST_PROJECT/requirements.txt" "fastapi>=0.104.0" "FastAPI added as Python dependency"
    
    # Test that Node.js components don't get Python treatment
    create_basic_package_json "$TEST_PROJECT/package.json"
    manage_component_dependencies "$TEST_PROJECT" "nextjs"
    test_file_contains "$TEST_PROJECT/package.json" "\"next\":" "Next.js added as Node.js dependency"
    
    # Verify no cross-contamination
    test_assert "! grep -q 'fastapi' '$TEST_PROJECT/package.json'" "FastAPI not added to package.json"
    test_assert "! grep -q 'next' '$TEST_PROJECT/requirements.txt'" "Next.js not added to requirements.txt"
    cleanup_test_project
    
    # === Dependency Installation Scripts Tests ===
    echo -e "${YELLOW}=== Dependency Installation Scripts Tests ===${NC}"
    
    # Test Python dependency installation script
    echo -e "${BLUE}Testing: Python dependency installation script${NC}"
    TEST_PROJECT=$(create_test_project_with_deps "--fastapi")
    touch "$TEST_PROJECT/requirements.txt"
    create_dependency_scripts "$TEST_PROJECT"
    test_assert "[[ -f \"$TEST_PROJECT/setup-python-deps.sh\" ]]" "Python setup script created"
    test_file_executable "$TEST_PROJECT/setup-python-deps.sh" "Python setup script is executable"
    test_file_contains "$TEST_PROJECT/setup-python-deps.sh" "pip3 install -r requirements.txt" "Python setup script has install command"
    cleanup_test_project
    
    # Test Node.js dependency installation script
    echo -e "${BLUE}Testing: Node.js dependency installation script${NC}"
    TEST_PROJECT=$(create_test_project_with_deps "--nextjs")
    create_basic_package_json "$TEST_PROJECT/package.json"
    create_dependency_scripts "$TEST_PROJECT"
    test_assert "[[ -f \"$TEST_PROJECT/setup-nodejs-deps.sh\" ]]" "Node.js setup script created"
    test_file_executable "$TEST_PROJECT/setup-nodejs-deps.sh" "Node.js setup script is executable"
    test_file_contains "$TEST_PROJECT/setup-nodejs-deps.sh" "npm install" "Node.js setup script has install command"
    cleanup_test_project
    
    # === Edge Cases Tests ===
    echo -e "${YELLOW}=== Edge Cases Tests ===${NC}"
    
    # Test duplicate dependency handling
    echo -e "${BLUE}Testing: Duplicate dependency handling${NC}"
    TEST_PROJECT=$(create_test_project_with_deps "--fastapi")
    add_python_dependencies "$TEST_PROJECT" "fastapi"
    add_python_dependencies "$TEST_PROJECT" "fastapi"  # Add same component twice
    
    # Count occurrences of fastapi in requirements.txt
    fastapi_count=$(grep -c "fastapi>=" "$TEST_PROJECT/requirements.txt" 2>/dev/null || echo 0)
    test_assert "[[ $fastapi_count -eq 1 ]]" "Duplicate dependencies not added"
    cleanup_test_project
    
    # Test unknown component handling
    echo -e "${BLUE}Testing: Unknown component handling${NC}"
    TEST_PROJECT=$(create_test_project_with_deps "--unknown")
    
    # This should not crash or create invalid files
    add_python_dependencies "$TEST_PROJECT" "unknown-component" 2>/dev/null || true
    test_assert "[[ ! -f \"$TEST_PROJECT/requirements.txt\" ]] || [[ ! -s \"$TEST_PROJECT/requirements.txt\" ]]" "Unknown component doesn't create invalid dependencies"
    cleanup_test_project
    
    echo ""
    echo -e "${YELLOW}===============================================${NC}"
    echo -e "${YELLOW}           Dependency Management Test Results              ${NC}"
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