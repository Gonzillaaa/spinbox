# Spinbox Manual Permutation Testing

This directory contains tools for comprehensive manual testing of all possible Spinbox project combinations to detect structural bugs that automated tests might miss.

## Background

The need for these tools arose from discovering that the `--nextjs` flag was incorrectly creating both a Next.js application AND a separate Express.js backend. Our existing tests didn't catch this structural issue, highlighting the need for manual inspection of generated projects.

## Tools

### 1. `run-permutation-tests.sh` (Recommended)

**Unified runner that executes both generation and analysis in one go.**

```bash
# Basic usage - generates and analyzes
./run-permutation-tests.sh

# Skip analysis (generation only)
./run-permutation-tests.sh --skip-analysis

# Open results in file manager after completion (macOS/Linux)
./run-permutation-tests.sh --open

# Show help
./run-permutation-tests.sh --help
```

### 2. `generate-all-permutations.sh`

**Generates ~70+ test projects covering all component combinations.**

```bash
# Run from any directory - creates test folder in current location
./generate-all-permutations.sh

# Output: spinbox-permutation-test-YYYYMMDD-HHMMSS/
```

Test categories:
- Single components (8 tests)
- Two-component combinations (~20 tests)
- Three+ component combinations (~15 tests)
- Feature flag variations (10 tests)
- Profile tests (8 tests)
- Edge cases (3 tests)

### 3. `analyze-permutations.sh`

**Scans generated projects for common structural issues.**

```bash
# Analyze a test directory
./analyze-permutations.sh ./spinbox-permutation-test-20250720-143000
```

Checks for:
- Dual application structures (like the Next.js bug)
- Unexpected file placements
- Missing DevContainer configurations
- Suspiciously small projects
- Database-only project issues
- Profile consistency problems

## Workflow

### Quick Test (Recommended)

```bash
# From project root or any test directory
cd /tmp  # or anywhere you want test output

# Run all tests and analysis
/path/to/spinbox/testing/manual/run-permutation-tests.sh

# Review flagged issues in the output
# Navigate to specific problematic projects for inspection
```

### Manual Process

```bash
# 1. Generate all permutations
./testing/manual/generate-all-permutations.sh

# 2. Run analysis
./testing/manual/analyze-permutations.sh ./spinbox-permutation-test-*

# 3. Inspect flagged projects
cd spinbox-permutation-test-*/
ls -la

# 4. Check individual projects
cd 04-nextjs-only/  # Example
cat INSPECT.md      # Review checklist
ls -la             # Check structure
```

## What to Look For

### Known Bug Patterns

1. **Dual Application Generation**
   - Component creates both intended and unintended base projects
   - Example: Next.js creating both Next.js app and Express.js server

2. **Wrong Directory Structure**
   - Files in root when they should be in subdirectories
   - Components overwriting each other's files

3. **Missing Dependencies**
   - Component doesn't set up required base environment
   - Missing package.json or requirements.txt

4. **Configuration Conflicts**
   - Incompatible DevContainer configurations
   - Docker Compose service conflicts

5. **Incorrect Defaults**
   - Wrong assumptions about component combinations
   - Hardcoded values that should be dynamic

## Bug Reporting

When you find a bug:

1. Document it in `MASTER-CHECKLIST.md` in the test directory
2. Use this template:

```
Project: [directory name]
Command: [spinbox command used]
Bug: [clear description]
Expected: [what should happen]
Actual: [what actually happened]
Impact: [severity/user impact]
```

3. Create a GitHub issue if it's a significant bug

## Files Generated

Each test run creates:

- `test-results.log` - Complete log of all operations
- `failed-tests.log` - List of failed project creations
- `MASTER-CHECKLIST.md` - Main inspection guide and bug tracking
- Individual project directories with:
  - Generated project files
  - `INSPECT.md` - Project-specific inspection checklist

## Tips

1. **Focus on Flagged Issues**: The analyzer highlights likely problems
2. **Compare Similar Projects**: Look for inconsistencies between similar combinations
3. **Check Edge Cases**: Pay special attention to unusual combinations
4. **Test Before Release**: Run these tests before any release to catch structural issues

## Example Issues to Find

```bash
# After running tests, you might find:

⚠️  04-nextjs-only: Has both src/ and nextjs/ directories
# This indicates the Next.js bug - it shouldn't create src/

⚠️  05-postgresql-only: Only 3 files
# Database-only might not make sense without a base component

⚠️  30-fastapi-nextjs-postgresql: Missing .devcontainer directory
# Multi-component project missing essential configuration
```

## Maintenance

These scripts should be updated when:
- New components are added to Spinbox
- New flags are introduced
- New profiles are created
- Bug patterns are discovered that need specific tests