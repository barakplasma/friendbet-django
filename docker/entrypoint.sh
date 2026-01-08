#!/bin/sh
set -e

# FriendBet Docker Entrypoint Script
# This script handles initialization and startup of PocketBase with proper error handling

echo "Starting FriendBet PocketBase Container..."
echo "Version: $(/pocketbase/pocketbase version)"
echo "Data directory: ${PB_DATA_DIR:-/pb_data}"
echo "Public directory: ${PB_PUBLIC_DIR:-/pb_public}"

# Functions
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1" >&2
}

# Initialize directories
initialize_directories() {
    log_info "Initializing directories..."
    
    # Ensure directories exist with correct permissions
    mkdir -p "${PB_DATA_DIR:-/pb_data}/backups"
    mkdir -p "${PB_PUBLIC_DIR:-/pb_public}"
    mkdir -p "${PB_HOOKS_DIR:-/pb_hooks}"
    
    # Check if database exists
    if [ ! -f "${PB_DATA_DIR:-/pb_data}/data.db" ]; then
        log_info "No existing database found. This appears to be a fresh installation."
        
        # Create admin user if credentials provided
        if [ -n "$PB_ADMIN_EMAIL" ] && [ -n "$PB_ADMIN_PASSWORD" ]; then
            log_info "Admin credentials provided. User will be created on first access."
            export PB_ADMIN_EMAIL
            export PB_ADMIN_PASSWORD
        fi
    else
        log_info "Existing database found. Starting with existing data."
    fi
}

# Health check function
health_check() {
    log_info "Performing initial health check..."
    
    # Wait for PocketBase to be ready
    MAX_ATTEMPTS=30
    ATTEMPT=0
    
    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        if curl -f -s "http://localhost:8090/api/health" > /dev/null 2>&1; then
            log_info "Health check passed!"
            return 0
        fi
        
        ATTEMPT=$((ATTEMPT + 1))
        sleep 2
    done
    
    log_error "Health check failed after ${MAX_ATTEMPTS} attempts"
    return 1
}

# Signal handler for graceful shutdown
graceful_shutdown() {
    log_info "Received shutdown signal. Gracefully stopping PocketBase..."
    
    if [ -n "$POCKETBASE_PID" ]; then
        kill -TERM "$POCKETBASE_PID" 2>/dev/null || true
        wait "$POCKETBASE_PID" 2>/dev/null || true
    fi
    
    log_info "PocketBase stopped gracefully."
    exit 0
}

# Setup signal handlers
trap graceful_shutdown SIGTERM SIGINT

# Main execution
main() {
    # Initialize environment
    initialize_directories
    
    # Set default environment variables if not set
    export PB_HOME="${PB_HOME:-/pocketbase}"
    export PB_DATA_DIR="${PB_DATA_DIR:-/pb_data}"
    export PB_PUBLIC_DIR="${PB_PUBLIC_DIR:-/pb_public}"
    export PB_HOOKS_DIR="${PB_HOOKS_DIR:-/pb_hooks}"
    
    # Display startup information
    log_info "Starting PocketBase server..."
    log_info "Application URL: ${PB_URL:-http://localhost:8090}"
    log_info "Admin UI: ${PB_URL:-http://localhost:8090}/_/"
    
    # Start PocketBase in background
    /pocketbase/pocketbase serve --http=0.0.0.0:8090 "$@" &
    POCKETBASE_PID=$!
    
    log_info "PocketBase started with PID: $POCKETBASE_PID"
    
    # Perform health check
    if ! health_check; then
        log_error "Failed to start PocketBase properly"
        kill "$POCKETBASE_PID" 2>/dev/null || true
        exit 1
    fi
    
    log_info "FriendBet is ready and accepting connections!"
    
    # Wait for PocketBase process
    wait "$POCKETBASE_PID"
}

# Run main function
main "$@"
