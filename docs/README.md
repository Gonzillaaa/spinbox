# Spinbox Documentation Index

## 🚀 User Documentation

**For end-users who want to install, configure, and use Spinbox:**

### Getting Started
- **[Installation Guide](./user/installation.md)** - Complete installation guide for all platforms
- **[Quick Start Tutorial](./user/quick-start.md)** - 5-minute tutorial to get started  
- **[CLI Reference](./user/cli-reference.md)** - Complete command-line interface reference

### User Guides
- **[Adding Components](./user/adding-components.md)** - How to add components to projects
- **[Git Hooks Integration](./user/git-hooks.md)** - Git hooks integration and quality assurance
- **[Chroma Database Usage](./user/chroma-usage.md)** - Chroma vector database usage guide
- **[Troubleshooting](./user/troubleshooting.md)** - Common issues and solutions

### Quick Navigation for Users
- **New to Spinbox?** Start with [Installation](./user/installation.md) → [Quick Start](./user/quick-start.md) → [CLI Reference](./user/cli-reference.md)
- **Need Help?** Check [Troubleshooting](./user/troubleshooting.md) or [Adding Components](./user/adding-components.md)
- **Advanced Features?** See [Git Hooks](./user/git-hooks.md) or [Chroma Usage](./user/chroma-usage.md)

## 🏗️ Developer Documentation

**For contributors, maintainers, and developers working on Spinbox:**

### Implementation & Strategy
- **[Global CLI Strategy](./dev/global-cli-strategy.md)** - High-level vision and approach
- **[Global CLI Implementation](./dev/global-cli-implementation.md)** - Detailed technical implementation
- **[Implementation Strategy](./dev/implementation-strategy.md)** - Implementation strategy overview

### Development & Process
- **[Development Backlog](./dev/backlog.md)** - Feature roadmap and implementation tracking
- **[Bare-bones Projects](./dev/bare-bones-projects.md)** - Minimal project specifications
- **[Release Process](./dev/release-process.md)** - Release procedures and versioning

### Quick Navigation for Developers
- **Contributing?** Start with [Implementation Strategy](./dev/implementation-strategy.md) → [Global CLI Implementation](./dev/global-cli-implementation.md)
- **Planning?** Check [Development Backlog](./dev/backlog.md) or [Global CLI Strategy](./dev/global-cli-strategy.md)
- **Releasing?** Follow [Release Process](./dev/release-process.md) guidelines

## 🎯 Profiles Quick Reference

### 🎯 **Predefined Profiles - Choose Your Stack**

| Profile | What's Included | Perfect For |
|---------|-----------------|-------------|
| **web-app** | FastAPI + Next.js + PostgreSQL | Full-stack web applications |
| **api-only** | FastAPI + PostgreSQL + Redis | High-performance API backends |
| **data-science** | Jupyter + pandas + scikit-learn + PostgreSQL | Data analysis & ML workflows |
| **ai-llm** | OpenAI + LangChain + LlamaIndex + ChromaDB | AI/LLM applications |
| **minimal** | Python DevContainer + essential tools | Simple scripts & prototypes |

**Quick Commands:**
```bash
spinbox create myapp --profile web-app        # Full-stack application
spinbox create api --profile api-only         # High-performance API
spinbox create analysis --profile data-science # Data analysis project
spinbox create ai-proj --profile ai-llm       # AI/LLM application
spinbox create basic --profile minimal        # Simple Python project
```

## 🔧 Components Quick Reference

**Application Frameworks** (Build user interfaces):
| Component | Description | Flag | Use With |
|-----------|-------------|------|----------|
| FastAPI | Backend framework | `--fastapi` | API development |
| Next.js | Frontend framework | `--nextjs` | Web applications |

**Workflow Frameworks** (Specialized work methodologies):
| Component | Description | Flag | Use With |
|-----------|-------------|------|----------|
| Data Science | Data analysis workflow | `--data-science` | ML/analysis projects |
| AI/ML | AI/LLM workflow | `--ai-ml` | AI/agent projects |

**Infrastructure Services** (Data storage & core services):
| Component | Description | Flag | Use With |
|-----------|-------------|------|----------|
| PostgreSQL | Primary storage + PGVector | `--postgresql` | Relational data |
| MongoDB | Document storage | `--mongodb` | Document/NoSQL data |
| Redis | Caching/queue layer | `--redis` | Performance/caching |
| Chroma | Vector search layer | `--chroma` | AI/ML embeddings |

**Foundation Environments** (Base containers):
| Component | Description | Flag | Use With |
|-----------|-------------|------|----------|
| Python | Python DevContainer | `--python` | Any Python project |
| Node.js | Node.js DevContainer | `--node` | Any Node.js project |

---

**Implementation Status: ✅ Complete** - All planned features have been implemented and tested. This documentation reflects the current production-ready state of Spinbox v0.1.0.