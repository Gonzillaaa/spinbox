# Spinbox Integration Testing

Integration and installation testing for real-world Spinbox usage scenarios.

## Quick Start

```bash
# Use the new unified test runner (recommended)
cd testing
./test-runner.sh --integration      # Run integration tests
./test-runner.sh --end-to-end       # Run end-to-end tests
./test-runner.sh --all              # Run all tests

# Or run individual test suites directly
./integration/workflow-scenarios.sh    # 8 user workflow scenarios
./end-to-end/installation-scenarios.sh # Comprehensive system testing
```

## New Testing Structure

### Reorganized Testing Framework

The testing framework has been reorganized into a standard structure:

```
testing/
├── unit/
│   ├── core-functionality.sh    # Core library and CLI tests (72 tests)
│   └── test-utils.sh            # Shared testing utilities
├── integration/
│   ├── cli-integration.sh       # CLI integration tests
│   └── workflow-scenarios.sh    # Real-world workflow tests (formerly test-integration.sh)
├── end-to-end/
│   └── installation-scenarios.sh # Installation tests (formerly test-all-scenarios.sh)
└── test-runner.sh               # Unified test entry point
```

### Integration Tests

| Script | Purpose | Use Case |
|--------|---------|----------|
| `testing/integration/workflow-scenarios.sh` | 8 user workflow scenarios | Quick workflow validation |
| `testing/end-to-end/installation-scenarios.sh` | Comprehensive system testing | Full system validation |

### Functionality Tests

| Script | Purpose | Use Case |
|--------|---------|----------|
| `test-cli-reference.sh` | CLI reference documentation validation | Verify CLI matches docs |
| `test-component-generators.sh` | Component generator testing | Test all generators |
| `test-advanced-cli.sh` | Advanced CLI features testing | Test version overrides, templates |
| `test-project-creation.sh` | Real project creation validation | Test actual file generation |
| `test-update-system.sh` | Update/backup/rollback testing | Test update functionality |
| `test-profiles.sh` | Profile parsing and validation | Test all profile definitions |

### Utility Scripts

| Script | Purpose |
|--------|---------|
| `remove-installed.sh` | Complete uninstallation helper |

## testing/integration/workflow-scenarios.sh

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

## Functionality Test Scripts

### test-component-generators.sh

Tests all component generators and identifies missing implementations:

- **Existing Generators**: Tests FastAPI, Next.js, PostgreSQL, Python, Node generators
- **Missing Generators**: Identifies missing MongoDB, Redis, Chroma generators
- **CLI Integration**: Tests component flags (`--mongodb`, `--redis`, etc.)
- **Component Combinations**: Tests common component combinations
- **Real Implementation**: Validates generators create actual files

Runtime: ~10-15 seconds

### test-advanced-cli.sh

Tests advanced CLI features beyond basic commands:

- **Version Overrides**: Tests `--python-version`, `--node-version`, `--postgres-version` flags
- **Template Selection**: Tests `--template` flag with all documented templates
- **Force Flag**: Tests `--force` flag behavior
- **Configuration Operations**: Tests `spinbox config --set`, `--reset`, `--setup`
- **Update Features**: Tests advanced update flags (`--version`, `--force`, `--yes`)
- **Add Command**: Tests `spinbox add` with version overrides and multiple components

Runtime: ~15-20 seconds

### test-project-creation.sh

Tests actual file and directory generation (non-dry-run mode):

- **Real Project Creation**: Creates actual projects using profiles and components
- **File Structure Validation**: Verifies expected files and directories are created
- **Configuration Validation**: Tests DevContainer and Docker Compose file generation
- **JSON/YAML Validation**: Validates syntax of generated configuration files
- **Requirements/Package Files**: Tests Python requirements.txt and Node package.json generation
- **Project Structure**: Validates proper directory structure for different project types

Runtime: ~20-30 seconds (creates and cleans up real projects)

### test-update-system.sh

Tests update, backup, and rollback functionality:

- **Update Check**: Tests `spinbox update --check` and version information
- **Dry Run**: Tests `spinbox update --dry-run` preview functionality
- **Version-Specific Updates**: Tests `spinbox update --version X.Y.Z`
- **Force Updates**: Tests `spinbox update --force` behavior
- **Backup Functionality**: Tests backup creation and rollback mechanisms
- **Installation Detection**: Tests detection of different installation methods
- **Error Handling**: Tests error conditions and helpful error messages

Runtime: ~10-15 seconds

### test-cli-reference.sh

Comprehensive CLI reference documentation validation:

- **All Commands**: Tests every command documented in `docs/user/cli-reference.md`
- **All Flags**: Tests all documented options and flags
- **Exit Codes**: Validates proper exit codes for success and error conditions
- **Help System**: Tests help for all commands and flag combinations
- **Error Messages**: Validates user-friendly error messages
- **Profile Validation**: Tests all 6 documented profiles work correctly

Runtime: ~5-10 seconds

### test-profiles.sh

Profile-specific testing and validation:

- **Profile Parsing**: Tests all profile definition files can be parsed
- **Profile Creation**: Tests project creation with each profile
- **Component Mapping**: Validates profiles include expected components
- **Template Assignment**: Tests profiles use correct requirements templates

Runtime: ~10-15 seconds

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

# Test CLI functionality
./test-cli-reference.sh

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

# Test specific functionality areas
./test-component-generators.sh
./test-advanced-cli.sh
```

### 4. Testing New Features
```bash
# Test component generators
./test-component-generators.sh

# Test advanced CLI features
./test-advanced-cli.sh

# Test real project creation
./test-project-creation.sh

# Test update system
./test-update-system.sh
```

### 5. Complete System Validation
```bash
# Run everything (takes ~2-3 minutes)
./test-all-scenarios.sh

# Run all functionality tests
./test-cli-reference.sh
./test-component-generators.sh
./test-advanced-cli.sh
./test-project-creation.sh
./test-update-system.sh
```

### 6. Cleaning Up After Testing
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