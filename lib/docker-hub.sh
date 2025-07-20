#!/bin/bash
# Docker Hub integration utilities for Spinbox
# Provides functions for checking image availability and handling fallbacks

# Source required libraries
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/version-config.sh"

# Configuration (timeout is static, others are configurable)
DOCKER_HUB_TIMEOUT=5

# Check Docker Hub connectivity
function check_docker_hub_connectivity() {
    print_debug "Checking Docker Hub connectivity..."
    
    if ! command -v curl >/dev/null 2>&1; then
        print_warning "curl not available, cannot check Docker Hub connectivity"
        return 1
    fi
    
    # Get configured registry
    local docker_registry=$(get_effective_docker_hub_registry)
    
    # Quick connectivity test with timeout
    if curl -s --max-time "$DOCKER_HUB_TIMEOUT" "https://${docker_registry}" >/dev/null 2>&1; then
        print_debug "Docker Hub connectivity confirmed"
        return 0
    else
        print_debug "Docker Hub connectivity failed"
        return 1
    fi
}

# Verify specific image exists on Docker Hub
function verify_image_exists() {
    local image_name="$1"
    local tag="${2:-latest}"
    
    if [[ -z "$image_name" ]]; then
        print_error "verify_image_exists: image_name is required"
        return 1
    fi
    
    print_debug "Checking if image exists: ${image_name}:${tag}"
    
    # Get configured registry
    local docker_registry=$(get_effective_docker_hub_registry)
    
    # Check image manifest exists
    local manifest_url="https://${docker_registry}/${image_name}/manifests/${tag}"
    
    if curl -s --max-time "$DOCKER_HUB_TIMEOUT" \
       -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
       "$manifest_url" >/dev/null 2>&1; then
        print_debug "Image ${image_name}:${tag} exists on Docker Hub"
        return 0
    else
        print_debug "Image ${image_name}:${tag} not found on Docker Hub"
        return 1
    fi
}

# Get docker pull command for image
function get_image_pull_command() {
    local image_name="$1"
    local tag="${2:-latest}"
    
    echo "docker pull ${image_name}:${tag}"
}

# Check if Docker is available locally
function check_docker_available() {
    if ! command -v docker >/dev/null 2>&1; then
        print_warning "Docker not available, cannot use Docker Hub images"
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        print_warning "Docker daemon not running, cannot use Docker Hub images"
        return 1
    fi
    
    return 0
}

# Main function to check if Docker Hub mode is feasible
function check_docker_hub_feasibility() {
    local image_name="$1"
    
    # Check if Docker is available
    if ! check_docker_available; then
        return 1
    fi
    
    # Check Docker Hub connectivity
    if ! check_docker_hub_connectivity; then
        print_warning "Cannot reach Docker Hub, falling back to local build"
        return 1
    fi
    
    # Check if specific image exists
    if [[ -n "$image_name" ]]; then
        if ! verify_image_exists "$image_name"; then
            print_warning "Image $image_name not found on Docker Hub, falling back to local build"
            return 1
        fi
    fi
    
    return 0
}

# Fallback function with user-friendly messaging
function fallback_to_local_build() {
    local component="$1"
    local reason="$2"
    
    print_warning "Docker Hub not available for $component component"
    if [[ -n "$reason" ]]; then
        print_info "Reason: $reason"
    fi
    print_info "Using local build instead (this may take longer)"
}

# Get appropriate image name for component
function get_component_image() {
    local component="$1"
    
    case "$component" in
        "fastapi"|"python"|"minimal-python")
            echo "$(get_effective_python_base_image)"
            ;;
        "nextjs"|"node")
            echo "$(get_effective_node_base_image)"
            ;;
        *)
            print_error "Unknown component: $component"
            return 1
            ;;
    esac
}

# Check if Docker Hub mode should be used for component
function should_use_docker_hub() {
    local component="$1"
    
    # Check if Docker Hub flag is enabled
    if [[ "${USE_DOCKER_HUB:-false}" != "true" ]]; then
        print_debug "Docker Hub mode not requested"
        return 1
    fi
    
    # Get component image name
    local image_name
    image_name=$(get_component_image "$component")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # Check feasibility
    if check_docker_hub_feasibility "$image_name"; then
        print_info "Using optimized Docker Hub image for $component: $image_name"
        return 0
    else
        fallback_to_local_build "$component" "connectivity or image availability issue"
        return 1
    fi
}

# Generate Docker Compose service configuration for Docker Hub image
function generate_dockerhub_compose_service() {
    local service_name="$1"
    local image_name="$2"
    local tag="${3:-latest}"
    local ports="$4"
    local volumes="$5"
    local env_file="$6"
    
    cat << EOF
  $service_name:
    image: ${image_name}:${tag}
    container_name: ${service_name}
EOF

    if [[ -n "$ports" ]]; then
        echo "    ports:"
        for port in $ports; do
            echo "      - \"$port\""
        done
    fi
    
    if [[ -n "$volumes" ]]; then
        echo "    volumes:"
        for volume in $volumes; do
            echo "      - $volume"
        done
    fi
    
    if [[ -n "$env_file" ]]; then
        echo "    env_file:"
        echo "      - $env_file"
    fi
    
    echo "    stdin_open: true"
    echo "    tty: true"
    echo "    command: [\"zsh\", \"-c\", \"while sleep 1000; do :; done\"]"
}

# Pull Docker Hub image with progress indication
function pull_docker_hub_image() {
    local image_name="$1"
    local tag="${2:-latest}"
    
    print_status "Pulling optimized image: ${image_name}:${tag}"
    
    if docker pull "${image_name}:${tag}" >/dev/null 2>&1; then
        print_status "Successfully pulled ${image_name}:${tag}"
        return 0
    else
        print_error "Failed to pull ${image_name}:${tag}"
        return 1
    fi
}

# Export functions for use in generators
export -f check_docker_hub_connectivity verify_image_exists
export -f get_image_pull_command check_docker_available
export -f check_docker_hub_feasibility fallback_to_local_build
export -f get_component_image should_use_docker_hub
export -f generate_dockerhub_compose_service pull_docker_hub_image