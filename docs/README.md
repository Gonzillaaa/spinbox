# Spinbox Documentation Index

## 🚀 User Guides (Start Here!)
- [`installation.md`](./installation.md) - Complete installation guide for all platforms
- [`quick-start.md`](./quick-start.md) - 5-minute tutorial to get started
- [`cli-reference.md`](./cli-reference.md) - Complete command-line interface reference

## 📚 Core Documentation  
- [`adding-components.md`](./adding-components.md) - How to add components to projects
- [`git-hooks.md`](./git-hooks.md) - Git hooks integration and quality assurance
- [`chroma-usage.md`](./chroma-usage.md) - Chroma vector database usage guide
- [`troubleshooting.md`](./troubleshooting.md) - Common issues and solutions
- [`bare-bones-projects.md`](./bare-bones-projects.md) - Minimal project specifications

## 🏗️ Implementation Documentation
- [`global-cli-strategy.md`](./global-cli-strategy.md) - High-level vision and approach
- [`global-cli-implementation.md`](./global-cli-implementation.md) - Detailed technical implementation
- [`implementation-strategy.md`](./implementation-strategy.md) - Implementation strategy overview

## 🎯 Quick Navigation

### New to Spinbox?
1. **[Installation Guide](./installation.md)** - Set up Spinbox on your system
2. **[Quick Start Tutorial](./quick-start.md)** - 5-minute walkthrough 
3. **[CLI Reference](./cli-reference.md)** - Complete command documentation

### Common Tasks
- **Creating Projects**: See [Quick Start Guide](./quick-start.md) for examples
- **Adding Components**: Check [Adding Components Guide](./adding-components.md)
- **Setting Up Git Hooks**: Follow [Git Hooks Guide](./git-hooks.md) for quality assurance
- **Troubleshooting**: Visit [Troubleshooting Guide](./troubleshooting.md)
- **Configuration**: Reference [CLI Reference - Config](./cli-reference.md#spinbox-config)

### Advanced Usage
- **Custom Profiles**: See [CLI Reference - Profiles](./cli-reference.md#templates)
- **Component Development**: Check [Implementation Docs](./global-cli-implementation.md)
- **Contributing**: Review implementation and strategy documents

## 🎯 Profiles Quick Reference

| Profile | Use Case | Components | Command |
|---------|----------|------------|---------|
| `web-app` | Full-stack web application | FastAPI + Next.js + PostgreSQL | `spinbox create myapp --profile web-app` |
| `api-only` | Backend API development | FastAPI + PostgreSQL + Redis | `spinbox create api --profile api-only` |
| `data-science` | Data analysis workflow | Data Science + PostgreSQL | `spinbox create ml-proj --profile data-science` |
| `ai-llm` | AI/LLM workflow | AI/ML + Chroma | `spinbox create ai-proj --profile ai-llm` |
| `minimal` | Basic development | Python DevContainer | `spinbox create basic --profile minimal` |

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