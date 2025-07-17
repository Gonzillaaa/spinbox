# Spinbox Working Examples

This directory contains production-ready code examples for all Spinbox components and their combinations.

## Quick Start

1. Create a project with examples:
   ```bash
   spinbox create myproject --fastapi --with-examples
   ```

2. Examples are copied to your project with `example-` prefix
3. Each example includes a README with setup instructions

## Directory Structure

### Core Components
- **`core-components/fastapi/`** - FastAPI REST API examples
- **`core-components/nextjs/`** - Next.js React component examples
- **`core-components/postgresql/`** - Database schema and query examples
- **`core-components/redis/`** - Caching and session management examples
- **`core-components/mongodb/`** - MongoDB document database examples
- **`core-components/chroma/`** - Vector database and similarity search examples

### AI/LLM Integration
- **`ai-llm/openai/`** - OpenAI GPT integration examples
- **`ai-llm/anthropic/`** - Anthropic Claude integration examples
- **`ai-llm/langchain/`** - LangChain framework examples
- **`ai-llm/llamaindex/`** - LlamaIndex framework examples

### Data Science
- **`data-science/`** - Data analysis, ML, and visualization examples

### Component Combinations
- **`combinations/two-component/`** - Two-component integration examples
- **`combinations/three-component/`** - Three-component integration examples
- **`combinations/full-stack/`** - Complete application examples

## Available Combinations

### Two-Component Combinations
- **FastAPI + PostgreSQL**: Database-backed REST APIs
- **FastAPI + OpenAI**: AI-powered API endpoints
- **FastAPI + LangChain**: RAG and agent-based APIs
- **FastAPI + Chroma**: Vector database APIs
- **FastAPI + Redis**: Cached and session-based APIs
- **FastAPI + Data Science**: ML and analytics APIs
- **Next.js + FastAPI**: Full-stack web applications
- **Next.js + AI**: AI-powered frontend interfaces

### Three-Component Combinations
- **FastAPI + PostgreSQL + AI**: Chat with conversation history
- **FastAPI + Chroma + AI**: Complete RAG systems
- **FastAPI + Redis + AI**: Cached AI responses
- **Next.js + FastAPI + AI**: Full-stack AI applications

### Full-Stack Applications
- **AI Chat Platform**: Complete chat system with conversation history
- **RAG Documentation System**: Document Q&A with semantic search
- **ML Analytics Platform**: Data analytics dashboard
- **AI Content Generator**: Content creation platform

## Example Features

All examples are designed to be:
- **Copy-paste ready**: Work immediately after setup
- **Production patterns**: Follow best practices and security guidelines
- **Well-documented**: Clear inline comments and README files
- **Minimal dependencies**: Only essential packages required
- **Error handling**: Proper error handling and validation
- **Environment-based**: Use environment variables for configuration

## File Naming Convention

- All examples use `example-` prefix for easy identification
- Files are named by functionality: `example-{purpose}.{ext}`
- README.md files provide setup and usage instructions
- Consistent structure across all components

## Usage Patterns

### Single Component
```bash
spinbox create myapi --fastapi --with-examples
# Creates FastAPI examples in fastapi/
```

### Multiple Components
```bash
spinbox create myapp --fastapi --postgresql --with-examples
# Creates individual examples + combination examples
```

### AI/LLM Projects
```bash
spinbox create myai --profile ai-llm --with-examples
# Creates AI-focused examples with multiple providers
```

### Data Science Projects
```bash
spinbox create mydata --profile data-science --with-examples
# Creates data analysis and ML examples
```

### Full-Stack Applications
```bash
spinbox create myapp --nextjs --fastapi --postgresql --with-examples
# Creates full-stack application examples
```

## Environment Setup

Most examples require environment variables:
```bash
# Copy environment template
cp .env.example .env

# Edit with your values
OPENAI_API_KEY=your-key-here
DATABASE_URL=postgresql://user:pass@localhost/db
```

## Getting Help

1. Check the component-specific README in each directory
2. Review the troubleshooting section in individual examples
3. Check the main Spinbox documentation
4. File an issue on GitHub for bugs or requests

## Contributing

When adding new examples:
1. Use the `example-` prefix for all files
2. Include comprehensive README with setup instructions
3. Follow existing patterns and conventions
4. Test examples in fresh environments
5. Document all dependencies and environment requirements

---

*Examples are regularly updated to reflect current best practices and framework versions.*