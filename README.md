# Spinbox: Rapid Development Environment Scaffolding

[logo]: https://github.com/Gonzillaaa/spinbox/docs/spinbox.png "Spinbox"

![alt text][logo]

A comprehensive **scaffolding** toolkit for spinning up customizable development environments in both new and existing codebases on **macOS**. Uses Docker, DevContainers (compatible with VS Code, Cursor, and other editors), and Zsh with Powerlevel10k. Build your stack by selecting any combination of:

- FastAPI backend (Python 3.12+)
- Next.js frontend (TypeScript)
- PostgreSQL database with PGVector
- MongoDB document database
- Redis for caching and queues
- Chroma vector database for embeddings

## 🚀 Features

- **DevContainer-First**: Every setup includes a DevContainer as the baseline
- **Requirements.txt Templates**: Quick-start templates for common prototyping scenarios
- **Works with Existing Codebases**: No need to start from scratch
- **Temporary Scaffolding**: Delete the setup directory after use
- **Modular Components**: Start with DevContainer, add what you need
- **Modern Tech Stack**: Python 3.12+, UV package manager, Next.js
- **Enhanced Developer Experience**:
  - DevContainers for consistency across VS Code, Cursor, and other editors
  - Zsh with Powerlevel10k for a beautiful, functional terminal in all containers
  - UV package manager and preconfigured aliases and shortcuts
- **macOS Native**: Built specifically for macOS with Homebrew integration
- **Fully Automated**: Single-command setup and initialization
- **Root-Level Deployment**: All project files created at repository root

## 📋 Prerequisites

- macOS (required)
- Docker Desktop
- DevContainer-compatible editor (VS Code, Cursor, etc.)
- Git

## 🏁 Quick Start

### 1. Set Up Your Environment (One-time)

```bash
# Clone this repository temporarily
git clone https://github.com/Gonzillaaa/spinbox.git
cd spinbox

# Run the macOS setup script
chmod +x macos-setup.sh
./macos-setup.sh
```

This installs all required tools via Homebrew and configures Zsh with Powerlevel10k on macOS.

### 2. Set Up Your Project

#### For Existing Codebases:
```bash
cd your-existing-repo/
git clone https://github.com/Gonzillaaa/spinbox.git spinbox/
./spinbox/project-setup.sh
# Always creates DevContainer + select additional components you want
# After setup completes:
rm -rf spinbox/  # Safe to delete!
```

#### For New Projects:
```bash
mkdir new-project && cd new-project/
git clone https://github.com/Gonzillaaa/spinbox.git spinbox/
./spinbox/project-setup.sh
# Select components
rm -rf spinbox/  # Safe to delete!
```

### 3. Start Your Development Environment

```bash
# If spinbox still exists:
./spinbox/start.sh

# OR if you deleted spinbox:
docker-compose up -d
# Then open in your preferred editor:
code .     # VS Code
cursor .   # Cursor
# Or manually open the project folder
```

Your editor should detect the DevContainer configuration and prompt to "Reopen in Container".

## 🗂️ Structure

### Scaffolding Directory (Temporary)
```
spinbox/
├── macos-setup.sh         # Environment setup for macOS
├── project-setup.sh       # Project creation and configuration
├── start.sh               # Project startup script
├── lib/                   # Utility libraries
├── docs/                  # Documentation
├── templates/             # Requirements.txt templates
└── README.md              # This file
```

### After Setup (Permanent)
```
your-repo/
├── backend/               # FastAPI backend (if selected)
├── frontend/              # Next.js frontend (if selected)
├── database/              # PostgreSQL config (if selected)
├── mongodb/               # MongoDB config (if selected)
├── redis/                 # Redis config (if selected)
├── chroma_data/           # Chroma vector database data (if selected)
├── .devcontainer/         # DevContainer config with Dockerfile (always created)
├── docker-compose.yml     # Docker services (if components selected)
├── venv/                  # Python virtual environment (created in DevContainer)
├── requirements.txt       # Python dependencies
├── package.json          # Node.js dependencies (if frontend)
└── README.md             # Project documentation
```

## 🧩 Components

### FastAPI Backend

- Python 3.12+ with type hints
- UV package manager for dependencies
- Virtual environment for isolation
- SQLAlchemy ORM with async support
- Alembic for migrations
- Easy-to-extend structure

### Next.js Frontend

- TypeScript for type safety
- Modern App Router
- Tailwind CSS for styling
- ESLint for code quality
- Optimized for DevContainer development

### PostgreSQL with PGVector

- Vector embedding support
- Initialization scripts for schema setup
- Proper volume configuration
- PGVector extension pre-installed

### MongoDB

- Document database for flexible data storage
- Initialization scripts for collections and indexes
- Authentication enabled
- Volume persistence configured

### Redis

- Configured for caching and queues
- Persistence enabled
- Optimized configuration

### Chroma Vector Database

- Lightweight vector database for embeddings
- Persistent storage for vectors
- Simple REST API for adding and searching documents
- Built-in similarity search

## 📦 Requirements.txt Templates

When setting up a minimal Python project, choose from curated requirements.txt templates:

- **Minimal**: Basic development tools (uv, pytest, black, python-dotenv, requests)
- **Data Science**: pandas, numpy, matplotlib, jupyter, plotly, scikit-learn
- **AI/LLM**: openai, anthropic, langchain, llama-index, tiktoken
- **Web Scraping**: beautifulsoup4, selenium, scrapy, lxml
- **API Development**: fastapi, uvicorn, pydantic, httpx
- **Custom**: Minimal template you can customize

Perfect for rapid prototyping - get started immediately with the right dependencies!

## 🔄 Adding Components Later

Already set up a project but need to add more components? No problem!

### Re-run Setup

```bash
# In your existing project:
git clone https://github.com/Gonzillaaa/spinbox.git spinbox/
./spinbox/project-setup.sh
# Select additional components you want to add
rm -rf spinbox/
```

The setup script will detect existing components and only add new ones.

### Manual Addition

Follow our detailed guides in the [docs/adding-components.md](./docs/adding-components.md) file.

## ⚙️ Configuration

### DevContainers

Your DevContainer configuration is automatically generated based on selected components and works with VS Code, Cursor, and other compatible editors. It includes:

- Appropriate extensions
- Container connections
- Shared volumes
- Development server ports

### Docker Compose

The Docker Compose file is custom-built for your selected components with:

- Inter-service networking
- Volume persistence
- Environment variables
- Port mappings

### Zsh with Powerlevel10k

Every container comes with:

- Beautiful Powerlevel10k theme
- Helpful aliases for common commands
- Syntax highlighting
- Autosuggestions

## 🛠️ Advanced Usage

### Custom Components

The project setup script can be extended to support additional components. Modify `project-setup.sh` to add your own component templates and configuration logic.

### Local Development

Development is designed to happen inside DevContainers for consistency. The virtual environment is automatically created and activated inside the container. However, if you need to work outside containers:

1. **Open in DevContainer** (Recommended):
   - Your editor will prompt to reopen in container
   - Virtual environment is auto-activated
   - All dependencies are pre-installed

2. **Local development** (if needed):
   - Virtual environment must be created manually: `python3 -m venv venv`
   - Activate with: `source venv/bin/activate`

### Cleanup After Setup

Once your project is set up, the `spinbox/` directory serves no purpose:

```bash
rm -rf spinbox/
```

All your development environment files are now at the root level and will continue working normally.

## 🔍 Troubleshooting

See [docs/troubleshooting.md](./docs/troubleshooting.md) for solutions to common issues.

## 📚 Documentation

- [Adding Components](./docs/adding-components.md)
- [Chroma Vector Database Usage](./docs/chroma-usage.md)
- [Troubleshooting](./docs/troubleshooting.md)
- [Performance Optimization](./docs/performance.md)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
