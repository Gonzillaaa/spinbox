# Roadmap & Backlog

## Philosophy

**Core principle**: Always choose the simplest possible implementation that works.

## Current: v0.1.0-beta.8

Foundation complete:
- 8 component generators
- 6 profiles
- Automatic dependency management
- Git hooks, Docker Hub optimization
- Atomic installation updates

## Technical Debt

**High**: Error message clarity (shell details shown instead of user-friendly messages)

**Medium**: Template caching, dependency conflict detection

**Low**: Help text cleanup

## Future Enhancements

### v0.2.0 - Developer Experience
- Homebrew tap for Mac installation
- Cloud deployment helpers (Vercel, Railway)
- Improved error messages

### v0.3.0 - Extensibility
- Plugin system for community components
- Template sharing infrastructure

### v1.0 Vision
- Instant setup (<5s for any stack)
- Rich plugin ecosystem
- Enterprise-ready

## Quality Metrics

- **Tests**: 124/124 passing
- **Performance**: <0.5s project generation
- **Memory**: <50MB during creation
