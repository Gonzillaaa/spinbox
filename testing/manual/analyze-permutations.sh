#!/bin/bash
# Quick analysis script for permutation test results

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <test-directory>"
    echo "Example: $0 /tmp/spinbox-permutation-test-20250720-143000"
    exit 1
fi

TEST_DIR="$1"

if [[ ! -d "$TEST_DIR" ]]; then
    echo "Error: Directory $TEST_DIR does not exist"
    exit 1
fi

echo "========================================"
echo "Permutation Test Analysis"
echo "Test Directory: $TEST_DIR"
echo "========================================"
echo

# Count projects - handle both numbered (01-name) and named (name-only) patterns
numbered_dirs=$(find "$TEST_DIR" -maxdepth 1 -type d -name "[0-9]*-*" 2>/dev/null | wc -l)
named_dirs=$(find "$TEST_DIR" -maxdepth 1 -type d -name "*-only" 2>/dev/null | wc -l)
combo_dirs=$(find "$TEST_DIR" -maxdepth 1 -type d -name "*-*" ! -name ".*" ! -name "*test*" 2>/dev/null | wc -l)
total_dirs=$((numbered_dirs + named_dirs + combo_dirs))
# Remove duplicates by using actual count
total_dirs=$(find "$TEST_DIR" -maxdepth 1 -type d ! -name ".*" ! -name "$(basename "$TEST_DIR")" 2>/dev/null | wc -l)
echo "Total test projects: $total_dirs"
echo

# Check for common issues
echo "### Potential Issues Found ###"
echo

# 1. Check for projects with both src/ and nextjs/ (dual app bug pattern)
echo "1. Checking for dual application structures (src/ + nextjs/):"
for dir in "$TEST_DIR"/*/; do
    [[ ! -d "$dir" ]] && continue
    dirname=$(basename "$dir")
    [[ "$dirname" == ".*" ]] && continue
    if [[ -d "$dir/src" ]] && [[ -d "$dir/nextjs" ]]; then
        echo "   ⚠️  $dirname: Has both src/ and nextjs/ directories"
    fi
done
echo

# 2. Check for projects with unexpected root package.json
echo "2. Checking for unexpected root package.json in component-only projects:"
for dir in "$TEST_DIR"/[0-9]*-*/; do
    basename=$(basename "$dir")
    # Single component projects that shouldn't have root package.json
    if [[ "$basename" =~ ^[0-9]+-nextjs-only$ ]] && [[ -f "$dir/package.json" ]]; then
        echo "   ⚠️  $basename: Has root package.json (should be in nextjs/)"
    fi
done
echo

# 3. Check for missing DevContainer
echo "3. Checking for missing DevContainer configurations:"
for dir in "$TEST_DIR"/*/; do
    [[ ! -d "$dir" ]] && continue
    basename_dir=$(basename "$dir")
    [[ "$basename_dir" == ".*" ]] && continue
    if [[ ! -d "$dir/.devcontainer" ]]; then
        echo "   ⚠️  $basename_dir: Missing .devcontainer directory"
    elif [[ ! -f "$dir/.devcontainer/devcontainer.json" ]]; then
        echo "   🔥 $basename_dir: CRITICAL - Empty .devcontainer directory (missing devcontainer.json)"
    else
        # Check if devcontainer.json has content
        if [[ ! -s "$dir/.devcontainer/devcontainer.json" ]]; then
            echo "   ⚠️  $basename_dir: Empty devcontainer.json file"
        fi
    fi
done
echo

# 4. Check for empty or very small projects
echo "4. Checking for suspiciously small projects (<5 files):"
for dir in "$TEST_DIR"/*/; do
    [[ ! -d "$dir" ]] && continue
    basename_dir=$(basename "$dir")
    [[ "$basename_dir" == ".*" ]] && continue
    file_count=$(find "$dir" -type f | wc -l)
    if [[ $file_count -lt 5 ]]; then
        echo "   ⚠️  $basename_dir: Only $file_count files"
    fi
done
echo

# 5. Database-only projects check
echo "5. Checking database-only projects (may need base component):"
for db in postgresql mongodb redis chroma; do
    db_only="$TEST_DIR/0[5-8]-$db-only"
    if [[ -d "$db_only" ]]; then
        # Check if it has meaningful content beyond docker-compose
        if [[ ! -f "$db_only/requirements.txt" ]] && [[ ! -f "$db_only/package.json" ]]; then
            echo "   ⚠️  $(basename "$db_only"): No application files (needs base component?)"
        fi
    fi
done
echo

# 6. Check for profile consistency
echo "6. Checking profile-generated projects for consistency:"
webapp_files=$(find "$TEST_DIR/60-profile-web-app" -type f 2>/dev/null | wc -l)
if [[ ${webapp_files:-0} -gt 0 ]]; then
    echo "   Web-app profile: $webapp_files files"
    # Compare with manually created equivalent
    manual_equiv=$(find "$TEST_DIR/14-fastapi-nextjs" -type f 2>/dev/null | wc -l)
    if [[ ${manual_equiv:-0} -gt 0 ]]; then
        echo "   FastAPI+NextJS manual: $manual_equiv files"
        if [[ $((webapp_files - manual_equiv)) -gt 5 ]] || [[ $((manual_equiv - webapp_files)) -gt 5 ]]; then
            echo "   ⚠️  Significant file count difference!"
        fi
    fi
fi
echo

# Summary of findings
echo "### Quick Directory Structure Summary ###"
echo
echo "Projects with key directories:"
src_count=$(find "$TEST_DIR"/*/src -maxdepth 0 2>/dev/null | wc -l)
fastapi_count=$(find "$TEST_DIR"/*/fastapi -maxdepth 0 2>/dev/null | wc -l)
nextjs_count=$(find "$TEST_DIR"/*/nextjs -maxdepth 0 2>/dev/null | wc -l)
compose_count=$(find "$TEST_DIR"/*/docker-compose.yml 2>/dev/null | wc -l)
echo "- With src/: ${src_count:-0}"
echo "- With fastapi/: ${fastapi_count:-0}"
echo "- With nextjs/: ${nextjs_count:-0}"
echo "- With docker-compose.yml: ${compose_count:-0}"
echo

# Failed tests
if [[ -f "$TEST_DIR/failed-tests.log" ]]; then
    echo "### Failed Tests ###"
    cat "$TEST_DIR/failed-tests.log"
else
    echo "No failed tests recorded! 🎉"
fi

echo
echo "For detailed inspection, review:"
echo "  $TEST_DIR/MASTER-CHECKLIST.md"
echo "  Individual INSPECT.md files in each project"