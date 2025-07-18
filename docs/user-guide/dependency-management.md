# Dependency Management Guide

The `--with-deps` flag automatically manages dependencies for your Spinbox projects, eliminating the need to manually add packages to `requirements.txt` or `package.json`.

## Quick Start

```bash
# Create a project with automatic dependency management
spinbox create myproject --fastapi --postgresql --with-deps

# Add a component with dependencies to existing project
spinbox add --chroma --with-deps
```

## How It Works

When you use `--with-deps`, Spinbox:

1. **Automatically adds appropriate dependencies** to `requirements.txt` (Python) or `package.json` (Node.js)
2. **Creates installation scripts** (`setup-python-deps.sh`, `setup-nodejs-deps.sh`)
3. **Sorts and cleans** dependency files
4. **Provides a summary** of all dependencies added

## Component Dependencies

### Python Components

| Component | Dependencies Added |
|-----------|-------------------|
| **FastAPI** | `fastapi>=0.104.0`, `uvicorn[standard]>=0.24.0`, `pydantic>=2.5.0`, `python-dotenv>=1.0.0` |
| **PostgreSQL** | `sqlalchemy>=2.0.0`, `asyncpg>=0.29.0`, `alembic>=1.13.0`, `psycopg2-binary>=2.9.0` |
| **Redis** | `redis>=5.0.0`, `celery>=5.3.0` |
| **MongoDB** | `beanie>=1.24.0`, `motor>=3.3.0` |
| **Chroma** | `chromadb>=0.4.0`, `sentence-transformers>=2.2.0` |

### Node.js Components

| Component | Dependencies Added |
|-----------|-------------------|
| **Next.js** | `next^14.0.0`, `react^18.0.0`, `react-dom^18.0.0`, `axios^1.6.0` |
| **Next.js (dev)** | `@types/node^20.0.0`, `@types/react^18.0.0`, `@types/react-dom^18.0.0`, `typescript^5.0.0`, `eslint^8.0.0`, `eslint-config-next^14.0.0` |
| **Express** | `express^4.18.0`, `cors^2.8.5`, `helmet^7.0.0`, `morgan^1.10.0` |
| **TailwindCSS** | `tailwindcss^3.3.0`, `autoprefixer^10.4.0`, `postcss^8.4.0` |

### Profile-Based Dependencies

| Profile | Dependencies Added |
|---------|-------------------|
| **AI/LLM** | `openai>=1.3.0`, `anthropic>=0.7.0`, `langchain>=0.0.350`, `llama-index>=0.9.0`, `tiktoken>=0.5.0`, `transformers>=4.36.0` |
| **Data Science** | `pandas>=2.0.0`, `numpy>=1.24.0`, `matplotlib>=3.7.0`, `seaborn>=0.12.0`, `scikit-learn>=1.3.0`, `jupyter>=1.0.0`, `plotly>=5.15.0` |
| **Web Scraping** | `beautifulsoup4>=4.12.0`, `requests>=2.31.0`, `selenium>=4.15.0`, `scrapy>=2.11.0`, `lxml>=4.9.0` |
| **API Development** | `fastapi>=0.104.0`, `uvicorn[standard]>=0.24.0`, `pydantic>=2.5.0`, `httpx>=0.25.0`, `python-multipart>=0.0.6` |

## Installation Scripts

Spinbox creates installation scripts for easy dependency management:

### Python Dependencies

```bash
# Generated script: setup-python-deps.sh
#!/bin/bash
set -e

echo "Setting up Python dependencies..."

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed"
    exit 1
fi

# Install dependencies
echo "Installing Python dependencies from requirements.txt..."
pip3 install -r requirements.txt

echo "Python dependencies installed successfully!"
```

### Node.js Dependencies

```bash
# Generated script: setup-nodejs-deps.sh
#!/bin/bash
set -e

echo "Setting up Node.js dependencies..."

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed"
    exit 1
fi

# Install dependencies
echo "Installing Node.js dependencies from package.json..."
npm install

echo "Node.js dependencies installed successfully!"
```

## Usage Examples

### Basic Usage

```bash
# Create a FastAPI project with dependencies
spinbox create api-project --fastapi --with-deps

# Result:
# - requirements.txt with FastAPI dependencies
# - setup-python-deps.sh script
```

### Full-Stack Project

```bash
# Create a full-stack project with dependencies
spinbox create webapp --fastapi --nextjs --postgresql --with-deps

# Result:
# - requirements.txt with FastAPI + PostgreSQL dependencies
# - package.json with Next.js dependencies
# - setup-python-deps.sh script
# - setup-nodejs-deps.sh script
```

### AI/ML Project

```bash
# Create an AI project with LLM dependencies
spinbox create ai-project --profile ai-llm --with-deps

# Result:
# - requirements.txt with OpenAI, Anthropic, LangChain, etc.
# - setup-python-deps.sh script
```

### Adding to Existing Project

```bash
# Add Redis with dependencies to existing project
cd my-existing-project
spinbox add --redis --with-deps

# Result:
# - Redis dependencies added to existing requirements.txt
# - setup-python-deps.sh updated
```

## Combining with Examples

Use both flags together for a complete development setup:

```bash
# Create project with dependencies AND examples
spinbox create fullstack --fastapi --nextjs --postgresql --with-deps --with-examples

# Result:
# - All dependencies added
# - Working code examples included
# - Installation scripts created
# - Documentation and usage instructions
```

## Dependency Summary

After running with `--with-deps`, Spinbox shows a summary:

```
Dependency Management Summary:
✓ Python packages: 14 dependencies in requirements.txt
✓ Node.js packages: 31 dependencies, 31 dev dependencies in package.json
ℹ Run 'pip install -r requirements.txt' to install Python dependencies
ℹ Run 'npm install' to install Node.js dependencies
```

## Smart Component Detection

Spinbox automatically detects the correct dependency type:

- **Python components** (FastAPI, PostgreSQL, Redis, etc.) → `requirements.txt`
- **Node.js components** (Next.js, Express, TailwindCSS) → `package.json`
- **No cross-contamination** → Python dependencies won't appear in `package.json`

## File Management

### Requirements.txt

```txt
# Python dependencies for myproject
# Generated by Spinbox

# Development tools
alembic>=1.13.0
asyncpg>=0.29.0
black>=23.0.0
fastapi>=0.104.0
psycopg2-binary>=2.9.0
pydantic>=2.5.0
python-dotenv>=1.0.0
sqlalchemy>=2.0.0
uv>=0.1.0
uvicorn[standard]>=0.24.0
```

### Package.json

```json
{
  "name": "myproject",
  "version": "1.0.0",
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "axios": "^1.6.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/react": "^18.0.0",
    "@types/react-dom": "^18.0.0",
    "typescript": "^5.0.0",
    "eslint": "^8.0.0",
    "eslint-config-next": "^14.0.0"
  }
}
```

## Troubleshooting

### Common Issues

**Q: Dependencies not being added**
- Ensure you're using the `--with-deps` flag
- Check that the component is supported for dependency management
- Verify the component is being detected correctly

**Q: Wrong dependency type added**
- This should not happen due to smart component detection
- Report as a bug if Python dependencies appear in `package.json`

**Q: Installation scripts not created**
- Scripts are only created when dependency files exist
- Check that `requirements.txt` or `package.json` was created
- Verify the `--with-deps` flag was used

**Q: Duplicate dependencies**
- Spinbox automatically handles duplicates
- Existing dependencies are not overwritten
- Dependencies are sorted and cleaned automatically

### Getting Help

If you encounter issues with dependency management:

1. **Check the summary output** - Look for error messages or warnings
2. **Verify file contents** - Check that `requirements.txt` and `package.json` are correct
3. **Test installation scripts** - Run the generated scripts to verify they work
4. **Report issues** - File bug reports with specific component combinations

## Best Practices

1. **Always use `--with-deps`** for new projects to ensure dependencies are managed
2. **Combine with `--with-examples`** for complete development setup
3. **Review generated files** before committing to version control
4. **Test installation scripts** in clean environments
5. **Update dependencies regularly** using standard package managers

## Advanced Usage

### Profile-Based Dependencies

```bash
# AI/LLM project with specialized dependencies
spinbox create ai-project --profile ai-llm --with-deps

# Data science project with ML dependencies
spinbox create data-project --profile data-science --with-deps
```

### Selective Component Addition

```bash
# Add just the dependencies you need
spinbox add --chroma --with-deps          # Vector database
spinbox add --redis --with-deps           # Caching layer
spinbox add --mongodb --with-deps         # Document database
```

### Mixed Language Projects

```bash
# Full-stack with both Python and Node.js dependencies
spinbox create fullstack --fastapi --nextjs --postgresql --with-deps

# Result:
# - requirements.txt with Python dependencies
# - package.json with Node.js dependencies
# - Both installation scripts created
```

This dependency management system eliminates the manual work of researching and adding dependencies, allowing you to focus on building your application.