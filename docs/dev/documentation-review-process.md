# Documentation Review Process

Run after releases, feature additions, or file structure changes.

## Checklist

### Critical (Must Fix)

- [ ] Version references match current (`v0.1.0-beta.8`)
- [ ] No broken internal links
- [ ] Platform info accurate (macOS/Linux only)
- [ ] CLI `--help` output matches cli-reference.md

### High Priority

- [ ] No contradictory info ("planned" vs implemented)
- [ ] CLAUDE.md paths and commands current
- [ ] All CLI flags documented
- [ ] `spinbox profiles` output matches docs

### Medium Priority

- [ ] All docs linked from docs/README.md navigation
- [ ] No orphan files (docs not linked anywhere)
- [ ] No redundant content across files
- [ ] File organization: user/ vs dev/ correct

## Commands Reference

### Version Audit
```bash
# Find all version references
grep -r "v0\.1\.0-beta\." docs/ README.md CLAUDE.md

# Find inconsistent formats
grep -r "beta\.[0-9]" docs/
```

### Link Validation
```bash
# Find internal links
grep -r "\]\(\..*\.md\)" docs/

# List all doc files (check against navigation)
find docs/ -name "*.md" | sort
```

### Platform Check
```bash
grep -r -i "windows\|wsl" docs/
```

### CLI Sync
```bash
# Compare help output to docs
spinbox --help
spinbox create --help
spinbox add --help
spinbox profiles

# Check all flags are documented
spinbox create --help | grep -E "^\s+--"
```

### Content Issues
```bash
# Find "planned" features that may be implemented
grep -r "planned\|future\|upcoming\|coming soon" docs/

# Find duplicate content
grep -r "spinbox create" docs/ | cut -d: -f2 | sort | uniq -c | sort -nr
```

### Navigation Check
```bash
# List files that should be in navigation
ls docs/user/*.md docs/dev/*.md

# Check docs/README.md links to them
grep -o "\[.*\](.*\.md)" docs/README.md
```

## File Organization

| Directory | Content |
|-----------|---------|
| `docs/user/` | End-user docs (installation, CLI, troubleshooting) |
| `docs/dev/` | Developer docs (architecture, release process) |
| `docs/releases/` | Release notes |

## Standards

- **Versions**: Use full format `v0.1.0-beta.8`
- **Platforms**: Only macOS and Linux
- **Links**: Relative paths from file location
- **Examples**: Test before documenting
- **Principle**: Concise > comprehensive. Explain with fewest words possible.
