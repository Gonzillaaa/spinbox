# Spinbox Testing Suite

A comprehensive, organized, and reliable testing framework for Spinbox following standard testing practices.

## Philosophy: Keep Testing Super Simple

This testing framework follows the principle of **minimal complexity**:
- ✅ Fast execution (< 10 seconds for unit tests)
- ✅ Minimal dependencies
- ✅ Essential coverage only
- ✅ Self-contained assertions
- ✅ No infinite loops or hanging tests
- ✅ Standard directory structure

## Quick Start

```bash
# Run all tests (recommended)
./test-runner.sh

# Run only unit tests (fastest)
./test-runner.sh --unit

# Run specific test suites
./test-runner.sh --integration
./test-runner.sh --end-to-end

# Quick feedback during development
./test-runner.sh --quick
```

That's it! One command, everything tested.

## Directory Structure

```
testing/
├── unit/
│   └── core-functionality.sh    # Core library and CLI tests (77 tests)
├── integration/
│   ├── cli-integration.sh       # CLI integration tests
│   └── workflow-scenarios.sh    # Real-world workflow tests
├── workflows/
│   ├── advanced-cli.sh          # Advanced CLI features tests
│   ├── cli-reference.sh         # CLI reference validation tests
│   ├── component-generators.sh  # Component generator tests
│   ├── profiles.sh              # Profile validation tests
│   ├── project-creation.sh      # Project creation tests
│   └── update-system.sh         # Update system tests
├── end-to-end/
│   └── installation-scenarios.sh # Installation and deployment tests
├── test-utils.sh                # Shared testing utilities
└── test-runner.sh               # Unified test entry point
```

## Test Categories

### Unit Tests (`testing/unit/`)
- **Core Functionality** - Library functions, configuration, version handling
- **CLI Commands** - All CLI commands (help, version, create, config, profiles)
- **Profile Validation** - All 6 predefined profiles
- **Component Validation** - Generator existence and structure
- **Smoke Tests** - Key files, executability, configuration system
- **Coverage**: 77 tests, < 10 seconds execution

### Integration Tests (`testing/integration/`)
- **CLI Integration** - Command parsing, flag handling, error cases
- **Workflow Scenarios** - Real user workflows end-to-end
- **Cross-component Testing** - Components working together
- **Coverage**: Real-world usage patterns, < 2 minutes execution

### Workflow Tests (`testing/workflows/`)
- **Advanced CLI Features** - Version overrides, templates, force flags
- **CLI Reference Validation** - CLI documentation compliance
- **Component Generator Testing** - All component generators
- **Profile Validation** - Profile parsing and validation
- **Project Creation** - Real project creation
- **Update System** - Update/backup/rollback functionality
- **Coverage**: Feature-specific workflows, advanced functionality

### End-to-End Tests (`testing/end-to-end/`)
- **Installation Scenarios** - Local, global, remote installations
- **Platform Testing** - Different installation methods
- **Edge Cases** - Error recovery, permission issues
- **Coverage**: Complete deployment scenarios, several minutes execution

## Test Runner Options

The unified test runner provides multiple options:

```bash
# Test suite options
./test-runner.sh              # Run standard tests (unit + integration) - default
./test-runner.sh --all        # Run all test suites
./test-runner.sh --unit       # Unit tests only
./test-runner.sh --integration # Integration tests only
./test-runner.sh --workflows  # Workflow tests only

# Help
./test-runner.sh --help              # Show all options
```

## User Testing Workflows

### Integration Test Suites

#### Quick Integration Testing
```bash
# Run integration tests only
./test-runner.sh --integration      # Run integration tests
./test-runner.sh --end-to-end       # Run end-to-end tests

# Or run individual test suites directly
./integration/workflow-scenarios.sh    # 8 user workflow scenarios
./end-to-end/installation-scenarios.sh # Comprehensive system testing
```

#### Workflow Scenarios (`testing/integration/workflow-scenarios.sh`)

Tests 8 critical user workflows:

1. **Developer Workflow** - Running spinbox directly from source without installation
2. **New User Installation** - First-time user installing and using spinbox
3. **System Administrator** - Installing spinbox system-wide for all users
4. **Profile Migration** - Transitioning from old minimal profile to python/node
5. **Update Workflow** - Checking for updates and version management
6. **Multiple Installation Cleanup** - Removing all spinbox installations
7. **Cross-Mode Consistency** - Verifying dev and production modes match
8. **Error Recovery** - Handling common errors gracefully

Runtime: ~30-60 seconds

#### Installation Scenarios (`testing/end-to-end/installation-scenarios.sh`)

Comprehensive testing suite with modular phases:

```bash
./installation-scenarios.sh              # Run all tests
./installation-scenarios.sh --dev        # Test development mode only
./installation-scenarios.sh --local      # Test user installation only
./installation-scenarios.sh --global     # Test system installation only
./installation-scenarios.sh --remote     # Test remote installation (needs network)
./installation-scenarios.sh --edge       # Test edge cases and error handling
./installation-scenarios.sh --skip-cleanup  # Skip cleanup between tests
./installation-scenarios.sh --help       # Show all options
```

**Phases:**
1. Development Mode Tests
2. Local Installation Tests  
3. Global Installation Tests
4. Remote Installation Tests (GitHub)
5. Edge Cases and Error Handling
6. Architecture Consistency Tests

Runtime: ~2-3 minutes for full suite

### Common Testing Scenarios

#### 1. Before Creating a Pull Request
```bash
# Run core tests
./test-runner.sh --unit
./test-runner.sh --integration

# If making installation changes, also run:
./test-runner.sh --end-to-end
```

#### 2. Testing New Installation
```bash
# Test local user installation
./end-to-end/installation-scenarios.sh --local

# Test system-wide installation
./end-to-end/installation-scenarios.sh --global
```

#### 3. Testing Development Changes
```bash
# Test development mode specifically
./end-to-end/installation-scenarios.sh --dev

# Test core functionality
./test-runner.sh --unit
```

#### 4. Complete System Validation
```bash
# Run everything (takes ~2-3 minutes)
./test-runner.sh --all
```

#### 5. Cleaning Up After Testing
```bash
# Remove all Spinbox installations
./uninstall.sh --config --force
```

## What's Tested

### Core Library Functions (Unit Tests)
- **Configuration Loading** - Config file creation and variable loading
- **Version Substitution** - Python/Node version handling in templates
- **File Generation** - Template processing and file creation
- **Error Handling** - Fallback behavior and validation
- **Integration** - Component interaction and configuration persistence

### CLI Functionality (Unit + Integration Tests)
- **Command Execution** - All CLI commands (help, version, create, config, profiles)
- **Profile Validation** - All 6 predefined profiles (web-app, api-only, data-science, ai-llm, python, node)
- **Project Creation** - Dry-run validation of project creation workflows
- **Error Cases** - Invalid inputs and failure scenario handling
- **Component Generators** - Existence and structure validation

### Real-World Scenarios (Integration + End-to-End Tests)
- **User Workflows** - Complete development workflows
- **Installation Methods** - Local, global, remote installations
- **Cross-platform Testing** - Different shells and environments
- **Error Recovery** - Graceful failure handling

## Test Results Summary

```
Unit Tests: 77 tests ✅
- Core functionality: 73 tests ✅
- Additional smoke tests: 4 tests ✅
- Fast execution (< 10 seconds) ✅
- Zero hanging or infinite loops ✅

Integration Tests: Multiple suites ✅
- CLI integration coverage ✅
- Workflow scenario validation ✅
- Moderate execution time (< 2 minutes) ✅

End-to-End Tests: Comprehensive coverage ✅
- Installation scenario testing ✅
- Platform compatibility ✅
- Edge case handling ✅
```

## Writing Tests

### Using Test Utils

The framework provides shared utilities in `testing/test-utils.sh`:

```bash
# Source the utilities
source testing/test-utils.sh

# Setup test environment
setup_test_environment "My Test Suite"

# Use assertion functions
assert_true '[[ -f "file.txt" ]]' "File exists"
assert_equals "expected" "$actual" "Values match"
assert_contains "$string" "substring" "String contains text"
assert_file_exists "path/to/file" "File was created"
assert_executable "path/to/script" "Script is executable"

# Show test results
show_test_summary "My Test Suite"
```

### Test Structure

All tests follow this pattern:
1. **Setup** - Use `setup_test_environment`
2. **Execute** - Run test functions with proper assertions
3. **Cleanup** - Automatic cleanup via trap handlers
4. **Results** - Use `show_test_summary` for final results

## Integration

The framework is completely self-contained:

- ✅ Single command execution via test-runner.sh
- ✅ Minimal external dependencies
- ✅ No hanging or timeout issues
- ✅ Clear, colored output
- ✅ Proper cleanup mechanisms
- ✅ Standard directory structure

## Understanding Test Output

### Integration Test Output
```
Test 1: Developer Workflow
Description: Developer clones repo and runs spinbox directly
---------------------------------
✓ PASSED

Test 2: New User Installation
Description: User installs spinbox locally and creates first project
---------------------------------
✗ FAILED
```

### Installation Test Output
```
=== Phase 1: Development Mode Tests ===
✓ dev_binary_exists: Development binary found
✓ dev_version: Command succeeded as expected
✓ dev_ai_profile: Enhanced AI/LLM profile found
✓ dev_profile_count: Correct profile count: 6

=== Phase 2: Local Installation Tests ===
✓ local_install: Command succeeded as expected
✓ local_binary_installed: Local binary installed
✓ local_source_created: Centralized source created
```

## Troubleshooting

### Common Issues

**Installation tests fail**
- Run `./uninstall.sh --config --force` to clean up first
- Check you have proper permissions (sudo for global install)
- Ensure no existing installations conflict

**Remote tests fail**
- Check internet connectivity
- Verify GitHub repository is accessible
- May fail if testing unpublished changes

**Edge case tests fail**
- Some edge cases test expected failures
- Check the specific test output for details

### Debug Mode

Test scripts support debug output:
```bash
VERBOSE=true ./test-runner.sh
DEBUG=1 ./integration/workflow-scenarios.sh
```

Check the log file for detailed output:
```bash
tail -f /tmp/spinbox-test-*.log
```

## Test Coverage Analysis

### ✅ Well-Tested Areas

**Basic CLI Functionality:**
- Version and help commands
- Profile listing and validation
- Basic project creation with dry-run mode
- Configuration listing and basic operations
- Installation workflows (local, global, development)
- Integration scenarios and user workflows

**Core Test Coverage:**
- `unit/core-functionality.sh` - 77 tests covering all core functionality
- `integration/cli-integration.sh` - CLI integration and performance tests
- `integration/workflow-scenarios.sh` - 8 user workflow scenarios
- `end-to-end/installation-scenarios.sh` - Comprehensive installation testing

### 📊 Advanced Test Coverage

**Workflow Tests:**

The workflow tests in `testing/workflows/` provide comprehensive coverage of advanced features:

1. **Component Generators**
   - All generators are implemented and tested (mongodb, redis, chroma, etc.)
   - Component combinations are validated
   - CLI flags are properly integrated

2. **Advanced CLI Features**
   - Version override flags (`--python-version`, `--node-version`, etc.)
   - Template selection (`--template data-science`, etc.)
   - Force flag (`--force`) behavior
   - Configuration set/reset operations

3. **Real Project Creation**
   - Actual file and directory generation (beyond dry-run)
   - DevContainer configuration validation
   - Docker Compose file generation
   - Requirements.txt template processing

4. **Update System**
   - Backup creation and rollback functionality
   - Installation method detection
   - Version-specific updates
   - Error handling in update scenarios

## Migration Notes

This framework replaces the previous scattered test scripts:

**Old Structure:**
- ❌ 6 different test entry points
- ❌ Duplicated cleanup code
- ❌ Inconsistent patterns
- ❌ Complex dependencies

**New Structure:**
- ✅ Single unified entry point
- ✅ Centralized common utilities
- ✅ Standard directory organization
- ✅ Consistent testing patterns
- ✅ Zero test coverage loss (all 77 tests preserved)

**Total Test Coverage:**
- **Unit Tests:** 77 tests (comprehensive core functionality)
- **Integration Tests:** 21+ tests (CLI and workflow scenarios)
- **Workflow Tests:** 100+ tests (advanced features and real-world usage)
- **End-to-End Tests:** 50+ tests (installation and deployment)

## Cleanup and Maintenance

The testing framework includes comprehensive cleanup mechanisms:

- **Automatic cleanup** via trap handlers in all test scripts
- **Manual cleanup** using `./uninstall.sh --config --force`
- **Test artifact removal** for all temporary files and directories
- **Installation cleanup** for both user and system installations

All test scripts follow proper cleanup patterns to ensure no artifacts are left behind.

---

**Remember: Always keep testing super simple while maintaining comprehensive coverage!**