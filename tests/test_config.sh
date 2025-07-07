#!/bin/bash
# Test framework for configuration management functions

# Source the test framework and libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_utils.sh"
source "$SCRIPT_DIR/../lib/config.sh"

# Configuration-specific test functions
function test_config_initialization() {
  CURRENT_TEST="config_initialization"
  
  # Test config directory creation
  init_config
  assert_true "-d \"$CONFIG_DIR\"" "Config directory should be created"
  
  # Test default global config creation
  assert_file_exists "$GLOBAL_CONFIG" "Global config file should be created"
  
  # Test that config variables are set
  assert_true "-n \"$PYTHON_VERSION\"" "Python version should be set"
  assert_true "-n \"$NODE_VERSION\"" "Node version should be set"
}

function test_global_config_operations() {
  CURRENT_TEST="global_config_operations"
  
  # Set test values
  PYTHON_VERSION="3.11"
  NODE_VERSION="18"
  PROJECT_AUTHOR="Test Author"
  PROJECT_EMAIL="test@example.com"
  
  # Save global config
  save_global_config
  assert_file_exists "$GLOBAL_CONFIG" "Global config should be saved"
  
  # Reset variables
  PYTHON_VERSION=""
  NODE_VERSION=""
  PROJECT_AUTHOR=""
  PROJECT_EMAIL=""
  
  # Load global config
  load_global_config
  assert_equals "3.11" "$PYTHON_VERSION" "Python version should be loaded"
  assert_equals "18" "$NODE_VERSION" "Node version should be loaded"
  assert_equals "Test Author" "$PROJECT_AUTHOR" "Project author should be loaded"
  assert_equals "test@example.com" "$PROJECT_EMAIL" "Project email should be loaded"
}

function test_user_config_operations() {
  CURRENT_TEST="user_config_operations"
  
  # Set test values
  PREFERRED_EDITOR="vim"
  AUTO_START_SERVICES="false"
  SKIP_CONFIRMATIONS="true"
  
  # Save user config
  save_user_config
  assert_file_exists "$USER_CONFIG" "User config should be saved"
  
  # Reset variables
  PREFERRED_EDITOR=""
  AUTO_START_SERVICES=""
  SKIP_CONFIRMATIONS=""
  
  # Load user config
  load_user_config
  assert_equals "vim" "$PREFERRED_EDITOR" "Preferred editor should be loaded"
  assert_equals "false" "$AUTO_START_SERVICES" "Auto start services should be loaded"
  assert_equals "true" "$SKIP_CONFIRMATIONS" "Skip confirmations should be loaded"
}

function test_project_config_operations() {
  CURRENT_TEST="project_config_operations"
  
  local project_dir="$TEST_TEMP_DIR/test_project"
  mkdir -p "$project_dir"
  
  # Set test values
  PROJECT_NAME="test-project"
  PROJECT_DESCRIPTION="A test project"
  USE_BACKEND="true"
  USE_FRONTEND="false"
  BACKEND_PORT="9000"
  
  # Save project config
  save_project_config "$project_dir"
  assert_file_exists "$project_dir/.config/project.conf" "Project config should be saved"
  
  # Reset variables
  PROJECT_NAME=""
  PROJECT_DESCRIPTION=""
  USE_BACKEND=""
  USE_FRONTEND=""
  BACKEND_PORT=""
  
  # Load project config
  load_project_config "$project_dir"
  assert_equals "test-project" "$PROJECT_NAME" "Project name should be loaded"
  assert_equals "A test project" "$PROJECT_DESCRIPTION" "Project description should be loaded"
  assert_equals "true" "$USE_BACKEND" "Use backend should be loaded"
  assert_equals "false" "$USE_FRONTEND" "Use frontend should be loaded"
  assert_equals "9000" "$BACKEND_PORT" "Backend port should be loaded"
}

function test_config_value_operations() {
  CURRENT_TEST="config_value_operations"
  
  # Test getting config values with defaults
  local value=$(get_config_value "NONEXISTENT_VAR" "default_value")
  assert_equals "default_value" "$value" "Should return default for non-existent variable"
  
  # Test getting existing config value
  PROJECT_AUTHOR="Existing Author"
  local existing_value=$(get_config_value "PROJECT_AUTHOR" "default")
  assert_equals "Existing Author" "$existing_value" "Should return existing value"
  
  # Test setting config values
  set_config_value "PYTHON_VERSION" "3.12" "global"
  assert_equals "3.12" "$PYTHON_VERSION" "Global config value should be set"
  
  set_config_value "PREFERRED_EDITOR" "nano" "user"
  assert_equals "nano" "$PREFERRED_EDITOR" "User config value should be set"
  
  set_config_value "PROJECT_NAME" "new-project" "project"
  assert_equals "new-project" "$PROJECT_NAME" "Project config value should be set"
}

function test_config_validation() {
  CURRENT_TEST="config_validation"
  
  # Set valid configuration
  PROJECT_EMAIL="valid@example.com"
  PYTHON_VERSION="3.12"
  NODE_VERSION="20"
  BACKEND_PORT="8000"
  FRONTEND_PORT="3000"
  
  validate_config
  assert_equals "0" "$?" "Valid configuration should pass validation"
  
  # Test invalid email
  PROJECT_EMAIL="invalid-email"
  validate_config
  assert_equals "1" "$?" "Invalid email should fail validation"
  
  # Reset to valid email
  PROJECT_EMAIL="valid@example.com"
  
  # Test invalid Python version
  PYTHON_VERSION="invalid"
  validate_config
  assert_equals "1" "$?" "Invalid Python version should fail validation"
  
  # Reset to valid version
  PYTHON_VERSION="3.12"
  
  # Test invalid port
  BACKEND_PORT="99999"
  validate_config
  assert_equals "1" "$?" "Invalid port should fail validation"
}

function test_config_reset() {
  CURRENT_TEST="config_reset"
  
  # Set some custom values
  PROJECT_AUTHOR="Custom Author"
  PYTHON_VERSION="3.11"
  
  # Save the config
  save_global_config
  
  # Simulate user confirming reset (skip confirmations)
  export SKIP_CONFIRMATIONS=true
  
  # Reset global config
  reset_config "global"
  
  # Load config again
  load_global_config
  
  # Should be back to defaults
  assert_equals "$DEFAULT_PYTHON_VERSION" "$PYTHON_VERSION" "Python version should be reset to default"
  assert_equals "" "$PROJECT_AUTHOR" "Project author should be empty after reset"
}

function test_config_import_export() {
  CURRENT_TEST="config_import_export"
  
  # Create a test config file
  local test_config="$TEST_TEMP_DIR/test_config.conf"
  cat > "$test_config" << EOF
# Test configuration
PYTHON_VERSION="3.13"
PROJECT_AUTHOR="Imported Author"
PROJECT_EMAIL="imported@example.com"
EOF
  
  # Import the configuration
  import_config "$test_config" "global"
  
  # Load the imported config
  load_global_config
  
  assert_equals "3.13" "$PYTHON_VERSION" "Imported Python version should be loaded"
  assert_equals "Imported Author" "$PROJECT_AUTHOR" "Imported author should be loaded"
  assert_equals "imported@example.com" "$PROJECT_EMAIL" "Imported email should be loaded"
  
  # Test export
  local export_file="$TEST_TEMP_DIR/exported_config.conf"
  export_config "global" "$export_file"
  assert_file_exists "$export_file" "Exported config file should exist"
  
  # Verify exported content contains our values
  grep -q "PYTHON_VERSION=\"3.13\"" "$export_file"
  assert_equals "0" "$?" "Exported file should contain Python version"
  
  grep -q "PROJECT_AUTHOR=\"Imported Author\"" "$export_file"
  assert_equals "0" "$?" "Exported file should contain project author"
}

function test_config_list() {
  CURRENT_TEST="config_list"
  
  # Set some test values
  PYTHON_VERSION="3.12"
  PROJECT_AUTHOR="Test Author"
  PREFERRED_EDITOR="code"
  
  # Capture list output
  local output=$(list_config "global" 2>&1)
  
  # Check that output contains our values
  echo "$output" | grep -q "PYTHON_VERSION=3.12"
  assert_equals "0" "$?" "List output should contain Python version"
  
  echo "$output" | grep -q "PROJECT_AUTHOR=Test Author"
  assert_equals "0" "$?" "List output should contain project author"
  
  # Test user config listing
  local user_output=$(list_config "user" 2>&1)
  echo "$user_output" | grep -q "PREFERRED_EDITOR=code"
  assert_equals "0" "$?" "User config list should contain preferred editor"
}

function test_config_error_handling() {
  CURRENT_TEST="config_error_handling"
  
  # Test setting invalid configuration scope
  set_config_value "TEST_VAR" "test_value" "invalid_scope"
  assert_equals "1" "$?" "Invalid scope should return error"
  
  # Test setting invalid key for scope
  set_config_value "INVALID_KEY" "test_value" "global"
  assert_equals "1" "$?" "Invalid key for global scope should return error"
  
  # Test importing non-existent file
  import_config "/nonexistent/file.conf" "global"
  assert_equals "1" "$?" "Importing non-existent file should return error"
  
  # Test loading non-existent project config
  load_project_config "/nonexistent/project"
  assert_equals "1" "$?" "Loading non-existent project config should return error"
}

# Main test runner for configuration tests
function run_config_tests() {
  print_status "Starting configuration management tests..."
  
  setup_test
  
  # Initialize configuration for testing
  export CONFIG_DIR="$TEST_TEMP_DIR/.config"
  export GLOBAL_CONFIG="$CONFIG_DIR/global.conf"
  export USER_CONFIG="$CONFIG_DIR/user.conf"
  
  # Run all configuration test functions
  test_config_initialization
  test_global_config_operations
  test_user_config_operations
  test_project_config_operations
  test_config_value_operations
  test_config_validation
  test_config_reset
  test_config_import_export
  test_config_list
  test_config_error_handling
  
  teardown_test
  
  # Print test summary
  echo ""
  print_info "Configuration Test Summary:"
  echo "  Total tests: $TEST_COUNT"
  echo "  Passed: $PASSED_COUNT"
  echo "  Failed: $FAILED_COUNT"
  
  if [[ $FAILED_COUNT -eq 0 ]]; then
    print_status "All configuration tests passed! ✓"
    return 0
  else
    print_error "$FAILED_COUNT configuration test(s) failed! ✗"
    return 1
  fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  run_config_tests
  exit $?
fi