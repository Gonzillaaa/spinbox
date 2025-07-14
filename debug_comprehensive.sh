#\!/bin/bash
# This simulates exactly what the main CLI does

export SPINBOX_PROJECT_ROOT="/Users/gonzalo/code/spinbox"

# Initialize exactly like the main CLI
source "$SPINBOX_PROJECT_ROOT/lib/utils.sh"
source "$SPINBOX_PROJECT_ROOT/lib/config.sh"
source "$SPINBOX_PROJECT_ROOT/lib/profiles.sh"
source "$SPINBOX_PROJECT_ROOT/lib/version.sh"
source "$SPINBOX_PROJECT_ROOT/lib/version-config.sh"
source "$SPINBOX_PROJECT_ROOT/lib/update.sh"

init_logging "test"
init_config

echo "=== After CLI initialization ==="
echo "PYTHON_VERSION: '$PYTHON_VERSION'"
echo "CLI_PYTHON_VERSION: '$CLI_PYTHON_VERSION'"
echo "get_effective_python_version: $(get_effective_python_version)"

# Apply version overrides (like the CLI does)
apply_version_overrides

echo -e "\n=== After apply_version_overrides ==="
echo "PYTHON_VERSION: '$PYTHON_VERSION'"
echo "CLI_PYTHON_VERSION: '$CLI_PYTHON_VERSION'"
echo "get_effective_python_version: $(get_effective_python_version)"

# Export variables (like the CLI does)
export CLI_PYTHON_VERSION CLI_NODE_VERSION CLI_POSTGRES_VERSION CLI_REDIS_VERSION
export PYTHON_VERSION NODE_VERSION POSTGRES_VERSION REDIS_VERSION

echo -e "\n=== After exports ==="
echo "PYTHON_VERSION: '$PYTHON_VERSION'"
echo "CLI_PYTHON_VERSION: '$CLI_PYTHON_VERSION'"
echo "get_effective_python_version: $(get_effective_python_version)"

# Source project generator (like the CLI does)
source "$SPINBOX_PROJECT_ROOT/lib/project-generator.sh"

echo -e "\n=== After sourcing project-generator.sh ==="
echo "PYTHON_VERSION: '$PYTHON_VERSION'"
echo "CLI_PYTHON_VERSION: '$CLI_PYTHON_VERSION'"
echo "get_effective_python_version: $(get_effective_python_version)"

# Test the version source detection logic (like show_version_configuration does)
echo -e "\n=== Version source detection ==="
if [[ -n "$CLI_PYTHON_VERSION" ]]; then
    echo "Source: CLI flag (CLI_PYTHON_VERSION='$CLI_PYTHON_VERSION')"
elif [[ -n "$PYTHON_VERSION" ]]; then
    echo "Source: config file (PYTHON_VERSION='$PYTHON_VERSION')"
else
    echo "Source: default"
fi
