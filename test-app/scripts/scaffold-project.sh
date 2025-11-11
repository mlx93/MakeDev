#!/bin/bash
# Generate "hello world" level project structure
#
# SAFETY: This script ONLY creates/modifies files in $PROJECT_ROOT (the subdirectory).
# It NEVER modifies files in parent directories.
# All operations use $PROJECT_ROOT, $FRONTEND_PATH, or $BACKEND_PATH which are
# relative to the subdirectory where the script is executed.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$PROJECT_ROOT/scaffold-templates"

cd "$PROJECT_ROOT"

# Read config.yaml
if [ ! -f "config.yaml" ]; then
    echo "❌ config.yaml not found"
    exit 1
fi

# Parse config.yaml
PROJECT_NAME=$(grep -A 1 "^project:" config.yaml | grep "name:" | sed 's/.*name: *"\(.*\)".*/\1/' | sed 's/.*name: *\(.*\)/\1/' | head -1 | tr -d ' ')
FRONTEND_PATH=$(grep -A 2 "^services:" config.yaml | grep -A 1 "frontend:" | grep "path:" | sed 's/.*path: *"\(.*\)".*/\1/' | sed 's/.*path: *\(.*\)/\1/' | head -1 | tr -d ' ')
BACKEND_PATH=$(grep -A 2 "^services:" config.yaml | grep -A 1 "backend:" | grep "path:" | sed 's/.*path: *"\(.*\)".*/\1/' | sed 's/.*path: *\(.*\)/\1/' | head -1 | tr -d ' ')

# Defaults
PROJECT_NAME=${PROJECT_NAME:-my-app}
FRONTEND_PATH=${FRONTEND_PATH:-./frontend}
BACKEND_PATH=${BACKEND_PATH:-./backend}

echo "🏗️  Scaffolding project: $PROJECT_NAME"
echo "   Frontend: $FRONTEND_PATH"
echo "   Backend: $BACKEND_PATH"

# Check if directories already exist
if [ -d "$FRONTEND_PATH" ] || [ -d "$BACKEND_PATH" ]; then
    echo "❌ frontend/ or backend/ directories already exist"
    echo "   Remove them first or use a different path in config.yaml"
    exit 1
fi

# Check if templates directory exists
if [ ! -d "$TEMPLATES_DIR" ]; then
    echo "❌ scaffold-templates/ directory not found"
    echo "   Expected: $TEMPLATES_DIR"
    exit 1
fi

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p "$FRONTEND_PATH/src"
mkdir -p "$BACKEND_PATH/src/routes"
mkdir -p "$BACKEND_PATH/prisma"

# Copy frontend templates
echo "📦 Copying frontend templates..."
cp -r "$TEMPLATES_DIR/frontend/"* "$FRONTEND_PATH/" 2>/dev/null || {
    # If templates don't exist, create minimal structure
    echo "   Creating minimal frontend structure..."
    mkdir -p "$FRONTEND_PATH/src"
}

# Copy backend templates
echo "📦 Copying backend templates..."
cp -r "$TEMPLATES_DIR/backend/"* "$BACKEND_PATH/" 2>/dev/null || {
    # If templates don't exist, create minimal structure
    echo "   Creating minimal backend structure..."
    mkdir -p "$BACKEND_PATH/src/routes"
    mkdir -p "$BACKEND_PATH/prisma"
}

# Copy root templates
echo "📦 Copying root templates..."
if [ -d "$TEMPLATES_DIR/root" ]; then
    cp -r "$TEMPLATES_DIR/root/"* "$PROJECT_ROOT/" 2>/dev/null || true
fi

# Replace template variables in files
echo "🔧 Replacing template variables..."
find "$FRONTEND_PATH" "$BACKEND_PATH" -type f -name "*.json" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.prisma" 2>/dev/null | while read -r file; do
    if [ -f "$file" ]; then
        sed -i.bak "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" "$file" 2>/dev/null || true
        sed -i.bak "s/{{FRONTEND_PORT}}/3000/g" "$file" 2>/dev/null || true
        sed -i.bak "s/{{BACKEND_PORT}}/8080/g" "$file" 2>/dev/null || true
        rm -f "${file}.bak" 2>/dev/null || true
    fi
done

# Install frontend dependencies
echo "📥 Installing frontend dependencies..."
cd "$FRONTEND_PATH"
if [ -f "package.json" ]; then
    npm install
else
    echo "   ⚠️  package.json not found, skipping npm install"
fi

# Install backend dependencies
echo "📥 Installing backend dependencies..."
cd "$PROJECT_ROOT/$BACKEND_PATH"
if [ -f "package.json" ]; then
    npm install
    
    # Generate Prisma client
    if [ -f "prisma/schema.prisma" ]; then
        echo "🔧 Generating Prisma client..."
        npx prisma generate
    fi
else
    echo "   ⚠️  package.json not found, skipping npm install"
fi

# Initialize Git repository (if not already initialized)
cd "$PROJECT_ROOT"
if [ ! -d ".git" ]; then
    echo "🔧 Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial scaffold from zero-to-running-dev-env" || true
else
    echo "   Git repository already initialized, skipping"
fi

echo ""
echo "✅ Project scaffolded successfully!"
echo ""
echo "📋 Next steps:"
echo "   1. Run: make dev"
echo "   2. Open: http://localhost:3000"
echo "   3. Backend API: http://localhost:8080/health"
echo ""

