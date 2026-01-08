#!/bin/bash
# FriendBet Quick Start Script
# Run this on a fresh VPS for complete deployment

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       FriendBet Quick Start Setup         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root${NC}"
    exit 1
fi

echo -e "${YELLOW}This script will:${NC}"
echo "1. Install PocketBase and configure it as a service"
echo "2. Set up automated backups and monitoring"
echo "3. Prepare Cloudflare Tunnel configuration"
echo "4. Provide next steps for frontend deployment"
echo ""

read -p "Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Setup cancelled"
    exit 0
fi

# Step 1: Install dependencies
echo -e "${YELLOW}=== Step 1: Installing dependencies ===${NC}"
apt update
apt install -y wget unzip sqlite3 curl

echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Step 2: Setup PocketBase
echo -e "${YELLOW}=== Step 2: Setting up PocketBase ===${NC}"
./deploy/setup-pocketbase.sh

echo ""
echo -e "${GREEN}✓ PocketBase setup complete${NC}"
echo ""

# Step 3: Setup automated maintenance
echo -e "${YELLOW}=== Step 3: Setting up automated backups ===${NC}"
./deploy/setup-cron.sh

echo ""
echo -e "${GREEN}✓ Automated backups configured${NC}"
echo ""

# Step 4: Test service
echo -e "${YELLOW}=== Step 4: Testing service ===${NC}"
sleep 2
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8090/)
if [ "$HTTP_STATUS" -eq 200 ]; then
    echo -e "${GREEN}✓ Service is responding${NC}"
else
    echo -e "${RED}✗ Service not responding (HTTP $HTTP_STATUS)${NC}"
    echo "Check logs: journalctl -u friendbet -f"
    exit 1
fi

echo ""
echo -e "${GREEN}═════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Backend Setup Complete!${NC}"
echo -e "${GREEN}═════════════════════════════════════════════${NC}"
echo ""

# Display next steps
echo -e "${BLUE}=== Next Steps ===${NC}"
echo ""
echo -e "${YELLOW}1. Configure PocketBase Admin:${NC}"
echo "   Access: http://localhost:8090/_/"
echo "   Or via your VPS IP: http://$(hostname -I | awk '{print $1}')/:8090/_/"
echo "   - Create admin account"
echo "   - Configure OAuth providers (Google/GitHub/Microsoft)"
echo ""

echo -e "${YELLOW}2. Set up Database Collections:${NC}"
echo "   - Access the admin UI"
echo "   - Create collections as per PRD:"
echo "     • groups"
echo "     • group_memberships"
echo "     • invite_codes"
echo "     • markets"
echo "     • bets"
echo "     • transactions"
echo ""

echo -e "${YELLOW}3. Configure Cloudflare Tunnel:${NC}"
echo "   - Review: cat deploy/cloudflare-tunnel.yaml"
echo "   - Add to your existing K8s tunnel configuration"
echo "   - Update hostname: friendbet.yourdomain.com"
echo ""

echo -e "${YELLOW}4. Deploy Frontend (after development):${NC}"
echo "   ./deploy/build-deploy.sh"
echo ""

echo -e "${YELLOW}5. Monitor Your Deployment:${NC}"
echo "   ./deploy/monitoring.sh"
echo ""

echo -e "${YELLOW}6. Important Files:${NC}"
echo "   - Installation: /opt/friendbet/"
echo "   - Backups: /opt/friendbet/backups/"
echo "   - Service logs: journalctl -u friendbet -f"
echo "   - Deployment guide: deploy/README.md"
echo ""

echo -e "${BLUE}=== Quick Commands ===${NC}"
echo "Service status:    systemctl status friendbet"
echo "View logs:         journalctl -u friendbet -f"
echo "Restart service:   systemctl restart friendbet"
echo "Manual backup:     /opt/friendbet/deploy/backup.sh"
echo "Monitoring:        /opt/friendbet/deploy/monitoring.sh"
echo ""

echo -e "${GREEN}Setup complete! Your FriendBet backend is ready.${NC}"
echo -e "${BLUE}Press Ctrl+C to exit${NC}"

# Keep logs open
sleep 2
journalctl -u friendbet -f