# Spinbox Global CLI Strategy

## Vision

Transform Spinbox from a template-based scaffolding system into a globally installable CLI tool that maintains all current functionality while providing a more streamlined user experience. Users will be able to run `spinbox <projectname>` from anywhere to create new prototyping environments.

## Current State vs. Target State

### Current Workflow
```bash
# Clone the template repository
git clone https://github.com/Gonzillaaa/spinbox.git
cd spinbox

# Run macOS setup (one-time)
./macos-setup.sh

# Navigate to project location
cd ../my-project/
git clone https://github.com/Gonzillaaa/spinbox.git spinbox/

# Run project setup
./spinbox/project-setup.sh
# Interactive component selection
# Generate files at project root

# Clean up
rm -rf spinbox/

# Start development
./start.sh  # or docker-compose up -d
```

### Target Workflow
```bash
# One-time global installation
brew install spinbox
# or manual installation

# Create projects from anywhere
spinbox myproject
# Interactive component selection
# Instant project creation in ./myproject/

# Start development
cd myproject
spinbox start  # or docker-compose up -d
```

## Core Principles

### 1. Simplicity First
- Follow the CLAUDE.md philosophy: "Always choose the simplest possible implementation that works"
- Maintain the current interactive experience users love
- Keep dependencies minimal
- Fast execution (< 5 seconds target for project creation)

### 2. Functionality Preservation
- **100% backward compatibility**: All current features must work identically
- **Same component options**: Backend, frontend, database, Redis, MongoDB, Chroma
- **Same templates**: All requirements.txt templates preserved
- **Same DevContainer experience**: VS Code, Cursor, and editor compatibility maintained

### 3. Enhanced User Experience
- **Global accessibility**: Use `spinbox` command from anywhere
- **No temporary files**: No need to clone/delete repositories
- **Professional distribution**: Homebrew tap for easy installation
- **Consistent interface**: Standard CLI conventions and help system

## Command Structure

### Primary Commands
```bash
# Project creation (main use case)
spinbox <projectname>                     # Create new project with interactive selection
spinbox <projectname> --python           # Create minimal Python project
spinbox <projectname> --node             # Create minimal Node/JavaScript project
spinbox <projectname> --profile api      # Create with predefined profile

# Version configuration (hybrid approach)
spinbox <projectname> --python 3.11     # Override Python version
spinbox <projectname> --node 18         # Override Node version
spinbox <projectname> --postgres 14     # Override PostgreSQL version
spinbox <projectname> --configure       # Interactive version/component selection

# Project management
spinbox start                            # Start services in existing project
spinbox add <component>                  # Add component to existing project
spinbox delete <component>               # Delete component on existing project
spinbox status                           # Show project components and status
spinbox components                       # list available components  

# Global management
spinbox config                           # Show current configuration
spinbox config set <key> <value>        # Set configuration value (e.g., python_version 3.11)
spinbox config reset                     # Reset to built-in defaults
spinbox templates                        # List available templates
spinbox version                          # Show version information
spinbox help                             # Show help information
```

### Project Types

#### 1. Interactive Full-Stack (Current Default)
- User selects from: Backend, Frontend, Database, Redis, MongoDB, Chroma
- Generates DevContainer + Docker Compose + selected components
- Maintains exact current functionality

#### 2. Bare-bones Python Project
- DevContainer with Python 3.12+
- Requirements.txt template selection (minimal, data-science, AI/LLM, etc.)
- Virtual environment setup
- Basic project structure

#### 3. Bare-bones Node/JavaScript Project
- DevContainer with Node.js 20+
- Package.json with basic dependencies
- Basic project structure with src/ directory
- ESLint, Prettier configuration

#### 4. Predefined Profiles
- `--profile api`: Backend + Database + Redis
- `--profile web`: Backend + Frontend + Database
- `--profile data`: Python + Jupyter + Database
- `--profile minimal`: Just DevContainer

## Version Configuration Strategy

### Hybrid Approach (Option 3)
Spinbox uses a hybrid approach for version configuration that prioritizes simplicity while allowing customization when needed.

#### Configuration Hierarchy (Priority Order)
1. **Command-line flags** (highest priority)
   ```bash
   spinbox myproject --python 3.11 --node 18
   ```

2. **Global user configuration** 
   ```bash
   spinbox config set python_version 3.11
   spinbox config set node_version 18
   ```

3. **Built-in defaults** (lowest priority)
   - Python: 3.12
   - Node.js: 20
   - PostgreSQL: 15
   - Redis: 7

#### Usage Patterns

**Simple (Most Common)**:
```bash
# Uses global configuration, no questions asked
spinbox myproject
```

**Quick Overrides**:
```bash
# Override specific versions
spinbox myproject --python 3.11
spinbox myproject --node 18 --postgres 14
```

**Interactive Configuration**:
```bash
# Full interactive mode for complex customization
spinbox myproject --configure
# Prompts: "Python version [3.12]: "
#         "Node version [20]: "
#         "Select components..."
```

**Global Configuration Management**:
```bash
# View current defaults
spinbox config

# Set new defaults
spinbox config set python_version 3.11
spinbox config set node_version 18

# Reset to built-in defaults
spinbox config reset
```

#### Benefits
- ✅ **Fast common case**: Default behavior requires no decisions
- ✅ **Flexible when needed**: Easy to override for specific projects
- ✅ **Consistent**: Global configuration ensures team consistency
- ✅ **CLI conventions**: Standard flag-based overrides
- ✅ **Backward compatible**: Maintains current interactive experience

## Installation Methods

### 1. Homebrew Formula (Recommended)
```bash
# Direct formula installation (no tap required)
brew install https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/Formula/spinbox.rb
```

### 2. Manual Installation
```bash
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh | bash
```

### 3. Future: Official Homebrew Core (Goal)
```bash
# Target for official Homebrew inclusion
brew install spinbox
```
**Note**: This is our long-term goal. Once Spinbox gains sufficient adoption and meets Homebrew's criteria, we'll submit it to the official Homebrew core repository for the simplest possible installation experience.

### 4. Development Installation
```bash
git clone https://github.com/Gonzillaaa/spinbox.git
cd spinbox
./install.sh --dev
```

## Architecture Overview

### File Structure
```
spinbox/
├── bin/
│   └── spinbox                   # Main CLI executable
├── lib/
│   ├── utils.sh                  # Shared utilities (existing)
│   ├── config.sh                 # Configuration management (existing)
│   ├── project-generator.sh      # Main project generation logic
│   └── environment-setup.sh      # Environment setup (from macos-setup.sh)
├── generators/
│   ├── devcontainer.sh           # DevContainer generation
│   ├── backend.sh                # FastAPI backend
│   ├── frontend.sh               # Next.js frontend
│   ├── database.sh               # PostgreSQL setup
│   ├── mongodb.sh                # MongoDB setup
│   ├── redis.sh                  # Redis setup
│   └── chroma.sh                 # Chroma vector database
├── templates/
│   ├── requirements/             # Python requirements templates (existing)
│   ├── package-json/             # Node.js package.json templates (new)
│   └── profiles/                 # Project profile definitions (new)
├── config/
│   └── default.toml              # Default configuration
├── install.sh                    # Installation script
└── Formula/                      # Homebrew formula
    └── spinbox.rb
```

### Core Components

#### 1. CLI Entry Point (`bin/spinbox`)
- Command parsing and routing
- Global configuration management
- Error handling and user feedback
- Help system and documentation

#### 2. Project Generator (`lib/project-generator.sh`)
- Interactive component selection
- Project directory creation
- Component orchestration
- Git repository initialization

#### 3. Component Generators (`generators/`)
- Modular component creation
- Template processing
- File generation
- Configuration management

#### 4. Configuration System
- Global user preferences
- Default component selections
- Custom template locations
- Version preferences

## Benefits

### For Users
- **Instant access**: Use `spinbox` from anywhere
- **No cleanup**: No temporary directories to manage
- **Professional tool**: Standard CLI conventions
- **Easy updates**: Update tool independently of projects
- **Consistent experience**: Same interface across all projects

### For Maintainers
- **Centralized distribution**: Single installation point
- **Version control**: Easier to manage updates and compatibility
- **Analytics**: Better understanding of usage patterns
- **Community**: Easier for contributors to extend functionality

## Migration Strategy

### Phase 1: Preserve Current Functionality
1. **Maintain existing scripts**: Keep all current scripts working
2. **Add CLI wrapper**: Create `bin/spinbox` that calls existing scripts
3. **Test compatibility**: Ensure all current features work through CLI

### Phase 2: Refactor and Optimize
1. **Extract generators**: Break down `project-setup.sh` into modular components
2. **Improve configuration**: Add global configuration management
3. **Add bare-bones options**: Implement minimal Python and Node projects

### Phase 3: Enhance and Distribute
1. **Add profiles**: Implement predefined project profiles
2. **Create Homebrew formula**: Enable `brew install` distribution
3. **Add advanced features**: Project introspection and component addition

### Phase 4: Community and Ecosystem
1. **Documentation**: Comprehensive guides and API documentation
2. **Plugin system**: Allow community extensions
3. **Template marketplace**: Community-contributed templates

## Success Metrics

### Functionality
- [ ] All current features work identically through CLI
- [ ] Project creation time < 5 seconds
- [ ] Zero regression in existing functionality
- [ ] DevContainer compatibility maintained

### User Experience
- [ ] Single command project creation
- [ ] Clear error messages and help system
- [ ] Consistent CLI interface
- [ ] Easy installation process

### Distribution
- [ ] Homebrew formula available
- [ ] GitHub releases automated
- [ ] Documentation complete
- [ ] Community adoption

## Risk Mitigation

### Technical Risks
- **Regression**: Comprehensive testing suite to prevent functionality loss
- **Compatibility**: Maintain support for existing project structures
- **Performance**: Optimize for fast execution while maintaining features

### User Adoption Risks
- **Learning curve**: Maintain familiar interaction patterns
- **Migration complexity**: Provide clear migration guides
- **Documentation**: Comprehensive guides for all use cases

## Timeline

### Phase 1: Foundation (Weeks 1-2)
- CLI infrastructure
- Command parsing
- Basic project creation
- Testing framework

### Phase 2: Feature Parity (Weeks 3-4)
- All current components working
- Configuration management
- Error handling
- Documentation

### Phase 3: Enhancement (Weeks 5-6)
- Bare-bones projects
- Installation scripts
- Direct Homebrew formula URL
- Community feedback

### Phase 4: Polish (Weeks 7-8)
- Performance optimization
- Advanced features
- Community documentation
- Release preparation

### Future Goal: Homebrew Core Submission (6-12 months)
- **Target**: Submit to official Homebrew core repository
- **Goal**: Enable simple `brew install spinbox` command
- **Requirements**: 
  - Significant user adoption (1000+ stars)
  - Proven stability and maintenance
  - Active community engagement
  - Comprehensive testing and documentation
- **Benefits**: Maximum discoverability and ease of installation

This strategy maintains the simplicity and effectiveness that makes Spinbox valuable while evolving it into a professional, globally accessible tool for rapid prototyping.