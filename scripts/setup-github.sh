#!/bin/bash
# GitHub Repository Setup Automation
# Automatically creates/connects GitHub repository for deployment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔗 GitHub Repository Setup"
echo ""

# Read config.yaml
if [ ! -f "$PROJECT_ROOT/config.yaml" ]; then
    echo "❌ Error: config.yaml not found"
    exit 1
fi

# Extract project name and git_repo from config.yaml
PROJECT_NAME=$(grep "name:" "$PROJECT_ROOT/config.yaml" | head -1 | sed 's/.*name:[[:space:]]*"\?\([^"]*\)"\?.*/\1/' | tr -d ' ')
GIT_REPO=$(grep "git_repo:" "$PROJECT_ROOT/config.yaml" | head -1 | sed 's/.*git_repo:[[:space:]]*"\?\([^"]*\)"\?.*/\1/' | tr -d ' ')

# Check if Git repo is already connected
if [ -d "$PROJECT_ROOT/.git" ]; then
    REMOTE_URL=$(cd "$PROJECT_ROOT" && git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$REMOTE_URL" ]; then
        echo "✅ Git repository already connected: $REMOTE_URL"
        echo "   No GitHub setup needed."
        exit 0
    fi
fi

# Check if git_repo is set in config.yaml
if [ -n "$GIT_REPO" ] && [ "$GIT_REPO" != "" ]; then
    echo "✅ Git repository URL found in config.yaml: $GIT_REPO"
    echo "   No GitHub setup needed."
    exit 0
fi

echo "⚠️  GitHub repository not connected yet."
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

# Create GitHub repository
echo "📦 Creating GitHub repository..."
echo "   Repository name: $PROJECT_NAME"
echo ""

# Check if repo already exists on GitHub
if gh repo view "$PROJECT_NAME" &> /dev/null; then
    echo "✅ Repository already exists on GitHub: $PROJECT_NAME"
    REPO_URL=$(gh repo view "$PROJECT_NAME" --json url -q .url)
else
    # Create new private repository
    echo "   Creating private repository..."
    gh repo create "$PROJECT_NAME" --private --source=. --remote=origin --push || {
        echo "❌ Failed to create repository"
        echo ""
        echo "Manual steps:"
        echo "  1. Go to https://github.com/new"
        echo "  2. Create repository: $PROJECT_NAME"
        echo "  3. Don't initialize with README"
        echo "  4. Run: git remote add origin <repo-url>"
        echo "  5. Run: git push -u origin main"
        echo "  6. Update config.yaml with repo URL"
        exit 1
    }
    
    REPO_URL=$(gh repo view "$PROJECT_NAME" --json url -q .url)
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

