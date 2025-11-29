#!/bin/bash
# Minimal Python project generator for Spinbox
# Creates a bare-bones Python DevContainer setup

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/version-config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/dependency-manager.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/docker-hub.sh"

# Generate minimal Python DevContainer
function generate_minimal_python_devcontainer() {
    local project_dir="$1"
    local devcontainer_dir="$project_dir/.devcontainer"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would generate minimal Python DevContainer"
        return 0
    fi
    
    safe_create_dir "$devcontainer_dir"
    
    # Check if we should use Docker Hub optimized images
    if should_use_docker_hub "python"; then
        generate_python_dockerhub_config "$devcontainer_dir"
    else
        generate_python_local_dockerfiles "$devcontainer_dir"
    fi
    
    print_status "Generated minimal Python DevContainer"
}

# Generate Docker Hub configuration for Python
function generate_python_dockerhub_config() {
    local devcontainer_dir="$1"
    local image_name=$(get_component_image "python")

    print_debug "Generating Python configuration with Docker Hub image: $image_name"

    # Generate minimal devcontainer.json
    cat > "$devcontainer_dir/devcontainer.json" << EOF
{
    "name": "$PROJECT_NAME - Python DevContainer",
    "dockerFile": "Dockerfile",
    "remoteUser": "developer",
    "containerUser": "developer",
    "customizations": {
        "vscode": {
            "settings": {
                "terminal.integrated.shell.linux": "/bin/zsh",
                "python.defaultInterpreterPath": "/workspace/venv/bin/python"
            },
            "extensions": [
                "ms-python.python",
                "ms-python.pylint",
                "ms-python.black-formatter",
                "ms-python.isort"
            ]
        }
    },
    "postCreateCommand": "bash .devcontainer/setup.sh",
    "mounts": [
        "source=\${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
    ],
    "workspaceFolder": "/workspace",
    "shutdownAction": "stopContainer"
}
EOF
    
    # Create minimal Dockerfile that uses the pre-built base image
    cat > "$devcontainer_dir/Dockerfile" << EOF
# Minimal Python DevContainer (Docker Hub optimized)
# Uses pre-built base image: ${image_name}:latest
FROM ${image_name}:latest

# Create non-root user for development
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=\$USER_UID

RUN groupadd --gid \$USER_GID \$USERNAME \\
    && useradd --uid \$USER_UID --gid \$USER_GID -m \$USERNAME -s /bin/zsh \\
    && apt-get update && apt-get install -y sudo vim \\
    && echo \$USERNAME ALL=\\(root\\) NOPASSWD:ALL > /etc/sudoers.d/\$USERNAME \\
    && chmod 0440 /etc/sudoers.d/\$USERNAME \\
    && rm -rf /var/lib/apt/lists/*

# Set up Oh My Zsh and shell config for non-root user
RUN cp -r /root/.oh-my-zsh /home/\$USERNAME/.oh-my-zsh \\
    && cp /root/.zshrc /home/\$USERNAME/.zshrc \\
    && chown -R \$USERNAME:\$USERNAME /home/\$USERNAME/.oh-my-zsh \\
    && chown \$USERNAME:\$USERNAME /home/\$USERNAME/.zshrc \\
    && sed -i "s|/root|/home/\$USERNAME|g" /home/\$USERNAME/.zshrc

WORKDIR /workspace

# The base image contains:
# - Python 3.11 with UV package manager
# - Development tools (git, zsh, oh-my-zsh, powerlevel10k, nano, tree, jq, htop)
# - Development aliases and environment setup
# Application dependencies will be installed via requirements.txt

# Create Python virtual environment with correct ownership
RUN python -m venv venv && chown -R \$USERNAME:\$USERNAME venv
ENV PATH="/workspace/venv/bin:\$PATH"

# Copy requirements and install dependencies using UV
COPY requirements.txt ./
RUN uv pip install -r requirements.txt

# Add Python development aliases for non-root user
USER \$USERNAME
RUN echo '# Python Development aliases' >> ~/.zshrc \\
    && echo 'alias venv="source venv/bin/activate"' >> ~/.zshrc \\
    && echo 'alias pytest-run="pytest"' >> ~/.zshrc \\
    && echo 'alias format="black . && isort ."' >> ~/.zshrc \\
    && echo 'alias lint="pylint *.py"' >> ~/.zshrc \\
    && echo 'alias uvinstall="uv pip install"' >> ~/.zshrc

# Activate virtual environment on shell start
RUN echo 'if [[ -f /workspace/venv/bin/activate ]]; then source /workspace/venv/bin/activate; fi' >> ~/.zshrc

# Switch back to root for setup script (will run as developer via devcontainer.json)
USER root

# Copy and run setup script
COPY setup.sh /setup.sh
RUN chmod +x /setup.sh

# Set default user
USER \$USERNAME

# Keep container running for development
CMD ["zsh", "-c", "while sleep 1000; do :; done"]
EOF

    # Generate common setup script for both modes
    generate_python_setup_script "$devcontainer_dir"
}

# Generate local Docker configuration for Python (fallback mode)
function generate_python_local_dockerfiles() {
    local devcontainer_dir="$1"
    local python_version=$(get_effective_python_version)
    local python_image=$(get_python_image_tag)

    print_debug "Generating Python configuration with local builds"

    # Generate minimal devcontainer.json
    cat > "$devcontainer_dir/devcontainer.json" << EOF
{
    "name": "$PROJECT_NAME - Python DevContainer",
    "dockerFile": "Dockerfile",
    "remoteUser": "developer",
    "containerUser": "developer",
    "customizations": {
        "vscode": {
            "settings": {
                "terminal.integrated.shell.linux": "/bin/zsh",
                "python.defaultInterpreterPath": "/workspace/venv/bin/python"
            },
            "extensions": [
                "ms-python.python",
                "ms-python.pylint",
                "ms-python.black-formatter",
                "ms-python.isort"
            ]
        }
    },
    "postCreateCommand": "bash .devcontainer/setup.sh",
    "mounts": [
        "source=\${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
    ],
    "workspaceFolder": "/workspace",
    "shutdownAction": "stopContainer"
}
EOF

    # Generate minimal Dockerfile (original implementation)
    cat > "$devcontainer_dir/Dockerfile" << EOF
# Minimal Python DevContainer
# Generated by Spinbox on $(date)

FROM $python_image

# Install system dependencies
RUN apt-get update && apt-get install -y \\
    git \\
    curl \\
    build-essential \\
    zsh \\
    sudo \\
    vim \\
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for development
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=\$USER_UID

RUN groupadd --gid \$USER_GID \$USERNAME \\
    && useradd --uid \$USER_UID --gid \$USER_GID -m \$USERNAME -s /bin/zsh \\
    && echo \$USERNAME ALL=\\(root\\) NOPASSWD:ALL > /etc/sudoers.d/\$USERNAME \\
    && chmod 0440 /etc/sudoers.d/\$USERNAME

# Install UV for fast Python package management
RUN pip install --no-cache-dir uv

# Install Oh My Zsh and Powerlevel10k for non-root user
USER \$USERNAME
RUN sh -c "\$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \\
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# Configure Zsh with Powerlevel10k theme and config
COPY --chown=\$USERNAME:\$USERNAME p10k.zsh /home/\$USERNAME/.p10k.zsh
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\\/powerlevel10k"/g' ~/.zshrc \\
    && echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc

# Set Zsh as default shell
USER root
RUN chsh -s /bin/zsh \$USERNAME
ENV SHELL=/bin/zsh

# Create workspace directory with correct ownership
WORKDIR /workspace
RUN chown \$USERNAME:\$USERNAME /workspace

# Copy and run setup script
COPY setup.sh /setup.sh
RUN chmod +x /setup.sh

# Set default user
USER \$USERNAME
EOF

    # Generate common setup script for both modes
    generate_python_setup_script "$devcontainer_dir"
}

# Generate common setup script for Python DevContainer
function generate_python_setup_script() {
    local devcontainer_dir="$1"
    
    cat > "$devcontainer_dir/setup.sh" << 'EOF'
#!/bin/bash
# Minimal Python DevContainer setup script

echo "Setting up minimal Python development environment..."

# Create Python virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip and install UV in venv
pip install --upgrade pip
pip install uv

# Install dependencies if requirements.txt exists
if [ -f "requirements.txt" ]; then
    echo "Installing Python dependencies with UV..."
    uv pip install -r requirements.txt
else
    echo "No requirements.txt found, installing basic development tools..."
    uv pip install pytest black isort python-dotenv requests
fi

# Set up git hooks directory
mkdir -p .git/hooks

# Create basic .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'GITIGNORE'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
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
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
venv/
env/
ENV/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Environment variables
.env
.env.local
.env.*.local
GITIGNORE
fi

echo "Minimal Python environment setup complete!"
echo ""
echo "Available commands:"
echo "  source venv/bin/activate  # Activate virtual environment"
echo "  uv pip install <package>  # Install Python packages"
echo "  pytest                    # Run tests"
echo "  black .                   # Format code"
echo ""
EOF

    chmod +x "$devcontainer_dir/setup.sh"

    # Copy Powerlevel10k configuration
    local p10k_template="$PROJECT_ROOT/templates/shell/p10k.zsh"
    if [[ -f "$p10k_template" ]]; then
        cp "$p10k_template" "$devcontainer_dir/p10k.zsh"
    fi
}

# Generate minimal Python project files
function generate_minimal_python_files() {
    local project_dir="$1"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would generate minimal Python project files"
        return 0
    fi
    
    # Generate requirements.txt
    local template_name="${TEMPLATE_NAME:-minimal}"
    local template_file="$PROJECT_ROOT/templates/requirements/$template_name.txt"
    
    if [[ -f "$template_file" ]]; then
        cp "$template_file" "$project_dir/requirements.txt"
        print_debug "Used requirements template: $template_name"
    else
        cat > "$project_dir/requirements.txt" << EOF
# Minimal Python development dependencies
# Generated by Spinbox on $(date)

# Package management
uv>=0.1.0

# Testing
pytest>=7.0.0
pytest-cov>=4.0.0

# Code formatting and linting
black>=23.0.0
isort>=5.12.0
pylint>=2.17.0

# Environment and utilities
python-dotenv>=1.0.0
requests>=2.28.0
EOF
    fi
    
    # Create src directory structure
    safe_create_dir "$project_dir/src"
    safe_create_dir "$project_dir/tests"
    
    # Generate basic module in src
    cat > "$project_dir/src/__init__.py" << EOF
"""
$PROJECT_NAME package
Generated by Spinbox on $(date)
"""

__version__ = "0.1.0"
EOF
    
    cat > "$project_dir/src/core.py" << EOF
"""
Core module for $PROJECT_NAME
Generated by Spinbox on $(date)
"""

def hello_world():
    """Return a greeting message."""
    return "Hello from $PROJECT_NAME!"

def main():
    """Main function for the package."""
    print(hello_world())
    return True

if __name__ == "__main__":
    main()
EOF
    
    # Generate basic main.py
    cat > "$project_dir/main.py" << EOF
"""
Main entry point for $PROJECT_NAME
Generated by Spinbox on $(date)
"""

from src.core import main as core_main

def main():
    """Main function."""
    print("Welcome to $PROJECT_NAME!")
    print("Your minimal Python environment is ready!")
    core_main()

if __name__ == "__main__":
    main()
EOF
    
    # Generate basic test file
    cat > "$project_dir/tests/test_main.py" << EOF
"""
Tests for $PROJECT_NAME
Generated by Spinbox on $(date)
"""

import pytest
import sys
from pathlib import Path

# Add the project root to Python path for imports
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

def test_main_imports():
    """Test that main module can be imported."""
    import main
    assert hasattr(main, 'main')

def test_src_core_imports():
    """Test that src.core module can be imported."""
    from src.core import hello_world, main as core_main
    assert callable(hello_world)
    assert callable(core_main)

def test_hello_world():
    """Test hello_world function."""
    from src.core import hello_world
    result = hello_world()
    assert isinstance(result, str)
    assert "$PROJECT_NAME" in result

def test_core_main_function():
    """Test core main function."""
    from src.core import main as core_main
    result = core_main()
    assert result is True

if __name__ == "__main__":
    pytest.main([__file__])
EOF
    
    # Generate pytest configuration
    cat > "$project_dir/pytest.ini" << EOF
[tool:pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = --verbose --tb=short
EOF
    
    # Generate basic README
    cat > "$project_dir/README.md" << EOF
# $PROJECT_NAME

A minimal Python project created with Spinbox.

## Development Environment

This project uses DevContainers for a consistent development environment.

### Getting Started

1. Open this project in VS Code or Cursor
2. When prompted, click "Reopen in Container"
3. Wait for the DevContainer to build and start
4. The Python virtual environment will be automatically created

### Available Commands

\`\`\`bash
# Activate virtual environment (auto-activated in DevContainer)
source venv/bin/activate

# Install packages
uv pip install <package-name>

# Run the main script
python main.py

# Run tests
pytest

# Format code
black .
isort .

# Lint code
pylint *.py
\`\`\`

### Project Structure

\`\`\`
$PROJECT_NAME/
├── .devcontainer/          # DevContainer configuration
├── tests/                  # Test files
├── venv/                   # Python virtual environment (created automatically)
├── main.py                 # Main application file
├── requirements.txt        # Python dependencies
├── pytest.ini            # Test configuration
└── README.md              # This file
\`\`\`

### Adding Dependencies

To add new Python packages:

\`\`\`bash
uv pip install <package-name>
uv pip freeze > requirements.txt  # Update requirements file
\`\`\`

---

Generated by [Spinbox](https://github.com/Gonzillaaa/spinbox) on $(date)
EOF
    
    # Create .gitignore file
    cat > "$project_dir/.gitignore" << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
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
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
venv/
env/
ENV/
.venv

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Environment variables
.env
.env.local
.env.*.local

# Testing
.coverage
.pytest_cache/
htmlcov/

# Documentation
docs/_build/
EOF
    
    print_status "Generated minimal Python project files"
}

# Main function to create minimal Python project
function create_minimal_python_project() {
    local project_dir="$1"
    
    print_info "Creating minimal Python project in $project_dir"
    
    # Generate DevContainer
    generate_minimal_python_devcontainer "$project_dir"
    
    # Generate project files
    generate_minimal_python_files "$project_dir"
    
    # Manage dependencies if --with-deps flag is enabled
    if [[ -n "$TEMPLATE" ]]; then
        manage_component_dependencies "$project_dir" "$TEMPLATE"
    fi

    print_status "Minimal Python project created successfully!"
    print_info "Next steps:"
    echo "  1. cd $(basename "$project_dir")"
    echo "  2. Open in VS Code: code . (or cursor .)"
    echo "  3. Reopen in DevContainer when prompted"
    echo "  4. Virtual environment auto-activates on terminal open"
    echo "  5. Start coding in main.py"
    echo "  6. Run your code: python main.py"
    echo "  7. Run tests: pytest"
}

# Export functions for use by project generator
export -f generate_minimal_python_devcontainer
export -f generate_minimal_python_files
export -f create_minimal_python_project