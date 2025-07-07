#!/bin/bash
# Test framework for utility functions
# This script provides a testing framework for shell scripts

# Source the utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/utils.sh"

# Test framework variables
TEST_COUNT=0
PASSED_COUNT=0
FAILED_COUNT=0
CURRENT_TEST=""

# Test framework functions
function setup_test() {
  # Initialize test environment
  export VERBOSE=true
  export DRY_RUN=false
  init_logging "test_utils"
  
  # Create temporary directories for testing
  export TEST_TEMP_DIR="/tmp/project-template-tests-$$"
  mkdir -p "$TEST_TEMP_DIR"
  cd "$TEST_TEMP_DIR"
  
  print_status "Test environment initialized at $TEST_TEMP_DIR"
}

function teardown_test() {
  # Clean up test environment
  cd /tmp
  rm -rf "$TEST_TEMP_DIR"
  print_status "Test environment cleaned up"
}

function assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Assertion failed}"
  
  ((TEST_COUNT++))
  
  if [[ "$expected" == "$actual" ]]; then
    ((PASSED_COUNT++))
    print_status "✓ $CURRENT_TEST: $message"
    return 0
  else
    ((FAILED_COUNT++))
    print_error "✗ $CURRENT_TEST: $message"
    print_error "  Expected: '$expected'"
    print_error "  Actual:   '$actual'"
    return 1
  fi
}

function assert_true() {
  local condition="$1"
  local message="${2:-Condition should be true}"
  
  ((TEST_COUNT++))
  
  if [[ "$condition" == "true" ]] || [[ "$condition" == "0" ]]; then
    ((PASSED_COUNT++))
    print_status "✓ $CURRENT_TEST: $message"
    return 0
  else
    ((FAILED_COUNT++))
    print_error "✗ $CURRENT_TEST: $message"
    print_error "  Condition evaluated to: '$condition'"
    return 1
  fi
}

function assert_false() {
  local condition="$1"
  local message="${2:-Condition should be false}"
  
  ((TEST_COUNT++))
  
  if [[ "$condition" == "false" ]] || [[ "$condition" == "1" ]]; then
    ((PASSED_COUNT++))
    print_status "✓ $CURRENT_TEST: $message"
    return 0
  else
    ((FAILED_COUNT++))
    print_error "✗ $CURRENT_TEST: $message"
    print_error "  Condition evaluated to: '$condition'"
    return 1
  fi
}

function assert_file_exists() {
  local file_path="$1"
  local message="${2:-File should exist: $file_path}"
  
  ((TEST_COUNT++))
  
  if [[ -f "$file_path" ]]; then
    ((PASSED_COUNT++))
    print_status "✓ $CURRENT_TEST: $message"
    return 0
  else
    ((FAILED_COUNT++))
    print_error "✗ $CURRENT_TEST: $message"
    return 1
  fi
}

function assert_command_success() {
  local command="$1"
  local message="${2:-Command should succeed: $command}"
  
  ((TEST_COUNT++))
  
  if eval "$command" &>/dev/null; then
    ((PASSED_COUNT++))
    print_status "✓ $CURRENT_TEST: $message"
    return 0
  else
    ((FAILED_COUNT++))
    print_error "✗ $CURRENT_TEST: $message"
    return 1
  fi
}

function assert_command_failure() {
  local command="$1"
  local message="${2:-Command should fail: $command}"
  
  ((TEST_COUNT++))
  
  if ! eval "$command" &>/dev/null; then
    ((PASSED_COUNT++))
    print_status "✓ $CURRENT_TEST: $message"
    return 0
  else
    ((FAILED_COUNT++))
    print_error "✗ $CURRENT_TEST: $message"
    return 1
  fi
}

# Individual test functions
function test_validate_project_name() {
  CURRENT_TEST="validate_project_name"
  
  # Valid project names
  validate_project_name "my-project"
  assert_equals "0" "$?" "Valid project name with hyphens"
  
  validate_project_name "myproject123"
  assert_equals "0" "$?" "Valid project name with numbers"
  
  validate_project_name "my_project"
  assert_equals "0" "$?" "Valid project name with underscores"
  
  # Invalid project names
  validate_project_name "My-Project"
  assert_equals "1" "$?" "Invalid project name with uppercase"
  
  validate_project_name "my project"
  assert_equals "1" "$?" "Invalid project name with spaces"
  
  validate_project_name "-project"
  assert_equals "1" "$?" "Invalid project name starting with hyphen"
  
  validate_project_name "123project"
  assert_equals "0" "$?" "Valid project name starting with number"
}

function test_validate_email() {
  CURRENT_TEST="validate_email"
  
  # Valid emails
  validate_email "user@example.com"
  assert_equals "0" "$?" "Valid simple email"
  
  validate_email "user.name+tag@example.co.uk"
  assert_equals "0" "$?" "Valid complex email"
  
  validate_email "user123@test-domain.org"
  assert_equals "0" "$?" "Valid email with numbers and hyphens"
  
  # Invalid emails
  validate_email "invalid-email"
  assert_equals "1" "$?" "Invalid email without @"
  
  validate_email "user@"
  assert_equals "1" "$?" "Invalid email without domain"
  
  validate_email "@example.com"
  assert_equals "1" "$?" "Invalid email without user"
  
  validate_email "user@example"
  assert_equals "1" "$?" "Invalid email without TLD"
}

function test_validate_url() {
  CURRENT_TEST="validate_url"
  
  # Valid URLs
  validate_url "https://example.com"
  assert_equals "0" "$?" "Valid HTTPS URL"
  
  validate_url "http://example.com"
  assert_equals "0" "$?" "Valid HTTP URL"
  
  validate_url "https://sub.example.com/path"
  assert_equals "0" "$?" "Valid URL with subdomain and path"
  
  # Invalid URLs
  validate_url "ftp://example.com"
  assert_equals "1" "$?" "Invalid protocol"
  
  validate_url "https://example"
  assert_equals "1" "$?" "Invalid URL without TLD"
  
  validate_url "not-a-url"
  assert_equals "1" "$?" "Invalid URL format"
}

function test_safe_write_file() {
  CURRENT_TEST="safe_write_file"
  
  local test_file="$TEST_TEMP_DIR/test_file.txt"
  local test_content="Hello, World!"
  
  # Test writing a new file
  safe_write_file "$test_file" "$test_content"
  assert_file_exists "$test_file" "File should be created"
  
  local actual_content=$(cat "$test_file")
  assert_equals "$test_content" "$actual_content" "File content should match"
  
  # Test overwriting existing file
  local new_content="New content"
  safe_write_file "$test_file" "$new_content"
  
  local updated_content=$(cat "$test_file")
  assert_equals "$new_content" "$updated_content" "File content should be updated"
  
  # Check that backup was created
  local backup_count=$(find "$BACKUP_DIR" -name "*test_file.txt*" | wc -l)
  assert_true "$((backup_count > 0))" "Backup should be created"
}

function test_safe_create_dir() {
  CURRENT_TEST="safe_create_dir"
  
  local test_dir="$TEST_TEMP_DIR/test_directory"
  
  # Test creating a new directory
  safe_create_dir "$test_dir"
  assert_true "-d \"$test_dir\"" "Directory should be created"
  
  # Test creating directory that already exists
  safe_create_dir "$test_dir"
  assert_true "-d \"$test_dir\"" "Directory should still exist"
}

function test_check_command() {
  CURRENT_TEST="check_command"
  
  # Test with existing command
  check_command "bash"
  assert_equals "0" "$?" "bash command should exist"
  
  # Test with non-existing command
  check_command "nonexistent-command-12345"
  assert_equals "1" "$?" "Non-existent command should fail check"
}

function test_confirm() {
  CURRENT_TEST="confirm"
  
  # Test with automatic yes (for testing)
  export SKIP_CONFIRMATIONS=true
  
  confirm "Test question"
  local result=$?
  
  # When SKIP_CONFIRMATIONS=true, confirm should return based on default
  assert_equals "1" "$result" "Should return default (no) when skipping confirmations"
  
  export SKIP_CONFIRMATIONS=false
}

function test_backup_and_restore() {
  CURRENT_TEST="backup_and_restore"
  
  local test_file="$TEST_TEMP_DIR/backup_test.txt"
  local original_content="Original content"
  
  # Create original file
  echo "$original_content" > "$test_file"
  
  # Backup the file
  backup_file "$test_file"
  assert_true "$((${#ROLLBACK_ACTIONS[@]} > 0))" "Rollback action should be added"
  
  # Modify the file
  echo "Modified content" > "$test_file"
  
  # Check backup exists
  local backup_count=$(find "$BACKUP_DIR" -name "*backup_test.txt*" | wc -l)
  assert_true "$((backup_count > 0))" "Backup file should exist"
  
  # Restore from backup
  local backup_file=$(find "$BACKUP_DIR" -name "*backup_test.txt*" | head -1)
  restore_file "$backup_file" "$test_file"
  
  # Check content is restored
  local restored_content=$(cat "$test_file")
  assert_equals "$original_content" "$restored_content" "Content should be restored"
}

function test_dry_run_mode() {
  CURRENT_TEST="dry_run_mode"
  
  # Enable dry run mode
  export DRY_RUN=true
  
  local test_file="$TEST_TEMP_DIR/dry_run_test.txt"
  
  # Try to write file in dry run mode
  safe_write_file "$test_file" "Test content"
  
  # File should not exist
  assert_false "-f \"$test_file\"" "File should not be created in dry run mode"
  
  # Try to create directory in dry run mode
  local test_dir="$TEST_TEMP_DIR/dry_run_dir"
  safe_create_dir "$test_dir"
  
  # Directory should not exist
  assert_false "-d \"$test_dir\"" "Directory should not be created in dry run mode"
  
  # Disable dry run mode
  export DRY_RUN=false
}

function test_configuration_functions() {
  CURRENT_TEST="configuration_functions"
  
  # Test configuration directory creation
  local config_dir="$TEST_TEMP_DIR/.config"
  safe_create_dir "$config_dir"
  assert_true "-d \"$config_dir\"" "Config directory should be created"
  
  # Test saving configuration variables
  local config_file="$config_dir/test.conf"
  TEST_VAR1="value1"
  TEST_VAR2="value2"
  
  save_config "$config_file" "TEST_VAR1" "TEST_VAR2"
  assert_file_exists "$config_file" "Config file should be created"
  
  # Test loading configuration
  unset TEST_VAR1 TEST_VAR2
  load_config "$config_file"
  
  assert_equals "value1" "$TEST_VAR1" "TEST_VAR1 should be loaded"
  assert_equals "value2" "$TEST_VAR2" "TEST_VAR2 should be loaded"
}

function test_retry_function() {
  CURRENT_TEST="retry_function"
  
  # Create a command that fails twice then succeeds
  local counter_file="$TEST_TEMP_DIR/retry_counter"
  echo "0" > "$counter_file"
  
  local test_command="
    count=\$(cat '$counter_file')
    count=\$((count + 1))
    echo \"\$count\" > '$counter_file'
    if [[ \$count -lt 3 ]]; then
      exit 1
    else
      exit 0
    fi
  "
  
  # Test retry with sufficient attempts
  retry 5 0.1 bash -c "$test_command"
  assert_equals "0" "$?" "Retry should succeed after multiple attempts"
  
  # Check that it took 3 attempts
  local final_count=$(cat "$counter_file")
  assert_equals "3" "$final_count" "Should have taken 3 attempts"
}

# Main test runner
function run_all_tests() {
  print_status "Starting utility function tests..."
  
  setup_test
  
  # Run all test functions
  test_validate_project_name
  test_validate_email
  test_validate_url
  test_safe_write_file
  test_safe_create_dir
  test_check_command
  test_confirm
  test_backup_and_restore
  test_dry_run_mode
  test_configuration_functions
  test_retry_function
  
  teardown_test
  
  # Print test summary
  echo ""
  print_info "Test Summary:"
  echo "  Total tests: $TEST_COUNT"
  echo "  Passed: $PASSED_COUNT"
  echo "  Failed: $FAILED_COUNT"
  
  if [[ $FAILED_COUNT -eq 0 ]]; then
    print_status "All tests passed! ✓"
    return 0
  else
    print_error "$FAILED_COUNT test(s) failed! ✗"
    return 1
  fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_all_tests
  exit $?
fi