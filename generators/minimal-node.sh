#!/bin/bash
# Minimal Node.js project generator for Spinbox
# Creates a bare-bones Node.js DevContainer setup

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/version-config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/dependency-manager.sh"

# Generate minimal Node.js DevContainer
function generate_minimal_node_devcontainer() {
    local project_dir="$1"
    local devcontainer_dir="$project_dir/.devcontainer"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would generate minimal Node.js DevContainer"
        return 0
    fi
    
    safe_create_dir "$devcontainer_dir"
    
    local node_version=$(get_effective_node_version)
    local node_image=$(get_node_image_tag)
    
    # Generate minimal devcontainer.json
    cat > "$devcontainer_dir/devcontainer.json" << EOF
{
    "name": "$PROJECT_NAME - Node.js DevContainer",
    "dockerFile": "Dockerfile",
    "forwardPorts": [3000],
    "customizations": {
        "vscode": {
            "settings": {
                "terminal.integrated.shell.linux": "/bin/zsh"
            },
            "extensions": [
                "ms-vscode.vscode-typescript-next",
                "esbenp.prettier-vscode",
                "ms-vscode.vscode-json",
                "bradlc.vscode-tailwindcss"
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
    
    # Generate minimal Dockerfile
    cat > "$devcontainer_dir/Dockerfile" << EOF
# Minimal Node.js DevContainer
# Generated by Spinbox on $(date)

FROM $node_image

# Install system dependencies
RUN apk add --no-cache \\
    git \\
    curl \\
    zsh \\
    build-base \\
    python3 \\
    make \\
    g++

# Install Oh My Zsh and Powerlevel10k
RUN sh -c "\$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \\
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# Set up Zsh configuration
RUN echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> ~/.zshrc \\
    && echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> ~/.zshrc \\
    && echo 'source ~/.oh-my-zsh/oh-my-zsh.sh' >> ~/.zshrc

# Create workspace directory
WORKDIR /workspace

# Copy and run setup script
COPY setup.sh /setup.sh
RUN chmod +x /setup.sh
EOF
    
    # Generate setup script
    cat > "$devcontainer_dir/setup.sh" << 'EOF'
#!/bin/bash
# Minimal Node.js DevContainer setup script

echo "Setting up minimal Node.js development environment..."

# Update npm to latest version
npm install -g npm@latest

# Install global development tools
npm install -g typescript ts-node nodemon

# Install project dependencies if package.json exists
if [ -f "package.json" ]; then
    echo "Installing Node.js dependencies..."
    npm install
else
    echo "No package.json found, initializing basic Node.js project..."
    npm init -y
    
    # Install basic development dependencies
    npm install --save-dev typescript @types/node nodemon ts-node
    npm install express
fi

# Create basic tsconfig.json if it doesn't exist
if [ ! -f "tsconfig.json" ]; then
    cat > tsconfig.json << 'TSCONFIG'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
TSCONFIG
fi

# Create basic .gitignore if it doesn't exist
if [ ! -f ".gitignore" ]; then
    cat > .gitignore << 'GITIGNORE'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build outputs
dist/
build/
*.tsbuildinfo

# Environment variables
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
logs/
*.log

# Runtime data
pids/
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# Temporary folders
tmp/
temp/
GITIGNORE
fi

echo "Minimal Node.js environment setup complete!"
echo ""
echo "Available commands:"
echo "  npm run dev        # Start development server"
echo "  npm run build      # Build TypeScript to JavaScript"
echo "  npm test           # Run tests"
echo "  npm install <pkg>  # Install packages"
echo ""
EOF
    
    chmod +x "$devcontainer_dir/setup.sh"
    
    print_status "Generated minimal Node.js DevContainer"
}

# Generate minimal Node.js project files
function generate_minimal_node_files() {
    local project_dir="$1"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would generate minimal Node.js project files"
        return 0
    fi
    
    # Generate package.json
    cat > "$project_dir/package.json" << EOF
{
  "name": "$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')",
  "version": "1.0.0",
  "description": "A minimal Node.js project created with Spinbox",
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "dev": "nodemon --exec ts-node src/index.ts",
    "start": "node dist/index.js",
    "test": "echo \\"Error: no test specified\\" && exit 1",
    "lint": "echo \\"Linting not configured yet\\"",
    "clean": "rm -rf dist"
  },
  "keywords": ["nodejs", "typescript", "spinbox"],
  "author": "",
  "license": "MIT",
  "devDependencies": {
    "@types/node": "^20.0.0",
    "nodemon": "^3.0.0",
    "ts-node": "^10.9.0",
    "typescript": "^5.0.0"
  },
  "dependencies": {
    "express": "^4.18.0"
  },
  "engines": {
    "node": ">=$(get_effective_node_version)"
  }
}
EOF
    
    # Generate TypeScript configuration
    cat > "$project_dir/tsconfig.json" << EOF
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "**/*.test.ts"]
}
EOF
    
    # Create source directory and main file
    safe_create_dir "$project_dir/src"
    cat > "$project_dir/src/index.ts" << EOF
/**
 * Main entry point for $PROJECT_NAME
 * Generated by Spinbox on $(date)
 */

import express from 'express';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Hello from $PROJECT_NAME!',
    timestamp: new Date().toISOString(),
    environment: 'development'
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

// Start server
app.listen(PORT, () => {
  console.log(\`🚀 Server running on http://localhost:\${PORT}\`);
  console.log(\`📊 Health check: http://localhost:\${PORT}/health\`);
});

export default app;
EOF
    
    # Generate basic README
    cat > "$project_dir/README.md" << EOF
# $PROJECT_NAME

A minimal Node.js project created with Spinbox.

## Development Environment

This project uses DevContainers for a consistent development environment.

### Getting Started

1. Open this project in VS Code or Cursor
2. When prompted, click "Reopen in Container"
3. Wait for the DevContainer to build and start
4. Dependencies will be automatically installed

### Available Commands

\`\`\`bash
# Start development server (with auto-reload)
npm run dev

# Build TypeScript to JavaScript
npm run build

# Start production server
npm start

# Install new packages
npm install <package-name>

# Clean build artifacts
npm run clean
\`\`\`

### API Endpoints

- \`GET /\` - Hello world message
- \`GET /health\` - Health check endpoint

### Project Structure

\`\`\`
$PROJECT_NAME/
├── .devcontainer/          # DevContainer configuration
├── src/                    # TypeScript source files
│   └── index.ts           # Main application file
├── dist/                   # Compiled JavaScript (created by build)
├── node_modules/           # Dependencies (created by npm install)
├── package.json            # Project configuration and dependencies
├── tsconfig.json          # TypeScript configuration
└── README.md              # This file
\`\`\`

### Adding Dependencies

To add new Node.js packages:

\`\`\`bash
# Runtime dependency
npm install <package-name>

# Development dependency
npm install --save-dev <package-name>

# Type definitions
npm install --save-dev @types/<package-name>
\`\`\`

### Development Tips

- The development server runs on port 3000 by default
- Code changes trigger automatic reload in development mode
- TypeScript provides type checking during development
- Build the project before deploying to production

---

Generated by [Spinbox](https://github.com/Gonzillaaa/spinbox) on $(date)
EOF
    
    # Create .gitignore file
    cat > "$project_dir/.gitignore" << 'EOF'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
.nyc_output

# Grunt intermediate storage
.grunt

# node-waf configuration
.lock-wscript

# Compiled binary addons
build/Release

# Dependency directories
jspm_packages/

# TypeScript cache
*.tsbuildinfo

# Optional npm cache directory
.npm

# Optional eslint cache
.eslintcache

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variables file
.env
.env.test
.env.local
.env.production

# parcel-bundler cache
.cache
.parcel-cache

# next.js build output
.next

# nuxt.js build output
.nuxt

# vuepress build output
.vuepress/dist

# Serverless directories
.serverless

# FuseBox cache
.fusebox/

# DynamoDB Local files
.dynamodb/

# TernJS port file
.tern-port

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Build output
dist/
build/
EOF
    
    print_status "Generated minimal Node.js project files"
}

# Main function to create minimal Node.js project
function create_minimal_node_project() {
    local project_dir="$1"
    
    print_info "Creating minimal Node.js project in $project_dir"
    
    # Generate DevContainer
    generate_minimal_node_devcontainer "$project_dir"
    
    # Generate project files
    generate_minimal_node_files "$project_dir"
    
    # Manage dependencies if --with-deps flag is enabled
    # Note: Minimal Node.js setup doesn't have specific component dependencies
    # Dependencies are handled in the package.json creation
    
    print_status "Minimal Node.js project created successfully!"
    print_info "Next steps:"
    echo "  1. cd $(basename "$project_dir")"
    echo "  2. Open in VS Code: code ."
    echo "  3. Reopen in DevContainer when prompted"
    echo "  4. Start development server: npm run dev"
    echo "  5. Visit http://localhost:3000"
}

# Export functions for use by project generator
export -f generate_minimal_node_devcontainer
export -f generate_minimal_node_files
export -f create_minimal_node_project