# Spinbox Documentation Index

## 🚀 User Guides (Start Here!)
- [`installation.md`](./installation.md) - Complete installation guide for all platforms
- [`quick-start.md`](./quick-start.md) - 5-minute tutorial to get started
- [`cli-reference.md`](./cli-reference.md) - Complete command-line interface reference

## 📚 Core Documentation  
- [`adding-components.md`](./adding-components.md) - How to add components to projects
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
- **Troubleshooting**: Visit [Troubleshooting Guide](./troubleshooting.md)
- **Configuration**: Reference [CLI Reference - Config](./cli-reference.md#spinbox-config)

### Advanced Usage
- **Custom Profiles**: See [CLI Reference - Profiles](./cli-reference.md#templates)
- **Component Development**: Check [Implementation Docs](./global-cli-implementation.md)
- **Contributing**: Review implementation and strategy documents

## 🎯 Profiles Quick Reference

| Profile | Use Case | Components | Command |
|---------|----------|------------|---------|
| `web-app` | Full-stack web application | Backend + Frontend + Database | `spinbox create myapp --profile web-app` |
| `api-only` | Backend API development | Backend + Database + Redis | `spinbox create api --profile api-only` |
| `data-science` | ML/Data science projects | Python + Database | `spinbox create ml-proj --profile data-science` |
| `ai-llm` | AI/LLM development | Python + Database + Chroma | `spinbox create ai-proj --profile ai-llm` |
| `minimal` | Basic development | Python DevContainer | `spinbox create basic --profile minimal` |

## 🔧 Components Quick Reference

| Component | Description | Flag | Use With |
|-----------|-------------|------|----------|
| Python | Python DevContainer | `--python` | Any project |
| Node.js | Node.js DevContainer | `--node` | Frontend projects |
| Backend | FastAPI backend | `--backend` | API development |
| Frontend | Next.js frontend | `--frontend` | Web applications |
| Database | PostgreSQL + PGVector | `--database` | Data storage |
| MongoDB | Document database | `--mongodb` | NoSQL projects |
| Redis | Caching and queues | `--redis` | Performance |
| Chroma | Vector database | `--chroma` | AI/ML projects |

---

**Implementation Status: ✅ Complete** - All planned features have been implemented and tested. This documentation reflects the current production-ready state of Spinbox v1.0.0.