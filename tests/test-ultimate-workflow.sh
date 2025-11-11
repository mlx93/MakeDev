#!/bin/bash
# Ultimate test: Just create folder and run make dev (no setup needed!)
# Run from ZeroToRunDevEnv root: bash tests/test-ultimate-workflow.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$TOOL_ROOT"

echo "🧪 Testing ultimate workflow:"
echo "1. Creating test-app subfolder..."
mkdir -p test-app
cd test-app

echo "2. Running make dev directly (no Makefile, no setup!)"
echo "   (Makefile will be auto-created)"
make -C . -f "$TOOL_ROOT/Makefile" dev
