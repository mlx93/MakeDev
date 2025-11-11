#!/bin/bash
# Pre-flight checks for local development environment

set -e

echo "🔍 Checking prerequisites..."

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

echo "✅ All prerequisites met"

