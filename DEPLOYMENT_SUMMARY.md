# FriendBet Deployment Architecture Summary

## Executive Summary

I've designed a **hybrid deployment architecture** for FriendBet that leverages your existing infrastructure (Kubernetes + Cloudflare Tunnel + systemctl services) while maintaining the project's simplicity goals.

**Recommended Approach:**
- **PocketBase**: Deploy as systemctl service (like your Miniflux setup)
- **Frontend**: Build Angular static files, serve via PocketBase
- **Ingress**: Use existing Cloudflare Tunnel (no Nginx needed)
- **Backups**: Automated local backups + optional cloud sync

This is **simpler than Kubernetes** for a single binary while still fitting your infrastructure patterns.

## Why This Architecture?

| Consideration | Decision | Rationale |
|---------------|----------|-----------|
| **Complexity** | systemctl service | Like Miniflux, simpler than K8s for single binary |
| **Ingress** | Cloudflare Tunnel | Leverages existing setup, handles SSL/TLS |
| **Database** | SQLite (embedded) | Single file backup, no separate DB server |
| **Static Files** | PocketBase built-in | No need for Nginx or separate web server |
| **OAuth** | PocketBase built-in | No need for separate auth service |
| **Backups** | File copy + cron | Simple, reliable, easy to restore |

## Deployment Scripts Created

All scripts are in `/root/toto/deploy/` and are executable:

### 1. **setup-pocketbase.sh** - Initial PocketBase Installation
```bash
sudo ./deploy/setup-pocketbase.sh
```
**What it does:**
- Downloads PocketBase binary
- Creates dedicated user (`friendbet`)
- Sets up directory structure at `/opt/friendbet`
- Creates systemd service
- Starts service on port 8090
- Enables auto-start on boot

**Output:**
- PocketBase Admin UI: `http://localhost:8090/_/`
- API endpoint: `http://localhost:8090/`

### 2. **quick-start.sh** - Complete Backend Setup
```bash
sudo ./deploy/quick-start.sh
```
**What it does:**
- Runs all setup steps in sequence
- Installs dependencies
- Sets up PocketBase
- Configures automated backups
- Tests service health
- Provides next steps

**Time:** ~5 minutes on fresh VPS

### 3. **build-deploy.sh** - Frontend Deployment
```bash
sudo ./deploy/build-deploy.sh
```
**What it does:**
- Installs frontend dependencies
- Builds English version
- Builds Hebrew version
- Deploys to `/opt/friendbet/pb_public/`
- Creates backup of current deployment
- Restarts service
- Verifies deployment
- Auto-rollback on failure

**Safety:** Backs up current deployment before updating

### 4. **backup.sh** - Manual Backup
```bash
sudo /opt/friendbet/deploy/backup.sh
```
**What it does:**
- Stops service briefly for consistent backup
- Creates PocketBase backup (SQLite + uploads)
- Creates timestamped backup file
- Cleans old backups (>30 days)
- Optionally syncs to cloud storage (rclone)

**Backup location:** `/opt/friendbet/backups/`

### 5. **restore.sh** - Restore from Backup
```bash
sudo /opt/friendbet/deploy/restore.sh <backup-file.zip>
```
**What it does:**
- Stops service
- **Backs up current data first** (safety)
- Restores from selected backup
- Starts service
- Verifies service health

**Safety:** Always backs up current data before restore

### 6. **setup-cron.sh** - Automated Maintenance
```bash
sudo ./deploy/setup-cron.sh
```
**What it does:**
- Configures daily backups (2 AM)
- Sets up health checks (every 5 minutes)
- Configures log rotation
- Sets up weekly cleanup (Sundays 3 AM)
- Creates maintenance log files

**Cron jobs created:**
- `/etc/cron.d/friendbet-backup` - Daily backups
- `/etc/cron.d/friendbet-health` - Health checks
- `/etc/cron.d/friendbet-cleanup` - Log cleanup
- `/etc/logrotate.d/friendbet` - Log rotation

### 7. **monitoring.sh** - Monitoring Dashboard
```bash
sudo /opt/friendbet/deploy/monitoring.sh

# Or continuous monitoring:
watch -n 5 sudo /opt/friendbet/deploy/monitoring.sh
```
**What it shows:**
- Service status and uptime
- CPU and memory usage
- Disk usage
- Database statistics
- Backup status
- Recent logs
- Health check results
- Recent errors

### 8. **health-check.sh** - Health Monitoring
**What it does:**
- Checks if service is running
- Attempts restart if failed
- Checks API responsiveness
- Logs all checks
- Sends alerts (if configured)

**Runs:** Every 5 minutes via cron

## File Structure

```
/root/toto/
├── deploy/
│   ├── setup-pocketbase.sh      # Initial PocketBase setup
│   ├── quick-start.sh            # Complete backend setup
│   ├── build-deploy.sh           # Frontend deployment
│   ├── backup.sh                 # Manual backup
│   ├── restore.sh                # Restore from backup
│   ├── setup-cron.sh             # Automated maintenance
│   ├── monitoring.sh             # Monitoring dashboard
│   ├── health-check.sh           # Health monitoring
│   ├── cloudflare-tunnel.yaml    # Tunnel configuration
│   └── README.md                 # Detailed deployment guide
├── frontend/                     # Angular frontend (to be created)
│   └── (Angular project files)
└── DEPLOYMENT_SUMMARY.md         # This file

/opt/friendbet/                   # Installation directory
├── pocketbase                    # PocketBase binary
├── pb_data/
│   └── data.db                   # SQLite database (single file!)
├── pb_public/                    # Angular static files
│   ├── index.html
│   ├── assets/
│   └── ...
├── backups/                      # Automated backups
│   ├── friendbet_backup_20240108.zip
│   └── ...
└── deploy/                       # Production scripts
    └── (copy of /root/toto/deploy scripts)
```

## Deployment Workflow

### Initial Setup (One-time)

```bash
# 1. Clone repository to VPS
cd /root/toto

# 2. Run quick start (installs everything)
sudo ./deploy/quick-start.sh

# 3. Configure PocketBase admin
# Open http://localhost:8090/_/ in browser
# - Create admin account
# - Configure OAuth providers

# 4. Set up database collections via admin UI
# (Follow schema in PRD)

# 5. Configure Cloudflare Tunnel
# Add ingress rule to existing tunnel:
cat deploy/cloudflare-tunnel.yaml

# 6. Test external access
# Open https://friendbet.yourdomain.com
```

**Time:** 15-30 minutes

### Frontend Deployment (After Development)

```bash
# From project root on VPS
cd /root/toto

# Build and deploy Angular app
sudo ./deploy/build-deploy.sh
```

**Time:** 3-5 minutes

### Updating Application

```bash
# 1. Update frontend code
git pull

# 2. Build and deploy
sudo ./deploy/build-deploy.sh
```

### Maintenance

```bash
# View service status
sudo systemctl status friendbet

# View logs
sudo journalctl -u friendbet -f

# Manual backup
sudo /opt/friendbet/deploy/backup.sh

# Monitoring dashboard
sudo /opt/friendbet/deploy/monitoring.sh
```

## Integration with Existing Infrastructure

### Cloudflare Tunnel (K8s)

Your existing Cloudflare Tunnel setup handles ingress. Just add:

```yaml
# Add to your tunnel's config.yml
ingress:
  - hostname: friendbet.yourdomain.com
    service: http://localhost:8090
```

**No need for:**
- Nginx reverse proxy
- SSL certificates (handled by Cloudflare)
- Firewall rules for ports 80/443 (Cloudflare Tunnel)

### Systemd Services

FriendBet follows your Miniflux pattern:
- Single binary as systemctl service
- Automatic restart on failure
- Journal logging
- Dedicated user account

### Monitoring

Use existing monitoring tools or the provided scripts:
- `journalctl` for logs
- `monitoring.sh` for quick overview
- Health checks via cron

## Security Features

1. **Dedicated user**: `friendbet` user with limited permissions
2. **Systemd security**: `NoNewPrivileges`, `PrivateTmp`, `ProtectSystem`
3. **Cloudflare Access**: Optional additional auth layer
4. **OAuth only**: No password authentication
5. **HTTPS**: SSL/TLS via Cloudflare Tunnel
6. **Firewall**: Only SSH needed (Cloudflare Tunnel for HTTP)
7. **Automated backups**: Daily, 30-day retention
8. **Regular updates**: PocketBase single binary updates

## Backup & Restore Strategy

### Backup Strategy

- **Frequency**: Daily (2 AM) via cron
- **Retention**: 30 days locally
- **Location**: `/opt/friendbet/backups/`
- **Optional**: Cloud sync via rclone

### Backup Contents

Each backup includes:
- SQLite database (`data.db`)
- User uploads (avatars)
- PocketBase configuration

### Restore Procedure

```bash
# List available backups
ls -lh /opt/friendbet/backups/

# Restore from backup
sudo /opt/friendbet/deploy/restore.sh friendbet_backup_20240108_120000.zip
```

**Restore includes:**
- Automatic pre-restore backup (safety)
- Service restart
- Health verification

## Disaster Recovery

### Quick Recovery (Service Issue)
```bash
sudo systemctl restart friendbet
```

### Full Recovery (Data Corruption)
```bash
# 1. Stop service
sudo systemctl stop friendbet

# 2. Restore from latest backup
sudo /opt/friendbet/deploy/restore.sh friendbet_backup_YYYYMMDD.zip

# 3. Verify
sudo systemctl status friendbet
```

### Worst Case (Complete VPS Failure)
```bash
# 1. Provision new VPS
# 2. Run quick-start.sh
# 3. Stop service
sudo systemctl stop friendbet
# 4. Copy backup from off-site storage
# 5. Restore
sudo /opt/friendbet/deploy/restore.sh backup.zip
```

## Performance Considerations

### Expected Resource Usage

- **RAM**: 50-150 MB (PocketBase + SQLite)
- **CPU**: <5% idle, up to 20% during busy periods
- **Disk**: 10-50 MB for database (depends on usage)
- **Network**: Minimal (API calls + real-time updates)

### Scaling Capacity

**Comfortable for:**
- 5-20 active users
- 10-50 concurrent markets
- Hundreds of bets per day

**Beyond this:**
- Consider PostgreSQL instead of SQLite
- Add Redis caching
- Separate application and database servers

## Cost Estimate

### VPS Requirements

- **RAM**: 1GB minimum, 2GB recommended
- **CPU**: 1 vCPU minimum, 2 vCPU recommended
- **Storage**: 20GB SSD
- **Cost**: $5-10/month (DigitalOcean, Linode, Hetzner)

### Additional Costs

- **Domain**: $10-15/year (if not already owned)
- **Cloudflare**: Free tier sufficient
- **Total**: ~$5-10/month

## Next Steps

### Immediate

1. **Review deployment scripts**: `cat deploy/README.md`
2. **Test on development VPS**: `sudo ./deploy/quick-start.sh`
3. **Configure OAuth providers**: Get credentials for Google/GitHub/Microsoft
4. **Set up database schema**: Create collections via admin UI

### Development

1. **Set up Angular project**: Follow Phase 0 in todo.md
2. **Implement backend logic**: Follow Phase 1 in todo.md
3. **Build frontend components**: Follow Phases 2-7 in todo.md
4. **Test deployment**: Use `build-deploy.sh`

### Production

1. **Configure DNS**: Add friendbet subdomain to Cloudflare
2. **Update tunnel**: Add FriendBet ingress rule
3. **Set up Cloudflare Access**: Restrict access to authorized users
4. **Deploy production build**: `sudo ./deploy/build-deploy.sh`
5. **Configure monitoring**: `watch -n 5 /opt/friendbet/deploy/monitoring.sh`
6. **Test with real users**: Gather feedback

## Advantages Over Alternatives

### vs. Full Kubernetes Deployment

| Aspect | K8s Deployment | This Approach |
|--------|----------------|---------------|
| Complexity | High (pods, services, ingress) | Low (single service) |
| Setup time | 1-2 hours | 15 minutes |
| Maintenance | High | Low |
| Scalability | Excellent | Good for target use case |
| Monitoring | K8s tools needed | Standard Linux tools |
| Cost | Higher | Lower |

### vs. Docker Containers

| Aspect | Docker | This Approach |
|--------|--------|---------------|
| Overhead | Additional layer | None |
| Complexity | Medium | Low |
| Updates | Rebuild image | Replace binary |
| Backups | Volume mounts | File copy |
| Debugging | Docker commands | Direct access |

### vs. Traditional Nginx + PostgreSQL

| Aspect | Traditional | This Approach |
|--------|-------------|---------------|
| Components | 3+ (Nginx, App, DB) | 1 (PocketBase) |
| Setup complexity | High | Low |
| Backup complexity | High (DB dumps) | Low (file copy) |
| SSL/TLS | Certbot needed | Handled by Cloudflare |
| Maintenance | High | Low |

## Conclusion

This deployment architecture:

✅ **Leverages your existing infrastructure** (K8s Cloudflare Tunnel)
✅ **Follows your patterns** (systemctl services like Miniflux)
✅ **Maintains simplicity** (single binary, no Docker/K8s complexity)
✅ **Production-ready** (automated backups, monitoring, security)
✅ **Easy to maintain** (standard Linux tools, clear procedures)
✅ **Cost-effective** ($5-10/month VPS)
✅ **Scalable enough** for friend group use case

**Bottom line:** This is the **simplest self-hosting approach** that still integrates with your existing infrastructure while meeting all FriendBet requirements.

## Questions?

Review the detailed documentation:
- `deploy/README.md` - Complete deployment guide
- `todo.md` - Development task breakdown
- `CLAUDE.md` - Product requirements

Or run the monitoring dashboard to see system health:
```bash
sudo /opt/friendbet/deploy/monitoring.sh
```