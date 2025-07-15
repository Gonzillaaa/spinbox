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
│   ├── core-functionality.sh    # Core library and CLI tests (72 tests)
│   └── test-utils.sh            # Shared testing utilities
├── integration/
│   ├── cli-integration.sh       # CLI integration tests
│   └── workflow-scenarios.sh    # Real-world workflow tests
├── end-to-end/
│   └── installation-scenarios.sh # Installation and deployment tests
└── test-runner.sh               # Unified test entry point
```

## Test Categories

### Unit Tests (`testing/unit/`)
- **Core Functionality** - Library functions, configuration, version handling
- **CLI Commands** - All CLI commands (help, version, create, config, profiles)
- **Profile Validation** - All 6 predefined profiles
- **Component Validation** - Generator existence and structure
- **Smoke Tests** - Key files, executability, configuration system
- **Coverage**: 72 tests, < 10 seconds execution

### Integration Tests (`testing/integration/`)
- **CLI Integration** - Command parsing, flag handling, error cases
- **Workflow Scenarios** - Real user workflows end-to-end
- **Cross-component Testing** - Components working together
- **Coverage**: Real-world usage patterns, < 2 minutes execution

### End-to-End Tests (`testing/end-to-end/`)
- **Installation Scenarios** - Local, global, remote installations
- **Platform Testing** - Different installation methods
- **Edge Cases** - Error recovery, permission issues
- **Coverage**: Complete deployment scenarios, several minutes execution

## Test Runner Options

The unified test runner provides multiple options:

```bash
# Test suite categories
./test-runner.sh --unit              # Unit tests only
./test-runner.sh --integration       # Integration tests only
./test-runner.sh --end-to-end        # End-to-end tests only
./test-runner.sh --all               # All tests (default)

# Quick options
./test-runner.sh --quick             # Unit tests only (fastest)

# Individual test suites
./test-runner.sh --core              # Core functionality only
./test-runner.sh --cli               # CLI integration only
./test-runner.sh --workflow          # Workflow scenarios only
./test-runner.sh --installation      # Installation scenarios only

# Help
./test-runner.sh --help              # Show all options
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
Unit Tests: 72 tests ✅
- Core functionality: 68 tests ✅
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

The framework provides shared utilities in `testing/unit/test-utils.sh`:

```bash
# Source the utilities
source testing/unit/test-utils.sh

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
- ✅ Zero test coverage loss (all 72 tests preserved)

## Related Testing

For additional testing information, see:
- **[scripts/USER-TESTING.md](../scripts/USER-TESTING.md)** - Complete testing guide
- **[scripts/TEST-GAP-ANALYSIS.md](../scripts/TEST-GAP-ANALYSIS.md)** - Coverage analysis

---

**Remember: Always keep testing super simple while maintaining comprehensive coverage!**