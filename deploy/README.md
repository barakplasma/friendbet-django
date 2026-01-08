# FriendBet Deployment Guide

Complete deployment guide for FriendBet on your existing infrastructure (Kubernetes + Cloudflare Tunnel + systemctl services).

## Architecture Overview

```
FriendBet Deployment Architecture:
┌─────────────────────────────────────────────────────────────┐
│                    Cloudflare DNS                          │
│                 friendbet.yourdomain.com                   │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              Cloudflare Tunnel (K8s)                        │
│           Your existing tunnel setup                        │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              VPS (Ubuntu/Debian)                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  FriendBet Service (systemctl)                       │  │
│  │  ├─ PocketBase Binary (port 8090)                   │  │
│  │  ├─ SQLite Database (/opt/friendbet/pb_data)        │  │
│  │  └─ Angular Static Files (/opt/friendbet/pb_public) │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Automated Backups: /opt/friendbet/backups                  │
│  Maintenance Scripts: /opt/friendbet/deploy/                │
└─────────────────────────────────────────────────────────────┘
```

## Why This Architecture?

- **PocketBase as systemctl service**: Like your Miniflux setup, simpler than K8s for a single binary
- **No Nginx needed**: Cloudflare Tunnel handles SSL/TLS termination
- **SQLite embedded**: Single file database, easy backup/restore
- **Angular static files**: Served directly by PocketBase (built-in static file server)
- **Existing infrastructure**: Leverages your K8s Cloudflare Tunnel setup

## Prerequisites

- Ubuntu/Debian VPS with sudo access
- Existing Kubernetes cluster with Cloudflare Tunnel
- Domain configured in Cloudflare
- Basic familiarity with command line

## Deployment Steps

### 1. Initial Setup (15 minutes)

```bash
# Make scripts executable
chmod +x deploy/*.sh

# Run PocketBase setup
sudo ./deploy/setup-pocketbase.sh
```

This will:
- Download and install PocketBase
- Create dedicated user (friendbet)
- Set up systemd service
- Start service on port 8090
- Create directory structure at `/opt/friendbet`

### 2. Configure PocketBase Admin

1. Access admin UI: `http://localhost:8090/_/` (or via your VPS IP)
2. Create admin account
3. Configure OAuth providers (Google/GitHub/Microsoft)
4. Set up collections (use provided schema)

### 3. Build and Deploy Frontend

```bash
# From project root directory
sudo ./deploy/build-deploy.sh
```

This will:
- Install frontend dependencies
- Build English and Hebrew versions
- Deploy to PocketBase static file directory
- Restart service
- Verify deployment

### 4. Configure Cloudflare Tunnel

Add to your existing Cloudflare Tunnel configuration:

```yaml
# Add to your tunnel's config.yml
ingress:
  - hostname: friendbet.yourdomain.com
    service: http://localhost:8090
```

Or use the CLI:
```bash
cloudflare tunnel route dns <tunnel-id> friendbet.yourdomain.com
```

### 5. Set Up Automated Backups

```bash
sudo ./deploy/setup-cron.sh
```

This configures:
- Daily backups at 2 AM
- Health checks every 5 minutes
- Automatic log rotation
- Weekly cleanup of old backups

### 6. Configure Cloudflare Access (Recommended)

1. Go to Cloudflare Dashboard → Zero Trust → Access → Applications
2. Add new application:
   - Application: `friendbet.yourdomain.com/*`
   - Session duration: 24h
3. Add policy:
   - Include: Email domain `yourdomain.com`
   - OR: Specific emails
   - OR: Social login (Google, GitHub, etc.)

This adds an extra authentication layer on top of OAuth.

## File Structure

```
/opt/friendbet/
├── pocketbase                 # PocketBase binary
├── pb_data/
│   └── data.db               # SQLite database (single file!)
├── pb_public/                # Angular static files
│   ├── index.html
│   ├── assets/
│   └── ...
├── backups/                  # Automated backups
│   ├── friendbet_backup_20240108.zip
│   └── ...
└── deploy/                   # Deployment scripts
    ├── setup-pocketbase.sh
    ├── backup.sh
    ├── restore.sh
    ├── build-deploy.sh
    ├── health-check.sh
    ├── monitoring.sh
    └── setup-cron.sh
```

## Common Operations

### View Service Status
```bash
sudo systemctl status friendbet
```

### View Logs
```bash
# Live logs
sudo journalctl -u friendbet -f

# Last 100 lines
sudo journalctl -u friendbet -n 100

# Last 24 hours
sudo journalctl -u friendbet -since "24 hours ago"
```

### Manual Backup
```bash
sudo /opt/friendbet/deploy/backup.sh
```

### Restore from Backup
```bash
sudo /opt/friendbet/deploy/restore.sh friendbet_backup_20240108_120000.zip
```

### Monitoring Dashboard
```bash
sudo /opt/friendbet/deploy/monitoring.sh

# Or watch continuously
watch -n 5 sudo /opt/friendbet/deploy/monitoring.sh
```

### Deploy Frontend Update
```bash
sudo ./deploy/build-deploy.sh
```

### Restart Service
```bash
sudo systemctl restart friendbet
```

### Update PocketBase
```bash
# Stop service
sudo systemctl stop friendbet

# Download new version
cd /tmp
wget https://github.com/pocketbase/pocketbase/releases/download/v0.x.x/pocketbase_linux_amd64.zip
unzip pocketbase_linux_amd64.zip

# Replace binary (keep data!)
sudo cp pocketbase /opt/friendbet/
sudo chmod +x /opt/friendbet/pocketbase

# Start service
sudo systemctl start friendbet
```

## Backup & Restore

### Backup Strategy

1. **Automated Daily Backups**: Run at 2 AM via cron
2. **Retention**: Keep last 30 days locally
3. **Optional Cloud Sync**: Configure rclone in `backup.sh` for cloud storage
4. **Pre-deployment Backups**: Automatic before each deployment

### Backup File Contents

Each backup includes:
- SQLite database (`data.db`)
- User uploads (avatars, etc.)
- PocketBase settings and configuration

### Restore Procedure

1. Stop service: `sudo systemctl stop friendbet`
2. Run restore script: `sudo /opt/friendbet/deploy/restore.sh <backup-file.zip>`
3. Verify service started: `sudo systemctl status friendbet`

The restore script automatically:
- Backs up current data (safety measure)
- Restores from backup
- Restarts service
- Verifies service health

## Troubleshooting

### Service Won't Start

```bash
# Check error logs
sudo journalctl -u friendbet -n 50

# Check if port is already in use
sudo netstat -tulpn | grep 8090

# Check file permissions
ls -la /opt/friendbet
```

### Database Locked

```bash
# Stop service
sudo systemctl stop friendbet

# Check for lock files
ls -la /opt/friendbet/pb_data/

# Remove lock file if exists
sudo rm /opt/friendbet/pb_data/data.db-shm
sudo rm /opt/friendbet/pb_data/data.db-wal

# Restart service
sudo systemctl start friendbet
```

### Can't Access Admin UI

1. Check service is running: `sudo systemctl status friendbet`
2. Check firewall: `sudo ufw status`
3. Check Cloudflare Tunnel is routing correctly
4. Check Cloudflare Access policy (if configured)

### Frontend Not Loading

```bash
# Check static files exist
ls -la /opt/friendbet/pb_public/

# Check file permissions
sudo chown -R friendbet:friendbet /opt/friendbet/pb_public/

# Rebuild and redeploy
sudo ./deploy/build-deploy.sh
```

### High Memory Usage

```bash
# Check memory usage
sudo /opt/friendbet/deploy/monitoring.sh

# Restart service if needed
sudo systemctl restart friendbet
```

## Performance Tuning

### Database Optimization

PocketBase uses SQLite which is already optimized, but you can:

```bash
# Run VACUUM to optimize database
sqlite3 /opt/friendbet/pb_data/data.db "VACUUM;"
```

### Resource Limits

Edit systemd service if needed:

```bash
sudo nano /etc/systemd/system/friendbet.service

# Add resource limits:
[Service]
MemoryLimit=512M
CPUQuota=50%

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart friendbet
```

## Security Considerations

1. **OAuth Only**: No email/password authentication (simpler, more secure)
2. **Cloudflare Access**: Additional authentication layer
3. **Firewall**: Only expose ports 80/443 via Cloudflare Tunnel
4. **Systemd Security**: Service runs with limited permissions (NoNewPrivileges, PrivateTmp)
5. **Regular Backups**: Automated daily backups
6. **HTTPS**: SSL/TLS handled by Cloudflare Tunnel
7. **User Isolation**: Dedicated user (friendbet) with minimal permissions

## Monitoring

### Log Locations

- Service logs: `journalctl -u friendbet`
- Backup logs: `/var/log/friendbet-backup.log`
- Health logs: `/var/log/friendbet-health.log`

### Monitoring Dashboard

Run the monitoring script:
```bash
sudo /opt/friendbet/deploy/monitoring.sh
```

This shows:
- Service status
- Resource usage
- Database statistics
- Backup status
- Recent logs
- Health check results

### Alerting

Edit `health-check.sh` to configure email alerts:
```bash
ALERT_EMAIL="your-email@domain.com"
```

Ensure mail service is configured:
```bash
sudo apt install mailutils
```

## Scaling Considerations

For small groups (5-20 users), this single-VPS setup is sufficient.

If you need to scale beyond 100+ users or multiple groups:
1. Consider moving PostgreSQL (instead of SQLite)
2. Add Redis caching
3. Separate application server from database
4. Use nginx load balancer
5. Consider container orchestration

However, for the intended use case (friend groups), this architecture is **more than sufficient**.

## Next Steps

1. **Set up OAuth providers**:
   - Google OAuth: https://console.cloud.google.com/
   - GitHub OAuth: https://github.com/settings/developers
   - Microsoft OAuth: https://portal.azure.com/

2. **Configure collections**:
   - Use the PocketBase admin UI
   - Follow the database schema in the PRD
   - Set up collection rules for privacy

3. **Test with real users**:
   - Deploy to production
   - Invite a few friends
   - Test the complete flow
   - Gather feedback

4. **Monitor and iterate**:
   - Check logs regularly
   - Monitor resource usage
   - Gather user feedback
   - Implement improvements

## Support

For issues or questions:
- Check PocketBase docs: https://pocketbase.io/docs/
- Check Cloudflare Tunnel docs: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- Review logs: `sudo journalctl -u friendbet -f`

## Summary

This deployment architecture:
- ✅ Leverages your existing infrastructure (K8s + Cloudflare)
- ✅ Simple deployment (single systemctl service like Miniflux)
- ✅ No additional cloud services needed
- ✅ Easy backup and restore (single file database)
- ✅ Automated maintenance and monitoring
- ✅ SSL/TLS handled by Cloudflare Tunnel
- ✅ Production-ready for friend group scale