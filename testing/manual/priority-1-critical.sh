#!/bin/bash
# Priority 1: Critical Path Tests
# Base runtimes, profiles, and single database additions
# These are the most common user scenarios - MUST TEST

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
        # Cleanup if not dry-run
        [[ -z "$DRY_RUN" ]] && rm -rf "$TEST_DIR/$project"
    else
        log_test "$name" "FAIL"
    fi
}

cleanup() {
    echo -e "\n${BLUE}Cleaning up test projects...${NC}"
    rm -rf "$TEST_DIR"/test-p1-* 2>/dev/null || true
}

trap cleanup EXIT

echo "============================================="
echo "Priority 1: Critical Path Tests (12 scenarios)"
echo "============================================="

# P1.1 Base Runtimes Only
echo -e "\n${YELLOW}=== P1.1 Base Runtimes ===${NC}"
run_test "Python base" "test-p1-python" --python
run_test "Node.js base" "test-p1-node" --node

# P1.2 Profile-Based Projects
echo -e "\n${YELLOW}=== P1.2 Profiles ===${NC}"
run_test "Profile: python" "test-p1-profile-python" --profile python
run_test "Profile: node" "test-p1-profile-node" --profile node
run_test "Profile: web-app" "test-p1-profile-webapp" --profile web-app
run_test "Profile: api-only" "test-p1-profile-api" --profile api-only
run_test "Profile: data-science" "test-p1-profile-ds" --profile data-science
run_test "Profile: ai-llm" "test-p1-profile-ai" --profile ai-llm

# P1.3 Single Database Additions
echo -e "\n${YELLOW}=== P1.3 Single Database ===${NC}"
run_test "Python + PostgreSQL" "test-p1-py-pg" --python --postgresql
run_test "Python + MongoDB" "test-p1-py-mongo" --python --mongodb
run_test "Node + PostgreSQL" "test-p1-node-pg" --node --postgresql
run_test "Node + MongoDB" "test-p1-node-mongo" --node --mongodb

# Summary
echo ""
echo "============================================="
echo "Priority 1 Results"
echo "============================================="
echo "Total: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [[ $FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}All Priority 1 tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some tests failed${NC}"
    exit 1
fi
