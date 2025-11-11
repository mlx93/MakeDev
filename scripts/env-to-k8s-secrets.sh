#!/bin/bash
# Convert .env to Kubernetes Secrets and ConfigMaps
# Automatically detects sensitive keys and generates K8s manifests
# Compatible with bash 3.2+ (no associative arrays)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(pwd)"

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

# Initialize secret and config files
BACKEND_SECRET_FILE="$SECRETS_DIR/backend-secret.yaml"
POSTGRES_SECRET_FILE="$SECRETS_DIR/postgres-secret.yaml"
DB_USER="postgres"
DB_PASSWORD="postgres"
DB_NAME="appdb"

# Start backend secret file
cat > "$BACKEND_SECRET_FILE" << 'EOF'
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

# Parse .env file and build secrets/configs
SECRET_COUNT=0
while IFS='=' read -r key value || [ -n "$key" ]; do
    # Skip comments and empty lines
    [[ "$key" =~ ^#.*$ ]] && continue
    [[ -z "$key" ]] && continue
    
    # Remove leading/trailing whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)
    
    # Remove quotes from value
    value=$(echo "$value" | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//")
    
    # Extract database credentials for postgres secret
    # Support both DATABASE_* and POSTGRES_* prefixes
    if [ "$key" = "DATABASE_USER" ] || [ "$key" = "POSTGRES_USER" ]; then
        DB_USER="$value"
    elif [ "$key" = "DATABASE_PASSWORD" ] || [ "$key" = "POSTGRES_PASSWORD" ]; then
        DB_PASSWORD="$value"
    elif [ "$key" = "DATABASE_NAME" ] || [ "$key" = "POSTGRES_DB" ]; then
        DB_NAME="$value"
    fi
    
    # Check if key is sensitive or required for backend (like DATABASE_URL, REDIS_URL)
    REQUIRED_BACKEND_VARS="DATABASE_URL|REDIS_URL"
    if echo "$key" | grep -iE "$SENSITIVE_PATTERNS" > /dev/null || echo "$key" | grep -iE "$REQUIRED_BACKEND_VARS" > /dev/null; then
        # Add to backend secret
        encoded=$(echo -n "$value" | base64)
        echo "  $key: $encoded" >> "$BACKEND_SECRET_FILE"
        echo "   ✅ Added secret: $key"
        SECRET_COUNT=$((SECRET_COUNT + 1))
    fi
done < "$ENV_FILE"

# Remove backend secret file if no secrets were added
if [ $SECRET_COUNT -eq 0 ]; then
    rm -f "$BACKEND_SECRET_FILE"
else
    echo ""
fi

# Generate postgres-secret.yaml
echo "🔒 Generating postgres-secret.yaml..."

cat > "$POSTGRES_SECRET_FILE" <<EOF
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
[ -f "$BACKEND_SECRET_FILE" ] && echo "  - $BACKEND_SECRET_FILE"
echo "  - $POSTGRES_SECRET_FILE"
echo ""
echo "⚠️  IMPORTANT: These files contain sensitive data and are gitignored."
echo "   They will be applied directly to your GKE cluster."
echo ""
