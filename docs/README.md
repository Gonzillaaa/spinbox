# Spinbox Documentation Index

## 🚀 User Documentation
Essential guides for Spinbox users - start here for installation, tutorials, and daily usage.

- [`user/installation.md`](./user/installation.md) - Complete installation guide for all platforms
- [`user/quick-start.md`](./user/quick-start.md) - 5-minute tutorial to get started
- [`user/cli-reference.md`](./user/cli-reference.md) - Complete command-line interface reference
- [`user/dependency-management.md`](./user/dependency-management.md) - Automatic dependency management with --with-deps
- [`user/git-hooks.md`](./user/git-hooks.md) - Git repository and hooks configuration
- [`user/docker-hub-configuration.md`](./user/docker-hub-configuration.md) - Docker Hub optimized images
- [`user/chroma-usage.md`](./user/chroma-usage.md) - Chroma vector database usage guide
- [`user/troubleshooting.md`](./user/troubleshooting.md) - Common issues and solutions

## 🏗️ Development Documentation
Technical documentation for contributors and component developers.

- [`dev/README.md`](./dev/README.md) - **Developer docs index**
- [`dev/architecture.md`](./dev/architecture.md) - System design and component system
- [`dev/bare-bones-projects.md`](./dev/bare-bones-projects.md) - Minimal project structure
- [`dev/release-process.md`](./dev/release-process.md) - Release process
- [`dev/roadmap.md`](./dev/roadmap.md) - Roadmap and backlog

## 🎯 Quick Navigation

### New to Spinbox?
1. **[Installation Guide](./user/installation.md)** - Set up Spinbox on your system
2. **[Quick Start Tutorial](./user/quick-start.md)** - 5-minute walkthrough 
3. **[CLI Reference](./user/cli-reference.md)** - Complete command documentation

### Common Tasks
- **Creating Projects**: See [Quick Start Guide](./user/quick-start.md) for examples
- **Adding Components**: See [CLI Reference - add](./user/cli-reference.md#spinbox-add)
- **Troubleshooting**: Visit [Troubleshooting Guide](./user/troubleshooting.md)
- **Configuration**: Reference [CLI Reference - Config](./user/cli-reference.md#spinbox-config)

### Advanced Usage
- **Custom Profiles**: See [CLI Reference - Profiles](./user/cli-reference.md#templates)
- **Component Development**: Check [Architecture](./dev/architecture.md)
- **Contributing**: Start with [Developer Docs](./dev/README.md)

## 🎯 Profiles Quick Reference

| Profile | Use Case | Components | Command |
|---------|----------|------------|---------|
| `web-app` | Full-stack web application | Backend + Frontend + Database | `spinbox create myapp --profile web-app` |
| `api-only` | Backend API development | Backend + Database + Redis | `spinbox create api --profile api-only` |
| `data-science` | ML/Data science projects | Python + Database | `spinbox create ml-proj --profile data-science` |
| `ai-llm` | AI/LLM development | Python + Database + Chroma | `spinbox create ai-proj --profile ai-llm` |
| `python` | Python development | Python + testing tools | `spinbox create basic --profile python` |
| `node` | Node.js development | Node.js + TypeScript + testing | `spinbox create basic --profile node` |

## 🔧 Components Quick Reference

| Component | Description | Flag | Use With |
|-----------|-------------|------|----------|
| Python | Python DevContainer | `--python` | Any project |
| Node.js | Node.js DevContainer | `--node` | Frontend projects |
| FastAPI | FastAPI backend | `--fastapi` | API development |
| Next.js | Next.js frontend | `--nextjs` | Web applications |
| PostgreSQL | PostgreSQL + PGVector | `--postgresql` | Relational data |
| MongoDB | MongoDB document database | `--mongodb` | Document/NoSQL data |
| Redis | Redis caching/queue | `--redis` | Performance/caching |
| Chroma | Chroma vector database | `--chroma` | AI/ML embeddings |

---

**Implementation Status: ✅ Complete** - All planned features have been implemented and tested. This documentation reflects the current production-ready state of Spinbox v0.1.0.