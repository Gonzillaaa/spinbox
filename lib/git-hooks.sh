#!/bin/bash
# Git hooks management library for Spinbox projects
# Provides functionality to install, manage, and configure git hooks

# Source utilities
HOOKS_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HOOKS_SCRIPT_DIR/utils.sh"

# Constants
readonly TEMPLATES_DIR="$PROJECT_ROOT/templates/hooks"
readonly HOOKS_DIR=".git/hooks"

# Git hooks configuration
# Function to get hook description
function get_hook_description() {
    local hook_type="$1"
    case "$hook_type" in
        "pre-commit")
            echo "Format and lint checks"
            ;;
        "pre-push")
            echo "Testing and build validation"
            ;;
        "commit-msg")
            echo "Commit message validation"
            ;;
        *)
            echo "Unknown hook type"
            ;;
    esac
}

# Valid hook types
readonly VALID_HOOK_TYPES="pre-commit pre-push commit-msg"

# Project type detection
function detect_project_type() {
    local project_dir="${1:-.}"
    local project_types=()
    
    # Check for Python project
    if [[ -f "$project_dir/requirements.txt" ]] || [[ -f "$project_dir/pyproject.toml" ]] || find "$project_dir" -name "*.py" -type f -print -quit | grep -q .; then
        project_types+=("python")
    fi
    
    # Check for Node.js project
    if [[ -f "$project_dir/package.json" ]] || find "$project_dir" -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" -type f -print -quit | grep -q .; then
        project_types+=("nodejs")
    fi
    
    # Check for FastAPI
    if [[ -d "$project_dir/fastapi" ]] || grep -q "fastapi" "$project_dir/requirements.txt" 2>/dev/null; then
        project_types+=("fastapi")
    fi
    
    # Check for Next.js
    if [[ -d "$project_dir/nextjs" ]] || grep -q "next" "$project_dir/package.json" 2>/dev/null; then
        project_types+=("nextjs")
    fi
    
    # Check for database projects
    if [[ -f "$project_dir/docker-compose.yml" ]] && grep -q "postgres\|mongodb\|redis" "$project_dir/docker-compose.yml" 2>/dev/null; then
        project_types+=("database")
    fi
    
    # Determine primary project type
    if [[ "${#project_types[@]}" -eq 0 ]]; then
        echo "unknown"
    elif [[ " ${project_types[*]} " =~ " fastapi " ]] && [[ " ${project_types[*]} " =~ " nextjs " ]]; then
        echo "fullstack"
    elif [[ " ${project_types[*]} " =~ " fastapi " ]]; then
        echo "fastapi"
    elif [[ " ${project_types[*]} " =~ " nextjs " ]]; then
        echo "nextjs"
    elif [[ " ${project_types[*]} " =~ " python " ]]; then
        echo "python"
    elif [[ " ${project_types[*]} " =~ " nodejs " ]]; then
        echo "nodejs"
    else
        echo "mixed"
    fi
}

# Validate git repository
function validate_git_repository() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not a git repository. Please run 'git init' first."
        return 1
    fi
    
    if [[ ! -d ".git/hooks" ]]; then
        print_error "Git hooks directory not found."
        return 1
    fi
    
    return 0
}

# Check if required tools are available
function check_tool_availability() {
    local project_type="$1"
    local missing_tools=()
    
    case "$project_type" in
        "python"|"fastapi")
            command -v python3 >/dev/null 2>&1 || missing_tools+=("python3")
            command -v pip >/dev/null 2>&1 || missing_tools+=("pip")
            ;;
        "nodejs"|"nextjs")
            command -v node >/dev/null 2>&1 || missing_tools+=("node")
            command -v npm >/dev/null 2>&1 || missing_tools+=("npm")
            ;;
        "fullstack")
            command -v python3 >/dev/null 2>&1 || missing_tools+=("python3")
            command -v node >/dev/null 2>&1 || missing_tools+=("node")
            command -v npm >/dev/null 2>&1 || missing_tools+=("npm")
            ;;
    esac
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        return 1
    fi
    
    return 0
}

# Install specific hook
function install_hook() {
    local hook_type="$1"
    local project_type="$2"
    local with_examples="${3:-false}"
    
    print_info "Installing $hook_type hook for $project_type project..."
    
    # Validate inputs
    if [[ ! " $VALID_HOOK_TYPES " =~ " $hook_type " ]]; then
        print_error "Unknown hook type: $hook_type"
        return 1
    fi
    
    # Create hook file path
    local hook_file="$HOOKS_DIR/$hook_type"
    
    # Select appropriate template
    local template_file="$TEMPLATES_DIR/${project_type}/${hook_type}"
    
    if [[ ! -f "$template_file" ]]; then
        print_error "Template not found: $template_file"
        return 1
    fi
    
    # Copy and configure hook
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY RUN: Would copy $template_file to $hook_file"
    else
        cp "$template_file" "$hook_file"
        chmod +x "$hook_file"
        print_success "Installed $hook_type hook"
    fi
    
    # Install example configurations if requested
    if [[ "$with_examples" == "true" ]]; then
        install_hook_examples "$project_type" "$hook_type"
    fi
    
    return 0
}

# Install example configurations
function install_hook_examples() {
    local project_type="$1"
    local hook_type="$2"
    
    print_info "Installing example configurations for $project_type..."
    
    local examples_dir="$TEMPLATES_DIR/${project_type}/examples"
    
    if [[ ! -d "$examples_dir" ]]; then
        print_warning "No examples found for $project_type"
        return 0
    fi
    
    # Copy example files
    for example_file in "$examples_dir"/*; do
        if [[ -f "$example_file" ]]; then
            local filename=$(basename "$example_file")
            
            if [[ "$DRY_RUN" == "true" ]]; then
                print_info "DRY RUN: Would copy $example_file to ./$filename"
            else
                if [[ ! -f "./$filename" ]]; then
                    cp "$example_file" "./$filename"
                    print_success "Created example: $filename"
                else
                    print_info "Example already exists: $filename"
                fi
            fi
        fi
    done
}

# Install all recommended hooks for project type
function install_all_hooks() {
    local project_type="$1"
    local with_examples="${2:-false}"
    
    print_info "Installing all recommended hooks for $project_type project..."
    
    # Define recommended hooks per project type
    local hooks_to_install=()
    
    case "$project_type" in
        "python"|"fastapi")
            hooks_to_install=("pre-commit" "pre-push")
            ;;
        "nodejs"|"nextjs")
            hooks_to_install=("pre-commit" "pre-push")
            ;;
        "fullstack")
            hooks_to_install=("pre-commit" "pre-push")
            ;;
        *)
            hooks_to_install=("pre-commit")
            ;;
    esac
    
    # Install each hook
    for hook_type in "${hooks_to_install[@]}"; do
        install_hook "$hook_type" "$project_type" "$with_examples"
    done
    
    print_success "All hooks installed successfully"
}

# List installed hooks
function list_hooks() {
    print_info "Checking installed git hooks..."
    
    local hooks_found=false
    
    for hook_type in $VALID_HOOK_TYPES; do
        local hook_file="$HOOKS_DIR/$hook_type"
        
        if [[ -f "$hook_file" && -x "$hook_file" ]]; then
            print_success "✓ $hook_type: $(get_hook_description "$hook_type")"
            hooks_found=true
        else
            print_info "✗ $hook_type: Not installed"
        fi
    done
    
    if [[ "$hooks_found" == "false" ]]; then
        print_info "No git hooks are currently installed"
    fi
}

# Remove specific hook
function remove_hook() {
    local hook_type="$1"
    
    local hook_file="$HOOKS_DIR/$hook_type"
    
    if [[ -f "$hook_file" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            print_info "DRY RUN: Would remove $hook_file"
        else
            rm "$hook_file"
            print_success "Removed $hook_type hook"
        fi
    else
        print_info "$hook_type hook is not installed"
    fi
}

# Remove all hooks
function remove_all_hooks() {
    print_info "Removing all git hooks..."
    
    for hook_type in $VALID_HOOK_TYPES; do
        remove_hook "$hook_type"
    done
    
    print_success "All hooks removed"
}

# Main hooks management function
function manage_hooks() {
    local action="$1"
    local hook_type="$2"
    local with_examples="${3:-false}"
    
    # Validate git repository
    if ! validate_git_repository; then
        return 1
    fi
    
    # Detect project type
    local project_type=$(detect_project_type)
    
    if [[ "$project_type" == "unknown" ]]; then
        print_warning "Could not detect project type. Using generic hooks."
        project_type="generic"
    else
        print_info "Detected project type: $project_type"
    fi
    
    # Check tool availability
    if ! check_tool_availability "$project_type"; then
        print_error "Required tools not available for $project_type project"
        return 1
    fi
    
    # Execute action
    case "$action" in
        "add")
            if [[ "$hook_type" == "all" ]]; then
                install_all_hooks "$project_type" "$with_examples"
            elif [[ -n "$hook_type" ]]; then
                install_hook "$hook_type" "$project_type" "$with_examples"
            else
                print_error "Hook type required. Use: pre-commit, pre-push, or all"
                return 1
            fi
            ;;
        "list")
            list_hooks
            ;;
        "remove")
            if [[ "$hook_type" == "all" ]]; then
                remove_all_hooks
            elif [[ -n "$hook_type" ]]; then
                remove_hook "$hook_type"
            else
                print_error "Hook type required. Use: pre-commit, pre-push, or all"
                return 1
            fi
            ;;
        *)
            print_error "Unknown action: $action"
            return 1
            ;;
    esac
    
    return 0
}

# Usage information
function show_hooks_usage() {
    cat << EOF
Usage: spinbox hooks <action> [options]

Actions:
    add <hook-type>         Install specific hook (pre-commit, pre-push, all)
    list                    List installed hooks
    remove <hook-type>      Remove specific hook (pre-commit, pre-push, all)

Options:
    --with-examples         Include example configurations
    --dry-run              Show what would be done without making changes

Examples:
    spinbox hooks add pre-commit
    spinbox hooks add all --with-examples
    spinbox hooks list
    spinbox hooks remove all

Hook Types:
    pre-commit             Format and lint checks
    pre-push              Testing and build validation
    all                   Install all recommended hooks
EOF
}