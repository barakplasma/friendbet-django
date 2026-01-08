#!/bin/bash
# FriendBet Restore Script
# Restores PocketBase from a backup

set -e

# Configuration
INSTALL_DIR="/opt/friendbet"
BACKUP_DIR="$INSTALL_DIR/backups"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== FriendBet Restore ===${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root${NC}"
    exit 1
fi

# Check if backup file provided
if [ -z "$1" ]; then
    echo -e "${RED}Usage: $0 <backup_file.zip>${NC}"
    echo ""
    echo "Available backups:"
    ls -lh "$BACKUP_DIR"/friendbet_backup_*.zip 2>/dev/null || echo "No backups found"
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "$BACKUP_FILE" ] && [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    echo -e "${RED}Backup file not found: $BACKUP_FILE${NC}"
    exit 1
fi

# Use full path if only filename provided
if [ ! -f "$BACKUP_FILE" ]; then
    BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
fi

echo -e "${YELLOW}Backup to restore: $BACKUP_FILE${NC}"
echo ""

# Confirm restoration
read -p "This will replace all current data. Are you sure? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

# Stop service
echo -e "${YELLOW}Stopping FriendBet service...${NC}"
systemctl stop friendbet

# Backup current data before restore (just in case)
echo -e "${YELLOW}Backing up current data...${NC}"
CURRENT_BACKUP="${BACKUP_DIR}/pre_restore_$(date +%Y%m%d_%H%M%S).zip"
cd "$INSTALL_DIR"
./pocketbase backup "$CURRENT_BACKUP"
echo -e "${GREEN}✓ Current data backed up to: $CURRENT_BACKUP${NC}"

# Clear existing data directory
echo -e "${YELLOW}Clearing existing data...${NC}"
rm -rf "$INSTALL_DIR/pb_data"/*

# Restore from backup
echo -e "${YELLOW}Restoring from backup...${NC}"
unzip -q "$BACKUP_FILE" -d "$INSTALL_DIR"

# Start service
echo -e "${YELLOW}Starting FriendBet service...${NC}"
systemctl start friendbet

# Wait for service to start
sleep 3

# Check service status
if systemctl is-active --quiet friendbet; then
    echo -e "${GREEN}✓ Service started successfully${NC}"
else
    echo -e "${RED}✗ Service failed to start${NC}"
    echo -e "${YELLOW}Check logs with: journalctl -u friendbet -f${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Restore Complete ===${NC}"
echo -e "${GREEN}✓ Data restored from: $BACKUP_FILE${NC}"
echo -e "${YELLOW}✓ Pre-restore backup saved to: $CURRENT_BACKUP${NC}"