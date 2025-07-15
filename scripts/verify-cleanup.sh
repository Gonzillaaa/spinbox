#!/bin/bash
# Verify Test Cleanup Script
# Ensures all test scripts properly clean up after themselves

set -e

cd "$(dirname "$0")/.."

echo "🧹 Verifying Test Cleanup Mechanisms"
echo "====================================="

# Function to count test directories
count_test_dirs() {
    ls -la | grep "test-" | wc -l
}

# Test each script's cleanup
test_scripts=(
    "testing/cli-test.sh"
    "testing/simple-test.sh"
    "testing/quick-test.sh"
    "scripts/test-integration.sh"
)

echo ""
echo "Testing cleanup for individual scripts:"
echo "--------------------------------------"

for script in "${test_scripts[@]}"; do
    if [[ -f "$script" ]]; then
        echo "Testing: $script"
        
        # Run script and capture exit code
        if ./"$script" >/dev/null 2>&1; then
            exit_code=0
        else
            exit_code=$?
        fi
        
        # Check for leftover directories
        leftover_dirs=$(count_test_dirs)
        
        if [[ $leftover_dirs -eq 0 ]]; then
            echo "  ✅ Cleanup successful (exit code: $exit_code)"
        else
            echo "  ❌ Found $leftover_dirs leftover test directories"
            echo "  Cleaning up manually..."
            rm -rf test-* 2>/dev/null || true
        fi
    else
        echo "  ⚠️  Script not found: $script"
    fi
done

echo ""
echo "Final verification:"
echo "------------------"
final_count=$(count_test_dirs)
if [[ $final_count -eq 0 ]]; then
    echo "✅ All cleanup mechanisms working correctly!"
    echo "✅ No test directories remain in project root"
else
    echo "❌ Found $final_count test directories remaining"
    echo "🧹 Cleaning up..."
    rm -rf test-* 2>/dev/null || true
    echo "✅ Manual cleanup completed"
fi

echo ""
echo "🎯 Test cleanup verification complete!"