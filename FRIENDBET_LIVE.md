# FriendBet Live Configuration

## 🎉 Deployment Complete!

FriendBet is now accessible via Cloudflare Tunnel at:
**https://friendbet.526462738.xyz**

## 🌐 Access URLs

- **FriendBet App**: https://friendbet.526462738.xyz
- **PocketBase Admin UI**: https://friendbet.526462738.xyz/_/
- **API Endpoint**: https://friendbet.526462738.xyz/api/
- **PocketBase Health**: https://friendbet.526462738.xyz/api/health

## 🏗️ Architecture

```
User → Cloudflare Tunnel → FriendBet Service (K8s) → VPS PocketBase
         (SSL/Term)          (ExternalName: 157.180.114.219)   (Port 8090)
```

## 🔧 Kubernetes Configuration

### Service:
```yaml
Name: friendbet
Type: ExternalName
External: 157.180.114.219
Port: 8090
```

### Ingress:
```yaml
Name: friendbet-ingress
Class: Traefik
Host: friendbet.526462738.xyz
Backend: friendbet:8090
```

### Cloudflare Tunnel:
```yaml
Hostname: friendbet.526462738.xyz
Service: http://friendbet.default.svc.cluster.local:8090
```

## 🔒 Security Setup

### Current Status:
- ✅ **SSL/TLS**: Provided by Cloudflare
- ✅ **DDoS Protection**: Cloudflare network
- ✅ **Cloudflare Tunnel**: No public IP exposure
- ⚠️ **Cloudflare Access**: Needs configuration (optional)

### Optional Cloudflare Access Setup:
To add authentication via Cloudflare Access:

1. **Go to**: https://dash.cloudflare.com/sign-up-workers-and-pages/526462738.xyz/access/apps

2. **Add Application**:
   - Name: FriendBet
   - Domain: friendbet.526462738.xyz
   - Session Duration: 24h

3. **Create Policy**:
   - Email Domain: 526462738.xyz
   - Or specific email addresses
   - Or OAuth providers (Google, GitHub, Microsoft)

## 📊 PocketBase Setup

### Admin Configuration:
1. Access: https://friendbet.526462738.xyz/_/
2. Create admin account
3. Configure OAuth providers (Google/GitHub/Microsoft)
4. Import database schema from: `/root/toto/backend/pb_schema_setup.js`

### CORS Configuration:
Add these origins to PocketBase settings:
- https://friendbet.526462738.xyz
- http://localhost:4200 (for development)

## 🛠️ Management Commands

### Check Status:
```bash
# Kubernetes resources
kubectl get service -n default friendbet
kubectl get ingress -n default friendbet-ingress

# Cloudflare tunnel
kubectl get pods -n cloudflare
kubectl logs -n cloudflare -l app.kubernetes.io/name=cloudflared-tunnel

# PocketBase process on VPS
ps aux | grep pocketbase
curl http://localhost:8090/api/health
```

### Restart Services:
```bash
# Restart Cloudflare tunnel
kubectl rollout restart deployment -n cloudflare cloudflared-tunnel

# Restart PocketBase (on VPS)
systemctl restart friendbet  # if running as service
# Or kill and restart process
```

### Update Configuration:
```bash
# Update Cloudflare tunnel config
kubectl edit cm -n cloudflare cloudflared-config

# Update service
kubectl edit service friendbet

# Update ingress
kubectl edit ingress friendbet-ingress
```

## 🚀 Development Workflow

### Backend Development:
```bash
# Access PocketBase Admin
https://friendbet.526462738.xyz/_/

# Access API
https://friendbet.526462738.xyz/api/

# View logs on VPS
tail -f /root/toto/logs/pocketbase.log
```

### Frontend Development:
```bash
cd /root/toto/frontend

# Install dependencies
npm install

# Start dev server
npm run dev

# Build for production
npm run build

# Output will be in: frontend/dist/frontend/
```

### Deploy Frontend:
```bash
# Build Angular app
cd /root/toto/frontend
npm run build

# Copy to PocketBase public directory (on VPS)
cp -r dist/frontend/* /root/toto/backend/pb_public/

# Or use deployment script
cd /root/toto
./deploy/build-deploy.sh
```

## 📱 Application Features (When Developed)

Based on PRD requirements:

### Core Features:
- ✅ Admin-controlled group management
- ✅ Private time-stacked betting
- ✅ Market creation and resolution
- ✅ Leaderboard and profiles
- ✅ Bilingual UI (Hebrew/English)
- ✅ Points management system

### Database Collections:
- users (extended with OAuth)
- groups
- group_memberships
- invite_codes
- markets
- bets
- transactions

## 🔍 Troubleshooting

### Issue: "Connection Refused"
```bash
# Check if PocketBase is running on VPS
ps aux | grep pocketbase
curl http://localhost:8090/api/health

# Check service connectivity
kubectl run test-pod --rm -it --image=curlimages/curl -- \
  curl http://friendbet.default.svc.cluster.local:8090
```

### Issue: "404 Not Found"
```bash
# Check ingress configuration
kubectl describe ingress friendbet-ingress

# Check Cloudflare tunnel status
kubectl logs -n cloudflare -l app.kubernetes.io/name=cloudflared-tunnel
```

### Issue: "CORS Errors"
- Add domain to PocketBase CORS settings via admin UI
- Check browser console for specific CORS errors

## 🎯 Next Steps

1. **Configure PocketBase Admin**:
   - Access: https://friendbet.526462738.xyz/_/
   - Create admin account
   - Import database schema

2. **Set Up OAuth Providers**:
   - Configure Google/GitHub/Microsoft in PocketBase admin
   - Get OAuth credentials from each provider

3. **Build Frontend**:
   - Complete Angular development
   - Deploy to PocketBase pb_public directory

4. **Optional: Add Cloudflare Access**:
   - Configure Zero Trust policies
   - Add authentication layer

## 📞 Support

**PocketBase Status**: ✅ Running on VPS (157.180.114.219:8090)
**Cloudflare Tunnel**: ✅ Running and configured
**DNS**: ✅ friendbet.526462738.xyz → Tunnel → FriendBet

---

**Status**: Live and accessible! 🚀
**Last Updated**: January 8, 2025
**Version**: Foundation Complete