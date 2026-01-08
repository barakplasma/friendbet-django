#!/bin/bash
# FriendBet Staging Deployment Script
# Deploys to staging environment with rollback capabilities

set -e

# Configuration
IMAGE_TAG="${1:-latest}"
NAMESPACE="friendbet-staging"
HELM_RELEASE="friendbet-staging"
REGISTRY="${REGISTRY:-localhost:5000}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${BLUE}=== FriendBet Staging Deployment ===${NC}"
echo "Image tag: $IMAGE_TAG"
echo "Namespace: $NAMESPACE"
echo ""

# Create staging namespace if it doesn't exist
log_info "Creating staging namespace..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Deploy staging configuration
log_info "Deploying to staging environment..."
cd /root/toto/helm/friendbet

helm upgrade --install "$HELM_RELEASE" . \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --values values.yaml \
    --set image.repository="${REGISTRY}/friendbet" \
    --set image.tag="$IMAGE_TAG" \
    --set fullnameOverride="friendbet-staging" \
    --set ingress.hostes[0].host="friendbet-staging.526462738.xyz" \
    --set resources.limits.cpu="500m" \
    --set resources.limits.memory="512Mi" \
    --set resources.requests.cpu="100m" \
    --set resources.requests.memory="128Mi" \
    --wait \
    --timeout 5m

# Wait for deployment
log_info "Waiting for staging deployment to be ready..."
kubectl wait --for=condition=available --timeout=90s \
    deployment/friendbet-staging -n "$NAMESPACE"

log_success "Staging deployment completed"

# Show status
echo ""
log_info "Staging deployment status:"
kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=friendbet"
kubectl get ingress -n "$NAMESPACE" friendbet-staging
echo ""

echo "Staging URL: https://friendbet-staging.526462738.xyz"
echo ""
log_info "Run smoke tests against staging environment before promoting to production"
