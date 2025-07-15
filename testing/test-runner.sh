#!/bin/bash
# Unified Test Runner for Spinbox Testing Infrastructure
# Single entry point for all test suites with clear options

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source test utilities
source "$SCRIPT_DIR/unit/test-utils.sh"

# Test suite paths
UNIT_TESTS="$SCRIPT_DIR/unit/core-functionality.sh"
INTEGRATION_CLI="$SCRIPT_DIR/integration/cli-integration.sh"
INTEGRATION_WORKFLOW="$SCRIPT_DIR/integration/workflow-scenarios.sh"
END_TO_END="$SCRIPT_DIR/end-to-end/installation-scenarios.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Help function
show_help() {
    cat << EOF
Spinbox Test Runner - Unified Testing Interface

USAGE:
    $(basename "$0") [OPTIONS]

OPTIONS:
    --unit              Run unit tests (core functionality)
    --integration       Run integration tests (CLI and workflows)
    --end-to-end        Run end-to-end tests (installation scenarios)
    --all               Run all test suites (default)
    --quick             Run only unit tests (fastest option)
    --help              Show this help message
    
INDIVIDUAL TEST SUITES:
    --core              Run core functionality tests only
    --cli               Run CLI integration tests only  
    --workflow          Run workflow scenario tests only
    --installation      Run installation scenario tests only

EXAMPLES:
    $(basename "$0")                    # Run all tests
    $(basename "$0") --unit             # Run unit tests only
    $(basename "$0") --integration      # Run integration tests only
    $(basename "$0") --quick            # Run core tests only (fastest)
    $(basename "$0") --core --cli       # Run specific test suites

NOTES:
    - Unit tests are fastest (< 10 seconds)
    - Integration tests require moderate time (< 2 minutes)
    - End-to-end tests may take longer (several minutes)
    - Use --quick for rapid development feedback

EOF
}

# Test suite execution functions
run_unit_tests() {
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${BLUE}             Running Unit Tests               ${NC}"
    echo -e "${BLUE}===============================================${NC}"
    
    if [[ -f "$UNIT_TESTS" ]]; then
        if bash "$UNIT_TESTS"; then
            echo -e "${GREEN}✓ Unit tests completed successfully${NC}"
            return 0
        else
            echo -e "${RED}✗ Unit tests failed${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Unit test file not found: $UNIT_TESTS${NC}"
        return 1
    fi
}

run_integration_tests() {
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${BLUE}           Running Integration Tests          ${NC}"
    echo -e "${BLUE}===============================================${NC}"
    
    local integration_passed=0
    local integration_total=0
    
    # Run CLI integration tests
    if [[ -f "$INTEGRATION_CLI" ]]; then
        echo -e "${YELLOW}--- CLI Integration Tests ---${NC}"
        ((integration_total++))
        if bash "$INTEGRATION_CLI"; then
            echo -e "${GREEN}✓ CLI integration tests passed${NC}"
            ((integration_passed++))
        else
            echo -e "${RED}✗ CLI integration tests failed${NC}"
        fi
    else
        echo -e "${RED}✗ CLI integration test file not found: $INTEGRATION_CLI${NC}"
    fi
    
    # Run workflow scenario tests
    if [[ -f "$INTEGRATION_WORKFLOW" ]]; then
        echo -e "${YELLOW}--- Workflow Scenario Tests ---${NC}"
        ((integration_total++))
        if bash "$INTEGRATION_WORKFLOW"; then
            echo -e "${GREEN}✓ Workflow scenario tests passed${NC}"
            ((integration_passed++))
        else
            echo -e "${RED}✗ Workflow scenario tests failed${NC}"
        fi
    else
        echo -e "${RED}✗ Workflow scenario test file not found: $INTEGRATION_WORKFLOW${NC}"
    fi
    
    # Report integration results
    if [[ $integration_passed -eq $integration_total && $integration_total -gt 0 ]]; then
        echo -e "${GREEN}✓ All integration tests completed successfully${NC}"
        return 0
    else
        echo -e "${RED}✗ Integration tests failed ($integration_passed/$integration_total passed)${NC}"
        return 1
    fi
}

run_end_to_end_tests() {
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${BLUE}          Running End-to-End Tests           ${NC}"
    echo -e "${BLUE}===============================================${NC}"
    
    if [[ -f "$END_TO_END" ]]; then
        echo -e "${YELLOW}--- Installation Scenario Tests ---${NC}"
        if bash "$END_TO_END"; then
            echo -e "${GREEN}✓ End-to-end tests completed successfully${NC}"
            return 0
        else
            echo -e "${RED}✗ End-to-end tests failed${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ End-to-end test file not found: $END_TO_END${NC}"
        return 1
    fi
}

# Individual test suite runners
run_core_tests() {
    echo -e "${BLUE}Running Core Functionality Tests...${NC}"
    bash "$UNIT_TESTS"
}

run_cli_tests() {
    echo -e "${BLUE}Running CLI Integration Tests...${NC}"
    bash "$INTEGRATION_CLI"
}

run_workflow_tests() {
    echo -e "${BLUE}Running Workflow Scenario Tests...${NC}"
    bash "$INTEGRATION_WORKFLOW"
}

run_installation_tests() {
    echo -e "${BLUE}Running Installation Scenario Tests...${NC}"
    bash "$END_TO_END"
}

# Main execution function
main() {
    local run_unit=false
    local run_integration=false
    local run_end_to_end=false
    local run_all=true
    local run_quick=false
    
    # Individual test flags
    local run_core=false
    local run_cli=false
    local run_workflow=false
    local run_installation=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unit)
                run_unit=true
                run_all=false
                shift
                ;;
            --integration)
                run_integration=true
                run_all=false
                shift
                ;;
            --end-to-end)
                run_end_to_end=true
                run_all=false
                shift
                ;;
            --all)
                run_all=true
                shift
                ;;
            --quick)
                run_quick=true
                run_all=false
                shift
                ;;
            --core)
                run_core=true
                run_all=false
                shift
                ;;
            --cli)
                run_cli=true
                run_all=false
                shift
                ;;
            --workflow)
                run_workflow=true
                run_all=false
                shift
                ;;
            --installation)
                run_installation=true
                run_all=false
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Set up test environment
    setup_test_environment "Unified Test Runner"
    
    # Show header
    echo -e "${YELLOW}=================================================${NC}"
    echo -e "${YELLOW}          Spinbox Unified Test Runner           ${NC}"
    echo -e "${YELLOW}=================================================${NC}"
    echo ""
    
    # Track overall results
    local total_suites=0
    local passed_suites=0
    local start_time=$(date +%s)
    
    # Run tests based on options
    if [[ "$run_all" == "true" ]]; then
        # Run all test suites
        ((total_suites++))
        if run_unit_tests; then
            ((passed_suites++))
        fi
        
        ((total_suites++))
        if run_integration_tests; then
            ((passed_suites++))
        fi
        
        ((total_suites++))
        if run_end_to_end_tests; then
            ((passed_suites++))
        fi
        
    elif [[ "$run_quick" == "true" ]]; then
        # Run only unit tests for quick feedback
        ((total_suites++))
        if run_unit_tests; then
            ((passed_suites++))
        fi
        
    else
        # Run specific test suites
        if [[ "$run_unit" == "true" ]]; then
            ((total_suites++))
            if run_unit_tests; then
                ((passed_suites++))
            fi
        fi
        
        if [[ "$run_integration" == "true" ]]; then
            ((total_suites++))
            if run_integration_tests; then
                ((passed_suites++))
            fi
        fi
        
        if [[ "$run_end_to_end" == "true" ]]; then
            ((total_suites++))
            if run_end_to_end_tests; then
                ((passed_suites++))
            fi
        fi
        
        # Run individual test suites
        if [[ "$run_core" == "true" ]]; then
            ((total_suites++))
            if run_core_tests; then
                ((passed_suites++))
            fi
        fi
        
        if [[ "$run_cli" == "true" ]]; then
            ((total_suites++))
            if run_cli_tests; then
                ((passed_suites++))
            fi
        fi
        
        if [[ "$run_workflow" == "true" ]]; then
            ((total_suites++))
            if run_workflow_tests; then
                ((passed_suites++))
            fi
        fi
        
        if [[ "$run_installation" == "true" ]]; then
            ((total_suites++))
            if run_installation_tests; then
                ((passed_suites++))
            fi
        fi
    fi
    
    # Calculate execution time
    local end_time=$(date +%s)
    local execution_time=$((end_time - start_time))
    
    # Show final results
    echo ""
    echo -e "${YELLOW}=================================================${NC}"
    echo -e "${YELLOW}             Final Test Results                 ${NC}"
    echo -e "${YELLOW}=================================================${NC}"
    echo -e "Test suites run: $total_suites"
    echo -e "${GREEN}Passed: $passed_suites${NC}"
    echo -e "${RED}Failed: $((total_suites - passed_suites))${NC}"
    echo -e "Execution time: ${execution_time}s"
    echo ""
    
    if [[ $passed_suites -eq $total_suites ]]; then
        echo -e "${GREEN}🎉 All test suites passed!${NC}"
        echo -e "${GREEN}✨ Spinbox is ready for use!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some test suites failed${NC}"
        echo -e "${RED}💡 Use individual test options to debug specific failures${NC}"
        exit 1
    fi
}

# Run main function with all arguments
main "$@"