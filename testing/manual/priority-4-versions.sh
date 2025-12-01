#!/bin/bash
# Priority 4: Version Override Tests
# Python, Node.js, PostgreSQL, and Redis version overrides
# Tests CLI version flags with various combinations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SPINBOX_CMD="$PROJECT_ROOT/bin/spinbox"
TEST_DIR="/tmp"

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
    echo -e "${YELLOW}Running in dry-run mode${NC}"
fi

# Test tracking
TOTAL=0
PASSED=0
FAILED=0

log_test() {
    local name="$1"
    local status="$2"
    ((TOTAL++))
    if [[ "$status" == "PASS" ]]; then
        ((PASSED++))
        echo -e "${GREEN}✓${NC} $name"
    else
        ((FAILED++))
        echo -e "${RED}✗${NC} $name"
    fi
}

run_test() {
    local name="$1"
    local project="$2"
    shift 2
    local flags="$@"

    echo -e "\n${BLUE}Testing:${NC} $name"
    echo "  Command: spinbox create $project $flags $DRY_RUN"

    cd "$TEST_DIR"
    if $SPINBOX_CMD create "$project" $flags $DRY_RUN 2>&1; then
        log_test "$name" "PASS"
        [[ -z "$DRY_RUN" ]] && rm -rf "$TEST_DIR/$project"
    else
        log_test "$name" "FAIL"
    fi
}

cleanup() {
    echo -e "\n${BLUE}Cleaning up test projects...${NC}"
    rm -rf "$TEST_DIR"/test-p4-* 2>/dev/null || true
}

trap cleanup EXIT

echo "============================================="
echo "Priority 4: Version Override Tests (6 scenarios)"
echo "============================================="

# P4.1 Python Version Overrides
echo -e "\n${YELLOW}=== P4.1 Python Versions ===${NC}"
run_test "Python 3.11" "test-p4-py311" --python --python-version 3.11
run_test "FastAPI + Python 3.12" "test-p4-py312" --fastapi --python-version 3.12

# P4.2 Node Version Overrides
echo -e "\n${YELLOW}=== P4.2 Node.js Versions ===${NC}"
run_test "Node.js 20" "test-p4-node20" --node --node-version 20
run_test "Next.js + Node 22" "test-p4-node22" --nextjs --node-version 22

# P4.3 Database Version Overrides
echo -e "\n${YELLOW}=== P4.3 Database Versions ===${NC}"
run_test "PostgreSQL 15" "test-p4-pg15" --fastapi --postgresql --postgres-version 15
run_test "Redis 7" "test-p4-redis7" --fastapi --redis --redis-version 7

# Summary
echo ""
echo "============================================="
echo "Priority 4 Results"
echo "============================================="
echo "Total: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [[ $FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}All Priority 4 tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed${NC}"
    exit 1
fi
