# Git Hooks Integration Guide

Spinbox provides automatic git hooks integration for quality assurance and automated code formatting. This guide covers everything you need to know about using git hooks with your Spinbox projects.

## Overview

Git hooks are scripts that automatically run at specific points in your Git workflow. Spinbox provides project-aware hooks that:

- **Pre-commit**: Run fast quality checks before commits (< 5 seconds)
- **Pre-push**: Run comprehensive tests and validation before pushing
- **Project-aware**: Automatically configure appropriate tools for your project type

## Quick Start

### 1. Install Hooks

```bash
# Install all recommended hooks for your project
spinbox hooks add all

# Install specific hook type
spinbox hooks add pre-commit
spinbox hooks add pre-push
```

### 2. Install with Examples

```bash
# Install hooks with example configurations
spinbox hooks add all --with-examples

# This creates sample config files like:
# - .pre-commit-config.yaml (for Python projects)
# - .eslintrc.json (for Node.js projects)
# - prettier.config.js (for formatting)
```

### 3. Manage Hooks

```bash
# List installed hooks
spinbox hooks list

# Remove specific hook
spinbox hooks remove pre-commit

# Remove all hooks
spinbox hooks remove all
```

## Project Types and Hooks

Spinbox automatically detects your project type and installs appropriate hooks:

### Python Projects
**Detected by**: `requirements.txt`, `pyproject.toml`, `.py` files

**Pre-commit hooks**:
- ✅ Black code formatting check
- ✅ Quick pytest tests (< 5 seconds)
- ✅ Import validation

**Pre-push hooks**:
- ✅ Full test suite with pytest
- ✅ Type checking with mypy (if available)
- ✅ Security scanning with bandit (if available)

**Example workflow**:
```bash
# Your project structure
my-python-project/
├── requirements.txt
├── src/
│   └── main.py
└── tests/
    └── test_main.py

# Install hooks
spinbox hooks add all --with-examples

# Now when you commit:
# 1. Black checks your code formatting
# 2. Quick tests run automatically
# 3. If anything fails, commit is blocked
```

### Node.js Projects
**Detected by**: `package.json`, `.js/.ts/.jsx/.tsx` files

**Pre-commit hooks**:
- ✅ ESLint code quality checks
- ✅ TypeScript type checking
- ✅ Prettier formatting validation
- ✅ Quick tests (if available)

**Pre-push hooks**:
- ✅ Full test suite with npm test
- ✅ Build validation
- ✅ Security audit with npm audit

**Example workflow**:
```bash
# Your project structure
my-node-project/
├── package.json
├── src/
│   └── index.js
└── tests/
    └── index.test.js

# Install hooks
spinbox hooks add all

# Now when you commit:
# 1. ESLint checks your code
# 2. TypeScript validates types
# 3. Prettier checks formatting
```

### FastAPI Projects
**Detected by**: `fastapi/` directory or `fastapi` in requirements.txt

**Pre-commit hooks**:
- ✅ FastAPI application validation
- ✅ Black code formatting
- ✅ Quick API tests
- ✅ OpenAPI schema validation

**Pre-push hooks**:
- ✅ Full API test suite
- ✅ Database migration validation
- ✅ Security scanning
- ✅ API documentation generation

### Next.js Projects
**Detected by**: `nextjs/` directory or `next` in package.json

**Pre-commit hooks**:
- ✅ Next.js lint checks
- ✅ TypeScript validation
- ✅ Build validation (quick)
- ✅ Component testing

**Pre-push hooks**:
- ✅ Full Next.js build
- ✅ Component test suite
- ✅ Security audit
- ✅ Bundle size validation

### Full-stack Projects
**Detected by**: Both Python and Node.js indicators present

**Pre-commit hooks**:
- ✅ Combined Python and Node.js checks
- ✅ API and frontend validation
- ✅ Cross-component integration checks

**Pre-push hooks**:
- ✅ Full-stack integration tests
- ✅ Database and API validation
- ✅ Build and deployment checks

## Common Workflows

### Setting Up a New Project

```bash
# 1. Create your Spinbox project
spinbox create myproject --fastapi --nextjs --postgresql

# 2. Install git hooks
cd myproject
spinbox hooks add all --with-examples

# 3. Make your first commit
git add .
git commit -m "Initial commit with hooks"
# Hooks will run automatically!
```

### Adding Hooks to Existing Projects

```bash
# Navigate to your existing project
cd existing-project

# Install hooks (Spinbox will detect your project type)
spinbox hooks add all

# Test the hooks
git add .
git commit -m "Add git hooks"
```

### Customizing Hook Behavior

```bash
# Install hooks with example configurations
spinbox hooks add all --with-examples

# Edit the generated config files:
# - .pre-commit-config.yaml (Python)
# - .eslintrc.json (Node.js)
# - prettier.config.js (Formatting)
```

## Hook Configuration Files

When you use `--with-examples`, Spinbox generates sample configuration files:

### Python Projects

**.pre-commit-config.yaml**:
```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.11.0
    hooks:
      - id: black
        language_version: python3.12

  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort
        args: ["--profile", "black"]
```

### Node.js Projects

**.eslintrc.json**:
```json
{
  "extends": ["eslint:recommended", "@typescript-eslint/recommended"],
  "rules": {
    "no-console": "warn",
    "no-unused-vars": "error"
  }
}
```

**prettier.config.js**:
```javascript
module.exports = {
  semi: true,
  trailingComma: 'all',
  singleQuote: true,
  printWidth: 80,
  tabWidth: 2,
};
```

## Troubleshooting

### Hooks Not Running

1. **Check if you're in a git repository**:
   ```bash
   git status
   # If not: git init
   ```

2. **Verify hooks are installed**:
   ```bash
   spinbox hooks list
   ```

3. **Check hook permissions**:
   ```bash
   ls -la .git/hooks/
   # Hooks should be executable (-rwxr-xr-x)
   ```

### Hook Failures

1. **Pre-commit hook fails**:
   ```bash
   # Fix formatting issues
   black .
   
   # Run tests manually
   pytest -x
   
   # Then commit again
   git commit -m "Fix formatting"
   ```

2. **Pre-push hook fails**:
   ```bash
   # Run full test suite
   pytest
   
   # Check for type errors
   mypy .
   
   # Fix issues and try again
   git push
   ```

### Missing Tools

If hooks report missing tools:

**Python projects**:
```bash
# Install missing tools
pip install black pytest mypy bandit
```

**Node.js projects**:
```bash
# Install missing tools
npm install --save-dev eslint prettier typescript
```

### Disabling Hooks Temporarily

```bash
# Skip pre-commit hooks for emergency commits
git commit --no-verify -m "Emergency fix"

# Skip pre-push hooks
git push --no-verify
```

### Removing Hooks

```bash
# Remove specific hook
spinbox hooks remove pre-commit

# Remove all hooks
spinbox hooks remove all

# Or manually delete from .git/hooks/
rm .git/hooks/pre-commit
rm .git/hooks/pre-push
```

## Best Practices

### 1. Install Hooks Early
```bash
# Install hooks right after project creation
spinbox create myproject --fastapi
cd myproject
spinbox hooks add all
```

### 2. Use Examples for Customization
```bash
# Generate base configurations
spinbox hooks add all --with-examples

# Then customize the generated files
```

### 3. Test Before Committing
```bash
# Run checks manually first
black .
pytest -x
eslint .

# Then commit
git commit -m "Feature implementation"
```

### 4. Keep Hooks Fast
- Pre-commit hooks target < 5 seconds
- Use `pytest -x` for quick failure detection
- Cache dependencies when possible

### 5. Team Consistency
```bash
# Share hook configurations in your repository
git add .pre-commit-config.yaml
git add .eslintrc.json
git add prettier.config.js
git commit -m "Add team code standards"
```

## Advanced Usage

### Custom Hook Scripts

You can modify the generated hooks in `.git/hooks/`:

```bash
# Edit pre-commit hook
nano .git/hooks/pre-commit

# Add custom checks
echo "echo 'Running custom validations...'" >> .git/hooks/pre-commit
```

### Project-Specific Overrides

Create a `.spinbox-hooks` configuration file:

```bash
# .spinbox-hooks
SKIP_FORMATTING=false
SKIP_TESTS=false
MAX_COMMIT_TIME=5
```

### Integration with CI/CD

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Spinbox
        run: curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | bash
      - name: Run hooks
        run: |
          spinbox hooks add all
          # Run the same checks as pre-push hooks
          .git/hooks/pre-push
```

## FAQ

**Q: Do hooks work with all git clients?**
A: Yes! Hooks work with command-line git, VS Code, GitHub Desktop, and other git clients.

**Q: Can I use hooks with existing projects?**
A: Absolutely! Spinbox will detect your project type and install appropriate hooks.

**Q: What if I don't want certain checks?**
A: You can modify the hook files or remove specific hooks with `spinbox hooks remove <hook-type>`.

**Q: Do hooks work on Windows?**
A: Yes, but some tools (like bandit) might need additional setup on Windows.

**Q: Can I share hooks with my team?**
A: Hook scripts aren't shared via git, but configuration files (like `.pre-commit-config.yaml`) can be committed and shared.

## Getting Help

If you encounter issues:

1. **Check the troubleshooting section** above
2. **Run with verbose output**: `spinbox hooks add all --verbose`
3. **Check logs**: Look in `.git/hooks/` for error messages
4. **Ask for help**: Create an issue on the Spinbox GitHub repository

## Related Documentation

- [CLI Reference - Hooks](./cli-reference.md#spinbox-hooks) - Complete command reference
- [Quick Start Guide](./quick-start.md) - Basic Spinbox usage
- [Adding Components](./adding-components.md) - Managing project components
- [Troubleshooting](./troubleshooting.md) - General troubleshooting guide