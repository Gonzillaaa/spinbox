# Set component flags (default to false)
USE_BACKEND=false
USE_FRONTEND=false
USE_DATABASE=false
USE_REDIS=false

# Check if Docker is running
function check_docker() {
  print_status "Checking Docker status..."
  
  if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop and try again."
    exit 1
  fi
  
  print_status "Docker is running."
}

# Check if Docker Compose is available
function check_docker_compose() {
  print_status "Checking Docker Compose..."
  
  if ! docker-compose version > /dev/null 2>&1; then
    print_error "Docker Compose is not available. Please install Docker Desktop with Docker Compose."
    exit 1
  fi
  
  print_status "Docker Compose is available."
}

# Detect which components are present in the project
function detect_components() {
  print_status "Detecting components..."
  
  if [ -d "backend" ]; then
    USE_BACKEND=true
    print_status "Detected: FastAPI backend"
  fi
  
  if [ -d "frontend" ]; then
    USE_FRONTEND=true
    print_status "Detected: Next.js frontend"
  fi
  
  if [ -d "database" ]; then
    USE_DATABASE=true
    print_status "Detected: PostgreSQL database"
  fi
  
  if [ -d "redis" ]; then
    USE_REDIS=true
    print_status "Detected: Redis"
  fi#!/bin/bash
# Project startup script
# This script starts all services and sets up the development environment

# Make script exit on error
set -e

# Set color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print colored status messages
function print_status() {
  echo -e "${GREEN}[+] $1${NC}"
}

function print_warning() {
  echo -e "${YELLOW}[!] $1${NC}"
}

function print_error() {
  echo -e "${RED}[-] $1${NC}"
}

# Check if Docker is running
function check_docker() {
  print_status "Checking Docker status..."
  
  if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop and try again."
    exit 1
  fi
  
  print_status "Docker is running."
}

# Check if Docker Compose is available
function check_docker_compose() {
  print_status "Checking Docker Compose..."
  
  if ! docker-compose version > /dev/null 2>&1; then
    print_error "Docker Compose is not available. Please install Docker Desktop with Docker Compose."
    exit 1
  fi
  
  print_status "Docker Compose is available."
}

# Start the services
function start_services() {
  print_status "Starting services..."
  
  docker-compose up -d
  
  print_status "Services started."
}

# Check service health
function check_services() {
  print_status "Checking service health..."
  
  if [ "$USE_DATABASE" = true ]; then
    # Wait for PostgreSQL to be ready
    print_status "Waiting for PostgreSQL..."
    for i in {1..30}; do
      if docker-compose exec -T database pg_isready -h localhost -U postgres > /dev/null 2>&1; then
        print_status "PostgreSQL is ready."
        break
      fi
      
      if [ $i -eq 30 ]; then
        print_error "PostgreSQL did not become ready in time."
        exit 1
      fi
      
      echo -n "."
      sleep 1
    done
  fi
  
  if [ "$USE_REDIS" = true ]; then
    # Check Redis
    print_status "Checking Redis..."
    if docker-compose exec -T redis redis-cli ping | grep -q "PONG"; then
      print_status "Redis is ready."
    else
      print_error "Redis is not responding."
      exit 1
    fi
  fi
  
  print_status "All services are healthy."
}

# Open VS Code in current directory
function open_vscode() {
  print_status "Opening VS Code..."
  
  if command -v code > /dev/null 2>&1; then
    code .
    print_status "VS Code opened."
  else
    print_warning "VS Code command not found. Please open VS Code manually."
  fi
}

# Display information about the running services
function display_info() {
  print_status "Development environment is ready!"
  echo "------------------------------------------------------"
  echo "Services:"
  
  if [ "$USE_BACKEND" = true ]; then
    echo "- FastAPI Backend: http://localhost:8000"
    echo "  API Documentation: http://localhost:8000/docs"
  fi
  
  if [ "$USE_FRONTEND" = true ]; then
    echo "- Next.js Frontend: http://localhost:3000"
  fi
  
  if [ "$USE_DATABASE" = true ]; then
    echo "- PostgreSQL: localhost:5432"
    echo "  Username: postgres"
    echo "  Password: postgres"
    echo "  Database: app_db"
  fi
  
  if [ "$USE_REDIS" = true ]; then
    echo "- Redis: localhost:6379"
  fi
  
  echo "------------------------------------------------------"
  echo "To start developing:"
  
  if [ "$USE_BACKEND" = true ]; then
    echo "- In VS Code Terminal, use 'rs' to start the FastAPI server"
  fi
  
  if [ "$USE_FRONTEND" = true ]; then
    echo "- In a Terminal tab, use 'dev' to start the Next.js dev server"
  fi
  
  echo "------------------------------------------------------"
  echo "To stop all services:"
  echo "  docker-compose down"
  echo "------------------------------------------------------"
}

# Main function
function main() {
  print_status "Starting development environment..."
  
  check_docker
  check_docker_compose
  detect_components
  
  # Check if at least one component is detected
  if [[ "$USE_BACKEND" == false && "$USE_FRONTEND" == false && "$USE_DATABASE" == false && "$USE_REDIS" == false ]]; then
    print_error "No components detected in project. Please make sure you're in the right directory."
    exit 1
  fi
  
  start_services
  check_services
  open_vscode
  display_info
}

# Run the main function
main
