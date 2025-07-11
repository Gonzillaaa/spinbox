#!/bin/bash
# Quick verification script for the DRY_RUN fix

echo "Testing DRY_RUN fix..."

# Test 1: Check if DRY_RUN variable is properly handled in utils.sh
echo "Test 1: Checking utils.sh DRY_RUN handling"
if grep -q "DRY_RUN=\${DRY_RUN:-false}" /Users/gonzalo/code/spinbox/lib/utils.sh; then
    echo "✅ DRY_RUN variable properly handled in utils.sh"
else
    echo "❌ DRY_RUN variable not fixed in utils.sh"
fi

# Test 2: Check if CLI command works with --dry-run
echo "Test 2: Testing CLI dry-run functionality"
cd /Users/gonzalo/code/spinbox
export DRY_RUN=true
if ./bin/spinbox create test-dry --fastapi --with-examples --dry-run 2>&1 | grep -q "DRY RUN:"; then
    echo "✅ CLI dry-run mode working correctly"
else
    echo "❌ CLI dry-run mode not working"
fi

# Test 3: Check if test files are simplified
echo "Test 3: Checking test file simplification"
test_count=$(grep -c "test_command" /Users/gonzalo/code/spinbox/testing/deps-examples-test.sh)
if [ "$test_count" -le 10 ]; then
    echo "✅ Test file simplified (${test_count} tests)"
else
    echo "❌ Test file still complex (${test_count} tests)"
fi

echo "Verification complete!"