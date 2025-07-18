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

echo "Development environment setup complete!"
