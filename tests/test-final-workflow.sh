#!/bin/bash
# Final test: Just create folder and run make dev (truly zero setup!)
# Run from ZeroToRunDevEnv root: bash tests/test-final-workflow.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$TOOL_ROOT"

echo "🧪 Testing final workflow:"
echo "1. Creating test-app subfolder..."
mkdir -p test-app
cd test-app

echo "2. Running make dev using wrapper (no Makefile needed!)"
bash "$TOOL_ROOT/make-wrapper.sh" dev
