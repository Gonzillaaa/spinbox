#!/bin/bash
# Pre-commit hook for Node.js projects
# Runs code quality checks before allowing commits

set -e

echo "Running pre-commit checks..."

# Get list of staged JS/TS files
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR | grep -E "\.(js|jsx|ts|tsx)$" || true)

if [ -z "$STAGED_FILES" ]; then
    echo "No JavaScript/TypeScript files to check."
    exit 0
fi

echo "Checking ${STAGED_FILES}"

# Check for available tools
HAS_PRETTIER=false
HAS_ESLINT=false

if command -v npx &> /dev/null; then
    # Check if prettier is available (local or global)
    if npx prettier --version &> /dev/null 2>&1; then
        HAS_PRETTIER=true
    fi
    # Check if eslint is available
    if npx eslint --version &> /dev/null 2>&1; then
        HAS_ESLINT=true
    fi
fi

# Warn if no tools found
if [ "$HAS_PRETTIER" = false ] && [ "$HAS_ESLINT" = false ]; then
    echo "⚠️  Warning: No code quality tools found (prettier, eslint)"
    echo "   Install with: npm install -D prettier eslint"
    echo "   Skipping quality checks..."
    exit 0
fi

# Run prettier formatting check
if [ "$HAS_PRETTIER" = true ]; then
    echo "1. Checking code formatting (prettier)..."
    if ! npx prettier --check $STAGED_FILES 2>&1; then
        echo "❌ Code formatting issues found!"
        echo "   Fix with: npx prettier --write $STAGED_FILES"
        exit 1
    fi
fi

# Run eslint linting
if [ "$HAS_ESLINT" = true ]; then
    echo "2. Running linter (eslint)..."
    if ! npx eslint $STAGED_FILES; then
        echo "❌ Linting issues found!"
        echo "   Review the errors above and fix them."
        exit 1
    fi
fi

echo "✅ All pre-commit checks passed!"
exit 0
