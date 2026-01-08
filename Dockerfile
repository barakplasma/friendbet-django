# Multi-stage Multi-architecture Dockerfile for FriendBet
# Build arguments for architecture-specific builds
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH

# Stage 1: Build Angular frontend
FROM node:24-alpine AS frontend-builder

WORKDIR /app/frontend

# Copy frontend package files
COPY frontend/package*.json ./
RUN npm ci --production=false

# Copy frontend source and build
COPY frontend/ ./
RUN npm run build && \
    # Verify build output
    ls -la dist/frontend/ && \
    # Clean up node_modules to reduce layer size
    npm cache clean --force

# Stage 2: Build PocketBase backend with frontend
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    wget \
    curl \
    tzdata \
    && update-ca-certificates

# Build arguments for PocketBase download
ARG PB_VERSION=v0.34.2
ARG TARGETPLATFORM=linux/amd64
ARG TARGETARCH=amd64

# Download and setup PocketBase for the target architecture
RUN echo "Building for platform: ${TARGETPLATFORM}, arch: ${TARGETARCH}" && \
    case "${TARGETARCH}" in \
        arm64) \
            PB_ARCH="linux_arm64" ;; \
        amd64) \
            PB_ARCH="linux_amd64" ;; \
        arm) \
            PB_ARCH="linux_armv7" ;; \
        *) \
            echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    PB_URL="https://github.com/pocketbase/pocketbase/releases/download/${PB_VERSION}/pocketbase_${PB_VERSION}_${PB_ARCH}.tar.gz" && \
    echo "Downloading PocketBase from: ${PB_URL}" && \
    wget -q "${PB_URL}" -O /tmp/pocketbase.tar.gz && \
    tar -xzf /tmp/pocketbase.tar.gz -C /tmp/ && \
    mv /tmp/pocketbase /pocketbase/ && \
    chmod +x /pocketbase/pocketbase && \
    rm /tmp/pocketbase.tar.gz && \
    # Verify installation
    /pocketbase/pocketbase version

# Create directories with proper permissions
RUN mkdir -p /pb_data /pb_public /pb_hooks /pb_data/backups /tmp && \
    # Create non-root user
    addgroup -g 1000 pocketbase && \
    adduser -D -u 1000 -G pocketbase -h /pocketbase pocketbase && \
    # Set ownership
    chown -R pocketbase:pocketbase /pb_data /pb_public /pb_hooks /pocketbase

# Copy built frontend from previous stage
COPY --from=frontend-builder --chown=pocketbase:pocketbase /app/frontend/dist/frontend/ /pb_public/

# Copy PocketBase hooks and migrations if they exist
COPY --chown=pocketbase:pocketbase backend/pb_hooks/ /pb_hooks/ 2>/dev/null || true
COPY --chown=pocketbase:pocketbase backend/migrations/ /pb_data/migrations/ 2>/dev/null || true

# Copy custom entrypoint script
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose PocketBase port
EXPOSE 8090

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8090/api/health || exit 1

# Set working directory
WORKDIR /pocketbase

# Switch to non-root user
USER pocketbase

# Set environment variables
ENV PB_HOME=/pocketbase \
    PB_DATA_DIR=/pb_data \
    PB_PUBLIC_DIR=/pb_public \
    PB_HOOKS_DIR=/pb_hooks \
    PB_ENCRYPTION_ENV=auto \
    TZ=UTC

# Run PocketBase via entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["serve", "--http=0.0.0.0:8090"]