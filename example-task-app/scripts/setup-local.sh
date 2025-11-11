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

# Cleanup function: stop containers using required ports and old project containers
cleanup_ports_and_containers() {
    echo "🧹 Cleaning up ports and old containers..."
    
    # Check and stop any container using port 5432 (PostgreSQL)
    PORT_5432_CONTAINER=$(docker ps --filter "publish=5432" --format "{{.ID}}" | head -1)
    if [ -n "$PORT_5432_CONTAINER" ]; then
        CONTAINER_NAME=$(docker ps --filter "id=$PORT_5432_CONTAINER" --format "{{.Names}}")
        echo "   ⚠️  Port 5432 is in use by container: $CONTAINER_NAME"
        echo "   Stopping container..."
        docker stop "$PORT_5432_CONTAINER" > /dev/null 2>&1 || true
        docker rm "$PORT_5432_CONTAINER" > /dev/null 2>&1 || true
        echo "   ✅ Freed port 5432"
    fi
    
    # Check and stop any container using port 6379 (Redis) - only if it's our project
    PORT_6379_CONTAINER=$(docker ps --filter "publish=6379" --format "{{.ID}}" | head -1)
    if [ -n "$PORT_6379_CONTAINER" ]; then
        CONTAINER_NAME=$(docker ps --filter "id=$PORT_6379_CONTAINER" --format "{{.Names}}")
        # Only stop if it matches our project name pattern
        if echo "$CONTAINER_NAME" | grep -q "^${PROJECT_NAME}-"; then
            echo "   ⚠️  Port 6379 is in use by our container: $CONTAINER_NAME"
            echo "   Stopping container..."
            docker stop "$PORT_6379_CONTAINER" > /dev/null 2>&1 || true
            docker rm "$PORT_6379_CONTAINER" > /dev/null 2>&1 || true
            echo "   ✅ Freed port 6379"
        fi
    fi
    
    # Stop and remove any old containers from this project that might be unhealthy
    OLD_CONTAINERS=$(docker ps -a --filter "name=^${PROJECT_NAME}-" --format "{{.ID}}" 2>/dev/null || true)
    if [ -n "$OLD_CONTAINERS" ]; then
        echo "   🧹 Cleaning up old project containers..."
        echo "$OLD_CONTAINERS" | while read -r container_id; do
            if [ -n "$container_id" ]; then
                container_name=$(docker ps -a --filter "id=$container_id" --format "{{.Names}}")
                echo "      Stopping: $container_name"
                docker stop "$container_id" > /dev/null 2>&1 || true
                docker rm "$container_id" > /dev/null 2>&1 || true
            fi
        done
        echo "   ✅ Cleaned up old containers"
    fi
    
    # Also try docker-compose down if docker-compose.yml exists (in case of partial state)
    if [ -d "docker" ] && [ -f "docker/docker-compose.yml" ]; then
        cd docker
        if docker-compose ps 2>/dev/null | grep -q "Up"; then
            echo "   🧹 Stopping any remaining docker-compose services..."
            docker-compose down > /dev/null 2>&1 || true
            echo "   ✅ Cleaned up docker-compose services"
        fi
        cd ..
    fi
}

# Run cleanup before starting services
cleanup_ports_and_containers

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

# Generate package-lock.json files if missing or invalid (required for npm ci in Docker)
echo "📦 Checking for package-lock.json files..."
cd "$REPO_ROOT"

# Track if any lock files were regenerated (requires Docker rebuild without cache)
LOCK_FILE_REGENERATED=false

# Function to ensure lock file is valid and complete
ensure_lock_file() {
    local dir=$1
    local name=$2
    
    if [ ! -d "$dir" ] || [ ! -f "$dir/package.json" ]; then
        return 0
    fi
    
    cd "$dir"
    
    # Always regenerate lock file to ensure it's complete and up-to-date
    # This is safer than trying to validate an existing one
    if [ -f "package-lock.json" ]; then
        # Check if package.json is newer than lock file
        if [ "package.json" -nt "package-lock.json" ]; then
            echo "   ⚠️  $name package.json is newer than lock file, regenerating..."
            rm -f package-lock.json node_modules -rf
            LOCK_FILE_REGENERATED=true
        else
            # Try a dry-run of npm ci to verify lock file is valid
            if ! npm ci --dry-run > /dev/null 2>&1; then
                echo "   ⚠️  $name lock file has dependency issues, regenerating..."
                rm -f package-lock.json node_modules -rf
                LOCK_FILE_REGENERATED=true
            else
                echo "   ✅ $name lock file is valid"
                cd ..
                return 0
            fi
        fi
    else
        echo "   ⚠️  $name lock file missing, generating..."
        LOCK_FILE_REGENERATED=true
    fi
    
    # Generate lock file with full npm install
    if [ "$LOCK_FILE_REGENERATED" = true ] || [ ! -f "package-lock.json" ]; then
        echo "   Generating $name/package-lock.json (running npm install)..."
        # Use npm install (NOT --package-lock-only) to ensure all dependencies are properly resolved
        # Suppress verbose output but show errors
        if npm install > /tmp/npm-install-$name.log 2>&1; then
            if [ -f "package-lock.json" ]; then
                echo "   ✅ $name lock file generated successfully"
                LOCK_FILE_REGENERATED=true
            else
                echo "   ❌ Failed to generate $name lock file"
                cat /tmp/npm-install-$name.log
                cd ..
                return 1
            fi
        else
            echo "   ❌ npm install failed for $name"
            cat /tmp/npm-install-$name.log
            cd ..
            return 1
        fi
        rm -f /tmp/npm-install-$name.log
    fi
    
    cd ..
    return 0
}

# Ensure frontend lock file
ensure_lock_file "frontend" "Frontend"

# Ensure backend lock file
ensure_lock_file "backend" "Backend"

# Check if lock files are newer than Docker images (indicates need for rebuild without cache)
FORCE_REBUILD=false
if [ -f "$REPO_ROOT/backend/package-lock.json" ]; then
    LOCK_FILE_TIME=$(stat -f "%m" "$REPO_ROOT/backend/package-lock.json" 2>/dev/null || stat -c "%Y" "$REPO_ROOT/backend/package-lock.json" 2>/dev/null || echo "0")
    IMAGE_TIME=$(docker images docker-backend:latest --format "{{.CreatedAt}}" 2>/dev/null | xargs -I {} date -j -f "%Y-%m-%d %H:%M:%S" "{}" "+%s" 2>/dev/null || docker images docker-backend:latest --format "{{.CreatedAt}}" 2>/dev/null | xargs -I {} date -d "{}" "+%s" 2>/dev/null || echo "0")
    if [ "$LOCK_FILE_TIME" -gt "$IMAGE_TIME" ] 2>/dev/null; then
        FORCE_REBUILD=true
        echo "   ⚠️  Lock file is newer than Docker image, forcing rebuild..."
    fi
fi

# Check if containers are already running
cd docker
if docker-compose ps | grep -q "Up"; then
    echo "⚠️  Some containers are already running"
    
    # If we need to rebuild, stop containers and remove volumes now
    if [ "$LOCK_FILE_REGENERATED" = true ] || [ "$FORCE_REBUILD" = true ]; then
        echo "   Lock files changed - need to rebuild. Stopping containers and removing volumes..."
        docker-compose down -v
        cd ..
    else
        # No rebuild needed, check if healthy
        echo "   Checking if they're healthy (30s timeout)..."
        cd ..
        if "$SCRIPT_DIR/health-check.sh" 30 2>&1; then
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
            echo "   Containers are running but not healthy, stopping..."
            cd docker
            docker-compose down
            cd ..
        fi
    fi
else
    cd ..
fi

# Stop any existing containers for this project before rebuilding (ensures fresh build)
# Note: docker-compose only affects containers defined in this project's docker-compose.yml
cd docker
if docker-compose ps -a 2>/dev/null | grep -q "Up\|Exit"; then
    echo "🛑 Stopping existing project containers before rebuild..."
    # Remove volumes if forcing rebuild to ensure fresh node_modules
    if [ "$LOCK_FILE_REGENERATED" = true ] || [ "$FORCE_REBUILD" = true ]; then
        docker-compose down -v > /dev/null 2>&1 || true
    else
        docker-compose down > /dev/null 2>&1 || true
    fi
fi
cd ..

# Build Docker images
cd "$PROJECT_ROOT/docker"

# Check if lock files are newer than Docker images (indicates need for rebuild without cache)
FORCE_REBUILD=false
if [ -f "../backend/package-lock.json" ]; then
    LOCK_FILE_TIME=$(stat -f "%m" "../backend/package-lock.json" 2>/dev/null || stat -c "%Y" "../backend/package-lock.json" 2>/dev/null || echo "0")
    IMAGE_TIME=$(docker images docker-backend:latest --format "{{.CreatedAt}}" 2>/dev/null | xargs -I {} date -j -f "%Y-%m-%d %H:%M:%S" "{}" "+%s" 2>/dev/null || docker images docker-backend:latest --format "{{.CreatedAt}}" 2>/dev/null | xargs -I {} date -d "{}" "+%s" 2>/dev/null || echo "0")
    if [ "$LOCK_FILE_TIME" -gt "$IMAGE_TIME" ] 2>/dev/null; then
        FORCE_REBUILD=true
        echo "   ⚠️  Lock file is newer than Docker image, forcing rebuild..."
    fi
fi

if [ "$LOCK_FILE_REGENERATED" = true ] || [ "$FORCE_REBUILD" = true ]; then
    echo "🔨 Building Docker images (without cache - lock files changed)..."
    docker-compose build --no-cache
    # Stop and remove existing containers to ensure they use the new image
    echo "   Stopping existing containers to use new image..."
    docker-compose down > /dev/null 2>&1 || true
else
    echo "🔨 Building Docker images..."
    docker-compose build
fi

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

