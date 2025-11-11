#!/bin/bash
# Test workflow: Create subfolder and run make dev
# Run from ZeroToRunDevEnv root: bash tests/test-workflow.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$TOOL_ROOT"

echo "🧪 Testing workflow:"
echo "1. Creating test-app subfolder..."
mkdir -p test-app
cd test-app

echo "2. Copying minimal Makefile..."
cp "$TOOL_ROOT/Makefile.minimal" Makefile

echo "3. Running make dev..."
echo "   (This will bootstrap tool infrastructure and scaffold app)"
make dev
