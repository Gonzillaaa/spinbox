#!/bin/bash
# Next.js component generator for Spinbox
# Creates Next.js frontend with TypeScript, Tailwind CSS, and development tools

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/version-config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/dependency-manager.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/docker-hub.sh"

# Generate Next.js frontend component
function generate_nextjs_component() {
    local project_dir="$1"
    
    # Determine target directory based on component configuration
    local nextjs_dir
    if [[ "$USE_FASTAPI" == false && "$USE_NODE" == false && "$USE_PYTHON" == false ]]; then
        # Next.js is the only component - generate at root level
        nextjs_dir="$project_dir"
    else
        # Multi-component project - generate in subdirectory
        nextjs_dir="$project_dir/nextjs"
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would generate Next.js frontend component"
        return 0
    fi
    
    print_status "Creating Next.js frontend component..."
    
    # Ensure frontend directory exists
    safe_create_dir "$nextjs_dir"
    safe_create_dir "$nextjs_dir/src"
    safe_create_dir "$nextjs_dir/src/app"
    safe_create_dir "$nextjs_dir/src/components"
    safe_create_dir "$nextjs_dir/src/lib"
    safe_create_dir "$nextjs_dir/public"
    
    # Generate frontend files
    generate_nextjs_dockerfiles "$nextjs_dir"
    generate_nextjs_package_json "$nextjs_dir"
    generate_nextjs_config_files "$nextjs_dir"
    generate_nextjs_application "$nextjs_dir"
    generate_nextjs_components "$nextjs_dir"
    generate_nextjs_styles "$nextjs_dir"
    
    # Manage dependencies if --with-deps flag is enabled
    manage_component_dependencies "$project_dir" "nextjs"
    
    print_status "Next.js frontend component created successfully"
}

# Generate Docker configuration for frontend
function generate_nextjs_dockerfiles() {
    local nextjs_dir="$1"
    
    # Check if we should use Docker Hub optimized images
    if should_use_docker_hub "nextjs"; then
        generate_nextjs_dockerhub_config "$nextjs_dir"
    else
        generate_nextjs_local_dockerfiles "$nextjs_dir"
    fi
}

# Generate Docker Hub configuration for NextJS
function generate_nextjs_dockerhub_config() {
    local nextjs_dir="$1"
    local image_name=$(get_component_image "nextjs")

    print_debug "Generating NextJS configuration with Docker Hub image: $image_name"

    # Create minimal Dockerfile.dev that uses the pre-built base image
    cat > "$nextjs_dir/Dockerfile.dev" << EOF
# Next.js Development Container (Docker Hub optimized)
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

WORKDIR /app
RUN chown \$USERNAME:\$USERNAME /app

# The base image contains:
# - Node.js 20 with npm package manager
# - Development tools (git, zsh, oh-my-zsh, powerlevel10k, nano, tree, jq, htop)
# - Development aliases and environment setup
# Application dependencies will be installed via package.json

# Copy package files and install dependencies using npm
COPY --chown=\$USERNAME:\$USERNAME package.json package-lock.json* ./
USER \$USERNAME
RUN npm install

# Add Next.js development aliases
RUN echo '# Next.js Development aliases' >> ~/.zshrc \\
    && echo 'alias dev="npm run dev"' >> ~/.zshrc \\
    && echo 'alias build="npm run build"' >> ~/.zshrc \\
    && echo 'alias lint="npm run lint"' >> ~/.zshrc \\
    && echo 'alias test="npm test"' >> ~/.zshrc \\
    && echo 'alias type-check="npm run type-check"' >> ~/.zshrc

EXPOSE 3000

# Keep container running for development
CMD ["zsh", "-c", "while sleep 1000; do :; done"]
EOF

    # Production Dockerfile (still uses local build for production)
    local node_version=$(get_effective_node_version)
    cat > "$nextjs_dir/Dockerfile" << EOF
FROM node:${node_version}-alpine AS deps

WORKDIR /app

# Install dependencies
COPY package.json package-lock.json* ./
RUN npm ci --only=production

FROM node:${node_version}-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:${node_version}-alpine AS runner

WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
EOF

    # Generate common .dockerignore file
    generate_nextjs_dockerignore "$nextjs_dir"
}

# Generate local Docker configuration for NextJS (fallback mode)
function generate_nextjs_local_dockerfiles() {
    local nextjs_dir="$1"
    local node_version=$(get_effective_node_version)

    print_debug "Generating NextJS configuration with local builds"

    # Development Dockerfile (original implementation)
    cat > "$nextjs_dir/Dockerfile.dev" << EOF
FROM node:${node_version}-alpine

# Install system dependencies including Zsh
RUN apk add --no-cache \\
    git \\
    zsh \\
    curl \\
    shadow \\
    util-linux \\
    sudo \\
    vim

# Create non-root user for development
ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=\$USER_UID

RUN addgroup -g \$USER_GID \$USERNAME \\
    && adduser -D -u \$USER_UID -G \$USERNAME -s /bin/zsh \$USERNAME \\
    && echo "\$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/\$USERNAME \\
    && chmod 0440 /etc/sudoers.d/\$USERNAME

# Install Oh My Zsh and Powerlevel10k for non-root user
USER \$USERNAME
RUN sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \\
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# Install Zsh plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions \\
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# Configure Zsh
RUN sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\\/powerlevel10k"/g' ~/.zshrc \\
    && sed -i 's/plugins=(git)/plugins=(git docker npm node)/g' ~/.zshrc \\
    && echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> ~/.zshrc

# Add development aliases
RUN echo '# Development aliases' >> ~/.zshrc \\
    && echo 'alias dev="npm run dev"' >> ~/.zshrc \\
    && echo 'alias build="npm run build"' >> ~/.zshrc \\
    && echo 'alias lint="npm run lint"' >> ~/.zshrc \\
    && echo 'alias test="npm test"' >> ~/.zshrc

# Create app directory with correct ownership
USER root
WORKDIR /app
RUN chown \$USERNAME:\$USERNAME /app

EXPOSE 3000

# Set Zsh as default shell
SHELL ["/bin/zsh", "-c"]

# Set default user
USER \$USERNAME

# Keep container running for development
CMD ["zsh", "-c", "npm run dev"]
EOF

    # Production Dockerfile
    cat > "$nextjs_dir/Dockerfile" << EOF
FROM node:${node_version}-alpine AS deps

WORKDIR /app

# Install dependencies
COPY package.json package-lock.json* ./
RUN npm ci --only=production

FROM node:${node_version}-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:${node_version}-alpine AS runner

WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
EOF

    # Generate common .dockerignore file
    generate_nextjs_dockerignore "$nextjs_dir"
}

# Generate .dockerignore file for NextJS projects
function generate_nextjs_dockerignore() {
    local nextjs_dir="$1"
    
    # Docker ignore file
    cat > "$nextjs_dir/.dockerignore" << 'EOF'
node_modules
.next
.git
*.md
Dockerfile*
docker-compose*
.env*.local
EOF

    print_debug "Generated frontend Docker configuration"
}

# Generate package.json and related Node.js configuration
function generate_nextjs_package_json() {
    local nextjs_dir="$1"
    local project_name=$(echo "${PROJECT_NAME:-frontend-app}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    
    cat > "$nextjs_dir/package.json" << EOF
{
  "name": "$project_name",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "type-check": "tsc --noEmit",
    "test": "jest",
    "test:watch": "jest --watch"
  },
  "dependencies": {
    "next": "14.0.4",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "clsx": "^2.0.0",
    "lucide-react": "^0.303.0"
  },
  "devDependencies": {
    "@types/node": "^20.10.5",
    "@types/react": "^18.2.45",
    "@types/react-dom": "^18.2.18",
    "@typescript-eslint/eslint-plugin": "^6.15.0",
    "@typescript-eslint/parser": "^6.15.0",
    "autoprefixer": "^10.4.16",
    "eslint": "^8.56.0",
    "eslint-config-next": "14.0.4",
    "postcss": "^8.4.32",
    "tailwindcss": "^3.4.0",
    "typescript": "^5.3.3",
    "jest": "^29.7.0",
    "@testing-library/react": "^14.1.2",
    "@testing-library/jest-dom": "^6.1.6"
  },
  "engines": {
    "node": ">=$(get_effective_node_version)"
  }
}
EOF

    print_debug "Generated package.json"
}

# Generate configuration files (Next.js, TypeScript, Tailwind)
function generate_nextjs_config_files() {
    local nextjs_dir="$1"
    
    # Next.js configuration
    cat > "$nextjs_dir/next.config.js" << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  // Note: In Next.js 14, App Router is enabled by default (no experimental flag needed)
  async rewrites() {
    // Only add API rewrites if BACKEND_URL is configured
    const backendUrl = process.env.BACKEND_URL
    if (!backendUrl) {
      return []
    }
    return [
      {
        source: '/api/:path*',
        destination: `${backendUrl}/api/:path*`,
      },
    ]
  },
}

module.exports = nextConfig
EOF

    # TypeScript configuration
    cat > "$nextjs_dir/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "es6"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

    # Tailwind CSS configuration
    cat > "$nextjs_dir/tailwind.config.js" << 'EOF'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        border: 'hsl(var(--border))',
      },
    },
  },
  plugins: [],
}
EOF

    # PostCSS configuration
    cat > "$nextjs_dir/postcss.config.js" << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

    # ESLint configuration
    cat > "$nextjs_dir/.eslintrc.json" << 'EOF'
{
  "extends": ["next/core-web-vitals", "@typescript-eslint/recommended"],
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint"],
  "rules": {
    "@typescript-eslint/no-unused-vars": "error",
    "@typescript-eslint/no-explicit-any": "warn"
  }
}
EOF

    # Environment files - use security template
    local env_template="$PROJECT_ROOT/templates/security/nextjs.env.example"
    if [[ -f "$env_template" ]]; then
        cp "$env_template" "$nextjs_dir/.env.local.example"
    else
        # Fallback to basic template
        cat > "$nextjs_dir/.env.local.example" << 'EOF'
# API Configuration
NEXT_PUBLIC_API_URL=http://localhost:8000
BACKEND_URL=http://backend:8000

# App Configuration
NEXT_PUBLIC_APP_NAME="Next.js App"
EOF
    fi


    # Copy Next.js .gitignore
    local gitignore_template="$PROJECT_ROOT/templates/security/nextjs.gitignore"
    if [[ -f "$gitignore_template" ]]; then
        cp "$gitignore_template" "$nextjs_dir/.gitignore"
    fi

    print_debug "Generated configuration files"
}

# Generate main Next.js application structure
function generate_nextjs_application() {
    local nextjs_dir="$1"
    local src_dir="$nextjs_dir/src"
    local app_dir="$src_dir/app"
    
    # App layout
    cat > "$app_dir/layout.tsx" << 'EOF'
import './globals.css'
import { Inter } from 'next/font/google'

const inter = Inter({ subsets: ['latin'] })

export const metadata = {
  title: 'Next.js App',
  description: 'Generated by Spinbox',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  )
}
EOF

    # Home page
    cat > "$app_dir/page.tsx" << 'EOF'
import { ApiStatus } from '@/components/ApiStatus'
import { Button } from '@/components/ui/Button'

export default function Home() {
  return (
    <main className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 dark:from-gray-900 dark:to-gray-800">
      <div className="container mx-auto px-4 py-16">
        <div className="text-center">
          <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-6">
            Welcome to Your App
          </h1>
          <p className="text-lg text-gray-600 dark:text-gray-300 mb-8">
            Your Next.js application is ready! Start building something amazing.
          </p>
          
          <div className="space-y-4 mb-12">
            <Button href="/api/docs" variant="primary">
              View API Documentation
            </Button>
            <Button href="https://nextjs.org/docs" variant="secondary" external>
              Next.js Documentation
            </Button>
          </div>

          <ApiStatus />
        </div>
      </div>
    </main>
  )
}
EOF

    # API route example
    safe_create_dir "$app_dir/api"
    safe_create_dir "$app_dir/api/health"
    cat > "$app_dir/api/health/route.ts" << 'EOF'
import { NextResponse } from 'next/server'

export async function GET() {
  return NextResponse.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'frontend'
  })
}
EOF

    print_debug "Generated Next.js application structure"
}

# Generate reusable components
function generate_nextjs_components() {
    local nextjs_dir="$1"
    local components_dir="$nextjs_dir/src/components"
    
    # UI components directory
    safe_create_dir "$components_dir/ui"
    
    # Button component
    cat > "$components_dir/ui/Button.tsx" << 'EOF'
import React from 'react'
import Link from 'next/link'
import { clsx } from 'clsx'

interface ButtonProps {
  children: React.ReactNode
  variant?: 'primary' | 'secondary' | 'outline'
  size?: 'sm' | 'md' | 'lg'
  href?: string
  external?: boolean
  className?: string
  onClick?: () => void
  disabled?: boolean
  type?: 'button' | 'submit' | 'reset'
}

export function Button({
  children,
  variant = 'primary',
  size = 'md',
  href,
  external = false,
  className,
  onClick,
  disabled = false,
  type = 'button',
}: ButtonProps) {
  const baseClasses = 'inline-flex items-center justify-center font-medium rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2'
  
  const variantClasses = {
    primary: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500',
    secondary: 'bg-gray-600 text-white hover:bg-gray-700 focus:ring-gray-500',
    outline: 'border border-gray-300 text-gray-700 hover:bg-gray-50 focus:ring-blue-500',
  }
  
  const sizeClasses = {
    sm: 'px-3 py-2 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg',
  }
  
  const classes = clsx(
    baseClasses,
    variantClasses[variant],
    sizeClasses[size],
    disabled && 'opacity-50 cursor-not-allowed',
    className
  )

  if (href) {
    if (external) {
      return (
        <a
          href={href}
          target="_blank"
          rel="noopener noreferrer"
          className={classes}
        >
          {children}
        </a>
      )
    }
    
    return (
      <Link href={href} className={classes}>
        {children}
      </Link>
    )
  }

  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={classes}
    >
      {children}
    </button>
  )
}
EOF

    # API Status component
    cat > "$components_dir/ApiStatus.tsx" << 'EOF'
'use client'

import { useEffect, useState } from 'react'

interface ApiStatusProps {
  className?: string
}

interface HealthStatus {
  status: string
  service?: string
  timestamp?: string
}

export function ApiStatus({ className }: ApiStatusProps) {
  const [backendStatus, setBackendStatus] = useState<HealthStatus | null>(null)
  const [frontendStatus, setFrontendStatus] = useState<HealthStatus | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const checkStatus = async () => {
      try {
        // Check frontend health
        const frontendResponse = await fetch('/api/health')
        const frontendData = await frontendResponse.json()
        setFrontendStatus(frontendData)

        // Check backend health
        try {
          const backendResponse = await fetch('/api/health', {
            headers: { 'X-Proxy-To': 'backend' }
          })
          const backendData = await backendResponse.json()
          setBackendStatus(backendData)
        } catch (error) {
          setBackendStatus({ status: 'error' })
        }
      } catch (error) {
        setFrontendStatus({ status: 'error' })
      } finally {
        setLoading(false)
      }
    }

    checkStatus()
  }, [])

  if (loading) {
    return (
      <div className={`text-center ${className}`}>
        <div className="inline-block animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
        <p className="mt-2 text-sm text-gray-500">Checking service status...</p>
      </div>
    )
  }

  return (
    <div className={`space-y-4 ${className}`}>
      <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
        Service Status
      </h3>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow">
          <div className="flex items-center space-x-2">
            <div className={`w-3 h-3 rounded-full ${
              frontendStatus?.status === 'healthy' ? 'bg-green-500' : 'bg-red-500'
            }`} />
            <span className="font-medium">Frontend</span>
          </div>
          <p className="text-sm text-gray-500 mt-1">
            Status: {frontendStatus?.status || 'Unknown'}
          </p>
        </div>
        
        <div className="bg-white dark:bg-gray-800 rounded-lg p-4 shadow">
          <div className="flex items-center space-x-2">
            <div className={`w-3 h-3 rounded-full ${
              backendStatus?.status === 'healthy' ? 'bg-green-500' : 'bg-red-500'
            }`} />
            <span className="font-medium">Backend</span>
          </div>
          <p className="text-sm text-gray-500 mt-1">
            Status: {backendStatus?.status || 'Unavailable'}
          </p>
        </div>
      </div>
    </div>
  )
}
EOF

    print_debug "Generated frontend components"
}

# Generate styles and global CSS
function generate_nextjs_styles() {
    local nextjs_dir="$1"
    local app_dir="$nextjs_dir/src/app"
    
    cat > "$app_dir/globals.css" << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --background: 0 0% 100%;
  --foreground: 222.2 84% 4.9%;
  --primary: 221.2 83.2% 53.3%;
  --primary-foreground: 210 40% 98%;
  --secondary: 210 40% 96%;
  --secondary-foreground: 222.2 84% 4.9%;
  --muted: 210 40% 96%;
  --muted-foreground: 215.4 16.3% 46.9%;
  --border: 214.3 31.8% 91.4%;
}

.dark {
  --background: 222.2 84% 4.9%;
  --foreground: 210 40% 98%;
  --primary: 217.2 91.2% 59.8%;
  --primary-foreground: 222.2 84% 4.9%;
  --secondary: 217.2 32.6% 17.5%;
  --secondary-foreground: 210 40% 98%;
  --muted: 217.2 32.6% 17.5%;
  --muted-foreground: 215 20.2% 65.1%;
  --border: 217.2 32.6% 17.5%;
}

* {
  border-color: hsl(var(--border));
}

body {
  color: hsl(var(--foreground));
  background: hsl(var(--background));
}
EOF

    print_debug "Generated frontend styles"
}

# Main function to create frontend component
function create_nextjs_component() {
    local project_dir="$1"
    
    print_info "Creating Next.js frontend component in $project_dir"
    
    generate_nextjs_component "$project_dir"
    
    print_status "Next.js frontend component created successfully!"
    print_info "Next steps:"
    if [[ "$USE_FASTAPI" == false && "$USE_NODE" == false && "$USE_PYTHON" == false ]]; then
        echo "  1. cd $(basename "$project_dir")"
        echo "  2. Open in VS Code: code ."
        echo "  3. Reopen in DevContainer when prompted"
        echo "  4. Install dependencies: npm install"
        echo "  5. Start development server: npm run dev"
        echo "  6. Open http://localhost:3000 in your browser"
    else
        echo "  1. cd $(basename "$project_dir")/nextjs"
        echo "  2. Install dependencies: npm install"
        echo "  3. Start development server: npm run dev"
        echo "  4. Open http://localhost:3000 in your browser"
    fi
}

# Export functions for use by project generator
export -f generate_nextjs_component create_nextjs_component
export -f generate_nextjs_dockerfiles generate_nextjs_package_json
export -f generate_nextjs_config_files generate_nextjs_application
export -f generate_nextjs_components generate_nextjs_styles