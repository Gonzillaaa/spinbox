#\!/bin/bash
export SPINBOX_PROJECT_ROOT="/Users/gonzalo/code/spinbox"

# Set some test values
PYTHON_VERSION="3.10"
CLI_PYTHON_VERSION=""

echo "=== Before sourcing config.sh ==="
echo "PYTHON_VERSION: '$PYTHON_VERSION'"
echo "CLI_PYTHON_VERSION: '$CLI_PYTHON_VERSION'"

# Source config.sh (like project-generator.sh does)
source "$SPINBOX_PROJECT_ROOT/lib/config.sh"

echo -e "\n=== After sourcing config.sh ==="
echo "PYTHON_VERSION: '$PYTHON_VERSION'"
echo "CLI_PYTHON_VERSION: '$CLI_PYTHON_VERSION'"
