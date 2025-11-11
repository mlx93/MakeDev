#!/bin/bash
# Perfect workflow: Just run make dev SUBDIR=test-app from tool directory!
# Run from ZeroToRunDevEnv root: bash tests/test-perfect-workflow.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$TOOL_ROOT"

echo "🧪 Testing perfect workflow:"
echo "Running from ZeroToRunDevEnv directory:"
echo "make dev SUBDIR=test-app"
echo ""
echo "This will:"
echo "  1. Create test-app/ subdirectory"
echo "  2. Set up tool infrastructure"
echo "  3. Scaffold hello world app"
echo "  4. Start all services"
echo ""

make dev SUBDIR=test-app
