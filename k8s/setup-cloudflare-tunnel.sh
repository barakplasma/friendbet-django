#!/bin/bash
# Cloudflare Tunnel Setup Script for FriendBet
# This script helps you create and configure a Cloudflare tunnel for FriendBet

set -e

# Configuration
TUNNEL_NAME="friendbet-tunnel"
DOMAIN="friendbet.526462738.xyz"
NAMESPACE="friendbet"

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

echo -e "${BLUE}=== FriendBet Cloudflare Tunnel Setup ===${NC}"
echo ""

# Check if cloudflared is installed
if ! command -v cloudflared &> /dev/null; then
    log_error "cloudflared is not installed. Please install it first:"
    echo "  # On Linux"
    echo "  wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
    echo "  sudo dpkg -i cloudflared-linux-amd64.deb"
    echo ""
    echo "  # Or on macOS"
    echo "  brew install cloudflared"
fi

# Check if user is authenticated
log_info "Checking Cloudflare authentication..."
if ! cloudflared tunnel info &> /dev/null; then
    log_warning "You need to authenticate with Cloudflare first"
    echo "Run: cloudflared tunnel login"
    exit 1
fi

# Create tunnel
log_info "Creating Cloudflare tunnel: $TUNNEL_NAME"
if cloudflared tunnel info "$TUNNEL_NAME" &> /dev/null; then
    log_warning "Tunnel $TUNNEL_NAME already exists"
    TUNNEL_INFO=$(cloudflared tunnel info "$TUNNEL_NAME")
    log_info "Existing tunnel info: $TUNNEL_INFO"
else
    TUNNEL_OUTPUT=$(cloudflared tunnel create "$TUNNEL_NAME")
    log_success "Tunnel created successfully"
    echo "$TUNNEL_OUTPUT"
fi

# Get tunnel credentials
log_info "Getting tunnel credentials..."
TUNNEL_ID=$(cloudflared tunnel info "$TUNNEL_NAME" | grep -oP 'Your tunnel ID is \K[^ ]+')
CREDENTIALS_FILE=$(mktemp)

cloudflared tunnel token "$TUNNEL_NAME" > "$CREDENTIALS_FILE"
log_success "Tunnel credentials obtained"

# Create Kubernetes secret
log_info "Creating Kubernetes secret for tunnel credentials..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Create the secret with the tunnel token
kubectl create secret generic cloudflare-tunnel-credentials \
    --from-file=credentials.json="$CREDENTIALS_FILE" \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

log_success "Kubernetes secret created"

# Update the configmap with tunnel ID
log_info "Updating Cloudflare tunnel configuration..."
cat > /tmp/cloudflare-config.yaml <<EOF
data:
  config.yaml: |
    tunnel: ${TUNNEL_ID}
    credentials-file: /etc/cloudflared/credentials/credentials.json
    
    metrics: 0.0.0.0:2000
    
    no-autoupdate: true
    
    ingress:
      # FriendBet main application
      - hostname: ${DOMAIN}
        service: http://friendbet.${NAMESPACE}.svc.cluster.local:8090
        originRequest:
          noTLSVerify: true
          connectTimeout: 30s
          tcpKeepAlive: 30s
          keepAliveConnections: 10
          keepAliveTimeout: 90s
      
      # Health check endpoint (optional)
      - hostname: friendbet-health.526462738.xyz
        service: http://friendbet.${NAMESPACE}.svc.cluster.local:8090
        path: /api/health
        originRequest:
          noTLSVerify: true
      
      # Catch-all service to block other requests
      - service: http_status:404
EOF

# Apply the updated configuration
log_info "Applying Cloudflare tunnel configuration..."
kubectl apply -f /root/toto/k8s/cloudflare-tunnel-config.yaml

log_success "Cloudflare tunnel configuration applied"

# Deploy cloudflared
log_info "Deploying cloudflared daemon..."
kubectl apply -f /root/toto/k8s/cloudflare-tunnel-config.yaml

# Wait for deployment
log_info "Waiting for cloudflared pod to be ready..."
kubectl wait --for=condition=ready --timeout=60s \
    pod -l "app=friendbet,component=cloudflare-tunnel" -n "$NAMESPACE"

log_success "Cloudflare tunnel is now running"

# Clean up
rm -f "$CREDENTIALS_FILE" /tmp/cloudflare-config.yaml

echo ""
echo -e "${GREEN}=== Cloudflare Tunnel Setup Complete ===${NC}"
echo ""
echo "Tunnel Information:"
echo "  Tunnel Name: $TUNNEL_NAME"
echo "  Tunnel ID: $TUNNEL_ID"
echo "  Domain: $DOMAIN"
echo ""
echo "Your FriendBet application should now be accessible via:"
echo "  https://$DOMAIN"
echo ""
echo "To check tunnel status:"
echo "  cloudflared tunnel info $TUNNEL_NAME"
echo ""
echo "To view cloudflared logs:"
echo "  kubectl logs -f deployment/cloudflare-tunnel-friendbet -n $NAMESPACE"
echo ""
log_info "You can now configure your DNS to point to the Cloudflare tunnel"
