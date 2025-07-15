#!/bin/bash
# CLI Integration Tests for Spinbox
# Tests the CLI functionality with integration-focused tests

# Set up test environment
set -e
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Source the test utilities
source testing/test-utils.sh

# Test configuration
TEST_PROJECT_NAME="test-cli-project"
TEST_DIR="/tmp/spinbox-test-$$"
CLI_PATH="$PROJECT_ROOT/bin/spinbox"

# Setup test environment
setup_test_env() {
    mkdir -p "$TEST_DIR"
    export TEST_MODE=true
    export CONFIG_DIR="$TEST_DIR/.config"
}

# Setup test environment and cleanup
setup_test_environment "CLI Integration Tests"

# CLI Help System Tests
test_cli_help() {
    echo -e "\n${YELLOW}=== CLI Help System Tests ===${NC}"
    
    assert_true \
        "\"$CLI_PATH\" --help | grep -q 'Spinbox - Prototyping Environment Scaffolding Tool'" \
        "Main help displays correctly"
    
    assert_true \
        "\"$CLI_PATH\" create --help | grep -q 'Create a new development project'" \
        "Create command help works"
    
    assert_true \
        "\"$CLI_PATH\" config --help | grep -q 'Manage global configuration'" \
        "Config command help works"
    
    assert_true \
        "\"$CLI_PATH\" status --help | grep -q 'Show project and configuration status'" \
        "Status command help works"
}

# CLI Version Tests
test_cli_version() {
    echo -e "\n${YELLOW}=== CLI Version Tests ===${NC}"
    
    assert_true \
        "\"$CLI_PATH\" --version | grep -q 'Spinbox v'" \
        "Version command displays version info"
}

# Configuration System Tests
test_config_system() {
    echo -e "\n${YELLOW}=== Configuration System Tests ===${NC}"
    
    # Test config listing
    assert_true \
        "\"$CLI_PATH\" config --list | grep -q 'Global Configuration'" \
        "Config list command works"
    
    # Test status command
    assert_true \
        "\"$CLI_PATH\" status | grep -q 'Spinbox Status'" \
        "Status command works"
}

# Project Creation Tests (Dry Run)
test_project_creation() {
    echo -e "\n${YELLOW}=== Project Creation Tests ===${NC}"
    
    # Test basic Python project creation
    assert_true \
        "\"$CLI_PATH\" create $TEST_PROJECT_NAME --python --dry-run | grep -q 'Project $TEST_PROJECT_NAME created successfully'" \
        "Python project creation (dry-run)"
    
    # Test full-stack project creation
    assert_true \
        "\"$CLI_PATH\" create test-fullstack --fastapi --nextjs --postgresql --dry-run | grep -q 'Project test-fullstack created successfully'" \
        "Full-stack project creation (dry-run)"
    
    # Test with version overrides (TODO: implement CLI flag parsing for versions)
    # assert_true \
    #     "\"$CLI_PATH\" create test-versions --python --python-version 3.11 --dry-run | grep -q 'Python 3.11 (from CLI flag)'" \
    #     "Version override through CLI flags"
    echo -e "${YELLOW}  SKIP: Version override through CLI flags (not yet implemented)${NC}"
}

# Error Handling Tests
test_error_handling() {
    echo -e "\n${YELLOW}=== Error Handling Tests ===${NC}"
    
    # Test invalid command
    assert_true \
        "\"$CLI_PATH\" invalid-command 2>&1 | grep -q 'Unknown command'" \
        "Invalid command error handling"
    
    # Test missing project name
    assert_true \
        "\"$CLI_PATH\" create 2>&1 | grep -q 'Project name is required'" \
        "Missing project name error"
    
    # Test invalid project name
    assert_true \
        "\"$CLI_PATH\" create Invalid-Name 2>&1 | grep -q 'Invalid project name'" \
        "Invalid project name validation"
}

# Component Generator Tests
test_component_generators() {
    echo -e "\n${YELLOW}=== Component Generator Tests ===${NC}"
    
    # Test that generators exist and are executable
    assert_true \
        "[[ -f 'generators/minimal-python.sh' && -x 'generators/minimal-python.sh' ]]" \
        "Minimal Python generator exists and is executable"
    
    assert_true \
        "[[ -f 'generators/minimal-node.sh' && -x 'generators/minimal-node.sh' ]]" \
        "Minimal Node generator exists and is executable"
    
    assert_true \
        "[[ -f 'generators/fastapi.sh' && -r 'generators/fastapi.sh' ]]" \
        "FastAPI generator exists and is readable"
    
    assert_true \
        "[[ -f 'generators/nextjs.sh' && -r 'generators/nextjs.sh' ]]" \
        "Next.js generator exists and is readable"
    
    assert_true \
        "[[ -f 'generators/postgresql.sh' && -r 'generators/postgresql.sh' ]]" \
        "PostgreSQL generator exists and is readable"
}

# Integration Tests
test_integration() {
    echo -e "\n${YELLOW}=== Integration Tests ===${NC}"
    
    # Test that CLI can source all required libraries
    assert_true \
        "source lib/utils.sh && source lib/config.sh && source lib/version-config.sh && source lib/project-generator.sh" \
        "All library modules can be sourced"
    
    # Test that version configuration works
    assert_true \
        "source lib/version-config.sh && [[ \$(get_effective_python_version) =~ ^[0-9]+\.[0-9]+$ ]]" \
        "Version configuration returns valid version format"
}

# Performance Tests
test_performance() {
    echo -e "\n${YELLOW}=== Performance Tests ===${NC}"
    
    # Test help command performance (should be under 2 seconds)
    start_time=$(date +%s.%N)
    "$CLI_PATH" --help > /dev/null
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    
    assert_true \
        "[[ \$(echo \"$duration < 2.0\" | bc) -eq 1 ]]" \
        "Help command completes under 2 seconds ($duration seconds)"
    
    # Test dry-run performance (should be under 5 seconds)
    start_time=$(date +%s.%N)
    "$CLI_PATH" create perf-test --python --dry-run > /dev/null 2>&1
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    
    assert_true \
        "[[ \$(echo \"$duration < 5.0\" | bc) -eq 1 ]]" \
        "Dry-run project creation completes under 5 seconds ($duration seconds)"
}

# Main test execution
main() {
    echo -e "${BLUE}Starting Spinbox CLI Tests${NC}"
    echo "Target: < 5 seconds total execution time"
    
    # Setup and cleanup any existing test artifacts
    cleanup_test_env
    setup_test_env
    
    # Record start time
    start_time=$(date +%s.%N)
    
    # Run test suites
    test_cli_help
    test_cli_version
    test_config_system
    test_project_creation
    test_error_handling
    test_component_generators
    test_integration
    test_performance
    
    # Record end time
    end_time=$(date +%s.%N)
    total_duration=$(echo "$end_time - $start_time" | bc)
    
    # Cleanup
    cleanup_test_env
    
    # Final report
    echo -e "\n${BLUE}=== Test Results ===${NC}"
    echo "Total tests run: $TESTS_RUN"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    echo "Total time: ${total_duration} seconds"
    
    # Performance check
    if [[ $(echo "$total_duration < 5.0" | bc) -eq 1 ]]; then
        echo -e "${GREEN}✓ Performance target met (< 5 seconds)${NC}"
    else
        echo -e "${YELLOW}! Performance target missed (${total_duration}s > 5s)${NC}"
    fi
    
    # Exit with appropriate code
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi