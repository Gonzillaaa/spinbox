# Documentation Review Process

A systematic guide for conducting comprehensive documentation reviews in the Spinbox project. This process should be performed after each major release or when significant changes are made to project functionality.

## Overview

Documentation reviews ensure consistency, accuracy, and usability across all project documentation. This guide provides a methodical approach to identify and fix common documentation issues.

## When to Perform Reviews

### Mandatory Reviews
- **After major releases** (e.g., v0.1.0-beta.5 → v0.1.0-beta.6)
- **After platform changes** (adding/removing supported platforms)
- **After new feature additions** (e.g., --with-deps flag)
- **After file structure changes** (moving/renaming documentation files)
- **After backlog/roadmap updates** (align documentation with current planning)

### Optional Reviews
- **Quarterly maintenance reviews**
- **Before preparing for stable releases**
- **When user feedback indicates documentation issues**

## Pre-Review Setup

### 1. Environment Preparation
```bash
# Ensure you're on the latest main branch
git checkout main
git pull origin main

# Check current project status
spinbox --version
git status
```

### 2. Documentation Inventory
Create a list of all documentation files:
```bash
# List all documentation files
find docs/ -name "*.md" | sort > docs-inventory.txt

# Review main project files
ls -la README.md CLAUDE.md
```

## Review Categories

The review process covers five main categories of issues:

### 🔴 **Critical Errors** (Must Fix Immediately)
Issues that break functionality or provide incorrect information.

### 🟡 **Inconsistencies** (High Priority)
Content conflicts between files or outdated information.

### 🟠 **Missing Items** (Medium Priority)
Gaps in documentation or incomplete sections.

### 🔵 **Redundant Items** (Medium Priority)
Duplicate information that should be consolidated.

### 📁 **File Organization** (Low Priority)
Structural improvements and naming conventions.

## Systematic Review Process

### Phase 1: Critical Error Detection

#### Step 1.1: Version Reference Audit
```bash
# Find all version references in documentation
grep -r "v0\.1\.0-beta\." docs/ README.md CLAUDE.md

# Check for specific version patterns
grep -r "beta\.[0-9]" docs/
grep -r "Spinbox v" docs/
```

**Common Issues:**
- Old version numbers in installation guides
- Outdated version references in release notes
- Inconsistent version format (v0.1.0-beta.5 vs 0.1.0-beta.5)

**Fix Pattern:**
```bash
# Update version references systematically
# docs/user/installation.md
# docs/user/quick-start.md  
# docs/releases/README.md
# docs/dev/release-process.md
```

#### Step 1.2: Platform Support Audit
```bash
# Find platform references
grep -r -i "windows" docs/
grep -r -i "wsl" docs/
grep -r "macos\|linux\|windows" docs/
```

**Common Issues:**
- References to unsupported platforms
- Installation instructions for wrong platforms
- Platform requirement tables with outdated info

#### Step 1.3: Broken Link Detection
```bash
# Find internal documentation links
grep -r "\]\(\..*\.md\)" docs/
grep -r "\]\(\./.*\.md\)" docs/

# Find missing file references
grep -r "docs/.*\.md" docs/ | grep -v "\.md:" | cut -d: -f2 | sort | uniq
```

**Common Issues:**
- Links to moved files (docs/troubleshooting.md → docs/user/troubleshooting.md)
- References to non-existent files
- Relative path errors after file moves

### Phase 2: Content Consistency Review

#### Step 2.1: Cross-Reference Analysis
```bash
# Check for file moves needed
ls -la docs/dependency-management.md 2>/dev/null
ls -la docs/dev/chroma-usage.md 2>/dev/null

# Verify proper file organization
ls docs/user/
ls docs/dev/
```

**File Organization Rules:**
- **docs/user/**: End-user documentation (installation, quick-start, CLI reference, troubleshooting)
- **docs/dev/**: Developer/contributor documentation (implementation, strategy, release process)
- **docs/releases/**: Release notes and version history

#### Step 2.2: Content Contradiction Detection
```bash
# Check for contradictory information
grep -r "planned\|future\|upcoming" docs/
grep -r "not yet\|coming soon" docs/
```

**Common Issues:**
- Features described as "planned" that are actually implemented
- Conflicting information about supported features
- Outdated status information

#### Step 2.3: Navigation Consistency
Review main navigation files:
- `docs/README.md` - Documentation index
- `README.md` - Main project documentation section
- Cross-references between files

### Phase 3: Completeness Assessment

#### Step 3.1: Missing Documentation Detection
```bash
# Check for new features without documentation
grep -r "with-deps" docs/user/troubleshooting.md || echo "Missing --with-deps troubleshooting"

# Verify all user-facing features are documented
spinbox --help | grep -E "^\s+--" | while read flag; do
  echo "Checking $flag in documentation..."
  grep -r "$flag" docs/user/ || echo "Missing: $flag"
done
```

#### Step 3.2: Cross-Reference Gaps
```bash
# Find missing cross-references
grep -r "dependency.management" docs/ || echo "dependency-management.md not referenced"
grep -r "chroma.usage" docs/ || echo "chroma-usage.md not referenced"
```

### Phase 4: Redundancy Elimination

#### Step 4.1: Installation Content Audit
Review these files for redundant installation instructions:
- `README.md` (should have basic quick-start only)
- `docs/user/installation.md` (detailed instructions)
- `docs/user/quick-start.md` (5-minute tutorial only)

#### Step 4.2: Command Example Consolidation
```bash
# Find duplicate command examples
grep -r "spinbox create" docs/ | cut -d: -f2 | sort | uniq -c | sort -nr
```

## Implementation Workflow

### Step 1: Plan the Review
```bash
# Create a todo list for tracking
# Use TodoWrite tool to organize tasks by priority
# Update backlog.md with documentation review story points
# Reference roadmap.md for strategic documentation needs
```

### Step 2: Execute by Priority
1. **Critical Errors** (Phase 1) - Fix immediately
2. **Content Improvements** (Phase 2) - Medium priority  
3. **Organization & Polish** (Phase 3) - Low priority

### Step 3: File Operations
```bash
# Moving files (update cross-references after)
mv docs/file.md docs/user/file.md

# Updating cross-references
grep -r "old-path" docs/ | cut -d: -f1 | xargs sed -i 's|old-path|new-path|g'
```

### Step 4: Verification
```bash
# Check all links work
find docs/ -name "*.md" -exec grep -l "\]\(" {} \; | while read file; do
  echo "Checking links in $file..."
  # Manual verification of each file
done
```

## Quality Assurance Checklist

### Pre-Commit Verification
- [ ] All version references updated to current version
- [ ] No broken internal links remain  
- [ ] Platform support is consistent and accurate
- [ ] File organization follows docs/user/ vs docs/dev/ convention
- [ ] Navigation in docs/README.md is complete and accurate

### Post-Review Testing
- [ ] Generate test project: `spinbox create test-review --profile web-app`
- [ ] Verify documentation accuracy by following quick-start guide
- [ ] Check troubleshooting sections with common user scenarios
- [ ] Validate all cross-references by clicking through documentation

## Common Patterns and Fixes

### Version Update Pattern
```bash
# Find and replace version references
find docs/ -name "*.md" -exec sed -i 's/v0\.1\.0-beta\.4/v0.1.0-beta.5/g' {} \;
find . -name "README.md" -exec sed -i 's/v0\.1\.0-beta\.4/v0.1.0-beta.5/g' {} \;
```

### Cross-Reference Update Pattern
```bash
# Update moved file references
find docs/ -name "*.md" -exec sed -i 's|docs/troubleshooting\.md|docs/user/troubleshooting.md|g' {} \;
```

### Platform Reference Cleanup
```bash
# Remove Windows references
grep -r -l -i "windows\|wsl" docs/ | while read file; do
  echo "Reviewing Windows references in $file"
  # Manual review and removal required
done
```

## Tools and Automation

### Useful Commands
```bash
# Find all markdown files
find . -name "*.md" | grep -E "(docs|README|CLAUDE)" | sort

# Check for broken links (requires manual verification)
grep -r "\]\(" docs/ | grep -v "http" | cut -d: -f1 | sort | uniq

# Find version references  
grep -r "v[0-9]\+\.[0-9]\+\.[0-9]\+-beta\.[0-9]\+" docs/

# List file structure
tree docs/ | grep "\.md$"
```

### Validation Scripts
Consider creating automation for:
- Version consistency checks
- Broken link detection
- File organization validation
- Cross-reference verification

## Documentation Standards

### File Naming Convention
- **User docs**: descriptive names (installation.md, quick-start.md, troubleshooting.md)
- **Dev docs**: purpose-based names (release-process.md, adding-components.md)
- **Process docs**: action-based names (documentation-review-process.md)

### Content Standards
- **Version references**: Always use full version (v0.1.0-beta.5)
- **Platform support**: Only mention supported platforms (macOS, Linux)
- **Cross-references**: Use relative paths from file location
- **Code examples**: Always test and verify accuracy

## Review Frequency

### Regular Schedule
- **After each beta release**: Complete review
- **Monthly**: Quick consistency check
- **Quarterly**: Full structural review
- **Before stable release**: Comprehensive audit

### Trigger Events
- New feature releases
- Platform support changes
- File structure modifications
- User feedback about documentation issues

## Success Metrics

A successful documentation review should achieve:

- ✅ **Zero broken internal links**
- ✅ **Consistent version references throughout**
- ✅ **Accurate platform support information**
- ✅ **Logical file organization**
- ✅ **Complete cross-reference network**
- ✅ **No contradictory information**
- ✅ **Coverage of all user-facing features**

## Post-Review Actions

### Immediate
1. Test documentation by following user workflows
2. Update any automation scripts with new file paths
3. Inform team of significant documentation changes

### Long-term
1. Monitor user feedback for documentation gaps
2. Track documentation quality metrics
3. Improve this review process based on lessons learned

---

## Example Review Execution

For reference, here's how the v0.1.0-beta.5 review was executed:

### Phase 1 - Critical Issues (2-3 hours)
1. Updated 5 files with version references from beta.4 to beta.5
2. Removed Windows installation sections from installation.md
3. Fixed 6 broken cross-reference paths

### Phase 2 - Content Issues (2-3 hours)  
1. Moved dependency-management.md and chroma-usage.md to docs/user/
2. Updated 3 cross-references after file moves
3. Added dependency management to main navigation
4. Clarified chroma-usage.md disclaimer language

### Phase 3 - Polish (2-3 hours)
1. Consolidated redundant installation content in README.md and quick-start.md
2. Added comprehensive --with-deps troubleshooting section
3. Reorganized docs/README.md navigation structure

**Total effort**: 6-9 hours for comprehensive review
**Files modified**: 12 documentation files
**Issues resolved**: 25+ documentation problems
**Backlog updated**: Added 8 SP for documentation work
**Roadmap impact**: Aligned documentation with v0.2.0 planning

This systematic approach ensures consistent, accurate, and user-friendly documentation across the entire project. All documentation work should be tracked in the backlog with appropriate story point estimates for velocity planning.