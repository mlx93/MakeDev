#!/bin/bash
# Convert .env to Kubernetes Secrets and ConfigMaps
# Automatically detects sensitive keys and generates K8s manifests

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔐 Converting environment variables to Kubernetes Secrets/ConfigMaps"
echo ""

# Check for .env.production or .env
ENV_FILE=""
if [ -f "$PROJECT_ROOT/.env.production" ]; then
    ENV_FILE="$PROJECT_ROOT/.env.production"
    echo "📄 Using .env.production"
elif [ -f "$PROJECT_ROOT/.env" ]; then
    ENV_FILE="$PROJECT_ROOT/.env"
    echo "📄 Using .env (fallback)"
else
    echo "⚠️  No .env or .env.production file found"
    echo "   Using default configuration (postgres/postgres credentials)"
    echo "   For production, create .env.production with secure passwords"
    echo ""
    
    # Create minimal defaults
    ENV_FILE="/tmp/default_env_$$"
    cat > "$ENV_FILE" << 'EOF'
DATABASE_URL=postgresql://postgres:postgres@postgres-service:5432/appdb
DATABASE_USER=postgres
DATABASE_PASSWORD=postgres
DATABASE_NAME=appdb
REDIS_URL=redis://redis-service:6379
JWT_SECRET=change-this-in-production
NODE_ENV=production
API_PORT=8080
EOF
    echo "   ✅ Using default configuration"
    echo ""
fi

# Create secrets directory
SECRETS_DIR="$PROJECT_ROOT/k8s/secrets"
mkdir -p "$SECRETS_DIR"

# Sensitive key patterns (case-insensitive)
SENSITIVE_PATTERNS="password|secret|key|token|auth|credential|api_key|private"

# Parse .env file
declare -A SECRETS
declare -A CONFIGS

while IFS='=' read -r key value || [ -n "$key" ]; do
    # Skip comments and empty lines
    [[ "$key" =~ ^#.*$ ]] && continue
    [[ -z "$key" ]] && continue
    
    # Remove leading/trailing whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    
    # Remove quotes from value
    value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
    
    # Check if key is sensitive
    if echo "$key" | grep -iE "$SENSITIVE_PATTERNS" > /dev/null; then
        SECRETS["$key"]="$value"
    else
        CONFIGS["$key"]="$value"
    fi
done < "$ENV_FILE"

# Generate backend-secret.yaml
if [ ${#SECRETS[@]} -gt 0 ]; then
    echo "🔒 Generating backend-secret.yaml..."
    
    cat > "$SECRETS_DIR/backend-secret.yaml" <<EOF
# Backend Secret (auto-generated from .env)
# DO NOT COMMIT THIS FILE TO GIT
apiVersion: v1
kind: Secret
metadata:
  name: backend-secret
  namespace: zero-to-running-app
  labels:
    app: backend
    tier: backend
type: Opaque
data:
EOF
    
    for key in "${!SECRETS[@]}"; do
        value="${SECRETS[$key]}"
        # Base64 encode the value
        encoded=$(echo -n "$value" | base64)
        echo "  $key: $encoded" >> "$SECRETS_DIR/backend-secret.yaml"
        echo "   ✅ Added secret: $key"
    done
    
    echo ""
fi

# Generate postgres-secret.yaml
echo "🔒 Generating postgres-secret.yaml..."

# Extract database credentials
DB_USER="${SECRETS[DATABASE_USER]:-postgres}"
DB_PASSWORD="${SECRETS[DATABASE_PASSWORD]:-postgres}"
DB_NAME="${CONFIGS[DATABASE_NAME]:-appdb}"

cat > "$SECRETS_DIR/postgres-secret.yaml" <<EOF
# PostgreSQL Secret (auto-generated from .env)
# DO NOT COMMIT THIS FILE TO GIT
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
  namespace: zero-to-running-app
  labels:
    app: postgres
    tier: database
type: Opaque
data:
  POSTGRES_USER: $(echo -n "$DB_USER" | base64)
  POSTGRES_PASSWORD: $(echo -n "$DB_PASSWORD" | base64)
  POSTGRES_DB: $(echo -n "$DB_NAME" | base64)
EOF

echo "   ✅ PostgreSQL credentials configured"
echo ""

# Update backend-config.yaml with non-sensitive values
if [ ${#CONFIGS[@]} -gt 0 ]; then
    echo "📝 Updating backend-config.yaml..."
    
    BACKEND_CONFIG="$PROJECT_ROOT/k8s/backend/configmap.yaml"
    
    # Read existing config
    if [ -f "$BACKEND_CONFIG" ]; then
        # Append non-sensitive values
        for key in "${!CONFIGS[@]}"; do
            # Skip if already in config
            if ! grep -q "^  $key:" "$BACKEND_CONFIG"; then
                echo "  $key: \"${CONFIGS[$key]}\"" >> "$BACKEND_CONFIG"
                echo "   ✅ Added config: $key"
            fi
        done
    fi
    
    echo ""
fi

# Add .gitignore to secrets directory
cat > "$SECRETS_DIR/.gitignore" <<EOF
# Never commit secrets to Git
*.yaml
!.gitignore
EOF

# Cleanup temporary env file if created
if [[ "$ENV_FILE" == /tmp/default_env_* ]]; then
    rm -f "$ENV_FILE"
fi

echo "✅ Secret generation complete!"
echo ""
echo "Generated files:"
echo "  - $SECRETS_DIR/backend-secret.yaml"
echo "  - $SECRETS_DIR/postgres-secret.yaml"
echo ""
echo "⚠️  IMPORTANT: These files contain sensitive data and are gitignored."
echo "   They will be applied directly to your GKE cluster."
echo ""

