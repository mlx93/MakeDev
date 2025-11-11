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
        elif [ -f "../scripts/bootstrap.sh" ]; then
            bash "../scripts/bootstrap.sh"
        else
            cp -r ../docker . 2>/dev/null || true
            cp -r ../scripts . 2>/dev/null || true
            cp -r ../scaffold-templates . 2>/dev/null || true
            [ -f "../config.yaml.example" ] && cp "../config.yaml.example" . 2>/dev/null || true
        fi
    fi
    
    # Create config.yaml if missing (greenfield = empty git_repo)
    if [ ! -f "config.yaml" ]; then
        if [ -f "config.yaml.example" ]; then
            cp config.yaml.example config.yaml
            if [ "$GREENFIELD" = "true" ]; then
                echo "   Setting git_repo to empty (greenfield scaffold)"
                sed -i.bak 's/git_repo:.*/git_repo: ""/' config.yaml 2>/dev/null || sed -i '' 's/git_repo:.*/git_repo: ""/' config.yaml 2>/dev/null || true
                rm -f config.yaml.bak 2>/dev/null || true
            fi
        fi
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
        if [ ! -f "config.yaml" ]; then
            cp config.yaml.example config.yaml 2>/dev/null || true
            sed -i.bak 's/git_repo:.*/git_repo: ""/' config.yaml 2>/dev/null || sed -i '' 's/git_repo:.*/git_repo: ""/' config.yaml 2>/dev/null || true
            rm -f config.yaml.bak 2>/dev/null || true
        fi
    elif [ -f "../scripts/bootstrap.sh" ]; then
        bash "../scripts/bootstrap.sh"
    else
        cp -r ../docker . 2>/dev/null || true
        cp -r ../scripts . 2>/dev/null || true
        cp -r ../scaffold-templates . 2>/dev/null || true
        [ -f "../config.yaml.example" ] && cp "../config.yaml.example" . 2>/dev/null || true
        if [ ! -f "config.yaml" ]; then
            cp config.yaml.example config.yaml 2>/dev/null || true
            sed -i.bak 's/git_repo:.*/git_repo: ""/' config.yaml 2>/dev/null || sed -i '' 's/git_repo:.*/git_repo: ""/' config.yaml 2>/dev/null || true
            rm -f config.yaml.bak 2>/dev/null || true
        fi
    fi
    
    # Run setup-local.sh directly (avoid recursive make calls)
    bash scripts/setup-local.sh
fi

