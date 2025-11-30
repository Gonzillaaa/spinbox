#!/bin/bash
# Git hooks installation and management library

# Note: This library assumes utils.sh is already sourced by the caller
# We don't source it here to avoid circular dependencies

# Install git hooks for a project
function install_git_hooks() {
    local project_dir="$1"
    local language="$2"  # python, node, etc.

    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN: Would install git hooks for $language project"
        return 0
    fi

    print_debug "Installing git hooks for $language project in $project_dir"

    # Check if project is a git repository (should already be initialized by project-generator.sh)
    if [[ ! -d "$project_dir/.git" ]]; then
        print_warning "Not a git repository, skipping hooks installation"
        return 1
    fi

    local hooks_dir="$project_dir/.git/hooks"

    # Install pre-commit hook
    if [[ -f "$PROJECT_ROOT/templates/git-hooks/pre-commit-${language}.sh" ]]; then
        cp "$PROJECT_ROOT/templates/git-hooks/pre-commit-${language}.sh" "$hooks_dir/pre-commit"
        chmod +x "$hooks_dir/pre-commit"
        print_debug "Installed pre-commit hook"
    fi

    # Install pre-push hook
    if [[ -f "$PROJECT_ROOT/templates/git-hooks/pre-push-${language}.sh" ]]; then
        cp "$PROJECT_ROOT/templates/git-hooks/pre-push-${language}.sh" "$hooks_dir/pre-push"
        chmod +x "$hooks_dir/pre-push"
        print_debug "Installed pre-push hook"
    fi

    print_status "Git hooks installed successfully"
}

# Remove git hooks from a project
function remove_git_hooks() {
    local project_dir="$1"

    if [[ ! -d "$project_dir/.git/hooks" ]]; then
        print_warning "No git hooks directory found"
        return 1
    fi

    rm -f "$project_dir/.git/hooks/pre-commit"
    rm -f "$project_dir/.git/hooks/pre-push"

    print_status "Git hooks removed"
}

# Check if git hooks are installed
function check_git_hooks() {
    local project_dir="$1"

    if [[ -f "$project_dir/.git/hooks/pre-commit" ]]; then
        echo "pre-commit hook: installed"
    else
        echo "pre-commit hook: not installed"
    fi

    if [[ -f "$project_dir/.git/hooks/pre-push" ]]; then
        echo "pre-push hook: installed"
    else
        echo "pre-push hook: not installed"
    fi
}

# Export functions for use in other scripts
export -f install_git_hooks remove_git_hooks check_git_hooks
