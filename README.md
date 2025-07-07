# Modular Development Environment with DevContainers

A comprehensive **scaffolding** toolkit for setting up customizable development environments in both new and existing codebases on **macOS**. Uses Docker, DevContainers (compatible with VS Code, Cursor, and other editors), and Zsh with Powerlevel10k. Build your perfect stack by selecting any combination of:

- FastAPI backend (Python 3.12+)
- Next.js frontend (TypeScript)
- PostgreSQL database with PGVector
- MongoDB document database
- Redis for caching and queues

**Key Feature**: This scaffolding directory is temporary - after setup, you can delete `project-template/` and your development environment will continue working perfectly!

## 🚀 Features

- **Works with Existing Codebases**: No need to start from scratch
- **Temporary Scaffolding**: Delete the setup directory after use
- **Modular Components**: Choose only what you need
- **Modern Tech Stack**: Python 3.12+, UV package manager, Next.js
- **Enhanced Developer Experience**:
  - DevContainers for consistency across VS Code, Cursor, and other editors
  - Zsh with Powerlevel10k for a beautiful, functional terminal
  - Preconfigured aliases and shortcuts
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
git clone https://github.com/Gonzillaaa/project-template.git
cd project-template

# Run the macOS setup script
chmod +x macos-setup.sh
./macos-setup.sh
```

This installs all required tools via Homebrew and configures Zsh with Powerlevel10k on macOS.

### 2. Set Up Your Project

#### For Existing Codebases:
```bash
cd your-existing-repo/
git clone https://github.com/Gonzillaaa/project-template.git project-template/
./project-template/project-setup.sh
# Select components you want to add
# After setup completes:
rm -rf project-template/  # Safe to delete!
```

#### For New Projects:
```bash
mkdir new-project && cd new-project/
git clone https://github.com/Gonzillaaa/project-template.git project-template/
./project-template/project-setup.sh
# Select components
rm -rf project-template/  # Safe to delete!
```

### 3. Start Your Development Environment

```bash
# If project-template still exists:
./project-template/start.sh

# OR if you deleted project-template:
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
project-template/
├── macos-setup.sh         # Environment setup for macOS
├── project-setup.sh       # Project creation and configuration
├── start.sh               # Project startup script
├── vscode-setup.sh        # VS Code setup script
├── lib/                   # Utility libraries
├── tests/                 # Test framework
├── docs/                  # Documentation
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
├── .devcontainer/         # VS Code DevContainer config
├── docker-compose.yml     # Docker services
├── venv/                  # Python virtual environment
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

## 🔄 Adding Components Later

Already set up a project but need to add more components? No problem!

### Re-run Setup

```bash
# In your existing project:
git clone https://github.com/Gonzillaaa/project-template.git project-template/
./project-template/project-setup.sh
# Select additional components you want to add
rm -rf project-template/
```

The setup script will detect existing components and only add new ones.

### Manual Addition

Follow our detailed guides in the [docs/adding-components.md](./docs/adding-components.md) file.

## ⚙️ Configuration

### DevContainers

Your VS Code DevContainer configuration is automatically generated based on selected components. It includes:

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

Add your own components by creating templates in the `templates/` directory and updating the project setup script.

### Local Development

For backend development outside containers, activate the virtual environment:

```bash
source venv/bin/activate
pip install -r requirements.txt
cd backend
uvicorn app.main:app --reload
```

### Cleanup After Setup

Once your project is set up, the `project-template/` directory serves no purpose:

```bash
rm -rf project-template/
```

All your development environment files are now at the root level and will continue working normally.

## 🔍 Troubleshooting

See [docs/troubleshooting.md](./docs/troubleshooting.md) for solutions to common issues.

## 📚 Documentation

- [Adding Components](./docs/adding-components.md)
- [Testing Documentation](./docs/testing.md)
- [Troubleshooting](./docs/troubleshooting.md)
- [Performance Optimization](./docs/performance.md)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
