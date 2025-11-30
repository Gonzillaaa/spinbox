# Release Process

**Current**: v0.1.0-beta.8

## Versioning

- Format: `MAJOR.MINOR.PATCH-beta.N`
- Breaking changes allowed between beta releases
- Stable releases (no `-beta`) have no breaking changes within major version

## Steps

### 1. Prepare

```bash
git checkout main && git pull
git checkout -b release/v0.1.0-beta.X

# Update version
sed -i '' 's/readonly VERSION=".*"/readonly VERSION="0.1.0-beta.X"/' bin/spinbox
./bin/spinbox --version
```

### 2. Test

```bash
./testing/simple-test.sh
# All tests must pass
```

### 3. Release Notes

Create `docs/releases/v0.1.0-beta.X.md`:

```markdown
# Spinbox v0.1.0-beta.X

## New Features
- Feature description

## Bug Fixes
- Fix description

## Breaking Changes
- Change with migration notes

## Update
spinbox update
```

### 4. Commit and Tag

```bash
git add -A
git commit -m "chore: bump version to v0.1.0-beta.X"
git push -u origin release/v0.1.0-beta.X

git tag -a v0.1.0-beta.X -m "Release v0.1.0-beta.X"
git push origin v0.1.0-beta.X
```

### 5. GitHub Release

```bash
gh release create v0.1.0-beta.X \
  --title "Spinbox v0.1.0-beta.X" \
  --notes-file docs/releases/v0.1.0-beta.X.md \
  --prerelease
```

### 6. Verify

```bash
spinbox update --check
spinbox update --dry-run
```

## Notes

- Release notes go in `docs/releases/`
- Requires `gh auth login` for GitHub CLI
- Use `--prerelease` flag for beta releases
