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

## Real-World Examples

### Example 1: Commit with Formatting Issues

```bash
$ git add myfile.py
$ git commit -m "Add new feature"

Running pre-commit checks...
Checking myfile.py
1. Checking code formatting (black)...
❌ Code formatting issues found!
   Fix with: black myfile.py
```

**Fix and retry:**
```bash
$ black myfile.py
reformatted myfile.py
$ git add myfile.py
$ git commit -m "Add new feature"

Running pre-commit checks...
✅ All pre-commit checks passed!
[main abc1234] Add new feature
```

### Example 2: Push with Failing Tests

```bash
$ git push origin main

Running pre-push tests...
Running pytest...
=================== test session starts ====================
tests/test_feature.py F                               [100%]

========================= FAILURES =========================
❌ Tests failed! Push aborted.
   Fix the failing tests before pushing.
```

**Fix tests and retry:**
```bash
$ # Fix the failing test
$ pytest tests/  # Verify tests pass
$ git push origin main

Running pre-push tests...
✅ All tests passed!
[Push successful]
```

### Example 3: Quick Commit (Skip Hooks)

Sometimes you need to commit work-in-progress code:

```bash
$ git commit --no-verify -m "WIP: debugging feature"
[main def5678] WIP: debugging feature
```

## Benefits

- **Catch errors early** - Before they're committed or pushed
- **Consistent code style** - Automatic formatting checks
- **Prevent broken builds** - Tests run before pushing
- **Team collaboration** - Everyone follows the same standards
- **Zero configuration** - Works out of the box

## Customizing Hooks

Spinbox hooks are simple bash scripts that you can customize to fit your workflow.

### Location

Hooks are installed in your project's `.git/hooks/` directory:
- `.git/hooks/pre-commit` - Pre-commit hook
- `.git/hooks/pre-push` - Pre-push hook

### Modify Hook Behavior

Edit the hook files directly to customize checks:

```bash
# Example: Skip isort in pre-commit
vim .git/hooks/pre-commit
# Comment out the isort section
```

### Add Additional Checks

Add your own checks to the hooks:

```bash
# Example: Add mypy type checking to pre-commit
echo "" >> .git/hooks/pre-commit
echo "# Run mypy type checking" >> .git/hooks/pre-commit
echo "if command -v mypy &> /dev/null; then" >> .git/hooks/pre-commit
echo "    mypy $STAGED_PY_FILES" >> .git/hooks/pre-commit
echo "fi" >> .git/hooks/pre-commit
```

### Shared Team Hooks

To share customized hooks with your team:

1. Create a `hooks/` directory in your repo
2. Copy customized hooks there
3. Add installation script to your README
4. Team members run the script to install hooks

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
