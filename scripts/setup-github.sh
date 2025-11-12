#!/bin/bash
# GitHub Repository Setup Automation
# Automatically creates/connects GitHub repository for deployment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# PROJECT_ROOT is the current working directory (where the project is)
PROJECT_ROOT="$(pwd)"

echo "🔗 GitHub Repository Setup"
echo ""

# Read config.yaml
if [ ! -f "$PROJECT_ROOT/config.yaml" ]; then
    echo "❌ Error: config.yaml not found in $PROJECT_ROOT"
    exit 1
fi

# Extract project name and git_repo from config.yaml using awk
# Strip inline comments before parsing, then extract value
PROJECT_NAME=$(grep "^[[:space:]]*name:" "$PROJECT_ROOT/config.yaml" | head -1 | sed 's/#.*$//' | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')

# For git_repo, strip comments first, then extract value, handling empty strings properly
# Match git_repo line, strip comments, extract quoted or unquoted value
GIT_REPO_LINE=$(grep "^[[:space:]]*git_repo:" "$PROJECT_ROOT/config.yaml" | head -1 | sed 's/#.*$//')
GIT_REPO=$(echo "$GIT_REPO_LINE" | awk -F': ' '{print $2}' | sed -E 's/^["'\'']?([^"'\'']*)["'\'']?.*$/\1/' | tr -d ' ')

# If GIT_REPO is empty, contains only quotes, or matches comment-like text, treat it as unset
if [ -z "$GIT_REPO" ] || [ "$GIT_REPO" = '""' ] || [ "$GIT_REPO" = "''" ] || echo "$GIT_REPO" | grep -q "^#"; then
    GIT_REPO=""
fi

echo "   Project directory: $PROJECT_ROOT"
echo "   Project name: $PROJECT_NAME"
echo ""

# Check if Git repo is already initialized and connected
HAS_REMOTE=false
if [ -d "$PROJECT_ROOT/.git" ]; then
    REMOTE_URL=$(cd "$PROJECT_ROOT" && git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$REMOTE_URL" ]; then
        echo "✅ Git repository already connected: $REMOTE_URL"
        HAS_REMOTE=true
    else
        echo "   Git initialized but no remote. Will create GitHub repo..."
    fi
else
    echo "   Git not initialized. Will initialize new repository..."
fi

echo ""

# Check if GitHub CLI (gh) is installed
if ! command -v gh &> /dev/null; then
    echo "📦 GitHub CLI (gh) not found. Attempting to install..."
    
    # Check if Homebrew is available (macOS)
    if command -v brew &> /dev/null; then
        echo "   Installing GitHub CLI via Homebrew..."
        if brew install gh; then
            echo "   ✅ GitHub CLI installed successfully"
        else
            echo "   ❌ Installation failed"
            echo ""
            echo "Please install GitHub CLI manually:"
            echo "  1. Run: brew install gh"
            echo "  2. Authenticate: gh auth login"
            echo "  3. Run this script again"
            exit 1
        fi
    else
        echo "❌ Homebrew not found. Cannot auto-install GitHub CLI."
        echo ""
        echo "Please install GitHub CLI manually:"
        echo "  macOS: brew install gh"
        echo "  Or visit: https://cli.github.com/"
        echo ""
        echo "After installation:"
        echo "  1. Authenticate: gh auth login"
        echo "  2. Run this script again"
        exit 1
    fi
fi

# Check if GitHub CLI is authenticated
echo "🔐 Checking GitHub CLI authentication..."
if ! gh auth status &> /dev/null; then
    echo "   GitHub CLI not authenticated. Please authenticate now."
    echo ""
    gh auth login
    
    # Verify authentication succeeded
    if ! gh auth status &> /dev/null; then
        echo "❌ Authentication failed"
        exit 1
    fi
fi

echo "   ✅ GitHub CLI authenticated"
echo ""

# Always ensure changes are committed and pushed (even if repo already exists)
cd "$PROJECT_ROOT"

# Initialize Git repository if not already initialized
if [ ! -d "$PROJECT_ROOT/.git" ]; then
    echo "📦 Initializing Git repository..."
    cd "$PROJECT_ROOT"
    
    # Initialize git
    git init
    
    # Create .gitignore if it doesn't exist
    if [ ! -f ".gitignore" ]; then
        echo "   Creating .gitignore..."
        cat > .gitignore << 'EOF'
# Dependencies
node_modules/
.pnp
.pnp.js

# Testing
coverage/

# Production build
dist/
build/

# Environment variables
.env
.env.local
.env.production

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
logs/
*.log
npm-debug.log*

# Deployment infrastructure (copied from tool during make deploy)
k8s/
terraform/
docker/Dockerfile.backend
docker/Dockerfile.frontend

# Keep docker-compose.yml for local dev reference
!docker/docker-compose.yml
EOF
        echo "   ✅ .gitignore created"
    fi
    
    # Remove node_modules from git tracking if they were previously committed
    # This prevents thousands of delete messages when .gitignore is applied
    if git ls-files | grep -q "node_modules"; then
        echo "   Removing node_modules from git tracking (this may take a moment)..."
        # Remove all node_modules files/directories from git index
        git ls-files | grep "node_modules" | git update-index --remove --stdin 2>/dev/null || \
        git rm -r --cached --quiet frontend/node_modules backend/node_modules 2>/dev/null || true
    fi
    
    # Add all files (excluding those in .gitignore)
    git add -A --quiet 2>/dev/null || git add -A
    
    # Make initial commit with quiet output
    git commit -m "Initial commit: $PROJECT_NAME

Generated by Zero-to-Running Developer Environment
Project: $PROJECT_NAME
" --quiet 2>/dev/null || git commit -m "Initial commit: $PROJECT_NAME

Generated by Zero-to-Running Developer Environment
Project: $PROJECT_NAME
"
    
    echo "   ✅ Git repository initialized"
    echo "   ✅ Initial commit created"
else
    echo "✅ Git repository already initialized"
    
    # Always commit any uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "   📝 Uncommitted changes detected. Committing..."
        
        # Remove node_modules from tracking if they exist in the index
        if git ls-files | grep -q "^.*node_modules/"; then
            echo "   Removing node_modules from git tracking..."
            git rm -r --cached --quiet */node_modules 2>/dev/null || true
            git rm -r --cached --quiet frontend/node_modules backend/node_modules 2>/dev/null || true
        fi
        
        # Add changes quietly, suppressing verbose output
        git add -A --quiet 2>/dev/null || git add -A 2>&1 | grep -v "^delete mode" | grep -v "node_modules" | head -20 || true
        
        # Count changes for summary
        CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
        if [ "$CHANGED_FILES" -gt 100 ]; then
            echo "   📦 Staging $CHANGED_FILES files (suppressing verbose output)..."
        fi
        
        # Commit with quiet output
        git commit -m "Update: $(date +'%Y-%m-%d %H:%M:%S')

Auto-committed during deployment" --quiet 2>/dev/null || \
        git commit -m "Update: $(date +'%Y-%m-%d %H:%M:%S')

Auto-committed during deployment" 2>&1 | grep -E "^\[|files changed" || true
        
        echo "   ✅ Changes committed"
    else
        echo "   ✅ No uncommitted changes"
    fi
fi

echo ""

# Determine GitHub repository name/URL
# If GIT_REPO is already set (and is a valid URL), extract repo name from URL, otherwise use PROJECT_NAME
# Debug: Show what we parsed (can be removed in production)
if [ -n "$GIT_REPO" ] && [ "$GIT_REPO" != '""' ] && [ "$GIT_REPO" != "" ] && echo "$GIT_REPO" | grep -qE "^https?://|^git@"; then
    # Extract repo name from URL (e.g., https://github.com/user/repo.git -> repo)
    REPO_NAME=$(echo "$GIT_REPO" | sed -E 's|.*github\.com/[^/]+/([^/]+)(\.git)?/?$|\1|' | sed 's|\.git$||')
    REPO_URL="$GIT_REPO"
    echo "📦 Using existing GitHub repository from config.yaml..."
    echo "   Repository: $REPO_NAME"
    echo "   URL: $REPO_URL"
echo ""
    
    # Ensure remote is set to the URL from config.yaml
    cd "$PROJECT_ROOT"
    if [ -d "$PROJECT_ROOT/.git" ]; then
        CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
        if [ "$CURRENT_REMOTE" != "$REPO_URL" ]; then
            echo "   Setting remote origin to: $REPO_URL"
            if [ -n "$CURRENT_REMOTE" ]; then
                git remote set-url origin "$REPO_URL" 2>/dev/null || true
            else
                git remote add origin "$REPO_URL" 2>/dev/null || true
            fi
        fi
    fi
else
    # No GIT_REPO set, use PROJECT_NAME to create/find repo
    REPO_NAME="$PROJECT_NAME"
    echo "📦 Setting up GitHub repository..."
    echo "   Checking for repository: $REPO_NAME"
    echo ""
fi

# If repo already has remote, ensure we commit and push changes
if [ "$HAS_REMOTE" = true ]; then
    echo "📤 Ensuring all changes are committed and pushed..."
    
    cd "$PROJECT_ROOT"
    
    # First, commit any uncommitted changes (in case they weren't committed above)
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "   📝 Uncommitted changes detected. Committing..."
        
        # Remove node_modules from tracking if they exist
        if git ls-files | grep -q "^.*node_modules/"; then
            git rm -r --cached --quiet */node_modules 2>/dev/null || true
        fi
        
        # Add changes quietly
        git add -A --quiet 2>/dev/null || git add -A 2>&1 | grep -v "^delete mode" | grep -v "node_modules" | head -20 || true
        
        # Commit quietly
        git commit -m "Update: $(date +'%Y-%m-%d %H:%M:%S')

Auto-committed during deployment" --quiet 2>/dev/null || \
        git commit -m "Update: $(date +'%Y-%m-%d %H:%M:%S')

Auto-committed during deployment" 2>&1 | grep -E "^\[|files changed" || true
        
        echo "   ✅ Changes committed"
    fi
    
    # Get current branch
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
    
    # Check if remote branch exists
    if git rev-parse --verify "origin/$CURRENT_BRANCH" &>/dev/null 2>&1; then
        # Remote branch exists - check if local is ahead
        HAS_UNPUSHED=$(git rev-list --count origin/$CURRENT_BRANCH..HEAD 2>/dev/null || echo "0")
    else
        # Remote branch doesn't exist - we need to push
        HAS_UNPUSHED="1"
    fi
    
    # Only push if there are actually unpushed commits
    if [ "$HAS_UNPUSHED" != "0" ] && [ "$HAS_UNPUSHED" != "" ] && [ "$HAS_UNPUSHED" -gt 0 ] 2>/dev/null; then
        echo "   📤 Pushing changes to GitHub..."
        if git push origin "$CURRENT_BRANCH" 2>/dev/null || git push -u origin "$CURRENT_BRANCH" 2>/dev/null; then
            echo "   ✅ Changes pushed to GitHub"
        else
            echo "   ⚠️  Could not push to remote (non-blocking)"
            echo "   You can manually push with: git push origin $CURRENT_BRANCH"
        fi
    else
        echo "   ✅ Repository is up to date (no changes to push)"
    fi
    
    echo ""
    echo "✅ GitHub setup complete!"
    echo "   Repository: $REMOTE_URL"
    echo ""
    return 0 2>/dev/null || exit 0
fi

# If GIT_REPO was already set, we're done (repo exists and is connected)
if [ -n "$GIT_REPO" ] && [ "$GIT_REPO" != '""' ] && [ "$GIT_REPO" != "" ]; then
    # Just ensure changes are committed and pushed
    cd "$PROJECT_ROOT"
    
    # First, commit any uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo "   📝 Uncommitted changes detected. Committing..."
        
        # Remove node_modules from tracking if they exist
        if git ls-files | grep -q "^.*node_modules/"; then
            git rm -r --cached --quiet */node_modules 2>/dev/null || true
        fi
        
        # Add changes quietly
        git add -A --quiet 2>/dev/null || git add -A 2>&1 | grep -v "^delete mode" | grep -v "node_modules" | head -20 || true
        
        # Commit quietly
        git commit -m "Update: $(date +'%Y-%m-%d %H:%M:%S')

Auto-committed during deployment" --quiet 2>/dev/null || \
        git commit -m "Update: $(date +'%Y-%m-%d %H:%M:%S')

Auto-committed during deployment" 2>&1 | grep -E "^\[|files changed" || true
        
        echo "   ✅ Changes committed"
    fi
    
    # Check for unpushed commits
    CURRENT_BRANCH=$(git branch --show-current || echo "main")
    
    # Check if remote branch exists
    if git rev-parse --verify "origin/$CURRENT_BRANCH" &>/dev/null 2>&1; then
        # Remote branch exists - check if local is ahead
        HAS_UNPUSHED=$(git rev-list --count origin/$CURRENT_BRANCH..HEAD 2>/dev/null || echo "0")
    else
        # Remote branch doesn't exist - we need to push
        HAS_UNPUSHED="1"
    fi
    
    # Only push if there are actually unpushed commits
    if [ "$HAS_UNPUSHED" != "0" ] && [ "$HAS_UNPUSHED" != "" ] && [ "$HAS_UNPUSHED" -gt 0 ] 2>/dev/null; then
        echo "   📤 Pushing changes to GitHub..."
        if git push origin "$CURRENT_BRANCH" 2>/dev/null || git push -u origin "$CURRENT_BRANCH" 2>/dev/null; then
            echo "   ✅ Changes pushed to GitHub"
        else
            echo "   ⚠️  Could not push to remote (non-blocking)"
            echo "   You can manually push with: git push origin $CURRENT_BRANCH"
        fi
    else
        echo "   ✅ Repository is up to date (no changes to push)"
    fi
    
    echo ""
    echo "✅ GitHub setup complete!"
    echo "   Repository: $REPO_URL"
    echo ""
    exit 0
fi

# Create GitHub repository if it doesn't exist (only if GIT_REPO was not set)
if gh repo view "$REPO_NAME" &> /dev/null; then
    echo "✅ Found existing repository on GitHub: $REPO_NAME"
    REPO_URL=$(gh repo view "$REPO_NAME" --json url -q .url)
    echo "   URL: $REPO_URL"
    echo ""
    
    # Ensure remote is set
    cd "$PROJECT_ROOT"
    if ! git remote get-url origin &> /dev/null; then
        echo "   🔗 Connecting to existing repository..."
        git remote add origin "$REPO_URL" 2>/dev/null || \
        git remote set-url origin "$REPO_URL" 2>/dev/null || true
        echo "   ✅ Connected to remote repository"
    else
        CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
        if [ "$CURRENT_REMOTE" != "$REPO_URL" ]; then
            echo "   🔗 Updating remote URL..."
            git remote set-url origin "$REPO_URL" 2>/dev/null || true
            echo "   ✅ Remote URL updated"
        else
            echo "   ✅ Already connected to correct repository"
        fi
    fi
    
    # Check if there are unpushed commits (changes were already committed above)
    cd "$PROJECT_ROOT"
    CURRENT_BRANCH=$(git branch --show-current || echo "main")
    
    # Check if remote branch exists
    if git rev-parse --verify "origin/$CURRENT_BRANCH" &>/dev/null 2>&1; then
        # Remote branch exists - check if local is ahead
        HAS_UNPUSHED=$(git rev-list --count origin/$CURRENT_BRANCH..HEAD 2>/dev/null || echo "0")
    else
        # Remote branch doesn't exist - we need to push
        HAS_UNPUSHED="1"
    fi
    
    # Only push if there are actually unpushed commits
    if [ "$HAS_UNPUSHED" != "0" ] && [ "$HAS_UNPUSHED" != "" ] && [ "$HAS_UNPUSHED" -gt 0 ] 2>/dev/null; then
        echo "   📤 Pushing changes to GitHub..."
        if git push origin "$CURRENT_BRANCH" 2>/dev/null || git push -u origin "$CURRENT_BRANCH" 2>/dev/null; then
            echo "   ✅ Changes pushed to GitHub"
        else
            echo "   ⚠️  Could not push to remote (non-blocking)"
            echo "   You can manually push with: git push origin $CURRENT_BRANCH"
        fi
    else
        echo "   ✅ Repository is up to date (no changes to push)"
    fi
else
    # Create new private repository
    echo "   Creating new private repository: $REPO_NAME"
    gh repo create "$REPO_NAME" --private --source=. --remote=origin --push || {
        echo "❌ Failed to create repository"
        echo ""
        echo "Manual steps:"
        echo "  1. Go to https://github.com/new"
        echo "  2. Create repository: $REPO_NAME"
        echo "  3. Don't initialize with README"
        echo "  4. Run: git remote add origin <repo-url>"
        echo "  5. Run: git push -u origin main"
        echo "  6. Update config.yaml with repo URL"
        exit 1
    }
    
    REPO_URL=$(gh repo view "$REPO_NAME" --json url -q .url)
    echo "   ✅ Repository created: $REPO_URL"
fi

# Update config.yaml with repository URL
echo ""
echo "📝 Updating config.yaml with repository URL..."
if command -v sed &> /dev/null; then
    # macOS/BSD sed requires backup extension
    sed -i.bak "s|git_repo:.*|git_repo: \"$REPO_URL\"|" "$PROJECT_ROOT/config.yaml"
    rm -f "$PROJECT_ROOT/config.yaml.bak"
    echo "   ✅ config.yaml updated"
else
    echo "   ⚠️  Could not auto-update config.yaml"
    echo "   Please manually add: git_repo: \"$REPO_URL\""
fi

echo ""
echo "✅ GitHub setup complete!"
echo "   Repository: $REPO_URL"
echo "   Code pushed to GitHub"
echo ""

