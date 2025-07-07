# Modular Development Environment with DevContainers

A comprehensive toolkit for creating customizable, isolated development environments using Docker, VS Code DevContainers, and Zsh with Powerlevel10k. Build your perfect stack by selecting any combination of:

- FastAPI backend (Python 3.12+)
- Next.js frontend (TypeScript)
- PostgreSQL database with PGVector
- Redis for caching and queues

## 🚀 Features

- **Modular Components**: Choose only what you need
- **Modern Tech Stack**: Python 3.12+, UV package manager, Next.js
- **Enhanced Developer Experience**:
  - VS Code DevContainers for consistency
  - Zsh with Powerlevel10k for a beautiful, functional terminal
  - Preconfigured aliases and shortcuts
- **macOS Optimized**: Built with performance considerations for macOS
- **Fully Automated**: Single-command setup and initialization
- **Expandable**: Add components to existing projects anytime

## 📋 Prerequisites

- macOS (recommended, though scripts can be adapted for Linux/Windows)
- Docker Desktop
- Visual Studio Code
- Git

## 🏁 Quick Start

### 1. Set Up Your Environment

```bash
# Clone this repository
git clone https://github.com/Gonzillaaa/project-template.git
cd project-template

# Run the macOS setup script
chmod +x macos-setup.sh
./macos-setup.sh
```

This installs all required tools, configures Zsh with Powerlevel10k, and prepares VS Code.

### 2. Create a New Project

```bash
chmod +x project-setup.sh
./project-setup.sh
```

Follow the prompts to:

- Name your project
- Select which components to include
- Configure project-specific settings

### 3. Start Your Development Environment

```bash
./start.sh
```

VS Code will open with your DevContainer environment ready to use.

## 🗂️ Repository Structure

```
project-template/
├── macos-setup.sh         # Environment setup for macOS
├── project-setup.sh       # Project creation and configuration
├── start.sh               # Project startup script
├── project-setup-old.sh   # Legacy project setup script
├── README.md              # This file
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

### Redis

- Configured for caching and queues
- Persistence enabled
- Optimized configuration

## 🔄 Adding Components Later

Already created a project but need to add more components? No problem! You have two options:

### Option 1: Using the Scripts

Create a temporary project with only the component you want to add, then copy the relevant files.

```bash
./project-setup.sh
# Select only the component you want to add
# Then copy the files to your existing project
```

### Option 2: Manual Addition

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

For backend development outside containers, use the provided `setup_local_env.sh` script in your project:

```bash
cd your-project/backend
./setup_local_env.sh
```

## 🔍 Troubleshooting

See [docs/troubleshooting.md](./docs/troubleshooting.md) for solutions to common issues.

## 📚 Documentation

- [Adding Components](./docs/adding-components.md)
- [Troubleshooting](./docs/troubleshooting.md)
- [Performance Optimization](./docs/performance.md)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
