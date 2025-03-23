# Create a local script to initialize Python environment
  cat > backend/setup_local_env.sh << 'EOF'
#!/bin/bash
# Setup script for local Python environment (outside Docker)

# Set color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print colored status messages
function print_status() {
  echo -e "${GREEN}[+] $1${NC}"
}

function print_warning() {
  echo -e "${YELLOW}[!] $1${NC}"
}

function print_error() {
  echo -e "${RED}[-] $1${NC}"
}

# Check Python version
PYTHON_VERSION=$(python --version 2>&1)
print_status "Checking Python version: $PYTHON_VERSION"

# Ensure Python 3.12+
if [[ ! "$PYTHON_VERSION" =~ "Python 3.1" ]]; then
  print_error "Python 3.12+ is required. Please install it and try again."
  exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
  print_status "Creating virtual environment..."
  python -m venv venv
else
  print_status "Virtual environment already exists."
fi

# Activate virtual environment
print_status "Activating virtual environment..."
source venv/bin/activate

# Install uv if not installed
if ! command -v uv &> /dev/null; then
  print_status "Installing uv package manager..."
  pip install uv
else
  print_status "uv is already installed."
fi

# Install dependencies using uv
print_status "Installing dependencies with uv..."
uv pip install -r requirements.txt

print_status "Environment setup complete!"
print_status "Run 'source venv/bin/activate' to activate the virtual environment."
print_status "Use 'uvicorn app.main:app --reload' to start the development server."
EOF
  
  # Make the script executable
  chmod +x backend/setup_local_env.sh  # Create setup.py for backend
  cat > backend/setup.py << 'EOF'
from setuptools import setup, find_packages

setup(
    name="backend",
    version="0.1.0",
    packages=find_packages(),
    install_requires=[
        # Requirements are read from requirements.txt
    ],
    python_requires=">=3.12",
)
EOF  # Create local virtual environment and initialize files
  mkdir -p backend/venv
  touch backend/venv/.keep
  
  # Create .gitignore specific for backend
  cat > backend/.gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
ENV/
.pytest_cache/
.coverage
htmlcov/
.env
.env.local
EOF# Set component flags (default to false)
USE_BACKEND=false
USE_FRONTEND=false
USE_DATABASE=false
USE_REDIS=false

# Function to select components
function select_components() {
  print_status "Select the components you want to include:"
  
  read -p "Include FastAPI backend? (y/N): " INCLUDE_BACKEND
  if [[ $INCLUDE_BACKEND =~ ^[Yy]$ ]]; then
    USE_BACKEND=true
    print_status "FastAPI backend will be included."
  fi
  
  read -p "Include Next.js frontend? (y/N): " INCLUDE_FRONTEND
  if [[ $INCLUDE_FRONTEND =~ ^[Yy]$ ]]; then
    USE_FRONTEND=true
    print_status "Next.js frontend will be included."
  fi
  
  read -p "Include PostgreSQL database? (y/N): " INCLUDE_DATABASE
  if [[ $INCLUDE_DATABASE =~ ^[Yy]$ ]]; then
    USE_DATABASE=true
    print_status "PostgreSQL database will be included."
  fi
  
  read -p "Include Redis? (y/N): " INCLUDE_REDIS
  if [[ $INCLUDE_REDIS =~ ^[Yy]$ ]]; then
    USE_REDIS=true
    print_status "Redis will be included."
  fi
  
  # Ensure at least one component is selected
  if [[ "$USE_BACKEND" == false && "$USE_FRONTEND" == false && "$USE_DATABASE" == false && "$USE_REDIS" == false ]]; then
    print_error "You must select at least one component."
    select_components
  fi
}#!/bin/bash
# Project structure setup script
# This script creates the project structure and configuration files for
# a full-stack application with optional FastAPI, Next.js, PostgreSQL, and Redis

# Make script exit on error
set -e

# Set color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print colored status messages
function print_status() {
  echo -e "${GREEN}[+] $1${NC}"
}

function print_warning() {
  echo -e "${YELLOW}[!] $1${NC}"
}

function print_error() {
  echo -e "${RED}[-] $1${NC}"
}

# Get project name from user
function get_project_name() {
  read -p "Enter project name (lowercase, no spaces): " PROJECT_NAME
  
  # Validate project name
  if [[ ! $PROJECT_NAME =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
    print_error "Invalid project name. Use lowercase letters, numbers, hyphens and underscores only."
    get_project_name
  fi
  
  # Check if directory already exists
  if [ -d "$PROJECT_NAME" ]; then
    print_warning "Directory $PROJECT_NAME already exists."
    read -p "Do you want to overwrite? (y/N): " OVERWRITE
    if [[ ! $OVERWRITE =~ ^[Yy]$ ]]; then
      get_project_name
    fi
  fi
}

# Create project directory structure
function create_project_structure() {
  print_status "Creating project directory structure..."
  
  mkdir -p "$PROJECT_NAME"
  cd "$PROJECT_NAME"
  
  # Create main directories
  mkdir -p .devcontainer
  
  if [ "$USE_BACKEND" = true ]; then
    mkdir -p backend/app/{api,core,models}
  fi
  
  if [ "$USE_FRONTEND" = true ]; then
    mkdir -p frontend/src/{app,components}
  fi
  
  if [ "$USE_DATABASE" = true ]; then
    mkdir -p database/init-scripts
  fi
  
  if [ "$USE_REDIS" = true ]; then
    mkdir -p redis
  fi
  
  print_status "Project structure created."
}

# Create DevContainer configuration
function create_devcontainer_config() {
  print_status "Creating DevContainer configuration..."
  
  # Start with the basic structure
  cat > .devcontainer/devcontainer.json << 'EOF'
{
  "name": "Development Environment",
EOF

  # Determine which service to use as the primary container
  if [ "$USE_BACKEND" = true ]; then
    cat >> .devcontainer/devcontainer.json << 'EOF'
  "dockerComposeFile": "../docker-compose.yml",
  "service": "backend",
  "workspaceFolder": "/workspace",
EOF
  elif [ "$USE_FRONTEND" = true ]; then
    cat >> .devcontainer/devcontainer.json << 'EOF'
  "dockerComposeFile": "../docker-compose.yml",
  "service": "frontend",
  "workspaceFolder": "/app",
EOF
  else
    # If no backend or frontend, use a default simple configuration
    cat >> .devcontainer/devcontainer.json << 'EOF'
  "dockerComposeFile": "../docker-compose.yml",
  "service": "database",
  "workspaceFolder": "/workspace",
EOF
  fi
  
  # Add VS Code customizations
  cat >> .devcontainer/devcontainer.json << 'EOF'
  "customizations": {
    "vscode": {
      "extensions": [
EOF
  
  # Add Python extensions if backend is selected
  if [ "$USE_BACKEND" = true ]; then
    cat >> .devcontainer/devcontainer.json << 'EOF'
        "ms-python.python",
        "ms-python.vscode-pylance",
EOF
  fi
  
  # Add JavaScript/TypeScript extensions if frontend is selected
  if [ "$USE_FRONTEND" = true ]; then
    cat >> .devcontainer/devcontainer.json << 'EOF'
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
EOF
  fi
  
  # Add database extensions if database is selected
  if [ "$USE_DATABASE" = true ]; then
    cat >> .devcontainer/devcontainer.json << 'EOF'
        "mtxr.sqltools",
        "mtxr.sqltools-driver-pg",
EOF
  fi
  
  # Add Docker extension for all configs
  cat >> .devcontainer/devcontainer.json << 'EOF'
        "ms-azuretools.vscode-docker"
      ],
      "settings": {
EOF

  # Add Python settings if backend is selected
  if [ "$USE_BACKEND" = true ]; then
    cat >> .devcontainer/devcontainer.json << 'EOF'
        "python.defaultInterpreterPath": "/usr/local/bin/python",
        "python.linting.enabled": true,
        "python.linting.pylintEnabled": true,
EOF
  fi
  
  # Add ESLint settings if frontend is selected
  if [ "$USE_FRONTEND" = true ]; then
    cat >> .devcontainer/devcontainer.json << 'EOF'
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
          "source.fixAll.eslint": true
        },
EOF
  fi
  
  # Add terminal settings for all configs
  cat >> .devcontainer/devcontainer.json << 'EOF'
        "terminal.integrated.defaultProfile.linux": "zsh",
        "terminal.integrated.fontFamily": "MesloLGS NF",
        "terminal.integrated.profiles.linux": {
          "zsh": {
            "path": "zsh"
          }
        }
      }
    }
  },
EOF

  # Add port forwarding based on selected components
  cat >> .devcontainer/devcontainer.json << 'EOF'
  "forwardPorts": [
EOF

  if [ "$USE_FRONTEND" = true ]; then
    cat >> .devcontainer/devcontainer.json << 'EOF'
    3000,
EOF
  fi
  
  if [ "$USE_BACKEND" = true ]; then
    cat >> .devcontainer/devcontainer.json << 'EOF'
    8000,
EOF
  fi
  
  if [ "$USE_DATABASE" = true ]; then
    cat >> .devcontainer/devcontainer.json << 'EOF'
    5432,
EOF
  fi
  
  if [ "$USE_REDIS" = true ]; then
    cat >> .devcontainer/devcontainer.json << 'EOF'
    6379,
EOF
  fi
  
  # Remove the trailing comma from the last port
  sed -i '' '$ s/,$//' .devcontainer/devcontainer.json
  
  # Close the forwardPorts array
  cat >> .devcontainer/devcontainer.json << 'EOF'
  ],
  "remoteUser": "root",
EOF

  # Add post-create command based on selected components
  if [ "$USE_BACKEND" = true ] || [ "$USE_FRONTEND" = true ]; then
    cat >> .devcontainer/devcontainer.json << 'EOF'
  "postCreateCommand": "
EOF
    
    if [ "$USE_BACKEND" = true ]; then
      cat >> .devcontainer/devcontainer.json << 'EOF'
    cd /workspace/backend && pip install -r requirements.txt
EOF
    fi
    
    if [ "$USE_BACKEND" = true ] && [ "$USE_FRONTEND" = true ]; then
      cat >> .devcontainer/devcontainer.json << 'EOF'
 && 
EOF
    fi
    
    if [ "$USE_FRONTEND" = true ]; then
      cat >> .devcontainer/devcontainer.json << 'EOF'
    cd /workspace/frontend && npm install
EOF
    fi
    
    cat >> .devcontainer/devcontainer.json << 'EOF'
  "
EOF
  fi
  
  # Close the JSON object
  cat >> .devcontainer/devcontainer.json << 'EOF'
}
EOF

  print_status "DevContainer configuration created."
}

# Create Docker Compose file
function create_docker_compose() {
  print_status "Creating Docker Compose configuration..."
  
  # Start with version and networks
  cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
EOF

  # Add backend service if selected
  if [ "$USE_BACKEND" = true ]; then
    cat >> docker-compose.yml << 'EOF'
  # Development workspace container
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.dev
    volumes:
      - .:/workspace:cached
      - ./backend/.p10k.zsh:/root/.p10k.zsh
    environment:
EOF
    
    # Add database environment variables if database is selected
    if [ "$USE_DATABASE" = true ]; then
      cat >> docker-compose.yml << 'EOF'
      - DATABASE_URL=postgresql://postgres:postgres@database:5432/app_db
EOF
    fi
    
    # Add Redis environment variables if Redis is selected
    if [ "$USE_REDIS" = true ]; then
      cat >> docker-compose.yml << 'EOF'
      - REDIS_URL=redis://redis:6379/0
EOF
    fi
    
    cat >> docker-compose.yml << 'EOF'
    ports:
      - "8000:8000"
EOF
    
    # Add dependencies if selected
    if [ "$USE_DATABASE" = true ] || [ "$USE_REDIS" = true ]; then
      cat >> docker-compose.yml << 'EOF'
    depends_on:
EOF
      
      if [ "$USE_DATABASE" = true ]; then
        cat >> docker-compose.yml << 'EOF'
      - database
EOF
      fi
      
      if [ "$USE_REDIS" = true ]; then
        cat >> docker-compose.yml << 'EOF'
      - redis
EOF
      fi
    fi
    
    cat >> docker-compose.yml << 'EOF'
    networks:
      - app-network

EOF
  fi
  
  # Add frontend service if selected
  if [ "$USE_FRONTEND" = true ]; then
    cat >> docker-compose.yml << 'EOF'
  # Frontend service for development
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.dev
    volumes:
      - ./frontend:/app:cached
      - frontend-node-modules:/app/node_modules
      - ./frontend/.p10k.zsh:/root/.p10k.zsh
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8000
EOF
    
    # Add backend dependency if both backend and frontend are selected
    if [ "$USE_BACKEND" = true ]; then
      cat >> docker-compose.yml << 'EOF'
    depends_on:
      - backend
EOF
    fi
    
    cat >> docker-compose.yml << 'EOF'
    networks:
      - app-network

EOF
  fi
  
  # Add database service if selected
  if [ "$USE_DATABASE" = true ]; then
    cat >> docker-compose.yml << 'EOF'
  # PostgreSQL Database with PGVector
  database:
    build:
      context: ./database
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=app_db
    ports:
      - "5432:5432"
    networks:
      - app-network

EOF
  fi
  
  # Add Redis service if selected
  if [ "$USE_REDIS" = true ]; then
    cat >> docker-compose.yml << 'EOF'
  # Redis for queues
  redis:
    image: redis:7-alpine
    volumes:
      - ./redis/redis.conf:/usr/local/etc/redis/redis.conf
      - redis-data:/data
    ports:
      - "6379:6379"
    command: redis-server /usr/local/etc/redis/redis.conf
    networks:
      - app-network

EOF
  fi
  
  # Add networks and volumes
  cat >> docker-compose.yml << 'EOF'
networks:
  app-network:
    driver: bridge

volumes:
EOF
  
  # Add volumes based on selected components
  if [ "$USE_DATABASE" = true ]; then
    cat >> docker-compose.yml << 'EOF'
  postgres-data:
EOF
  fi
  
  if [ "$USE_REDIS" = true ]; then
    cat >> docker-compose.yml << 'EOF'
  redis-data:
EOF
  fi
  
  if [ "$USE_FRONTEND" = true ]; then
    cat >> docker-compose.yml << 'EOF'
  frontend-node-modules:
EOF
  fi
  
  print_status "Docker Compose configuration created."
}

# Create backend files
function create_backend_files() {
  print_status "Creating backend files..."
  
  # Create Dockerfile.dev
  cat > backend/Dockerfile.dev << 'EOF'
FROM python:3.12-slim

WORKDIR /workspace/backend

# Install development tools and dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    zsh \
    fonts-powerline \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Powerlevel10k
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Install Zsh plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Set Zsh theme and plugins
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc && \
    sed -i 's/plugins=(git)/plugins=(git docker docker-compose python pip)/g' ~/.zshrc

# Install pyenv
RUN curl https://pyenv.run | bash
ENV PATH="/root/.pyenv/bin:$PATH"
RUN echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc && \
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc && \
    echo 'eval "$(pyenv init --path)"' >> ~/.zshrc && \
    echo 'eval "$(pyenv init -)"' >> ~/.zshrc

# Add Powerlevel10k configuration
RUN echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> ~/.zshrc
RUN echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc

# Set up Python
RUN pyenv install 3.12.0 && \
    pyenv global 3.12.0

# Install UV for dependency management
RUN pip install uv

# Create virtual environment with UV
RUN python -m venv venv
ENV PATH="/workspace/backend/venv/bin:$PATH"

# Install Python packages using UV
COPY requirements.txt .
RUN uv pip install -r requirements.txt

# Add useful aliases
RUN echo '# Aliases' >> ~/.zshrc && \
    echo 'alias rs="uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"' >> ~/.zshrc && \
    echo 'alias test="pytest"' >> ~/.zshrc && \
    echo 'alias py="python"' >> ~/.zshrc && \
    echo 'alias pyvenv="source venv/bin/activate"' >> ~/.zshrc && \
    echo 'alias uvinstall="uv pip install -r requirements.txt"' >> ~/.zshrc

EXPOSE 8000

# Set Zsh as default shell
SHELL ["/bin/zsh", "-c"]

# Setup virtual environment activation on container startup
RUN echo 'source /workspace/backend/venv/bin/activate' >> ~/.zshrc

# Keep container running during development
CMD ["zsh", "-c", "while sleep 1000; do :; done"]
EOF

  # Create production Dockerfile
  cat > backend/Dockerfile << 'EOF'
FROM python:3.12-slim

WORKDIR /app

# Install UV for dependency management
RUN pip install uv

# Create virtual environment
RUN python -m venv venv
ENV PATH="/app/venv/bin:$PATH"

COPY requirements.txt .
RUN uv pip install -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

  # Create requirements.txt
  cat > backend/requirements.txt << 'EOF'
fastapi>=0.103.0
uvicorn>=0.23.0
sqlalchemy>=2.0.0
psycopg2-binary>=2.9.7
redis>=5.0.0
pydantic>=2.4.0
alembic>=1.12.0
python-dotenv>=1.0.0
pytest>=7.4.0
httpx>=0.24.1
asyncio>=3.4.3
typing-extensions>=4.7.0
EOF

  # Create .dockerignore
  cat > backend/.dockerignore << 'EOF'
venv/
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
.env
.env.local
.git
.gitignore
.pytest_cache/
.coverage
htmlcov/
EOF

  # Create basic FastAPI app
  cat > backend/app/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import sys
import os
from typing import Dict, Any

# Ensure Python version is 3.12+
assert sys.version_info >= (3, 12), "This app requires Python 3.12 or higher"

app = FastAPI(title="My FastAPI App")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # Frontend URL
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root() -> Dict[str, str]:
    """Root endpoint returning a simple greeting."""
    return {"message": "Hello World"}

@app.get("/api/healthcheck")
async def healthcheck() -> Dict[str, str]:
    """Health check endpoint for monitoring."""
    return {"status": "ok"}

@app.get("/api/info")
async def info() -> Dict[str, Any]:
    """Information about the runtime environment."""
    return {
        "python_version": f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}",
        "environment": os.environ.get("ENVIRONMENT", "development"),
        "api_version": "1.0.0"
    }

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
EOF

  # Create empty init files
  touch backend/app/__init__.py
  touch backend/app/api/__init__.py
  touch backend/app/core/__init__.py
  touch backend/app/models/__init__.py

  # Download p10k.zsh
  curl -s -o backend/.p10k.zsh https://raw.githubusercontent.com/romkatv/powerlevel10k/master/config/p10k-lean.zsh

  print_status "Backend files created."
}

# Create frontend files
function create_frontend_files() {
  print_status "Creating frontend files..."
  
  # Create Dockerfile.dev
  cat > frontend/Dockerfile.dev << 'EOF'
FROM node:20-alpine

WORKDIR /app

# Install dependencies and Zsh
RUN apk add --no-cache \
    git \
    zsh \
    curl \
    wget \
    shadow \
    util-linux

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Powerlevel10k
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Install Zsh plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Set Zsh theme and plugins
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc && \
    sed -i 's/plugins=(git)/plugins=(git docker npm node)/g' ~/.zshrc

# Add Powerlevel10k configuration
RUN echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> ~/.zshrc
RUN echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc

# Add useful aliases
RUN echo '# Aliases' >> ~/.zshrc && \
    echo 'alias dev="npm run dev"' >> ~/.zshrc && \
    echo 'alias build="npm run build"' >> ~/.zshrc && \
    echo 'alias lint="npm run lint"' >> ~/.zshrc

# Set Zsh as default shell
SHELL ["/bin/zsh", "-c"]

# Keep container running during development
CMD ["zsh", "-c", "npm run dev"]
EOF

  # Create production Dockerfile
  cat > frontend/Dockerfile << 'EOF'
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app

ENV NODE_ENV production

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000

CMD ["node", "server.js"]
EOF

  # Create .dockerignore
  cat > frontend/.dockerignore << 'EOF'
node_modules
.next
.git
.gitignore
EOF

  # Create package.json
  cat > frontend/package.json << 'EOF'
{
  "name": "frontend",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "14.0.0",
    "react": "^18",
    "react-dom": "^18"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "autoprefixer": "^10",
    "eslint": "^8",
    "eslint-config-next": "14.0.0",
    "postcss": "^8",
    "tailwindcss": "^3",
    "typescript": "^5"
  }
}
EOF

  # Download p10k.zsh
  curl -s -o frontend/.p10k.zsh https://raw.githubusercontent.com/romkatv/powerlevel10k/master/config/p10k-lean.zsh

  print_status "Frontend files created."
}

# Create database files
function create_database_files() {
  print_status "Creating database files..."
  
  # Create Dockerfile
  cat > database/Dockerfile << 'EOF'
FROM postgres:15

# Install necessary packages
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    postgresql-server-dev-15 \
    && rm -rf /var/lib/apt/lists/*

# Clone and install pgvector
RUN git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git \
    && cd pgvector \
    && make \
    && make install

# Add initialization scripts
COPY ./init-scripts/ /docker-entrypoint-initdb.d/
EOF

  # Create initialization script
  cat > database/init-scripts/01-init.sql << 'EOF'
-- Create extensions
CREATE EXTENSION IF NOT EXISTS vector;

-- Create a sample table with vector capability
CREATE TABLE IF NOT EXISTS items (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    embedding vector(384)
);

-- Create a simple users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Grant privileges
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO postgres;
EOF

  print_status "Database files created."
}

# Create Redis configuration
function create_redis_files() {
  print_status "Creating Redis configuration..."
  
  cat > redis/redis.conf << 'EOF'
bind 0.0.0.0
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize no
supervised no
pidfile /var/run/redis_6379.pid
loglevel notice
logfile ""
databases 16
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir ./
EOF

  print_status "Redis configuration created."
}

# Create Git configuration
function create_git_files() {
  print_status "Creating Git configuration..."
  
  # Create .gitignore
  cat > .gitignore << 'EOF'
# Node
node_modules/
.next/
out/
build/
.DS_Store
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg

# Docker
.env

# Database
*.sqlite3

# VS Code
.vscode/*
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
!.vscode/extensions.json
EOF

  # Initialize git repository
  git init
  git add .
  git commit -m "Initial commit"
  
  print_status "Git repository initialized with .gitignore."
}

# Create a sample API status component for frontend
function create_sample_component() {
  print_status "Creating sample API status component..."
  
  mkdir -p frontend/src/components
  
  cat > frontend/src/components/ApiStatus.tsx << 'EOF'
"use client";

import { useState, useEffect } from 'react';

export default function ApiStatus() {
  const [status, setStatus] = useState<string>('Loading...');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const checkApiStatus = async () => {
      try {
        const response = await fetch('http://localhost:8000/api/healthcheck');
        
        if (!response.ok) {
          throw new Error(`API returned status code ${response.status}`);
        }
        
        const data = await response.json();
        setStatus(`API Status: ${data.status}`);
        setError(null);
      } catch (err) {
        setStatus('Error connecting to API');
        setError(err instanceof Error ? err.message : 'Unknown error');
      }
    };

    checkApiStatus();
  }, []);

  return (
    <div className="p-4 border rounded-md bg-white shadow-sm">
      <h2 className="text-xl font-bold mb-2">Backend Connection</h2>
      <p className={error ? "text-red-500" : "text-green-500"}>{status}</p>
      {error && <p className="text-sm text-red-400 mt-1">{error}</p>}
    </div>
  );
}
EOF

  print_status "Sample component created."
}

# Create README.md with usage instructions
function create_readme() {
  print_status "Creating README.md with usage instructions..."
  
  cat > README.md << 'EOF'
# Development Environment Setup

This project uses VS Code DevContainers for development. It includes:

- Python (FastAPI) backend with pyenv
- Next.js frontend with TypeScript
- PostgreSQL database with PGVector extension
- Redis for queues
- Zsh with Powerlevel10k theme

## Getting Started

### Prerequisites

- Docker Desktop
- Visual Studio Code
- VS Code Remote - Containers extension

### Opening the Project

1. Clone this repository
2. Open the project folder in VS Code
3. When prompted, click "Reopen in Container"
   - Alternatively, press F1 and select "Remote-Containers: Open Folder in Container..."

This will start all the containers and configure the development environment.

### Development Workflow

#### Backend (FastAPI)

- Open a terminal in VS Code
- Run `rs` to start the FastAPI server (alias for `uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload`)
- Access the API at http://localhost:8000
- API documentation is available at http://localhost:8000/docs

#### Frontend (Next.js)

- Open another terminal in VS Code
- Run `dev` to start the Next.js dev server (alias for `npm run dev`)
- Access the frontend at http://localhost:3000

#### Database (PostgreSQL with PGVector)

- Connect to the database using:
  - Host: localhost
  - Port: 5432
  - Username: postgres
  - Password: postgres
  - Database: app_db

#### Redis

- Connect to Redis on localhost:6379

## Project Structure

```
.
├── .devcontainer/       # DevContainer configuration
├── backend/             # FastAPI backend
│   ├── app/             # Application code
│   │   ├── api/         # API endpoints
│   │   ├── core/        # Core functionality
│   │   └── models/      # Database models
│   ├── Dockerfile       # Production Dockerfile
│   ├── Dockerfile.dev   # Development Dockerfile
│   └── requirements.txt # Python dependencies
├── frontend/            # Next.js frontend
│   ├── src/             # Source code
│   │   ├── app/         # Next.js App Router
│   │   └── components/  # React components
│   ├── Dockerfile       # Production Dockerfile
│   └── Dockerfile.dev   # Development Dockerfile
├── database/            # PostgreSQL configuration
│   ├── init-scripts/    # Database initialization scripts
│   └── Dockerfile       # Database Dockerfile with PGVector
├── redis/               # Redis configuration
│   └── redis.conf       # Redis configuration file
└── docker-compose.yml   # Docker Compose configuration
```

## Troubleshooting

### Docker Issues

If you encounter issues with Docker:
1. Check Docker Desktop is running
2. Try restarting Docker Desktop
3. Ensure you have allocated enough resources to Docker Desktop (Memory, CPU)

### Container Issues

If containers fail to start:
1. Check logs with `docker-compose logs`
2. Try rebuilding with `docker-compose build --no-cache`
3. Restart with `docker-compose down && docker-compose up -d`

### VS Code Issues

If VS Code has issues with the DevContainer:
1. Run the "Remote-Containers: Rebuild Container" command
2. Check that you have the latest Remote - Containers extension
EOF
