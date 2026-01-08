#!/bin/bash
# FriendBet Backup Script
# Automated backup of PocketBase database and uploads

set -e

# Configuration
INSTALL_DIR="/opt/friendbet"
BACKUP_DIR="$INSTALL_DIR/backups"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="friendbet_backup_${DATE}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== FriendBet Backup ===${NC}"
echo "Started: $(date)"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Stop service briefly for consistent backup
echo -e "${YELLOW}Stopping FriendBet service...${NC}"
systemctl stop friendbet

# Create backup using PocketBase backup command
echo -e "${YELLOW}Creating backup...${NC}"
cd "$INSTALL_DIR"
./pocketbase backup "${BACKUP_DIR}/${BACKUP_NAME}.zip" || {
    echo -e "${RED}Backup creation failed${NC}"
    systemctl start friendbet
    exit 1
}

# Restart service
echo -e "${YELLOW}Restarting FriendBet service...${NC}"
systemctl start friendbet

# Verify backup was created
if [ -f "${BACKUP_DIR}/${BACKUP_NAME}.zip" ]; then
    BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.zip" | cut -f1)
    echo -e "${GREEN}✓ Backup created: ${BACKUP_NAME}.zip (${BACKUP_SIZE})${NC}"
else
    echo -e "${RED}✗ Backup file not found${NC}"
    exit 1
fi

# Clean old backups
echo -e "${YELLOW}Cleaning old backups (older than ${RETENTION_DAYS} days)...${NC}"
find "$BACKUP_DIR" -name "friendbet_backup_*.zip" -mtime +$RETENTION_DAYS -delete
DELETED_COUNT=$(find "$BACKUP_DIR" -name "friendbet_backup_*.zip" | wc -l)
echo -e "${GREEN}✓ Retained ${DELETED_COUNT} backups${NC}"

# Optional: Sync to remote storage (configure as needed)
# Example using rclone for cloud storage:
# if command -v rclone &> /dev/null; then
#     echo -e "${YELLOW}Syncing to cloud storage...${NC}"
#     rclone copy "${BACKUP_DIR}/${BACKUP_NAME}.zip" remote:friendbet-backups/
#     echo -e "${GREEN}✓ Cloud sync complete${NC}"
# fi

echo "Completed: $(date)"
echo -e "${GREEN}=== Backup Complete ===${NC}"