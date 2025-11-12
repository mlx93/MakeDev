#!/bin/bash
# Interactive Config Generator
# Creates a config.yaml file with user input

set -e

PROJECT_ROOT="$(pwd)"
CONFIG_FILE="$PROJECT_ROOT/config.yaml"

echo "⚙️  Zero-to-Running Config Generator"
echo "=========================================="
echo ""

# Try to read existing project.name from config.yaml if it exists
EXISTING_PROJECT_NAME=""
if [ -f "$CONFIG_FILE" ]; then
    EXISTING_PROJECT_NAME=$(grep "name:" "$CONFIG_FILE" | head -1 | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ' || echo "")
fi

# Check if config.yaml already exists and we're updating it
# If project.name exists, we're updating GCP settings (no overwrite prompt)
# If project.name doesn't exist, prompt for overwrite
if [ -f "$CONFIG_FILE" ] && [ -z "$EXISTING_PROJECT_NAME" ]; then
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
elif [ -f "$CONFIG_FILE" ] && [ -n "$EXISTING_PROJECT_NAME" ]; then
    echo "✅ Found existing config.yaml with project name: $EXISTING_PROJECT_NAME"
    echo "   Updating GCP deployment settings..."
    echo ""
fi

# Prompt for project name (only if not found in existing config)
if [ -n "$EXISTING_PROJECT_NAME" ]; then
    project_name="$EXISTING_PROJECT_NAME"
    echo "📦 Project Configuration"
    echo "──────────────────────────────────────────"
    echo ""
    echo "✅ Found existing project name: $project_name"
    echo ""
else
    echo "📦 Project Configuration"
    echo "──────────────────────────────────────────"
    echo ""
    read -p "Enter your project name (e.g., my-app, task-tracker): " project_name
    
    if [ -z "$project_name" ]; then
        echo "❌ Project name cannot be empty"
        exit 1
    fi
    echo ""
fi

# Read existing git_repo if config exists
EXISTING_GIT_REPO=""
if [ -f "$CONFIG_FILE" ]; then
    EXISTING_GIT_REPO=$(grep "git_repo:" "$CONFIG_FILE" | head -1 | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ' || echo "")
fi

echo "🔗 GitHub Configuration"
echo "──────────────────────────────────────────"
echo ""
echo "We'll create a GitHub repository for you during deployment."
read -p "Enter desired GitHub repo name [$project_name]: " git_repo_name

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
read -p "Use all default settings for region, cluster name, machine type, etc.? (Y/n): " use_defaults
use_defaults=${use_defaults:-Y}

if [[ "$use_defaults" =~ ^[Yy]$ ]] || [ -z "$use_defaults" ]; then
    # Use all defaults
    gcp_region="us-central1"
    cluster_name=""  # Will be auto-generated as ${project_name}-cluster
    machine_type="e2-medium"
    node_count=2
    domain_name=""
    
    echo ""
    echo "✅ Using default settings:"
    echo "──────────────────────────────────────────"
    echo "  Region:           $gcp_region"
    echo "  Cluster Name:     ${project_name}-cluster (auto-generated)"
    echo "  Machine Type:     $machine_type"
    echo "  Node Count:       $node_count"
    echo "  Domain:           (none - HTTP mode)"
    echo "──────────────────────────────────────────"
    echo ""
else
    # Prompt for each setting with defaults shown in brackets
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
    read -p "Enter GCP region [us-central1]: " gcp_region
    gcp_region=${gcp_region:-us-central1}
    
    echo ""
    echo "⚙️  Advanced Configuration (Optional)"
    echo "──────────────────────────────────────────"
    echo ""
    read -p "Enter GKE cluster name [${project_name}-cluster (auto-generated)]: " cluster_name
    cluster_name=${cluster_name:-""}
    
    read -p "Enter machine type [e2-medium]: " machine_type
    machine_type=${machine_type:-e2-medium}
    
    read -p "Enter number of nodes [2]: " node_count
    node_count=${node_count:-2}
    
    echo ""
    echo "🌐 Domain Name (Optional - for HTTPS)"
    echo "──────────────────────────────────────────"
    echo ""
    echo "If you have a domain name, enter it to enable HTTPS with SSL."
    echo "Example: app.example.com or task-app.yourdomain.com"
    echo "Leave empty to use HTTP with IP address (for testing)."
    echo ""
    read -p "Enter domain name (optional, press Enter to skip): " domain_name
    domain_name=${domain_name:-""}
fi

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
  
  domain_name: "$domain_name"

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
if [ -n "$domain_name" ]; then
    echo "  Domain Name:       $domain_name (HTTPS enabled)"
else
    echo "  Domain Name:       (not set - using HTTP)"
fi
echo "──────────────────────────────────────────"
echo ""
echo "🚀 Next Steps:"
echo "  1. Create .env.production with your database credentials"
echo "  2. Run: make deploy"
echo ""
echo "📖 For more info, see: PRE_DEPLOYMENT_CHECKLIST.md"
echo ""
