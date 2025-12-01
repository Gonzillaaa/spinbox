#!/bin/bash
# Priority 2: Common Combination Tests
# FastAPI/Next.js with databases, full-stack, AI/ML combinations
# Realistic user scenarios with multiple services

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
    rm -rf "$TEST_DIR"/test-p2-* 2>/dev/null || true
}

trap cleanup EXIT

echo "============================================="
echo "Priority 2: Common Combinations (12 scenarios)"
echo "============================================="

# P2.1 FastAPI with Databases
echo -e "\n${YELLOW}=== P2.1 FastAPI + Databases ===${NC}"
run_test "FastAPI + PostgreSQL" "test-p2-fastapi-pg" --fastapi --postgresql
run_test "FastAPI + MongoDB" "test-p2-fastapi-mongo" --fastapi --mongodb
run_test "FastAPI + Redis" "test-p2-fastapi-redis" --fastapi --redis
run_test "FastAPI + PostgreSQL + Redis" "test-p2-fastapi-pg-redis" --fastapi --postgresql --redis

# P2.2 Next.js with Databases
echo -e "\n${YELLOW}=== P2.2 Next.js + Databases ===${NC}"
run_test "Next.js + PostgreSQL" "test-p2-nextjs-pg" --nextjs --postgresql
run_test "Next.js + MongoDB" "test-p2-nextjs-mongo" --nextjs --mongodb

# P2.3 Full-Stack Combinations
echo -e "\n${YELLOW}=== P2.3 Full-Stack ===${NC}"
run_test "Full-stack + PostgreSQL" "test-p2-fullstack-pg" --fastapi --nextjs --postgresql
run_test "Full-stack + MongoDB" "test-p2-fullstack-mongo" --fastapi --nextjs --mongodb
run_test "Full-stack + All Services" "test-p2-fullstack-all" --fastapi --nextjs --postgresql --redis

# P2.4 AI/ML Combinations
echo -e "\n${YELLOW}=== P2.4 AI/ML ===${NC}"
run_test "Python + Chroma" "test-p2-ai-basic" --python --chroma
run_test "FastAPI + PostgreSQL + Chroma" "test-p2-ai-pg" --fastapi --postgresql --chroma
run_test "FastAPI + All AI Stack" "test-p2-ai-full" --fastapi --postgresql --redis --chroma

# Summary
echo ""
echo "============================================="
echo "Priority 2 Results"
echo "============================================="
echo "Total: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [[ $FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}All Priority 2 tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed${NC}"
    exit 1
fi
