# Testing Documentation

## Overview

This project includes a comprehensive testing framework for bash scripts, providing automated testing capabilities for configuration management, utility functions, and overall project setup validation.

## Test Structure

### Test Files Location
- All test files are located in the `tests/` directory
- Main test runner: `tests/run_tests.sh`
- Individual test suites:
  - `tests/test_utils.sh` - Utility functions testing
  - `tests/test_config.sh` - Configuration management testing

### Test Framework Architecture

The testing framework consists of:

1. **Main Test Runner** (`run_tests.sh`) - Orchestrates test execution
2. **Test Suites** - Individual test files for different components
3. **Test Framework Functions** - Assertion helpers and test utilities
4. **Test Environment** - Isolated testing environment with cleanup

## Running Tests

### Run All Tests
```bash
./tests/run_tests.sh
```

### Run Specific Test Suite
```bash
./tests/run_tests.sh suite utils      # Run utils tests only
./tests/run_tests.sh suite config     # Run config tests only
```

### List Available Test Suites
```bash
./tests/run_tests.sh list
```

### Clean Test Artifacts
```bash
./tests/run_tests.sh clean
```

### Get Help
```bash
./tests/run_tests.sh help
```

## Test Framework Features

### Assertion Functions

The test framework provides several assertion functions:

- `assert_equals(expected, actual, message)` - Compare two values
- `assert_true(condition, message)` - Assert condition is true
- `assert_false(condition, message)` - Assert condition is false
- `assert_file_exists(file_path, message)` - Assert file exists
- `assert_command_success(command, message)` - Assert command succeeds
- `assert_command_failure(command, message)` - Assert command fails

### Test Environment

Each test runs in an isolated environment:
- Temporary directory created for each test session
- Environment variables set for testing mode
- Automatic cleanup after test completion
- Backup and rollback functionality

### Test Reporting

The framework provides multiple reporting formats:

1. **Console Output** - Real-time test results
2. **HTML Report** - Detailed test report with styling
3. **Log Files** - Individual test suite outputs
4. **Summary Statistics** - Pass/fail counts and success rates

## Writing Tests

### Test Structure

Each test file should follow this pattern:

```bash
#!/bin/bash
# Test description

# Source the test framework
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_utils.sh"
source "$SCRIPT_DIR/../lib/your_module.sh"

# Test function
function test_your_function() {
  CURRENT_TEST="your_function"
  
  # Test implementation
  your_function "test_input"
  assert_equals "expected_output" "$?" "Function should return expected value"
}

# Main test runner
function run_your_tests() {
  print_status "Starting your tests..."
  
  setup_test
  
  # Run test functions
  test_your_function
  
  teardown_test
  
  # Print summary
  if [[ $FAILED_COUNT -eq 0 ]]; then
    print_status "All tests passed! ✓"
    return 0
  else
    print_error "$FAILED_COUNT test(s) failed! ✗"
    return 1
  fi
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_your_tests
  exit $?
fi
```

### Test Guidelines

1. **Test Names** - Use descriptive function names starting with `test_`
2. **Test Isolation** - Each test should be independent
3. **Assertions** - Use appropriate assertion functions
4. **Error Messages** - Provide clear, descriptive error messages
5. **Cleanup** - Always clean up resources in teardown

## Test Coverage

### Utility Functions (`test_utils.sh`)

Tests for core utility functions:
- Project name validation
- Email validation
- URL validation
- File operations (safe write, create directories)
- Command checking
- Confirmation prompts
- Backup and restore functionality
- Dry run mode
- Configuration management
- Retry mechanisms

### Configuration Management (`test_config.sh`)

Tests for configuration system:
- Configuration initialization
- Global/user/project config operations
- Config value operations
- Configuration validation
- Config reset functionality
- Import/export operations
- Config listing
- Error handling

## Test Environment Variables

The following environment variables affect test behavior:

- `TESTING=true` - Indicates test mode
- `TEST_MODE=true` - Additional test mode flag
- `SKIP_CONFIRMATIONS=true` - Skip user confirmations
- `DRY_RUN=true/false` - Enable/disable dry run mode
- `VERBOSE=true` - Enable verbose output

## Test Output

### Console Output Format
```
✓ test_name: Test description - PASSED
✗ test_name: Test description - FAILED
  Expected: 'expected_value'
  Actual:   'actual_value'
```

### HTML Report
- Located at `.test-results/test-report.html`
- Includes summary statistics
- Individual test suite results
- Styled for easy reading
- Timestamp and run information

### Log Files
- Individual suite logs in `.test-results/`
- Format: `{suite_name}_output.log`
- Contains detailed test execution output

## Continuous Integration

The test framework is designed to work with CI/CD pipelines:

- Exit codes: 0 (success), 1 (failure)
- Machine-readable output formats
- Configurable test environments
- Artifact generation for reporting

## Best Practices

1. **Run Tests Regularly** - Execute tests before committing changes
2. **Add Tests for New Features** - Write tests for new functionality
3. **Test Edge Cases** - Include boundary and error conditions
4. **Keep Tests Fast** - Optimize test execution time
5. **Document Test Cases** - Explain complex test scenarios
6. **Use Descriptive Messages** - Make test failures easy to understand

## Troubleshooting

### Common Issues

1. **Permission Errors** - Ensure test files are executable
2. **Path Issues** - Verify relative paths in test files
3. **Environment Variables** - Check required variables are set
4. **Cleanup Failures** - Ensure proper teardown in tests

### Debug Mode

Enable verbose output for debugging:
```bash
VERBOSE=true ./tests/run_tests.sh
```

### Test Isolation

If tests interfere with each other:
- Check shared state between tests
- Verify cleanup in teardown functions
- Use unique temporary directories

## Adding New Test Suites

1. Create test file in `tests/` directory
2. Follow naming convention: `test_<module>.sh`
3. Implement test functions
4. Add to `TEST_SUITES` array in `run_tests.sh`
5. Test the new suite independently
6. Update documentation

## Performance Considerations

- Tests run in parallel where possible
- Individual test timeouts prevent hanging
- Efficient assertion implementations
- Minimal test data requirements
- Quick cleanup procedures

## Security

- Tests run in isolated environments
- No network access required
- Temporary files cleaned up
- No sensitive data in test files
- Safe file operations only