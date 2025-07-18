#!/bin/bash
# Dependency Management System for Spinbox
# Handles automatic package management for Python and Node.js projects

# Function to add Python dependencies to requirements.txt
function add_python_dependencies() {
    local project_dir="$1"
    local component="$2"
    local requirements_file="$project_dir/requirements.txt"
    
    # Ensure requirements.txt exists
    if [[ ! -f "$requirements_file" ]]; then
        touch "$requirements_file"
    fi
    
    print_debug "Adding Python dependencies for component: $component"
    
    case "$component" in
        "fastapi")
            add_to_requirements "$requirements_file" "fastapi>=0.104.0"
            add_to_requirements "$requirements_file" "uvicorn[standard]>=0.24.0"
            add_to_requirements "$requirements_file" "pydantic>=2.5.0"
            add_to_requirements "$requirements_file" "python-dotenv>=1.0.0"
            ;;
        "postgresql")
            add_to_requirements "$requirements_file" "sqlalchemy>=2.0.0"
            add_to_requirements "$requirements_file" "asyncpg>=0.29.0"
            add_to_requirements "$requirements_file" "alembic>=1.13.0"
            add_to_requirements "$requirements_file" "psycopg2-binary>=2.9.0"
            ;;
        "redis")
            add_to_requirements "$requirements_file" "redis>=5.0.0"
            add_to_requirements "$requirements_file" "celery>=5.3.0"
            ;;
        "chroma")
            add_to_requirements "$requirements_file" "chromadb>=0.4.0"
            add_to_requirements "$requirements_file" "sentence-transformers>=2.2.0"
            ;;
        "mongodb")
            add_to_requirements "$requirements_file" "beanie>=1.24.0"
            add_to_requirements "$requirements_file" "motor>=3.3.0"
            ;;
        "openai")
            add_to_requirements "$requirements_file" "openai>=1.3.0"
            add_to_requirements "$requirements_file" "tiktoken>=0.5.0"
            ;;
        "anthropic")
            add_to_requirements "$requirements_file" "anthropic>=0.7.0"
            ;;
        "langchain")
            add_to_requirements "$requirements_file" "langchain>=0.0.350"
            add_to_requirements "$requirements_file" "langchain-community>=0.0.1"
            add_to_requirements "$requirements_file" "langchain-openai>=0.0.1"
            ;;
        "llamaindex")
            add_to_requirements "$requirements_file" "llama-index>=0.9.0"
            add_to_requirements "$requirements_file" "llama-index-vector-stores-chroma>=0.1.0"
            ;;
        "data-science")
            add_to_requirements "$requirements_file" "pandas>=2.0.0"
            add_to_requirements "$requirements_file" "numpy>=1.24.0"
            add_to_requirements "$requirements_file" "matplotlib>=3.7.0"
            add_to_requirements "$requirements_file" "seaborn>=0.12.0"
            add_to_requirements "$requirements_file" "scikit-learn>=1.3.0"
            add_to_requirements "$requirements_file" "jupyter>=1.0.0"
            add_to_requirements "$requirements_file" "plotly>=5.15.0"
            ;;
        "ai-llm")
            add_to_requirements "$requirements_file" "openai>=1.3.0"
            add_to_requirements "$requirements_file" "anthropic>=0.7.0"
            add_to_requirements "$requirements_file" "langchain>=0.0.350"
            add_to_requirements "$requirements_file" "llama-index>=0.9.0"
            add_to_requirements "$requirements_file" "tiktoken>=0.5.0"
            add_to_requirements "$requirements_file" "transformers>=4.36.0"
            ;;
        "web-scraping")
            add_to_requirements "$requirements_file" "beautifulsoup4>=4.12.0"
            add_to_requirements "$requirements_file" "requests>=2.31.0"
            add_to_requirements "$requirements_file" "selenium>=4.15.0"
            add_to_requirements "$requirements_file" "scrapy>=2.11.0"
            add_to_requirements "$requirements_file" "lxml>=4.9.0"
            ;;
        "api-development")
            add_to_requirements "$requirements_file" "fastapi>=0.104.0"
            add_to_requirements "$requirements_file" "uvicorn[standard]>=0.24.0"
            add_to_requirements "$requirements_file" "pydantic>=2.5.0"
            add_to_requirements "$requirements_file" "httpx>=0.25.0"
            add_to_requirements "$requirements_file" "python-multipart>=0.0.6"
            ;;
        *)
            print_warning "Unknown component for Python dependencies: $component"
            return 1
            ;;
    esac
    
    print_info "Added Python dependencies for $component"
}

# Function to add Node.js dependencies to package.json
function add_nodejs_dependencies() {
    local project_dir="$1"
    local component="$2"
    local package_json="$project_dir/package.json"
    
    print_debug "Adding Node.js dependencies for component: $component"
    
    case "$component" in
        "nextjs")
            add_to_package_json "$package_json" "dependencies" "next" "^14.0.0"
            add_to_package_json "$package_json" "dependencies" "react" "^18.0.0"
            add_to_package_json "$package_json" "dependencies" "react-dom" "^18.0.0"
            add_to_package_json "$package_json" "dependencies" "axios" "^1.6.0"
            add_to_package_json "$package_json" "devDependencies" "@types/node" "^20.0.0"
            add_to_package_json "$package_json" "devDependencies" "@types/react" "^18.0.0"
            add_to_package_json "$package_json" "devDependencies" "@types/react-dom" "^18.0.0"
            add_to_package_json "$package_json" "devDependencies" "typescript" "^5.0.0"
            add_to_package_json "$package_json" "devDependencies" "eslint" "^8.0.0"
            add_to_package_json "$package_json" "devDependencies" "eslint-config-next" "^14.0.0"
            ;;
        "express")
            add_to_package_json "$package_json" "dependencies" "express" "^4.18.0"
            add_to_package_json "$package_json" "dependencies" "cors" "^2.8.5"
            add_to_package_json "$package_json" "dependencies" "helmet" "^7.0.0"
            add_to_package_json "$package_json" "dependencies" "morgan" "^1.10.0"
            add_to_package_json "$package_json" "devDependencies" "@types/express" "^4.17.0"
            add_to_package_json "$package_json" "devDependencies" "@types/cors" "^2.8.0"
            add_to_package_json "$package_json" "devDependencies" "@types/morgan" "^1.9.0"
            ;;
        "tailwindcss")
            add_to_package_json "$package_json" "devDependencies" "tailwindcss" "^3.3.0"
            add_to_package_json "$package_json" "devDependencies" "autoprefixer" "^10.4.0"
            add_to_package_json "$package_json" "devDependencies" "postcss" "^8.4.0"
            ;;
        *)
            print_warning "Unknown component for Node.js dependencies: $component"
            return 1
            ;;
    esac
    
    print_info "Added Node.js dependencies for $component"
}

# Function to add a package to requirements.txt
function add_to_requirements() {
    local requirements_file="$1"
    local package="$2"
    
    # Check if package already exists (case-insensitive)
    local package_name="${package%%[><=]*}"
    if ! grep -i "^${package_name}[><=]" "$requirements_file" >/dev/null 2>&1; then
        # Ensure we add a newline before the package if the file doesn't end with one
        if [[ -s "$requirements_file" ]] && [[ $(tail -c 1 "$requirements_file") != $'\n' ]]; then
            echo "" >> "$requirements_file"
        fi
        echo "$package" >> "$requirements_file"
        print_debug "Added $package to requirements.txt"
    else
        print_debug "Package $package_name already exists in requirements.txt"
    fi
}

# Function to add a package to package.json
function add_to_package_json() {
    local package_json="$1"
    local dependency_type="$2"  # "dependencies" or "devDependencies"
    local package_name="$3"
    local version="$4"
    
    # Ensure package.json exists
    if [[ ! -f "$package_json" ]]; then
        create_basic_package_json "$package_json"
    fi
    
    # Check if package already exists
    if ! grep -q "\"$package_name\"" "$package_json"; then
        # Use a simpler file manipulation approach
        local temp_file=$(mktemp)
        
        # Add dependency_type section if it doesn't exist
        if ! grep -q "\"$dependency_type\"" "$package_json"; then
            # Insert dependencies section before the closing brace
            awk '
            /^}$/ {
                print "  \"'"$dependency_type"'\": {},"
                print $0
                next
            }
            { print }
            ' "$package_json" > "$temp_file"
            mv "$temp_file" "$package_json"
        fi
        
        # Add the package to the dependencies section
        awk '
        /^  "'"$dependency_type"'": {/ {
            print $0
            print "    \"'"$package_name"'\": \"'"$version"'\"," 
            next
        }
        { print }
        ' "$package_json" > "$temp_file"
        mv "$temp_file" "$package_json"
        
        print_debug "Added $package_name to package.json $dependency_type"
    else
        print_debug "Package $package_name already exists in package.json"
    fi
}

# Function to create a basic package.json if it doesn't exist
function create_basic_package_json() {
    local package_json="$1"
    local project_name="${PROJECT_NAME:-spinbox-project}"
    
    cat > "$package_json" << EOF
{
  "name": "$project_name",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
EOF
    
    print_debug "Created basic package.json"
}

# Function to manage dependencies for a component
function manage_component_dependencies() {
    local project_dir="$1"
    local component="$2"
    
    # Skip if WITH_DEPS is not enabled
    if [[ "$WITH_DEPS" != "true" ]]; then
        print_debug "Skipping dependency management (WITH_DEPS not enabled)"
        return 0
    fi
    
    print_debug "Managing dependencies for component: $component in $project_dir"
    
    # Define component types
    local python_components=("fastapi" "postgresql" "redis" "chroma" "mongodb" "openai" "anthropic" "langchain" "llamaindex" "data-science" "ai-llm" "web-scraping" "api-development")
    local nodejs_components=("nextjs" "express" "tailwindcss")
    
    # Check if component is a Python component
    local is_python_component=false
    for py_comp in "${python_components[@]}"; do
        if [[ "$component" == "$py_comp" ]]; then
            is_python_component=true
            break
        fi
    done
    
    # Check if component is a Node.js component
    local is_nodejs_component=false
    for js_comp in "${nodejs_components[@]}"; do
        if [[ "$component" == "$js_comp" ]]; then
            is_nodejs_component=true
            break
        fi
    done
    
    # Handle Python dependencies
    if [[ "$is_python_component" == true ]] || [[ -f "$project_dir/requirements.txt" ]]; then
        if [[ "$is_python_component" == true ]]; then
            add_python_dependencies "$project_dir" "$component"
        fi
    fi
    
    # Handle Node.js dependencies
    if [[ "$is_nodejs_component" == true ]] || [[ -f "$project_dir/package.json" ]]; then
        if [[ "$is_nodejs_component" == true ]]; then
            add_nodejs_dependencies "$project_dir" "$component"
        fi
    fi
    
    # Handle template-based dependencies
    if [[ -n "$TEMPLATE" ]]; then
        case "$TEMPLATE" in
            "data-science")
                add_python_dependencies "$project_dir" "data-science"
                ;;
            "ai-llm")
                add_python_dependencies "$project_dir" "ai-llm"
                ;;
            "web-scraping")
                add_python_dependencies "$project_dir" "web-scraping"
                ;;
            "api-development")
                add_python_dependencies "$project_dir" "api-development"
                ;;
        esac
    fi
}

# Function to sort and clean requirements.txt
function sort_requirements() {
    local requirements_file="$1"
    
    if [[ -f "$requirements_file" ]]; then
        local temp_file=$(mktemp)
        
        # Sort requirements.txt and remove duplicates
        sort -u "$requirements_file" > "$temp_file"
        mv "$temp_file" "$requirements_file"
        
        print_debug "Sorted and cleaned requirements.txt"
    fi
}

# Function to format package.json
function format_package_json() {
    local package_json="$1"
    
    if [[ -f "$package_json" ]] && command -v jq >/dev/null 2>&1; then
        local temp_file=$(mktemp)
        
        # Format package.json with jq if available
        jq . "$package_json" > "$temp_file" 2>/dev/null && mv "$temp_file" "$package_json"
        
        print_debug "Formatted package.json"
    fi
}

# Function to show dependency summary
function show_dependency_summary() {
    local project_dir="$1"
    local requirements_file="$project_dir/requirements.txt"
    local package_json="$project_dir/package.json"
    
    if [[ "$WITH_DEPS" == "true" ]]; then
        print_info "Dependency Management Summary:"
        
        if [[ -f "$requirements_file" ]]; then
            local py_count=$(wc -l < "$requirements_file")
            print_status "Python packages: $py_count dependencies in requirements.txt"
        fi
        
        if [[ -f "$package_json" ]]; then
            local node_deps=0
            local node_dev_deps=0
            
            if grep -q "\"dependencies\"" "$package_json"; then
                node_deps=$(grep -c "\".*\":" "$package_json" | head -1 || echo 0)
            fi
            
            if grep -q "\"devDependencies\"" "$package_json"; then
                node_dev_deps=$(grep -c "\".*\":" "$package_json" | tail -1 || echo 0)
            fi
            
            if [[ $node_deps -gt 0 ]] || [[ $node_dev_deps -gt 0 ]]; then
                print_status "Node.js packages: $node_deps dependencies, $node_dev_deps dev dependencies in package.json"
            fi
        fi
        
        print_info "Run 'pip install -r requirements.txt' to install Python dependencies"
        if [[ -f "$package_json" ]]; then
            print_info "Run 'npm install' to install Node.js dependencies"
        fi
    fi
}

# Function to create dependency installation scripts
function create_dependency_scripts() {
    local project_dir="$1"
    
    if [[ "$WITH_DEPS" == "true" ]]; then
        # Create setup script for Python dependencies
        if [[ -f "$project_dir/requirements.txt" ]]; then
            cat > "$project_dir/setup-python-deps.sh" << 'EOF'
#!/bin/bash
# Setup script for Python dependencies

set -e

echo "Setting up Python dependencies..."

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed"
    exit 1
fi

# Check if pip is available
if ! command -v pip3 &> /dev/null; then
    echo "Error: pip3 is not installed"
    exit 1
fi

# Install dependencies
echo "Installing Python dependencies from requirements.txt..."
pip3 install -r requirements.txt

echo "Python dependencies installed successfully!"
EOF
            chmod +x "$project_dir/setup-python-deps.sh"
            print_debug "Created setup-python-deps.sh"
        fi
        
        # Create setup script for Node.js dependencies
        if [[ -f "$project_dir/package.json" ]]; then
            cat > "$project_dir/setup-nodejs-deps.sh" << 'EOF'
#!/bin/bash
# Setup script for Node.js dependencies

set -e

echo "Setting up Node.js dependencies..."

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed"
    exit 1
fi

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo "Error: npm is not installed"
    exit 1
fi

# Install dependencies
echo "Installing Node.js dependencies from package.json..."
npm install

echo "Node.js dependencies installed successfully!"
EOF
            chmod +x "$project_dir/setup-nodejs-deps.sh"
            print_debug "Created setup-nodejs-deps.sh"
        fi
    fi
}