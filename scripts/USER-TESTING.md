# Spinbox Integration Testing

Integration and installation testing for real-world Spinbox usage scenarios.

## Quick Start

```bash
# Run integration tests - Test real user workflows
./test-integration.sh

# Run comprehensive system tests - Test everything
./test-all-scenarios.sh
```

## Scripts Overview

### Integration Tests

| Script | Purpose | Use Case |
|--------|---------|----------|
| `test-integration.sh` | 8 user workflow scenarios | Quick workflow validation |
| `test-all-scenarios.sh` | Comprehensive system testing | Full system validation |

### Utility Scripts

| Script | Purpose |
|--------|---------|
| `remove-installed.sh` | Complete uninstallation helper |

## test-integration.sh

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

## test-all-scenarios.sh

Comprehensive testing suite with modular phases:

```bash
./test-all-scenarios.sh              # Run all tests
./test-all-scenarios.sh --dev        # Test development mode only
./test-all-scenarios.sh --local      # Test user installation only
./test-all-scenarios.sh --global     # Test system installation only
./test-all-scenarios.sh --remote     # Test remote installation (needs network)
./test-all-scenarios.sh --edge       # Test edge cases and error handling
./test-all-scenarios.sh --skip-cleanup  # Skip cleanup between tests
./test-all-scenarios.sh --help       # Show all options
```

**Phases:**
1. Development Mode Tests
2. Local Installation Tests  
3. Global Installation Tests
4. Remote Installation Tests (GitHub)
5. Edge Cases and Error Handling
6. Architecture Consistency Tests

Runtime: ~2-3 minutes for full suite

## remove-installed.sh

Comprehensive uninstallation utility that:
- Removes both system (`/usr/local/bin/`) and user (`~/.local/bin/`) installations
- Cleans up old library directories from pre-centralized architecture
- Removes configuration and centralized source (`~/.spinbox/`)
- Cleans up test projects
- Provides clear feedback on what was removed

## Common Testing Scenarios

### 1. Before Creating a Pull Request
```bash
# Run integration tests
./test-integration.sh

# If making installation changes, also run:
./test-all-scenarios.sh --local --global
```

### 2. Testing New Installation
```bash
# Test local user installation
./test-all-scenarios.sh --local

# Test system-wide installation
./test-all-scenarios.sh --global
```

### 3. Testing Development Changes
```bash
# Test development mode specifically
./test-all-scenarios.sh --dev
```

### 4. Complete System Validation
```bash
# Run everything (takes ~2-3 minutes)
./test-all-scenarios.sh
```

### 5. Cleaning Up After Testing
```bash
# Remove all Spinbox installations
./remove-installed.sh
```

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

### test-all-scenarios.sh Output
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
- Run `./remove-installed.sh` to clean up first
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
VERBOSE=true ./test-all-scenarios.sh
DEBUG=1 ./test-integration.sh
```

Check the log file for detailed output:
```bash
tail -f /tmp/spinbox-test-*.log
```

## Related Testing

For unit testing of core functionality, see:
- [`/testing/README.md`](../testing/README.md) - Unit test documentation
- Run unit tests with: `../testing/quick-test.sh`

---

**Remember: Keep testing super simple!**