#!/bin/bash
# Pre-commit hook for Python projects
# Runs code quality checks before allowing commits

set -e

echo "Running pre-commit checks..."

# Get list of staged Python files
STAGED_PY_FILES=$(git diff --cached --name-only --diff-filter=ACMR | grep "\.py$" || true)

if [ -z "$STAGED_PY_FILES" ]; then
    echo "No Python files to check."
    exit 0
fi

echo "Checking ${STAGED_PY_FILES}"

# Check if required tools are installed
MISSING_TOOLS=()

if ! command -v black &> /dev/null; then
    MISSING_TOOLS+=("black")
fi

if ! command -v isort &> /dev/null; then
    MISSING_TOOLS+=("isort")
fi

if ! command -v flake8 &> /dev/null; then
    MISSING_TOOLS+=("flake8")
fi

# Warn about missing tools but don't fail
if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    echo "⚠️  Warning: Some code quality tools are not installed: ${MISSING_TOOLS[*]}"
    echo "   Install with: pip install black isort flake8"
    echo "   Skipping quality checks..."
    exit 0
fi

# Run black formatting check
echo "1. Checking code formatting (black)..."
if ! black --check $STAGED_PY_FILES 2>&1; then
    echo "❌ Code formatting issues found!"
    echo "   Fix with: black $STAGED_PY_FILES"
    exit 1
fi

# Run isort import sorting check
echo "2. Checking import sorting (isort)..."
if ! isort --check-only $STAGED_PY_FILES 2>&1; then
    echo "❌ Import sorting issues found!"
    echo "   Fix with: isort $STAGED_PY_FILES"
    exit 1
fi

# Run flake8 linting
echo "3. Running linter (flake8)..."
if ! flake8 $STAGED_PY_FILES; then
    echo "❌ Linting issues found!"
    echo "   Review the errors above and fix them."
    exit 1
fi

echo "✅ All pre-commit checks passed!"
exit 0
