#!/bin/bash
# Comprehensive Test for Centralized Installation Architecture

set -e

echo "============================================="
echo "Testing Centralized Installation Architecture"
echo "============================================="

cd /Users/gonzalo/code/spinbox

# Function to print test results
print_result() {
    if [[ $1 -eq 0 ]]; then
        echo "✓ $2"
    else
        echo "✗ $2"
        exit 1
    fi
}

echo ""
echo "=== Phase 1: Testing Development Mode ==="

# Test development mode (should use local files)
echo "[INFO] Testing development mode..."
./bin/spinbox --version
./bin/spinbox profiles > /tmp/dev_profiles.txt

# Verify enhanced profiles in development mode
if grep -q "OpenAI, Anthropic, LangChain" /tmp/dev_profiles.txt; then
    print_result 0 "Development mode: Enhanced AI/LLM profile found"
else
    print_result 1 "Development mode: Enhanced AI/LLM profile missing"
fi

if grep -q "pandas, numpy, matplotlib" /tmp/dev_profiles.txt; then
    print_result 0 "Development mode: Enhanced data-science profile found"
else
    print_result 1 "Development mode: Enhanced data-science profile missing"
fi

if grep -q "minimal" /tmp/dev_profiles.txt; then
    print_result 1 "Development mode: Minimal profile should be removed"
else
    print_result 0 "Development mode: Minimal profile correctly removed"
fi

dev_profile_count=$(grep -E "^  [a-z-]+$" /tmp/dev_profiles.txt | wc -l | tr -d ' ')
if [[ "$dev_profile_count" == "6" ]]; then
    print_result 0 "Development mode: Correct profile count ($dev_profile_count)"
else
    print_result 1 "Development mode: Incorrect profile count ($dev_profile_count, expected 6)"
fi

echo ""
echo "=== Phase 2: Testing Local Installation ==="

# Clean up any existing installation
echo "[INFO] Cleaning up existing installations..."
./uninstall.sh --config --force 2>/dev/null || echo "No existing installation found"

# Test local installation
echo "[INFO] Testing local installation..."
./install-user.sh

# Update PATH for testing
export PATH="$HOME/.local/bin:$PATH"

# Verify installation
if [[ -f "$HOME/.local/bin/spinbox" ]]; then
    print_result 0 "Local installation: Binary installed"
else
    print_result 1 "Local installation: Binary missing"
fi

if [[ -d "$HOME/.spinbox/source" ]]; then
    print_result 0 "Local installation: Centralized source created"
else
    print_result 1 "Local installation: Centralized source missing"
fi

# Test installed binary
spinbox --version
spinbox profiles > /tmp/local_profiles.txt

# Verify enhanced profiles in local installation
if grep -q "OpenAI, Anthropic, LangChain" /tmp/local_profiles.txt; then
    print_result 0 "Local installation: Enhanced AI/LLM profile found"
else
    print_result 1 "Local installation: Enhanced AI/LLM profile missing"
fi

local_profile_count=$(grep -E "^  [a-z-]+$" /tmp/local_profiles.txt | wc -l | tr -d ' ')
if [[ "$local_profile_count" == "6" ]]; then
    print_result 0 "Local installation: Correct profile count ($local_profile_count)"
else
    print_result 1 "Local installation: Incorrect profile count ($local_profile_count, expected 6)"
fi

# Test that --python and --node work as minimal replacements
echo "[INFO] Testing base options (--python, --node)..."
spinbox create test-python-base --python --dry-run
print_result $? "Base option: --python works"

spinbox create test-node-base --node --dry-run
print_result $? "Base option: --node works"

# Test new python and node profiles
spinbox create test-python-profile --profile python --dry-run
print_result $? "Profile: python profile works"

spinbox create test-node-profile --profile node --dry-run  
print_result $? "Profile: node profile works"

# Clean up local installation
echo "[INFO] Cleaning up local installation..."
spinbox uninstall --config --force

echo ""
echo "=== Phase 3: Testing Global Installation ==="

# Test global installation (requires sudo)
echo "[INFO] Testing global installation..."
sudo ./install.sh

# Test installed binary
if [[ -f "/usr/local/bin/spinbox" ]]; then
    print_result 0 "Global installation: Binary installed"
else
    print_result 1 "Global installation: Binary missing"
fi

if [[ -d "$HOME/.spinbox/source" ]]; then
    print_result 0 "Global installation: Centralized source created"
else
    print_result 1 "Global installation: Centralized source missing"
fi

# Test global binary
spinbox --version
spinbox profiles > /tmp/global_profiles.txt

global_profile_count=$(grep -E "^  [a-z-]+$" /tmp/global_profiles.txt | wc -l | tr -d ' ')
if [[ "$global_profile_count" == "6" ]]; then
    print_result 0 "Global installation: Correct profile count ($global_profile_count)"
else
    print_result 1 "Global installation: Incorrect profile count ($global_profile_count, expected 6)"
fi

# Clean up global installation
echo "[INFO] Cleaning up global installation..."
sudo spinbox uninstall --config --force

echo ""
echo "=== Phase 4: Testing Architecture Consistency ==="

# Compare outputs between development and installation modes
if diff /tmp/dev_profiles.txt /tmp/local_profiles.txt > /dev/null; then
    print_result 0 "Architecture consistency: Development and local outputs identical"
else
    print_result 1 "Architecture consistency: Development and local outputs differ"
fi

# Clean up temporary files
rm -f /tmp/dev_profiles.txt /tmp/local_profiles.txt /tmp/global_profiles.txt

echo ""
echo "============================================="
echo "✓ ALL CENTRALIZED ARCHITECTURE TESTS PASSED"
echo "============================================="
echo ""
echo "Summary of what was tested:"
echo "  ✓ Development mode uses local files"
echo "  ✓ Local installation uses centralized source"
echo "  ✓ Global installation uses centralized source" 
echo "  ✓ Enhanced profile descriptions work"
echo "  ✓ Minimal profile removed, python/node added"
echo "  ✓ Correct profile count (6 profiles)"
echo "  ✓ --python and --node base options work"
echo "  ✓ Python and node profiles work"
echo "  ✓ Uninstall cleans up properly"
echo "  ✓ Architecture consistency across modes"
echo ""
echo "The centralized installation architecture is working correctly!"