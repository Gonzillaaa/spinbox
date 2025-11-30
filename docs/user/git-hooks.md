# Git Repository & Hooks

Spinbox automatically initializes Git and installs quality hooks for Python/Node.js projects.

## Git Initialization

Every project gets Git initialized by default.

```bash
# Skip Git initialization
spinbox create myproject --python --no-git
```

## Git Hooks

For Python/Node.js projects, Spinbox installs:
- **Pre-commit**: Runs before each commit
- **Pre-push**: Runs before pushing

### Pre-commit Hook (Python)

Checks staged Python files for:
1. **black** - Code formatting
2. **isort** - Import sorting
3. **flake8** - Linting

### Pre-push Hook (Python)

Runs `pytest tests/` before allowing push.

## Install Tools

```bash
pip install black isort flake8 pytest
```

Or use `--with-deps` when creating projects.

## Skipping Hooks

```bash
# Skip hooks during project creation
spinbox create myproject --python --no-hooks

# Skip for single commit
git commit --no-verify -m "WIP"

# Skip for single push
git push --no-verify
```

## Manual Hook Management

```bash
# Check hooks
ls -la .git/hooks/pre-commit .git/hooks/pre-push

# Remove hooks
rm .git/hooks/pre-commit .git/hooks/pre-push

# Reinstall hooks
cp ~/.spinbox/runtime/templates/git-hooks/pre-commit-python.sh .git/hooks/pre-commit
cp ~/.spinbox/runtime/templates/git-hooks/pre-push-python.sh .git/hooks/pre-push
chmod +x .git/hooks/pre-commit .git/hooks/pre-push
```

## Customizing Hooks

Edit `.git/hooks/pre-commit` or `.git/hooks/pre-push` to add/remove checks.

## Benefits

- Catch errors before commit
- Consistent code style
- Prevent broken builds
- Zero configuration needed
