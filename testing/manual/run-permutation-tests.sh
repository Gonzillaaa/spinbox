#!/bin/bash
# Unified runner for permutation testing
# Runs both generation and analysis in one go

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Parse arguments
SKIP_ANALYSIS=false
OPEN_DIRECTORY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-analysis)
            SKIP_ANALYSIS=true
            shift
            ;;
        --open)
            OPEN_DIRECTORY=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Options:"
            echo "  --skip-analysis    Skip the automatic analysis after generation"
            echo "  --open            Open the test directory in Finder/file manager after completion"
            echo "  -h, --help        Show this help message"
            echo
            echo "This script runs comprehensive permutation tests for Spinbox to detect"
            echo "structural bugs across all component combinations."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run '$0 --help' for usage information"
            exit 1
            ;;
    esac
done

# Header
echo -e "${GREEN}========================================"
echo "Spinbox Permutation Test Runner"
echo "========================================"
echo -e "${NC}"

# Check if generator script exists
if [[ ! -x "$SCRIPT_DIR/generate-all-permutations.sh" ]]; then
    echo -e "${RED}Error: generate-all-permutations.sh not found or not executable${NC}"
    exit 1
fi

# Check if analyzer script exists
if [[ ! -x "$SCRIPT_DIR/analyze-permutations.sh" ]] && [[ "$SKIP_ANALYSIS" == false ]]; then
    echo -e "${RED}Error: analyze-permutations.sh not found or not executable${NC}"
    exit 1
fi

# Save starting directory
START_DIR=$(pwd)

# Step 1: Generate all permutations
echo -e "${YELLOW}Step 1: Generating all permutations...${NC}"
echo

# Run the generator and capture the test directory path
OUTPUT=$("$SCRIPT_DIR/generate-all-permutations.sh" 2>&1)
echo "$OUTPUT"

# Extract test directory path from output
TEST_DIR=$(echo "$OUTPUT" | grep "Test directory created at:" | sed 's/Test directory created at: //')

if [[ -z "$TEST_DIR" ]] || [[ ! -d "$TEST_DIR" ]]; then
    echo -e "${RED}Error: Could not find test directory${NC}"
    exit 1
fi

echo
echo -e "${GREEN}✅ Permutation generation complete!${NC}"
echo

# Step 2: Run analysis (unless skipped)
if [[ "$SKIP_ANALYSIS" == false ]]; then
    echo -e "${YELLOW}Step 2: Running analysis...${NC}"
    echo
    
    "$SCRIPT_DIR/analyze-permutations.sh" "$TEST_DIR"
    
    echo
    echo -e "${GREEN}✅ Analysis complete!${NC}"
else
    echo -e "${YELLOW}Skipping analysis as requested${NC}"
fi

# Summary
echo
echo -e "${GREEN}========================================"
echo "Test Complete!"
echo "========================================"
echo -e "${NC}"
echo "Test directory: $TEST_DIR"
echo
echo "Next steps:"
echo "1. Review flagged issues from the analysis above"
echo "2. Navigate to test directory:"
echo "   cd $(basename "$TEST_DIR")"
echo "3. Manually inspect projects with potential issues"
echo "4. Document bugs in MASTER-CHECKLIST.md"
echo

# Extract counts from log
if [[ -f "$TEST_DIR/test-results.log" ]]; then
    SUCCESS_COUNT=$(grep -c "✅ SUCCESS:" "$TEST_DIR/test-results.log" || echo 0)
    FAILED_COUNT=$(grep -c "❌ FAILED:" "$TEST_DIR/test-results.log" || echo 0)
    
    echo "Test Statistics:"
    echo "  Successful: $SUCCESS_COUNT"
    echo "  Failed: $FAILED_COUNT"
    echo "  Total: $((SUCCESS_COUNT + FAILED_COUNT))"
    echo
fi

# Open directory if requested
if [[ "$OPEN_DIRECTORY" == true ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        open "$TEST_DIR"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v xdg-open &> /dev/null; then
            xdg-open "$TEST_DIR"
        else
            echo -e "${YELLOW}Note: Could not open file manager. Please navigate manually.${NC}"
        fi
    fi
fi

# Return to starting directory
cd "$START_DIR"

# Exit with appropriate code
if [[ -f "$TEST_DIR/failed-tests.log" ]] && [[ -s "$TEST_DIR/failed-tests.log" ]]; then
    echo -e "${YELLOW}⚠️  Some tests failed. Check failed-tests.log for details.${NC}"
    exit 1
else
    echo -e "${GREEN}🎉 All tests completed successfully!${NC}"
    exit 0
fi