#!/bin/bash
# Test script for --with-deps and --with-examples flags

set -e

echo "Testing --with-deps and --with-examples flags..."

# Create test directory
TEST_DIR="/tmp/spinbox-test-$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "Test directory: $TEST_DIR"

# Test 1: Basic FastAPI project with dependencies and examples
echo "Test 1: Creating FastAPI project with --with-deps --with-examples"
if /Users/gonzalo/code/spinbox/bin/spinbox create test-api --fastapi --with-deps --with-examples --dry-run; then
    echo "✓ Test 1 passed: FastAPI with --with-deps --with-examples (dry run)"
else
    echo "✗ Test 1 failed: FastAPI with --with-deps --with-examples (dry run)"
    exit 1
fi

# Test 2: Next.js project with dependencies and examples
echo "Test 2: Creating Next.js project with --with-deps --with-examples"
if /Users/gonzalo/code/spinbox/bin/spinbox create test-frontend --nextjs --with-deps --with-examples --dry-run; then
    echo "✓ Test 2 passed: Next.js with --with-deps --with-examples (dry run)"
else
    echo "✗ Test 2 failed: Next.js with --with-deps --with-examples (dry run)"
    exit 1
fi

# Test 3: Full-stack project with dependencies and examples
echo "Test 3: Creating full-stack project with --with-deps --with-examples"
if /Users/gonzalo/code/spinbox/bin/spinbox create test-fullstack --fastapi --nextjs --postgresql --with-deps --with-examples --dry-run; then
    echo "✓ Test 3 passed: Full-stack with --with-deps --with-examples (dry run)"
else
    echo "✗ Test 3 failed: Full-stack with --with-deps --with-examples (dry run)"
    exit 1
fi

# Test 4: Project without new flags (should work as before)
echo "Test 4: Creating project without new flags"
if /Users/gonzalo/code/spinbox/bin/spinbox create test-basic --fastapi --dry-run; then
    echo "✓ Test 4 passed: Basic project without new flags"
else
    echo "✗ Test 4 failed: Basic project without new flags"
    exit 1
fi

# Test 5: Test help output includes new flags
echo "Test 5: Checking help output includes new flags"
if /Users/gonzalo/code/spinbox/bin/spinbox create --help | grep -q "with-deps"; then
    echo "✓ Test 5 passed: Help includes --with-deps"
else
    echo "✗ Test 5 failed: Help missing --with-deps"
    exit 1
fi

if /Users/gonzalo/code/spinbox/bin/spinbox create --help | grep -q "with-examples"; then
    echo "✓ Test 5 passed: Help includes --with-examples"
else
    echo "✗ Test 5 failed: Help missing --with-examples"
    exit 1
fi

# Cleanup
cd ..
rm -rf "$TEST_DIR"

echo "All tests passed! 🎉"
echo "The --with-deps and --with-examples flags are working correctly."