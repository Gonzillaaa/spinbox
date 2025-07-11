#!/bin/bash
# Simple Tests for --with-deps and --with-examples flags
# Following the simple test framework pattern

# Test setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/simple-test.sh"

echo "Testing --with-deps and --with-examples functionality..."

# Test 1: CLI argument parsing
test_group "CLI Argument Parsing"

test_assert "echo 'spinbox create --help' | $PROJECT_ROOT/bin/spinbox create --help 2>&1 | grep -q 'with-deps'" \
    "Help text includes --with-deps flag"

test_assert "echo 'spinbox create --help' | $PROJECT_ROOT/bin/spinbox create --help 2>&1 | grep -q 'with-examples'" \
    "Help text includes --with-examples flag"

test_assert "echo 'spinbox add --help' | $PROJECT_ROOT/bin/spinbox add --help 2>&1 | grep -q 'with-deps'" \
    "Add command help includes --with-deps flag"

test_assert "echo 'spinbox add --help' | $PROJECT_ROOT/bin/spinbox add --help 2>&1 | grep -q 'with-examples'" \
    "Add command help includes --with-examples flag"

# Test 2: Dependency manager functions
test_group "Dependency Manager"

# Source the dependency manager
source "$PROJECT_ROOT/lib/dependency-manager.sh"

test_assert "type -t add_component_dependencies | grep -q function" \
    "add_component_dependencies function exists"

test_assert "type -t add_dependencies_for_components | grep -q function" \
    "add_dependencies_for_components function exists"

test_assert "type -t init_python_project_with_uv | grep -q function" \
    "init_python_project_with_uv function exists"

test_assert "type -t init_nodejs_project_with_npm | grep -q function" \
    "init_nodejs_project_with_npm function exists"

# Test 3: Examples generator functions
test_group "Examples Generator"

# Source the examples generator
source "$PROJECT_ROOT/lib/examples-generator.sh"

test_assert "type -t generate_component_examples | grep -q function" \
    "generate_component_examples function exists"

test_assert "type -t generate_examples_for_components | grep -q function" \
    "generate_examples_for_components function exists"

test_assert "type -t generate_environment_example | grep -q function" \
    "generate_environment_example function exists"

# Test 4: Dry-run mode functionality
test_group "Dry-run Mode"

# Create temporary directory for testing
TEST_DIR="/tmp/spinbox-test-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

test_assert "$PROJECT_ROOT/bin/spinbox create test-api --fastapi --with-deps --with-examples --dry-run >/dev/null 2>&1" \
    "FastAPI project with --with-deps --with-examples (dry-run)"

test_assert "$PROJECT_ROOT/bin/spinbox create test-frontend --nextjs --with-deps --with-examples --dry-run >/dev/null 2>&1" \
    "Next.js project with --with-deps --with-examples (dry-run)"

test_assert "$PROJECT_ROOT/bin/spinbox create test-full --fastapi --nextjs --postgresql --with-deps --with-examples --dry-run >/dev/null 2>&1" \
    "Full-stack project with --with-deps --with-examples (dry-run)"

# Test 5: Backwards compatibility
test_group "Backwards Compatibility"

test_assert "$PROJECT_ROOT/bin/spinbox create test-basic --fastapi --dry-run >/dev/null 2>&1" \
    "Basic project creation without new flags works"

test_assert "$PROJECT_ROOT/bin/spinbox create test-python --python --dry-run >/dev/null 2>&1" \
    "Python project creation without new flags works"

# Test 6: Flag combinations
test_group "Flag Combinations"

test_assert "$PROJECT_ROOT/bin/spinbox create test-deps-only --fastapi --with-deps --dry-run >/dev/null 2>&1" \
    "Project with --with-deps only works"

test_assert "$PROJECT_ROOT/bin/spinbox create test-examples-only --fastapi --with-examples --dry-run >/dev/null 2>&1" \
    "Project with --with-examples only works"

test_assert "$PROJECT_ROOT/bin/spinbox create test-both --fastapi --with-deps --with-examples --dry-run >/dev/null 2>&1" \
    "Project with both flags works"

# Test 7: Module integration
test_group "Module Integration"

# Test that dependency manager is properly sourced in project generator
test_assert "grep -q 'dependency-manager.sh' '$PROJECT_ROOT/lib/project-generator.sh'" \
    "Project generator sources dependency manager"

# Test that examples generator is properly sourced in project generator
test_assert "grep -q 'examples-generator.sh' '$PROJECT_ROOT/lib/project-generator.sh'" \
    "Project generator sources examples generator"

# Test that new functions are called in project generator
test_assert "grep -q 'add_dependencies_for_components' '$PROJECT_ROOT/lib/project-generator.sh'" \
    "Project generator calls dependency functions"

test_assert "grep -q 'generate_examples_for_components' '$PROJECT_ROOT/lib/project-generator.sh'" \
    "Project generator calls example functions"

# Cleanup
cd - >/dev/null 2>&1
rm -rf "$TEST_DIR"

# Test summary
test_summary