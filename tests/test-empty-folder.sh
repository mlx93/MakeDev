#!/bin/bash
# Test: Empty folder should be treated as greenfield
# Run from ZeroToRunDevEnv root: bash tests/test-empty-folder.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$TOOL_ROOT"

echo "🧪 Testing empty folder scenario:"
echo "1. Creating empty test-app folder..."
mkdir -p test-app-empty
# Don't add any files - keep it empty

echo "2. Running make dev SUBDIR=test-app-empty"
echo "   Should detect empty folder and scaffold greenfield project"
make dev SUBDIR=test-app-empty
