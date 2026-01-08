#!/bin/sh
# Health check script for FriendBet PocketBase container
# This can be used for more advanced health checks if needed

HEALTH_URL="${HEALTH_URL:-http://localhost:8090/api/health}"
TIMEOUT="${HEALTH_TIMEOUT:-5}"
MAX_RETRIES="${HEALTH_RETRIES:-3}"

# Function to check health
check_health() {
    curl -f -s --max-time "$TIMEOUT" "$HEALTH_URL" > /dev/null 2>&1
}

# Perform health check with retries
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if check_health; then
        echo "Health check passed"
        exit 0
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    sleep 2
done

echo "Health check failed after $MAX_RETRIES attempts"
exit 1
