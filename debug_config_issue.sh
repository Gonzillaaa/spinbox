#\!/bin/bash
export SPINBOX_PROJECT_ROOT="/Users/gonzalo/code/spinbox"
source "$SPINBOX_PROJECT_ROOT/lib/utils.sh"
source "$SPINBOX_PROJECT_ROOT/lib/config.sh"
source "$SPINBOX_PROJECT_ROOT/lib/version-config.sh"

# Initialize config
init_config

echo "=== After init_config ==="
echo "PYTHON_VERSION: '$PYTHON_VERSION'"
echo "CLI_PYTHON_VERSION: '$CLI_PYTHON_VERSION'"
echo "get_effective_python_version: $(get_effective_python_version)"

# Test the version source detection logic
echo -e "\n=== Version source detection ==="
echo "CLI_PYTHON_VERSION empty?: $(if [[ -n "$CLI_PYTHON_VERSION" ]]; then echo "NO"; else echo "YES"; fi)"
echo "PYTHON_VERSION empty?: $(if [[ -n "$PYTHON_VERSION" ]]; then echo "NO"; else echo "YES"; fi)"

if [[ -n "$CLI_PYTHON_VERSION" ]]; then
    echo "Source: CLI flag"
elif [[ -n "$PYTHON_VERSION" ]]; then
    echo "Source: config file"
else
    echo "Source: default"
fi
