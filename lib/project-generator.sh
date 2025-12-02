#!/bin/bash
# Project generator for Spinbox
# Handles project creation, directory setup, and component orchestration

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/version-config.sh"

# Project generation variables
PROJECT_PATH=""
SELECTED_COMPONENTS=()
TEMPLATE_NAME=""

# Component flags
USE_PYTHON=false
USE_NODE=false
USE_FASTAPI=false
USE_NEXTJS=false
USE_POSTGRESQL=false
USE_MONGODB=false
USE_REDIS=false
USE_CHROMA=false

# Parse component flags from arguments
function parse_component_flags() {
    local args=("$@")
    
    for arg in "${args[@]}"; do
        case "$arg" in
            --python)
                USE_PYTHON=true
                SELECTED_COMPONENTS+=("python")
                ;;
            --node)
                USE_NODE=true
                SELECTED_COMPONENTS+=("node")
                ;;
            --fastapi)
                USE_FASTAPI=true
                USE_PYTHON=true  # FastAPI requires Python
                SELECTED_COMPONENTS+=("fastapi")
                ;;
            --nextjs)
                USE_NEXTJS=true
                USE_NODE=true  # Next.js requires Node.js
                SELECTED_COMPONENTS+=("nextjs")
                ;;
            --postgresql)
                USE_POSTGRESQL=true
                SELECTED_COMPONENTS+=("postgresql")
                ;;
            --mongodb)
                USE_MONGODB=true
                SELECTED_COMPONENTS+=("mongodb")
                ;;
            --redis)
                USE_REDIS=true
                SELECTED_COMPONENTS+=("redis")
                ;;
            --chroma)
                USE_CHROMA=true
                SELECTED_COMPONENTS+=("chroma")
                ;;
        esac
    done
    
    # If no components specified, default to Python DevContainer
    if [[ ${#SELECTED_COMPONENTS[@]} -eq 0 ]]; then
        USE_PYTHON=true
        SELECTED_COMPONENTS+=("python")
        print_info "No components specified, defaulting to Python DevContainer"
    fi
    
    print_debug "Selected components: ${SELECTED_COMPONENTS[*]}"
}

# Validate project directory
function validate_project_directory() {
    local project_dir="$1"
    
    if [[ -d "$project_dir" ]]; then
        if [[ "$FORCE" == true ]]; then
            # Safety check: validate path before any destructive operations
            if ! validate_path_safety "$project_dir" "force removal"; then
                print_error "Cannot force remove directory for safety reasons"
                print_info "Choose a different project name or location"
                exit 1
            fi
            
            print_warning "Directory $project_dir already exists - force mode enabled, will overwrite"
            if [[ "$DRY_RUN" != true ]]; then
                rm -rf "$project_dir"
                print_info "Removed existing directory $project_dir"
            else
                print_info "DRY RUN: Would remove existing directory $project_dir"
            fi
        else
            print_error "Project directory already exists: $project_dir"
            print_info "Options:"
            print_info "  • Use --force flag to overwrite: spinbox create $(basename "$project_dir") --force [options]"
            print_info "  • Choose a different name: spinbox create my-new-project [options]"
            print_info "  • Use a different location: spinbox create ~/projects/$(basename "$project_dir") [options]"
            exit 1
        fi
    fi
    
    # Check if parent directory is writable
    local parent_dir=$(dirname "$project_dir")
    if [[ ! -w "$parent_dir" ]]; then
        print_error "Permission denied: Cannot create project in $parent_dir"
        print_info "The directory is not writable by your user"
        print_info "Solutions:"
        print_info "  • Choose a location in your home directory: spinbox create ~/projects/$(basename "$project_dir") [options]"
        print_info "  • Use your current directory: spinbox create $(basename "$project_dir") [options]"
        print_info "  • Check directory permissions: ls -la $(dirname "$parent_dir")"
        exit 1
    fi

    # Check if sufficient disk space is available (10MB minimum)
    if ! check_disk_space "$project_dir" 10240; then
        exit 1
    fi

    return 0
}

# Create project directory structure
function create_project_directory() {
    local project_dir="$1"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would create project directory $project_dir"
        return 0
    fi
    
    # Create main project directory
    safe_create_dir "$project_dir"
    
    # Create essential subdirectories
    safe_create_dir "$project_dir/.config"
    safe_create_dir "$project_dir/.devcontainer"
    
    # Create component-specific directories
    if [[ "$USE_FASTAPI" == true ]]; then
        safe_create_dir "$project_dir/backend"
    fi

    if [[ "$USE_NEXTJS" == true ]]; then
        # Only create frontend subdirectory for multi-component projects
        # Check if there's a backend component (FastAPI or minimal Python)
        local has_backend=false
        [[ "$USE_FASTAPI" == true ]] && has_backend=true
        [[ "$USE_PYTHON" == true && "$USE_FASTAPI" == false ]] && has_backend=true
        if [[ "$has_backend" == true ]]; then
            safe_create_dir "$project_dir/frontend"
        fi
    fi

    if [[ "$USE_POSTGRESQL" == true ]]; then
        safe_create_dir "$project_dir/database"
    fi

    if [[ "$USE_MONGODB" == true ]]; then
        safe_create_dir "$project_dir/mongodb"
    fi

    if [[ "$USE_REDIS" == true ]]; then
        safe_create_dir "$project_dir/redis"
    fi

    if [[ "$USE_CHROMA" == true ]]; then
        safe_create_dir "$project_dir/chroma"
    fi
    
    print_status "Created project directory structure"
}

# Generate project-specific DevContainer based on components
function generate_project_devcontainer() {
    local project_dir="$1"
    
    # Count active components
    local component_count=0
    [[ "$USE_PYTHON" == true ]] && ((component_count++))
    [[ "$USE_FASTAPI" == true ]] && ((component_count++))
    [[ "$USE_NEXTJS" == true ]] && ((component_count++))
    [[ "$USE_NODE" == true ]] && ((component_count++))
    [[ "$USE_MONGODB" == true ]] && ((component_count++))
    [[ "$USE_REDIS" == true ]] && ((component_count++))
    [[ "$USE_CHROMA" == true ]] && ((component_count++))
    
    # Use component-specific DevContainer generators for single-component projects
    if [[ $component_count -eq 1 ]]; then
        if [[ "$USE_PYTHON" == true ]]; then
            if source "$PROJECT_ROOT/generators/minimal-python.sh" 2>/dev/null; then
                generate_minimal_python_devcontainer "$project_dir"
                return 0
            fi
        elif [[ "$USE_NODE" == true ]]; then
            if source "$PROJECT_ROOT/generators/minimal-node.sh" 2>/dev/null; then
                generate_minimal_node_devcontainer "$project_dir"
                return 0
            fi
        elif [[ "$USE_FASTAPI" == true ]]; then
            # FastAPI has its own DevContainer generation within the generator
            return 0
        elif [[ "$USE_NEXTJS" == true ]]; then
            # NextJS has its own DevContainer generation within the generator
            return 0
        fi
    fi
    
    # Fall back to generic multi-component DevContainer
    generate_devcontainer_config "$project_dir"
}

# Generate DevContainer configuration
function generate_devcontainer_config() {
    local project_dir="$1"
    local devcontainer_dir="$project_dir/.devcontainer"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would generate DevContainer configuration"
        return 0
    fi

    # Generate devcontainer.json
    local python_version=$(get_effective_python_version)
    local node_version=$(get_effective_node_version)

    cat > "$devcontainer_dir/devcontainer.json" << EOF
{
    "name": "$PROJECT_NAME",
    "dockerFile": "Dockerfile",
    "remoteUser": "developer",
    "containerUser": "developer",
    "forwardPorts": [$(generate_port_list)],
    "postCreateCommand": "bash .devcontainer/setup.sh",
    "customizations": {
        "vscode": {
            "settings": {
                "terminal.integrated.shell.linux": "/bin/zsh"
            },
            "extensions": [$(generate_vscode_extensions)]
        }
    },
    "mounts": [
        "source=\${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
    ],
    "workspaceFolder": "/workspace",
    "shutdownAction": "stopContainer"
}
EOF

    # Generate Dockerfile
    cat > "$devcontainer_dir/Dockerfile" << EOF
# Multi-stage DevContainer for $PROJECT_NAME
# Generated by Spinbox on $(date)

$(generate_dockerfile_content)

# Install system dependencies including sudo
RUN apt-get update && apt-get install -y \\
    zsh \\
    git \\
    curl \\
    sudo \\
    vim \\
    procps \\
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for development
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=\$USER_UID

RUN groupadd --gid \$USER_GID \$USERNAME \\
    && useradd --uid \$USER_UID --gid \$USER_GID -m \$USERNAME -s /bin/zsh \\
    && echo \$USERNAME ALL=\\(root\\) NOPASSWD:ALL > /etc/sudoers.d/\$USERNAME \\
    && chmod 0440 /etc/sudoers.d/\$USERNAME

# Install Oh My Zsh and Powerlevel10k for non-root user
USER \$USERNAME
RUN sh -c "\$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \\
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# Configure Zsh with Powerlevel10k theme and config
COPY --chown=\$USERNAME:\$USERNAME p10k.zsh /home/\$USERNAME/.p10k.zsh
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\\/powerlevel10k"/g' ~/.zshrc \\
    && echo '' >> ~/.zshrc \\
    && echo '# Powerlevel10k configuration' >> ~/.zshrc \\
    && echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc \\
    && echo '' >> ~/.zshrc \\
    && echo '# Auto-activate Python virtual environment if it exists' >> ~/.zshrc \\
    && echo 'if [[ -f /workspace/venv/bin/activate ]]; then source /workspace/venv/bin/activate; fi' >> ~/.zshrc \\
    && echo 'if [[ -f /workspace/backend/venv/bin/activate ]]; then source /workspace/backend/venv/bin/activate; fi' >> ~/.zshrc

# Set up Zsh as default shell
USER root
RUN chsh -s /bin/zsh \$USERNAME
ENV SHELL=/bin/zsh

# Create workspace directory with correct ownership
WORKDIR /workspace
RUN chown \$USERNAME:\$USERNAME /workspace

$(generate_python_venv_setup)

# Copy setup script
COPY setup.sh /setup.sh
RUN chmod +x /setup.sh

# Set default user
USER \$USERNAME
EOF
    
    # Generate setup script
    cat > "$devcontainer_dir/setup.sh" << EOF
#!/bin/bash
# DevContainer setup script
# Runs after container creation

echo "Setting up development environment..."

$(generate_setup_script_content)

echo "Development environment setup complete!"
EOF

    chmod +x "$devcontainer_dir/setup.sh"

    # Copy Powerlevel10k configuration
    local p10k_template="$PROJECT_ROOT/templates/shell/p10k.zsh"
    if [[ -f "$p10k_template" ]]; then
        cp "$p10k_template" "$devcontainer_dir/p10k.zsh"
    fi

    print_status "Generated DevContainer configuration"
}

# Generate port forwarding list for devcontainer.json
function generate_port_list() {
    local ports=()
    
    if [[ "$USE_FASTAPI" == true ]]; then
        ports+=("$BACKEND_PORT")
    fi
    
    if [[ "$USE_NEXTJS" == true ]]; then
        ports+=("$FRONTEND_PORT")
    fi
    
    if [[ "$USE_POSTGRESQL" == true ]]; then
        ports+=("$DATABASE_PORT")
    fi
    
    if [[ "$USE_REDIS" == true ]]; then
        ports+=("$REDIS_PORT")
    fi
    
    # Join ports with commas, handle empty array
    if [[ ${#ports[@]} -gt 0 ]]; then
        local IFS=','
        echo "${ports[*]}"
    else
        echo ""
    fi
}

# Generate VS Code extensions list
function generate_vscode_extensions() {
    local extensions=()
    
    # Base extensions
    extensions+=("\"ms-vscode-remote.remote-containers\"")
    
    if [[ "$USE_PYTHON" == true ]]; then
        extensions+=("\"ms-python.python\"")
        extensions+=("\"ms-python.pylint\"")
        extensions+=("\"ms-python.black-formatter\"")
    fi
    
    if [[ "$USE_NODE" == true ]] || [[ "$USE_NEXTJS" == true ]]; then
        extensions+=("\"ms-vscode.vscode-typescript-next\"")
        extensions+=("\"esbenp.prettier-vscode\"")
        extensions+=("\"bradlc.vscode-tailwindcss\"")
    fi
    
    if [[ "$USE_POSTGRESQL" == true ]]; then
        extensions+=("\"ms-ossdata.vscode-postgresql\"")
    fi
    
    # Join extensions with commas, handle empty array
    if [[ ${#extensions[@]} -gt 0 ]]; then
        local IFS=','
        echo "${extensions[*]}"
    else
        echo ""
    fi
}

# Generate Python virtual environment PATH setup (only if Python is used)
# Note: venv is created in setup.sh after workspace mount, not in Dockerfile
function generate_python_venv_setup() {
    if [[ "$USE_PYTHON" == true ]]; then
        cat << 'VENV_EOF'
# Set PATH to include venv (venv created by setup.sh after mount)
ENV PATH="/workspace/venv/bin:$PATH"
VENV_EOF
    fi
}

# Generate Dockerfile content based on components
function generate_dockerfile_content() {
    local python_image=$(get_python_image_tag)
    local node_image=$(get_node_image_tag)
    
    if [[ "$USE_PYTHON" == true ]] && [[ "$USE_NODE" == true || "$USE_NEXTJS" == true ]]; then
        # Install both Python and Node.js on Debian-based image
        local node_major_version=$(echo "$node_image" | grep -oE '[0-9]+' | head -1)
        cat << EOF
FROM $python_image

# Install Node.js from NodeSource repository
RUN apt-get update && apt-get install -y ca-certificates curl gnupg \\
    && mkdir -p /etc/apt/keyrings \\
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \\
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${node_major_version}.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \\
    && apt-get update && apt-get install -y nodejs \\
    && rm -rf /var/lib/apt/lists/*

# Install Python and Node.js development tools
RUN apt-get update && apt-get install -y \\
    build-essential \\
    && rm -rf /var/lib/apt/lists/*

# Install UV for Python package management
RUN pip install uv
EOF
    elif [[ "$USE_PYTHON" == true ]]; then
        # Python-only setup
        cat << EOF
FROM $python_image

# Install Python development tools
RUN apt-get update && apt-get install -y \\
    build-essential \\
    && rm -rf /var/lib/apt/lists/*

# Install UV for Python package management
RUN pip install uv
EOF
    elif [[ "$USE_NODE" == true ]]; then
        # Node-only setup
        cat << EOF
FROM $node_image

# Install Node.js development tools
RUN apk add --no-cache \\
    build-base \\
    python3 \\
    make \\
    g++
EOF
    else
        # Minimal setup (shouldn't happen, but fallback)
        cat << EOF
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \\
    build-essential \\
    curl \\
    && rm -rf /var/lib/apt/lists/*
EOF
    fi
}

# Generate setup script content based on components
function generate_setup_script_content() {
    cat << 'EOF'
# Set up git configuration if not already set
if [ -z "$(git config --global user.name)" ]; then
    echo "Setting up git configuration..."
    read -p "Enter your name: " git_name
    read -p "Enter your email: " git_email
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
fi

EOF
    
    # Create venv for all Python projects (runs after workspace mount)
    if [[ "$USE_PYTHON" == true ]]; then
        cat << 'EOF'
# Set up Python virtual environment
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python -m venv venv
fi

# Activate venv and install dependencies
source venv/bin/activate

# Install backend requirements if they exist (FastAPI projects)
if [ -f "backend/requirements.txt" ]; then
    echo "Installing backend Python dependencies..."
    uv pip install -r backend/requirements.txt
# Install root requirements if they exist (simple Python projects)
elif [ -f "requirements.txt" ]; then
    echo "Installing Python dependencies..."
    uv pip install -r requirements.txt
fi

EOF
    fi
    
    if [[ "$USE_NODE" == true ]] || [[ "$USE_NEXTJS" == true ]]; then
        cat << 'EOF'
# Install Node.js dependencies
if [ -f "package.json" ]; then
    echo "Installing Node.js dependencies..."
    npm install
elif [ -d "frontend" ] && [ -f "frontend/package.json" ]; then
    echo "Installing Next.js dependencies..."
    cd frontend && npm install && cd ..
fi

EOF
    fi
}

# Generate Docker Compose configuration for services
function generate_docker_compose() {
    local project_dir="$1"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would generate Docker Compose configuration"
        return 0
    fi
    
    # Only generate docker-compose if we have services beyond DevContainer
    if [[ "$USE_POSTGRESQL" == false ]] && [[ "$USE_MONGODB" == false ]] && [[ "$USE_REDIS" == false ]] && [[ "$USE_CHROMA" == false ]]; then
        print_debug "No services required, skipping Docker Compose"
        return 0
    fi
    
    # Generate volumes section only if there are named volumes
    local volumes_section=""
    local volumes_content=$(generate_compose_volumes)
    if [[ -n "$volumes_content" ]]; then
        volumes_section="
volumes:
$volumes_content"
    fi

    cat > "$project_dir/docker-compose.yml" << EOF
services:
$(generate_compose_services)
${volumes_section}
networks:
  default:
    name: ${PROJECT_NAME}_network
EOF

    print_status "Generated Docker Compose configuration"
}

# Generate services section for Docker Compose
function generate_compose_services() {
    local services=""
    
    if [[ "$USE_POSTGRESQL" == true ]]; then
        local postgres_image=$(get_postgres_image_tag)
        services+="
  postgres:
    image: $postgres_image
    environment:
      POSTGRES_DB: ${PROJECT_NAME}
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - \"$DATABASE_PORT:5432\"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d
    restart: unless-stopped
"
    fi
    
    if [[ "$USE_MONGODB" == true ]]; then
        local mongodb_ver=$(get_effective_mongodb_version)
        services+="
  mongodb:
    image: mongo:$mongodb_ver
    environment:
      MONGO_INITDB_ROOT_USERNAME: mongo
      MONGO_INITDB_ROOT_PASSWORD: mongo
      MONGO_INITDB_DATABASE: ${PROJECT_NAME}
    ports:
      - \"27017:27017\"
    volumes:
      - mongodb_data:/data/db
      - ./mongodb/init:/docker-entrypoint-initdb.d
    restart: unless-stopped
"
    fi
    
    if [[ "$USE_REDIS" == true ]]; then
        local redis_image=$(get_redis_image_tag)
        services+="
  redis:
    image: $redis_image
    ports:
      - \"$REDIS_PORT:6379\"
    volumes:
      - redis_data:/data
    restart: unless-stopped
"
    fi
    
    if [[ "$USE_CHROMA" == true ]]; then
        local chroma_ver=$(get_effective_chroma_version)
        services+="
  chroma:
    image: chromadb/chroma:$chroma_ver
    ports:
      - \"8000:8000\"
    volumes:
      - ./chroma:/chroma/chroma
    environment:
      - CHROMA_SERVER_HOST=0.0.0.0
    restart: unless-stopped
"
    fi
    
    echo "$services"
}

# Generate volumes section for Docker Compose
function generate_compose_volumes() {
    local volumes=""
    
    if [[ "$USE_POSTGRESQL" == true ]]; then
        volumes+="  postgres_data:"$'\n'
    fi
    
    if [[ "$USE_MONGODB" == true ]]; then
        volumes+="  mongodb_data:"$'\n'
    fi
    
    if [[ "$USE_REDIS" == true ]]; then
        volumes+="  redis_data:"$'\n'
    fi
    
    echo "$volumes"
}

# Generate component-specific files
function generate_component_files() {
    local project_dir="$1"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would generate component files"
        return 0
    fi
    
    # Generate Python components (only if FastAPI is not used, since FastAPI has its own structure)
    if [[ "$USE_PYTHON" == true ]] && [[ "$USE_FASTAPI" == false ]]; then
        generate_python_requirements "$project_dir"
        # Generate basic Python project structure
        if source "$PROJECT_ROOT/generators/minimal-python.sh" 2>/dev/null; then
            generate_minimal_python_files "$project_dir"
        else
            print_warning "Minimal Python generator not found"
        fi
    fi
    
    # Generate Node.js components (only if Next.js is not used, since Next.js has its own structure)
    if [[ "$USE_NODE" == true ]] && [[ "$USE_NEXTJS" == false ]]; then
        generate_node_package_json "$project_dir"
        # Generate basic Node.js project structure
        if source "$PROJECT_ROOT/generators/minimal-node.sh" 2>/dev/null; then
            generate_minimal_node_files "$project_dir"
        else
            print_warning "Minimal Node.js generator not found"
        fi
    fi
    
    # Generate component-specific configurations using modular generators
    if [[ "$USE_FASTAPI" == true ]]; then
        if source "$PROJECT_ROOT/generators/fastapi.sh" 2>/dev/null; then
            generate_fastapi_component "$project_dir"
        else
            print_warning "FastAPI generator not found, using fallback"
            generate_basic_backend "$project_dir"
        fi
    fi
    
    if [[ "$USE_NEXTJS" == true ]]; then
        if source "$PROJECT_ROOT/generators/nextjs.sh" 2>/dev/null; then
            generate_nextjs_component "$project_dir"
        else
            print_warning "Next.js generator not found, using fallback"
            generate_basic_frontend "$project_dir"
        fi
    fi
    
    if [[ "$USE_POSTGRESQL" == true ]]; then
        if source "$PROJECT_ROOT/generators/postgresql.sh" 2>/dev/null; then
            generate_postgresql_component "$project_dir"
        else
            print_warning "PostgreSQL generator not found, using fallback"
            generate_database_init "$project_dir"
        fi
    fi
    
    if [[ "$USE_MONGODB" == true ]]; then
        if source "$PROJECT_ROOT/generators/mongodb.sh" 2>/dev/null; then
            generate_mongodb_component "$project_dir"
        else
            print_warning "MongoDB generator not found"
        fi
    fi
    
    if [[ "$USE_REDIS" == true ]]; then
        if source "$PROJECT_ROOT/generators/redis.sh" 2>/dev/null; then
            generate_redis_component "$project_dir"
        else
            print_warning "Redis generator not found"
        fi
    fi
    
    if [[ "$USE_CHROMA" == true ]]; then
        if source "$PROJECT_ROOT/generators/chroma.sh" 2>/dev/null; then
            generate_chroma_component "$project_dir"
        else
            print_warning "Chroma generator not found"
        fi
    fi
    
    print_status "Generated component files"
}

# Generate Python requirements.txt
function generate_python_requirements() {
    local project_dir="$1"
    # Use centralized template path (same pattern as profiles.sh)
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local template_file="$(dirname "$script_dir")/templates/requirements/${TEMPLATE:-minimal}.txt"
    
    if [[ -f "$template_file" ]]; then
        cp "$template_file" "$project_dir/requirements.txt"
        print_debug "Used requirements template: ${TEMPLATE:-minimal}"
    else
        # Fallback to basic requirements
        cat > "$project_dir/requirements.txt" << EOF
# Python dependencies for $PROJECT_NAME
# Generated by Spinbox on $(date)

# Development tools
uv>=0.1.0
pytest>=7.0.0
black>=23.0.0
python-dotenv>=1.0.0
requests>=2.28.0
EOF
        print_debug "Generated basic requirements.txt"
    fi
}

# Generate Node.js package.json
function generate_node_package_json() {
    local project_dir="$1"
    
    cat > "$project_dir/package.json" << EOF
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "Generated by Spinbox",
  "main": "index.js",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "14.0.0",
    "react": "18.2.0",
    "react-dom": "18.2.0"
  },
  "devDependencies": {
    "@types/node": "20.0.0",
    "@types/react": "18.2.0",
    "@types/react-dom": "18.2.0",
    "eslint": "8.0.0",
    "eslint-config-next": "14.0.0",
    "typescript": "5.0.0"
  }
}
EOF
}

# Generate basic backend files (fallback if generator doesn't exist)
function generate_basic_backend() {
    local project_dir="$1"
    
    safe_create_dir "$project_dir/backend"
    cat > "$project_dir/backend/main.py" << EOF
# FastAPI backend for $PROJECT_NAME
# Generated by Spinbox on $(date)

from fastapi import FastAPI

app = FastAPI(title="$PROJECT_NAME API")

@app.get("/")
async def root():
    return {"message": "Hello from $PROJECT_NAME!"}

@app.get("/health")
async def health():
    return {"status": "healthy"}
EOF
}

# Generate basic frontend files (fallback if generator doesn't exist)
function generate_basic_frontend() {
    local project_dir="$1"
    
    safe_create_dir "$project_dir/frontend"
    safe_create_dir "$project_dir/frontend/pages"

    cat > "$project_dir/frontend/pages/index.tsx" << EOF
// Next.js frontend for $PROJECT_NAME
// Generated by Spinbox on $(date)

export default function Home() {
  return (
    <div>
      <h1>Welcome to $PROJECT_NAME</h1>
      <p>Your development environment is ready!</p>
    </div>
  )
}
EOF
}

# Generate database initialization scripts
function generate_database_init() {
    local project_dir="$1"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would generate database initialization scripts"
        return 0
    fi
    
    safe_create_dir "$project_dir/database"
    safe_create_dir "$project_dir/database/init"

    cat > "$project_dir/database/init/01-init.sql" << EOF
-- Database initialization for $PROJECT_NAME
-- Generated by Spinbox on $(date)

-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS ${PROJECT_NAME};

-- Use the database
\c ${PROJECT_NAME};

-- Enable PGVector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Example table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF
}

# Save project configuration
function save_project_configuration() {
    local project_dir="$1"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would save project configuration"
        return 0
    fi
    
    # Set project configuration variables
    PROJECT_DESCRIPTION="Generated by Spinbox on $(date)"
    USE_FASTAPI="$USE_FASTAPI"
    USE_NEXTJS="$USE_NEXTJS"
    USE_POSTGRESQL="$USE_POSTGRESQL"
    USE_REDIS="$USE_REDIS"
    
    # Save project-specific config
    save_project_config "$project_dir"
    
    # Save version configuration used
    generate_version_config > "$project_dir/.config/versions.conf"
    
    print_status "Saved project configuration"
}

# Generate .gitignore from template
function generate_gitignore() {
    local project_dir="$1"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would generate .gitignore"
        return 0
    fi

    local template_file="$PROJECT_ROOT/templates/gitignore/comprehensive.gitignore"
    if [[ -f "$template_file" ]]; then
        cp "$template_file" "$project_dir/.gitignore"
        print_status "Generated .gitignore"
    else
        print_warning "gitignore template not found, creating basic .gitignore"
        cat > "$project_dir/.gitignore" << 'EOF'
# Environment
.env
.env.local
.env.*.local
venv/
__pycache__/
node_modules/
.next/
dist/
*.pyc
.DS_Store
EOF
    fi
}

# Generate README.md based on project type
function generate_readme() {
    local project_dir="$1"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would generate README.md"
        return 0
    fi

    local template_file=""
    local is_multi_component=false

    # Determine project type
    if [[ "$USE_FASTAPI" == true ]] && [[ "$USE_NEXTJS" == true ]]; then
        is_multi_component=true
        template_file="$PROJECT_ROOT/templates/readme/multi-component.md"
    elif [[ "$USE_FASTAPI" == true ]]; then
        template_file="$PROJECT_ROOT/templates/readme/fastapi.md"
    elif [[ "$USE_NEXTJS" == true ]]; then
        template_file="$PROJECT_ROOT/templates/readme/nextjs.md"
    elif [[ "$USE_PYTHON" == true ]]; then
        template_file="$PROJECT_ROOT/templates/readme/minimal-python.md"
    elif [[ "$USE_NODE" == true ]]; then
        template_file="$PROJECT_ROOT/templates/readme/minimal-node.md"
    fi

    if [[ -n "$template_file" ]] && [[ -f "$template_file" ]]; then
        local readme_content
        readme_content=$(cat "$template_file")

        # Replace project name
        readme_content="${readme_content//\{\{PROJECT_NAME\}\}/$PROJECT_NAME}"

        if [[ "$is_multi_component" == true ]]; then
            # Build dynamic sections for multi-component projects
            local backend_setup=""
            local frontend_setup=""
            local backend_structure=""
            local frontend_structure=""
            local database_structure=""
            local chroma_structure=""
            local services_info=""
            local backend_commands=""
            local frontend_commands=""
            local env_info=""

            if [[ "$USE_FASTAPI" == true ]]; then
                backend_setup="5. Set up Python environment: \`cd backend && ./setup_venv.sh\`
6. Start the backend: \`uvicorn app.main:app --reload --host 0.0.0.0\`"
                backend_structure="├── backend/           # FastAPI backend
│   ├── app/           # Application code
│   └── requirements.txt"
                services_info+="### Backend (FastAPI)
- URL: http://localhost:8000
- API docs: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

"
                backend_commands="### Backend Commands
\`\`\`bash
cd backend

# Start development server
uvicorn app.main:app --reload --host 0.0.0.0

# Run tests
pytest

# Format code
black .
\`\`\`"
                env_info+="### Backend (.env)
\`\`\`bash
DATABASE_URL=postgresql://postgres:postgres@postgres:5432/app
SECRET_KEY=your-secret-key
\`\`\`

"
            fi

            if [[ "$USE_NEXTJS" == true ]]; then
                frontend_setup="7. Install frontend dependencies: \`cd frontend && npm install\`
8. Start the frontend: \`npm run dev\`"
                frontend_structure="├── frontend/          # Next.js frontend
│   ├── src/           # Source code
│   └── package.json"
                services_info+="### Frontend (Next.js)
- URL: http://localhost:3000

"
                frontend_commands="### Frontend Commands
\`\`\`bash
cd frontend

# Start development server
npm run dev

# Build for production
npm run build

# Run linting
npm run lint
\`\`\`"
                env_info+="### Frontend (.env.local)
\`\`\`bash
NEXT_PUBLIC_API_URL=http://localhost:8000
\`\`\`

"
            fi

            if [[ "$USE_POSTGRESQL" == true ]]; then
                database_structure="├── database/          # PostgreSQL initialization
│   └── init/          # SQL init scripts"
                services_info+="### PostgreSQL Database
- Host: localhost:5432
- Database: ${PROJECT_NAME}
- User: postgres
- Password: postgres
- Connection URL: postgresql://postgres:postgres@localhost:5432/${PROJECT_NAME}

"
            fi

            if [[ "$USE_MONGODB" == true ]]; then
                services_info+="### MongoDB Database
- Host: localhost:27017
- Database: ${PROJECT_NAME}
- User: mongo
- Password: mongo
- Connection URL: mongodb://mongo:mongo@localhost:27017/${PROJECT_NAME}

"
            fi

            if [[ "$USE_REDIS" == true ]]; then
                services_info+="### Redis Cache
- Host: localhost:6379
- Connection URL: redis://localhost:6379

"
            fi

            if [[ "$USE_CHROMA" == true ]]; then
                chroma_structure="├── chroma/            # ChromaDB data"
                services_info+="### ChromaDB Vector Database
- Host: localhost:8000
- Connection URL: http://localhost:8000

"
            fi

            # Replace placeholders
            readme_content="${readme_content//\{\{BACKEND_SETUP\}\}/$backend_setup}"
            readme_content="${readme_content//\{\{FRONTEND_SETUP\}\}/$frontend_setup}"
            readme_content="${readme_content//\{\{BACKEND_STRUCTURE\}\}/$backend_structure}"
            readme_content="${readme_content//\{\{FRONTEND_STRUCTURE\}\}/$frontend_structure}"
            readme_content="${readme_content//\{\{DATABASE_STRUCTURE\}\}/$database_structure}"
            readme_content="${readme_content//\{\{CHROMA_STRUCTURE\}\}/$chroma_structure}"
            readme_content="${readme_content//\{\{SERVICES_INFO\}\}/$services_info}"
            readme_content="${readme_content//\{\{BACKEND_COMMANDS\}\}/$backend_commands}"
            readme_content="${readme_content//\{\{FRONTEND_COMMANDS\}\}/$frontend_commands}"
            readme_content="${readme_content//\{\{ENV_INFO\}\}/$env_info}"
        fi

        # Build services info for any project with databases (FastAPI, NextJS, etc.)
        local services_info=""

        if [[ "$USE_POSTGRESQL" == true ]]; then
            services_info+="### PostgreSQL Database
- Host: postgres (inside container) / localhost (from host)
- Port: 5432
- Database: ${PROJECT_NAME}
- User: postgres
- Password: postgres
- Connection URL: postgresql://postgres:postgres@postgres:5432/${PROJECT_NAME}

"
        fi

        if [[ "$USE_MONGODB" == true ]]; then
            services_info+="### MongoDB Database
- Host: mongodb (inside container) / localhost (from host)
- Port: 27017
- Database: ${PROJECT_NAME}
- User: mongo
- Password: mongo
- Connection URL: mongodb://mongo:mongo@mongodb:27017/${PROJECT_NAME}

"
        fi

        if [[ "$USE_REDIS" == true ]]; then
            services_info+="### Redis Cache
- Host: redis (inside container) / localhost (from host)
- Port: 6379
- Connection URL: redis://redis:6379

"
        fi

        if [[ "$USE_CHROMA" == true ]]; then
            services_info+="### ChromaDB Vector Database
- Host: chroma (inside container) / localhost (from host)
- Port: 8000
- Connection URL: http://chroma:8000

"
        fi

        # Replace services info placeholder (for all templates that have it)
        readme_content="${readme_content//\{\{SERVICES_INFO\}\}/$services_info}"

        echo "$readme_content" > "$project_dir/README.md"
        print_status "Generated README.md"
    else
        print_warning "README template not found, creating basic README"
        cat > "$project_dir/README.md" << EOF
# $PROJECT_NAME

A project created with [Spinbox](https://github.com/Gonzillaaa/spinbox).

## Getting Started

1. Open this project in VS Code or Cursor
2. When prompted, click "Reopen in Container"
3. Wait for the DevContainer to build and start

---
Generated by [Spinbox](https://github.com/Gonzillaaa/spinbox)
EOF
    fi
}

# Main project creation function
function create_project() {
    # Parse component flags from global COMPONENTS variable
    if [[ -n "${COMPONENTS:-}" ]]; then
        parse_component_flags $COMPONENTS
    fi

    # Apply version overrides
    apply_version_overrides

    # Determine project path
    if [[ -n "$PROJECT_DIR" ]]; then
        PROJECT_PATH="$PROJECT_DIR/$PROJECT_NAME"
    else
        PROJECT_PATH="./$PROJECT_NAME"
    fi

    # Export component flags for version configuration display
    export USE_PYTHON USE_NODE USE_POSTGRESQL USE_REDIS
    
    # Show configuration
    print_info "Creating project: $PROJECT_NAME"
    print_info "Location: $PROJECT_PATH"
    if [[ ${#SELECTED_COMPONENTS[@]} -gt 0 ]]; then
        print_info "Components: ${SELECTED_COMPONENTS[*]}"
    fi
    show_version_configuration
    
    # Validate and create project
    if ! validate_project_directory "$PROJECT_PATH"; then
        return 1
    fi
    
    print_status "Creating project $PROJECT_NAME..."
    
    # Create directory structure
    create_project_directory "$PROJECT_PATH"
    
    # Generate configurations
    generate_project_devcontainer "$PROJECT_PATH"
    generate_docker_compose "$PROJECT_PATH"
    generate_component_files "$PROJECT_PATH"
    save_project_configuration "$PROJECT_PATH"

    # Generate README and .gitignore
    generate_readme "$PROJECT_PATH"
    generate_gitignore "$PROJECT_PATH"

    # Initialize git repository unless --no-git flag is set
    if [[ "${NO_GIT:-false}" != true ]] && [[ "$DRY_RUN" != true ]]; then
        if [[ ! -d "$PROJECT_PATH/.git" ]]; then
            (cd "$PROJECT_PATH" && git init -q)
            print_status "Git repository initialized"
        fi
    fi

    # Install git hooks unless --no-hooks or --no-git flag is set
    if [[ "${NO_HOOKS:-false}" != true ]] && [[ "${NO_GIT:-false}" != true ]] && [[ "$DRY_RUN" != true ]]; then
        # Determine language for hooks based on components
        local hook_language=""
        if [[ "$USE_PYTHON" == true ]] || [[ "$USE_FASTAPI" == true ]]; then
            hook_language="python"
        elif [[ "$USE_NODE" == true ]] || [[ "$USE_NEXTJS" == true ]]; then
            hook_language="node"
        fi

        if [[ -n "$hook_language" ]]; then
            if source "$PROJECT_ROOT/lib/git-hooks.sh" 2>/dev/null; then
                install_git_hooks "$PROJECT_PATH" "$hook_language"
            fi
        fi
    fi

    # Show appropriate completion message based on mode
    if [[ "$DRY_RUN" == true ]]; then
        print_status "Dry run completed - no files were created"
        print_info "Run without --dry-run to create the project:"
        echo "  spinbox create $PROJECT_NAME${COMPONENTS:+ $COMPONENTS}"
        return 0
    fi

    print_status "Project $PROJECT_NAME created successfully!"
    print_info "Next steps:"
    echo "  1. cd $PROJECT_NAME"
    echo "  2. Open in your preferred editor (code . or cursor .)"
    echo "  3. Reopen in DevContainer when prompted"

    local step=4
    if [[ "$USE_POSTGRESQL" == true ]] || [[ "$USE_REDIS" == true ]] || [[ "$USE_MONGODB" == true ]] || [[ "$USE_CHROMA" == true ]]; then
        echo "  $step. Start database services (on host): docker compose up -d"
        ((step++))
    fi
    if [[ "$USE_FASTAPI" == true ]]; then
        echo "  $step. Set up Python environment: cd backend && ./setup_venv.sh"
        ((step++))
    fi
    if [[ "$USE_NEXTJS" == true ]]; then
        # Check if Next.js is the only primary component (not counting databases)
        local nextjs_only=true
        [[ "$USE_FASTAPI" == true ]] && nextjs_only=false
        [[ "$USE_PYTHON" == true && "$USE_FASTAPI" == false ]] && nextjs_only=false

        if [[ "$nextjs_only" == true ]]; then
            echo "  $step. Install Node.js dependencies: npm install"
        else
            echo "  $step. Install Node.js dependencies: cd frontend && npm install"
        fi
        ((step++))
    fi
    if [[ "$USE_FASTAPI" == true ]]; then
        echo "  $step. Start FastAPI server: cd backend && uvicorn app.main:app --reload --host 0.0.0.0"
        ((step++))
    fi
    if [[ "$USE_NEXTJS" == true ]]; then
        # Check if Next.js is the only primary component (not counting databases)
        local nextjs_only=true
        [[ "$USE_FASTAPI" == true ]] && nextjs_only=false
        [[ "$USE_PYTHON" == true && "$USE_FASTAPI" == false ]] && nextjs_only=false

        if [[ "$nextjs_only" == true ]]; then
            echo "  $step. Start Next.js dev server: npm run dev"
        else
            echo "  $step. Start Next.js dev server: cd frontend && npm run dev"
        fi
    fi

    show_connection_details
}

# Show connection details for services
function show_connection_details() {
    echo ""
    if [[ "$USE_POSTGRESQL" == true ]]; then
        print_info "PostgreSQL connection:"
        echo "  • Host: postgres (inside container) / localhost (from host)"
        echo "  • Port: 5432"
        echo "  • Database: ${PROJECT_NAME}"
        echo "  • User: postgres"
        echo "  • Password: postgres"
        echo "  • URL: postgresql://postgres:postgres@postgres:5432/${PROJECT_NAME}"
        echo ""
    fi

    if [[ "$USE_MONGODB" == true ]]; then
        print_info "MongoDB connection:"
        echo "  • Host: mongodb (inside container) / localhost (from host)"
        echo "  • Port: 27017"
        echo "  • Database: ${PROJECT_NAME}"
        echo "  • User: mongo"
        echo "  • Password: mongo"
        echo "  • URL: mongodb://mongo:mongo@mongodb:27017/${PROJECT_NAME}"
        echo ""
    fi

    if [[ "$USE_REDIS" == true ]]; then
        print_info "Redis connection:"
        echo "  • Host: redis (inside container) / localhost (from host)"
        echo "  • Port: 6379"
        echo "  • URL: redis://redis:6379"
        echo ""
    fi

    if [[ "$USE_CHROMA" == true ]]; then
        print_info "ChromaDB connection:"
        echo "  • Host: chroma (inside container) / localhost (from host)"
        echo "  • Port: 8000"
        echo "  • URL: http://chroma:8000"
        echo "  • Data stored in: ./chroma/"
        echo ""
    fi

    print_info "Security reminders:"
    echo "  • Review and update .env files with your actual credentials"
    echo "  • Never commit .env files to version control"
    echo "  • Use strong passwords and secure API keys"
}

# Add components to existing project
function add_components() {
    # Check if we're in a Spinbox project
    if [[ ! -d ".devcontainer" ]] && [[ ! -f "docker-compose.yml" ]]; then
        print_error "Not in a Spinbox project directory"
        print_info "Run this command from the root of a Spinbox project"
        return 1
    fi

    # Load existing project configuration FIRST
    if [[ -f ".config/project.conf" ]]; then
        load_project_config "."
    fi

    # Parse component flags AFTER loading config (new flags override/add to existing)
    if [[ -n "${COMPONENTS:-}" ]]; then
        parse_component_flags $COMPONENTS
    fi

    # Apply version overrides
    apply_version_overrides
    
    PROJECT_PATH="."
    PROJECT_NAME="${PROJECT_NAME:-$(basename "$PWD")}"
    
    # Export component flags for version configuration display
    export USE_PYTHON USE_NODE USE_POSTGRESQL USE_REDIS
    
    print_info "Adding components to project: $PROJECT_NAME"
    print_info "New components: ${SELECTED_COMPONENTS[*]}"
    show_version_configuration
    
    # Add components (similar to create but preserve existing)
    print_status "Adding components to $PROJECT_NAME..."
    
    create_project_directory "$PROJECT_PATH"  # Creates only missing directories
    generate_project_devcontainer "$PROJECT_PATH"  # Updates DevContainer
    generate_docker_compose "$PROJECT_PATH"  # Updates or creates Compose
    generate_component_files "$PROJECT_PATH"  # Adds new component files
    save_project_configuration "$PROJECT_PATH"  # Updates config
    
    print_status "Components added successfully!"
    print_info "Restart your DevContainer to apply changes"

    show_connection_details
}

# Export functions for use in other scripts
export -f parse_component_flags validate_project_directory
export -f create_project_directory generate_project_devcontainer generate_devcontainer_config
export -f generate_docker_compose generate_component_files
export -f save_project_configuration create_project add_components