# Git Hooks

Spinbox automatically installs git hooks for Python projects to help maintain code quality and catch issues before they're committed or pushed.

## What Are Git Hooks?

Git hooks are scripts that run automatically when certain git events occur (like committing or pushing code). Spinbox installs two hooks for Python projects:

1. **Pre-commit Hook** - Runs before each commit
2. **Pre-push Hook** - Runs before pushing to remote

## Pre-commit Hook (Python Projects)

Runs three code quality checks on staged Python files:

### 1. Code Formatting (black)
Ensures consistent code formatting across your project.

**Fix formatting issues:**
```bash
black yourfile.py
```

### 2. Import Sorting (isort)
Keeps your imports organized and consistent.

**Fix import sorting:**
```bash
isort yourfile.py
```

### 3. Linting (flake8)
Catches common Python errors and style issues.

**View linting errors:**
```bash
flake8 yourfile.py
```

## Pre-push Hook (Python Projects)

Runs your test suite before allowing a push to ensure you don't push breaking changes.

**Requires:** pytest installed in your environment
**Runs:** `pytest tests/`

If tests fail, the push is aborted.

## Installing Tools

The hooks gracefully skip checks if tools aren't installed, but for best results install them:

```bash
pip install black isort flake8 pytest
```

Or use the `--with-deps` flag when creating your project to automatically include these tools.

## Skipping Hooks

### Skip for All Projects

Use the `--no-hooks` flag when creating a project:

```bash
spinbox create myproject --python --no-hooks
```

### Skip for a Single Commit

```bash
git commit --no-verify -m "Your message"
```

### Skip for a Single Push

```bash
git push --no-verify
```

## Manual Hook Management

### Check Hook Status

```bash
ls -la .git/hooks/pre-commit .git/hooks/pre-push
```

### Remove Hooks

```bash
rm .git/hooks/pre-commit .git/hooks/pre-push
```

### Reinstall Hooks

If you removed hooks and want them back, you can manually copy them from the Spinbox templates:

```bash
cp ~/.spinbox/runtime/templates/git-hooks/pre-commit-python.sh .git/hooks/pre-commit
cp ~/.spinbox/runtime/templates/git-hooks/pre-push-python.sh .git/hooks/pre-push
chmod +x .git/hooks/pre-commit .git/hooks/pre-push
```

## Benefits

- **Catch errors early** - Before they're committed or pushed
- **Consistent code style** - Automatic formatting checks
- **Prevent broken builds** - Tests run before pushing
- **Team collaboration** - Everyone follows the same standards
- **Zero configuration** - Works out of the box

## Troubleshooting

### Hook tools not found

If you see warnings about missing tools, install them:

```bash
pip install black isort flake8
```

### Tests failing on pre-push

Your tests must pass before you can push. Fix the failing tests:

```bash
pytest tests/ -v  # Run tests with verbose output
```

### Hook not running

Check if the hook file is executable:

```bash
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-push
```

## Next Steps

- Read about [dependency management](dependency-management.md) to auto-install quality tools
- See [Quick Start Guide](quick-start.md) for project creation examples
- Check [Troubleshooting](troubleshooting.md) for common issues
