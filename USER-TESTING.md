# Spinbox User Testing Guide

A comprehensive guide to testing Spinbox functionality, from quick unit tests to full integration scenarios.

## Quick Start

```bash
# Run unit tests (< 5 seconds) - Test core functionality
./testing/quick-test.sh

# Run integration tests - Test real user workflows
./scripts/test-integration.sh

# Run comprehensive system tests - Test everything
./scripts/test-all-scenarios.sh
```

## Testing Philosophy

Following CLAUDE.md principles:
- ✅ **Simple**: Clear test structure, no complex frameworks
- ✅ **Fast**: Unit tests < 5 seconds, integration tests < 30 seconds
- ✅ **Essential**: Focus on what users actually need
- ✅ **Reliable**: No infinite loops or hanging tests

## Testing Structure

### Unit Tests (`/testing/`)

Fast, focused tests for core Spinbox functionality.

| Script | Purpose | Runtime |
|--------|---------|---------|
| `simple-test.sh` | 68 unit tests for core library functions | ~1.3 sec |
| `quick-test.sh` | Main test runner (runs simple-test.sh) | < 5 sec |
| `cli-test.sh` | Additional CLI-specific tests | < 2 sec |

**What's tested:**
- Configuration loading and management
- Version substitution in templates
- File generation from templates
- Error handling and validation
- CLI command execution
- Profile validation (all 6 profiles)
- Component generators

### Integration Tests (`/scripts/`)

Real-world scenarios and installation testing.

| Script | Purpose | Use Case |
|--------|---------|----------|
| `test-integration.sh` | 8 user workflow scenarios | Quick workflow validation |
| `test-all-scenarios.sh` | Comprehensive system testing | Full system validation |

**test-integration.sh scenarios:**
1. Developer workflow (no installation)
2. New user installation journey
3. System administrator installation
4. Profile migration (minimal → python/node)
5. Update workflow
6. Multiple installation cleanup
7. Cross-mode consistency
8. Error recovery

**test-all-scenarios.sh options:**
```bash
./test-all-scenarios.sh              # Run all tests
./test-all-scenarios.sh --dev        # Test development mode only
./test-all-scenarios.sh --local      # Test user installation only
./test-all-scenarios.sh --global     # Test system installation only
./test-all-scenarios.sh --remote     # Test remote installation
./test-all-scenarios.sh --edge       # Test edge cases
./test-all-scenarios.sh --help       # Show all options
```

### Utility Scripts (`/scripts/`)

| Script | Purpose |
|--------|---------|
| `remove-installed.sh` | Complete uninstallation helper |

## Common Testing Scenarios

### 1. Before Creating a Pull Request
```bash
# Run all unit tests
./testing/quick-test.sh

# Run integration tests
./scripts/test-integration.sh

# If making installation changes, also run:
./scripts/test-all-scenarios.sh --local --global
```

### 2. Testing New Installation
```bash
# Test local user installation
./scripts/test-all-scenarios.sh --local

# Test system-wide installation
./scripts/test-all-scenarios.sh --global
```

### 3. Testing Development Changes
```bash
# Quick unit test during development
./testing/quick-test.sh

# Test development mode specifically
./scripts/test-all-scenarios.sh --dev
```

### 4. Complete System Validation
```bash
# Run everything (takes ~2-3 minutes)
./testing/quick-test.sh && ./scripts/test-all-scenarios.sh
```

### 5. Cleaning Up After Testing
```bash
# Remove all Spinbox installations
./scripts/remove-installed.sh
```

## Understanding Test Output

### Unit Test Output (simple-test.sh)
```
Testing: Config file created
✓ PASS: Config file created

Testing: Python version substitution  
✗ FAIL: Python version substitution
  Expected: 3.11
  Actual: 3.12
```

### Integration Test Output
```
Test 1: Developer Workflow
Description: Developer clones repo and runs spinbox directly
---------------------------------
✓ PASSED
```

## CI/CD Integration

For continuous integration:

```yaml
# Quick validation (< 10 seconds)
- run: ./testing/quick-test.sh

# Full validation (~ 2-3 minutes)
- run: |
    ./testing/quick-test.sh
    ./scripts/test-integration.sh
    ./scripts/test-all-scenarios.sh
```

## Troubleshooting

### Common Issues

**Tests fail with "command not found"**
- Ensure you're in the Spinbox project root directory
- Check that test scripts are executable: `chmod +x scripts/*.sh testing/*.sh`

**Installation tests fail**
- Run `./scripts/remove-installed.sh` to clean up first
- Check you have proper permissions (sudo for global install)

**Profile tests fail**
- Verify you have the latest code with 6 profiles (not 5)
- Check that minimal profile has been removed

### Debug Mode

Most test scripts support debug output:
```bash
DEBUG=1 ./testing/quick-test.sh
VERBOSE=true ./scripts/test-all-scenarios.sh
```

## Contributing Tests

When adding new tests:

1. **Unit tests** go in `/testing/simple-test.sh`
   - Use existing assertion functions
   - Keep tests fast (< 0.1 sec each)
   - Focus on one thing per test

2. **Integration tests** go in `/scripts/test-integration.sh`
   - Test real user workflows
   - Include setup and cleanup
   - Document what's being tested

Remember: Keep testing super simple!

---

For more details on unit tests, see [`/testing/README.md`](testing/README.md)