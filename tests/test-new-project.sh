#!/bin/bash
# Helper script to test the tool in a fresh directory (simulates new developer experience)
# Usage: bash tests/test-new-project.sh [project-name]
# Creates a subfolder in the current directory, or use absolute path
# Run from ZeroToRunDevEnv root: bash tests/test-new-project.sh [project-name]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Get target directory from argument or use default
PROJECT_NAME="${1:-my-new-app}"

# If absolute path provided, use it; otherwise create relative to tool root
if [[ "$PROJECT_NAME" == /* ]]; then
    TARGET_DIR="$PROJECT_NAME"
else
    TARGET_DIR="$TOOL_ROOT/$PROJECT_NAME"
fi

echo "🧪 Setting up test project in: $TARGET_DIR"
echo ""

# Create target directory
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

# Copy tool files (excluding git, node_modules, and scaffolded apps)
echo "📦 Copying tool files..."
rsync -av --exclude='.git' \
          --exclude='node_modules' \
          --exclude='frontend' \
          --exclude='backend' \
          --exclude='.env' \
          "$TOOL_ROOT/" "$TARGET_DIR/"

# Copy config template
if [ ! -f "config.yaml" ]; then
    echo "📝 Creating config.yaml..."
    cp config.yaml.example config.yaml
    
    # Set empty git_repo for scaffolding
    if command -v yq &> /dev/null; then
        yq eval '.project.git_repo = ""' -i config.yaml
    else
        # Fallback: use sed
        sed -i.bak 's/git_repo:.*/git_repo: ""/' config.yaml
        rm -f config.yaml.bak
    fi
    
    echo "✅ Created config.yaml with empty git_repo (will scaffold new app)"
else
    echo "⚠️  config.yaml already exists, skipping"
fi

echo ""
echo "✅ Test project setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. cd $TARGET_DIR"
echo "   2. Edit config.yaml if needed (project.name, etc.)"
echo "   3. make dev"
echo ""
echo "This will scaffold a hello world app in this directory."
echo ""
echo "💡 To make this its own git repo:"
echo "   cd $TARGET_DIR"
echo "   git init"
echo "   git add ."
echo "   git commit -m 'Initial commit'"
echo "   # Then push to GitHub: git remote add origin <your-repo-url>"

