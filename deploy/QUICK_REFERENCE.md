# FriendBet Deployment Quick Reference

## Essential Commands

### Setup
```bash
# Complete initial setup
sudo ./deploy/quick-start.sh

# Manual PocketBase setup only
sudo ./deploy/setup-pocketbase.sh
```

### Deployment
```bash
# Build and deploy frontend
sudo ./deploy/build-deploy.sh

# Quick status check
sudo systemctl status friendbet
```

### Backup & Restore
```bash
# Manual backup
sudo /opt/friendbet/deploy/backup.sh

# Restore from backup
sudo /opt/friendbet/deploy/restore.sh friendbet_backup_20240108.zip

# List backups
ls -lh /opt/friendbet/backups/
```

### Monitoring
```bash
# Monitoring dashboard
sudo /opt/friendbet/deploy/monitoring.sh

# Live logs
sudo journalctl -u friendbet -f

# Service status
sudo systemctl status friendbet
```

### Service Management
```bash
# Start
sudo systemctl start friendbet

# Stop
sudo systemctl stop friendbet

# Restart
sudo systemctl restart friendbet

# Enable at boot
sudo systemctl enable friendbet
```

## Important URLs

- **Admin UI**: `http://localhost:8090/_/`
- **API**: `http://localhost:8090/api/`
- **Health Check**: `http://localhost:8090/api/health`

## File Locations

- **Installation**: `/opt/friendbet/`
- **Database**: `/opt/friendbet/pb_data/data.db`
- **Static Files**: `/opt/friendbet/pb_public/`
- **Backups**: `/opt/friendbet/backups/`
- **Service**: `/etc/systemd/system/friendbet.service`
- **Logs**: `journalctl -u friendbet`

## Troubleshooting

### Service won't start
```bash
# Check error logs
sudo journalctl -u friendbet -n 50

# Check if port is in use
sudo netstat -tulpn | grep 8090

# Check file permissions
ls -la /opt/friendbet
```

### Database locked
```bash
# Stop service
sudo systemctl stop friendbet

# Remove lock files
sudo rm /opt/friendbet/pb_data/data.db-shm
sudo rm /opt/friendbet/pb_data/data.db-wal

# Restart
sudo systemctl start friendbet
```

### Can't access admin UI
```bash
# Check service running
sudo systemctl status friendbet

# Check Cloudflare Tunnel routing
# Check firewall
sudo ufw status

# Check logs
sudo journalctl -u friendbet -f
```

## Automated Tasks

### Daily Backup (2 AM)
- Script: `/etc/cron.d/friendbet-backup`
- Logs: `/var/log/friendbet-backup.log`

### Health Checks (Every 5 min)
- Script: `/etc/cron.d/friendbet-health`
- Logs: `/var/log/friendbet-health.log`

### Weekly Cleanup (Sunday 3 AM)
- Script: `/etc/cron.d/friendbet-cleanup`
- Removes logs older than 30 days

## Next Steps After Setup

1. **Configure Admin UI**: `http://localhost:8090/_/`
2. **Set up OAuth**: Get credentials from Google/GitHub/Microsoft
3. **Create Collections**: Follow database schema in PRD
4. **Configure Tunnel**: Add to existing Cloudflare Tunnel
5. **Deploy Frontend**: `sudo ./deploy/build-deploy.sh`
6. **Test Everything**: OAuth login, betting, real-time updates

## Performance Tuning

```bash
# Check resource usage
sudo /opt/friendbet/deploy/monitoring.sh

# Optimize database (run occasionally)
sqlite3 /opt/friendbet/pb_data/data.db "VACUUM;"

# View detailed stats
sqlite3 /opt/friendbet/pb_data/data.db "SELECT COUNT(*) FROM markets;"
```

## Security Checklist

- ✅ Service runs as dedicated user (friendbet)
- ✅ No external ports needed (Cloudflare Tunnel)
- ✅ OAuth-only authentication
- ✅ Automated daily backups
- ✅ Systemd security hardening enabled
- ✅ HTTPS via Cloudflare Tunnel
- ✅ Optional Cloudflare Access for additional auth

## Support

- **PocketBase Docs**: https://pocketbase.io/docs/
- **Deployment Guide**: `deploy/README.md`
- **Full Summary**: `DEPLOYMENT_SUMMARY.md`
- **Project Tasks**: `todo.md`

## Typical Workflow

```bash
# Day 1: Initial setup
sudo ./deploy/quick-start.sh
# Configure admin UI, OAuth, collections

# Day 2: Configure tunnel, test external access
# Add FriendBet to Cloudflare Tunnel

# Day 3: Deploy frontend (after development)
sudo ./deploy/build-deploy.sh

# Ongoing: Monitor and maintain
sudo /opt/friendbet/deploy/monitoring.sh
sudo journalctl -u friendbet -f
```