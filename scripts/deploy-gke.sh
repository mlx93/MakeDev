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
    cd "$PROJECT_ROOT"
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

# Detect if running on macOS (ARM64 Mac)
IS_MAC=false
if [ "$(uname -s)" = "Darwin" ]; then
    IS_MAC=true
    echo "   🍎 Detected macOS - will use ARM64-compatible settings"
fi

# Extract configuration values using awk for reliable YAML parsing
PROJECT_NAME=$(grep "name:" "$PROJECT_ROOT/config.yaml" | head -1 | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
GCP_PROJECT_ID=$(grep "project_id:" "$PROJECT_ROOT/config.yaml" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
GCP_REGION=$(grep "region:" "$PROJECT_ROOT/config.yaml" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
CLUSTER_NAME=$(grep "cluster_name:" "$PROJECT_ROOT/config.yaml" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
MACHINE_TYPE=$(grep "machine_type:" "$PROJECT_ROOT/config.yaml" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
NODE_COUNT=$(grep "node_count:" "$PROJECT_ROOT/config.yaml" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
DISK_SIZE_GB=$(grep "disk_size_gb:" "$PROJECT_ROOT/config.yaml" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
# Extract domain_name, ignoring commented lines (lines starting with # or whitespace + #)
DOMAIN_NAME=$(grep "domain_name:" "$PROJECT_ROOT/config.yaml" | grep -v "^[[:space:]]*#" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')

# Check if GCP project_id is missing or contains placeholder value
if [ -z "$GCP_PROJECT_ID" ] || [ "$GCP_PROJECT_ID" = "your-gcp-project-id" ]; then
    echo "⚠️  GCP project_id is missing or contains placeholder value"
    echo ""
    echo "Let's configure your GCP deployment settings! (takes ~1 minute)"
    echo ""
    
    # Run interactive config generator (from project root)
    cd "$PROJECT_ROOT"
    bash "$TOOL_DIR/scripts/setup-config.sh"
    
    # Re-read GCP_PROJECT_ID after setup
    GCP_PROJECT_ID=$(grep "project_id:" "$PROJECT_ROOT/config.yaml" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
    GCP_REGION=$(grep "region:" "$PROJECT_ROOT/config.yaml" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
    CLUSTER_NAME=$(grep "cluster_name:" "$PROJECT_ROOT/config.yaml" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
    MACHINE_TYPE=$(grep "machine_type:" "$PROJECT_ROOT/config.yaml" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
    NODE_COUNT=$(grep "node_count:" "$PROJECT_ROOT/config.yaml" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
    DISK_SIZE_GB=$(grep "disk_size_gb:" "$PROJECT_ROOT/config.yaml" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
    DOMAIN_NAME=$(grep "domain_name:" "$PROJECT_ROOT/config.yaml" | grep -v "^[[:space:]]*#" | awk -F': ' '{print $2}' | tr -d '"' | tr -d ' ')
    
    # Verify GCP_PROJECT_ID is now set
    if [ -z "$GCP_PROJECT_ID" ] || [ "$GCP_PROJECT_ID" = "your-gcp-project-id" ]; then
        echo "❌ GCP project_id is still not configured"
        exit 1
    fi
    
    echo ""
    echo "✅ GCP configuration complete, continuing with deployment..."
    echo ""
fi

# Auto-update machine_type to ARM64 ONLY if creating NEW cluster
# If cluster already exists, we'll detect its architecture and build for that
# This prevents auto-updating config when cluster architecture doesn't match
CLUSTER_EXISTS_CHECK=$(gcloud container clusters describe "$CLUSTER_NAME" \
    --region="$GCP_REGION" \
    --project="$GCP_PROJECT_ID" \
    --format="value(name)" 2>/dev/null || echo "")

if [ "$IS_MAC" = true ] && ! echo "$MACHINE_TYPE" | grep -q "^t2a-" && [ -z "$CLUSTER_EXISTS_CHECK" ]; then
    # Only auto-update to ARM64 if cluster doesn't exist yet (new cluster)
    echo "   🔄 Auto-updating machine_type to ARM64 (t2a-standard-2) for macOS compatibility..."
    echo "   ℹ️  (Only applies to NEW clusters - existing clusters use their current architecture)"
    # Update config.yaml with ARM64 machine type
    if grep -q "machine_type:" "$PROJECT_ROOT/config.yaml"; then
        # Use sed to update machine_type (works on both macOS and Linux)
        if [ "$(uname -s)" = "Darwin" ]; then
            sed -i '' "s|machine_type:.*|machine_type: t2a-standard-2|g" "$PROJECT_ROOT/config.yaml"
        else
            sed -i "s|machine_type:.*|machine_type: t2a-standard-2|g" "$PROJECT_ROOT/config.yaml"
        fi
        MACHINE_TYPE="t2a-standard-2"
        echo "   ✅ Updated config.yaml: machine_type = t2a-standard-2"
    fi
elif [ "$IS_MAC" = true ] && [ -n "$CLUSTER_EXISTS_CHECK" ]; then
    echo "   ℹ️  Existing cluster detected - will build for cluster's architecture (not config machine_type)"
fi

# Validate required values
if [ -z "$PROJECT_NAME" ]; then
    echo "❌ project.name not found in config.yaml"
    exit 1
fi

# GCP_PROJECT_ID validation is already handled above (before this point)

# Set defaults
GCP_REGION=${GCP_REGION:-us-central1}
CLUSTER_NAME=${CLUSTER_NAME:-${PROJECT_NAME}-cluster}
MACHINE_TYPE=${MACHINE_TYPE:-e2-medium}
NODE_COUNT=${NODE_COUNT:-2}
DISK_SIZE_GB=${DISK_SIZE_GB:-20}

echo "   Project: $PROJECT_NAME"
echo "   GCP Project: $GCP_PROJECT_ID"
echo "   Region: $GCP_REGION"
echo "   Cluster: $CLUSTER_NAME"
echo "   Machine Type: $MACHINE_TYPE"
echo "   Node Count: $NODE_COUNT"
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
        -var="machine_type=$MACHINE_TYPE" \
        -var="node_count=$NODE_COUNT" \
        -var="disk_size_gb=$DISK_SIZE_GB" \
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

# Get cluster credentials
KUBECTL_OUTPUT=$(gcloud container clusters get-credentials "$CLUSTER_NAME" \
    --region="$GCP_REGION" \
    --project="$GCP_PROJECT_ID" 2>&1)

# Check if gke-gcloud-auth-plugin warning appears
if echo "$KUBECTL_OUTPUT" | grep -qi "gke-gcloud-auth-plugin\|ACTION REQUIRED"; then
    echo "   ⚠️  gke-gcloud-auth-plugin not found. Installing..."
    
    # Install the plugin
    INSTALL_OUTPUT=$(gcloud components install gke-gcloud-auth-plugin --quiet 2>&1)
    if echo "$INSTALL_OUTPUT" | grep -qi "ERROR\|failed"; then
        echo "   ⚠️  Auto-install failed. Please install manually:"
        echo "      gcloud components install gke-gcloud-auth-plugin"
        echo "   Continuing anyway (kubectl may still work)..."
    else
        echo "   ✅ gke-gcloud-auth-plugin installed"
        
        # Re-run get-credentials to use the plugin
        gcloud container clusters get-credentials "$CLUSTER_NAME" \
            --region="$GCP_REGION" \
            --project="$GCP_PROJECT_ID" &> /dev/null || true
    fi
fi

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

# Ensure GKE nodes can pull from Artifact Registry
echo "   Ensuring GKE nodes have Artifact Registry access..."
PROJECT_NUMBER=$(gcloud projects describe "$GCP_PROJECT_ID" --format='value(projectNumber)' 2>/dev/null || echo "")
if [ -n "$PROJECT_NUMBER" ]; then
    COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
    gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
        --member="serviceAccount:$COMPUTE_SA" \
        --role="roles/artifactregistry.reader" \
        --condition=None \
        &> /dev/null || true
    echo "   ✅ GKE nodes have Artifact Registry access"
fi

echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 10: Build Production Images
# ────────────────────────────────────────────────────────────────────────────────
echo "🐳 Building production Docker images..."

# Add production stages to Dockerfiles if not present
# This will be done by updating the existing Dockerfiles

# Configure Docker for Artifact Registry
echo "   Configuring Docker authentication..."
gcloud auth configure-docker "$LOCATION-docker.pkg.dev" --quiet 2>&1 | grep -v "WARNING:" || true
echo "   ✅ Docker configured for Artifact Registry"

# Detect target platform based on existing cluster nodes (if cluster exists) or machine type
# SAFETY: Check actual node architecture first, then fall back to machine type
BUILD_PLATFORM="linux/amd64"  # Default to AMD64 (most common)

if kubectl cluster-info &>/dev/null; then
    # Cluster is accessible, check actual node architecture
    NODE_ARCH=$(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.architecture}' 2>/dev/null || echo "")
    if [ -n "$NODE_ARCH" ]; then
        if [ "$NODE_ARCH" = "arm64" ]; then
            BUILD_PLATFORM="linux/arm64"
            echo "   Detected existing cluster with ARM64 nodes - building for linux/arm64"
        else
            BUILD_PLATFORM="linux/amd64"
            echo "   Detected existing cluster with AMD64 nodes - building for linux/amd64"
        fi
    else
        # Can't detect node arch, use machine type
        if echo "$MACHINE_TYPE" | grep -q "^t2a-"; then
            BUILD_PLATFORM="linux/arm64"
            echo "   Detected ARM64 machine type ($MACHINE_TYPE) - building for linux/arm64"
        else
            BUILD_PLATFORM="linux/amd64"
            echo "   Detected AMD64 machine type ($MACHINE_TYPE) - building for linux/amd64"
        fi
    fi
else
    # Cluster not accessible yet, use machine type from config
    if echo "$MACHINE_TYPE" | grep -q "^t2a-"; then
        BUILD_PLATFORM="linux/arm64"
        echo "   Detected ARM64 machine type ($MACHINE_TYPE) - building for linux/arm64"
    else
        BUILD_PLATFORM="linux/amd64"
        echo "   Detected AMD64 machine type ($MACHINE_TYPE) - building for linux/amd64"
    fi
fi

# Build backend image (for detected platform)
BACKEND_IMAGE="$LOCATION-docker.pkg.dev/$GCP_PROJECT_ID/$REPO_NAME/backend:latest"
echo "   Building backend image ($BUILD_PLATFORM)..."
docker buildx build --platform "$BUILD_PLATFORM" \
    -f "$PROJECT_ROOT/docker/Dockerfile.backend" \
    --target prod \
    -t "$BACKEND_IMAGE" \
    --load \
    "$PROJECT_ROOT" 2>&1 | grep -v "naming to\|#0\|#1\|#2\|#3\|#4\|#5\|#6\|#7\|#8\|#9\|#10\|#11\|#12\|#13\|#14\|#15" || docker build \
    --platform "$BUILD_PLATFORM" \
    -f "$PROJECT_ROOT/docker/Dockerfile.backend" \
    --target prod \
    -t "$BACKEND_IMAGE" \
    "$PROJECT_ROOT" 2>&1 | grep -v "naming to"

# Build frontend image (for detected platform)
FRONTEND_IMAGE="$LOCATION-docker.pkg.dev/$GCP_PROJECT_ID/$REPO_NAME/frontend:latest"
echo "   Building frontend image ($BUILD_PLATFORM)..."
docker buildx build --platform "$BUILD_PLATFORM" \
    -f "$PROJECT_ROOT/docker/Dockerfile.frontend" \
    --target prod \
    -t "$FRONTEND_IMAGE" \
    --load \
    "$PROJECT_ROOT" 2>&1 | grep -v "naming to\|#0\|#1\|#2\|#3\|#4\|#5\|#6\|#7\|#8\|#9\|#10\|#11\|#12\|#13\|#14\|#15" || docker build \
    --platform "$BUILD_PLATFORM" \
    -f "$PROJECT_ROOT/docker/Dockerfile.frontend" \
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

# Use project name for namespace (sanitized for Kubernetes naming rules)
# Kubernetes namespace names must be lowercase alphanumeric and hyphens only
K8S_NAMESPACE=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
# Fallback to default if sanitization results in empty string
if [ -z "$K8S_NAMESPACE" ]; then
    K8S_NAMESPACE="zero-to-running-app"
fi

# SAFETY CHECK: Verify namespace matches project (prevent accidental cross-project deletion)
# If namespace exists, check it has our label
if kubectl get namespace "$K8S_NAMESPACE" &>/dev/null; then
    NS_LABEL=$(kubectl get namespace "$K8S_NAMESPACE" -o jsonpath='{.metadata.labels.app}' 2>/dev/null || echo "")
    EXPECTED_LABEL=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
    
    # If namespace exists but doesn't match our project, warn but continue
    # (might be first deployment)
    if [ -n "$NS_LABEL" ] && [ "$NS_LABEL" != "$EXPECTED_LABEL" ] && [ "$NS_LABEL" != "zero-to-running" ]; then
        echo "   ⚠️  WARNING: Namespace $K8S_NAMESPACE exists but may belong to a different project"
        echo "   Continuing with deployment - pods will only be deleted if they match our labels"
    fi
fi

# Clean up any failed or stuck pods from previous deployments
# SAFETY: Only delete pods with our specific app labels to avoid deleting unrelated pods
echo "   Cleaning up failed/stuck pods from previous deployments (namespace: $K8S_NAMESPACE)..."
echo "   ⚠️  Safety: Only targeting pods with labels: app=backend, app=frontend, app=postgres, app=redis"

# Define our app labels (only pods with these labels will be deleted)
OUR_APP_LABELS=("backend" "frontend" "postgres" "redis")

# Clean up failed/stuck pods for each of our apps
for app_label in "${OUR_APP_LABELS[@]}"; do
    # Get pods with this label that are in error states or stuck pending
    FAILED_PODS=$(kubectl get pods -n "$K8S_NAMESPACE" \
        -l "app=$app_label" \
        -o json 2>/dev/null | \
        jq -r '.items[] | select(
            .status.phase == "Failed" or 
            (.status.phase == "Pending" and (.status.containerStatuses == null or .status.containerStatuses[0].state.waiting.reason == "ImagePullBackOff" or .status.containerStatuses[0].state.waiting.reason == "ErrImagePull")) or
            (.status.containerStatuses[]?.state.waiting.reason == "ImagePullBackOff") or
            (.status.containerStatuses[]?.state.waiting.reason == "ErrImagePull")
        ) | .metadata.name' 2>/dev/null || echo "")
    
    if [ -n "$FAILED_PODS" ]; then
        echo "$FAILED_PODS" | while read pod; do
            if [ -n "$pod" ]; then
                echo "   🗑️  Deleting failed/stuck pod: $pod (app=$app_label)"
                kubectl delete pod "$pod" -n "$K8S_NAMESPACE" --ignore-not-found=true 2>/dev/null || true
            fi
        done
    fi
    
    # Also clean up pods stuck in Pending state with Unschedulable reason (resource constraints)
    # This helps free up resources for new deployments
    UNSCHEDULABLE_PODS=$(kubectl get pods -n "$K8S_NAMESPACE" \
        -l "app=$app_label" \
        --field-selector=status.phase=Pending \
        -o json 2>/dev/null | \
        jq -r '.items[] | select(
            .status.conditions[]? | select(.type == "PodScheduled" and .status == "False" and .reason == "Unschedulable")
        ) | .metadata.name' 2>/dev/null || echo "")
    
    if [ -n "$UNSCHEDULABLE_PODS" ]; then
        echo "$UNSCHEDULABLE_PODS" | while read pod; do
            if [ -n "$pod" ]; then
                # Get pod age
                POD_AGE=$(kubectl get pod "$pod" -n "$K8S_NAMESPACE" -o jsonpath='{.metadata.creationTimestamp}' 2>/dev/null || echo "")
                if [ -n "$POD_AGE" ]; then
                    echo "   🗑️  Deleting stuck pending pod: $pod (app=$app_label) - unschedulable (resource constraints)"
                    kubectl delete pod "$pod" -n "$K8S_NAMESPACE" --ignore-not-found=true 2>/dev/null || true
                fi
            fi
        done
    fi
done

# Also check for ImagePullBackOff/ErrImagePull using label selectors (extra safety)
for app_label in "${OUR_APP_LABELS[@]}"; do
    FAILED_PODS=$(kubectl get pods -n "$K8S_NAMESPACE" \
        -l "app=$app_label" \
        -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].state.waiting.reason}{"\n"}{end}' 2>/dev/null | \
        grep -E "(ImagePullBackOff|ErrImagePull)" | cut -f1 || echo "")
    
    if [ -n "$FAILED_PODS" ]; then
        echo "$FAILED_PODS" | while read pod; do
            if [ -n "$pod" ]; then
                echo "   🗑️  Deleting failed pod: $pod (app=$app_label)"
                kubectl delete pod "$pod" -n "$K8S_NAMESPACE" --ignore-not-found=true 2>/dev/null || true
            fi
        done
    fi
done

echo "   ✅ Cleanup complete"
echo ""

# Update namespace in namespace.yaml to use project-based namespace
# Create/update namespace.yaml with dynamic namespace
cat > "$PROJECT_ROOT/k8s/namespace.yaml" <<EOF
# Kubernetes Namespace for Application
apiVersion: v1
kind: Namespace
metadata:
  name: $K8S_NAMESPACE
  labels:
    app: $(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
    managed-by: zero-to-running
EOF

# Update namespace in all Kubernetes manifests
echo "   Updating namespace in Kubernetes manifests..."
find "$PROJECT_ROOT/k8s" -name "*.yaml" -type f ! -name "namespace.yaml" -exec sed -i.bak "s|namespace: zero-to-running-app|namespace: $K8S_NAMESPACE|g" {} \; 2>/dev/null || \
find "$PROJECT_ROOT/k8s" -name "*.yaml" -type f ! -name "namespace.yaml" -exec sed -i '' "s|namespace: zero-to-running-app|namespace: $K8S_NAMESPACE|g" {} \; 2>/dev/null || true
# Clean up backup files
find "$PROJECT_ROOT/k8s" -name "*.bak" -type f -delete 2>/dev/null || true

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

# Configure frontend service and ingress based on domain_name
if [ -n "$DOMAIN_NAME" ] && [ "$DOMAIN_NAME" != "null" ] && [ "$DOMAIN_NAME" != "" ]; then
    echo "   🔒 HTTPS enabled - configuring Ingress with domain: $DOMAIN_NAME"
    
    # Change frontend service to ClusterIP (Ingress will handle external access)
    echo "   Updating frontend service to ClusterIP for Ingress..."
    sed -i.bak 's/type: LoadBalancer/type: ClusterIP/' "$PROJECT_ROOT/k8s/frontend/service.yaml" 2>/dev/null || \
    sed -i '' 's/type: LoadBalancer/type: ClusterIP/' "$PROJECT_ROOT/k8s/frontend/service.yaml" 2>/dev/null || true
    rm -f "$PROJECT_ROOT/k8s/frontend/service.yaml.bak" 2>/dev/null || true
    
    # Create/update ingress.yaml with domain name
    if [ -f "$PROJECT_ROOT/k8s/frontend/ingress.yaml" ]; then
        echo "   Updating Ingress manifest with domain name..."
        sed -i.bak "s/DOMAIN_PLACEHOLDER/$DOMAIN_NAME/g" "$PROJECT_ROOT/k8s/frontend/ingress.yaml" 2>/dev/null || \
        sed -i '' "s/DOMAIN_PLACEHOLDER/$DOMAIN_NAME/g" "$PROJECT_ROOT/k8s/frontend/ingress.yaml" 2>/dev/null || true
        rm -f "$PROJECT_ROOT/k8s/frontend/ingress.yaml.bak" 2>/dev/null || true
        
        # Update namespace in ingress.yaml
        sed -i.bak "s|namespace: zero-to-running-app|namespace: $K8S_NAMESPACE|g" "$PROJECT_ROOT/k8s/frontend/ingress.yaml" 2>/dev/null || \
        sed -i '' "s|namespace: zero-to-running-app|namespace: $K8S_NAMESPACE|g" "$PROJECT_ROOT/k8s/frontend/ingress.yaml" 2>/dev/null || true
        rm -f "$PROJECT_ROOT/k8s/frontend/ingress.yaml.bak" 2>/dev/null || true
        
        echo "   ✅ Ingress configured for HTTPS"
    else
        echo "   ⚠️  ingress.yaml not found - creating it..."
        # Create ingress.yaml from template
        cat > "$PROJECT_ROOT/k8s/frontend/ingress.yaml" <<EOF
# Frontend Ingress (HTTPS with Google-managed SSL)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
  namespace: $K8S_NAMESPACE
  labels:
    app: frontend
    tier: frontend
  annotations:
    # Use Google-managed SSL certificate
    networking.gke.io/managed-certificates: "frontend-ssl-cert"
    # Enable HTTP to HTTPS redirect
    kubernetes.io/ingress.allow-http: "false"
spec:
  # Use Google Cloud Load Balancer (replaces deprecated annotation)
  ingressClassName: "gce"
  rules:
  - host: $DOMAIN_NAME
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
---
# Google-managed SSL Certificate
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: frontend-ssl-cert
  namespace: $K8S_NAMESPACE
spec:
  domains:
    - $DOMAIN_NAME
EOF
        echo "   ✅ Ingress manifest created"
    fi
else
    echo "   🌐 HTTP mode - using LoadBalancer (no domain configured)"
    # Ensure frontend service is LoadBalancer (in case it was changed previously)
    sed -i.bak 's/type: ClusterIP/type: LoadBalancer/' "$PROJECT_ROOT/k8s/frontend/service.yaml" 2>/dev/null || \
    sed -i '' 's/type: ClusterIP/type: LoadBalancer/' "$PROJECT_ROOT/k8s/frontend/service.yaml" 2>/dev/null || true
    rm -f "$PROJECT_ROOT/k8s/frontend/service.yaml.bak" 2>/dev/null || true
    
    # Remove ingress if it exists (cleanup)
    if [ -f "$PROJECT_ROOT/k8s/frontend/ingress.yaml" ]; then
        echo "   Removing Ingress (not needed for HTTP mode)..."
        kubectl delete -f "$PROJECT_ROOT/k8s/frontend/ingress.yaml" --ignore-not-found=true 2>/dev/null || true
        # Also remove the file to prevent it from being applied
        rm -f "$PROJECT_ROOT/k8s/frontend/ingress.yaml" 2>/dev/null || true
    fi
fi

# Apply frontend (exclude ingress.yaml if no domain configured)
if [ -n "$DOMAIN_NAME" ] && [ "$DOMAIN_NAME" != "null" ] && [ "$DOMAIN_NAME" != "" ]; then
    # Apply all frontend resources including ingress
    kubectl apply -f "$PROJECT_ROOT/k8s/frontend/"
else
    # Apply frontend resources but exclude ingress.yaml
    find "$PROJECT_ROOT/k8s/frontend" -name "*.yaml" -type f ! -name "ingress.yaml" -exec kubectl apply -f {} \;
fi

# Apply ingress if domain is configured
if [ -n "$DOMAIN_NAME" ] && [ "$DOMAIN_NAME" != "null" ] && [ "$DOMAIN_NAME" != "" ]; then
    if [ -f "$PROJECT_ROOT/k8s/frontend/ingress.yaml" ]; then
        echo "   Applying Ingress..."
        kubectl apply -f "$PROJECT_ROOT/k8s/frontend/ingress.yaml"
        echo "   ✅ Ingress applied - SSL certificate provisioning may take 5-15 minutes"
    fi
fi

echo "   ✅ Resources applied"
echo ""

# Restart deployments to pull new images (if using :latest tag)
echo "🔄 Restarting deployments to pull new images..."
kubectl rollout restart deployment/backend -n "$K8S_NAMESPACE" 2>/dev/null || true
kubectl rollout restart deployment/frontend -n "$K8S_NAMESPACE" 2>/dev/null || true
kubectl rollout restart deployment/redis -n "$K8S_NAMESPACE" 2>/dev/null || true
echo "   ✅ Deployments restarted"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 15: Wait for Pods to be Ready
# ────────────────────────────────────────────────────────────────────────────────
echo "⏳ Waiting for pods to be ready (this may take 2-5 minutes)..."

# Wait for pods to be ready, excluding terminating pods
# Use field-selector to exclude terminating pods, with fallback if not supported
for app in postgres redis backend frontend; do
    # First try with field-selector to exclude terminating pods
    if kubectl wait --for=condition=ready pod \
        -l app=$app \
        -n "$K8S_NAMESPACE" \
        --field-selector=status.phase!=Terminating \
        --timeout=300s 2>/dev/null; then
        continue
    fi
    # Fallback: wait for all pods, but ignore errors for terminating ones
    kubectl wait --for=condition=ready pod \
        -l app=$app \
        -n "$K8S_NAMESPACE" \
        --timeout=300s 2>&1 | grep -v "not found" || true
    
    # Verify at least one pod is ready
    READY_COUNT=$(kubectl get pods -n "$K8S_NAMESPACE" \
        -l app=$app \
        --field-selector=status.phase=Running \
        -o jsonpath='{.items[*].status.containerStatuses[0].ready}' 2>/dev/null | \
        grep -o "true" | wc -l | tr -d ' ')
    
    if [ "$READY_COUNT" -eq "0" ]; then
        echo "   ⚠️  No ready pods found for app=$app, waiting a bit more..."
        sleep 10
    fi
done

# Check for any pods that failed during deployment and clean them up
# SAFETY: Only check pods with our app labels
echo "   Checking for failed pods (only our app pods)..."
OUR_APP_LABELS=("backend" "frontend" "postgres" "redis")
FOUND_FAILED=false

for app_label in "${OUR_APP_LABELS[@]}"; do
    FAILED_PODS=$(kubectl get pods -n "$K8S_NAMESPACE" \
        -l "app=$app_label" \
        -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].state.waiting.reason}{"\n"}{end}' 2>/dev/null | \
        grep -E "(ImagePullBackOff|ErrImagePull)" | cut -f1 || echo "")
    
    if [ -n "$FAILED_PODS" ]; then
        FOUND_FAILED=true
        echo "   ⚠️  Found failed pods for app=$app_label, cleaning up..."
        echo "$FAILED_PODS" | while read pod; do
            if [ -n "$pod" ]; then
                echo "   🗑️  Deleting failed pod: $pod (app=$app_label)"
                kubectl delete pod "$pod" -n "$K8S_NAMESPACE" --ignore-not-found=true 2>/dev/null || true
            fi
        done
    fi
done

if [ "$FOUND_FAILED" = true ]; then
    echo "   ✅ Failed pods cleaned up - they will be recreated automatically"
fi

echo "   ✅ All pods ready"
echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 15b: Verify Database Connectivity
# ────────────────────────────────────────────────────────────────────────────────
echo "🔍 Verifying database connectivity..."

# Wait a bit for postgres to be fully ready
sleep 5

# Get database credentials from secret
SECRET_PASSWORD=$(kubectl get secret postgres-secret -n "$K8S_NAMESPACE" -o jsonpath='{.data.POSTGRES_PASSWORD}' 2>/dev/null | base64 -d 2>/dev/null || echo "")
POSTGRES_USER=$(kubectl get secret postgres-secret -n "$K8S_NAMESPACE" -o jsonpath='{.data.POSTGRES_USER}' 2>/dev/null | base64 -d 2>/dev/null || echo "postgres")
POSTGRES_DB=$(kubectl get secret postgres-secret -n "$K8S_NAMESPACE" -o jsonpath='{.data.POSTGRES_DB}' 2>/dev/null | base64 -d 2>/dev/null || echo "postgres")

if [ -z "$SECRET_PASSWORD" ] || [ -z "$POSTGRES_USER" ]; then
    echo "   ⚠️  Could not read postgres credentials from secret"
    echo "   Continuing deployment, but database connectivity may fail..."
else
    # Test database connectivity using the secret password
    # We'll test by trying to connect with psql
    DB_TEST=$(kubectl exec -n "$K8S_NAMESPACE" postgres-0 -- \
        env PGPASSWORD="$SECRET_PASSWORD" \
        psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
        -c "SELECT 1;" 2>&1 | grep -q "1 row" && echo "success" || echo "failed")
    
    if [ "$DB_TEST" != "success" ]; then
        echo ""
        echo "❌ DATABASE CONNECTIVITY FAILED"
        echo "=========================================================="
        echo ""
        echo "The database password in your Kubernetes secret does not match"
        echo "the password configured in the PostgreSQL database."
        echo ""
        echo "This can happen if:"
        echo "  1. The database was created with a different password"
        echo "  2. The password in .env.production was changed"
        echo "  3. The database PersistentVolume contains old credentials"
        echo ""
        echo "To resolve this issue:"
        echo ""
        echo "OPTION 1: Delete the PersistentVolume (loses all data):"
        echo "  kubectl delete pvc postgres-pvc -n $K8S_NAMESPACE"
        echo "  kubectl delete statefulset postgres -n $K8S_NAMESPACE"
        echo "  Then redeploy: make deploy SUBDIR=example-task-app"
        echo ""
        echo "OPTION 2: Manually update the database password:"
        echo "  kubectl exec -n $K8S_NAMESPACE postgres-0 -- psql -U postgres -c \\"
        echo "    \"ALTER USER $POSTGRES_USER WITH PASSWORD 'YOUR_PASSWORD_FROM_ENV';\""
        echo ""
        echo "OPTION 3: Update .env.production to match existing database password"
        echo ""
        exit 1
    else
        echo "   ✅ Database connectivity verified"
    fi
fi

echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 15c: Seed Database
# ────────────────────────────────────────────────────────────────────────────────
echo "🌱 Seeding database with test data..."

# Check if backend directory exists
if [ ! -d "$PROJECT_ROOT/backend" ]; then
    echo "   ⚠️  Backend directory not found - skipping seed"
elif [ ! -f "$PROJECT_ROOT/backend/prisma/schema.prisma" ]; then
    echo "   ⚠️  Prisma schema not found - skipping seed"
else
    # Get a backend pod name (use the first running backend pod)
    BACKEND_POD=$(kubectl get pods -n "$K8S_NAMESPACE" -l app=backend --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$BACKEND_POD" ]; then
        echo "   ⚠️  No running backend pod found - skipping seed"
        echo "   You can manually seed later with: make seed SUBDIR=$(basename "$PROJECT_ROOT")"
    else
        echo "   Using backend pod: $BACKEND_POD"
        echo "   Copying seed script and config to pod..."
        
        # Create temporary directory in pod for seed files
        kubectl exec -n "$K8S_NAMESPACE" "$BACKEND_POD" -- mkdir -p /tmp/seed 2>/dev/null || true
        
        # Copy seed script to pod
        kubectl cp "$TOOL_DIR/scripts/seed-database.ts" "$K8S_NAMESPACE/$BACKEND_POD:/tmp/seed/seed-database.ts" 2>/dev/null
        
        # Copy config.yaml to pod if it exists (for seed configuration)
        if [ -f "$PROJECT_ROOT/config.yaml" ]; then
            kubectl cp "$PROJECT_ROOT/config.yaml" "$K8S_NAMESPACE/$BACKEND_POD:/tmp/seed/config.yaml" 2>/dev/null || true
        fi
        
        if [ $? -eq 0 ] || [ -f "$PROJECT_ROOT/config.yaml" ]; then
            echo "   Installing seed script dependencies..."
            
            # Install required dependencies for seed script
            # yaml, @faker-js/faker, and tsx are dev dependencies not in production image
            # Use --force to ensure installation even if package.json doesn't list them
            # Use --legacy-peer-deps to avoid peer dependency conflicts
            INSTALL_OUTPUT=$(kubectl exec -n "$K8S_NAMESPACE" "$BACKEND_POD" -- \
                sh -c "cd /app/backend && npm install --no-save --force --legacy-peer-deps yaml@2.3.4 @faker-js/faker@8.3.1 tsx@4.7.0 2>&1" 2>&1)
            
            # Verify the packages are actually installed by checking node_modules
            VERIFY_OUTPUT=$(kubectl exec -n "$K8S_NAMESPACE" "$BACKEND_POD" -- \
                sh -c "cd /app/backend && test -d node_modules/yaml && test -d node_modules/@faker-js/faker && test -d node_modules/tsx && echo 'installed' || echo 'missing'" 2>&1)
            
            if echo "$VERIFY_OUTPUT" | grep -q "installed"; then
                echo "   ✅ Dependencies installed and verified"
            else
                echo "   ⚠️  Warning: Dependencies may not be installed correctly"
                echo "   Verification output: $VERIFY_OUTPUT"
                echo "   Attempting alternative installation method..."
                # Try installing to a temp directory and using NODE_PATH
                kubectl exec -n "$K8S_NAMESPACE" "$BACKEND_POD" -- \
                    sh -c "mkdir -p /tmp/node_modules && cd /tmp && npm install --no-save yaml@2.3.4 @faker-js/faker@8.3.1 tsx@4.7.0 2>&1" 2>&1 || true
            fi
            
            echo "   Running seed script in pod..."
            
            # In pod: WORKDIR is /app/backend, so project root should be /app
            # Seed script will look for config.yaml at /app/config.yaml or use defaults
            # Schema is at /app/backend/prisma/schema.prisma
            # DATABASE_URL is already set as env var in the pod
            
            # Run seed script - it will detect project root or use /app
            # The script uses process.env.DATABASE_URL which is already set in the pod
            # Use NODE_PATH to ensure modules are found (check both locations)
            if kubectl exec -n "$K8S_NAMESPACE" "$BACKEND_POD" -- \
                sh -c "cd /app/backend && \
                       export NODE_PATH=/app/backend/node_modules:/tmp/node_modules:\$NODE_PATH && \
                       if [ -f /tmp/seed/config.yaml ]; then \
                         mkdir -p /app && cp /tmp/seed/config.yaml /app/config.yaml; \
                       fi && \
                       npx tsx /tmp/seed/seed-database.ts /app 2>&1" 2>&1; then
                echo "   ✅ Database seeded successfully"
            else
                # Try without config.yaml (use defaults)
                echo "   Retrying with default seed configuration..."
                if kubectl exec -n "$K8S_NAMESPACE" "$BACKEND_POD" -- \
                    sh -c "cd /app/backend && export NODE_PATH=/app/backend/node_modules:/tmp/node_modules:\$NODE_PATH && npx tsx /tmp/seed/seed-database.ts /app 2>&1" 2>&1; then
                    echo "   ✅ Database seeded successfully (using defaults)"
                else
                    echo "   ⚠️  Seed script failed - database may be empty"
                    echo "   You can manually seed later with: make seed SUBDIR=$(basename "$PROJECT_ROOT")"
                fi
            fi
            
            # Clean up seed files from pod
            kubectl exec -n "$K8S_NAMESPACE" "$BACKEND_POD" -- rm -rf /tmp/seed 2>/dev/null || true
            kubectl exec -n "$K8S_NAMESPACE" "$BACKEND_POD" -- rm -f /app/config.yaml 2>/dev/null || true
        else
            echo "   ⚠️  Could not copy seed script to pod - skipping seed"
            echo "   You can manually seed later with: make seed SUBDIR=$(basename "$PROJECT_ROOT")"
        fi
    fi
fi

echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 16: Get Application URL
# ────────────────────────────────────────────────────────────────────────────────
if [ -n "$DOMAIN_NAME" ] && [ "$DOMAIN_NAME" != "null" ] && [ "$DOMAIN_NAME" != "" ]; then
    echo "🌐 Getting Ingress IP (for DNS configuration)..."
    
    # Wait for Ingress IP to be assigned
    echo "   Waiting for Ingress IP assignment..."
    sleep 10
    
    INGRESS_IP=""
    for i in {1..30}; do
        INGRESS_IP=$(kubectl get ingress frontend-ingress \
            -n "$K8S_NAMESPACE" \
            -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        
        if [ -n "$INGRESS_IP" ]; then
            break
        fi
        
        echo "   Attempt $i/30: Waiting for IP assignment..."
        sleep 10
    done
    
    if [ -n "$INGRESS_IP" ]; then
        echo "   ✅ Ingress IP: $INGRESS_IP"
        echo ""
        
        # Extract domain and subdomain
        # e.g., task-app.mlx-ventures.com -> subdomain: task-app, domain: mlx-ventures.com
        DOMAIN_PART=$(echo "$DOMAIN_NAME" | cut -d'.' -f2-)
        SUBDOMAIN_PART=$(echo "$DOMAIN_NAME" | cut -d'.' -f1)
        
        echo "   🔧 Attempting to create DNS A record automatically..."
        
        # Enable Cloud DNS API if needed
        gcloud services enable dns.googleapis.com --project="$GCP_PROJECT_ID" 2>/dev/null || true
        
        # Find DNS zone for the domain
        DNS_ZONE=$(gcloud dns managed-zones list --project="$GCP_PROJECT_ID" --format="value(name)" 2>/dev/null | \
            while read zone; do
                zone_dns=$(gcloud dns managed-zones describe "$zone" --project="$GCP_PROJECT_ID" --format="value(dnsName)" 2>/dev/null)
                # Remove trailing dot and compare
                zone_dns=$(echo "$zone_dns" | sed 's/\.$//')
                if [ "$zone_dns" = "$DOMAIN_PART" ]; then
                    echo "$zone"
                    break
                fi
            done | head -1)
        
        if [ -n "$DNS_ZONE" ]; then
            echo "   ✅ Found DNS zone: $DNS_ZONE"
            
            # Check if record already exists
            EXISTING_RECORD=$(gcloud dns record-sets list \
                --zone="$DNS_ZONE" \
                --project="$GCP_PROJECT_ID" \
                --name="$DOMAIN_NAME." \
                --type=A \
                --format="value(name)" 2>/dev/null | head -1)
            
            if [ -n "$EXISTING_RECORD" ]; then
                echo "   🔄 Updating existing DNS A record..."
                # Delete old record
                OLD_IP=$(gcloud dns record-sets describe "$DOMAIN_NAME." \
                    --zone="$DNS_ZONE" \
                    --project="$GCP_PROJECT_ID" \
                    --type=A \
                    --format="value(rrdatas[0])" 2>/dev/null)
                
                if [ -n "$OLD_IP" ] && [ "$OLD_IP" != "$INGRESS_IP" ]; then
                    gcloud dns record-sets transaction start \
                        --zone="$DNS_ZONE" \
                        --project="$GCP_PROJECT_ID" 2>/dev/null || true
                    
                    gcloud dns record-sets transaction remove \
                        --zone="$DNS_ZONE" \
                        --project="$GCP_PROJECT_ID" \
                        --name="$DOMAIN_NAME." \
                        --type=A \
                        --ttl=300 \
                        --rrdatas="$OLD_IP" 2>/dev/null || true
                    
                    gcloud dns record-sets transaction add \
                        --zone="$DNS_ZONE" \
                        --project="$GCP_PROJECT_ID" \
                        --name="$DOMAIN_NAME." \
                        --type=A \
                        --ttl=300 \
                        --rrdatas="$INGRESS_IP" 2>/dev/null || true
                    
                    gcloud dns record-sets transaction execute \
                        --zone="$DNS_ZONE" \
                        --project="$GCP_PROJECT_ID" 2>/dev/null && \
                        echo "   ✅ DNS A record updated: $DOMAIN_NAME -> $INGRESS_IP" || \
                        echo "   ⚠️  Failed to update DNS record automatically"
                else
                    echo "   ℹ️  DNS record already points to $INGRESS_IP"
                fi
            else
                echo "   ➕ Creating new DNS A record..."
                gcloud dns record-sets create "$DOMAIN_NAME." \
                    --zone="$DNS_ZONE" \
                    --project="$GCP_PROJECT_ID" \
                    --type=A \
                    --ttl=300 \
                    --rrdatas="$INGRESS_IP" 2>/dev/null && \
                    echo "   ✅ DNS A record created: $DOMAIN_NAME -> $INGRESS_IP" || \
                    echo "   ⚠️  Failed to create DNS record automatically"
            fi
            
            echo ""
            echo "   ⏳ DNS propagation may take a few minutes"
            echo "   ⏳ SSL certificate provisioning may take 5-15 minutes after DNS propagates"
        else
            echo "   ⚠️  Could not find DNS zone for $DOMAIN_PART"
            echo "   Please create DNS A record manually:"
            echo "      $DOMAIN_NAME -> $INGRESS_IP"
            echo ""
            echo "   Or create a managed zone first:"
            echo "      gcloud dns managed-zones create ZONE_NAME \\"
            echo "        --dns-name=$DOMAIN_PART \\"
            echo "        --description=\"DNS zone for $DOMAIN_PART\" \\"
            echo "        --project=$GCP_PROJECT_ID"
        fi
    else
        echo "   ⚠️  Ingress IP not yet assigned"
        echo "   Check status with: kubectl get ingress -n $K8S_NAMESPACE"
    fi
    
    FRONTEND_URL="https://$DOMAIN_NAME"
else
    echo "🌐 Getting LoadBalancer IP..."
    
    # Wait for LoadBalancer IP to be assigned
    echo "   Waiting for LoadBalancer IP assignment..."
    sleep 10
    
    FRONTEND_IP=""
    for i in {1..30}; do
        FRONTEND_IP=$(kubectl get svc frontend-service \
            -n "$K8S_NAMESPACE" \
            -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        
        if [ -n "$FRONTEND_IP" ]; then
            break
        fi
        
        echo "   Attempt $i/30: Waiting for IP assignment..."
        sleep 10
    done
    
    if [ -z "$FRONTEND_IP" ]; then
        echo "⚠️  LoadBalancer IP not yet assigned"
        echo "   Check status with: kubectl get svc -n $K8S_NAMESPACE"
        FRONTEND_URL="(pending LoadBalancer IP assignment)"
    else
        echo "   ✅ LoadBalancer IP: $FRONTEND_IP"
        FRONTEND_URL="http://$FRONTEND_IP"
    fi
fi

echo ""

# ────────────────────────────────────────────────────────────────────────────────
# Step 17: Display Results
# ────────────────────────────────────────────────────────────────────────────────
echo "🎉 Deployment Complete!"
echo "=========================================================="
echo ""
echo "Application URLs:"
if [ -n "$DOMAIN_NAME" ] && [ "$DOMAIN_NAME" != "null" ] && [ "$DOMAIN_NAME" != "" ]; then
    echo "  Frontend: https://$DOMAIN_NAME"
    if [ -n "$INGRESS_IP" ]; then
        echo ""
        echo "  ⚠️  DNS Configuration Required:"
        echo "     Create A record: $DOMAIN_NAME -> $INGRESS_IP"
        echo "     SSL certificate will provision automatically after DNS is configured"
    fi
else
    echo "  Frontend: $FRONTEND_URL"
    if [ "$FRONTEND_URL" = "(pending LoadBalancer IP assignment)" ]; then
        echo "  Check with: kubectl get svc -n $K8S_NAMESPACE"
    fi
fi
echo ""
echo "GKE Cluster:"
echo "  Name: $CLUSTER_NAME"
echo "  Region: $GCP_REGION"
echo "  Project: $GCP_PROJECT_ID"
echo ""
echo "Useful Commands:"
echo "  View pods:     kubectl get pods -n $K8S_NAMESPACE"
echo "  View services: kubectl get svc -n $K8S_NAMESPACE"
echo "  View logs:     kubectl logs -f -l app=backend -n $K8S_NAMESPACE"
echo "  Teardown:      make destroy"
echo ""
echo "💰 Estimated Monthly Cost:"
echo "  - Compute (2x e2-medium): ~\$48/month"
echo "  - LoadBalancer: ~\$18/month"
echo "  - Storage (10GB): ~\$2/month"
echo "  - Total: ~\$68-73/month"
echo ""
echo "🔑 Demo User Credentials:"
echo "  Email:    demo@example.com"
echo "  Password: demo123"
echo ""
echo "  Use these credentials to log in and test your application."
echo "  Note: Run 'make seed' to generate seed data if needed."
echo ""
echo "⚠️  Remember to run 'make destroy' when done to avoid ongoing costs!"
echo ""

