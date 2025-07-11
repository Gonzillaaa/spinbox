# Adding Components to Existing Projects

This guide explains how to add new components to an existing Spinbox project using the global CLI tool.

## Overview

Spinbox supports adding components to existing projects seamlessly through the `spinbox add` command. You can add any component that's available during project creation:

### Available Components

**Application Frameworks** (Build user interfaces):
- **FastAPI**: Backend API framework with Python 3.12+
- **Next.js**: Frontend framework with TypeScript

**Workflow Frameworks** (Specialized methodologies):
- **Data Science**: Data analysis workflow (Jupyter, pandas, scikit-learn)
- **AI/ML**: AI/ML workflow (LLMs, agents, vector processing)

**Infrastructure Services** (Data storage & core services):
- **PostgreSQL**: Database with PGVector extension
- **MongoDB**: Document database
- **Redis**: Caching and queues
- **Chroma**: Vector database for embeddings

**Foundation Environments** (Base containers):
- **Python**: Python DevContainer environment
- **Node.js**: Node.js DevContainer environment

### Enhancement Flags
- **`--with-deps`**: Automatically install component dependencies using `uv` (Python) or `npm` (Node.js)
- **`--with-examples`**: Generate working code examples for the components

## Using the CLI Command (Recommended)

The `spinbox add` command is the recommended and supported method for adding components to existing projects.

### Prerequisites

1. **Existing Spinbox project**: Must be run from within a Spinbox project directory
2. **DevContainer configuration**: Project must have `.devcontainer/devcontainer.json` file
3. **Working directory**: Run the command from your project root

### Basic Usage

```bash
# Navigate to your existing project
cd myproject

# Add a single component
spinbox add --postgresql

# Add workflow frameworks
spinbox add --data-science
spinbox add --ai-ml

# Add multiple components
spinbox add --fastapi --redis
spinbox add --postgresql --chroma

# Add components with version specifications
spinbox add --postgresql --postgres-version 14
spinbox add --nextjs --node-version 18

# Add with automatic dependency installation
spinbox add --fastapi --with-deps
spinbox add --data-science --with-deps

# Add with working code examples
spinbox add --nextjs --with-examples

# Add with both dependencies and examples
spinbox add --postgresql --with-deps --with-examples
```

### Examples by Use Case

#### Adding Storage Components

```bash
# Add primary database storage
spinbox add --postgresql

# Add caching layer
spinbox add --redis

# Add document storage alternative
spinbox add --mongodb

# Add vector search for AI/ML
spinbox add --chroma

# Add multiple storage layers
spinbox add --postgresql --redis --chroma
```

#### Adding Application Layers

```bash
# Add API backend to existing project
spinbox add --fastapi

# Add web frontend
spinbox add --nextjs

# Add full web application stack
spinbox add --fastapi --nextjs --postgresql
```

#### Adding Workflow Frameworks

```bash
# Add data science workflow
spinbox add --data-science --with-examples

# Add AI/ML workflow
spinbox add --ai-ml --with-examples

# Add AI/ML with vector search
spinbox add --ai-ml --chroma --with-deps --with-examples
```

#### Version-Specific Additions

```bash
# Add components with specific versions
spinbox add --postgresql --postgres-version 15
spinbox add --fastapi --python-version 3.11
spinbox add --nextjs --node-version 20

# Multiple components with versions
spinbox add --fastapi --redis --python-version 3.12 --redis-version 7
```

## What Happens When You Add Components

### Automatic Updates

The `spinbox add` command automatically handles:

1. **Component Detection**: Detects existing components to avoid conflicts
2. **File Generation**: Creates all necessary component files and configurations
3. **DevContainer Updates**: Updates `.devcontainer/devcontainer.json` with new extensions and settings
4. **Docker Compose Updates**: Updates `docker-compose.yml` with new services
5. **Network Configuration**: Ensures proper inter-service networking
6. **Volume Management**: Sets up persistent storage for databases
7. **Environment Variables**: Configures required environment variables

### Directory Structure Changes

Adding components creates the following structure:

```
your-project/
├── .devcontainer/         # Updated with new extensions
├── docker-compose.yml     # Updated with new services
├── backend/              # If --backend added
│   ├── app/
│   ├── requirements.txt
│   └── Dockerfile.dev
├── frontend/             # If --frontend added
│   ├── src/
│   ├── package.json
│   └── Dockerfile.dev
├── database/             # If --database added
│   ├── init-scripts/
│   └── Dockerfile
├── mongodb/              # If --mongodb added
│   └── init-scripts/
├── redis/                # If --redis added
│   └── redis.conf
└── chroma_data/          # If --chroma added (directory)
```

## Component Integration

### Architectural Relationships

Components are designed to work together seamlessly:

**Storage Components**:
- **PostgreSQL** (`--database`): Primary relational storage
- **MongoDB** (`--mongodb`): Alternative document storage
- **Redis** (`--redis`): Caching and queue layer
- **Chroma** (`--chroma`): Vector search layer

**Application Components**:
- **Backend** (`--backend`): API layer with database connections
- **Frontend** (`--frontend`): Web interface with API integration

### Inter-Service Communication

When components are added together, they're automatically configured for communication:

- **Frontend ↔ Backend**: API calls on port 8000
- **Backend ↔ Database**: PostgreSQL connection on port 5432
- **Backend ↔ Redis**: Caching connection on port 6379
- **Backend ↔ MongoDB**: Document storage connection on port 27017
- **Backend ↔ Chroma**: Embedded vector database (no separate service)

## Development Workflow

### After Adding Components

1. **Rebuild DevContainer**:
   ```bash
   # In VS Code/Cursor: Command Palette -> "Dev Containers: Rebuild Container"
   # Or restart your editor and reopen in container
   ```

2. **Start Services**:
   ```bash
   spinbox start
   # Or use docker-compose directly:
   docker-compose up -d
   ```

3. **Verify Services**:
   ```bash
   # Check service status
   spinbox status

   # Or check Docker containers
   docker-compose ps
   ```

### Development Commands

```bash
# Start all services
spinbox start

# Start with logs visible
spinbox start --logs

# Rebuild and start
spinbox start --build

# Check project status
spinbox status --project
```

## Configuration Management

### Version Control

Components use configurable versions that can be set globally or per-project:

```bash
# Set global defaults
spinbox config --set PYTHON_VERSION=3.11
spinbox config --set NODE_VERSION=18
spinbox config --set POSTGRES_VERSION=14

# Add components with current configuration
spinbox add --backend --database
```

### Environment Variables

Components automatically get proper environment variable configuration:

- **Database connections**: `DATABASE_URL`, `MONGODB_URL`
- **Cache connections**: `REDIS_URL`
- **API endpoints**: `NEXT_PUBLIC_API_URL`
- **Development settings**: Debug flags, reload settings

## Validation and Testing

### Automatic Validation

The `spinbox add` command includes validation:

- **Project detection**: Ensures you're in a Spinbox project
- **Component compatibility**: Checks for conflicting configurations
- **File permissions**: Validates write access to project directory
- **Docker availability**: Ensures Docker is running for service creation

### Manual Testing

After adding components, test the integration:

```bash
# Test service startup
spinbox start

# Check logs for errors
docker-compose logs

# Test inter-service connectivity
# Backend API: http://localhost:8000
# Frontend: http://localhost:3000
# Database: localhost:5432
```

## Troubleshooting

### Common Issues

**1. Permission Denied**
```bash
# Check directory permissions
ls -la .
# Fix ownership if needed
sudo chown -R $USER:$USER .
```

**2. Port Conflicts**
```bash
# Check what's using ports
lsof -i :8000
lsof -i :3000
lsof -i :5432
# Kill conflicting processes or change ports in docker-compose.yml
```

**3. Docker Issues**
```bash
# Ensure Docker is running
docker ps
# Restart Docker if needed
sudo systemctl restart docker  # Linux
# Or restart Docker Desktop
```

**4. DevContainer Not Updated**
```bash
# Force rebuild DevContainer
# Command Palette -> "Dev Containers: Rebuild Container"
# Or delete .devcontainer and re-add components
```

### Getting Help

If you encounter issues:

1. **Check project status**: `spinbox status --project`
2. **Review logs**: `docker-compose logs [service-name]`
3. **Validate configuration**: `spinbox config --list`
4. **Compare with fresh project**: Create a new project with the same components
5. **Consult troubleshooting guide**: [docs/troubleshooting.md](./troubleshooting.md)

## Best Practices

### 1. Incremental Addition
```bash
# Add components one at a time for easier debugging
spinbox add --database
# Test, then add next component
spinbox add --backend
```

### 2. Version Consistency
```bash
# Set versions before adding components
spinbox config --set PYTHON_VERSION=3.12
spinbox config --set NODE_VERSION=20
spinbox add --backend --frontend
```

### 3. Git Integration
```bash
# Create branch before major changes
git checkout -b add-backend-redis

# Add components
spinbox add --backend --redis

# Test thoroughly, then commit
git add -A
git commit -m "Add backend API and Redis caching"
```

### 4. Documentation
- Update project README with new components
- Document any custom configurations
- Record component choices and architectural decisions

## Advanced Usage

### Custom Component Combinations

```bash
# Multi-database setup
spinbox add --database --mongodb     # Relational + Document storage

# Performance-optimized API
spinbox add --backend --redis --database

# AI/ML prototyping environment  
spinbox add --backend --database --chroma

# Full-stack with multiple storage layers
spinbox add --backend --frontend --database --redis --chroma
```

### Configuration Overrides

```bash
# Override default versions per component
spinbox add --database --postgres-version 13 --redis --redis-version 6

# Multiple version overrides
spinbox add --backend --frontend --python-version 3.10 --node-version 18
```

---

**Next Steps**: After adding components, see the [Quick Start Guide](./quick-start.md) for prototyping workflow examples and the [CLI Reference](./cli-reference.md) for complete command documentation.