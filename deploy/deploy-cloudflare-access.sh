#!/bin/bash
# Quick deploy FriendBet with Cloudflare Access
# Update the variables at the top and run this script

set -e

# ⚠️ UPDATE THESE VALUES ⚠️
DOMAIN="friendbet.526462738.xyz"            # Your domain
VPS_IP="157.180.114.219"                    # Your VPS IP address
NAMESPACE="default"                         # Kubernetes namespace
CLUSTER="kubernetes-admin"                  # Your k8s cluster context

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== FriendBet Cloudflare Access Deployment ===${NC}"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl not found. Please install kubectl first.${NC}"
    exit 1
fi

# Check if we can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    echo -e "${YELLOW}Current context: $(kubectl config current-context)${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Connected to cluster: $(kubectl config current-context)${NC}"
echo ""

# Confirm deployment
echo -e "${YELLOW}Deployment Configuration:${NC}"
echo "Domain: $DOMAIN"
echo "VPS IP: $VPS_IP"
echo "Namespace: $NAMESPACE"
echo ""

read -p "Continue with deployment? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled"
    exit 0
fi

# Create the service
echo -e "${YELLOW}Creating Kubernetes service...${NC}"
cat << SERVICE | kubectl apply -n "$NAMESPACE" -f -
apiVersion: v1
kind: Service
metadata:
  name: friendbet
  namespace: $NAMESPACE
  labels:
    app: friendbet
    env: production
spec:
  type: ExternalName
  externalName: $VPS_IP
  ports:
  - port: 8090
    targetPort: 8090
    protocol: TCP
    name: http
SERVICE

echo -e "${GREEN}✓ Service created${NC}"

# Create the ingress
echo -e "${YELLOW}Creating Kubernetes ingress...${NC}"
cat << INGRESS | kubectl apply -n "$NAMESPACE" -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: friendbet-ingress
  namespace: $NAMESPACE
  annotations:
    argocd.argoproj.io/sync-options: SkipDryRunOnMissingResource=true
  labels:
    app: friendbet
    env: production
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

echo -e "${GREEN}✓ Ingress created${NC}"

# Wait for ingress to be ready
echo -e "${YELLOW}Waiting for ingress to be ready...${NC}"
sleep 5

# Show status
echo ""
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo -e "${BLUE}Kubernetes Resources:${NC}"
kubectl get service -n "$NAMESPACE" friendbet
kubectl get ingress -n "$NAMESPACE" friendbet-ingress
echo ""

echo -e "${BLUE}Access Information:${NC}"
echo "🌐 FriendBet URL: https://$DOMAIN"
echo "🔧 PocketBase Admin: https://$DOMAIN/_/"
echo "📱 API Endpoint: https://$DOMAIN/api/"
echo ""

echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Configure Cloudflare Access policy in Zero Trust dashboard:"
echo "   https://dash.cloudflare.com/sign-up-workers-and-pages/your-domain/access/apps"
echo ""
echo "2. Add application with:"
echo "   - Domain: $DOMAIN"
echo "   - Session duration: 24h"
echo "   - Policy: Your team emails or OAuth providers"
echo ""
echo "3. Update PocketBase CORS settings:"
echo "   - Go to https://$DOMAIN/_/"
echo "   - Settings > CORS > Add: https://$DOMAIN"
echo ""
echo "4. Test the setup:"
echo "   - Access: https://$DOMAIN"
echo "   - Login: https://$DOMAIN/_/"
echo ""

echo -e "${GREEN}Your FriendBet is now protected by Cloudflare Access! 🎉${NC}"
echo ""
echo -e "${YELLOW}To check logs:${NC}"
echo "  kubectl logs -n $NAMESPACE -l app=friendbet"
echo ""
echo -e "${YELLOW}To delete deployment:${NC}"
echo "  kubectl delete -n $NAMESPACE service friendbet"
echo "  kubectl delete -n $NAMESPACE ingress friendbet-ingress"