#!/bin/bash
# Pre-push hook for Python projects
# Runs tests before allowing push

set -e

echo "Running pre-push tests..."

# Check if pytest is installed
if ! command -v pytest &> /dev/null; then
    echo "⚠️  Warning: pytest is not installed"
    echo "   Install with: pip install pytest"
    echo "   Skipping tests..."
    exit 0
fi

# Check if tests directory exists
if [ ! -d "tests" ]; then
    echo "ℹ️  No tests directory found, skipping tests."
    exit 0
fi

# Run pytest
echo "Running pytest..."
if ! pytest tests/ -v; then
    echo "❌ Tests failed! Push aborted."
    echo "   Fix the failing tests before pushing."
    exit 1
fi

echo "✅ All tests passed!"
exit 0
