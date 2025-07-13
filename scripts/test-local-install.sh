#!/bin/bash
# Test Local Installation (User-space) - Centralized Architecture

set -e

echo "================================"
echo "Testing Local Centralized Install"
echo "================================"

# From your spinbox directory
cd /Users/gonzalo/code/spinbox

# Clean up any existing installation first
echo "[INFO] Cleaning up existing installations..."
./uninstall.sh --config --force 2>/dev/null || echo "No existing installation found"

# Install using local user installation script
echo "[INFO] Installing using local user installation script..."
./install-user.sh

# Update PATH for current session (avoid shell-specific config issues)
export PATH="$HOME/.local/bin:$PATH"

echo "[INFO] Testing local installation..."

# Verify installation locations
echo "Checking installation locations:"
echo "  Binary: $(which spinbox 2>/dev/null || echo 'NOT FOUND')"
echo "  Source: $(ls -d ~/.spinbox/source 2>/dev/null || echo 'NOT FOUND')"

# Test version
echo "[INFO] Testing version command..."
spinbox --version

# Test profiles with enhanced descriptions
echo "[INFO] Testing profiles command..."
spinbox profiles

# Verify centralized source is being used
echo "[INFO] Verifying centralized source architecture..."
if [[ -d ~/.spinbox/source ]]; then
    echo "✓ Centralized source directory exists: ~/.spinbox/source"
    echo "  Contents: $(ls ~/.spinbox/source)"
else
    echo "✗ Centralized source directory missing!"
    exit 1
fi

# Test that profiles show enhanced descriptions (no minimal, detailed ai-llm/data-science)
echo "[INFO] Checking for enhanced profile descriptions..."
if spinbox profiles | grep -q "OpenAI, Anthropic, LangChain"; then
    echo "✓ Enhanced AI/LLM profile description found"
else
    echo "✗ Enhanced AI/LLM profile description missing!"
    exit 1
fi

if spinbox profiles | grep -q "pandas, numpy, matplotlib"; then
    echo "✓ Enhanced data-science profile description found"
else
    echo "✗ Enhanced data-science profile description missing!"
    exit 1
fi

if spinbox profiles | grep -q "minimal"; then
    echo "✗ Minimal profile still exists (should be removed)!"
    exit 1
else
    echo "✓ Minimal profile correctly removed"
fi

# Test profile count (should be 6: python, node, web-app, api-only, data-science, ai-llm)
profile_count=$(spinbox profiles | grep -E "^  [a-z-]+$" | wc -l | tr -d ' ')
if [[ "$profile_count" == "6" ]]; then
    echo "✓ Correct profile count: $profile_count"
else
    echo "✗ Incorrect profile count: $profile_count (expected 6)"
    exit 1
fi

# Test that both --python and --node work as base options (replacing minimal)
echo "[INFO] Testing new base options (--python, --node)..."
spinbox create test-python-project --python --dry-run
spinbox create test-node-project --node --dry-run

echo "[INFO] Testing new python and node profiles..."
spinbox create test-python-profile --profile python --dry-run
spinbox create test-node-profile --profile node --dry-run

echo "[INFO] Testing uninstall..."
spinbox uninstall --config --force

echo "================================"
echo "✓ Local Installation Test PASSED"
echo "================================"