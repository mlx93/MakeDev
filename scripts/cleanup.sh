#!/bin/bash
# Cleanup Script - Teardown GKE Resources
# Safely removes all deployed resources with confirmation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🧹 Zero-to-Running Developer Environment - Cleanup"
echo "=================================================="
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Read Configuration
# ────────────────────────────────────────────────────────────────────────────────
if [ ! -f "$PROJECT_ROOT/config.yaml" ]; then
    echo "❌ config.yaml not found"
    exit 1
fi

PROJECT_NAME=$(grep "name:" "$PROJECT_ROOT/config.yaml" | head -1 | sed 's/.*name:[[:space:]]*"\?\([^"]*\)"\?.*/\1/' | tr -d ' ')
GCP_PROJECT_ID=$(grep "project_id:" "$PROJECT_ROOT/config.yaml" | sed 's/.*project_id:[[:space:]]*"\?\([^"]*\)"\?.*/\1/' | tr -d ' ')
GCP_REGION=$(grep "region:" "$PROJECT_ROOT/config.yaml" | sed 's/.*region:[[:space:]]*"\?\([^"]*\)"\?.*/\1/' | tr -d ' ')
CLUSTER_NAME=$(grep "cluster_name:" "$PROJECT_ROOT/config.yaml" | sed 's/.*cluster_name:[[:space:]]*"\?\([^"]*\)"\?.*/\1/' | tr -d ' ')

GCP_REGION=${GCP_REGION:-us-east1}
CLUSTER_NAME=${CLUSTER_NAME:-${PROJECT_NAME}-cluster}

echo "Configuration:"
echo "  Project: $PROJECT_NAME"
echo "  Cluster: $CLUSTER_NAME"
echo "  Region: $GCP_REGION"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Confirmation Prompt
# ────────────────────────────────────────────────────────────────────────────────
echo "⚠️  WARNING: This will:"
echo "  1. Delete all Kubernetes resources in the cluster"
echo "  2. Destroy the GKE cluster and all data"
echo "  3. Remove local Docker containers and volumes"
echo ""
echo "This action cannot be undone!"
echo ""

read -p "Are you sure you want to proceed? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 1: Local Docker Cleanup
# ────────────────────────────────────────────────────────────────────────────────
echo "🐳 Cleaning up local Docker containers..."

if [ -f "$PROJECT_ROOT/docker/docker-compose.yml" ]; then
    cd "$PROJECT_ROOT/docker"
    docker-compose down -v 2>/dev/null || echo "   No local containers running"
    cd "$PROJECT_ROOT"
fi

echo "   ✅ Local containers stopped"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 2: Check if Cluster Exists
# ────────────────────────────────────────────────────────────────────────────────
echo "🔍 Checking for GKE cluster..."

if ! command -v gcloud &> /dev/null; then
    echo "   gcloud CLI not found. Skipping GKE cleanup."
    exit 0
fi

if ! command -v kubectl &> /dev/null; then
    echo "   kubectl not found. Skipping Kubernetes cleanup."
    exit 0
fi

# Check if cluster exists
if ! gcloud container clusters describe "$CLUSTER_NAME" --region="$GCP_REGION" &> /dev/null; then
    echo "   No GKE cluster found. Nothing to clean up."
    exit 0
fi

echo "   ✅ Cluster found: $CLUSTER_NAME"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 3: Configure kubectl
# ────────────────────────────────────────────────────────────────────────────────
echo "⚙️  Configuring kubectl..."

gcloud container clusters get-credentials "$CLUSTER_NAME" \
    --region="$GCP_REGION" \
    --project="$GCP_PROJECT_ID" 2>/dev/null || {
    echo "   Failed to get cluster credentials"
}

echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 4: Delete Kubernetes Resources
# ────────────────────────────────────────────────────────────────────────────────
echo "🗑️  Deleting Kubernetes resources..."

# Delete all resources in namespace
kubectl delete all --all -n zero-to-running-app --timeout=60s 2>/dev/null || echo "   Resources already deleted"

# Delete secrets and configmaps
kubectl delete secrets --all -n zero-to-running-app --timeout=30s 2>/dev/null || true
kubectl delete configmaps --all -n zero-to-running-app --timeout=30s 2>/dev/null || true

# Delete persistent volume claims
kubectl delete pvc --all -n zero-to-running-app --timeout=60s 2>/dev/null || true

# Delete namespace
kubectl delete namespace zero-to-running-app --timeout=60s 2>/dev/null || echo "   Namespace already deleted"

echo "   ✅ Kubernetes resources deleted"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 5: Destroy GKE Cluster
# ────────────────────────────────────────────────────────────────────────────────
echo "☁️  Destroying GKE cluster..."
echo "   This may take 5-10 minutes..."
echo ""

# Option 1: Using Terraform
if [ -f "$PROJECT_ROOT/terraform/main.tf" ]; then
    cd "$PROJECT_ROOT/terraform"
    
    terraform destroy \
        -var="gcp_project_id=$GCP_PROJECT_ID" \
        -var="gcp_region=$GCP_REGION" \
        -var="cluster_name=$CLUSTER_NAME" \
        -auto-approve
    
    cd "$PROJECT_ROOT"
else
    # Option 2: Using gcloud directly
    gcloud container clusters delete "$CLUSTER_NAME" \
        --region="$GCP_REGION" \
        --project="$GCP_PROJECT_ID" \
        --quiet
fi

echo ""
echo "   ✅ Cluster destroyed"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 6: Clean Local Generated Files
# ────────────────────────────────────────────────────────────────────────────────
echo "🧹 Cleaning generated files..."

# Remove generated secrets
rm -rf "$PROJECT_ROOT/k8s/secrets/"

# Clean Terraform state (optional - commented out to preserve state)
# rm -f "$PROJECT_ROOT/terraform/terraform.tfstate"
# rm -f "$PROJECT_ROOT/terraform/terraform.tfstate.backup"

echo "   ✅ Generated files cleaned"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Display Results
# ────────────────────────────────────────────────────────────────────────────────
echo "✅ Cleanup Complete!"
echo "=================================================="
echo ""
echo "Resources Removed:"
echo "  ✅ Local Docker containers"
echo "  ✅ Kubernetes resources"
echo "  ✅ GKE cluster"
echo "  ✅ Generated secret files"
echo ""
echo "💰 Estimated Monthly Savings: ~\$68-73/month"
echo ""
echo "Your GCP project is now clean. You can redeploy anytime with:"
echo "  make deploy"
echo ""

