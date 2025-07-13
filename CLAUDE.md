# Claude Development Preferences

This file contains development philosophy and preferences for working on the Spinbox project.

---

## 1. Core Principles

### Core Philosophy: Keep Everything Simple

**Primary Rule**: Always choose the simplest possible implementation that works.

### Decision Making Guidelines

When choosing between multiple approaches:
1. **Simple vs Complex**: Always choose simple
2. **Few dependencies vs Many**: Always choose fewer
3. **Fast vs Slow**: Always choose fast
4. **Essential vs Complete**: Always choose essential
5. **Reliable vs Feature-rich**: Always choose reliable

### Memory Note

**This is a critical preference**: The user strongly values simplicity above all else. When in doubt, always err on the side of the simpler solution, especially for testing infrastructure.

---

## 2. Development Standards

### General Implementation Philosophy

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
- Look for the right place to create a file before creating it. 

### Code Quality Principles

- Write code that's easy to understand and modify
- Prefer explicit over implicit behavior
- Use clear naming
- Add comments but not too many
- When reviewing code always eliminate unnecessary complexity
- Make failures obvious and fast

### Testing Philosophy

- **Always keep testing SUPER SIMPLE**
- Minimal dependencies (preferably none)
- Fast execution (< 5 seconds target)
- Essential coverage only (core functionality users actually need)
- No complex test frameworks or infinite loops
- Self-contained assertion functions
- Clear, readable test output
- Avoid over-engineering test infrastructure
- Avoid creating overly complicated fixtures just to make tests pass

#### Testing Examples
✅ **Good**: 22 focused tests in simple-test.sh that run in < 5 seconds
❌ **Bad**: 115+ test functions with complex dependencies that hang

### Error Handling Philosophy

#### Graceful Failure Handling
- **Fail fast with clear messages** - Don't let errors cascade or hide
- **User-friendly explanations** - Explain what went wrong and how to fix it
- **Consistent error format** - Use standard error patterns across all commands
- **Helpful context** - Include relevant information (file paths, command attempted, etc.)

#### Error Message Guidelines
```bash
# Good error messages:
Error: Project directory 'myproject' already exists
  → Use a different name or remove the existing directory

Error: Docker is not running
  → Please start Docker Desktop and try again
  → See troubleshooting: docs/troubleshooting.md#docker-issues

# Avoid technical jargon:
Error: ENOENT: no such file or directory, open '/path/file'
```

#### When to Fail vs Recover
- **Fail fast**: Invalid user input, missing prerequisites, permission issues
- **Attempt recovery**: Network timeouts, temporary file locks
- **Always validate**: User input, configuration values, system requirements
- **Exit codes**: Use standard Unix exit codes (0=success, 1=general error, 2=misuse)
- **Handle HTTP errors clearly**: For commands that interact with remote servers or APIs, detect HTTP errors and display concise, user-friendly messages (e.g., "Error: Failed to fetch project template (HTTP 404 Not Found)"). Suggest next steps or troubleshooting links when possible.


## 3. Project Workflow

### GitHub Workflow & Commit Strategy

#### Branch Management
- **ALWAYS check current branch**: Before making any changes, run `git branch` to confirm which branch you're on
- **Ask if in doubt**: If uncertain about the current branch or where changes should go, ask the user for clarification
- **ALWAYS work on feature branches**: Never work directly on main branch to avoid losing work and maintain clean history
- **Create feature branches immediately**: Before making any new features or bigger changes, create a feature branch (e.g., `git checkout -b feature/your-feature-name`)
- **Branch naming convention**: Use descriptive names like `feature/user-space-installation`, `fix/homebrew-formula`, `docs/installation-guide`

#### Commit Practices
- **Keep commits atomic**: Each commit should represent one logical change or fix
- **Commit frequently**: Make small, focused commits as you implement
- **Always commit and push**: Keep local and remote repositories in sync during implementation

#### Commit Message Format
```
feat: implement CLI entry point command parsing

- Add bin/spinbox executable with basic command routing
- Implement help system and version display
- Add error handling for invalid commands
- See docs/global-cli-implementation.md Phase 1, Step 1.1
```

#### Commit Examples
```bash
# Good atomic commits:
feat: add version configuration parsing (see implementation.md Step 1.4)
feat: implement project directory creation
fix: handle invalid project names with proper validation
docs: update CLI entry point status to completed

# Avoid large commits:
feat: implement entire CLI foundation (too broad)
```

#### Branching Strategy
- **Feature branches** for large functionality groups:
  - `feature/cli-foundation` - Phase 1 implementation
  - `feature/component-generators` - Phase 2 implementation  
  - `feature/installation-system` - Phase 3 implementation
  - `feature/advanced-features` - Phase 4 implementation
- **Pull requests** for each major phase or version milestone
- **Main branch** remains stable and deployable

### Implementation Process

#### Smart Documentation Protocol
**BEFORE starting work:**
1. **Check task index** - Look at `docs/README.md` quick navigation for your specific task
2. **Read only relevant sections** - Use the index to find the exact parts needed (not entire docs)
3. **Update TodoWrite** - Pull specific tasks from implementation plan

**DURING work:**
- **Update status only** - Change ⏳ to 🔄 to ✅ in `docs/global-cli-implementation.md`
- **Reference in code** - Add comments linking to relevant doc sections
- **Note deviations briefly** - Add short notes if approach changes from plan

**AFTER work:**
- **Quick status update** - Mark completed tasks with ✅
- **Brief implementation note** - 1-2 sentences about what was actually built (if different from plan)

#### Implementation Workflow
1. **Create feature branch** for the phase you're working on
2. **Make atomic commits** for each logical change during implementation
3. **Run tests before ANY pull request** - All tests must pass before PR creation
4. **Fix any test failures immediately** - Never create separate branches for test fixes
5. **Push regularly** to keep remote branch updated
6. **Create pull request only after tests pass** - Never create PRs with failing tests
7. **Reference documentation** in commit messages and PR descriptions

### File Deletion Policy

**ALWAYS ASK BEFORE DELETING FILES**: Even with preferences set for automatic edits, ALWAYS check with the user before deleting any files or directories, regardless of how unnecessary they may seem. This overrides all other automation settings for deletion operations specifically.

---

## 4. CLI-Specific Guidelines

### Spinbox CLI Architecture
- **Entry Point**: `bin/spinbox` - Main CLI executable with command routing
- **Libraries**: `lib/` directory contains reusable modules:
  - `utils.sh` - Common utilities and error handling
  - `config.sh` - Configuration management with variable preservation
  - `version-config.sh` - CLI flag override hierarchy (CLI > config > defaults)
  - `project-generator.sh` - Project creation and component orchestration
- **Generators**: `generators/` directory contains component-specific modules

### CLI Development Principles
- **Unix Standards**: Follow standard CLI conventions (--help, --version, etc.)
- **Variable Scoping**: Use conditional assignments to prevent variable conflicts:
  ```bash
  # Good: Preserve existing values
  : "${PROJECT_NAME:=""}"
  
  # Bad: Always overwrite
  PROJECT_NAME=""
  ```
- **Array Safety**: Handle empty arrays to prevent unbound variable errors:
  ```bash
  # Good: Check array length
  if [[ ${#ports[@]} -gt 0 ]]; then
      echo "${ports[*]}"
  fi
  
  # Bad: Direct expansion can fail
  echo "${ports[*]}"
  ```
- **Error Handling**: Use graceful failure with rollback support
- **Export Variables**: Export variables when sourcing scripts across boundaries

### Component Generator Pattern
Each generator should follow this structure:
1. **Validation**: Check prerequisites and validate inputs
2. **Directory Setup**: Create necessary directory structure
3. **Configuration Generation**: DevContainer, Docker Compose, etc.
4. **File Creation**: Component-specific files and templates
5. **Integration**: Ensure components work together

### Testing CLI Changes
- **ALWAYS RUN TESTS BEFORE CREATING PULL REQUESTS** - Tests must pass before any PR creation
- **Fix test failures immediately** - Never create separate branches just for test fixes
- Always test with `--dry-run` first
- Test help systems: `spinbox command --help`
- Test error conditions and edge cases
- Verify variable scoping doesn't conflict
- Test component combinations

### User Experience Principles

#### CLI Standards and Conventions
- **Follow Unix conventions** - Standard flags (-h, --help, -v, --version)
- **Consistent command structure** - `spinbox <command> [options] [arguments]`
- **Intuitive flag names** - Use common patterns (--config, --verbose, --dry-run)
- **Progressive disclosure** - Basic usage simple, advanced options available

#### Help and Documentation
```bash
# Comprehensive help structure:
spinbox --help                    # Overview of all commands
spinbox <command> --help          # Specific command help
spinbox <command> --examples      # Usage examples
```

#### User Feedback and Progress
- **Immediate feedback** - Show what's happening during operations
- **Progress indicators** - For operations taking >2 seconds
- **Success confirmation** - Clear indication when operations complete
- **Next steps guidance** - Tell users what to do after command completes

#### Configuration and Defaults
- **Sensible defaults** - Work out of the box with minimal configuration
- **Validate early** - Check configuration before starting long operations
- **Configuration discovery** - Show current settings with `spinbox config`
- **Override hierarchy** - CLI flags > config file > defaults (clearly documented)

### Dependencies Management

#### Criteria for Adding Dependencies
- **Essential functionality** - Dependency provides critical capability we can't reasonably implement
- **Well-maintained** - Active development, responsive maintainers, good track record
- **Minimal footprint** - Small size, few transitive dependencies
- **Stable API** - Unlikely to introduce breaking changes

#### Evaluation Guidelines
```bash
# Questions to ask before adding dependency:
1. Can we implement this functionality simply ourselves?
2. Is this dependency actively maintained?
3. How many transitive dependencies does it add?
4. What's the fallback if this dependency fails?
5. Does it align with our simplicity philosophy?
```

#### Dependency Strategy
- **Prefer system tools** - Use git, docker, curl instead of language-specific alternatives
- **Shell scripts over frameworks** - Bash built-ins and common Unix tools preferred
- **Optional dependencies** - Graceful degradation when optional tools unavailable
- **Version compatibility** - Support reasonable version ranges, not just latest

#### Fallback Approaches
- **Core functionality** - Must work without optional dependencies
- **Graceful degradation** - Reduced features rather than complete failure
- **Clear messaging** - Tell users what features require additional tools
- **Alternative paths** - Provide manual steps when automated tools unavailable

---

## 5. Quick Reference

### Key Documents
- `docs/README.md` - Task navigation index ← **START HERE**
- `docs/global-cli-strategy.md` - Overall vision and command structure
- `docs/global-cli-implementation.md` - Technical plan with status tracking
- `docs/bare-bones-projects.md` - Project specifications
- `docs/migration-path.md` - Migration approach

### CLI Implementation Status
**Current Status**: Phase 1 (Foundation) and basic Phase 2 (Component Generators) are complete. The system uses a modular architecture with proper variable scoping and Unix-standard CLI patterns.

### Critical Reminders
- **ALWAYS READ /docs/README.md for documentation and project guidance**
- **ALWAYS RUN TESTS BEFORE CREATING PULL REQUESTS** - Never create PRs with failing tests
- **Primary Rule**: Always choose the simplest possible implementation that works
- **User strongly values simplicity above all else** - When in doubt, err on the side of the simpler solution

---

*Remember: The goal is reliable, maintainable software that does what users need without unnecessary complexity.*