[logo]: https://github.com/Gonzillaaa/spinbox/blob/main/docs/spinbox-logo-cropped.png "Spinbox"

![Spinbox][logo]

# Spin up containerized prototyping environments in seconds! 

A **global CLI tool** for spinning up customizable prototyping environments with predefined profiles or custom component selection. Uses Docker, DevContainers (compatible with VS Code, Cursor, and other editors), and comes with a modern prototyping setup. Build your stack by selecting any combination of:

- FastAPI backend (Python 3.12+)
- Next.js frontend (TypeScript)
- PostgreSQL database with PGVector
- MongoDB document database
- Redis for caching and queues
- Chroma vector database for embeddings

## 🚀 Features

### **Global CLI Tool**
- **Simple Commands**: `spinbox create myproject --profile web-app`
- **Predefined Profiles**: 5 curated profiles for common development scenarios
- **Custom Components**: Mix and match components as needed
- **Project Management**: Add components, start services, check status

### **Prototyping Environment**
- **DevContainer-First**: Every project includes a DevContainer as the baseline
- **Requirements.txt Templates**: Quick-start templates for different prototyping needs
- **Modern Tech Stack**: Python 3.12+, UV package manager, Node.js 20+, TypeScript
- **Enhanced Developer Experience**:
  - DevContainers for consistency across VS Code, Cursor, and other editors
  - Zsh with Powerlevel10k for a beautiful, functional terminal
  - Pre-configured prototyping tools and shortcuts

### **Component System**
- **Modular Design**: Start minimal, add what you need
- **Service Management**: Built-in Docker Compose orchestration
- **Version Control**: Customize software versions globally or per-project
- **Easy Installation**: Homebrew integration for macOS
- **Root-Level Deployment**: All project files created at repository root

## 🛡️ Security Features

- **Environment Isolation**: Each project runs in its own Docker container
- **Virtual Environment Setup**: Automatic Python venv creation with `setup_venv.sh`
- **Secret Management**: Comprehensive .env templates with security guidelines
- **Version Control**: Automatic .gitignore generation (prevents .env commits)
- **Configuration Management**: Environment-specific config files
- **Clean Separation**: Development tools separate from production
- **Security Best Practices**: Built-in reminders and secure defaults

## 📋 Prerequisites

- Docker Desktop
- DevContainer-compatible editor (VS Code, Cursor, etc.)
- Git

## 🏁 Quick Start

### 1. Install Spinbox (One-time)

**User install (recommended):**
```bash
curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install-user.sh | bash
```

**System install (if you prefer):**
```bash
sudo bash <(curl -sSL https://raw.githubusercontent.com/Gonzillaaa/spinbox/main/install.sh)
```

Both methods work - choose what you prefer!

### 2. Create Projects with Predefined Profiles

```bash
# Use predefined profiles for common scenarios
spinbox create myapp --profile web-app        # Full-stack web application
spinbox create api-server --profile api-only  # FastAPI API with PostgreSQL
spinbox create ml-project --profile data-science  # Data science environment
spinbox create ai-project --profile ai-llm    # AI/LLM development

# List available profiles
spinbox profiles

# Show profile details
spinbox profiles web-app
```

### 3. Custom Component Selection

```bash
# Build custom projects by selecting components
spinbox create myproject --python             # Simple Python project
spinbox create webapp --python --node --postgresql  # Custom full-stack
spinbox create api --fastapi --redis          # API layer with caching

# Customize versions
spinbox create api --fastapi --redis --python-version 3.11
```

### 4. Project Management

```bash
# Add components to existing projects
cd myproject
spinbox add --postgresql --redis

# Start project services
spinbox start                    # Start all services in background
spinbox start --logs             # Start and show logs

# Check project status
spinbox status                   # Show project and configuration info

# Update Spinbox
spinbox update                   # Update to latest version
spinbox update --check           # Check for updates

# Manage global configuration
spinbox config --list           # Show current configuration
spinbox config --set PYTHON_VERSION=3.11

# Uninstall Spinbox
spinbox uninstall --config       # Remove Spinbox and configuration
```

## 📦 Available Components

Components are organized by their **architectural role**:

| Component | Flag | Architectural Role | Description |
|-----------|------|-------------------|-------------|
| **Prototyping Environment** |
| Python | `--python` | DevContainer | Python DevContainer with virtual environment |
| Node.js | `--node` | DevContainer | Node.js DevContainer with TypeScript |
| **Application Layer** |
| FastAPI | `--fastapi` | API Layer | FastAPI backend (includes Python) |
| Next.js | `--nextjs` | UI Layer | Next.js frontend (includes Node.js) |
| **Storage Layer** |
| PostgreSQL | `--postgresql` | Primary Storage | PostgreSQL with PGVector extension |
| MongoDB | `--mongodb` | Alternative Storage | MongoDB document database |
| Redis | `--redis` | Caching Layer | Redis for caching and queues |
| Chroma | `--chroma` | Vector Search | Chroma vector database for AI/ML |

**Examples of combining components:**
- `--postgresql --redis` - Primary storage + caching
- `--mongodb --chroma` - Document storage + vector search
- `--fastapi --nextjs --postgresql` - Full-stack application

## 🎯 Predefined Profiles

| Profile | Description | Components |
|---------|-------------|------------|
| `web-app` | Full-stack web application | fastapi, nextjs, postgresql |
| `api-only` | FastAPI API with caching | fastapi, postgresql, redis |
| `data-science` | ML/data science environment | python, postgresql |
| `ai-llm` | AI/LLM prototyping | python, postgresql, chroma |
| `minimal` | Basic prototyping environment | python |

## 🛠️ Development Workflow

### 1. Open in Editor
```bash
cd myproject
code .     # VS Code
cursor .   # Cursor
# When prompted, click "Reopen in Container"
```

### 2. Start Services (if needed)
```bash
# Start all services in background
spinbox start

# Or use docker-compose directly
docker-compose up -d
```

Your editor will detect the DevContainer configuration and prompt to "Reopen in Container".

### 3. Security Setup

**Python Projects:**
```bash
cd fastapi
./setup_venv.sh  # Sets up virtual environment with security best practices
```

**Environment Variables:**
- Review and update `.env` files with your actual credentials
- Never commit `.env` files to version control (already in .gitignore)
- Use strong passwords and secure API keys

---

## 🗂️ Project Structure

### After Project Creation
```
your-project/
├── fastapi/               # FastAPI backend (if selected)
├── nextjs/                # Next.js frontend (if selected)
├── postgresql/            # PostgreSQL config (if selected)
├── mongodb/               # MongoDB config (if selected)
├── redis/                 # Redis config (if selected)
├── chroma_data/           # Chroma vector database data (if selected)
├── .devcontainer/         # DevContainer config (always created)
├── docker-compose.yml     # Docker services (if components selected)
├── requirements.txt       # Python dependencies
├── package.json          # Node.js dependencies (if Next.js)
└── README.md             # Project documentation
```

## 🧩 Component Details

**Backend (FastAPI)**
- Python 3.12+ with type hints, UV package manager, SQLAlchemy ORM with async support

**Frontend (Next.js)**
- TypeScript, modern App Router, Tailwind CSS, ESLint

**Database (PostgreSQL)**
- PGVector extension for vector embeddings, initialization scripts

**MongoDB**
- Document database with authentication, collections and indexes

**Redis**
- Caching and queues with persistence enabled

**Chroma**
- Vector database for embeddings with persistent storage

## 📦 Requirements.txt Templates

When setting up a minimal Python project, choose from curated requirements.txt templates:

- **Minimal**: Basic development tools (uv, pytest, black, python-dotenv, requests)
- **Data Science**: pandas, numpy, matplotlib, jupyter, plotly, scikit-learn
- **AI/LLM**: openai, anthropic, langchain, llama-index, tiktoken, transformers
- **Web Scraping**: beautifulsoup4, selenium, scrapy, lxml
- **API Development**: fastapi, uvicorn, pydantic, httpx
- **Custom**: Minimal template you can customize

Perfect for rapid prototyping - get started immediately with the right dependencies!

## 🔄 Adding Components Later

```bash
# In your existing project directory:
spinbox add --postgresql --redis        # Add primary storage + caching layer
spinbox add --mongodb --chroma        # Add alternative storage + vector search
spinbox add --fastapi --nextjs      # Add API layer + web interface
```

See [docs/adding-components.md](./docs/adding-components.md) for detailed guides.

## ⚙️ Configuration

### Software Version Configuration

```bash
# Set default versions globally
spinbox config --set PYTHON_VERSION=3.11
spinbox config --set NODE_VERSION=18
spinbox config --set POSTGRES_VERSION=14

# View current configuration
spinbox config --list
```

**Default versions**: Python 3.12, Node.js 20, PostgreSQL 15, Redis 7

### DevContainers & Docker Compose

- **DevContainer**: Automatically configured for VS Code, Cursor, and other editors
- **Docker Compose**: Custom-built with networking, volumes, and environment variables
- **Zsh with Powerlevel10k**: Beautiful terminal with helpful aliases and syntax highlighting

## 🛠️ Advanced Usage

### Custom Components

Spinbox uses a modular generator system. You can extend it by:
- Adding new generators in the `generators/` directory
- Creating custom profiles in `templates/profiles/`
- Customizing requirements in `templates/requirements/`

### Local Development

**Recommended**: Open in DevContainer for consistency
- Virtual environment is auto-activated
- All dependencies pre-installed
- Editor extensions configured

**Alternative**: Manual setup outside container
- Create virtual environment: `python3 -m venv venv`
- Activate: `source venv/bin/activate`

## 🔍 Troubleshooting

See [docs/troubleshooting.md](./docs/troubleshooting.md) for solutions to common issues.

## 📚 Documentation

- [Quick Start Guide](./docs/quick-start.md)
- [CLI Reference](./docs/cli-reference.md)
- [Adding Components](./docs/adding-components.md)
- [Installation Guide](./docs/installation.md)
- [Troubleshooting](./docs/troubleshooting.md)

See [docs/README.md](./docs/README.md) for complete documentation index.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
