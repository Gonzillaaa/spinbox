# Claude Development Preferences

This file contains development philosophy and preferences for working on the Spinbox project.

## Core Philosophy: Keep Everything Simple

**Primary Rule**: Always choose the simplest possible implementation that works.

## Testing Philosophy

- **Always keep testing SUPER SIMPLE**
- Minimal dependencies (preferably none)
- Fast execution (< 5 seconds target)
- Essential coverage only (core functionality users actually need)
- No complex test frameworks or infinite loops
- Self-contained assertion functions
- Clear, readable test output
- Avoid over-engineering test infrastructure

### Testing Examples
✅ **Good**: 22 focused tests in simple-test.sh that run in < 5 seconds
❌ **Bad**: 115+ test functions with complex dependencies that hang

## General Implementation Philosophy

- **Prefer minimal solutions over complex ones**
- Avoid over-engineering and unnecessary abstractions
- Focus on what users actually need, not theoretical completeness
- Keep dependencies to a minimum
- Make things work reliably first, optimize later if needed
- Choose readability over cleverness
- Eliminate infinite loops, timeouts, and hanging processes
- **Use simple, flat directory structures** - avoid unnecessary nesting or complexity
- Keep file organization clear and straightforward
- Always cleanup as you go along. Delete temporary files, also files not needed anymore.
- Always create files in directories following the project structure. 

## Decision Making Guidelines

When choosing between multiple approaches:
1. **Simple vs Complex**: Always choose simple
2. **Few dependencies vs Many**: Always choose fewer
3. **Fast vs Slow**: Always choose fast
4. **Essential vs Complete**: Always choose essential
5. **Reliable vs Feature-rich**: Always choose reliable

## Code Quality Principles

- Write code that's easy to understand and modify
- Prefer explicit over implicit behavior
- Use clear naming
- Add comments but not too many
- Eliminate unnecessary complexity
- Make failures obvious and fast

## GitHub Workflow

- **Keep commits atomic**: Each commit should represent one logical change or fix
- **Commit frequently**: Avoid large, complex commits that are hard to review and understand
- **Use feature branches**: Create feature branches for major functionality chunks or version changes
- **Always commit and push**: Commit and push to the remote repository as you go to maintain backup and collaboration
- **Create pull requests**: Once work is completed on a feature branch, create a pull request for code review and integration

## File Deletion Policy

**ALWAYS ASK BEFORE DELETING FILES**: Even with preferences set for automatic edits, ALWAYS check with the user before deleting any files or directories, regardless of how unnecessary they may seem. This overrides all other automation settings for deletion operations specifically.

## Implementation Process
**ALWAYS READ /docs/README.md for documentation and project guidance**