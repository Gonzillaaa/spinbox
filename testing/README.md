# Spinbox Testing Suite

A minimal, fast, and reliable testing framework for Spinbox core functionality.

## Philosophy: Keep Testing Super Simple

This testing framework follows the principle of **minimal complexity**:
- ✅ Fast execution (< 5 seconds)
- ✅ No dependencies
- ✅ Essential coverage only
- ✅ Self-contained assertions
- ✅ No infinite loops or hanging tests

## Quick Start

```bash
# Run the complete test suite (recommended)
./quick-test.sh
```

That's it! One command, everything tested.

## Test Files

### Ultra-Simple Test Framework

- **`simple-test.sh`** - Core functionality tests (73 tests)
- **`with-flags-test.sh`** - Component flag tests (17 tests)
- **`framework-test.sh`** - Framework generator tests (29 tests)
- **`deps-examples-test.sh`** - Dependencies/examples tests (8 tests)
- **`quick-test.sh`** - Main test runner with additional smoke tests

### What's Tested

The framework provides comprehensive coverage:

**Core Library Functions:**
- **Configuration Loading** - Config file creation and variable loading
- **Version Substitution** - Python/Node version handling in templates
- **File Generation** - Template processing and file creation
- **Error Handling** - Fallback behavior and validation
- **Integration** - Component interaction and configuration persistence

**CLI Functionality:**
- **Command Execution** - All CLI commands (help, version, create, config, profiles)
- **Profile Validation** - All 5 predefined profiles (web-app, api-only, data-science, ai-llm, minimal)
- **Project Creation** - Dry-run validation of project creation workflows
- **Error Cases** - Invalid inputs and failure scenario handling
- **Component Generators** - Existence and structure validation

**Framework Generators:**
- **Data Science Component** - Generator file existence, functions, and integration
- **AI/ML Component** - Generator file existence, functions, and integration
- **CLI Integration** - New framework flags parsing and help text
- **Examples Integration** - Framework examples generation support
- **Profile Integration** - Framework-specific profile configurations

## Test Results

```
127 comprehensive tests ✅
• 73 core functionality tests ✅
• 17 component flag tests ✅ 
• 29 framework generator tests ✅
• 8 dependencies/examples tests ✅
Core library functionality ✅
Complete CLI command coverage ✅
All 5 profiles validated ✅
Framework generators validated ✅
Project creation workflows ✅
Error handling and edge cases ✅
Fast execution (< 5 seconds) ✅
No infinite loops ✅
Zero dependencies ✅
```

## Writing Tests

Keep it simple! Use the basic assertion functions:

```bash
# Test assertions
test_assert '[[ -f "file.txt" ]]' "File exists"
test_equals "expected" "$actual" "Values match"
test_contains "$string" "substring" "String contains text"
test_file_exists "path/to/file" "File was created"
```

## Integration

The minimal framework is completely self-contained:

- ✅ Single command execution
- ✅ No external dependencies or wrappers
- ✅ No hanging or timeout issues
- ✅ Clear, colored output

## Migration Notes

This framework replaces the previous complex test suite that had:
- ❌ 115+ test functions with infinite loops
- ❌ Complex dependencies and setup
- ❌ Long execution times
- ❌ Reliability issues

The new framework provides comprehensive coverage with:
- ✅ 127 focused tests covering library, CLI, and framework functionality
- ✅ Zero dependencies
- ✅ Sub-5-second execution
- ✅ 100% reliability

---

**Remember: Always keep testing super simple!**