#!/bin/bash
# FriendBet Maintenance Scripts Setup
# Configures automated backups and monitoring

set -e

# Configuration
BACKUP_SCRIPT="/opt/friendbet/deploy/backup.sh"
LOG_FILE="/var/log/friendbet-maintenance.log"
HEALTH_CHECK_URL="http://localhost:8090/api/health"
ALERT_EMAIL="admin@yourdomain.com"  # Configure your email

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== FriendBet Maintenance Setup ===${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root${NC}"
    exit 1
fi

# 1. Set up automated daily backups (2 AM)
echo -e "${YELLOW}Configuring daily backups...${NC}"
cat > /etc/cron.d/friendbet-backup << 'EOF'
# FriendBet automated backups
# Runs daily at 2 AM
0 2 * * * root /opt/friendbet/deploy/backup.sh >> /var/log/friendbet-backup.log 2>&1
EOF

echo -e "${GREEN}✓ Daily backups configured (2 AM)${NC}"

# 2. Set up weekly backup cleanup (Sunday 3 AM)
echo -e "${YELLOW}Configuring weekly cleanup...${NC}"
cat > /etc/cron.d/friendbet-cleanup << 'EOF'
# FriendBet maintenance
# Weekly cleanup of old logs (Sundays at 3 AM)
0 3 * * 0 root find /var/log -name "friendbet*.log" -mtime +30 -delete
EOF

echo -e "${GREEN}✓ Weekly cleanup configured${NC}"

# 3. Create log rotation configuration
echo -e "${YELLOW}Configuring log rotation...${NC}"
cat > /etc/logrotate.d/friendbet << 'EOF'
/var/log/friendbet*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
    postrotate
        systemctl reload friendbet > /dev/null 2>&1 || true
    endscript
}
EOF

echo -e "${GREEN}✓ Log rotation configured${NC}"

# 4. Create health check script
echo -e "${YELLOW}Creating health check script...${NC}"
cat > /opt/friendbet/deploy/health-check.sh << 'EOF'
#!/bin/bash
# FriendBet Health Check Script
# Checks service health and sends alerts if needed

HEALTH_URL="http://localhost:8090/api/health"
ALERT_EMAIL="admin@yourdomain.com"  # Configure your email
LOG_FILE="/var/log/friendbet-health.log"

# Check if service is running
if ! systemctl is-active --quiet friendbet; then
    echo "[$(date)] ERROR: FriendBet service is not running" >> "$LOG_FILE"
    
    # Try to restart the service
    systemctl start friendbet
    sleep 5
    
    if systemctl is-active --quiet friendbet; then
        echo "[$(date)] SUCCESS: Service restarted successfully" >> "$LOG_FILE"
    else
        echo "[$(date)] CRITICAL: Service failed to restart" >> "$LOG_FILE"
        # Send email alert (configure mail service first)
        # echo "FriendBet service is down and failed to restart" | mail -s "FriendBet Alert" "$ALERT_EMAIL"
        exit 1
    fi
fi

# Check if API is responding
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL" || echo "000")
if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "[$(date)] WARNING: API not responding (HTTP $HTTP_STATUS)" >> "$LOG_FILE"
    # You might want to restart here or send alert
fi

echo "[$(date)] OK: Service healthy" >> "$LOG_FILE"
EOF

chmod +x /opt/friendbet/deploy/health-check.sh
echo -e "${GREEN}✓ Health check script created${NC}"

# 5. Set up health checks every 5 minutes
echo -e "${YELLOW}Configuring health checks...${NC}"
cat > /etc/cron.d/friendbet-health << 'EOF'
# FriendBet health checks
# Run every 5 minutes
*/5 * * * * root /opt/friendbet/deploy/health-check.sh
EOF

echo -e "${GREEN}✓ Health checks configured (every 5 minutes)${NC}"

# 6. Create maintenance log
touch /var/log/friendbet-maintenance.log
chmod 640 /var/log/friendbet-maintenance.log

echo ""
echo -e "${GREEN}=== Maintenance Setup Complete ===${NC}"
echo ""
echo -e "${YELLOW}Configured tasks:${NC}"
echo "• Daily backups at 2 AM"
echo "• Weekly log cleanup on Sundays at 3 AM"
echo "• Health checks every 5 minutes"
echo "• Log rotation for FriendBet logs"
echo ""
echo -e "${YELLOW}View logs:${NC}"
echo "• Backup logs: tail -f /var/log/friendbet-backup.log"
echo "• Health logs: tail -f /var/log/friendbet-health.log"
echo "• Service logs: journalctl -u friendbet -f"
echo ""
echo -e "${YELLOW}Manual commands:${NC}"
echo "• Run backup now: /opt/friendbet/deploy/backup.sh"
echo "• Check health: /opt/friendbet/deploy/health-check.sh"
echo "• View cron jobs: crontab -l (as root)"