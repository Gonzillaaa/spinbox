#!/bin/bash
# FastAPI component generator for Spinbox
# Creates FastAPI backend with SQLAlchemy, Docker setup, and development tools

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/../lib/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/version-config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/dependency-manager.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/docker-hub.sh"

# Generate FastAPI backend component
function generate_fastapi_component() {
    local project_dir="$1"
    local fastapi_dir="$project_dir/backend"
    
    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would generate FastAPI backend component"
        return 0
    fi
    
    print_status "Creating FastAPI backend component..."
    
    # Ensure backend directory exists
    safe_create_dir "$fastapi_dir"
    safe_create_dir "$fastapi_dir/app"
    safe_create_dir "$fastapi_dir/app/core"
    safe_create_dir "$fastapi_dir/app/api"
    safe_create_dir "$fastapi_dir/app/models"
    safe_create_dir "$fastapi_dir/app/schemas"
    safe_create_dir "$fastapi_dir/tests"
    
    # Generate backend files
    generate_fastapi_dockerfiles "$fastapi_dir"
    generate_fastapi_requirements "$fastapi_dir"
    generate_fastapi_application "$fastapi_dir"
    generate_fastapi_database_config "$fastapi_dir"
    generate_fastapi_tests "$fastapi_dir"
    generate_fastapi_env_files "$fastapi_dir"
    
    # Manage dependencies if --with-deps flag is enabled
    manage_component_dependencies "$project_dir" "fastapi"
    
    # Generate working examples if --with-examples flag is enabled
    if [[ "${WITH_EXAMPLES:-false}" == "true" ]]; then
        generate_fastapi_working_examples "$fastapi_dir"
    fi

    # Copy Powerlevel10k configuration
    local p10k_template="$PROJECT_ROOT/templates/shell/p10k.zsh"
    if [[ -f "$p10k_template" ]]; then
        cp "$p10k_template" "$fastapi_dir/p10k.zsh"
    fi

    print_status "FastAPI backend component created successfully"
}

# Generate Docker configuration for backend
function generate_fastapi_dockerfiles() {
    local fastapi_dir="$1"
    
    # Check if we should use Docker Hub optimized images
    if should_use_docker_hub "fastapi"; then
        generate_fastapi_dockerhub_config "$fastapi_dir"
    else
        generate_fastapi_local_dockerfiles "$fastapi_dir"
    fi
}

# Generate Docker Hub configuration for FastAPI
function generate_fastapi_dockerhub_config() {
    local fastapi_dir="$1"
    local image_name=$(get_component_image "fastapi")

    print_debug "Generating FastAPI configuration with Docker Hub image: $image_name"

    # Production Dockerfile
    local python_version=$(get_effective_python_version)
    cat > "$fastapi_dir/Dockerfile" << EOF
FROM python:${python_version}-slim

WORKDIR /app

# Install UV for dependency management
RUN pip install --no-cache-dir uv

# Create and activate virtual environment
RUN python -m venv venv
ENV PATH="/app/venv/bin:\$PATH"

# Copy and install dependencies
COPY requirements.txt .
RUN uv pip install --no-cache -r requirements.txt

# Copy application code
COPY . .

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

    # Generate common .dockerignore file
    generate_fastapi_dockerignore "$fastapi_dir"
}

# Generate local Docker configuration for FastAPI (fallback mode)
function generate_fastapi_local_dockerfiles() {
    local fastapi_dir="$1"
    local python_version=$(get_effective_python_version)

    print_debug "Generating FastAPI configuration with local builds"

    # Production Dockerfile
    cat > "$fastapi_dir/Dockerfile" << EOF
FROM python:${python_version}-slim

WORKDIR /app

# Install UV for dependency management
RUN pip install --no-cache-dir uv

# Create and activate virtual environment
RUN python -m venv venv
ENV PATH="/app/venv/bin:\$PATH"

# Copy and install dependencies
COPY requirements.txt .
RUN uv pip install --no-cache -r requirements.txt

# Copy application code
COPY . .

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOF

    # Generate common .dockerignore file
    generate_fastapi_dockerignore "$fastapi_dir"
}

# Generate .dockerignore file for FastAPI projects
function generate_fastapi_dockerignore() {
    local fastapi_dir="$1"
    
    # Docker ignore file
    cat > "$fastapi_dir/.dockerignore" << 'EOF'
venv/
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
.env
.env.local
.pytest_cache/
.coverage
.tox/
dist/
build/
*.egg-info/
.git/
.gitignore
README.md
Dockerfile*
docker-compose*
EOF

    print_debug "Generated backend Docker configuration"
}

# Generate requirements.txt with appropriate dependencies
function generate_fastapi_requirements() {
    local fastapi_dir="$1"
    
    cat > "$fastapi_dir/requirements.txt" << 'EOF'
# FastAPI and ASGI server
fastapi>=0.103.0
uvicorn[standard]>=0.23.0

# Database
sqlalchemy>=2.0.0
alembic>=1.12.0

# PostgreSQL adapter
psycopg2-binary>=2.9.7

# Redis client
redis>=5.0.0

# Data validation and serialization
pydantic>=2.4.0
pydantic-settings>=2.0.0

# Environment management
python-dotenv>=1.0.0

# HTTP client for testing
httpx>=0.24.1

# Testing
pytest>=7.4.0
pytest-asyncio>=0.21.0
pytest-cov>=4.1.0

# Development tools
black>=23.0.0
isort>=5.12.0
mypy>=1.5.0
EOF

    # Add optional dependencies based on selected components
    if [[ "${USE_MONGODB:-false}" == "true" ]]; then
        cat >> "$fastapi_dir/requirements.txt" << 'EOF'

# MongoDB dependencies
motor>=3.3.0
beanie>=1.23.0
EOF
    fi
    
    if [[ "${USE_CHROMA:-false}" == "true" ]]; then
        cat >> "$fastapi_dir/requirements.txt" << 'EOF'

# Vector database dependencies
chromadb>=0.4.0
sentence-transformers>=2.2.0
EOF
    fi

    print_debug "Generated backend requirements.txt"
}

# Generate main FastAPI application structure
function generate_fastapi_application() {
    local fastapi_dir="$1"
    local app_dir="$fastapi_dir/app"
    
    # Main application entry point
    cat > "$app_dir/main.py" << 'EOF'
"""
FastAPI application entry point.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.api_v1.api import api_router
from app.core.config import settings

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Set up CORS
cors_origins = settings.get_cors_origins()
if cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/")
async def root():
    """Root endpoint."""
    return {"message": f"Welcome to {settings.PROJECT_NAME} API"}

@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy", "service": settings.PROJECT_NAME}
EOF

    # Core configuration
    cat > "$app_dir/core/__init__.py" << 'EOF'
"""Core application modules."""
EOF

    cat > "$app_dir/core/config.py" << 'EOF'
"""
Application configuration.
"""
import secrets
from typing import Any, Dict, List, Optional, Union

from pydantic import AnyHttpUrl, field_validator, PostgresDsn, ValidationInfo
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    PROJECT_NAME: str = "FastAPI Project"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = secrets.token_urlsafe(32)
    
    # Database
    POSTGRES_SERVER: str = "localhost"
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "postgres"
    POSTGRES_DB: str = "app"
    POSTGRES_PORT: int = 5432
    
    # Redis
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_DB: int = 0
    
    # CORS - use str type to avoid pydantic-settings JSON parsing issues
    BACKEND_CORS_ORIGINS: str = "http://localhost:3000"

    def get_cors_origins(self) -> List[str]:
        """Parse CORS origins from comma-separated string."""
        if not self.BACKEND_CORS_ORIGINS:
            return []
        return [origin.strip() for origin in self.BACKEND_CORS_ORIGINS.split(",")]
    
    # Database URL construction
    SQLALCHEMY_DATABASE_URI: Optional[PostgresDsn] = None
    
    @field_validator("SQLALCHEMY_DATABASE_URI", mode="before")
    @classmethod
    def assemble_db_connection(cls, v: Optional[str], info: ValidationInfo) -> Any:
        if isinstance(v, str):
            return v
        return PostgresDsn.build(
            scheme="postgresql",
            username=info.data.get("POSTGRES_USER"),
            password=info.data.get("POSTGRES_PASSWORD"),
            host=info.data.get("POSTGRES_SERVER"),
            port=info.data.get("POSTGRES_PORT"),
            path=f"/{info.data.get('POSTGRES_DB') or ''}",
        )

    model_config = {
        "case_sensitive": True,
        "env_file": ".env",
        "extra": "ignore",  # Allow extra env vars without error
    }


settings = Settings()
EOF

    # API router
    safe_create_dir "$app_dir/api"
    safe_create_dir "$app_dir/api/api_v1"
    
    cat > "$app_dir/api/__init__.py" << 'EOF'
"""API modules."""
EOF

    cat > "$app_dir/api/api_v1/__init__.py" << 'EOF'
"""API v1 modules."""
EOF

    cat > "$app_dir/api/api_v1/api.py" << 'EOF'
"""
API v1 router.
"""
from fastapi import APIRouter

from app.api.api_v1.endpoints import items

api_router = APIRouter()
api_router.include_router(items.router, prefix="/items", tags=["items"])
EOF

    # Example endpoints
    safe_create_dir "$app_dir/api/api_v1/endpoints"
    cat > "$app_dir/api/api_v1/endpoints/__init__.py" << 'EOF'
"""API endpoints."""
EOF

    cat > "$app_dir/api/api_v1/endpoints/items.py" << 'EOF'
"""
Items endpoints.
"""
from typing import Any, List

from fastapi import APIRouter

router = APIRouter()

@router.get("/", response_model=List[dict])
def read_items() -> Any:
    """
    Retrieve items.
    """
    return [
        {"id": 1, "name": "Item 1", "description": "First item"},
        {"id": 2, "name": "Item 2", "description": "Second item"},
    ]

@router.get("/{item_id}", response_model=dict)
def read_item(item_id: int) -> Any:
    """
    Get item by ID.
    """
    return {"id": item_id, "name": f"Item {item_id}", "description": f"Item with ID {item_id}"}
EOF

    # Models and schemas placeholder
    cat > "$app_dir/models/__init__.py" << 'EOF'
"""Database models."""
EOF

    cat > "$app_dir/schemas/__init__.py" << 'EOF'
"""Pydantic schemas."""
EOF

    print_debug "Generated FastAPI application structure"
}

# Generate database configuration
function generate_fastapi_database_config() {
    local fastapi_dir="$1"
    local app_dir="$fastapi_dir/app"
    
    cat > "$app_dir/core/database.py" << 'EOF'
"""
Database configuration and session management.
"""
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

from app.core.config import settings

engine = create_engine(str(settings.SQLALCHEMY_DATABASE_URI), pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    """Get database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOF

    # Alembic configuration
    cat > "$fastapi_dir/alembic.ini" << 'EOF'
# A generic, single database configuration.

[alembic]
# path to migration scripts
script_location = alembic

# template used to generate migration file names; The default value is %%(rev)s_%%(slug)s
# Uncomment the line below if you want the files to be prepended with date and time
# file_template = %%(year)d_%%(month).2d_%%(day).2d_%%(hour).2d%%(minute).2d-%%(rev)s_%%(slug)s

# sys.path path, will be prepended to sys.path if present.
# defaults to the current working directory.
prepend_sys_path = .

# timezone to use when rendering the date within the migration file
# as well as the filename.
# If specified, requires the python-dateutil library that can be
# installed by adding `alembic[tz]` to the pip requirements
# string value is passed to dateutil.tz.gettz()
# leave blank for localtime
# timezone =

# max length of characters to apply to the
# "slug" field
# truncate_slug_length = 40

# set to 'true' to run the environment during
# the 'revision' command, regardless of autogenerate
# revision_environment = false

# set to 'true' to allow .pyc and .pyo files without
# a source .py file to be detected as revisions in the
# versions/ directory
# sourceless = false

# version number format (defaults to 4 digits with zero-pad)
version_num_format = %04d

# version_locations = %(here)s/bar:%(here)s/bat:alembic/versions

# version path separator; As mentioned above, this is the character used to split
# version_locations. The default within new alembic.ini files is "os", which uses
# os.pathsep. If this key is omitted entirely, it falls back to the legacy
# behavior of splitting on spaces and/or commas.
# Valid values for version_path_separator are:
#
# version_path_separator = :
# version_path_separator = ;
# version_path_separator = space
version_path_separator = os

# the output encoding used when revision files
# are written from script.py.mako
# output_encoding = utf-8

sqlalchemy.url = driver://user:pass@localhost/dbname


[post_write_hooks]
# post_write_hooks defines scripts or Python functions that are run
# on newly generated revision scripts.  See the documentation for further
# detail and examples

# format using "black" - use the console_scripts runner, against the "black" entrypoint
# hooks = black
# black.type = console_scripts
# black.entrypoint = black
# black.options = -l 79 REVISION_SCRIPT_FILENAME

# Logging configuration
[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console
qualname =

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
EOF

    print_debug "Generated database configuration"
}

# Generate test files
function generate_fastapi_tests() {
    local fastapi_dir="$1"
    local tests_dir="$fastapi_dir/tests"
    
    cat > "$tests_dir/__init__.py" << 'EOF'
"""Backend tests."""
EOF

    cat > "$tests_dir/conftest.py" << 'EOF'
"""
Test configuration and fixtures.
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.core.database import get_db, Base

# Test database URL
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base.metadata.create_all(bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db

@pytest.fixture
def client():
    return TestClient(app)
EOF

    cat > "$tests_dir/test_main.py" << 'EOF'
"""
Test main application endpoints.
"""
from fastapi.testclient import TestClient


def test_read_root(client: TestClient):
    """Test root endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data

def test_health_check(client: TestClient):
    """Test health check endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"

def test_read_items(client: TestClient):
    """Test items endpoint."""
    response = client.get("/api/v1/items/")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 0
EOF

    print_debug "Generated backend tests"
}

# Generate environment files
function generate_fastapi_env_files() {
    local fastapi_dir="$1"
    
    # Use security template for .env.example
    local template_file="$PROJECT_ROOT/templates/security/fastapi.env.example"
    if [[ -f "$template_file" ]]; then
        cp "$template_file" "$fastapi_dir/.env.example"
    else
        # Fallback to basic template
        cat > "$fastapi_dir/.env.example" << 'EOF'
# Database
POSTGRES_SERVER=localhost
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=app
POSTGRES_PORT=5432

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# API
PROJECT_NAME="FastAPI Project"
SECRET_KEY=your-secret-key-here

# CORS
BACKEND_CORS_ORIGINS=http://localhost:3000,http://localhost:8080
EOF
    fi

    # Create actual .env if it doesn't exist
    if [[ ! -f "$fastapi_dir/.env" ]]; then
        cp "$fastapi_dir/.env.example" "$fastapi_dir/.env"
    fi

    # Copy virtual environment setup script
    local setup_venv_template="$PROJECT_ROOT/templates/security/setup_venv.sh"
    if [[ -f "$setup_venv_template" ]]; then
        cp "$setup_venv_template" "$fastapi_dir/setup_venv.sh"
        chmod +x "$fastapi_dir/setup_venv.sh"
    fi

    # Copy Python .gitignore
    local gitignore_template="$PROJECT_ROOT/templates/security/python.gitignore"
    if [[ -f "$gitignore_template" ]]; then
        cp "$gitignore_template" "$fastapi_dir/.gitignore"
    fi

    print_debug "Generated environment files with security templates"
}

# Generate working examples for FastAPI
function generate_fastapi_working_examples() {
    local fastapi_dir="$1"
    local examples_source="$PROJECT_ROOT/templates/examples/core-components/fastapi"
    
    if [[ -d "$examples_source" ]]; then
        print_debug "Copying FastAPI working examples from $examples_source"
        
        # Copy all example files
        if [[ -d "$examples_source" ]]; then
            cp -r "$examples_source"/* "$fastapi_dir/" 2>/dev/null || true
        fi
        
        print_info "Added FastAPI working examples"
    else
        print_warning "FastAPI examples directory not found: $examples_source"
    fi
}

# Main function to create backend component
function create_fastapi_component() {
    local project_dir="$1"
    
    print_info "Creating FastAPI backend component in $project_dir"
    
    generate_fastapi_component "$project_dir"
    
    print_status "FastAPI backend component created successfully!"
    print_info "Next steps:"
    echo "  1. cd $(basename "$project_dir")/fastapi"
    echo "  2. Set up virtual environment: ./setup_venv.sh"
    echo "  3. Configure environment: cp .env.example .env (and edit as needed)"
    echo "  4. Run development server: uvicorn app.main:app --reload --host 0.0.0.0"
    echo "  5. Visit http://localhost:8000/docs for API documentation"
}

# Export functions for use by project generator
export -f generate_fastapi_component create_fastapi_component
export -f generate_fastapi_dockerfiles generate_fastapi_requirements
export -f generate_fastapi_application generate_fastapi_database_config
export -f generate_fastapi_tests generate_fastapi_env_files