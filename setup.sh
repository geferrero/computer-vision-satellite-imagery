#!/usr/bin/env bash
set -euo pipefail

REQUIRED_MAJOR=3
REQUIRED_MINOR=11
VENV_DIR=".venv"
KERNEL_NAME="computer-vision-project"
KERNEL_DISPLAY_NAME="Python 3.11 (Computer Vision Project)"

# Always work from the directory where this script lives.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Checking for Python ${REQUIRED_MAJOR}.${REQUIRED_MINOR}..."

PYTHON_CMD=""
for candidate in python3.11 python3 python; do
    if command -v "$candidate" >/dev/null 2>&1; then
        if "$candidate" -c "import sys; raise SystemExit(0 if sys.version_info[:2] == (${REQUIRED_MAJOR}, ${REQUIRED_MINOR}) else 1)"; then
            PYTHON_CMD="$candidate"
            break
        fi
    fi
done

if [[ -z "$PYTHON_CMD" ]]; then
    echo "ERROR: Python ${REQUIRED_MAJOR}.${REQUIRED_MINOR} is required but was not found."
    echo "Install Python ${REQUIRED_MAJOR}.${REQUIRED_MINOR} and run this script again."
    exit 1
fi

PYTHON_VERSION="$($PYTHON_CMD --version 2>&1)"
echo "    Found: $PYTHON_VERSION"

if [[ ! -f "requirements.txt" ]]; then
    echo "ERROR: requirements.txt was not found in: $SCRIPT_DIR"
    exit 1
fi

if [[ ! -d "$VENV_DIR" ]]; then
    echo "==> Creating virtual environment in $VENV_DIR..."
    "$PYTHON_CMD" -m venv "$VENV_DIR"
else
    echo "==> Virtual environment already exists: $VENV_DIR"
fi

VENV_PYTHON="$VENV_DIR/bin/python"

if [[ ! -x "$VENV_PYTHON" ]]; then
    echo "ERROR: The virtual environment is invalid or incomplete."
    echo "Delete '$VENV_DIR' and run this script again."
    exit 1
fi

echo "==> Upgrading pip..."
"$VENV_PYTHON" -m pip install --upgrade pip

echo "==> Installing dependencies from requirements.txt..."
"$VENV_PYTHON" -m pip install -r requirements.txt

echo "==> Checking installed dependencies..."
"$VENV_PYTHON" -m pip check

echo "==> Registering Jupyter kernel..."
"$VENV_PYTHON" -m ipykernel install --user --name "$KERNEL_NAME" --display-name "$KERNEL_DISPLAY_NAME"

echo
echo "Setup completed successfully."
echo "Activate the environment with:"
echo "  source .venv/bin/activate"
echo
echo "Then start Jupyter with:"
echo "  jupyter notebook"
