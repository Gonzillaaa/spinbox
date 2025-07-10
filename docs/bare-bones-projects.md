# Bare-bones Project Options

## Overview

Spinbox will support minimal project creation options for developers who want to start with just the essentials. These bare-bones projects maintain the DevContainer-first philosophy while providing the lightest possible setup.

## Bare-bones Python Project

### Command Usage
```bash
spinbox myproject --minimal
# or
spinbox myproject --python
```

### What Gets Created
```
myproject/
├── .devcontainer/
│   ├── devcontainer.json     # Python DevContainer configuration
│   └── Dockerfile           # Custom Python environment
├── src/
│   ├── __init__.py
│   └── main.py              # Basic entry point
├── tests/
│   ├── __init__.py
│   └── test_main.py         # Basic test example
├── requirements.txt         # Selected from template
├── .gitignore              # Python-specific gitignore
├── .env.example            # Environment variables template
└── README.md               # Project documentation
```

### DevContainer Configuration
```json
{
  "name": "Python Development Environment",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "workspaceFolder": "/workspace",
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {
      "installZsh": true,
      "installOhMyZsh": true,
      "installOhMyZshConfig": true
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.pylint",
        "ms-python.black-formatter",
        "ms-python.isort",
        "ms-toolsai.jupyter"
      ],
      "settings": {
        "python.defaultInterpreterPath": "/workspace/venv/bin/python",
        "python.terminal.activateEnvironment": true,
        "python.linting.enabled": true,
        "python.linting.pylintEnabled": true,
        "python.formatting.provider": "black",
        "editor.formatOnSave": true,
        "terminal.integrated.defaultProfile.linux": "zsh"
      }
    }
  },
  "postCreateCommand": "python -m venv venv && source venv/bin/activate && pip install -r requirements.txt && pip install -e .",
  "remoteUser": "root"
}
```

### Custom Dockerfile
```dockerfile
FROM python:3.12-slim

WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    zsh \
    fonts-powerline \
    && rm -rf /var/lib/apt/lists/*

# Install UV for fast package management
RUN pip install uv

# Install development tools
RUN pip install black isort pylint pytest

# Set up shell
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true

# Add useful aliases
RUN echo 'alias ll="ls -la"' >> ~/.zshrc && \
    echo 'alias py="python"' >> ~/.zshrc && \
    echo 'alias venv="source venv/bin/activate"' >> ~/.zshrc && \
    echo 'alias test="python -m pytest"' >> ~/.zshrc && \
    echo 'alias install="uv pip install"' >> ~/.zshrc

# Auto-activate virtual environment
RUN echo 'source /workspace/venv/bin/activate 2>/dev/null || true' >> ~/.zshrc

CMD ["zsh"]
```

### Requirements Template Selection
Interactive selection from existing templates:
- **minimal.txt**: Basic development tools
- **data-science.txt**: pandas, numpy, jupyter, scikit-learn
- **ai-llm.txt**: openai, langchain, transformers
- **web-scraping.txt**: beautifulsoup, selenium, requests
- **api-development.txt**: fastapi, uvicorn, pydantic
- **custom.txt**: Minimal template for customization

### Basic Project Structure
**src/main.py**:
```python
#!/usr/bin/env python3
"""
Main entry point for the project.
"""

def main():
    """Main function."""
    print("Hello, Spinbox!")
    print("Your minimal Python project is ready!")

if __name__ == "__main__":
    main()
```

**tests/test_main.py**:
```python
"""
Basic test example.
"""

from src.main import main

def test_main():
    """Test the main function."""
    # This is a placeholder test
    # Add your actual tests here
    assert True

def test_import():
    """Test that main function can be imported."""
    assert callable(main)
```

## Bare-bones Node/JavaScript Project

### Command Usage
```bash
spinbox myproject --node
# or
spinbox myproject --javascript
```

### What Gets Created
```
myproject/
├── .devcontainer/
│   ├── devcontainer.json     # Node.js DevContainer configuration
│   └── Dockerfile           # Custom Node.js environment
├── src/
│   ├── index.js             # Main entry point
│   └── utils/
│       └── helpers.js       # Utility functions
├── tests/
│   ├── index.test.js        # Basic test example
│   └── setup.js            # Test setup
├── package.json            # Dependencies and scripts
├── .gitignore              # Node.js-specific gitignore
├── .env.example            # Environment variables template
├── .eslintrc.js            # ESLint configuration
├── .prettierrc             # Prettier configuration
└── README.md               # Project documentation
```

### DevContainer Configuration
```json
{
  "name": "Node.js Development Environment",
  "build": {
    "dockerfile": "Dockerfile"
  },
  "workspaceFolder": "/workspace",
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {
      "installZsh": true,
      "installOhMyZsh": true,
      "installOhMyZshConfig": true
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.vscode-typescript-next",
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
        "bradlc.vscode-tailwindcss",
        "ms-vscode.vscode-json"
      ],
      "settings": {
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "editor.codeActionsOnSave": {
          "source.fixAll.eslint": true
        },
        "eslint.format.enable": true,
        "terminal.integrated.defaultProfile.linux": "zsh"
      }
    }
  },
  "postCreateCommand": "npm install",
  "remoteUser": "root"
}
```

### Custom Dockerfile
```dockerfile
FROM node:20-slim

WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    zsh \
    fonts-powerline \
    && rm -rf /var/lib/apt/lists/*

# Install global npm packages
RUN npm install -g nodemon eslint prettier

# Set up shell
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true

# Add useful aliases
RUN echo 'alias ll="ls -la"' >> ~/.zshrc && \
    echo 'alias dev="npm run dev"' >> ~/.zshrc && \
    echo 'alias test="npm test"' >> ~/.zshrc && \
    echo 'alias lint="npm run lint"' >> ~/.zshrc && \
    echo 'alias build="npm run build"' >> ~/.zshrc

CMD ["zsh"]
```

### Package.json Template
```json
{
  "name": "{{PROJECT_NAME}}",
  "version": "1.0.0",
  "description": "Minimal Node.js project created with Spinbox",
  "main": "src/index.js",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "test": "jest",
    "test:watch": "jest --watch",
    "lint": "eslint src/**/*.js",
    "lint:fix": "eslint src/**/*.js --fix",
    "format": "prettier --write src/**/*.js"
  },
  "dependencies": {
    "dotenv": "^16.0.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.0",
    "eslint": "^8.0.0",
    "prettier": "^3.0.0",
    "jest": "^29.0.0"
  },
  "keywords": ["nodejs", "spinbox", "minimal"],
  "author": "",
  "license": "ISC",
  "engines": {
    "node": ">=18.0.0"
  }
}
```

### Basic Project Structure
**src/index.js**:
```javascript
#!/usr/bin/env node
/**
 * Main entry point for the project.
 */

const { loadConfig } = require('./utils/helpers');

async function main() {
    console.log('Hello, Spinbox!');
    console.log('Your minimal Node.js project is ready!');
    
    const config = loadConfig();
    console.log(`Environment: ${config.NODE_ENV || 'development'}`);
}

// Run main function if this file is executed directly
if (require.main === module) {
    main().catch(console.error);
}

module.exports = { main };
```

**src/utils/helpers.js**:
```javascript
/**
 * Utility functions for the project.
 */

require('dotenv').config();

/**
 * Load configuration from environment variables
 * @returns {Object} Configuration object
 */
function loadConfig() {
    return {
        NODE_ENV: process.env.NODE_ENV || 'development',
        PORT: process.env.PORT || 3000,
        // Add more configuration as needed
    };
}

module.exports = {
    loadConfig,
};
```

**tests/index.test.js**:
```javascript
/**
 * Basic test example.
 */

const { main } = require('../src/index');

describe('Main function', () => {
    test('should be callable', () => {
        expect(typeof main).toBe('function');
    });
    
    test('should run without errors', async () => {
        // Mock console.log to avoid output during tests
        const consoleSpy = jest.spyOn(console, 'log').mockImplementation(() => {});
        
        await expect(main()).resolves.not.toThrow();
        
        consoleSpy.mockRestore();
    });
});
```

## Interactive Component Selection

Both bare-bones projects will still support adding components later:

```bash
# In a bare-bones project directory
spinbox add backend    # Add FastAPI backend
spinbox add frontend   # Add Next.js frontend
spinbox add database   # Add PostgreSQL database
```

## Configuration Options

### Global Configuration
Users can set defaults in `~/.config/spinbox/config.toml`:

```toml
[defaults]
python_version = "3.12"
node_version = "20"
requirements_template = "minimal"
package_template = "minimal"

[bare_bones]
# Default components to include in bare-bones projects
include_tests = true
include_docker = false
include_ci = false
```

### Project-specific Configuration
Each project can have a `.spinbox` file for project-specific settings:

```toml
[project]
type = "bare-bones-python"
template = "data-science"
created_at = "2024-01-15T10:30:00Z"

[components]
# Track which components are installed
devcontainer = true
backend = false
frontend = false
database = false
```

## Benefits of Bare-bones Projects

### For Rapid Prototyping
- **Minimal setup time**: < 30 seconds to running environment
- **Essential tools only**: No bloat or unnecessary dependencies
- **Easy to extend**: Add components as needed

### For Learning
- **Clear structure**: Understand what each file does
- **Best practices**: Follow Python/Node.js conventions
- **DevContainer first**: Learn modern development practices

### For Experimentation
- **Quick iterations**: Fast setup for testing ideas
- **Isolated environments**: Each project is completely separate
- **Easy cleanup**: Simple to delete and start over

## Migration from Current System

Current minimal project creation in `project-setup.sh` will be enhanced to support both Python and Node.js bare-bones projects while maintaining the same interactive experience users expect.

The key difference is that instead of cloning a template repository, users will have a global tool that can create these minimal projects anywhere on their system with a single command.