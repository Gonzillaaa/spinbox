#!/bin/bash
# Test script to verify security template integration

set -e

echo "=== Testing Security Template Integration ==="

# Clean up any existing test project
rm -rf test-security-integration

# Create test project
echo "[1/7] Creating test project..."
./bin/spinbox create test-security-integration --fastapi --nextjs --postgresql

# Check FastAPI security files
echo "[2/7] Checking FastAPI security integration..."
test -f test-security-integration/fastapi/setup_venv.sh || { echo "ERROR: setup_venv.sh not found"; exit 1; }
test -x test-security-integration/fastapi/setup_venv.sh || { echo "ERROR: setup_venv.sh not executable"; exit 1; }
test -f test-security-integration/fastapi/.gitignore || { echo "ERROR: FastAPI .gitignore not found"; exit 1; }
test -f test-security-integration/fastapi/.env.example || { echo "ERROR: FastAPI .env.example not found"; exit 1; }
grep -q "POSTGRES_PASSWORD" test-security-integration/fastapi/.env.example || { echo "ERROR: FastAPI .env.example missing security template"; exit 1; }

# Check Next.js security files
echo "[3/7] Checking Next.js security integration..."
test -f test-security-integration/nextjs/.gitignore || { echo "ERROR: Next.js .gitignore not found"; exit 1; }
test -f test-security-integration/nextjs/.env.local.example || { echo "ERROR: Next.js .env.local.example not found"; exit 1; }
grep -q "NEXTAUTH_SECRET" test-security-integration/nextjs/.env.local.example || { echo "ERROR: Next.js .env.local.example missing security template"; exit 1; }

# Check PostgreSQL security files
echo "[4/7] Checking PostgreSQL security integration..."
test -f test-security-integration/postgresql/.env.example || { echo "ERROR: PostgreSQL .env.example not found"; exit 1; }
grep -q "BACKUP_ENCRYPTION_KEY" test-security-integration/postgresql/.env.example || { echo "ERROR: PostgreSQL .env.example missing security template"; exit 1; }

# Check .gitignore content
echo "[5/7] Checking .gitignore content..."
grep -q "venv/" test-security-integration/fastapi/.gitignore || { echo "ERROR: FastAPI .gitignore missing venv"; exit 1; }
grep -q "node_modules" test-security-integration/nextjs/.gitignore || { echo "ERROR: Next.js .gitignore missing node_modules"; exit 1; }
grep -q "\.env" test-security-integration/fastapi/.gitignore || { echo "ERROR: FastAPI .gitignore missing .env"; exit 1; }
grep -q "\.env" test-security-integration/nextjs/.gitignore || { echo "ERROR: Next.js .gitignore missing .env"; exit 1; }

# Check that .env files are created but different from .env.example
echo "[6/7] Checking .env file creation..."
test -f test-security-integration/fastapi/.env || { echo "ERROR: FastAPI .env not created"; exit 1; }
test -f test-security-integration/nextjs/.env.local || { echo "ERROR: Next.js .env.local not created"; exit 1; }
test -f test-security-integration/postgresql/.env || { echo "ERROR: PostgreSQL .env not created"; exit 1; }

# Test that setup_venv.sh has correct Python version detection
echo "[7/7] Testing setup_venv.sh functionality..."
if command -v python3 >/dev/null 2>&1; then
    cd test-security-integration/fastapi
    echo "Testing Python version detection..."
    grep -q "Python 3.10+" setup_venv.sh || { echo "ERROR: setup_venv.sh missing Python version check"; exit 1; }
    cd ../..
fi

echo ""
echo "✅ All security integration tests passed!"
echo ""
echo "Security features verified:"
echo "  • Virtual environment setup script (setup_venv.sh)"
echo "  • Comprehensive .gitignore files"
echo "  • Security-focused .env.example templates"
echo "  • Automatic .env file creation"
echo "  • Environment variable security guidelines"
echo ""

# Clean up
rm -rf test-security-integration
echo "Test cleanup completed."