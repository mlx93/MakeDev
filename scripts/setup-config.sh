#!/bin/bash
# Interactive Config Generator
# Creates a config.yaml file with user input

set -e

PROJECT_ROOT="$(pwd)"
CONFIG_FILE="$PROJECT_ROOT/config.yaml"

echo "⚙️  Zero-to-Running Config Generator"
echo "=========================================="
echo ""

# Check if config.yaml already exists
if [ -f "$CONFIG_FILE" ]; then
    echo "✅ config.yaml already exists in this directory"
    echo ""
    echo "Current configuration:"
    cat "$CONFIG_FILE"
    echo ""
    echo "──────────────────────────────────────────"
    read -p "Do you want to overwrite it? (y/N): " overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
        echo "✅ Keeping existing config.yaml"
        exit 0
    fi
    echo ""
fi

# Prompt for project name
echo "📦 Project Configuration"
echo "──────────────────────────────────────────"
echo ""
read -p "Enter your project name (e.g., my-app, task-tracker): " project_name

if [ -z "$project_name" ]; then
    echo "❌ Project name cannot be empty"
    exit 1
fi

echo ""
echo "🔗 GitHub Configuration"
echo "──────────────────────────────────────────"
echo ""
echo "We'll create a GitHub repository for you during deployment."
read -p "Enter desired GitHub repo name (default: $project_name): " git_repo_name

# Use project_name as default if empty
git_repo_name=${git_repo_name:-$project_name}

echo ""
echo "☁️  Google Cloud Platform (GKE) Configuration"
echo "──────────────────────────────────────────"
echo ""
echo "To find your GCP project ID:"
echo "  1. Visit: https://console.cloud.google.com/"
echo "  2. Select your project from the dropdown"
echo "  3. Copy the Project ID (not the name)"
echo ""
read -p "Enter your GCP project ID: " gcp_project_id

if [ -z "$gcp_project_id" ]; then
    echo "❌ GCP project ID cannot be empty"
    exit 1
fi

echo ""
echo "🌍 GCP Region"
echo "──────────────────────────────────────────"
echo ""
echo "Common regions:"
echo "  • us-central1 (Iowa) - Default, good latency for US"
echo "  • us-east1 (South Carolina)"
echo "  • us-west1 (Oregon)"
echo "  • europe-west1 (Belgium)"
echo "  • asia-southeast1 (Singapore)"
echo ""
read -p "Enter GCP region (default: us-central1): " gcp_region
gcp_region=${gcp_region:-us-central1}

echo ""
echo "⚙️  Advanced Configuration (Optional)"
echo "──────────────────────────────────────────"
echo ""
read -p "Enter GKE cluster name (default: $project_name-cluster): " cluster_name
cluster_name=${cluster_name:-""}

read -p "Enter machine type (default: e2-medium): " machine_type
machine_type=${machine_type:-e2-medium}

read -p "Enter number of nodes (default: 2): " node_count
node_count=${node_count:-2}

# Generate config.yaml
echo ""
echo "📝 Generating config.yaml..."
echo ""

cat > "$CONFIG_FILE" << EOF
# Zero-to-Running Developer Environment
# Configuration for: $project_name

project:
  name: "$project_name"
  git_repo: ""  # Will be auto-generated during deployment: $git_repo_name

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

gke:
  project_id: "$gcp_project_id"
  region: "$gcp_region"
  cluster_name: "$cluster_name"
  
  node_config:
    machine_type: "$machine_type"
    node_count: $node_count
    disk_size_gb: 20

seed:
  users: 30
  tasks_per_user: "5-10"
EOF

echo "✅ config.yaml created successfully!"
echo ""
echo "──────────────────────────────────────────"
echo "📋 Your Configuration Summary:"
echo "──────────────────────────────────────────"
echo "  Project Name:      $project_name"
echo "  GitHub Repo:       $git_repo_name (will be created)"
echo "  GCP Project ID:    $gcp_project_id"
echo "  GCP Region:        $gcp_region"
echo "  Cluster Name:      ${cluster_name:-$project_name-cluster (auto)}"
echo "  Machine Type:      $machine_type"
echo "  Node Count:        $node_count"
echo "──────────────────────────────────────────"
echo ""
echo "🚀 Next Steps:"
echo "  1. Create .env.production with your database credentials"
echo "  2. Run: make deploy"
echo ""
echo "📖 For more info, see: PRE_DEPLOYMENT_CHECKLIST.md"
echo ""

