#!/bin/bash
# Simple test: Create subfolder and run dev script
# Run from ZeroToRunDevEnv root: bash tests/test-simple-workflow.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$TOOL_ROOT"

echo "🧪 Testing simple workflow:"
echo "1. Creating test-app subfolder..."
mkdir -p test-app
cd test-app

echo "2. Copying dev script..."
cp "$TOOL_ROOT/dev" .

echo "3. Running ./dev (no Makefile needed!)"
./dev
