#!/bin/bash
# Main test runner for the project template
# This script runs all test suites and provides comprehensive test reporting

# Set script directory and source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities library
source "$PROJECT_ROOT/lib/utils.sh"

# Test configuration
TEST_OUTPUT_DIR="$PROJECT_ROOT/.test-results"
TEST_REPORT_FILE="$TEST_OUTPUT_DIR/test-report.html"
COVERAGE_DIR="$TEST_OUTPUT_DIR/coverage"

# Global test statistics
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0

# Test suite information
declare -A TEST_SUITES=(
  ["utils"]="test_utils.sh"
  ["config"]="test_config.sh"
)

# Initialize test environment
function init_test_environment() {
  print_status "Initializing test environment..."
  
  # Create test output directory
  mkdir -p "$TEST_OUTPUT_DIR"
  mkdir -p "$COVERAGE_DIR"
  
  # Initialize logging
  init_logging "test_runner"
  
  # Set test environment variables
  export TESTING=true
  export TEST_MODE=true
  
  print_status "Test environment initialized"
}

# Clean up test environment
function cleanup_test_environment() {
  print_status "Cleaning up test environment..."
  
  # Clean up any temporary test files
  find /tmp -name "project-template-tests-*" -type d -exec rm -rf {} + 2>/dev/null || true
  
  print_status "Test environment cleaned up"
}

# Run a single test suite
function run_test_suite() {
  local suite_name="$1"
  local test_file="$2"
  local test_path="$SCRIPT_DIR/$test_file"
  
  print_status "Running test suite: $suite_name"
  
  if [[ ! -f "$test_path" ]]; then
    print_error "Test file not found: $test_path"
    return 1
  fi
  
  # Make test file executable
  chmod +x "$test_path"
  
  # Run the test suite and capture output
  local output_file="$TEST_OUTPUT_DIR/${suite_name}_output.log"
  local start_time=$(date +%s)
  
  if bash "$test_path" > "$output_file" 2>&1; then
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_status "Test suite '$suite_name' PASSED (${duration}s)"
    ((PASSED_SUITES++))
    
    # Extract test statistics from output
    local suite_tests=$(grep "Total tests:" "$output_file" | awk '{print $3}' || echo "0")
    local suite_passed=$(grep "Passed:" "$output_file" | awk '{print $2}' || echo "0")
    local suite_failed=$(grep "Failed:" "$output_file" | awk '{print $2}' || echo "0")
    
    TOTAL_TESTS=$((TOTAL_TESTS + suite_tests))
    TOTAL_PASSED=$((TOTAL_PASSED + suite_passed))
    TOTAL_FAILED=$((TOTAL_FAILED + suite_failed))
    
    return 0
  else
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_error "Test suite '$suite_name' FAILED (${duration}s)"
    ((FAILED_SUITES++))
    
    # Show error output
    print_error "Error output:"
    tail -n 20 "$output_file" | sed 's/^/  /'
    
    return 1
  fi
}

# Run specific test suite
function run_specific_suite() {
  local suite_name="$1"
  
  if [[ -z "${TEST_SUITES[$suite_name]}" ]]; then
    print_error "Unknown test suite: $suite_name"
    print_info "Available test suites: ${!TEST_SUITES[*]}"
    return 1
  fi
  
  init_test_environment
  
  ((TOTAL_SUITES++))
  run_test_suite "$suite_name" "${TEST_SUITES[$suite_name]}"
  
  cleanup_test_environment
  print_test_summary
}

# Run all test suites
function run_all_suites() {
  print_status "Running all test suites..."
  
  init_test_environment
  
  # Run each test suite
  for suite_name in "${!TEST_SUITES[@]}"; do
    ((TOTAL_SUITES++))
    run_test_suite "$suite_name" "${TEST_SUITES[$suite_name]}"
  done
  
  cleanup_test_environment
  print_test_summary
  generate_test_report
}

# Print test summary
function print_test_summary() {
  echo ""
  print_info "=============================================="
  print_info "              TEST SUMMARY"
  print_info "=============================================="
  echo "  Test Suites:"
  echo "    Total: $TOTAL_SUITES"
  echo "    Passed: $PASSED_SUITES"
  echo "    Failed: $FAILED_SUITES"
  echo ""
  echo "  Individual Tests:"
  echo "    Total: $TOTAL_TESTS"
  echo "    Passed: $TOTAL_PASSED"
  echo "    Failed: $TOTAL_FAILED"
  echo ""
  
  if [[ $FAILED_SUITES -eq 0 ]]; then
    print_status "ALL TESTS PASSED! ✓"
    echo "    Success Rate: 100%"
  else
    print_error "SOME TESTS FAILED! ✗"
    local success_rate=$((TOTAL_PASSED * 100 / TOTAL_TESTS))
    echo "    Success Rate: ${success_rate}%"
  fi
  
  echo ""
  print_info "Test results saved to: $TEST_OUTPUT_DIR"
  
  if [[ -f "$TEST_REPORT_FILE" ]]; then
    print_info "HTML report available at: $TEST_REPORT_FILE"
  fi
  
  print_info "=============================================="
}

# Generate HTML test report
function generate_test_report() {
  print_status "Generating HTML test report..."
  
  cat > "$TEST_REPORT_FILE" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Project Template Test Report</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
            margin-bottom: 30px;
            border-bottom: 3px solid #007acc;
            padding-bottom: 15px;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            border-left: 4px solid #007acc;
        }
        .summary-card.passed {
            border-left-color: #28a745;
        }
        .summary-card.failed {
            border-left-color: #dc3545;
        }
        .summary-number {
            font-size: 2em;
            font-weight: bold;
            margin-bottom: 5px;
        }
        .passed { color: #28a745; }
        .failed { color: #dc3545; }
        .neutral { color: #6c757d; }
        .test-suites {
            margin-bottom: 30px;
        }
        .suite {
            margin-bottom: 20px;
            border: 1px solid #ddd;
            border-radius: 8px;
            overflow: hidden;
        }
        .suite-header {
            background: #f8f9fa;
            padding: 15px;
            font-weight: bold;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .suite-status {
            padding: 4px 12px;
            border-radius: 20px;
            color: white;
            font-size: 0.85em;
        }
        .suite-status.passed {
            background: #28a745;
        }
        .suite-status.failed {
            background: #dc3545;
        }
        .suite-details {
            padding: 15px;
            background: white;
        }
        .timestamp {
            text-align: center;
            color: #6c757d;
            margin-top: 30px;
            font-size: 0.9em;
        }
        pre {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
            border-left: 4px solid #007acc;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Project Template Test Report</h1>
        
        <div class="summary">
            <div class="summary-card">
                <div class="summary-number neutral">$TOTAL_SUITES</div>
                <div>Total Suites</div>
            </div>
            <div class="summary-card passed">
                <div class="summary-number passed">$PASSED_SUITES</div>
                <div>Passed Suites</div>
            </div>
            <div class="summary-card failed">
                <div class="summary-number failed">$FAILED_SUITES</div>
                <div>Failed Suites</div>
            </div>
            <div class="summary-card">
                <div class="summary-number neutral">$TOTAL_TESTS</div>
                <div>Total Tests</div>
            </div>
        </div>
        
        <div class="test-suites">
            <h2>Test Suite Results</h2>
EOF

  # Add results for each test suite
  for suite_name in "${!TEST_SUITES[@]}"; do
    local output_file="$TEST_OUTPUT_DIR/${suite_name}_output.log"
    local status="failed"
    
    if [[ -f "$output_file" ]] && grep -q "All.*tests passed" "$output_file"; then
      status="passed"
    fi
    
    cat >> "$TEST_REPORT_FILE" << EOF
            <div class="suite">
                <div class="suite-header">
                    <span>$suite_name Test Suite</span>
                    <span class="suite-status $status">$(echo $status | tr '[:lower:]' '[:upper:]')</span>
                </div>
                <div class="suite-details">
EOF

    if [[ -f "$output_file" ]]; then
      cat >> "$TEST_REPORT_FILE" << EOF
                    <pre>$(cat "$output_file" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')</pre>
EOF
    else
      cat >> "$TEST_REPORT_FILE" << EOF
                    <p>No output file found for this test suite.</p>
EOF
    fi

    cat >> "$TEST_REPORT_FILE" << EOF
                </div>
            </div>
EOF
  done

  cat >> "$TEST_REPORT_FILE" << EOF
        </div>
        
        <div class="timestamp">
            Report generated on $(date)
        </div>
    </div>
</body>
</html>
EOF

  print_status "HTML report generated: $TEST_REPORT_FILE"
}

# Check test environment
function check_test_environment() {
  print_status "Checking test environment..."
  
  # Check required files
  local required_files=(
    "$PROJECT_ROOT/lib/utils.sh"
    "$PROJECT_ROOT/lib/config.sh"
  )
  
  for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
      print_error "Required file not found: $file"
      return 1
    fi
  done
  
  # Check required commands
  local required_commands=("bash" "grep" "awk" "sed")
  
  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
      print_error "Required command not found: $cmd"
      return 1
    fi
  done
  
  print_status "Test environment check passed"
  return 0
}

# Run tests with coverage (placeholder for future enhancement)
function run_with_coverage() {
  print_warning "Coverage reporting is not yet implemented for shell scripts"
  print_info "Running tests without coverage..."
  run_all_suites
}

# Main function
function main() {
  local command="${1:-all}"
  local suite_name="$2"
  
  # Check test environment first
  if ! check_test_environment; then
    print_error "Test environment check failed"
    exit 1
  fi
  
  case "$command" in
    "all")
      run_all_suites
      ;;
    "suite")
      if [[ -z "$suite_name" ]]; then
        print_error "Suite name required for 'suite' command"
        print_info "Usage: $0 suite <suite_name>"
        print_info "Available suites: ${!TEST_SUITES[*]}"
        exit 1
      fi
      run_specific_suite "$suite_name"
      ;;
    "coverage")
      run_with_coverage
      ;;
    "list")
      print_info "Available test suites:"
      for suite in "${!TEST_SUITES[@]}"; do
        echo "  - $suite (${TEST_SUITES[$suite]})"
      done
      ;;
    "clean")
      print_status "Cleaning test artifacts..."
      rm -rf "$TEST_OUTPUT_DIR"
      cleanup_test_environment
      print_status "Test artifacts cleaned"
      ;;
    "help"|"-h"|"--help")
      cat << EOF
Project Template Test Runner

Usage: $0 [command] [options]

Commands:
  all                 Run all test suites (default)
  suite <name>        Run specific test suite
  coverage           Run tests with coverage (not yet implemented)
  list               List available test suites
  clean              Clean test artifacts
  help               Show this help message

Available test suites: ${!TEST_SUITES[*]}

Examples:
  $0                 # Run all tests
  $0 suite utils     # Run only utils tests
  $0 list            # List available test suites
  $0 clean           # Clean test artifacts

Exit codes:
  0 - All tests passed
  1 - Some tests failed or error occurred
EOF
      exit 0
      ;;
    *)
      print_error "Unknown command: $command"
      print_info "Use '$0 help' for usage information"
      exit 1
      ;;
  esac
  
  # Exit with appropriate code
  if [[ $FAILED_SUITES -eq 0 ]]; then
    exit 0
  else
    exit 1
  fi
}

# Execute main function with all arguments
main "$@"