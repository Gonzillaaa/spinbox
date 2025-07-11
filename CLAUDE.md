# Claude Development Preferences

This file contains development philosophy and preferences for working on the Spinbox project.

## Core Philosophy: Keep Everything Simple

**Primary Rule**: Always choose the simplest possible implementation that works.

## 🔄 MANDATORY DEVELOPMENT CYCLE 

**ALWAYS FOLLOW THIS CYCLE FOR ANY CHANGES:**

1. **Start with feature branch** (for major changes)
2. **Always follow the exiting project structure** (do not create duplicate or unnecessary files or directories)
3. **Update development documentation** (docs/backlog.md, implementation docs)
4. **Update end-user documentation** (README.md, CLI reference, guides)
5. **Run tests** (ensure all tests pass)
6. **Delete temporary or unused files** (ask if in doubt)
7. **Make atomic commits** (one logical change per commit)
8. **Push to remote** (maintain backup and collaboration)
9. **Create pull request** (for feature branches)

## GitHub Workflow (MANDATORY)

- **ALWAYS start major changes with feature branches**
- **Keep commits atomic**: Each commit should represent one logical change or fix
- **Commit frequently**: Avoid large, complex commits that are hard to review and understand
- **Use descriptive commit messages** that explain the "why" not just the "what"
- **Always commit and push**: Commit and push to the remote repository as you go to maintain backup and collaboration
- **Create pull requests**: Once work is completed on a feature branch, create a pull request for code review and integration

**⚠️ CRITICAL**: This cycle must be followed for EVERY change, no exceptions.

## Testing Philosophy

- **Always keep testing SUPER SIMPLE**
- **Self-contained tests only** - no external dependencies or complex frameworks
- **Fast execution** (< 5 seconds target for entire test suite)
- **Essential coverage only** (core functionality users actually need)
- **No complex test frameworks** or infinite loops
- **Clear, readable test output**
- **Avoid over-engineering test infrastructure**

### Testing Examples
✅ **Good**: 6-9 focused tests per file, self-contained, < 5 seconds
❌ **Bad**: 19+ test functions with complex dependencies that hang

## General Implementation Philosophy

- **Prefer minimal solutions over complex ones**
- **Avoid over-engineering and unnecessary abstractions**
- **Focus on what users actually need**, not theoretical completeness
- **Keep dependencies to a minimum**
- **Make things work reliably first**, optimize later if needed
- **Choose readability over cleverness**
- **Eliminate infinite loops, timeouts, and hanging processes**
- **Use simple, flat directory structures** - avoid unnecessary nesting or complexity
- **Keep file organization clear and straightforward**
- **Always cleanup as you go along** - Delete temporary files, also files not needed anymore
- **Always create files in directories following the project structure**

## Decision Making Guidelines

When choosing between multiple approaches:
1. **Simple vs Complex**: Always choose simple
2. **Few dependencies vs Many**: Always choose fewer
3. **Fast vs Slow**: Always choose fast
4. **Essential vs Complete**: Always choose essential
5. **Reliable vs Feature-rich**: Always choose reliable

## Code Quality Principles

- **Write code that's easy to read, understand and modify**
- **Prefer explicit over implicit behavior**
- **Use clear naming**
- **Add comments but not too many**
- **Eliminate unnecessary complexity**
- **Make failures obvious and fast**

## File Management

- **ALWAYS ASK BEFORE DELETING FILES**: Even with preferences set for automatic edits, ALWAYS check with the user before deleting any files or directories, regardless of how unnecessary they may seem. This overrides all other automation settings for deletion operations specifically.
- **Always follow the exiting project structure** (do not create duplicate or unnecessary files or directories)
- **Keep project structure clean**: No test files in root directory
- **Follow naming conventions**: Clear, descriptive file names
- **Organize by function**: Group related files together

## Documentation Requirements (MANDATORY)

- **ALWAYS update development documentation** (docs/backlog.md, implementation docs)
- **ALWAYS update end-user documentation** (README.md, CLI reference, user guides)
- **ALWAYS read /docs/README.md** for documentation and project guidance
- **Keep documentation simple and focused** on what users need
- **Update documentation BEFORE making changes** when possible

## Quality Assurance

- **ALWAYS run tests** before committing
- **ALWAYS verify functionality** works as expected
- **ALWAYS check for breaking changes**