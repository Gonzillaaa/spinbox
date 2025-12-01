#!/bin/bash
# Run All Manual Tests
# Executes all priority test scripts in sequence

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
DRY_RUN=""
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
    echo -e "${YELLOW}Running all tests in dry-run mode${NC}"
fi

echo "============================================="
echo "Spinbox Manual Test Suite"
echo "============================================="
echo ""
echo "This will run all 40 test scenarios across 4 priority levels."
echo ""

# Track overall results
TOTAL_PASSED=0
TOTAL_FAILED=0

run_priority() {
    local script="$1"
    local name="$2"

    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}Running: $name${NC}"
    echo -e "${BLUE}========================================${NC}"

    if "$SCRIPT_DIR/$script" $DRY_RUN; then
        echo -e "${GREEN}$name completed successfully${NC}"
        return 0
    else
        echo -e "${RED}$name had failures${NC}"
        return 1
    fi
}

# Run each priority level
if run_priority "priority-1-critical.sh" "Priority 1: Critical Path"; then
    TOTAL_PASSED=$((TOTAL_PASSED + 1))
else
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi

if run_priority "priority-2-common.sh" "Priority 2: Common Combinations"; then
    TOTAL_PASSED=$((TOTAL_PASSED + 1))
else
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi

if run_priority "priority-3-edge-cases.sh" "Priority 3: Edge Cases"; then
    TOTAL_PASSED=$((TOTAL_PASSED + 1))
else
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi

if run_priority "priority-4-versions.sh" "Priority 4: Version Overrides"; then
    TOTAL_PASSED=$((TOTAL_PASSED + 1))
else
    TOTAL_FAILED=$((TOTAL_FAILED + 1))
fi

# Final Summary
echo ""
echo "============================================="
echo "Overall Test Suite Results"
echo "============================================="
echo ""
echo "Priority Levels Passed: $TOTAL_PASSED/4"
echo "Priority Levels Failed: $TOTAL_FAILED/4"
echo ""

if [[ $TOTAL_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All test priorities passed!${NC}"
    exit 0
else
    echo -e "${RED}Some test priorities had failures${NC}"
    exit 1
fi
