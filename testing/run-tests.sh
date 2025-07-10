#!/bin/bash
# Test Runner for Spinbox Testing Suite
# This script orchestrates running different types of tests

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Default values
TEST_TYPE=""
SUITE=""
COMPONENT=""
SCENARIO=""
FAST_MODE=false
VERBOSE=false
PRESERVE_ON_FAILURE=false
REPORT=false
OUTPUT_DIR=""

# Usage information
show_help() {
    cat << EOF
Spinbox Test Runner

Usage: $0 [OPTIONS]

Test Types:
  --unit              Run unit tests
  --integration       Run integration tests
  --e2e              Run end-to-end tests
  --performance      Run performance tests
  --compatibility    Run compatibility tests
  --all              Run all tests

Filters:
  --suite SUITE      Run specific unit test suite (utils, config, setup)
  --component COMP   Run tests for specific component (backend, frontend, database, etc.)
  --scenario SCENE   Run specific e2e scenario (new-project, existing-project, etc.)

Options:
  --fast             Run quick tests only (skip slow integration tests)
  --verbose          Enable verbose output
  --preserve         Preserve test environment on failure for debugging
  --report           Generate test reports
  --output DIR       Output directory for reports
  --help             Show this help message

Examples:
  $0 --unit --suite utils                    # Run utils unit tests
  $0 --integration --component backend       # Run backend integration tests
  $0 --e2e --scenario new-project           # Run new project E2E test
  $0 --all --fast                           # Run all fast tests
  $0 --unit --integration --verbose         # Run unit and integration tests with verbose output

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unit)
                TEST_TYPE="$TEST_TYPE unit"
                shift
                ;;
            --integration)
                TEST_TYPE="$TEST_TYPE integration"
                shift
                ;;
            --e2e)
                TEST_TYPE="$TEST_TYPE e2e"
                shift
                ;;
            --performance)
                TEST_TYPE="$TEST_TYPE performance"
                shift
                ;;
            --compatibility)
                TEST_TYPE="$TEST_TYPE compatibility"
                shift
                ;;
            --all)
                TEST_TYPE="unit integration e2e performance compatibility"
                shift
                ;;
            --suite)
                SUITE="$2"
                shift 2
                ;;
            --component)
                COMPONENT="$2"
                shift 2
                ;;
            --scenario)
                SCENARIO="$2"
                shift 2
                ;;
            --fast)
                FAST_MODE=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --preserve)
                PRESERVE_ON_FAILURE=true
                shift
                ;;
            --report)
                REPORT=true
                shift
                ;;
            --output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Set up test environment
setup_test_environment() {
    # Ensure we're in the project root
    cd "$PROJECT_ROOT" || {
        echo -e "${RED}Error: Cannot access project root directory${NC}"
        exit 1
    }
    
    # Check for required files
    if [[ ! -f "lib/utils.sh" || ! -f "lib/config.sh" ]]; then
        echo -e "${RED}Error: Missing required library files${NC}"
        exit 1
    fi
    
    # Create reports directory if needed
    if [[ "$REPORT" == true ]]; then
        OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/reports}"
        mkdir -p "$OUTPUT_DIR"/{junit,coverage,html}
    fi
    
    # Set environment variables for tests
    export TEST_VERBOSE="$VERBOSE"
    export TEST_PRESERVE_ON_FAILURE="$PRESERVE_ON_FAILURE"
    export TEST_FAST_MODE="$FAST_MODE"
}

# Check test dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for basic utilities
    for cmd in bash docker git; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Check for Docker daemon
    if ! docker info >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: Docker daemon not running - integration tests may fail${NC}"
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing required dependencies: ${missing_deps[*]}${NC}"
        exit 1
    fi
}

# Run unit tests
run_unit_tests() {
    local suite_filter="$1"
    local exit_code=0
    
    echo -e "${BLUE}Running Unit Tests${NC}"
    echo "==================="
    
    # Use the new simple test framework
    echo -e "\n${YELLOW}Running Spinbox core tests...${NC}"
    
    if [[ "$VERBOSE" == true ]]; then
        bash "$SCRIPT_DIR/quick-test.sh"
    else
        bash "$SCRIPT_DIR/quick-test.sh" 2>/dev/null
    fi
    
    local suite_exit_code=$?
    if [[ $suite_exit_code -ne 0 ]]; then
        echo -e "${RED}✗ Core functionality tests failed${NC}"
        exit_code=1
    else
        echo -e "${GREEN}✓ Core functionality tests passed${NC}"
    fi
    
    return $exit_code
}

# Run integration tests
run_integration_tests() {
    local component_filter="$1"
    local exit_code=0
    
    echo -e "${BLUE}Running Integration Tests${NC}"
    echo "========================="
    
    # Available integration test components
    local components=("backend" "frontend" "database" "devcontainer")
    
    # Filter components if specified
    if [[ -n "$component_filter" ]]; then
        if [[ " ${components[*]} " =~ " $component_filter " ]]; then
            components=("$component_filter")
        else
            echo -e "${RED}Error: Unknown component '$component_filter'${NC}"
            echo "Available components: ${components[*]}"
            return 1
        fi
    fi
    
    # Run each component test
    for component in "${components[@]}"; do
        local test_file="$SCRIPT_DIR/integration/test_${component}_setup.sh"
        
        if [[ -f "$test_file" ]]; then
            echo -e "\n${YELLOW}Running $component integration tests...${NC}"
            
            if [[ "$FAST_MODE" == true ]]; then
                # Skip slow integration tests in fast mode
                echo -e "${YELLOW}Skipping $component tests in fast mode${NC}"
                continue
            fi
            
            if [[ "$VERBOSE" == true ]]; then
                bash "$test_file"
            else
                bash "$test_file" 2>/dev/null
            fi
            
            local component_exit_code=$?
            if [[ $component_exit_code -ne 0 ]]; then
                echo -e "${RED}✗ $component integration tests failed${NC}"
                exit_code=1
            else
                echo -e "${GREEN}✓ $component integration tests passed${NC}"
            fi
        else
            echo -e "${YELLOW}Warning: Integration test not implemented: $component${NC}"
        fi
    done
    
    return $exit_code
}

# Run end-to-end tests
run_e2e_tests() {
    local scenario_filter="$1"
    local exit_code=0
    
    echo -e "${BLUE}Running End-to-End Tests${NC}"
    echo "========================"
    
    # Available E2E scenarios
    local scenarios=("new-project" "existing-project" "minimal-project" "all-components")
    
    # Filter scenarios if specified
    if [[ -n "$scenario_filter" ]]; then
        if [[ " ${scenarios[*]} " =~ " $scenario_filter " ]]; then
            scenarios=("$scenario_filter")
        else
            echo -e "${RED}Error: Unknown scenario '$scenario_filter'${NC}"
            echo "Available scenarios: ${scenarios[*]}"
            return 1
        fi
    fi
    
    # Run each scenario
    for scenario in "${scenarios[@]}"; do
        local test_file="$SCRIPT_DIR/e2e/test_${scenario//-/_}_workflow.sh"
        
        if [[ -f "$test_file" ]]; then
            echo -e "\n${YELLOW}Running $scenario E2E test...${NC}"
            
            if [[ "$FAST_MODE" == true && "$scenario" == "all-components" ]]; then
                echo -e "${YELLOW}Skipping all-components test in fast mode${NC}"
                continue
            fi
            
            if [[ "$VERBOSE" == true ]]; then
                bash "$test_file"
            else
                bash "$test_file" 2>/dev/null
            fi
            
            local scenario_exit_code=$?
            if [[ $scenario_exit_code -ne 0 ]]; then
                echo -e "${RED}✗ $scenario E2E test failed${NC}"
                exit_code=1
            else
                echo -e "${GREEN}✓ $scenario E2E test passed${NC}"
            fi
        else
            echo -e "${YELLOW}Warning: E2E test not implemented: $scenario${NC}"
        fi
    done
    
    return $exit_code
}

# Run performance tests
run_performance_tests() {
    echo -e "${BLUE}Running Performance Tests${NC}"
    echo "========================="
    
    if [[ "$FAST_MODE" == true ]]; then
        echo -e "${YELLOW}Skipping performance tests in fast mode${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Performance tests not yet implemented${NC}"
    return 0
}

# Run compatibility tests
run_compatibility_tests() {
    echo -e "${BLUE}Running Compatibility Tests${NC}"
    echo "==========================="
    
    if [[ "$FAST_MODE" == true ]]; then
        echo -e "${YELLOW}Skipping compatibility tests in fast mode${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}Compatibility tests not yet implemented${NC}"
    return 0
}

# Generate test report
generate_report() {
    if [[ "$REPORT" != true ]]; then
        return 0
    fi
    
    echo -e "\n${BLUE}Generating Test Reports${NC}"
    echo "======================="
    
    # Create summary report
    cat > "$OUTPUT_DIR/test-summary.txt" << EOF
Spinbox Test Suite Results
Generated: $(date)

Test Configuration:
- Test Types: $TEST_TYPE
- Fast Mode: $FAST_MODE
- Verbose: $VERBOSE

Test Results:
$(cat /tmp/spinbox-test-results.txt 2>/dev/null || echo "No detailed results available")
EOF
    
    echo -e "${GREEN}Test report generated: $OUTPUT_DIR/test-summary.txt${NC}"
}

# Main execution function
main() {
    local overall_exit_code=0
    
    echo "======================================="
    echo "Spinbox Test Suite Runner"
    echo "======================================="
    echo "Timestamp: $(date)"
    echo "Fast Mode: $FAST_MODE"
    echo "Verbose: $VERBOSE"
    echo ""
    
    # Set up environment
    setup_test_environment
    check_dependencies
    
    # Default to unit tests if no type specified
    if [[ -z "$TEST_TYPE" ]]; then
        TEST_TYPE="unit"
    fi
    
    # Run specified test types
    for test_type in $TEST_TYPE; do
        case $test_type in
            unit)
                run_unit_tests "$SUITE"
                if [[ $? -ne 0 ]]; then
                    overall_exit_code=1
                fi
                ;;
            integration)
                run_integration_tests "$COMPONENT"
                if [[ $? -ne 0 ]]; then
                    overall_exit_code=1
                fi
                ;;
            e2e)
                run_e2e_tests "$SCENARIO"
                if [[ $? -ne 0 ]]; then
                    overall_exit_code=1
                fi
                ;;
            performance)
                run_performance_tests
                if [[ $? -ne 0 ]]; then
                    overall_exit_code=1
                fi
                ;;
            compatibility)
                run_compatibility_tests
                if [[ $? -ne 0 ]]; then
                    overall_exit_code=1
                fi
                ;;
            *)
                echo -e "${RED}Error: Unknown test type '$test_type'${NC}"
                overall_exit_code=1
                ;;
        esac
    done
    
    # Generate report if requested
    generate_report
    
    # Final summary
    echo ""
    echo "======================================="
    if [[ $overall_exit_code -eq 0 ]]; then
        echo -e "${GREEN}All tests completed successfully!${NC}"
    else
        echo -e "${RED}Some tests failed. Check output above for details.${NC}"
    fi
    echo "======================================="
    
    exit $overall_exit_code
}

# Parse arguments and run
parse_arguments "$@"
main