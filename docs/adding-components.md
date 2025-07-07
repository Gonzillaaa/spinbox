# Adding Components to Existing Projects

This guide explains how to add new components to an existing project created with the project template.

## Overview

The project template supports modular architecture, allowing you to add components even after initial project creation. You can add:

- FastAPI Backend
- Next.js Frontend  
- PostgreSQL Database with PGVector
- Redis for caching and queues

## Methods for Adding Components

### Method 1: Using the Project Setup Script

The recommended approach is to use the project setup script to create a temporary project with only the desired component, then merge it into your existing project.

#### Steps:

1. **Create a temporary project with the desired component:**
   ```bash
   cd /tmp
   ./path/to/project-setup.sh
   # Select only the component you want to add
   ```

2. **Copy the component files to your existing project:**
   ```bash
   # For backend
   cp -r /tmp/temp-project/backend /path/to/your-project/
   
   # For frontend
   cp -r /tmp/temp-project/frontend /path/to/your-project/
   
   # For database
   cp -r /tmp/temp-project/database /path/to/your-project/
   
   # For Redis
   cp -r /tmp/temp-project/redis /path/to/your-project/
   ```

3. **Update your Docker Compose configuration:**
   - Merge the service definitions from the temporary project's `docker-compose.yml`
   - Update networks, volumes, and dependencies as needed

4. **Update DevContainer configuration:**
   - Merge VS Code extensions and settings
   - Update port forwarding
   - Add environment variables

### Method 2: Manual Component Addition

For advanced users who want more control over the process.

## Adding Specific Components

### Adding FastAPI Backend

1. **Create directory structure:**
   ```bash
   mkdir -p backend/app/{api,core,models}
   ```

2. **Create essential files:**
   ```bash
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
   EOF
   ```

3. **Create main FastAPI application:**
   ```bash
   cat > backend/app/main.py << 'EOF'
   from fastapi import FastAPI
   from fastapi.middleware.cors import CORSMiddleware
   
   app = FastAPI(title="My API")
   
   app.add_middleware(
       CORSMiddleware,
       allow_origins=["http://localhost:3000"],
       allow_credentials=True,
       allow_methods=["*"],
       allow_headers=["*"],
   )
   
   @app.get("/")
   async def root():
       return {"message": "Hello World"}
   
   @app.get("/api/healthcheck")
   async def healthcheck():
       return {"status": "ok"}
   EOF
   ```

4. **Create Dockerfiles:**
   - Copy development and production Dockerfiles from template
   - Adjust paths and configurations as needed

5. **Update Docker Compose:**
   ```yaml
   services:
     backend:
       build:
         context: ./backend
         dockerfile: Dockerfile.dev
       volumes:
         - .:/workspace:cached
       environment:
         - DATABASE_URL=postgresql://postgres:postgres@database:5432/app_db
       ports:
         - "8000:8000"
       networks:
         - app-network
   ```

### Adding Next.js Frontend

1. **Create directory structure:**
   ```bash
   mkdir -p frontend/src/{app,components}
   ```

2. **Create package.json:**
   ```json
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
       "typescript": "^5"
     }
   }
   ```

3. **Create basic Next.js configuration:**
   - Copy template files for Next.js setup
   - Create basic pages and components

4. **Update Docker Compose:**
   ```yaml
   services:
     frontend:
       build:
         context: ./frontend
         dockerfile: Dockerfile.dev
       volumes:
         - ./frontend:/app:cached
         - frontend-node-modules:/app/node_modules
       ports:
         - "3000:3000"
       environment:
         - NEXT_PUBLIC_API_URL=http://localhost:8000
       networks:
         - app-network
   ```

### Adding PostgreSQL Database

1. **Create database directory:**
   ```bash
   mkdir -p database/init-scripts
   ```

2. **Create Dockerfile with PGVector:**
   ```dockerfile
   FROM postgres:15
   
   RUN apt-get update && apt-get install -y \
       git \
       build-essential \
       postgresql-server-dev-15 \
       && rm -rf /var/lib/apt/lists/*
   
   RUN git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git \
       && cd pgvector \
       && make \
       && make install
   
   COPY ./init-scripts/ /docker-entrypoint-initdb.d/
   ```

3. **Create initialization script:**
   ```sql
   -- database/init-scripts/01-init.sql
   CREATE EXTENSION IF NOT EXISTS vector;
   
   CREATE TABLE IF NOT EXISTS users (
       id SERIAL PRIMARY KEY,
       email TEXT UNIQUE NOT NULL,
       name TEXT,
       created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
   );
   ```

4. **Update Docker Compose:**
   ```yaml
   services:
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
   
   volumes:
     postgres-data:
   ```

### Adding Redis

1. **Create Redis directory:**
   ```bash
   mkdir -p redis
   ```

2. **Create Redis configuration:**
   ```bash
   cat > redis/redis.conf << 'EOF'
   bind 0.0.0.0
   protected-mode yes
   port 6379
   save 900 1
   save 300 10
   save 60 10000
   EOF
   ```

3. **Update Docker Compose:**
   ```yaml
   services:
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
   
   volumes:
     redis-data:
   ```

## Updating Configurations

### DevContainer Configuration

After adding components, update `.devcontainer/devcontainer.json`:

1. **Add relevant VS Code extensions:**
   ```json
   "extensions": [
     "ms-python.python",           // For backend
     "dbaeumer.vscode-eslint",     // For frontend
     "mtxr.sqltools",              // For database
     "ms-azuretools.vscode-docker"
   ]
   ```

2. **Update port forwarding:**
   ```json
   "forwardPorts": [3000, 8000, 5432, 6379]
   ```

3. **Add environment-specific settings:**
   ```json
   "settings": {
     "python.defaultInterpreterPath": "/usr/local/bin/python",
     "editor.formatOnSave": true
   }
   ```

### Project Configuration

Update your project's configuration to reflect the new components:

1. **Update .gitignore:**
   - Add component-specific ignore patterns
   - Update for new build artifacts

2. **Update documentation:**
   - Add component-specific setup instructions
   - Update architecture diagrams

3. **Update scripts:**
   - Modify startup scripts to handle new services
   - Update health checks

## Validation

After adding components:

1. **Test the build:**
   ```bash
   docker-compose build
   ```

2. **Start services:**
   ```bash
   docker-compose up -d
   ```

3. **Verify connectivity:**
   - Check that all services start properly
   - Test inter-service communication
   - Verify port accessibility

4. **Test in DevContainer:**
   - Open project in VS Code
   - Ensure DevContainer builds successfully
   - Test development workflow

## Troubleshooting

### Common Issues

1. **Port conflicts:**
   - Check if ports are already in use
   - Update port mappings in docker-compose.yml

2. **Network connectivity:**
   - Ensure all services are on the same network
   - Check firewall settings

3. **Volume permissions:**
   - Verify volume mount permissions
   - Check file ownership issues

4. **Environment variables:**
   - Ensure all required environment variables are set
   - Check for typos in variable names

### Getting Help

If you encounter issues:

1. Check the logs: `docker-compose logs [service-name]`
2. Verify configuration files for syntax errors
3. Review the troubleshooting guide
4. Compare with a fresh template project

## Best Practices

1. **Backup before changes:**
   - Create a git branch before adding components
   - Backup important configuration files

2. **Test incrementally:**
   - Add one component at a time
   - Test thoroughly before adding the next

3. **Document changes:**
   - Update project README
   - Document any custom configurations

4. **Version control:**
   - Commit changes frequently
   - Use descriptive commit messages

5. **Configuration management:**
   - Use environment variables for configuration
   - Keep sensitive data out of version control