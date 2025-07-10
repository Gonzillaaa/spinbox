# Spinbox Documentation Index

## 🎯 Core Planning Documents
- [`global-cli-strategy.md`](./global-cli-strategy.md) - High-level vision and approach
- [`global-cli-implementation.md`](./global-cli-implementation.md) - Detailed technical implementation
- [`bare-bones-projects.md`](./bare-bones-projects.md) - Minimal project specifications

## 📋 Implementation Tracking
- [x] Always read these docs before starting implementation tasks
- [x] Update progress in implementation.md as tasks are completed
- [x] Document any deviations or new ideas in strategy.md

## 🎯 Quick Task Navigation

### Working on CLI Entry Point?
- **Read**: `global-cli-implementation.md` Phase 1, Step 1.1 only
- **Status**: Update line 981 in `global-cli-implementation.md`
- **Code**: Create `bin/spinbox`
- **Key**: Command parsing, help system, routing

### Working on Configuration Management?
- **Read**: `global-cli-implementation.md` Phase 1, Step 1.2 only
- **Status**: Update line 982 in `global-cli-implementation.md`
- **Code**: Create `lib/config.sh`
- **Key**: Global config file, defaults

### Working on Version Configuration?
- **Read**: `global-cli-strategy.md` "Version Configuration Strategy" section
- **Read**: `global-cli-implementation.md` Phase 1, Step 1.4 only
- **Status**: Update line 983 in `global-cli-implementation.md`
- **Code**: Create `lib/version-config.sh`
- **Key**: CLI flags override hierarchy

### Working on Project Creation?
- **Read**: `global-cli-implementation.md` Phase 1, Step 1.3 only
- **Status**: Update line 984 in `global-cli-implementation.md`
- **Code**: Create `lib/project-generator.sh`
- **Key**: Project directory creation, component orchestration

### Working on Minimal Python Projects?
- **Read**: `bare-bones-projects.md` "Bare-bones Python Project" section
- **Read**: `global-cli-implementation.md` Phase 2, Step 2.1 (minimal-python.sh)
- **Status**: Update line 991 in `global-cli-implementation.md`
- **Code**: Create `generators/minimal-python.sh`

### Working on Minimal Node Projects?
- **Read**: `bare-bones-projects.md` "Bare-bones Node/JavaScript Project" section
- **Read**: `global-cli-implementation.md` Phase 2, Step 2.1 (minimal-node.sh)
- **Status**: Update line 992 in `global-cli-implementation.md`
- **Code**: Create `generators/minimal-node.sh`

### Working on Component Generators?
- **Read**: `global-cli-implementation.md` Phase 2, Step 2.1 only
- **Status**: Update line 990 in `global-cli-implementation.md`
- **Code**: Create files in `generators/` directory
- **Key**: Backend, frontend, database, etc. modules

### Working on Installation?
- **Read**: `global-cli-implementation.md` Phase 3 only
- **Status**: Update lines 997-1000 in `global-cli-implementation.md`
- **Code**: Create `install.sh` and `Formula/spinbox.rb`
- **Key**: Direct formula URL, not tap

## 📝 Lightweight Status Updates

### Status Symbols:
- ✅ Complete | 🔄 In Progress | ⏳ Pending | ❌ Blocked | 🔀 Changed

### Quick Update Format:
```markdown
**[Feature Name]** - Status changed from ⏳ to 🔄
- Brief note if different from plan
```

## 🔗 Cross-References

When working on specific features, refer to these document sections:

### CLI Entry Point
- Strategy: Command Structure section
- Implementation: Phase 1, Step 1.1

### Version Configuration
- Strategy: Version Configuration Strategy section
- Implementation: Phase 1, Step 1.4

### Project Creation
- Strategy: Project Types section
- Implementation: Phase 1, Step 1.3 & Phase 2

### Installation
- Strategy: Installation Methods section  
- Implementation: Phase 3

### Component Generators
- Bare-bones: All project type sections
- Implementation: Phase 2, Step 2.1

### Migration
- Migration Path: All sections
- Implementation: Phase 5, Step 5.2

## 📚 Additional Documentation

### Existing Documentation
- [`adding-components.md`](./adding-components.md) - How to add components to projects
- [`chroma-usage.md`](./chroma-usage.md) - Chroma vector database usage
- [`performance.md`](./performance.md) - Performance optimization guidelines
- [`troubleshooting.md`](./troubleshooting.md) - Common issues and solutions

### Implementation Artifacts
- [`decisions/`](./decisions/) - Architecture decision records
- [`learnings/`](./learnings/) - Implementation insights and best practices
- [`archive/`](./archive/) - Archived planning documents and outdated files

---

**Remember**: These planning documents are living resources. Update them as you learn and implement. They should reflect both the original plan AND the actual implementation experience.