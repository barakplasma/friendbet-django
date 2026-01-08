#!/bin/bash
# Cloudflare Access Setup for FriendBet
# This script helps configure Cloudflare Access for FriendBet using your existing K8s infrastructure

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     FriendBet Cloudflare Access Setup     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Configuration
FRIENDBIT_DOMAIN="friendbet.yourdomain.com"  # UPDATE THIS
FRIENDBIT_SERVICE="friendbet"
FRIENDBIT_NAMESPACE="default"
FRIENDBIT_PORT="8090"

echo -e "${YELLOW}Configuration:${NC}"
echo "Domain: $FRIENDBIT_DOMAIN"
echo "Service: $FRIENDBIT_SERVICE"
echo "Namespace: $FRIENDBIT_NAMESPACE"
echo "Port: $FRIENDBIT_PORT"
echo ""

# Option 1: Add to existing Cloudflare Tunnel
echo -e "${BLUE}=== Option 1: Add to Existing Cloudflare Tunnel ===${NC}"
echo ""
echo "Since you already have Cloudflare Tunnel running on K8s, add this ingress:"
echo ""
cat << 'EOF'
# Add this ingress to your existing Cloudflare Tunnel config
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: friendbet-ingress
  namespace: default
  annotations:
    argocd.argoproj.io/sync-options: SkipDryRunOnMissingResource=true
spec:
  ingressClassName: cloudflare-tunnel
  rules:
  - host: friendbet.yourdomain.com  # UPDATE THIS DOMAIN
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: friendbet
            port:
              number: 8090
EOF
echo ""

# Option 2: Create Cloudflare Access Policy
echo -e "${BLUE}=== Option 2: Cloudflare Access Policy ===${NC}"
echo ""
echo "Follow these steps in Cloudflare Dashboard:"
echo ""
echo "1. Go to: Zero Trust > Access > Applications"
echo "2. Click 'Add an application'"
echo "3. Configure:"
echo "   - Session duration: 24h"
echo "   - Application name: FriendBet"
echo "   - Path: https://friendbet.yourdomain.com/*"
echo "   - Type: Self-hosted"
echo ""
echo "4. Add access policy (examples):"
echo "   - Email domain: yourdomain.com"
echo "   - Or: Specific email addresses"
echo "   - Or: Google/Microsoft GitHub OAuth"
echo ""
echo "5. Configure authentication methods:"
echo "   - One-Time PIN, Hardware Key, or OAuth"
echo ""

# Step 3: Create K8s Service for FriendBet
echo -e "${BLUE}=== Step 3: Create Kubernetes Service ===${NC}"
echo ""
cat << 'EOF'
# Create this service and apply to your cluster
apiVersion: v1
kind: Service
metadata:
  name: friendbet
  namespace: default
spec:
  type: ClusterIP
  ports:
  - port: 8090
    targetPort: 8090
    protocol: TCP
    name: http
  selector:
    app: friendbet
---
# If PocketBase is running outside K8s, use ExternalName service:
apiVersion: v1
kind: Service
metadata:
  name: friendbet
  namespace: default
spec:
  type: ExternalName
  externalName: <your-vps-ip-or-hostname>  # UPDATE THIS
  ports:
  - port: 8090
EOF
echo ""

# Step 4: Update PocketBase CORS
echo -e "${BLUE}=== Step 4: Update PocketBase CORS Settings ===${NC}"
echo ""
echo "Add this to your PocketBase configuration or set via environment:"
echo ""
cat << 'EOF'
# In PocketBase, set CORS origins to allow your Cloudflare domain
# This can be done via environment variable or pb_data setting

# Environment variable approach:
export PB_ORIGIN_WHITELIST="https://friendbet.yourdomain.com,http://localhost:4200"

# Or update pb_data/base.db via admin UI:
# Settings > CORS > Add your Cloudflare domain
EOF
echo ""

# Quick deployment script
echo -e "${BLUE}=== Quick Deployment Script ===${NC}"
echo ""
cat << 'EOF'
# Save this as deploy-cloudflare-access.sh and run it
#!/bin/bash

# Update these values
DOMAIN="friendbet.yourdomain.com"
VPS_IP="your.vps.ip.address"

# Create the service
cat << SERVICE | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: friendbet
  namespace: default
spec:
  type: ExternalName
  externalName: $VPS_IP
  ports:
  - port: 8090
SERVICE

# Create the ingress
cat << INGRESS | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: friendbet-ingress
  namespace: default
  annotations:
    argocd.argoproj.io/sync-options: SkipDryRunOnMissingResource=true
spec:
  ingressClassName: cloudflare-tunnel
  rules:
  - host: $DOMAIN
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: friendbet
            port:
              number: 8090
INGRESS

echo "FriendBet service and ingress created!"
echo "Access: https://$DOMAIN"
EOF
echo ""

echo -e "${GREEN}=== Summary ===${NC}"
echo ""
echo "1. Update your existing Cloudflare Tunnel config with FriendBet ingress"
echo "2. Create Kubernetes Service pointing to your VPS"
echo "3. Configure Cloudflare Access policy in Zero Trust dashboard"
echo "4. Update PocketBase CORS settings"
echo "5. Access FriendBet at: https://friendbet.yourdomain.com"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo "- Update 'friendbet.yourdomain.com' to your actual domain"
echo "- Update VPS IP address in ExternalName service"
echo "- Configure Access policy to match your security requirements"
echo "- PocketBase continues running on VPS (not in K8s)"
echo ""
echo -e "${GREEN}Setup complete! Your FriendBet will be protected by Cloudflare Access.${NC}"