#!/bin/bash
# Real Project Creation Test Suite for Spinbox
# Tests actual file and directory generation (non-dry-run mode)
# Following CLAUDE.md principles: Simple, Fast, Essential Coverage

# Note: Not using set -e so tests can continue after failures

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SPINBOX_CMD="$PROJECT_ROOT/bin/spinbox"
TEST_DIR="/tmp/spinbox-creation-test-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
CREATED_PROJECTS=()

# Simple logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

# Test result tracking
record_test() {
    local test_name="$1"
    local result="$2"
    local message="$3"
    
    ((TOTAL_TESTS++))
    
    if [[ "$result" == "PASS" ]]; then
        ((PASSED_TESTS++))
        log_success "$test_name: $message"
    else
        ((FAILED_TESTS++))
        log_error "$test_name: $message"
    fi
}

# Test real project creation
test_real_project_creation() {
    local profile="$1"
    local test_name="$2"
    local expected_files="$3"
    
    log_info "Testing real project creation: $profile"
    
    local project_name="test-${test_name}-$$"
    local project_path="$TEST_DIR/$project_name"
    
    # Create project (NOT dry-run)
    cd "$TEST_DIR"
    if output=$("$SPINBOX_CMD" create "$project_name" --profile "$profile" 2>&1); then
        record_test "${test_name}_creation" "PASS" "Project created successfully"
        CREATED_PROJECTS+=("$project_path")
        
        # Test project directory exists
        if [[ -d "$project_path" ]]; then
            record_test "${test_name}_directory" "PASS" "Project directory created"
            
            # Test expected files exist
            cd "$project_path"
            local files_found=true
            IFS=' ' read -ra FILES <<< "$expected_files"
            for file in "${FILES[@]}"; do
                if [[ -f "$file" || -d "$file" ]]; then
                    record_test "${test_name}_file_${file//\//_}" "PASS" "File/directory $file exists"
                else
                    record_test "${test_name}_file_${file//\//_}" "FAIL" "Missing expected file/directory: $file"
                    files_found=false
                fi
            done
            
            # Test DevContainer configuration
            if [[ -f ".devcontainer/devcontainer.json" ]]; then
                record_test "${test_name}_devcontainer" "PASS" "DevContainer configuration created"
                
                # Validate JSON syntax
                if python3 -m json.tool ".devcontainer/devcontainer.json" >/dev/null 2>&1; then
                    record_test "${test_name}_devcontainer_valid_json" "PASS" "DevContainer JSON is valid"
                else
                    record_test "${test_name}_devcontainer_valid_json" "FAIL" "DevContainer JSON is invalid"
                fi
            else
                record_test "${test_name}_devcontainer" "FAIL" "DevContainer configuration missing"
            fi
            
            # Test Docker Compose if expected
            if echo "$expected_files" | grep -q "docker-compose"; then
                if [[ -f "docker-compose.yml" ]]; then
                    record_test "${test_name}_docker_compose" "PASS" "Docker Compose file created"
                    
                    # Basic YAML validation - check for common YAML syntax issues
                    # Since yaml module may not be installed, use basic checks
                    if grep -E "^[[:space:]]*[^#[:space:]].*:$" docker-compose.yml >/dev/null && \
                       grep -E "^services:" docker-compose.yml >/dev/null && \
                       ! grep -E "^[[:space:]]*-[[:space:]]*$" docker-compose.yml >/dev/null; then
                        record_test "${test_name}_docker_compose_valid" "PASS" "Docker Compose YAML is valid"
                    else
                        record_test "${test_name}_docker_compose_valid" "FAIL" "Docker Compose YAML is invalid"
                    fi
                else
                    record_test "${test_name}_docker_compose" "FAIL" "Expected Docker Compose file missing"
                fi
            fi
            
            # Test requirements.txt for Python projects
            if echo "$profile" | grep -E "(python|web-app|api-only|data-science|ai-llm)" >/dev/null; then
                local requirements_path="requirements.txt"

                # For profiles that use FastAPI, requirements.txt is in backend/
                if echo "$profile" | grep -E "(web-app|api-only|ai-llm)" >/dev/null; then
                    requirements_path="backend/requirements.txt"
                fi

                if [[ -f "$requirements_path" ]]; then
                    record_test "${test_name}_requirements" "PASS" "Requirements.txt created at $requirements_path"

                    # Check requirements.txt has content
                    if [[ -s "$requirements_path" ]]; then
                        record_test "${test_name}_requirements_content" "PASS" "Requirements.txt has content"
                    else
                        record_test "${test_name}_requirements_content" "FAIL" "Requirements.txt is empty"
                    fi
                else
                    record_test "${test_name}_requirements" "FAIL" "Requirements.txt missing for Python project at $requirements_path"
                fi
            fi
            
            # Test package.json for Node projects
            if echo "$profile" | grep -E "(node|web-app)" >/dev/null; then
                local package_json_path="package.json"

                # For web-app profile, check in frontend subdirectory (multi-component project)
                if [[ "$profile" == "web-app" ]]; then
                    package_json_path="frontend/package.json"
                fi

                if [[ -f "$package_json_path" ]]; then
                    record_test "${test_name}_package_json" "PASS" "Package.json created at $package_json_path"

                    # Validate JSON syntax
                    if python3 -m json.tool "$package_json_path" >/dev/null 2>&1; then
                        record_test "${test_name}_package_json_valid" "PASS" "Package.json is valid JSON"
                    else
                        record_test "${test_name}_package_json_valid" "FAIL" "Package.json is invalid JSON"
                    fi
                else
                    record_test "${test_name}_package_json" "FAIL" "Package.json missing at $package_json_path"
                fi
            fi
            
            cd "$TEST_DIR"
        else
            record_test "${test_name}_directory" "FAIL" "Project directory not created"
        fi
    else
        record_test "${test_name}_creation" "FAIL" "Project creation failed: $output"
    fi
}

# Test component-based creation
test_component_creation() {
    local components="$1"
    local test_name="$2"
    
    log_info "Testing component-based creation: $components"
    
    local project_name="test-${test_name}-$$"
    local project_path="$TEST_DIR/$project_name"
    
    # Build CLI flags
    local flags=""
    IFS=' ' read -ra COMPS <<< "$components"
    for comp in "${COMPS[@]}"; do
        flags="$flags --${comp}"
    done
    
    cd "$TEST_DIR"
    if output=$("$SPINBOX_CMD" create "$project_name" $flags 2>&1); then
        record_test "${test_name}_creation" "PASS" "Component-based project created"
        CREATED_PROJECTS+=("$project_path")
        
        if [[ -d "$project_path" ]]; then
            record_test "${test_name}_directory" "PASS" "Project directory created"
            
            cd "$project_path"
            
            # Test basic structure exists
            local basic_files=(".devcontainer" ".gitignore" "README.md")
            for file in "${basic_files[@]}"; do
                if [[ -e "$file" ]]; then
                    record_test "${test_name}_basic_${file//\//_}" "PASS" "Basic file $file exists"
                else
                    record_test "${test_name}_basic_${file//\//_}" "FAIL" "Missing basic file: $file"
                fi
            done
            
            cd "$TEST_DIR"
        else
            record_test "${test_name}_directory" "FAIL" "Project directory not created"
        fi
    else
        record_test "${test_name}_creation" "FAIL" "Component-based creation failed: $output"
    fi
}

# Test project structure validation
validate_project_structure() {
    local project_path="$1"
    local test_name="$2"
    
    if [[ ! -d "$project_path" ]]; then
        record_test "${test_name}_structure_validation" "FAIL" "Project path doesn't exist"
        return 1
    fi
    
    cd "$project_path"
    
    # Check for proper directory structure
    local expected_dirs=()
    
    # All projects should have these
    if [[ -d ".devcontainer" ]]; then
        record_test "${test_name}_devcontainer_dir" "PASS" "DevContainer directory exists"
    else
        record_test "${test_name}_devcontainer_dir" "FAIL" "DevContainer directory missing"
    fi
    
    # Check for source code directories based on project type
    if [[ -f "requirements.txt" ]]; then
        # Python project
        if [[ -d "src" ]]; then
            record_test "${test_name}_python_src_dir" "PASS" "Python src directory exists"
        else
            record_test "${test_name}_python_src_dir" "FAIL" "Python src directory missing"
        fi
    fi
    
    if [[ -f "package.json" ]]; then
        # Node project - might have different structure
        record_test "${test_name}_node_structure" "PASS" "Node project structure detected"
    fi
    
    # Check for essential files
    local essential_files=(".gitignore" "README.md")
    for file in "${essential_files[@]}"; do
        if [[ -f "$file" ]]; then
            record_test "${test_name}_essential_${file//\//_}" "PASS" "Essential file $file exists"
        else
            record_test "${test_name}_essential_${file//\//_}" "FAIL" "Missing essential file: $file"
        fi
    done
}

# Cleanup function
cleanup() {
    log_info "Cleaning up created projects..."
    for project in "${CREATED_PROJECTS[@]}"; do
        if [[ -d "$project" ]]; then
            rm -rf "$project"
        fi
    done
    rm -rf "$TEST_DIR" 2>/dev/null || true
}

# Main execution
echo "============================================="
echo "Spinbox Real Project Creation Test Suite"
echo "============================================="
echo ""

# Verify spinbox command exists
if [[ ! -f "$SPINBOX_CMD" ]]; then
    log_error "Spinbox command not found at: $SPINBOX_CMD"
    exit 1
fi

# Check for required tools
if ! command -v python3 &> /dev/null; then
    log_warning "Python3 not found - JSON/YAML validation tests will be skipped"
fi

# Set up cleanup
trap cleanup EXIT

# Create test directory
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Test 1: Profile-based real project creation
log_info "=== Testing Profile-Based Real Project Creation ==="

# Test Python profile
test_real_project_creation "python" "python_profile" ".devcontainer src tests requirements.txt"

# Test web-app profile (if it includes multiple components)
# Note: FastAPI files are in backend/, Next.js files in frontend/
test_real_project_creation "web-app" "webapp_profile" ".devcontainer backend/app backend/requirements.txt frontend/package.json"

# Test api-only profile
# Note: FastAPI files are in backend/ directory
test_real_project_creation "api-only" "api_profile" ".devcontainer backend/app backend/requirements.txt docker-compose.yml"

echo ""

# Test 2: Component-based real project creation
log_info "=== Testing Component-Based Real Project Creation ==="

test_component_creation "python" "python_component"
test_component_creation "node" "node_component"  
test_component_creation "python fastapi" "python_fastapi"

echo ""

# Test 3: Project structure validation
log_info "=== Testing Project Structure Validation ==="

# Validate structure of created projects
for project in "${CREATED_PROJECTS[@]}"; do
    if [[ -d "$project" ]]; then
        project_name=$(basename "$project")
        validate_project_structure "$project" "$project_name"
    fi
done

echo ""

# Summary
echo "============================================="
echo "Real Project Creation Test Results"
echo "============================================="
echo ""
echo "Total Tests: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"
echo ""
echo "Projects created for testing: ${#CREATED_PROJECTS[@]}"

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}✓ ALL REAL PROJECT CREATION TESTS PASSED!${NC}"
    echo ""
    log_success "Real file/directory generation is working correctly"
    exit_code=0
else
    echo -e "${RED}✗ SOME REAL PROJECT CREATION TESTS FAILED${NC}"
    echo ""
    log_error "Issues found with actual file/directory generation"
    exit_code=1
fi

echo ""
echo "Real project creation analysis complete!"
echo ""

exit $exit_code