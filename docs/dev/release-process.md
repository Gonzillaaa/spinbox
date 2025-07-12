# Spinbox Release Process

This document outlines the process for creating releases of Spinbox.

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
# Update version in main CLI script
sed -i 's/readonly VERSION=".*"/readonly VERSION="0.1.0-beta.2"/' bin/spinbox

# Update Homebrew formula (if needed)
sed -i 's|v0.1.0-beta.1|v0.1.0-beta.2|' Formula/spinbox.rb

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

### 3. Commit and Tag

```bash
# Commit version bump
git add -A
git commit -m "chore: bump version to v0.1.0-beta.2"

# Push changes
git push origin feature/cli-foundation

# Create annotated tag
git tag -a v0.1.0-beta.2 -m "Release v0.1.0-beta.2

## Changes in this release
- [List key changes]
- [Bug fixes]
- [New features]

## Testing
- All tests passing
- [Specific testing notes]"

# Push tag
git push origin v0.1.0-beta.2
```

### 4. GitHub Release

```bash
# Create release using GitHub CLI
gh release create v0.1.0-beta.2 \
  --title "🚀 Spinbox v0.1.0-beta.2 (Beta Release)" \
  --notes-file release-notes.md \
  --prerelease  # for beta releases
```

### 5. Post-Release Testing

```bash
# Test update functionality (if previous version exists)
spinbox update --check
spinbox update --dry-run
spinbox update --version v0.1.0-beta.2
```

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
sudo bash <(curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh)
\`\`\`

## Known Issues
- [Issue 1]: Workaround
- [Issue 2]: Workaround
```

## Testing Update Functionality

### Creating Test Releases

1. **Create Initial Release**: v0.1.0-beta.1
2. **Create Newer Release**: v0.1.0-beta.2
3. **Test Update Path**: v0.1.0-beta.1 → v0.1.0-beta.2

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

- [ ] Version detection works correctly
- [ ] Update download succeeds
- [ ] Backup creation works
- [ ] Installation replacement works
- [ ] Verification passes
- [ ] Configuration preserved
- [ ] Rollback works on failure

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