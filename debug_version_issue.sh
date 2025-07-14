#\!/bin/bash
# Debug version resolution issue

export SPINBOX_PROJECT_ROOT="/Users/gonzalo/code/spinbox"

# Source the main CLI script functions without executing main
source "$SPINBOX_PROJECT_ROOT/lib/utils.sh"
source "$SPINBOX_PROJECT_ROOT/lib/config.sh"
source "$SPINBOX_PROJECT_ROOT/lib/version-config.sh"

echo "=== Initial state ==="
echo "CLI_PYTHON_VERSION: '$CLI_PYTHON_VERSION'"
echo "PYTHON_VERSION: '$PYTHON_VERSION'"
echo "get_effective_python_version: $(get_effective_python_version)"
echo "get_python_image_tag: $(get_python_image_tag)"

echo -e "\n=== Setting CLI override ==="
set_cli_python_version "3.11"
echo "CLI_PYTHON_VERSION: '$CLI_PYTHON_VERSION'"
echo "PYTHON_VERSION: '$PYTHON_VERSION'"
echo "get_effective_python_version: $(get_effective_python_version)"
echo "get_python_image_tag: $(get_python_image_tag)"

echo -e "\n=== Exporting and re-sourcing ==="
export CLI_PYTHON_VERSION
source "$SPINBOX_PROJECT_ROOT/lib/version-config.sh"
echo "CLI_PYTHON_VERSION: '$CLI_PYTHON_VERSION'"
echo "PYTHON_VERSION: '$PYTHON_VERSION'"
echo "get_effective_python_version: $(get_effective_python_version)"
echo "get_python_image_tag: $(get_python_image_tag)"
