#!/bin/bash
# Local development environment setup orchestration
#
# SAFETY: This script ONLY creates/modifies files in $PROJECT_ROOT (the subdirectory).
# When run from a subdirectory, $PROJECT_ROOT is the subdirectory, not the tool repo root.
# All file operations use $PROJECT_ROOT or relative paths from the current directory.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Auto-detect if tool infrastructure is missing and set it up
# This allows running make dev from a new folder (subdirectory of tool repo)
if [ ! -d "docker" ] || [ ! -d "scripts" ] || [ ! -f "Makefile" ]; then
    echo "🔧 Detected new project folder - setting up tool infrastructure..."
    
    # Try to find the tool repository
    TOOL_REPO=""
    
    # Check if we're in a subdirectory of the tool repo
    CURRENT_DIR="$PROJECT_ROOT"
    while [ "$CURRENT_DIR" != "/" ]; do
        PARENT_DIR="$(dirname "$CURRENT_DIR")"
        if [ -f "$PARENT_DIR/Makefile" ] && [ -d "$PARENT_DIR/docker" ] && [ -d "$PARENT_DIR/scripts" ]; then
            TOOL_REPO="$PARENT_DIR"
            break
        fi
        CURRENT_DIR="$PARENT_DIR"
    done
    
    # If not found, check environment variable or common locations
    if [ -z "$TOOL_REPO" ]; then
        if [ -n "$ZERO_TO_RUN_TOOL_PATH" ] && [ -d "$ZERO_TO_RUN_TOOL_PATH" ]; then
            TOOL_REPO="$ZERO_TO_RUN_TOOL_PATH"
        elif [ -d "$HOME/zero-to-running-dev-env" ]; then
            TOOL_REPO="$HOME/zero-to-running-dev-env"
        elif [ -d "$HOME/Desktop/ZeroToRunDevEnv" ]; then
            TOOL_REPO="$HOME/Desktop/ZeroToRunDevEnv"
        fi
    fi
    
    if [ -n "$TOOL_REPO" ] && [ -d "$TOOL_REPO" ]; then
        echo "   Found tool repository at: $TOOL_REPO"
        echo "   Copying tool infrastructure..."
        
        # Use bootstrap script if available, otherwise copy manually
        if [ -f "$TOOL_REPO/scripts/bootstrap.sh" ]; then
            bash "$TOOL_REPO/scripts/bootstrap.sh"
        else
            # Fallback: copy specific directories/files
            cp -r "$TOOL_REPO/docker" "$PROJECT_ROOT/" 2>/dev/null || true
            cp -r "$TOOL_REPO/scripts" "$PROJECT_ROOT/" 2>/dev/null || true
            cp "$TOOL_REPO/Makefile" "$PROJECT_ROOT/" 2>/dev/null || true
            cp -r "$TOOL_REPO/scaffold-templates" "$PROJECT_ROOT/" 2>/dev/null || true
            [ -f "$TOOL_REPO/config.yaml.example" ] && cp "$TOOL_REPO/config.yaml.example" "$PROJECT_ROOT/" 2>/dev/null || true
        fi
        
        # Update SCRIPT_DIR since we may have copied scripts
        SCRIPT_DIR="$PROJECT_ROOT/scripts"
        
        echo "   ✅ Tool infrastructure set up"
    else
        echo "   ⚠️  Could not find tool repository"
        echo "   Please run: bash <tool-repo>/scripts/bootstrap.sh"
        echo "   Or ensure you have the tool files (docker/, scripts/, Makefile) in this directory"
        exit 1
    fi
fi

# Check prerequisites
echo "🔍 Running pre-flight checks..."
"$SCRIPT_DIR/check-prerequisites.sh"

# Read config.yaml
if [ ! -f "config.yaml" ]; then
    echo "❌ config.yaml not found"
    echo "   Copy config.yaml.example to config.yaml and edit it"
    exit 1
fi

# Parse config.yaml to get project name and paths
# Using simple grep/sed for YAML parsing (assumes simple structure)
PROJECT_NAME=$(grep -A 1 "^project:" config.yaml | grep "name:" | sed 's/.*name: *"\(.*\)".*/\1/' | sed 's/.*name: *\(.*\)/\1/' | head -1 | tr -d ' ')
GIT_REPO=$(grep -A 2 "^project:" config.yaml | grep "git_repo:" | sed 's/.*git_repo: *"\(.*\)".*/\1/' | sed 's/.*git_repo: *\(.*\)/\1/' | head -1 | tr -d ' ')

# Default project name if not set
if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME="my-app"
fi

export PROJECT_NAME

# Handle repository
REPO_ROOT="$PROJECT_ROOT"
if [ -z "$GIT_REPO" ] || [ "$GIT_REPO" = '""' ] || [ "$GIT_REPO" = "null" ]; then
    echo "📦 Empty git_repo detected - checking for scaffold script..."
    if [ -f "$SCRIPT_DIR/scaffold-project.sh" ]; then
        echo "   Running scaffold-project.sh..."
        "$SCRIPT_DIR/scaffold-project.sh"
    else
        echo "   Scaffold script not found, skipping..."
    fi
else
    echo "📥 Cloning repository: $GIT_REPO"
    # If it's a relative path, use it directly
    if [[ "$GIT_REPO" == ./* ]] || [[ "$GIT_REPO" == ../* ]]; then
        echo "   Using local path: $GIT_REPO"
        REPO_ROOT="$(cd "$GIT_REPO" && pwd)"
    else
        # Clone if directory doesn't exist
        REPO_DIR=$(basename "$GIT_REPO" .git)
        if [ ! -d "$REPO_DIR" ]; then
            git clone "$GIT_REPO"
        else
            echo "   Repository already exists, skipping clone"
        fi
        REPO_ROOT="$PROJECT_ROOT/$REPO_DIR"
    fi
fi

# Check if frontend and backend directories exist
if [ ! -d "$REPO_ROOT/frontend" ] && [ ! -d "$REPO_ROOT/backend" ]; then
    echo "❌ frontend/ and backend/ directories not found in $REPO_ROOT"
    echo "   Please ensure your project structure is correct"
    echo "   Expected structure:"
    echo "     $REPO_ROOT/frontend/"
    echo "     $REPO_ROOT/backend/"
    exit 1
fi

# If repo is in a subdirectory, we need to update docker-compose paths
# For now, we'll work from the repo root or create symlinks
# Update docker-compose.yml to use the correct paths
if [ "$REPO_ROOT" != "$PROJECT_ROOT" ]; then
    echo "📁 Repository cloned to: $REPO_ROOT"
    echo "   Updating paths for Docker Compose..."
    # Create symlinks in project root pointing to repo directories
    if [ ! -L "frontend" ]; then
        ln -sf "$REPO_ROOT/frontend" frontend
    fi
    if [ ! -L "backend" ]; then
        ln -sf "$REPO_ROOT/backend" backend
    fi
fi

# Check if containers are already running
cd docker
if docker-compose ps | grep -q "Up"; then
    echo "⚠️  Some containers are already running"
    echo "   Checking if they're healthy..."
    cd ..
    if "$SCRIPT_DIR/health-check.sh" 2>/dev/null; then
        echo ""
        echo "✅ Services are already running and healthy!"
        echo ""
        echo "📋 Service URLs:"
        echo "   Frontend: http://localhost:3000"
        echo "   Backend:  http://localhost:8080"
        echo "   Health:   http://localhost:8080/health"
        echo ""
        exit 0
    else
        echo "   Containers are running but not healthy, restarting..."
        cd docker
        docker-compose down
    fi
fi

# Build Docker images
echo "🔨 Building Docker images..."
docker-compose build

# Start services
echo "🚀 Starting services..."
docker-compose up -d

# Wait for health checks
echo "⏳ Waiting for services to be healthy..."
cd ..
"$SCRIPT_DIR/health-check.sh"

# Display success message
echo ""
echo "✅ Local development environment is ready!"
echo ""
echo "📋 Service URLs:"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:8080"
echo "   Health:   http://localhost:8080/health"
echo ""
echo "💡 Useful commands:"
echo "   View logs:    docker-compose -f docker/docker-compose.yml logs -f"
echo "   Stop:         docker-compose -f docker/docker-compose.yml down"
echo "   Clean:        docker-compose -f docker/docker-compose.yml down -v"
echo ""

