#!/bin/bash
# Project startup script
# This script starts all services and sets up the development environment

# Source the utilities library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../" && pwd)"
source "$SCRIPT_DIR/lib/utils.sh"

# Initialize error handling and logging
setup_error_handling
init_logging "project_start"
parse_common_args "$@"

# Set component flags (default to false)
USE_BACKEND=false
USE_FRONTEND=false
USE_DATABASE=false
USE_REDIS=false

# Check if Docker is running
function check_docker() {
  print_status "Checking Docker status..."
  
  if ! retry 3 2 docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop and try again."
    return 1
  fi
  
  print_status "Docker is running."
}

# Check if Docker Compose is available
function check_docker_compose() {
  print_status "Checking Docker Compose..."
  
  if ! check_command "docker-compose" "Docker Compose"; then
    print_error "Docker Compose is not available. Please install Docker Desktop with Docker Compose."
    return 1
  fi
  
  print_status "Docker Compose is available."
}

# Detect which components are present in the project
function detect_components() {
  print_status "Detecting components..."
  
  cd "$PROJECT_ROOT"
  
  if [[ -d "backend" ]]; then
    USE_BACKEND=true
    print_status "Detected: FastAPI backend"
  fi
  
  if [[ -d "frontend" ]]; then
    USE_FRONTEND=true
    print_status "Detected: Next.js frontend"
  fi
  
  if [[ -d "database" ]]; then
    USE_DATABASE=true
    print_status "Detected: PostgreSQL database"
  fi
  
  if [[ -d "redis" ]]; then
    USE_REDIS=true
    print_status "Detected: Redis"
  fi
  
  # Check if at least one component is detected
  if [[ "$USE_BACKEND" == false && "$USE_FRONTEND" == false && "$USE_DATABASE" == false && "$USE_REDIS" == false ]]; then
    print_error "No components detected in project. Please make sure you're in the right directory."
    return 1
  fi
}

# Start the services
function start_services() {
  print_status "Starting services..."
  
  cd "$PROJECT_ROOT"
  
  if [[ "$DRY_RUN" == true ]]; then
    print_info "DRY RUN: Would start Docker Compose services"
    return 0
  fi
  
  if ! retry 3 5 docker-compose up -d; then
    print_error "Failed to start services after 3 attempts"
    return 1
  fi
  
  print_status "Services started."
}

# Check service health
function check_services() {
  print_status "Checking service health..."
  
  cd "$PROJECT_ROOT"
  
  if [[ "$DRY_RUN" == true ]]; then
    print_info "DRY RUN: Would check service health"
    return 0
  fi
  
  if [[ "$USE_DATABASE" == true ]]; then
    # Wait for PostgreSQL to be ready
    print_status "Waiting for PostgreSQL..."
    local attempts=0
    local max_attempts=30
    
    while [[ $attempts -lt $max_attempts ]]; do
      if docker-compose exec -T database pg_isready -h localhost -U postgres > /dev/null 2>&1; then
        print_status "PostgreSQL is ready."
        break
      fi
      
      if [[ $attempts -eq $((max_attempts - 1)) ]]; then
        print_error "PostgreSQL did not become ready in time."
        return 1
      fi
      
      show_progress "$((attempts + 1))" "$max_attempts" "Waiting for PostgreSQL"
      sleep 1
      ((attempts++))
    done
  fi
  
  if [[ "$USE_REDIS" == true ]]; then
    # Check Redis
    print_status "Checking Redis..."
    if ! docker-compose exec -T redis redis-cli ping | grep -q "PONG"; then
      print_error "Redis is not responding."
      return 1
    fi
    print_status "Redis is ready."
  fi
  
  print_status "All services are healthy."
}

# Display editor instructions
function show_editor_info() {
  print_status "Development environment is ready!"
  echo ""
  print_info "Open your preferred editor with DevContainer support:"
  echo "  - VS Code: code ."
  echo "  - Cursor: cursor ."
  echo "  - Or manually open the project in your editor"
  echo ""
  print_info "Your editor should detect the .devcontainer configuration"
  print_info "and prompt to 'Reopen in Container'"
}

# Display information about the running services
function display_info() {
  print_status "Development environment is ready!"
  echo "======================================================"
  echo "Services:"
  
  if [[ "$USE_BACKEND" == true ]]; then
    echo "- FastAPI Backend: http://localhost:8000"
    echo "  API Documentation: http://localhost:8000/docs"
  fi
  
  if [[ "$USE_FRONTEND" == true ]]; then
    echo "- Next.js Frontend: http://localhost:3000"
  fi
  
  if [[ "$USE_DATABASE" == true ]]; then
    echo "- PostgreSQL: localhost:5432"
    echo "  Username: postgres"
    echo "  Password: postgres"
    echo "  Database: app_db"
  fi
  
  if [[ "$USE_REDIS" == true ]]; then
    echo "- Redis: localhost:6379"
  fi
  
  echo "======================================================"
  echo "To start developing:"
  
  if [[ "$USE_BACKEND" == true ]]; then
    echo "- In your editor's terminal, use 'rs' to start the FastAPI server"
  fi
  
  if [[ "$USE_FRONTEND" == true ]]; then
    echo "- In a terminal tab, use 'dev' to start the Next.js dev server"
  fi
  
  echo "======================================================"
  echo "To stop all services:"
  echo "  docker-compose down"
  echo "======================================================"
  
  if [[ "$VERBOSE" == true ]]; then
    print_debug "Log file available at: $LOG_FILE"
  fi
}

# Show help for this script
function show_help() {
  cat << EOF
Project Startup Script

This script starts all services in your development project.

Usage: $0 [options]

Options:
  -v, --verbose    Enable verbose output
  -d, --dry-run    Show what would be done without making changes
  -h, --help       Show this help message

This script will:
  1. Detect project components (backend, frontend, database, redis)
  2. Start Docker Compose services
  3. Wait for services to become healthy
  4. Open VS Code
  5. Display service information

Examples:
  $0                # Start the development environment
  $0 --dry-run      # Preview what would be started
  $0 --verbose      # Show detailed output

Prerequisites:
  - Docker Desktop must be running
  - Project must contain docker-compose.yml
  - At least one component directory must exist
EOF
}

# Validate environment
function validate_environment() {
  print_status "Validating environment..."
  
  # Check for docker-compose.yml
  if [[ ! -f "$PROJECT_ROOT/docker-compose.yml" ]]; then
    print_error "docker-compose.yml not found in project root"
    print_info "Please run ./project-template/project-setup.sh first to set up the project"
    return 1
  fi
  
  # Check required commands
  local required_commands=("docker" "docker-compose")
  if ! check_dependencies "${required_commands[@]}"; then
    print_error "Missing required dependencies"
    print_info "Please run ./macos-setup.sh to install required tools"
    return 1
  fi
  
  print_status "Environment validation passed"
}

# Main function
function main() {
  print_status "Starting development environment..."
  
  # Validate environment first
  if ! validate_environment; then
    print_error "Environment validation failed"
    exit 1
  fi
  
  # Run startup steps
  local steps=(
    "check_docker"
    "check_docker_compose"
    "detect_components"
    "start_services"
    "check_services"
    "show_editor_info"
  )
  
  local current=0
  local total=${#steps[@]}
  
  for step in "${steps[@]}"; do
    ((current++))
    show_progress "$current" "$total" "$step"
    
    if ! "$step"; then
      print_error "Step '$step' failed"
      if [[ "$DRY_RUN" != true ]]; then
        print_warning "Attempting to stop any started services..."
        cd "$PROJECT_ROOT"
        docker-compose down 2>/dev/null || true
      fi
      exit 1
    fi
  done
  
  echo ""
  display_info
}

# Execute main function with error handling
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi