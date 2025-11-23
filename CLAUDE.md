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

## 2. Repository Structure

### Directory Overview

```
/home/user/spinbox/
├── .config/              # Sample configuration files (global.conf, user.conf, project.conf)
├── .github/              # GitHub workflows (claude.yml)
├── bin/                  # Main CLI executable
│   └── spinbox          # Entry point (1,104 lines, handles all commands)
├── docker-images/        # Docker Hub base images
├── docs/                 # Documentation (29 markdown files)
│   ├── user/            # User documentation (8 files: installation, quick-start, CLI reference, troubleshooting)
│   ├── dev/             # Development docs (13 files: strategy, implementation, backlog, roadmap)
│   └── releases/        # Release notes (6 versions: beta.4 through beta.8)
├── Formula/              # Homebrew installation formula
│   └── spinbox.rb       # Homebrew formula
├── generators/           # Component generators (8 shell scripts)
│   ├── fastapi.sh       # FastAPI backend
│   ├── nextjs.sh        # Next.js frontend
│   ├── chroma.sh        # Chroma vector database
│   ├── minimal-python.sh # Minimal Python environment
│   ├── minimal-node.sh  # Minimal Node.js environment
│   ├── postgresql.sh    # PostgreSQL database
│   ├── mongodb.sh       # MongoDB database
│   └── redis.sh         # Redis cache/queue
├── lib/                  # Core library modules (10 shell scripts, ~110,000 lines total)
│   ├── utils.sh         # Common utilities, error handling (16,178 lines)
│   ├── project-generator.sh # Project creation (28,886 lines)
│   ├── config.sh        # Configuration management (13,625 lines)
│   ├── version-config.sh # CLI flag hierarchy (12,821 lines)
│   ├── dependency-manager.sh # Package management (15,405 lines)
│   ├── update.sh        # Update system (15,471 lines)
│   ├── version.sh       # Version checking (7,228 lines)
│   ├── profiles.sh      # Profile system (8,006 lines)
│   ├── git-hooks.sh     # Git hooks (2,377 lines)
│   └── docker-hub.sh    # Docker Hub integration (6,538 lines)
├── templates/            # Template files
│   ├── profiles/        # 6 TOML profiles (web-app, api-only, data-science, ai-llm, python, node)
│   ├── dependencies/    # Component dependency mappings
│   ├── requirements/    # 6 Python requirements templates
│   ├── git-hooks/       # Pre-commit and pre-push hooks
│   └── security/        # Security setup scripts
├── testing/              # Testing infrastructure (38 shell scripts, ~4,112 lines)
│   ├── test-runner.sh   # Unified test entry point
│   ├── test-utils.sh    # Shared testing utilities
│   ├── unit/            # 95 unit tests (2 files)
│   ├── integration/     # 21+ integration tests (2 files)
│   ├── workflows/       # 100+ workflow tests (6 files)
│   └── end-to-end/      # 50+ E2E tests (2 files)
├── install.sh            # System-wide installation script
├── install-user.sh       # User-space installation script (recommended)
├── uninstall.sh          # Uninstallation script
├── README.md             # Project README
├── LICENSE               # MIT License
├── CLAUDE.md             # This file - AI development guide
└── .gitignore            # Git ignore rules
```

### Key Files

#### Entry Point
- **bin/spinbox** (1,104 lines) - Main executable handling all CLI commands

#### Core Libraries (Most Important)
- **lib/utils.sh** (16,178 lines) - Error handling, logging, rollback, validation
- **lib/project-generator.sh** (28,886 lines) - Project creation orchestration
- **lib/dependency-manager.sh** (15,405 lines) - Automatic package installation
- **lib/update.sh** (15,471 lines) - Atomic update system with backup/rollback

#### Configuration Files
- **.config/global.conf** - Default versions (Python 3.11, Node 18, Postgres 14, Redis 6)
- Runtime location: **~/.spinbox/runtime/** - Installed code (never deleted during operations)
- Cache location: **~/.spinbox/cache/** - Temporary files
- User config: **~/.spinbox/spinbox.conf** - User preferences

#### Documentation Entry Points
- **docs/README.md** - Documentation navigation index ← **START HERE**
- **docs/user/quick-start.md** - 5-minute tutorial
- **docs/user/cli-reference.md** - Complete CLI documentation
- **docs/dev/backlog.md** - Development backlog with story points

#### Testing Entry Point
- **testing/test-runner.sh** - Run all tests or specific suites

### Statistics
- **Total Shell Scripts**: 38 files
- **Total Code Lines**: ~113,000+ lines (lib + generators + testing)
- **Total Documentation**: 29 markdown files
- **Components**: 8 generators
- **Profiles**: 6 predefined
- **Test Coverage**: 124 tests (100% passing)
- **Current Version**: 0.1.0-beta.8

---

## 3. Development Standards

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

#### Testing Infrastructure

**Current Test Suite**: 124 tests passing (100% success rate)

```
testing/
├── test-runner.sh          # Unified test entry point
├── test-utils.sh           # Shared testing utilities (11,911 bytes)
├── unit/                   # 95 unit tests
│   ├── core-functionality.sh (77 tests, <10 seconds)
│   └── git-hooks-tests.sh    (18 tests)
├── integration/            # 21+ integration tests
│   ├── cli-integration.sh
│   └── workflow-scenarios.sh (8 user workflow scenarios)
├── workflows/              # 100+ workflow tests
│   ├── advanced-cli.sh
│   ├── cli-reference.sh
│   ├── component-generators.sh
│   ├── profiles.sh
│   ├── project-creation.sh
│   └── update-system.sh
└── end-to-end/             # 50+ E2E tests
    ├── installation-scenarios.sh
    └── uninstall-scenarios.sh
```

#### Testing Examples
✅ **Good**: 95 unit tests that run in < 10 seconds with zero dependencies
✅ **Good**: Standard directory structure (unit → integration → workflows → e2e)
✅ **Good**: Centralized test utilities and single entry point (test-runner.sh)
✅ **Good**: All tests pass with 100% success rate, no hanging or infinite loops
❌ **Bad**: Complex test frameworks with external dependencies and timeouts

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


## 4. Project Workflow

### GitHub Workflow & Commit Strategy

#### Branch Management
- **ALWAYS check current branch**: Before making any changes, run `git branch` to confirm which branch you're on
- **Ask if in doubt**: If uncertain about the current branch or where changes should go, ask the user for clarification
- **ALWAYS work on feature branches**: Never work directly on main branch to avoid losing work and maintain clean history
- **Create feature branches IMMEDIATELY**: As soon as you start working on ANY task, create a feature branch BEFORE making any changes (e.g., `git checkout -b feature/your-feature-name`)
- **Branch naming convention**: Use descriptive names like `feature/user-space-installation`, `fix/homebrew-formula`, `docs/installation-guide`
- **IMPORTANT**: Only create pull requests AFTER you have fully tested and verified that everything is working correctly. Never create a PR with untested or broken code.
- **ASK BEFORE CREATING PR**: Always ask the user if they are satisfied with the work before creating a pull request. Show what was done and confirm they want to proceed with the PR.
- **NEVER MERGE PRs**: Claude should NEVER merge pull requests. Only create them and let the user handle the review and merge process.
- **DON'T DELETE BRANCHES**: Never delete remote branches after creating PRs - this will close unmerged PRs. Wait for the user to handle branch cleanup after merge.

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
1. **Check task index** - Look at `docs/dev/backlog.md` `docs/README.md` quick navigation for your specific task
2. **Read only relevant sections** - Use the index to find the exact parts needed (not entire docs)
3. **Update Backlog** - Pull specific tasks from implementation plan keep `docs/dev/backlog.md` updated

**DURING work:**
- **Update status only** - Change ⏳ to 🔄 to ✅ in `docs/global-cli-implementation.md`
- **Reference in code** - Add comments linking to relevant doc sections
- **Note deviations briefly** - Add short notes if approach changes from plan

**AFTER work:**
- **Quick status update** - Mark completed tasks with ✅
- **Brief implementation note** - 1-2 sentences about what was actually built (if different from plan)
- **Update Backlog** - Pull specific tasks from implementation plan keep `docs/dev/backlog.md` updated

#### Implementation Workflow
1. **Create feature branch** for the phase you're working on
2. **Make atomic commits** for each logical change during implementation
3. **Run tests before ANY pull request** - All tests must pass before PR creation
4. **Fix any test failures immediately** - Never create separate branches for test fixes
5. **Push regularly** to keep remote branch updated
6. **Verify work is complete and tested** - Ensure all tasks are done and working
7. **Ask user for PR approval** - Show completed work and ask if they want to create a PR
8. **Create pull request only after approval** - Never create PRs without user confirmation
9. **Reference documentation** in commit messages and PR descriptions
10. **Let user handle merge** - Never merge PRs, only create them

### File Deletion Policy

**ALWAYS ASK BEFORE DELETING FILES**: Even with preferences set for automatic edits, ALWAYS check with the user before deleting any files or directories, regardless of how unnecessary they may seem. This overrides all other automation settings for deletion operations specifically.

---

## 5. CLI-Specific Guidelines

### Spinbox CLI Architecture

#### Core Structure
- **Entry Point**: `bin/spinbox` - Main CLI executable with comprehensive command routing
- **Runtime Location**: `~/.spinbox/runtime/` - Single source of truth (stable, never deleted during operations)
- **Cache Location**: `~/.spinbox/cache/` - Temporary files and build artifacts
- **Config Location**: `~/.spinbox/` - User configuration files

#### Library Modules (`lib/` - 10 core modules)
- **utils.sh** - Common utilities, error handling, logging, rollback mechanisms (16,178 lines)
- **project-generator.sh** - Project creation, directory setup, component orchestration (28,886 lines)
- **config.sh** - Configuration management with variable preservation (13,625 lines)
- **version-config.sh** - CLI flag override hierarchy: CLI > config > defaults (12,821 lines)
- **dependency-manager.sh** - Automatic package management for Python/Node.js (15,405 lines)
- **update.sh** - Update system with backup/rollback support (15,471 lines)
- **version.sh** - Version checking and GitHub API integration (7,228 lines)
- **profiles.sh** - Profile parsing and validation (8,006 lines)
- **git-hooks.sh** - Git hooks installation and management (2,377 lines)
- **docker-hub.sh** - Docker Hub image integration (6,538 lines)

#### Component Generators (`generators/` - 8 generators)
- **fastapi.sh** - FastAPI backend generation
- **nextjs.sh** - Next.js frontend generation
- **chroma.sh** - Chroma vector database integration
- **minimal-python.sh** - Minimal Python environment
- **minimal-node.sh** - Minimal Node.js environment
- **postgresql.sh** - PostgreSQL database
- **mongodb.sh** - MongoDB database
- **redis.sh** - Redis cache/queue layer

#### Templates (`templates/` - organized in 5 subdirectories)
- **profiles/** - 6 TOML profile definitions (web-app, api-only, data-science, ai-llm, python, node)
- **dependencies/** - Component dependency mappings
- **requirements/** - 6 Python requirements.txt templates
- **git-hooks/** - Pre-commit and pre-push hooks for Python
- **security/** - Security setup scripts

#### Installation Architecture
- **System-wide**: `/usr/local/bin/spinbox` → Uses `~/.spinbox/runtime/`
- **User-space**: `~/.local/bin/spinbox` → Uses `~/.spinbox/runtime/` (recommended, no sudo)
- **Homebrew**: Formula available at `Formula/spinbox.rb`
- **Centralized source** - Both installation methods share the same runtime location

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

## 6. Quick Reference

### Available Commands

```bash
# Project Creation
spinbox create <project-name> [options]
  --profile <name>          # Use predefined profile (web-app, api-only, data-science, ai-llm, python, node)
  --python <version>        # Python version (default: 3.11)
  --node <version>          # Node.js version (default: 18)
  --with-deps              # Automatically install dependencies
  --dry-run                # Preview without creating

# Component Addition
spinbox add <component> [options]
  # Components: fastapi, nextjs, postgresql, mongodb, redis, chroma
  --with-deps              # Install component dependencies

# Project Management
spinbox start [service]    # Start all services or specific service
spinbox stop [service]     # Stop all services or specific service
spinbox status             # Show project status

# Configuration
spinbox config [key] [value]  # View or set configuration
spinbox config --list         # List all configuration

# Profiles
spinbox profiles list      # List available profiles
spinbox profiles show <name>  # Show profile details

# System Management
spinbox update [--check]   # Update Spinbox to latest version
spinbox uninstall [--config]  # Uninstall Spinbox

# Help
spinbox --help            # Show help for all commands
spinbox <command> --help  # Show help for specific command
spinbox --version         # Show version information
```

### Key Documents
- `docs/README.md` - Task navigation index ← **START HERE**
- `docs/user/quick-start.md` - 5-minute getting started guide
- `docs/user/cli-reference.md` - Complete CLI documentation with examples
- `docs/user/troubleshooting.md` - Common issues and solutions
- `docs/dev/global-cli-strategy.md` - Overall vision and command structure
- `docs/dev/global-cli-implementation.md` - Technical implementation details
- `docs/dev/backlog.md` - Development backlog and roadmap
- `docs/dev/bare-bones-projects.md` - Project specifications

### CLI Implementation Status

**Current Version**: 0.1.0-beta.8 (Edge Case Improvements)

**Implementation Status**: Production-ready with comprehensive features

**Phase Completion**:
- ✅ **Phase 1 (Foundation)** - Complete: CLI entry point, command routing, configuration system
- ✅ **Phase 2 (Component Generators)** - Complete: 8 generators (Python, Node, FastAPI, Next.js, PostgreSQL, MongoDB, Redis, Chroma)
- ✅ **Phase 3 (Advanced Features)** - Complete: Git hooks, Docker Hub, dependency management, profiles, update system
- 🔄 **Phase 4 (Optimization)** - Ongoing: Performance improvements, edge case handling

**Recent Features** (Beta 6-8):
- **Git Hooks Integration** (Beta 7) - Automatic code quality checks for Python projects
- **Edge Case Improvements** (Beta 8) - Disk space validation, name length limits, network error handling
- **Docker Hub Integration** (Beta 5) - Custom base images from Docker Hub
- **Dependency Management** - `--with-deps` flag for automatic package installation
- **Profile System** - 6 predefined profiles for common project types
- **Update System** - Atomic updates with backup/rollback support

**Architecture Highlights**:
- Centralized runtime architecture (`~/.spinbox/runtime/`)
- Atomic operations with rollback support
- Process locking to prevent concurrent operations
- Comprehensive error handling with user-friendly messages
- 124 automated tests (100% passing)

### Critical Reminders
- **ALWAYS READ /docs/README.md for documentation and project guidance**
- **ALWAYS RUN TESTS BEFORE CREATING PULL REQUESTS** - Never create PRs with failing tests
- **Primary Rule**: Always choose the simplest possible implementation that works
- **User strongly values simplicity above all else** - When in doubt, err on the side of the simpler solution

---

## 7. Common AI Assistant Tasks

### Task: Adding a New Component Generator

1. **Read existing generators** - Start with `generators/minimal-python.sh` or `generators/fastapi.sh` as templates
2. **Follow the pattern**: Validation → Directory Setup → Configuration → File Creation → Integration
3. **Update dependencies** - Add to `templates/dependencies/python-components.toml` or `nodejs-components.toml`
4. **Test thoroughly** - Create test project with new component
5. **Document** - Add usage to `docs/user/cli-reference.md`
6. **Run tests** - Execute `testing/test-runner.sh` before committing

### Task: Fixing a Bug

1. **Reproduce** - Understand the issue first, read relevant code
2. **Locate** - Use grep to find related code: `grep -r "function_name" lib/ generators/`
3. **Fix** - Make minimal change to fix the issue
4. **Test** - Add test case if missing, run relevant test suite
5. **Commit** - Atomic commit with clear message: `fix: handle edge case in project creation`

### Task: Adding a New Feature

1. **Check docs** - Read `docs/dev/backlog.md` and `docs/dev/global-cli-implementation.md`
2. **Plan** - Update backlog with feature tasks
3. **Feature branch** - Create branch: `git checkout -b feature/your-feature-name`
4. **Implement** - Make atomic commits for each logical change
5. **Test** - Add tests in appropriate directory (unit/integration/workflows)
6. **Document** - Update user documentation and CLI help text
7. **PR approval** - Ask user before creating pull request

### Task: Improving Error Handling

1. **Identify** - Find error-prone areas in code
2. **User-friendly messages** - Follow error message guidelines (see section 3)
3. **Validation** - Add input validation early in the flow
4. **Rollback** - Ensure operations can be rolled back on failure
5. **Test edge cases** - Add tests for error conditions
6. **Update troubleshooting** - Add to `docs/user/troubleshooting.md` if needed

### Task: Updating Documentation

1. **Read first** - Understand what exists before changing
2. **Be accurate** - Verify information matches actual code behavior
3. **Be concise** - Users want clear, actionable information
4. **Examples** - Include real examples users can copy-paste
5. **Cross-reference** - Link to related documentation sections
6. **Test examples** - Verify all code examples actually work

### Task: Investigating an Issue

1. **Read error message** - User-friendly errors point to the problem
2. **Check logs** - Look for detailed error context
3. **Reproduce** - Try to create minimal reproduction case
4. **Search code** - Use grep to find relevant code sections
5. **Check recent changes** - Look at git history: `git log --oneline -10`
6. **Test fix** - Verify solution works before implementing

### When to Use Each Tool

- **Grep**: Search code for keywords, function names, error messages
- **Glob**: Find files by pattern (*.sh, generators/*, etc.)
- **Read**: Read specific files to understand implementation
- **Edit**: Make targeted changes to existing files
- **Bash**: Run tests, check git status, execute commands
- **Task (Explore agent)**: Complex codebase exploration, multi-step research

### Common Pitfalls to Avoid

❌ **Don't**: Make changes without reading existing code first
✅ **Do**: Read related files to understand context

❌ **Don't**: Create PRs without running tests
✅ **Do**: Run `testing/test-runner.sh` before any PR

❌ **Don't**: Add complex dependencies or frameworks
✅ **Do**: Use simple bash, built-in commands, minimal dependencies

❌ **Don't**: Over-engineer solutions with abstractions
✅ **Do**: Implement the simplest thing that works

❌ **Don't**: Create documentation without verifying accuracy
✅ **Do**: Test examples and verify against actual code

❌ **Don't**: Commit directly to main branch
✅ **Do**: Always work on feature branches

❌ **Don't**: Delete files without asking user first
✅ **Do**: Always confirm deletions with user

---

*Remember: The goal is reliable, maintainable software that does what users need without unnecessary complexity.*