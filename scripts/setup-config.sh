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

# GitHub repo name will automatically use project_name during deployment
# No need to prompt - setup-github.sh will use PROJECT_NAME when git_repo is empty

# Read existing GCP settings from config.yaml if it exists
EXISTING_GCP_PROJECT_ID=""
EXISTING_GCP_REGION=""
EXISTING_CLUSTER_NAME=""
EXISTING_MACHINE_TYPE=""
EXISTING_NODE_COUNT=""
EXISTING_DOMAIN_NAME=""

if [ -f "$CONFIG_FILE" ]; then
    EXISTING_GCP_PROJECT_ID=$(grep "project_id:" "$CONFIG_FILE" | head -1 | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ' || echo "")
    EXISTING_GCP_REGION=$(grep "region:" "$CONFIG_FILE" | head -1 | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ' || echo "")
    EXISTING_CLUSTER_NAME=$(grep "cluster_name:" "$CONFIG_FILE" | head -1 | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ' || echo "")
    EXISTING_MACHINE_TYPE=$(grep "machine_type:" "$CONFIG_FILE" | head -1 | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ' || echo "")
    EXISTING_NODE_COUNT=$(grep "node_count:" "$CONFIG_FILE" | head -1 | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ' || echo "")
    EXISTING_DOMAIN_NAME=$(grep "domain_name:" "$CONFIG_FILE" | grep -v "^[[:space:]]*#" | head -1 | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ' || echo "")
fi

echo ""
echo "☁️  Google Cloud Platform (GKE) Configuration"
echo "──────────────────────────────────────────"
echo ""
echo "To find your GCP project ID:"
echo "  1. Visit: https://console.cloud.google.com/"
echo "  2. Select your project from the dropdown"
echo "  3. Copy the Project ID (not the name)"
echo ""

# Use existing project_id as default if available
if [ -n "$EXISTING_GCP_PROJECT_ID" ] && [ "$EXISTING_GCP_PROJECT_ID" != "your-gcp-project-id" ]; then
    read -p "Enter your GCP project ID [$EXISTING_GCP_PROJECT_ID]: " gcp_project_id
    gcp_project_id=${gcp_project_id:-$EXISTING_GCP_PROJECT_ID}
else
    read -p "Enter your GCP project ID: " gcp_project_id
fi

if [ -z "$gcp_project_id" ]; then
    echo "❌ GCP project ID cannot be empty"
    exit 1
fi

echo ""
read -p "Use all default settings for region, cluster name, machine type, etc.? (Y/n): " use_defaults
use_defaults=${use_defaults:-Y}

if [[ "$use_defaults" =~ ^[Yy]$ ]] || [ -z "$use_defaults" ]; then
    # Use defaults, but update old defaults if found
    # If existing values are old defaults, use new defaults; otherwise preserve existing
    if [ "$EXISTING_GCP_REGION" = "us-central1" ] || [ -z "$EXISTING_GCP_REGION" ]; then
        gcp_region="us-east1"
    else
        gcp_region="$EXISTING_GCP_REGION"
    fi
    
    cluster_name=""  # Will be auto-generated as ${project_name}-cluster
    
    if [ -z "$EXISTING_MACHINE_TYPE" ]; then
        machine_type="e2-medium"
    else
        machine_type="$EXISTING_MACHINE_TYPE"
    fi
    
    # Update old default (2) to new default (1), but preserve custom values
    if [ "$EXISTING_NODE_COUNT" = "2" ] || [ -z "$EXISTING_NODE_COUNT" ]; then
        node_count=1
    else
        node_count="$EXISTING_NODE_COUNT"
    fi
    
    domain_name="${EXISTING_DOMAIN_NAME:-}"
    
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
    echo "  • us-east1 (South Carolina) - Default, good latency for US"
    echo "  • us-central1 (Iowa)"
    echo "  • us-west1 (Oregon)"
    echo "  • europe-west1 (Belgium)"
    echo "  • asia-southeast1 (Singapore)"
    echo ""
    # Use existing region as default, but update old default (us-central1) to new default (us-east1)
    if [ "$EXISTING_GCP_REGION" = "us-central1" ]; then
        DEFAULT_REGION="us-east1"
    elif [ -n "$EXISTING_GCP_REGION" ]; then
        DEFAULT_REGION="$EXISTING_GCP_REGION"
    else
        DEFAULT_REGION="us-east1"
    fi
    read -p "Enter GCP region [$DEFAULT_REGION]: " gcp_region
    gcp_region=${gcp_region:-$DEFAULT_REGION}
    
    echo ""
    echo "⚙️  Advanced Configuration (Optional)"
    echo "──────────────────────────────────────────"
    echo ""
    read -p "Enter GKE cluster name [${project_name}-cluster (auto-generated)]: " cluster_name
    cluster_name=${cluster_name:-""}
    
    # Use existing machine_type as default if available
    DEFAULT_MACHINE_TYPE="${EXISTING_MACHINE_TYPE:-e2-medium}"
    read -p "Enter machine type [$DEFAULT_MACHINE_TYPE]: " machine_type
    machine_type=${machine_type:-$DEFAULT_MACHINE_TYPE}
    
    # Use existing node_count as default, but update old default (2) to new default (1)
    if [ "$EXISTING_NODE_COUNT" = "2" ]; then
        DEFAULT_NODE_COUNT="1"
    elif [ -n "$EXISTING_NODE_COUNT" ]; then
        DEFAULT_NODE_COUNT="$EXISTING_NODE_COUNT"
    else
        DEFAULT_NODE_COUNT="1"
    fi
    read -p "Enter number of nodes [$DEFAULT_NODE_COUNT]: " node_count
    node_count=${node_count:-$DEFAULT_NODE_COUNT}
    
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
  git_repo: ""  # Will be auto-generated during deployment using project name

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
echo "  GitHub Repo:       $project_name (will be created automatically)"
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
echo "📖 For more info, see: docs/PRE_DEPLOYMENT_CHECKLIST.md"
echo ""
