#!/bin/bash
# Dependency Manager for Spinbox
# Uses uv for Python and npm for Node.js dependencies

# Add Python dependencies using uv
function add_python_dependencies() {
    local project_dir="$1"
    local component="$2"
    
    if [[ "$WITH_DEPS" != "true" ]]; then
        print_debug "Skipping Python dependency installation (--with-deps not specified)"
        return 0
    fi
    
    # Check if we have a Python project
    if [[ ! -f "$project_dir/pyproject.toml" ]] && [[ ! -f "$project_dir/requirements.txt" ]]; then
        print_debug "No Python project detected, skipping Python dependencies"
        return 0
    fi
    
    print_info "Adding Python dependencies for component: $component"
    
    # Use uv to add dependencies based on component
    case "$component" in
        "fastapi")
            add_python_deps_with_uv "$project_dir" "fastapi" "uvicorn[standard]" "pydantic" "python-dotenv" "pydantic-settings"
            ;;
        "postgresql")
            add_python_deps_with_uv "$project_dir" "sqlalchemy" "asyncpg" "alembic" "psycopg2-binary"
            ;;
        "mongodb")
            add_python_deps_with_uv "$project_dir" "beanie" "motor" "pymongo"
            ;;
        "redis")
            add_python_deps_with_uv "$project_dir" "redis" "aioredis" "celery"
            ;;
        "chroma")
            add_python_deps_with_uv "$project_dir" "chromadb" "sentence-transformers"
            ;;
        "ai-llm")
            add_python_deps_with_uv "$project_dir" "openai" "anthropic" "langchain" "langchain-community" "tiktoken"
            ;;
        *)
            print_debug "No Python dependencies defined for component: $component"
            ;;
    esac
}

# Helper function to add Python dependencies with uv
function add_python_deps_with_uv() {
    local project_dir="$1"
    shift
    local deps=("$@")
    
    if ! command -v uv &> /dev/null; then
        print_warning "uv not found, falling back to pip"
        add_python_deps_with_pip "$project_dir" "${deps[@]}"
        return
    fi
    
    print_debug "Adding Python dependencies with uv: ${deps[*]}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "Would run: uv add ${deps[*]}"
        return
    fi
    
    # Change to project directory
    cd "$project_dir" || {
        print_error "Cannot change to project directory: $project_dir"
        return 1
    }
    
    # Use uv to add dependencies
    if uv add "${deps[@]}"; then
        print_status "Successfully added Python dependencies: ${deps[*]}"
    else
        print_error "Failed to add Python dependencies with uv"
        return 1
    fi
}

# Fallback function to add Python dependencies with pip
function add_python_deps_with_pip() {
    local project_dir="$1"
    shift
    local deps=("$@")
    local requirements_file="$project_dir/requirements.txt"
    
    print_debug "Adding Python dependencies with pip: ${deps[*]}"
    
    # Ensure requirements.txt exists
    touch "$requirements_file"
    
    for dep in "${deps[@]}"; do
        if ! grep -q "^${dep}[><=]" "$requirements_file" 2>/dev/null; then
            if [[ "$DRY_RUN" == "true" ]]; then
                print_info "Would add $dep to requirements.txt"
            else
                echo "$dep" >> "$requirements_file"
                print_status "Added $dep to requirements.txt"
            fi
        else
            print_debug "Dependency already exists: $dep"
        fi
    done
    
    # Clean up requirements.txt
    if [[ "$DRY_RUN" != "true" ]]; then
        sort -u "$requirements_file" -o "$requirements_file"
    fi
}

# Add Node.js dependencies using npm
function add_nodejs_dependencies() {
    local project_dir="$1"
    local component="$2"
    
    if [[ "$WITH_DEPS" != "true" ]]; then
        print_debug "Skipping Node.js dependency installation (--with-deps not specified)"
        return 0
    fi
    
    # Check if we have a Node.js project
    if [[ ! -f "$project_dir/package.json" ]]; then
        print_debug "No Node.js project detected, skipping Node.js dependencies"
        return 0
    fi
    
    print_info "Adding Node.js dependencies for component: $component"
    
    # Use npm to add dependencies based on component
    case "$component" in
        "nextjs")
            add_nodejs_deps_with_npm "$project_dir" "next" "react" "react-dom"
            add_nodejs_dev_deps_with_npm "$project_dir" "@types/node" "@types/react" "@types/react-dom" "typescript" "eslint" "eslint-config-next"
            ;;
        "api-client")
            add_nodejs_deps_with_npm "$project_dir" "axios" "swr"
            ;;
        "ui-components")
            add_nodejs_deps_with_npm "$project_dir" "@headlessui/react" "@heroicons/react" "clsx" "tailwindcss"
            ;;
        *)
            print_debug "No Node.js dependencies defined for component: $component"
            ;;
    esac
}

# Helper function to add Node.js dependencies with npm
function add_nodejs_deps_with_npm() {
    local project_dir="$1"
    shift
    local deps=("$@")
    
    if ! command -v npm &> /dev/null; then
        print_error "npm not found, cannot add Node.js dependencies"
        return 1
    fi
    
    print_debug "Adding Node.js dependencies with npm: ${deps[*]}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "Would run: npm install ${deps[*]}"
        return
    fi
    
    # Change to project directory
    cd "$project_dir" || {
        print_error "Cannot change to project directory: $project_dir"
        return 1
    }
    
    # Use npm to install dependencies
    if npm install "${deps[@]}"; then
        print_status "Successfully added Node.js dependencies: ${deps[*]}"
    else
        print_error "Failed to add Node.js dependencies with npm"
        return 1
    fi
}

# Helper function to add Node.js dev dependencies with npm
function add_nodejs_dev_deps_with_npm() {
    local project_dir="$1"
    shift
    local deps=("$@")
    
    if ! command -v npm &> /dev/null; then
        print_error "npm not found, cannot add Node.js dev dependencies"
        return 1
    fi
    
    print_debug "Adding Node.js dev dependencies with npm: ${deps[*]}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "Would run: npm install --save-dev ${deps[*]}"
        return
    fi
    
    # Change to project directory
    cd "$project_dir" || {
        print_error "Cannot change to project directory: $project_dir"
        return 1
    }
    
    # Use npm to install dev dependencies
    if npm install --save-dev "${deps[@]}"; then
        print_status "Successfully added Node.js dev dependencies: ${deps[*]}"
    else
        print_error "Failed to add Node.js dev dependencies with npm"
        return 1
    fi
}

# Main function to add dependencies based on component
function add_component_dependencies() {
    local project_dir="$1"
    local component="$2"
    
    if [[ "$WITH_DEPS" != "true" ]]; then
        print_debug "Skipping dependency installation (--with-deps not specified)"
        return 0
    fi
    
    print_debug "Adding dependencies for component: $component"
    
    # Add both Python and Node.js dependencies as appropriate
    add_python_dependencies "$project_dir" "$component"
    add_nodejs_dependencies "$project_dir" "$component"
}

# Add dependencies for multiple components
function add_dependencies_for_components() {
    local project_dir="$1"
    local components="$2"
    
    if [[ "$WITH_DEPS" != "true" ]]; then
        print_debug "Skipping dependency installation (--with-deps not specified)"
        return 0
    fi
    
    print_info "Processing dependencies for components: $components"
    
    # Process each component
    for component in $components; do
        # Remove leading -- from component name
        local clean_component="${component#--}"
        add_component_dependencies "$project_dir" "$clean_component"
    done
}

# Initialize Python project with uv if not already initialized
function init_python_project_with_uv() {
    local project_dir="$1"
    
    if [[ ! -f "$project_dir/pyproject.toml" ]] && [[ ! -f "$project_dir/requirements.txt" ]]; then
        print_debug "No Python project files found, skipping uv init"
        return 0
    fi
    
    if ! command -v uv &> /dev/null; then
        print_debug "uv not found, skipping uv init"
        return 0
    fi
    
    # Change to project directory
    cd "$project_dir" || {
        print_error "Cannot change to project directory: $project_dir"
        return 1
    }
    
    # Initialize uv project if pyproject.toml doesn't exist
    if [[ ! -f "pyproject.toml" ]]; then
        print_info "Initializing Python project with uv..."
        
        if [[ "$DRY_RUN" == "true" ]]; then
            print_info "Would run: uv init"
            return
        fi
        
        if uv init --no-readme --no-pin-python; then
            print_status "Initialized Python project with uv"
        else
            print_warning "Failed to initialize with uv, continuing anyway"
        fi
    fi
}

# Initialize Node.js project with npm if not already initialized
function init_nodejs_project_with_npm() {
    local project_dir="$1"
    
    if [[ -f "$project_dir/package.json" ]]; then
        print_debug "package.json already exists, skipping npm init"
        return 0
    fi
    
    if ! command -v npm &> /dev/null; then
        print_debug "npm not found, skipping npm init"
        return 0
    fi
    
    # Change to project directory
    cd "$project_dir" || {
        print_error "Cannot change to project directory: $project_dir"
        return 1
    }
    
    print_info "Initializing Node.js project with npm..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "Would run: npm init -y"
        return
    fi
    
    if npm init -y; then
        print_status "Initialized Node.js project with npm"
    else
        print_warning "Failed to initialize with npm, continuing anyway"
    fi
}

# Export functions for use in other scripts
export -f add_component_dependencies
export -f add_dependencies_for_components
export -f init_python_project_with_uv
export -f init_nodejs_project_with_npm