#!/bin/bash
# Multi-Architecture Build Script for FriendBet
# Builds and pushes images for multiple architectures

set -e

# Configuration
IMAGE_NAME="friendbet"
IMAGE_TAG="${1:-latest}"
REGISTRY="${REGISTRY:-ghcr.io/yourusername}"  # Change to your registry
PLATFORMS="linux/amd64,linux/arm64"  # Multi-architecture build

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${BLUE}=== FriendBet Multi-Architecture Build ===${NC}"
echo "Building for: $PLATFORMS"
echo ""

# Check if buildx is available
if ! docker buildx version &> /dev/null; then
    log_error "docker buildx is not available. Please install buildx first."
fi

# Create and use buildx builder
log_info "Setting up buildx builder..."
BUILDER_NAME="friendbet-builder"

if ! docker buildx inspect "$BUILDER_NAME" &> /dev/null; then
    docker buildx create --name "$BUILDER_NAME" --driver docker-container --use
    docker buildx inspect --bootstrap
else
    docker buildx use "$BUILDER_NAME"
fi

# Build Angular frontend first
log_info "Building Angular frontend..."
cd /root/toto/frontend
npm ci --production=false
npm run build
log_success "Frontend built successfully"

# Build and push multi-architecture image
log_info "Building multi-architecture Docker image..."
cd /root/toto

docker buildx build \
    --platform "$PLATFORMS" \
    --build-arg PB_VERSION=v0.34.2 \
    --tag "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}" \
    --tag "${REGISTRY}/${IMAGE_NAME}:latest" \
    --push \
    -f Dockerfile .

log_success "Multi-architecture image built and pushed"
echo ""
echo "Available images:"
echo "  - ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
echo "  - ${REGISTRY}/${IMAGE_NAME}:latest"
echo ""
echo "Supported architectures: AMD64, ARM64"
