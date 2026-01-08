#!/bin/bash
# FriendBet Production Build and Deployment Script for Kubernetes
# Supports multi-architecture builds and automated deployment

set -e  # Exit on error
set -o pipefail  # Catch errors in pipes

# Configuration
IMAGE_NAME="friendbet"
IMAGE_TAG="${1:-latest}"
REGISTRY="${REGISTRY:-localhost:5000}"  # Override with environment variable
NAMESPACE="${NAMESPACE:-friendbet}"
HELM_RELEASE="friendbet"
BUILD_PLATFORM="${BUILD_PLATFORM:-linux/arm64}"  # Default to ARM64, can be "linux/amd64,linux/arm64"
PROJECT_ROOT="/root/toto"
FRONTEND_DIR="${PROJECT_ROOT}/frontend"
BACKEND_DIR="${PROJECT_ROOT}/backend"
HELM_DIR="${PROJECT_ROOT}/helm/friendbet"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl first."
    fi
    
    # Check if helm is installed
    if ! command -v helm &> /dev/null; then
        log_error "Helm is not installed. Please install Helm first."
    fi
    
    # Check if project directories exist
    if [ ! -d "$PROJECT_ROOT" ]; then
        log_error "Project root directory not found: $PROJECT_ROOT"
    fi
    
    log_success "Prerequisites check passed"
}

# Build Angular frontend
build_frontend() {
    log_info "Building Angular frontend..."
    
    cd "$FRONTEND_DIR"
    
    # Clean previous build
    log_info "Cleaning previous build artifacts..."
    rm -rf dist/ node_modules/.cache/
    
    # Install dependencies
    log_info "Installing frontend dependencies..."
    npm ci --production=false
    
    # Build Angular app
    log_info "Compiling Angular application..."
    npm run build
    
    # Verify build output
    if [ ! -d "dist/frontend" ]; then
        log_error "Angular build failed - dist/frontend directory not found"
    fi
    
    log_success "Frontend built successfully"
}

# Build Docker image with multi-architecture support
build_docker_image() {
    log_info "Building Docker image for platform: $BUILD_PLATFORM"
    
    cd "$PROJECT_ROOT"
    
    # Use BuildKit for better caching and multi-platform support
    export DOCKER_BUILDKIT=1
    
    # Build image with specified platform
    docker build \
        --platform "$BUILD_PLATFORM" \
        --build-arg TARGETPLATFORM="$BUILD_PLATFORM" \
        --build-arg PB_VERSION=v0.34.2 \
        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
        -t "${IMAGE_NAME}:latest" \
        -f Dockerfile .
    
    # Verify image was built
    if ! docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" &> /dev/null; then
        log_error "Docker image build failed"
    fi
    
    log_success "Docker image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"
}

# Tag and push image to registry
tag_and_push_image() {
    log_info "Tagging and pushing image to registry: $REGISTRY"
    
    # Tag image for registry
    docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${REGISTRY}/${IMAGE_NAME}:latest"
    
    # Push to registry if not using local registry
    if [ "$REGISTRY" != "localhost:5000" ]; then
        log_info "Pushing images to registry..."
        docker push "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
        docker push "${REGISTRY}/${IMAGE_NAME}:latest"
        log_success "Images pushed to registry"
    else
        log_warning "Using local registry, skipping push"
    fi
}

# Deploy via Helm
deploy_helm() {
    log_info "Deploying via Helm to namespace: $NAMESPACE"
    
    # Create namespace if it doesn't exist
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    cd "$HELM_DIR"
    
    # Deploy using Helm
    helm upgrade --install "$HELM_RELEASE" . \
        --namespace "$NAMESPACE" \
        --create-namespace \
        --values values.yaml \
        --set image.repository="${REGISTRY}/${IMAGE_NAME}" \
        --set image.tag="${IMAGE_TAG}" \
        --set fullnameOverride="friendbet" \
        --wait \
        --timeout 5m
    
    log_success "Helm deployment completed"
}

# Wait for deployment to be ready
wait_for_deployment() {
    log_info "Waiting for deployment to be ready..."
    
    # Wait for deployment
    kubectl wait --for=condition=available --timeout=120s \
        deployment/friendbet -n "$NAMESPACE"
    
    # Wait for pods to be ready
    kubectl wait --for=condition=ready --timeout=120s \
        pod -l "app.kubernetes.io/name=friendbet" -n "$NAMESPACE"
    
    log_success "Deployment is ready"
}

# Show deployment status
show_deployment_status() {
    echo ""
    log_info "Deployment Status:"
    echo ""
    
    echo "Pods:"
    kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=friendbet"
    echo ""
    
    echo "Service:"
    kubectl get service -n "$NAMESPACE" friendbet
    echo ""
    
    echo "Ingress:"
    kubectl get ingress -n "$NAMESPACE" friendbet
    echo ""
    
    echo "PVC:"
    kubectl get pvc -n "$NAMESPACE" friendbet-data
}

# Main deployment function
main() {
    echo -e "${BLUE}=== FriendBet Kubernetes Build & Deploy ===${NC}"
    echo "Configuration:"
    echo "  - Registry: $REGISTRY"
    echo "  - Namespace: $NAMESPACE"
    echo "  - Image: ${IMAGE_NAME}:${IMAGE_TAG}"
    echo "  - Platform: $BUILD_PLATFORM"
    echo ""
    
    # Execute deployment steps
    check_prerequisites
    build_frontend
    build_docker_image
    tag_and_push_image
    deploy_helm
    wait_for_deployment
    show_deployment_status
    
    # Success message
    echo ""
    echo -e "${GREEN}=== Deployment Complete ===${NC}"
    echo ""
    echo -e "${BLUE}FriendBet URLs:${NC}"
    echo "  Application: https://friendbet.526462738.xyz"
    echo "  Admin UI:    https://friendbet.526462738.xyz/_/"
    echo "  API:         https://friendbet.526462738.xyz/api/"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Access admin UI to create initial account"
    echo "  2. Configure OAuth providers (Google, GitHub, Microsoft)"
    echo "  3. Import database schema if needed"
    echo "  4. Configure backup settings"
    echo ""
    echo -e "${YELLOW}Useful Commands:${NC}"
    echo "  - View logs: kubectl logs -f deployment/friendbet -n $NAMESPACE"
    echo "  - Restart:   kubectl rollout restart deployment/friendbet -n $NAMESPACE"
    echo "  - Scale:     kubectl scale deployment/friendbet --replicas=2 -n $NAMESPACE"
    echo ""
}

# Run main function
main "$@