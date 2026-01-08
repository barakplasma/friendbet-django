#!/bin/bash
# FriendBet Build and Deploy Script
# Builds Angular frontend and deploys to PocketBase

set -e

# Configuration
FRONTEND_DIR="./frontend"
BUILD_OUTPUT_DIR="$FRONTEND_DIR/dist/friendbet"
DEPLOY_TARGET="/opt/friendbet/pb_public"
SERVICE_NAME="friendbet"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== FriendBet Build & Deploy ===${NC}"
echo "Started: $(date)"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root${NC}"
    exit 1
fi

# Check if frontend directory exists
if [ ! -d "$FRONTEND_DIR" ]; then
    echo -e "${RED}Error: Frontend directory not found: $FRONTEND_DIR${NC}"
    echo "Run this script from the project root directory"
    exit 1
fi

# Step 1: Install dependencies
echo -e "${YELLOW}Installing frontend dependencies...${NC}"
cd "$FRONTEND_DIR"
npm ci --silent

# Step 2: Build English version
echo -e "${YELLOW}Building English version...${NC}"
ng build --configuration production,en

# Step 3: Build Hebrew version
echo -e "${YELLOW}Building Hebrew version...${NC}"
ng build --configuration production,he

# Step 4: Verify build output
if [ ! -d "$BUILD_OUTPUT_DIR" ]; then
    echo -e "${RED}Error: Build output not found${NC}"
    exit 1
fi

# Get build size
BUILD_SIZE=$(du -sh "$BUILD_OUTPUT_DIR" | cut -f1)
echo -e "${GREEN}✓ Build complete: ${BUILD_SIZE}${NC}"

# Step 5: Backup current deployment
echo -e "${YELLOW}Backing up current deployment...${NC}"
if [ -d "$DEPLOY_TARGET" ]; then
    BACKUP_NAME="pb_public_backup_$(date +%Y%m%d_%H%M%S)"
    cp -r "$DEPLOY_TARGET" "/opt/friendbet/${BACKUP_NAME}"
    echo -e "${GREEN}✓ Backup created: $BACKUP_NAME${NC}"
fi

# Step 6: Stop service
echo -e "${YELLOW}Stopping FriendBet service...${NC}"
systemctl stop "$SERVICE_NAME"

# Step 7: Deploy new build
echo -e "${YELLOW}Deploying new build...${NC}"
cd - # Return to project root
rm -rf "$DEPLOY_TARGET"/*
cp -r "$BUILD_OUTPUT_DIR"/* "$DEPLOY_TARGET/"

# Set permissions
chown -R friendbet:friendbet "$DEPLOY_TARGET"
chmod -R 755 "$DEPLOY_TARGET"

# Step 8: Start service
echo -e "${YELLOW}Starting FriendBet service...${NC}"
systemctl start "$SERVICE_NAME"

# Wait for service to start
sleep 3

# Step 9: Verify deployment
if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo -e "${GREEN}✓ Service started successfully${NC}"
else
    echo -e "${RED}✗ Service failed to start${NC}"
    echo -e "${YELLOW}Check logs with: journalctl -u $SERVICE_NAME -f${NC}"
    echo -e "${YELLOW}Restoring previous deployment...${NC}"
    systemctl stop "$SERVICE_NAME"
    if [ -d "/opt/friendbet/${BACKUP_NAME}" ]; then
        rm -rf "$DEPLOY_TARGET"/*
        cp -r "/opt/friendbet/${BACKUP_NAME}"/* "$DEPLOY_TARGET/"
        systemctl start "$SERVICE_NAME"
        echo -e "${GREEN}✓ Previous deployment restored${NC}"
    fi
    exit 1
fi

# Step 10: Test application
echo -e "${YELLOW}Testing deployment...${NC}"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8090/)
if [ "$HTTP_STATUS" -eq 200 ]; then
    echo -e "${GREEN}✓ Application is responding${NC}"
else
    echo -e "${RED}✗ Application not responding (HTTP $HTTP_STATUS)${NC}"
    exit 1
fi

echo "Completed: $(date)"
echo -e "${GREEN}=== Deployment Complete ===${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Test the application in your browser"
echo "2. Check language switching works"
echo "3. Test OAuth login flow"
echo "4. Verify real-time updates"
echo ""
echo -e "${YELLOW}To rollback if needed:${NC}"
echo "  systemctl stop friendbet"
echo "  rm -rf /opt/friendbet/pb_public/*"
echo "  cp -r /opt/friendbet/${BACKUP_NAME}/* /opt/friendbet/pb_public/"
echo "  systemctl start friendbet"