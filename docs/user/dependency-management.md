# Dependency Management

Spinbox supports automatic dependency management for Python and Node.js projects using the `--with-deps` flag.

## Overview

The `--with-deps` flag automatically adds the required packages to your project's dependency files:
- **Python projects**: Adds packages to `requirements.txt`
- **Node.js projects**: Adds packages to `package.json`

## Usage

### Create Command

```bash
# Create a FastAPI project with automatic dependency management
spinbox create myapi --fastapi --with-deps

# Create a Next.js project with automatic dependency management
spinbox create myapp --nextjs --with-deps

# Create a full-stack project with dependencies
spinbox create fullstack --fastapi --nextjs --postgresql --with-deps
```

### Add Command

```bash
# Add Redis component with its dependencies
spinbox add --redis --with-deps

# Add multiple components with dependencies
spinbox add --postgresql --chroma --with-deps
```

## Supported Components

### Python Components

| Component | Packages Added |
|-----------|---------------|
| `fastapi` | fastapi, uvicorn, pydantic, python-dotenv |
| `postgresql` | sqlalchemy, asyncpg, alembic, psycopg2-binary |
| `redis` | redis, celery |
| `chroma` | chromadb, sentence-transformers |
| `mongodb` | beanie, motor |
| `openai` | openai, tiktoken |
| `anthropic` | anthropic |
| `langchain` | langchain, langchain-community, langchain-openai |
| `llamaindex` | llama-index, llama-index-vector-stores-chroma |

### Node.js Components

| Component | Packages Added |
|-----------|---------------|
| `nextjs` | next, react, react-dom, axios, @types/node, @types/react, typescript, eslint |
| `express` | express, cors, helmet, morgan, @types/express, @types/cors, @types/morgan |
| `tailwindcss` | tailwindcss, autoprefixer, postcss |

### Template Dependencies

| Template | Packages Added |
|----------|---------------|
| `data-science` | pandas, numpy, matplotlib, seaborn, scikit-learn, jupyter, plotly |
| `ai-llm` | openai, anthropic, langchain, llama-index, tiktoken, transformers |
| `web-scraping` | beautifulsoup4, requests, selenium, scrapy, lxml |
| `api-development` | fastapi, uvicorn, pydantic, httpx, python-multipart |

## Examples

### Basic FastAPI API

```bash
spinbox create myapi --fastapi --with-deps
cd myapi
```

This creates a FastAPI project with `requirements.txt` containing:
```
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
pydantic>=2.5.0
python-dotenv>=1.0.0
```

### Full-Stack Application

```bash
spinbox create webapp --fastapi --nextjs --postgresql --with-deps
cd webapp
```

This creates:
- `requirements.txt` with FastAPI and PostgreSQL dependencies
- `nextjs/package.json` with Next.js dependencies

### AI/LLM Project

```bash
spinbox create ai-project --fastapi --chroma --with-deps --template ai-llm
cd ai-project
```

This creates a project with:
- FastAPI dependencies
- Chroma vector database dependencies
- AI/LLM template dependencies (OpenAI, LangChain, etc.)

## Features

### Automatic Package Detection

The system automatically detects:
- Existing `requirements.txt` files
- Existing `package.json` files
- Component combinations to avoid duplicate dependencies

### Smart Dependency Resolution

- Avoids adding duplicate packages
- Uses compatible version ranges
- Handles transitive dependencies appropriately

### Setup Scripts

When `--with-deps` is used, Spinbox also creates setup scripts:
- `setup-python-deps.sh` for Python projects
- `setup-nodejs-deps.sh` for Node.js projects

## Installation

After creating a project with `--with-deps`, install dependencies:

### Python
```bash
# Using the setup script
./setup-python-deps.sh

# Or manually
pip install -r requirements.txt
```

### Node.js
```bash
# Using the setup script
./setup-nodejs-deps.sh

# Or manually
npm install
```

## Configuration

Dependencies are defined in:
- `templates/dependencies/python-components.toml`
- `templates/dependencies/nodejs-components.toml`

You can customize these files to modify which packages are added for each component.

## Best Practices

1. **Use with DevContainers**: The `--with-deps` flag works best with DevContainers, which provide isolated environments.

2. **Review Dependencies**: Always review the generated `requirements.txt` and `package.json` files before installing.

3. **Version Management**: Dependencies use conservative version ranges for stability.

4. **Security**: Keep dependencies updated and review package security advisories.

## Troubleshooting

### Package Not Found
If a package isn't available in your package index:
```bash
# Check package availability
pip search package-name
npm search package-name
```

### Version Conflicts
If you encounter version conflicts:
```bash
# Check current versions
pip list
npm list
```

### Custom Dependencies
To add custom dependencies:
1. Edit `requirements.txt` or `package.json` directly
2. Or modify the component templates in `templates/dependencies/`

## Future Enhancements

Planned features:
- Support for more package managers (Poetry, Yarn, pnpm)
- Automatic security vulnerability scanning
- Dependency update notifications
- Custom dependency profiles