#!/bin/bash
# GKE Deployment Script
# Full deployment orchestration for Google Kubernetes Engine

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# PROJECT_ROOT is the current working directory (where Makefile cd'd to)
PROJECT_ROOT="$(pwd)"
# TOOL_DIR is where the ZeroToRunDevEnv tool is located
TOOL_DIR="$(dirname "$SCRIPT_DIR")"

echo "☁️  Zero-to-Running Developer Environment - GKE Deployment"
echo "=========================================================="
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 1: Prerequisites Check
# ────────────────────────────────────────────────────────────────────────────────
echo "🔍 Checking prerequisites..."

# Check gcloud
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI not found"
    echo "   Install: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found"
    echo "   Install: brew install kubectl"
    exit 1
fi

# Check terraform
if ! command -v terraform &> /dev/null; then
    echo "❌ terraform not found"
    echo "   Install: brew install terraform"
    exit 1
fi

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found"
    echo "   Install: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "   ✅ All prerequisites installed"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 2: Read Configuration
# ────────────────────────────────────────────────────────────────────────────────
echo "📋 Checking configuration..."

if [ ! -f "$PROJECT_ROOT/config.yaml" ]; then
    echo "⚠️  config.yaml not found in $PROJECT_ROOT"
    echo ""
    echo "Let's create one! (takes ~1 minute)"
    echo ""
    
    # Run interactive config generator
    bash "$TOOL_DIR/scripts/setup-config.sh"
    
    # Verify it was created
    if [ ! -f "$PROJECT_ROOT/config.yaml" ]; then
        echo "❌ config.yaml was not created"
        exit 1
    fi
fi

echo "✅ Configuration file found"
echo ""

echo "📋 Reading configuration..."

# Extract configuration values using awk for reliable YAML parsing
PROJECT_NAME=$(grep "name:" "$PROJECT_ROOT/config.yaml" | head -1 | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
GCP_PROJECT_ID=$(grep "project_id:" "$PROJECT_ROOT/config.yaml" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
GCP_REGION=$(grep "region:" "$PROJECT_ROOT/config.yaml" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
CLUSTER_NAME=$(grep "cluster_name:" "$PROJECT_ROOT/config.yaml" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')

# Validate required values
if [ -z "$PROJECT_NAME" ]; then
    echo "❌ project.name not found in config.yaml"
    exit 1
fi

if [ -z "$GCP_PROJECT_ID" ] || [ "$GCP_PROJECT_ID" == "your-gcp-project-id" ]; then
    echo "❌ gke.project_id not set in config.yaml"
    echo "   Please update config.yaml with your GCP project ID"
    exit 1
fi

# Set defaults
GCP_REGION=${GCP_REGION:-us-central1}
CLUSTER_NAME=${CLUSTER_NAME:-${PROJECT_NAME}-cluster}

echo "   Project: $PROJECT_NAME"
echo "   GCP Project: $GCP_PROJECT_ID"
echo "   Region: $GCP_REGION"
echo "   Cluster: $CLUSTER_NAME"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 3: GCP Authentication
# ────────────────────────────────────────────────────────────────────────────────
echo "🔐 Checking GCP authentication..."

# Check if already authenticated
if ! gcloud auth list 2>&1 | grep -q ACTIVE; then
    echo "   Not authenticated. Please authenticate:"
    gcloud auth login
fi

# Set active project
gcloud config set project "$GCP_PROJECT_ID" 2>&1 | grep -v "INFORMATION:" || true

echo "   ✅ Authenticated as: $(gcloud config get-value account 2>/dev/null)"
echo "   ✅ Active project: $(gcloud config get-value project 2>/dev/null)"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 4: Sync Deployment Infrastructure from Tool
# ────────────────────────────────────────────────────────────────────────────────
echo "📦 Syncing deployment infrastructure from tool..."
echo "   Tool directory: $TOOL_DIR"
echo "   Project directory: $PROJECT_ROOT"
echo ""

# Sync docker directory (production-ready Dockerfiles)
echo "   Syncing docker/ directory..."
mkdir -p "$PROJECT_ROOT/docker"
if [ -f "$TOOL_DIR/docker/Dockerfile.backend" ]; then
    cp -f "$TOOL_DIR/docker/Dockerfile.backend" "$PROJECT_ROOT/docker/"
    echo "   ✅ Dockerfile.backend synced"
else
    echo "   ⚠️  Dockerfile.backend not found"
fi

if [ -f "$TOOL_DIR/docker/Dockerfile.frontend" ]; then
    cp -f "$TOOL_DIR/docker/Dockerfile.frontend" "$PROJECT_ROOT/docker/"
    echo "   ✅ Dockerfile.frontend synced"
else
    echo "   ⚠️  Dockerfile.frontend not found"
fi

cp -f "$TOOL_DIR/docker/docker-compose.yml" "$PROJECT_ROOT/docker/" 2>/dev/null || true

# Sync k8s directory (Kubernetes manifests)
echo "   Syncing k8s/ directory..."
if [ -d "$TOOL_DIR/k8s" ]; then
    # Remove existing k8s directory in project to avoid conflicts
    rm -rf "$PROJECT_ROOT/k8s"
    cp -rf "$TOOL_DIR/k8s" "$PROJECT_ROOT/"
    echo "   ✅ k8s/ directory synced"
else
    echo "   ❌ k8s/ directory not found in tool"
    exit 1
fi

# Sync terraform directory (GKE provisioning)
echo "   Syncing terraform/ directory..."
if [ -d "$TOOL_DIR/terraform" ]; then
    # Remove existing terraform directory in project to avoid conflicts
    rm -rf "$PROJECT_ROOT/terraform"
    cp -rf "$TOOL_DIR/terraform" "$PROJECT_ROOT/"
    echo "   ✅ terraform/ directory synced"
else
    echo "   ❌ terraform/ directory not found in tool"
    exit 1
fi

echo ""
echo "   ✅ All deployment infrastructure synced"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 5: GitHub Setup
# ────────────────────────────────────────────────────────────────────────────────
echo "🔗 Checking GitHub repository setup..."

bash "$SCRIPT_DIR/setup-github.sh" || {
    echo "⚠️  GitHub setup skipped or failed (non-blocking)"
}

echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 6: Check for Existing Cluster
# ────────────────────────────────────────────────────────────────────────────────
echo "🔍 Checking for existing GKE cluster..."

if gcloud container clusters describe "$CLUSTER_NAME" --region="$GCP_REGION" &> /dev/null; then
    echo "   ✅ Cluster already exists: $CLUSTER_NAME"
    echo "   Reusing existing cluster (cost-efficient)"
    CLUSTER_EXISTS=true
else
    echo "   Cluster not found. Will provision new cluster."
    CLUSTER_EXISTS=false
fi

echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 7: Provision Cluster (if needed)
# ────────────────────────────────────────────────────────────────────────────────
if [ "$CLUSTER_EXISTS" = false ]; then
    echo "🏗️  Provisioning GKE cluster with Terraform..."
    echo "   This may take 5-10 minutes..."
    echo ""
    
    cd "$PROJECT_ROOT/terraform"
    
    # Initialize Terraform
    terraform init -input=false
    
    # Apply Terraform configuration
    terraform apply \
        -var="gcp_project_id=$GCP_PROJECT_ID" \
        -var="gcp_region=$GCP_REGION" \
        -var="cluster_name=$CLUSTER_NAME" \
        -auto-approve
    
    echo ""
    echo "   ✅ Cluster provisioned successfully"
    echo ""
    
    cd "$PROJECT_ROOT"
fi

# ────────────────────────────────────────────────────────────────────────────────
# Step 8: Configure kubectl
# ────────────────────────────────────────────────────────────────────────────────
echo "⚙️  Configuring kubectl..."

gcloud container clusters get-credentials "$CLUSTER_NAME" \
    --region="$GCP_REGION" \
    --project="$GCP_PROJECT_ID"

echo "   ✅ kubectl configured"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 9: Enable Artifact Registry API
# ────────────────────────────────────────────────────────────────────────────────
echo "📦 Ensuring Artifact Registry API is enabled..."

gcloud services enable artifactregistry.googleapis.com --project="$GCP_PROJECT_ID" &> /dev/null || true

# Create Artifact Registry repository (if doesn't exist)
REPO_NAME="$PROJECT_NAME-images"
LOCATION="$GCP_REGION"

if ! gcloud artifacts repositories describe "$REPO_NAME" --location="$LOCATION" &> /dev/null; then
    echo "   Creating Artifact Registry repository: $REPO_NAME"
    gcloud artifacts repositories create "$REPO_NAME" \
        --repository-format=docker \
        --location="$LOCATION" \
        --description="Docker images for $PROJECT_NAME"
fi

echo "   ✅ Artifact Registry ready"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 10: Build Production Images
# ────────────────────────────────────────────────────────────────────────────────
echo "🐳 Building production Docker images..."

# Add production stages to Dockerfiles if not present
# This will be done by updating the existing Dockerfiles

# Configure Docker for Artifact Registry
gcloud auth configure-docker "$LOCATION-docker.pkg.dev" --quiet

# Build backend image
BACKEND_IMAGE="$LOCATION-docker.pkg.dev/$GCP_PROJECT_ID/$REPO_NAME/backend:latest"
echo "   Building backend image..."
docker build -f "$PROJECT_ROOT/docker/Dockerfile.backend" \
    --target prod \
    -t "$BACKEND_IMAGE" \
    "$PROJECT_ROOT" 2>&1 | grep -v "naming to"

# Build frontend image
FRONTEND_IMAGE="$LOCATION-docker.pkg.dev/$GCP_PROJECT_ID/$REPO_NAME/frontend:latest"
echo "   Building frontend image..."
docker build -f "$PROJECT_ROOT/docker/Dockerfile.frontend" \
    --target prod \
    -t "$FRONTEND_IMAGE" \
    "$PROJECT_ROOT" 2>&1 | grep -v "naming to"

echo "   ✅ Images built successfully"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 11: Push Images to Artifact Registry
# ────────────────────────────────────────────────────────────────────────────────
echo "📤 Pushing images to Artifact Registry..."

docker push "$BACKEND_IMAGE" | grep -v "Waiting\|Preparing\|Layer already exists" || true
docker push "$FRONTEND_IMAGE" | grep -v "Waiting\|Preparing\|Layer already exists" || true

echo "   ✅ Images pushed successfully"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 12: Generate Kubernetes Secrets
# ────────────────────────────────────────────────────────────────────────────────
echo "🔐 Generating Kubernetes Secrets..."

bash "$SCRIPT_DIR/env-to-k8s-secrets.sh"

echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 13: Update K8s Manifests with Image URIs
# ────────────────────────────────────────────────────────────────────────────────
echo "📝 Updating Kubernetes manifests with image URIs..."

# Update frontend deployment
sed -i.bak "s|FRONTEND_IMAGE_PLACEHOLDER|$FRONTEND_IMAGE|g" "$PROJECT_ROOT/k8s/frontend/deployment.yaml"
rm -f "$PROJECT_ROOT/k8s/frontend/deployment.yaml.bak"

# Update backend deployment
sed -i.bak "s|BACKEND_IMAGE_PLACEHOLDER|$BACKEND_IMAGE|g" "$PROJECT_ROOT/k8s/backend/deployment.yaml"
rm -f "$PROJECT_ROOT/k8s/backend/deployment.yaml.bak"

echo "   ✅ Manifests updated"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 14: Deploy to Kubernetes
# ────────────────────────────────────────────────────────────────────────────────
echo "🚀 Deploying to Kubernetes..."

# Apply namespace
kubectl apply -f "$PROJECT_ROOT/k8s/namespace.yaml"

# Apply secrets
kubectl apply -f "$PROJECT_ROOT/k8s/secrets/"

# Apply PostgreSQL
kubectl apply -f "$PROJECT_ROOT/k8s/postgres/"

# Apply Redis
kubectl apply -f "$PROJECT_ROOT/k8s/redis/"

# Apply backend
kubectl apply -f "$PROJECT_ROOT/k8s/backend/"

# Apply frontend
kubectl apply -f "$PROJECT_ROOT/k8s/frontend/"

echo "   ✅ Resources applied"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 15: Wait for Pods to be Ready
# ────────────────────────────────────────────────────────────────────────────────
echo "⏳ Waiting for pods to be ready (this may take 2-5 minutes)..."

kubectl wait --for=condition=ready pod \
    -l app=postgres \
    -n zero-to-running-app \
    --timeout=300s

kubectl wait --for=condition=ready pod \
    -l app=redis \
    -n zero-to-running-app \
    --timeout=300s

kubectl wait --for=condition=ready pod \
    -l app=backend \
    -n zero-to-running-app \
    --timeout=300s

kubectl wait --for=condition=ready pod \
    -l app=frontend \
    -n zero-to-running-app \
    --timeout=300s

echo "   ✅ All pods ready"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 16: Get LoadBalancer IP
# ────────────────────────────────────────────────────────────────────────────────
echo "🌐 Getting LoadBalancer IP..."

# Wait for LoadBalancer IP to be assigned
echo "   Waiting for LoadBalancer IP assignment..."
sleep 10

FRONTEND_IP=""
for i in {1..30}; do
    FRONTEND_IP=$(kubectl get svc frontend-service \
        -n zero-to-running-app \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    
    if [ -n "$FRONTEND_IP" ]; then
        break
    fi
    
    echo "   Attempt $i/30: Waiting for IP assignment..."
    sleep 10
done

if [ -z "$FRONTEND_IP" ]; then
    echo "⚠️  LoadBalancer IP not yet assigned"
    echo "   Check status with: kubectl get svc -n zero-to-running-app"
else
    echo "   ✅ LoadBalancer IP: $FRONTEND_IP"
fi

echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 17: Display Results
# ────────────────────────────────────────────────────────────────────────────────
echo "🎉 Deployment Complete!"
echo "=========================================================="
echo ""
echo "Application URLs:"
if [ -n "$FRONTEND_IP" ]; then
    echo "  Frontend: http://$FRONTEND_IP"
else
    echo "  Frontend: (pending LoadBalancer IP assignment)"
    echo "  Check with: kubectl get svc -n zero-to-running-app"
fi
echo ""
echo "GKE Cluster:"
echo "  Name: $CLUSTER_NAME"
echo "  Region: $GCP_REGION"
echo "  Project: $GCP_PROJECT_ID"
echo ""
echo "Useful Commands:"
echo "  View pods:     kubectl get pods -n zero-to-running-app"
echo "  View services: kubectl get svc -n zero-to-running-app"
echo "  View logs:     kubectl logs -f -l app=backend -n zero-to-running-app"
echo "  Teardown:      make destroy"
echo ""
echo "💰 Estimated Monthly Cost:"
echo "  - Compute (2x e2-medium): ~\$48/month"
echo "  - LoadBalancer: ~\$18/month"
echo "  - Storage (10GB): ~\$2/month"
echo "  - Total: ~\$68-73/month"
echo ""
echo "⚠️  Remember to run 'make destroy' when done to avoid ongoing costs!"
echo ""

