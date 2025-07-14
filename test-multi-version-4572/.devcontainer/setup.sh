#!/bin/bash
# DevContainer setup script
# Runs after container creation

echo "Setting up development environment..."

# Set up git configuration if not already set
if [ -z "$(git config --global user.name)" ]; then
    echo "Setting up git configuration..."
    read -p "Enter your name: " git_name
    read -p "Enter your email: " git_email
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
fi

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

# Install Node.js dependencies
if [ -f "package.json" ]; then
    echo "Installing Node.js dependencies..."
    npm install
fi

echo "Development environment setup complete!"
