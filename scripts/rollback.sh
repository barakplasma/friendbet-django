#!/bin/bash
# FriendBet Rollback Script
# Safely rollbacks Helm deployment to previous version

set -e

# Configuration
NAMESPACE="${NAMESPACE:-friendbet}"
HELM_RELEASE="friendbet"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${BLUE}=== FriendBet Rollback ===${NC}"
echo ""

# Check if release exists
if ! helm list -n "$NAMESPACE" | grep -q "$HELM_RELEASE"; then
    log_error "Release $HELM_RELEASE not found in namespace $NAMESPACE"
fi

# Show current deployment
log_info "Current deployment:"
helm list -n "$NAMESPACE" | grep "$HELM_RELEASE"
echo ""

# Show revision history
log_info "Revision history:"
helm history "$HELM_RELEASE" -n "$NAMESPACE" --output table
echo ""

# Ask for revision to rollback
if [ -z "$1" ]; then
    log_warning "Please specify the revision number to rollback to."
    echo "Usage: $0 <revision-number>"
    echo ""
    echo "Available revisions:"
    helm history "$HELM_RELEASE" -n "$NAMESPACE" --output table | awk 'NR>2 {print $1}' | nl -v 0
    exit 1
fi

REVISION=$1

# Confirm rollback
read -p "Are you sure you want to rollback to revision $REVISION? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    log_info "Rollback cancelled"
    exit 0
fi

# Perform rollback
log_info "Rolling back to revision $REVISION..."
helm rollback "$HELM_RELEASE" "$REVISION" -n "$NAMESPACE"

# Wait for rollout
log_info "Waiting for rollback to complete..."
kubectl rollout status deployment/friendbet -n "$NAMESPACE" --timeout=120s

log_success "Rollback completed successfully"

# Show status
echo ""
log_info "Deployment status after rollback:"
kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=friendbet"
echo ""

log_info "Current Helm release:"
helm list -n "$NAMESPACE" | grep "$HELM_RELEASE"
