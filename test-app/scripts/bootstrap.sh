#!/bin/bash
# Bootstrap script - sets up tool infrastructure in current directory
# Usage: Run this from a new project folder, then run 'make dev'

set -e

CURRENT_DIR="$(pwd)"
SCRIPT_SOURCE="${BASH_SOURCE[0]}"

# Find the tool repository (where this script lives)
if [ -f "$SCRIPT_SOURCE" ]; then
    # If script exists, use its location
    TOOL_REPO="$(cd "$(dirname "$SCRIPT_SOURCE")/.." && pwd)"
else
    # Otherwise, search for it
    TOOL_REPO=""
    SEARCH_DIR="$CURRENT_DIR"
    while [ "$SEARCH_DIR" != "/" ]; do
        if [ -f "$SEARCH_DIR/Makefile" ] && [ -d "$SEARCH_DIR/docker" ] && [ -d "$SEARCH_DIR/scripts" ]; then
            TOOL_REPO="$SEARCH_DIR"
            break
        fi
        SEARCH_DIR="$(dirname "$SEARCH_DIR")"
    done
    
    # Check environment variable or common locations
    if [ -z "$TOOL_REPO" ]; then
        if [ -n "$ZERO_TO_RUN_TOOL_PATH" ] && [ -d "$ZERO_TO_RUN_TOOL_PATH" ]; then
            TOOL_REPO="$ZERO_TO_RUN_TOOL_PATH"
        elif [ -d "$HOME/zero-to-running-dev-env" ]; then
            TOOL_REPO="$HOME/zero-to-running-dev-env"
        elif [ -d "$HOME/Desktop/ZeroToRunDevEnv" ]; then
            TOOL_REPO="$HOME/Desktop/ZeroToRunDevEnv"
        fi
    fi
fi

if [ -z "$TOOL_REPO" ] || [ ! -d "$TOOL_REPO" ]; then
    echo "❌ Could not find tool repository"
    echo "   Please run this script from within the tool repository, or"
    echo "   set ZERO_TO_RUN_TOOL_PATH environment variable"
    exit 1
fi

echo "🔧 Bootstrapping project in: $CURRENT_DIR"
echo "   Using tool repository: $TOOL_REPO"
echo ""

# Copy tool infrastructure
echo "📦 Copying tool files..."
# Get the subdirectory name to exclude it
SUBDIR_NAME=$(basename "$CURRENT_DIR")
rsync -av --exclude='.git' \
          --exclude='node_modules' \
          --exclude='frontend' \
          --exclude='backend' \
          --exclude='.env' \
          --exclude='*.md' \
          --exclude='agent_prompts' \
          --exclude='example-task-app' \
          --exclude="$SUBDIR_NAME" \
          "$TOOL_REPO/" "$CURRENT_DIR/" 2>/dev/null || {
    # Fallback: copy specific directories/files
    echo "   Using fallback copy method..."
    [ -d "$TOOL_REPO/docker" ] && cp -r "$TOOL_REPO/docker" "$CURRENT_DIR/"
    [ -d "$TOOL_REPO/scripts" ] && cp -r "$TOOL_REPO/scripts" "$CURRENT_DIR/"
    # Copy Makefile (use subdir version if in subdirectory, otherwise full Makefile)
    if [ "$CURRENT_DIR" != "$TOOL_REPO" ]; then
        # We're in a subdirectory, copy the full Makefile
        cp "$TOOL_REPO/Makefile" "$CURRENT_DIR/"
    else
        # We're in the tool repo itself, just ensure Makefile exists
        [ -f "$TOOL_REPO/Makefile" ] && cp "$TOOL_REPO/Makefile" "$CURRENT_DIR/" || true
    fi
    [ -d "$TOOL_REPO/scaffold-templates" ] && cp -r "$TOOL_REPO/scaffold-templates" "$CURRENT_DIR/"
    [ -f "$TOOL_REPO/config.yaml.example" ] && cp "$TOOL_REPO/config.yaml.example" "$CURRENT_DIR/"
}

# Create config.yaml if it doesn't exist
if [ ! -f "config.yaml" ]; then
    echo "📝 Creating config.yaml..."
    cp config.yaml.example config.yaml
    
    # Set empty git_repo for scaffolding
    sed -i.bak 's/git_repo:.*/git_repo: ""/' config.yaml 2>/dev/null || \
    sed -i '' 's/git_repo:.*/git_repo: ""/' config.yaml 2>/dev/null || true
    rm -f config.yaml.bak 2>/dev/null || true
    
    echo "   ✅ Created config.yaml with empty git_repo (will scaffold new app)"
fi

echo ""
echo "✅ Bootstrap complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Edit config.yaml if needed (project.name, etc.)"
echo "   2. make dev"
echo ""

