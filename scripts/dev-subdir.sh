#!/bin/bash
# Handle dev command with SUBDIR parameter
#
# SAFETY: This script ONLY creates/modifies files in the specified SUBDIR.
# It NEVER modifies files in the parent ZeroToRunDevEnv directory.
# All operations:
#   - Copy FROM parent TO subdirectory (read-only from parent)
#   - Create/modify files ONLY in subdirectory
#   - Never write to parent directory

set -e

SUBDIR="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Store the tool repo root for safety checks
TOOL_REPO_ROOT="$PROJECT_ROOT"

cd "$PROJECT_ROOT"

# Helper function to sync Dockerfiles (only reports when files change)
sync_dockerfiles() {
    local PARENT_ROOT="$1"
    local UPDATED=false
    
    if [ -d "$PARENT_ROOT/docker" ] && [ -d "docker" ]; then
        if [ -f "$PARENT_ROOT/docker/Dockerfile.backend" ]; then
            # If target doesn't exist or files differ, copy it
            if [ ! -f "docker/Dockerfile.backend" ] || ! cmp -s "$PARENT_ROOT/docker/Dockerfile.backend" "docker/Dockerfile.backend" 2>/dev/null; then
                cp -f "$PARENT_ROOT/docker/Dockerfile.backend" "docker/Dockerfile.backend"
                UPDATED=true
            fi
        fi
        if [ -f "$PARENT_ROOT/docker/Dockerfile.frontend" ]; then
            if [ ! -f "docker/Dockerfile.frontend" ] || ! cmp -s "$PARENT_ROOT/docker/Dockerfile.frontend" "docker/Dockerfile.frontend" 2>/dev/null; then
                cp -f "$PARENT_ROOT/docker/Dockerfile.frontend" "docker/Dockerfile.frontend"
                UPDATED=true
            fi
        fi
        if [ -f "$PARENT_ROOT/docker/docker-compose.yml" ]; then
            # Always sync docker-compose.yml - it's critical for build targets
            # Check if files differ or target doesn't exist
            if [ ! -f "docker/docker-compose.yml" ] || ! cmp -s "$PARENT_ROOT/docker/docker-compose.yml" "docker/docker-compose.yml" 2>/dev/null || ! grep -q "target:" "docker/docker-compose.yml" 2>/dev/null; then
                cp -f "$PARENT_ROOT/docker/docker-compose.yml" "docker/docker-compose.yml"
                UPDATED=true
            fi
        fi
        
        if [ "$UPDATED" = true ]; then
            echo "   🔄 Updated Dockerfiles from parent"
            return 0
        fi
    fi
    return 0  # Always return success, even if nothing was updated
}

if [ -z "$SUBDIR" ]; then
    # No SUBDIR - run normal dev
    bash "$SCRIPT_DIR/setup-local.sh"
    exit 0
fi

# SUBDIR specified
if [ -d "$SUBDIR" ]; then
    echo "📁 Found existing subdirectory: $SUBDIR"
    
    # Safety check: ensure SUBDIR is actually a subdirectory, not the tool repo root
    SUBDIR_ABS="$(cd "$SUBDIR" && pwd)"
    if [ "$SUBDIR_ABS" = "$TOOL_REPO_ROOT" ]; then
        echo "❌ Error: SUBDIR cannot be the tool repository root"
        exit 1
    fi
    
    cd "$SUBDIR"
    
    # Check if folder is empty (no config.yaml and no frontend/backend)
    if [ ! -f "config.yaml" ] && [ ! -d "frontend" ] && [ ! -d "backend" ]; then
        echo "   Empty folder detected - treating as greenfield project..."
        GREENFIELD=true
    else
        echo "   Treating as existing project..."
        GREENFIELD=false
    fi
    
    # Create Makefile if missing
    if [ ! -f "Makefile" ]; then
        echo "   Creating Makefile (include ../Makefile)"
        echo "include ../Makefile" > Makefile
    fi
    
    # Bootstrap tool infrastructure if missing
    if [ ! -d "docker" ] || [ ! -d "scripts" ]; then
        echo "   Bootstrapping tool infrastructure..."
        PARENT_ROOT="$(cd .. && pwd)"
        if [ -d "$PARENT_ROOT/docker" ] && [ -d "$PARENT_ROOT/scripts" ]; then
            # Copy from parent (we're in a subdirectory)
            cp -r "$PARENT_ROOT/docker" . 2>/dev/null || true
            cp -r "$PARENT_ROOT/scripts" . 2>/dev/null || true
            cp -r "$PARENT_ROOT/scaffold-templates" . 2>/dev/null || true
            [ -f "$PARENT_ROOT/config.yaml.example" ] && cp "$PARENT_ROOT/config.yaml.example" . 2>/dev/null || true
            # Sync Dockerfiles after copying (ensures we have latest versions)
            sync_dockerfiles "$PARENT_ROOT" || true
        elif [ -f "../scripts/bootstrap.sh" ]; then
            bash "../scripts/bootstrap.sh"
            sync_dockerfiles "$PARENT_ROOT" || true
        else
            cp -r ../docker . 2>/dev/null || true
            cp -r ../scripts . 2>/dev/null || true
            cp -r ../scaffold-templates . 2>/dev/null || true
            [ -f "../config.yaml.example" ] && cp "../config.yaml.example" . 2>/dev/null || true
            sync_dockerfiles "$PARENT_ROOT" || true
        fi
    else
        # Docker directory exists - sync Dockerfiles to get latest fixes
        PARENT_ROOT="$(cd .. && pwd)"
        sync_dockerfiles "$PARENT_ROOT" || true
        
        # Also sync config.yaml.example to ensure latest defaults
        if [ -f "$PARENT_ROOT/config.yaml.example" ]; then
            if [ ! -f "config.yaml.example" ] || ! cmp -s "$PARENT_ROOT/config.yaml.example" "config.yaml.example" 2>/dev/null; then
                cp -f "$PARENT_ROOT/config.yaml.example" "config.yaml.example"
            fi
        fi
    fi
    
    # Create minimal config.yaml if missing (only project name, git_repo, and minimal services)
    if [ ! -f "config.yaml" ]; then
        echo "   Creating minimal config.yaml for local development..."
        cat > config.yaml <<EOF
project:
  name: "$SUBDIR"
  git_repo: ""

services:
  frontend:
    path: "./frontend"
    port: 3000
  
  backend:
    path: "./backend"
    port: 8080
  
  database:
    schema_path: "./backend/prisma/schema.prisma"
  
  cache:
    enabled: true

seed:
  users: 30
  tasks_per_user: "5-10"
EOF
        echo "   ✅ Created minimal config.yaml (GCP settings will be prompted during deployment)"
    fi
    
    # Run setup-local.sh directly (avoid recursive make calls)
    bash scripts/setup-local.sh
else
    echo "🔧 Creating new project in subdirectory: $SUBDIR"
    
    # Safety check: ensure SUBDIR is not the tool repo root
    if [ "$SUBDIR" = "." ] || [ "$SUBDIR" = "$TOOL_REPO_ROOT" ]; then
        echo "❌ Error: SUBDIR cannot be the tool repository root"
        exit 1
    fi
    
    mkdir -p "$SUBDIR"
    cd "$SUBDIR"
    
    # Verify we're in a subdirectory (safety check)
    CURRENT_DIR="$(pwd)"
    if [ "$CURRENT_DIR" = "$TOOL_REPO_ROOT" ]; then
        echo "❌ Error: Cannot create project in tool repository root"
        exit 1
    fi
    
    echo "   Creating Makefile (include ../Makefile)"
    echo "include ../Makefile" > Makefile
    
    echo "   Bootstrapping tool infrastructure..."
    PARENT_ROOT="$(cd .. && pwd)"
    if [ -d "$PARENT_ROOT/docker" ] && [ -d "$PARENT_ROOT/scripts" ]; then
        # Copy from parent (we're in a subdirectory)
        cp -r "$PARENT_ROOT/docker" . 2>/dev/null || true
        cp -r "$PARENT_ROOT/scripts" . 2>/dev/null || true
        cp -r "$PARENT_ROOT/scaffold-templates" . 2>/dev/null || true
        [ -f "$PARENT_ROOT/config.yaml.example" ] && cp "$PARENT_ROOT/config.yaml.example" . 2>/dev/null || true
        
        # Always sync Dockerfiles after copying to ensure we have latest versions
        # This is critical - the copied docker-compose.yml might be outdated
        sync_dockerfiles "$PARENT_ROOT" || true
        
        if [ ! -f "config.yaml" ]; then
            echo "   Creating minimal config.yaml for local development..."
            cat > config.yaml <<EOF
project:
  name: "$SUBDIR"
  git_repo: ""

services:
  frontend:
    path: "./frontend"
    port: 3000
  
  backend:
    path: "./backend"
    port: 8080
  
  database:
    schema_path: "./backend/prisma/schema.prisma"
  
  cache:
    enabled: true

seed:
  users: 30
  tasks_per_user: "5-10"
EOF
            echo "   ✅ Created minimal config.yaml (GCP settings will be prompted during deployment)"
        fi
    elif [ -f "../scripts/bootstrap.sh" ]; then
        bash "../scripts/bootstrap.sh"
        sync_dockerfiles "$PARENT_ROOT" || true
    else
        cp -r ../docker . 2>/dev/null || true
        cp -r ../scripts . 2>/dev/null || true
        cp -r ../scaffold-templates . 2>/dev/null || true
        [ -f "../config.yaml.example" ] && cp "../config.yaml.example" . 2>/dev/null || true
        sync_dockerfiles "$PARENT_ROOT" || true
        
        if [ ! -f "config.yaml" ]; then
            echo "   Creating minimal config.yaml for local development..."
            cat > config.yaml <<EOF
project:
  name: "$SUBDIR"
  git_repo: ""

services:
  frontend:
    path: "./frontend"
    port: 3000
  
  backend:
    path: "./backend"
    port: 8080
  
  database:
    schema_path: "./backend/prisma/schema.prisma"
  
  cache:
    enabled: true

seed:
  users: 30
  tasks_per_user: "5-10"
EOF
            echo "   ✅ Created minimal config.yaml (GCP settings will be prompted during deployment)"
        fi
    fi
    
    # Final sync of Dockerfiles from parent (redundant but ensures we have latest)
    # This ensures subdirectories get the latest Dockerfile fixes even if something was missed
    PARENT_ROOT="$(cd .. && pwd)"
    if [ -d "$PARENT_ROOT/docker" ] && [ -d "docker" ]; then
        echo "   Final sync of Dockerfiles from parent..."
        if [ -f "$PARENT_ROOT/docker/Dockerfile.backend" ]; then
            cp -f "$PARENT_ROOT/docker/Dockerfile.backend" "docker/Dockerfile.backend"
            echo "      ✅ Synced Dockerfile.backend"
        fi
        if [ -f "$PARENT_ROOT/docker/Dockerfile.frontend" ]; then
            cp -f "$PARENT_ROOT/docker/Dockerfile.frontend" "docker/Dockerfile.frontend"
            echo "      ✅ Synced Dockerfile.frontend"
        fi
        if [ -f "$PARENT_ROOT/docker/docker-compose.yml" ]; then
            cp -f "$PARENT_ROOT/docker/docker-compose.yml" "docker/docker-compose.yml"
            echo "      ✅ Synced docker-compose.yml"
        fi
    fi
    
    # Run setup-local.sh directly (avoid recursive make calls)
    bash scripts/setup-local.sh
fi

