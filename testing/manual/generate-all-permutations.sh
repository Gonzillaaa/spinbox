#!/bin/bash
# Comprehensive Permutation Testing Script for Spinbox
# Generates all possible combinations to manually test for structural bugs

set -uo pipefail  # Removed -e to prevent script exit on non-critical errors

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

# Configuration
TEST_DIR_NAME="spinbox-permutation-test-$(date +%Y%m%d-%H%M%S)"
TEST_ROOT="$(pwd)/$TEST_DIR_NAME"
SPINBOX="$PROJECT_ROOT/bin/spinbox"
LOG_FILE="$TEST_ROOT/test-results.log"
FAILED_FILE="$TEST_ROOT/failed-tests.log"
SUCCESS_COUNT=0
FAILED_COUNT=0
TEST_COUNT=0

# Create test directory in current location
mkdir -p "$TEST_ROOT"
cd "$TEST_ROOT"

# Logging functions
log_test() {
    local test_name="$1"
    local command="$2"
    echo "[$test_name] $command" | tee -a "$LOG_FILE"
}

log_success() {
    local test_name="$1"
    echo "✅ SUCCESS: $test_name" | tee -a "$LOG_FILE"
    ((SUCCESS_COUNT++))
}

log_failure() {
    local test_name="$1"
    local error="$2"
    echo "❌ FAILED: $test_name - $error" | tee -a "$LOG_FILE" "$FAILED_FILE"
    ((FAILED_COUNT++))
}

# Test execution function
run_test() {
    local test_name="$1"
    local project_name="$2"
    shift 2
    local flags=("$@")
    
    ((TEST_COUNT++))
    echo "🔄 Progress: Test $TEST_COUNT - $test_name | Success: $SUCCESS_COUNT | Failed: $FAILED_COUNT"
    
    local command="$SPINBOX create $project_name ${flags[*]}"
    log_test "$test_name" "$command"
    
    if $command 2>&1 | tee -a "$LOG_FILE"; then
        log_success "$test_name"
        
        # Create inspection checklist for this project (only if directory exists)
        if [[ -d "$project_name" ]]; then
            # Pre-generate component verification list (fix for command substitution issue)
            local component_checks=""
            for flag in "${flags[@]}"; do
                component_checks+="- [ ] $flag component correctly generated"$'\n'
            done
            
            cat > "$project_name/INSPECT.md" << EOF
# Manual Inspection Checklist for: $test_name

**Command**: \`$command\`

## Directory Structure
- [ ] Correct root-level files (no unwanted components)
- [ ] Proper subdirectory organization
- [ ] No duplicate or conflicting directories

## Component Verification
$component_checks

## File Placement
- [ ] Application files in correct location (root vs subdirectories)
- [ ] Configuration files properly placed
- [ ] No missing essential files

## DevContainer
- [ ] .devcontainer/devcontainer.json exists and is valid
- [ ] Dockerfile appropriate for selected components
- [ ] Port forwarding correct

## Docker Compose (if applicable)
- [ ] All selected services included
- [ ] No duplicate service definitions
- [ ] Proper networking configuration

## Dependencies
- [ ] requirements.txt/package.json appropriate for components
- [ ] No conflicting dependencies
- [ ] Version specifications reasonable

## Documentation
- [ ] README accurate for generated project
- [ ] Instructions match actual structure
EOF
        fi
    else
        log_failure "$test_name" "Command failed"
    fi
    
    echo "---" | tee -a "$LOG_FILE"
    echo "✅ Completed: Test $TEST_COUNT - $test_name"
    echo
}

# Print header
echo "========================================"
echo "Spinbox Permutation Testing"
echo "Test Directory: $TEST_ROOT"
echo "Started: $(date)"
echo "========================================"
echo

# =================
# 1. SINGLE COMPONENT TESTS
# =================
echo "### TESTING SINGLE COMPONENTS ###"
echo

# Base components
run_test "Python Only" "01-python-only" --python
run_test "Node Only" "02-node-only" --node

# Application components (these should include their base)
run_test "FastAPI Only" "03-fastapi-only" --fastapi
run_test "NextJS Only" "04-nextjs-only" --nextjs

# Database components (should these work alone?)
run_test "PostgreSQL Only" "05-postgresql-only" --postgresql
run_test "MongoDB Only" "06-mongodb-only" --mongodb
run_test "Redis Only" "07-redis-only" --redis
run_test "Chroma Only" "08-chroma-only" --chroma

# =================
# 2. TWO-COMPONENT COMBINATIONS
# =================
echo
echo "### TESTING TWO-COMPONENT COMBINATIONS ###"
echo

# Base + Application
run_test "Python + FastAPI" "10-python-fastapi" --python --fastapi
run_test "Python + NextJS" "11-python-nextjs" --python --nextjs
run_test "Node + FastAPI" "12-node-fastapi" --node --fastapi
run_test "Node + NextJS" "13-node-nextjs" --node --nextjs

# Application combos
run_test "FastAPI + NextJS" "14-fastapi-nextjs" --fastapi --nextjs

# Application + Each Database
for app in fastapi nextjs; do
    for db in postgresql mongodb redis chroma; do
        run_test "${app^} + ${db^}" "15-$app-$db" --$app --$db
    done
done

# Database pairs (do these make sense?)
run_test "PostgreSQL + Redis" "20-postgresql-redis" --postgresql --redis
run_test "MongoDB + Redis" "21-mongodb-redis" --mongodb --redis
run_test "PostgreSQL + Chroma" "22-postgresql-chroma" --postgresql --chroma

# =================
# 3. THREE-COMPONENT COMBINATIONS
# =================
echo
echo "### TESTING THREE-COMPONENT COMBINATIONS ###"
echo

# Full stack with each database
for db in postgresql mongodb; do
    run_test "FastAPI + NextJS + ${db^}" "30-fastapi-nextjs-$db" --fastapi --nextjs --$db
done

# Backend with multiple databases
run_test "FastAPI + PostgreSQL + Redis" "31-fastapi-postgresql-redis" --fastapi --postgresql --redis
run_test "FastAPI + MongoDB + Redis" "32-fastapi-mongodb-redis" --fastapi --mongodb --redis

# AI/ML stack combinations
run_test "Python + PostgreSQL + Chroma" "33-python-postgresql-chroma" --python --postgresql --chroma
run_test "FastAPI + PostgreSQL + Chroma" "34-fastapi-postgresql-chroma" --fastapi --postgresql --chroma

# =================
# 4. FOUR+ COMPONENT COMBINATIONS
# =================
echo
echo "### TESTING COMPLEX MULTI-COMPONENT PROJECTS ###"
echo

# Full stack with caching
run_test "Full Stack + Cache" "40-fullstack-cache" --fastapi --nextjs --postgresql --redis
run_test "Full Stack Mongo + Cache" "41-fullstack-mongo-cache" --fastapi --nextjs --mongodb --redis

# AI/ML full stack
run_test "AI/ML Full Stack" "42-ai-fullstack" --fastapi --nextjs --postgresql --chroma

# Everything but the kitchen sink
run_test "Maximum Components" "43-everything" --fastapi --nextjs --postgresql --redis --chroma

# =================
# 5. FEATURE FLAG VARIATIONS
# =================
echo
echo "### TESTING FEATURE FLAGS ###"
echo

# Single component with flags
run_test "Python + Dependencies" "50-python-deps" --python --with-deps
run_test "Python + Docker Hub" "51-python-dockerhub" --python --docker-hub
run_test "Python + Both Flags" "52-python-both" --python --with-deps --docker-hub

# Complex project with flags
run_test "Full Stack + Dependencies" "53-fullstack-deps" --fastapi --nextjs --postgresql --with-deps
run_test "Full Stack + Docker Hub" "54-fullstack-dockerhub" --fastapi --nextjs --postgresql --docker-hub
run_test "Full Stack + Both Flags" "55-fullstack-both" --fastapi --nextjs --postgresql --with-deps --docker-hub

# =================
# 6. PROFILE TESTS
# =================
echo
echo "### TESTING PROFILES ###"
echo

for profile in web-app api-only data-science ai-llm python node; do
    run_test "Profile: $profile" "60-profile-$profile" --profile $profile
done

# Profile with additional components
run_test "Web App Profile + Redis" "61-webapp-redis" --profile web-app --redis
run_test "API Profile + MongoDB" "62-api-mongodb" --profile api-only --mongodb

# Profile with flags
run_test "Data Science + Docker Hub" "63-datascience-dockerhub" --profile data-science --docker-hub
run_test "AI/LLM + Dependencies" "64-aillm-deps" --profile ai-llm --with-deps

# =================
# 7. EDGE CASES
# =================
echo
echo "### TESTING EDGE CASES ###"
echo

# Potentially conflicting combinations
run_test "All Databases" "70-all-databases" --postgresql --mongodb --redis --chroma
run_test "Python + Node Together" "71-python-node" --python --node
run_test "Redundant Base + App" "72-node-nextjs-explicit" --node --nextjs

# =================
# SUMMARY REPORT
# =================
echo
echo "========================================"
echo "TEST SUMMARY"
echo "========================================"
echo "Total Tests: $((SUCCESS_COUNT + FAILED_COUNT))"
echo "Successful: $SUCCESS_COUNT"
echo "Failed: $FAILED_COUNT"
echo
echo "Test Directory: $TEST_ROOT"
echo "Log File: $LOG_FILE"
if [[ $FAILED_COUNT -gt 0 ]]; then
    echo "Failed Tests: $FAILED_FILE"
fi
echo

# Create master inspection checklist
cat > "$TEST_ROOT/MASTER-CHECKLIST.md" << EOF
# Master Inspection Checklist

**Test Run**: $(date)
**Total Projects**: $((SUCCESS_COUNT + FAILED_COUNT))
**Successful**: $SUCCESS_COUNT
**Failed**: $FAILED_COUNT

## Known Bugs to Look For

1. **Dual Application Generation** (like Next.js bug)
   - Component creates both intended and unintended base projects
   - Check: 04-nextjs-only, 13-node-nextjs

2. **Missing Base Dependencies**
   - Component doesn't properly set up required base
   - Check: 03-fastapi-only, 04-nextjs-only

3. **Directory Structure Issues**
   - Components in wrong directories (root vs subdirectories)
   - Files overwriting each other
   - Check all multi-component projects

4. **Configuration Conflicts**
   - DevContainer configs incompatible
   - Docker Compose service conflicts
   - Check: 30-*, 40-*, 43-everything

5. **Dependency Issues**
   - Missing or conflicting package dependencies
   - Wrong package manager used
   - Check: 50-*, 53-*, 55-*

## Inspection Process

1. Navigate to each numbered directory
2. Review the INSPECT.md checklist
3. Look for structural anomalies
4. Compare similar projects for consistency
5. Note any bugs in this file

## Bug Report Template

\`\`\`
Project: [directory name]
Command: [spinbox command]
Bug: [description]
Expected: [what should happen]
Actual: [what actually happened]
Impact: [severity/user impact]
\`\`\`

## Bugs Found

[Document bugs here as you find them]

EOF

echo "Master checklist created at: $TEST_ROOT/MASTER-CHECKLIST.md"
echo
echo "Test directory created at: $TEST_ROOT"
echo
echo "To inspect results:"
echo "  cd $TEST_DIR_NAME"
echo "  ls -la"
echo "  # Check each directory and its INSPECT.md file"
echo
echo "To run analysis:"
echo "  $SCRIPT_DIR/analyze-permutations.sh $TEST_ROOT"
echo
echo "Happy bug hunting! 🐛🔍"