#!/bin/bash
# Pre-flight checks for local development and GKE deployment

set -e

MODE="${1:-local}"  # local or deploy

echo "🔍 Checking prerequisites..."

# ────────────────────────────────────────────────────────────────────────────────
# Local Development Prerequisites (Always Required)
# ────────────────────────────────────────────────────────────────────────────────

# Check Docker Desktop
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    echo "   Install with: brew install --cask docker"
    exit 1
fi

if ! docker ps &> /dev/null; then
    echo "❌ Docker daemon is not running"
    echo "   Start Docker Desktop and try again"
    exit 1
fi

echo "✅ Docker is installed and running"

# Check Node.js 20+
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    echo "   Install with: brew install node@20"
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 20 ]; then
    echo "❌ Node.js version must be 20 or higher (found: $(node --version))"
    echo "   Install with: brew install node@20"
    exit 1
fi

echo "✅ Node.js $(node --version) is installed"

# ────────────────────────────────────────────────────────────────────────────────
# GKE Deployment Prerequisites (Only for Deploy Mode)
# ────────────────────────────────────────────────────────────────────────────────

if [ "$MODE" == "deploy" ]; then
    echo ""
    echo "🔍 Checking GKE deployment prerequisites..."
    
    # Check gcloud CLI
    if ! command -v gcloud &> /dev/null; then
        echo "❌ gcloud CLI is not installed"
        echo "   Install from: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    echo "✅ gcloud CLI is installed"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl is not installed"
        echo "   Install with: brew install kubectl"
        exit 1
    fi
    echo "✅ kubectl is installed"
    
    # Check terraform
    if ! command -v terraform &> /dev/null; then
        echo "❌ terraform is not installed"
        echo "   Install with: brew install terraform"
        exit 1
    fi
    echo "✅ terraform is installed"
    
    # Check GitHub CLI (optional but recommended)
    if ! command -v gh &> /dev/null; then
        echo "⚠️  GitHub CLI (gh) is not installed (optional)"
        echo "   Install with: brew install gh"
        echo "   (will be auto-installed during deployment if needed)"
    else
        echo "✅ GitHub CLI is installed"
    fi
fi

echo ""
echo "✅ All prerequisites met"


