#!/bin/bash
# Pre-push hook for Node.js projects
# Runs tests before allowing push

set -e

echo "Running pre-push tests..."

# Check if package.json exists
if [ ! -f "package.json" ]; then
    echo "ℹ️  No package.json found, skipping tests."
    exit 0
fi

# Check if test script exists in package.json
if ! grep -q '"test"' package.json; then
    echo "ℹ️  No test script in package.json, skipping tests."
    exit 0
fi

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo "⚠️  Warning: npm is not installed"
    echo "   Skipping tests..."
    exit 0
fi

# Run tests
echo "Running npm test..."
if ! npm test; then
    echo "❌ Tests failed! Push aborted."
    echo "   Fix the failing tests before pushing."
    exit 1
fi

echo "✅ All tests passed!"
exit 0
