#!/bin/bash
# Health check polling script - waits for all services to be healthy

set -e

TIMEOUT=300  # 5 minutes
INTERVAL=5   # Check every 5 seconds
ELAPSED=0

FRONTEND_URL="http://localhost:3000/health"
BACKEND_URL="http://localhost:8080/health"
BACKEND_READY_URL="http://localhost:8080/health/ready"

echo "🏥 Waiting for services to be healthy..."

check_health() {
    local url=$1
    local service=$2
    
    if curl -sf "$url" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

while [ $ELAPSED -lt $TIMEOUT ]; do
    BACKEND_OK=false
    BACKEND_READY_OK=false
    FRONTEND_OK=false
    
    # Check backend health
    if check_health "$BACKEND_URL" "backend"; then
        BACKEND_OK=true
    fi
    
    # Check backend readiness
    if check_health "$BACKEND_READY_URL" "backend-ready"; then
        BACKEND_READY_OK=true
    fi
    
    # Check frontend health (optional, skip if not implemented)
    if check_health "$FRONTEND_URL" "frontend" 2>/dev/null; then
        FRONTEND_OK=true
    else
        # Frontend health check is optional, mark as OK if backend is ready
        if [ "$BACKEND_READY_OK" = true ]; then
            FRONTEND_OK=true
        fi
    fi
    
    # Display status
    STATUS=""
    [ "$BACKEND_OK" = true ] && STATUS="${STATUS}✅ backend "
    [ "$BACKEND_READY_OK" = true ] && STATUS="${STATUS}✅ backend-ready "
    [ "$FRONTEND_OK" = true ] && STATUS="${STATUS}✅ frontend "
    
    if [ "$BACKEND_OK" = true ] && [ "$BACKEND_READY_OK" = true ] && [ "$FRONTEND_OK" = true ]; then
        echo ""
        echo "✅ All services are healthy!"
        exit 0
    fi
    
    echo "[${ELAPSED}s] Waiting... ${STATUS}"
    
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

echo ""
echo "❌ Health check timeout after ${TIMEOUT} seconds"
echo "   Some services may not be ready. Check logs with: docker-compose logs"
exit 1

