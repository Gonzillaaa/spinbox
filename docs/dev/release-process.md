# Spinbox Release Process

This document outlines the process for creating releases of Spinbox.

**Current Status**: v0.1.0-beta.5 is the latest release with automatic dependency management implemented.

## Semantic Versioning

Spinbox follows [Semantic Versioning](https://semver.org/):

- **MAJOR.MINOR.PATCH** for releases (e.g., `1.0.0`)
- **MAJOR.MINOR.PATCH-beta.N** for beta releases (e.g., `0.1.0-beta.1`)
- **MAJOR.MINOR.PATCH-alpha.N** for alpha releases (e.g., `0.1.0-alpha.1`)

### Pre-1.0 Releases
- Start with `0.1.0-beta.1`
- Breaking changes can occur between beta releases
- Use semantic versioning for version comparison

## Release Types

### Beta Releases
- **Purpose**: Feature testing, update functionality validation
- **Audience**: Early adopters, contributors, testers
- **Frequency**: As needed for major features
- **Stability**: Functional but may have breaking changes

### Stable Releases
- **Purpose**: Production-ready versions
- **Audience**: General users
- **Frequency**: When features are thoroughly tested
- **Stability**: No breaking changes within major version

## Release Process

### 1. Version Preparation

```bash
# Create release branch
git checkout main
git pull origin main
git checkout -b release/v0.1.0-beta.X

# Update version in main CLI script
sed -i 's/readonly VERSION=".*"/readonly VERSION="0.1.0-beta.6"/' bin/spinbox

# Verify version
./bin/spinbox --version
```

### 2. Testing

```bash
# Run full test suite
./testing/simple-test.sh

# Verify all tests pass
# Tests run: X
# Passed: X
# Failed: 0
```

### 3. Release Notes and Commit

```bash
# Create release notes
cat > docs/releases/v0.1.0-beta.X.md << 'EOF'
# Spinbox v0.1.0-beta.X

Released: $(date +%Y-%m-%d)

## 🆕 New Features
- [Feature 1]: Description

## 🐛 Bug Fixes  
- [Fix 1]: Description

[... rest of release notes template ...]
EOF

# Commit version bump and release notes
git add -A
git commit -m "chore: bump version to v0.1.0-beta.X"

# Push release branch
git push -u origin release/v0.1.0-beta.X

# Create annotated tag
git tag -a v0.1.0-beta.X -m "Release v0.1.0-beta.X

## Changes in this release
- [List key changes]
- [Bug fixes]
- [New features]

## Testing
- All tests passing
- [Specific testing notes]"

# Push tag
git push origin v0.1.0-beta.X
```

### 4. GitHub Release

```bash
# Create release using GitHub CLI
gh release create v0.1.0-beta.X \
  --title "🚀 Spinbox v0.1.0-beta.X (Beta Release)" \
  --notes-file docs/releases/v0.1.0-beta.X.md \
  --prerelease  # for beta releases
```

### 5. Post-Release Testing

```bash
# Test installation scripts with new release
bash scripts/test-local-install.sh
bash scripts/test-global-install.sh

# Test update functionality (if previous version exists)
spinbox update --check
spinbox update --dry-run
spinbox update --version v0.1.0-beta.X
```

## Release Notes Organization

### Location
- **Directory**: `docs/releases/`
- **Naming**: `v{VERSION}.md` (e.g., `v0.1.0-beta.5.md`)
- **Archive**: Keep all release notes for historical reference

### Current Releases
- **Latest**: v0.1.0-beta.5 ✅ **CURRENT** (Automatic dependency management, TOML templates, enhanced ecosystem)
- **Previous**: v0.1.0-beta.4 (Bug fixes, test infrastructure), v0.1.0-beta.2 (Foundation release)
- **Status**: All core functionality implemented and working

## Release Notes Template

```markdown
# Spinbox v0.1.0-beta.X

## 🆕 New Features
- [Feature 1]: Description
- [Feature 2]: Description

## 🐛 Bug Fixes
- [Fix 1]: Description
- [Fix 2]: Description

## 📚 Documentation
- [Doc update 1]: Description
- [Doc update 2]: Description

## 🧪 Testing
- X tests passing
- [Coverage improvements]

## ⚠️ Breaking Changes (for beta releases)
- [Breaking change 1]: Migration notes
- [Breaking change 2]: Migration notes

## 🔄 Update Instructions

For existing installations:
\`\`\`bash
spinbox update
\`\`\`

For new installations:
\`\`\`bash
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | sudo bash
\`\`\`

## Known Issues
- [Issue 1]: Workaround
- [Issue 2]: Workaround
```

## Testing Update Functionality

### Creating Test Releases

1. **Create Initial Release**: v0.1.0-beta.1
2. **Create Newer Release**: v0.1.0-beta.5 (latest)
3. **Test Update Path**: v0.1.0-beta.1 → v0.1.0-beta.5

### Update Testing Scenarios

```bash
# Test 1: Check for updates
spinbox update --check

# Test 2: Dry-run update
spinbox update --dry-run

# Test 3: Actual update
spinbox update

# Test 4: Specific version
spinbox update --version v0.1.0-beta.1

# Test 5: Force update (same version)
spinbox update --force
```

### Validation Checklist

- [x] ✅ Version detection works correctly
- [x] ✅ Update download succeeds
- [x] ✅ Backup creation works
- [x] ✅ Installation replacement works
- [x] ✅ Verification passes
- [x] ✅ Configuration preserved
- [x] ✅ Rollback works on failure

## Repository Requirements

### Public Repository
- GitHub releases API requires public repository access
- Private repositories need authentication for API access

### GitHub CLI Setup
```bash
# Authenticate with GitHub
gh auth login

# Verify access
gh release list
```

## Troubleshooting

### API Access Issues
- Verify repository is public or authenticated
- Check GitHub CLI authentication: `gh auth status`
- Test API access: `curl -s "https://api.github.com/repos/USER/REPO/releases"`

### Update Failures
- Check network connectivity
- Verify release exists: `gh release list`
- Test download URL manually
- Check file permissions for installation directory

### Version Comparison Issues
- Verify semantic version format
- Test version comparison: `spinbox update --check --verbose`
- Check for typos in version strings

## Security Considerations

- Never commit sensitive data in release notes
- Verify download integrity (checksums)
- Use HTTPS for all download URLs
- Validate version strings to prevent injection

## Automation Opportunities

Future improvements could include:
- GitHub Actions for automated releases
- Automated testing on multiple platforms
- Homebrew tap automation
- Release note generation from commits