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
                USE_NODE=true    # Next.js requires Node
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
            print_warning "Directory $project_dir already exists - force mode enabled, will overwrite"
            if [[ "$DRY_RUN" != true ]]; then
                rm -rf "$project_dir"
                print_info "Removed existing directory $project_dir"
            else
                print_info "DRY RUN: Would remove existing directory $project_dir"
            fi
        else
            print_error "Directory $project_dir already exists"
            print_info "Use --force to overwrite or choose a different name/location"
            exit 1
        fi
    fi
    
    # Check if parent directory is writable
    local parent_dir=$(dirname "$project_dir")
    if [[ ! -w "$parent_dir" ]]; then
        print_error "Cannot create project in $parent_dir (permission denied)"
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
        safe_create_dir "$project_dir/fastapi"
    fi
    
    if [[ "$USE_NEXTJS" == true ]]; then
        safe_create_dir "$project_dir/nextjs"
    fi
    
    if [[ "$USE_POSTGRESQL" == true ]]; then
        safe_create_dir "$project_dir/postgresql"
    fi
    
    if [[ "$USE_MONGODB" == true ]]; then
        safe_create_dir "$project_dir/mongodb"
    fi
    
    if [[ "$USE_REDIS" == true ]]; then
        safe_create_dir "$project_dir/redis"
    fi
    
    if [[ "$USE_CHROMA" == true ]]; then
        safe_create_dir "$project_dir/chroma_data"
    fi
    
    print_status "Created project directory structure"
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

# Install Zsh and Powerlevel10k
RUN apt-get update && apt-get install -y \\
    zsh \\
    git \\
    curl \\
    && rm -rf /var/lib/apt/lists/*

# Install Oh My Zsh and Powerlevel10k
RUN sh -c "\$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \\
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \${ZSH_CUSTOM:-\$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Set up Zsh as default shell
RUN chsh -s /bin/zsh
ENV SHELL=/bin/zsh

# Create workspace directory
WORKDIR /workspace

# Copy setup script
COPY setup.sh /setup.sh
RUN chmod +x /setup.sh
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
    
    if [[ "$USE_NODE" == true ]]; then
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

# Generate Dockerfile content based on components
function generate_dockerfile_content() {
    local python_image=$(get_python_image_tag)
    local node_image=$(get_node_image_tag)
    
    if [[ "$USE_PYTHON" == true ]] && [[ "$USE_NODE" == true ]]; then
        # Multi-stage build for both Python and Node
        cat << EOF
FROM $node_image as node-base
FROM $python_image

# Copy Node.js from node image
COPY --from=node-base /usr/local/bin/node /usr/local/bin/
COPY --from=node-base /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm

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
    
    if [[ "$USE_PYTHON" == true ]]; then
        cat << 'EOF'
# Set up Python virtual environment
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python -m venv venv
    source venv/bin/activate
    
    # Install requirements if they exist
    if [ -f "requirements.txt" ]; then
        echo "Installing Python dependencies..."
        uv pip install -r requirements.txt
    fi
fi

EOF
    fi
    
    if [[ "$USE_NODE" == true ]]; then
        cat << 'EOF'
# Install Node.js dependencies
if [ -f "package.json" ]; then
    echo "Installing Node.js dependencies..."
    npm install
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
    
    cat > "$project_dir/docker-compose.yml" << EOF
services:
$(generate_compose_services)

volumes:
$(generate_compose_volumes)

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
      - ./postgresql/init:/docker-entrypoint-initdb.d
    restart: unless-stopped
"
    fi
    
    if [[ "$USE_MONGODB" == true ]]; then
        services+="
  mongodb:
    image: mongo:7
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
        services+="
  chroma:
    image: chromadb/chroma:latest
    ports:
      - \"8000:8000\"
    volumes:
      - ./chroma_data:/chroma/chroma
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
    
    # Generate Python components
    if [[ "$USE_PYTHON" == true ]]; then
        generate_python_requirements "$project_dir"
        # Generate basic Python project structure
        if source "$PROJECT_ROOT/generators/minimal-python.sh" 2>/dev/null; then
            generate_minimal_python_files "$project_dir"
        else
            print_warning "Minimal Python generator not found"
        fi
    fi
    
    # Generate Node.js components
    if [[ "$USE_NODE" == true ]]; then
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
    
    safe_create_dir "$project_dir/fastapi"
    cat > "$project_dir/fastapi/main.py" << EOF
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
    
    safe_create_dir "$project_dir/nextjs"
    safe_create_dir "$project_dir/nextjs/pages"
    
    cat > "$project_dir/nextjs/pages/index.tsx" << EOF
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
    
    safe_create_dir "$project_dir/postgresql"
    safe_create_dir "$project_dir/postgresql/init"
    
    cat > "$project_dir/postgresql/init/01-init.sql" << EOF
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
    print_info "Components: ${SELECTED_COMPONENTS[*]}"
    show_version_configuration
    
    # Validate and create project
    if ! validate_project_directory "$PROJECT_PATH"; then
        return 1
    fi
    
    print_status "Creating project $PROJECT_NAME..."
    
    # Create directory structure
    create_project_directory "$PROJECT_PATH"
    
    # Generate configurations
    generate_devcontainer_config "$PROJECT_PATH"
    generate_docker_compose "$PROJECT_PATH"
    generate_component_files "$PROJECT_PATH"
    save_project_configuration "$PROJECT_PATH"
    
    print_status "Project $PROJECT_NAME created successfully!"
    print_info "Next steps:"
    echo "  1. cd $PROJECT_NAME"
    echo "  2. Open in your preferred editor (code . or cursor .)"
    echo "  3. Reopen in DevContainer when prompted"
    if [[ "$USE_FASTAPI" == true ]]; then
        echo "  4. Set up Python environment: cd fastapi && ./setup_venv.sh"
    fi
    if [[ "$USE_NEXTJS" == true ]]; then
        echo "  4. Install Node.js dependencies: cd nextjs && npm install"
    fi
    if [[ "$USE_POSTGRESQL" == true ]] || [[ "$USE_REDIS" == true ]] || [[ "$USE_MONGODB" == true ]] || [[ "$USE_CHROMA" == true ]]; then
        echo "  5. Start services: docker-compose up -d"
    fi
    echo ""
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
    
    # Parse component flags
    if [[ -n "${COMPONENTS:-}" ]]; then
        parse_component_flags $COMPONENTS
    fi
    
    # Apply version overrides
    apply_version_overrides
    
    # Load existing project configuration
    if [[ -f ".config/project.conf" ]]; then
        load_project_config "."
    fi
    
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
    generate_devcontainer_config "$PROJECT_PATH"  # Updates DevContainer
    generate_docker_compose "$PROJECT_PATH"  # Updates or creates Compose
    generate_component_files "$PROJECT_PATH"  # Adds new component files
    save_project_configuration "$PROJECT_PATH"  # Updates config
    
    print_status "Components added successfully!"
    print_info "Restart your DevContainer to apply changes"
}

# Export functions for use in other scripts
export -f parse_component_flags validate_project_directory
export -f create_project_directory generate_devcontainer_config
export -f generate_docker_compose generate_component_files
export -f save_project_configuration create_project add_components