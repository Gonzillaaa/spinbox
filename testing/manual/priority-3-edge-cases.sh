#!/bin/bash
# Priority 3: Edge Case Tests
# Multi-database scenarios, Node.js advanced, cache-only, vector DB combinations
# Less common but valid combinations

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
    rm -rf "$TEST_DIR"/test-p3-* 2>/dev/null || true
}

trap cleanup EXIT

echo "============================================="
echo "Priority 3: Edge Cases (10 scenarios)"
echo "============================================="

# P3.1 Multi-Database Scenarios
echo -e "\n${YELLOW}=== P3.1 Multi-Database ===${NC}"
run_test "FastAPI + PostgreSQL + MongoDB" "test-p3-multi-db" --fastapi --postgresql --mongodb
run_test "FastAPI + All Databases" "test-p3-all-db" --fastapi --postgresql --mongodb --redis

# P3.2 Node.js Advanced
echo -e "\n${YELLOW}=== P3.2 Node.js Advanced ===${NC}"
run_test "Node + Redis" "test-p3-node-redis" --node --redis
run_test "Next.js + Redis" "test-p3-nextjs-redis" --nextjs --redis
run_test "Next.js + PostgreSQL + Redis" "test-p3-nextjs-pg-redis" --nextjs --postgresql --redis

# P3.3 Cache-Only Additions
echo -e "\n${YELLOW}=== P3.3 Cache-Only ===${NC}"
run_test "Python + Redis only" "test-p3-py-redis" --python --redis
run_test "FastAPI + Redis only" "test-p3-fastapi-redis" --fastapi --redis

# P3.4 Vector DB Combinations
echo -e "\n${YELLOW}=== P3.4 Vector DB ===${NC}"
run_test "FastAPI + Chroma + PostgreSQL" "test-p3-chroma-pg" --fastapi --chroma --postgresql
run_test "FastAPI + Chroma + MongoDB" "test-p3-chroma-mongo" --fastapi --chroma --mongodb
run_test "FastAPI + Chroma + All" "test-p3-chroma-all" --fastapi --chroma --postgresql --redis

# Summary
echo ""
echo "============================================="
echo "Priority 3 Results"
echo "============================================="
echo "Total: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [[ $FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}All Priority 3 tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed${NC}"
    exit 1
fi
