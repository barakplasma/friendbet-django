#!/bin/bash
# FriendBet Monitoring Dashboard
# Provides quick overview of system health and statistics

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       FriendBet Monitoring Dashboard       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# 1. Service Status
echo -e "${YELLOW}=== Service Status ===${NC}"
if systemctl is-active --quiet friendbet; then
    echo -e "${GREEN}✓ FriendBet service: RUNNING${NC}"
    UPTIME=$(systemctl show friendbet -p ActiveEnterTimestamp --value)
    echo "  Since: $UPTIME"
else
    echo -e "${RED}✗ FriendBet service: STOPPED${NC}"
fi
echo ""

# 2. Resource Usage
echo -e "${YELLOW}=== Resource Usage ===${NC}"
CPU=$(ps aux | grep '[p]ocketbase' | awk '{sum+=$3} END {printf "%.1f", sum}')
MEM=$(ps aux | grep '[p]ocketbase' | awk '{sum+=$4} END {printf "%.1f", sum}')
echo "CPU: ${CPU}%"
echo "Memory: ${MEM}%"
echo ""

# 3. Disk Usage
echo -e "${YELLOW}=== Disk Usage ===${NC}"
DISK=$(df -h /opt/friendbet | tail -1 | awk '{print $5}')
echo "FriendBet directory: ${DISK}"
BACKUPS=$(du -sh /opt/friendbet/backups 2>/dev/null | awk '{print $1}')
echo "Backups size: ${BACKUPS}"
echo ""

# 4. Database Stats
echo -e "${YELLOW}=== Database Stats ===${NC}"
if [ -f "/opt/friendbet/pb_data/data.db" ]; then
    DB_SIZE=$(du -h /opt/friendbet/pb_data/data.db | awk '{print $1}')
    echo "Database size: ${DB_SIZE}"
    
    # Count records in each table (requires sqlite3)
    if command -v sqlite3 &> /dev/null; then
        echo "Records (approximate):"
        sqlite3 /opt/friendbet/pb_data/data.db << 'EOF' 2>/dev/null
SELECT '  Users: ' || COUNT(*) FROM users;
SELECT '  Groups: ' || COUNT(*) FROM groups;
SELECT '  Markets: ' || COUNT(*) FROM markets;
SELECT '  Bets: ' || COUNT(*) FROM bets;
EOF
    fi
else
    echo -e "${RED}✗ Database not found${NC}"
fi
echo ""

# 5. Backup Status
echo -e "${YELLOW}=== Backup Status ===${NC}"
LATEST_BACKUP=$(ls -t /opt/friendbet/backups/friendbet_backup_*.zip 2>/dev/null | head -1)
if [ -n "$LATEST_BACKUP" ]; then
    BACKUP_DATE=$(stat -c %y "$LATEST_BACKUP" | cut -d'.' -f1)
    BACKUP_SIZE=$(du -h "$LATEST_BACKUP" | awk '{print $1}')
    echo -e "${GREEN}✓ Latest backup: ${BACKUP_SIZE}${NC}"
    echo "  Created: $BACKUP_DATE"
else
    echo -e "${RED}✗ No backups found${NC}"
fi

BACKUP_COUNT=$(ls /opt/friendbet/backups/friendbet_backup_*.zip 2>/dev/null | wc -l)
echo "Total backups: $BACKUP_COUNT"
echo ""

# 6. Recent Logs
echo -e "${YELLOW}=== Recent Logs (last 5 lines) ===${NC}"
journalctl -u friendbet -n 5 --no-pager
echo ""

# 7. Health Check
echo -e "${YELLOW}=== Health Check ===${NC}"
HEALTH_URL="http://localhost:8090/api/health"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" 2>/dev/null || echo "000")
if [ "$HTTP_STATUS" -eq 200 ]; then
    echo -e "${GREEN}✓ API responding (HTTP $HTTP_STATUS)${NC}"
else
    echo -e "${RED}✗ API not responding (HTTP $HTTP_STATUS)${NC}"
fi
echo ""

# 8. Recent Errors
echo -e "${YELLOW}=== Recent Errors (last 24h) ===${NC}"
ERROR_COUNT=$(journalctl -u friendbet -since "24 hours ago" --priority=err | wc -l)
if [ "$ERROR_COUNT" -gt 0 ]; then
    echo -e "${RED}✗ $ERROR_COUNT errors found${NC}"
    echo "Recent errors:"
    journalctl -u friendbet -since "24 hours ago" --priority=err -n 3 --no-pager
else
    echo -e "${GREEN}✓ No errors in last 24 hours${NC}"
fi
echo ""

# 9. Quick Actions Menu
echo -e "${YELLOW}=== Quick Actions ===${NC}"
echo "1) View live logs: journalctl -u friendbet -f"
echo "2) Restart service: systemctl restart friendbet"
echo "3) Run backup now: /opt/friendbet/deploy/backup.sh"
echo "4) View all backups: ls -lh /opt/friendbet/backups/"
echo "5) Access admin UI: http://localhost:8090/_/"
echo "6) Open monitoring: watch -n 5 /opt/friendbet/deploy/monitoring.sh"

echo ""
echo -e "${BLUE}Press Ctrl+C to exit${NC}"