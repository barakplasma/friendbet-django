# Cloudflare Access Setup Guide for FriendBet

## 🚀 Quick Setup (5 minutes)

### Option 1: Automated Deployment ⚡

```bash
# 1. Edit the configuration
cd /root/toto/deploy
nano deploy-cloudflare-access.sh

# 2. Update these values:
#    DOMAIN="friendbet.yourdomain.com"
#    VPS_IP="your.vps.ip.address"

# 3. Deploy to Kubernetes
./deploy-cloudflare-access.sh
```

### Option 2: Manual Deployment

#### Step 1: Create Kubernetes Service

```bash
# Edit the service file
cd /root/toto/deploy
nano k8s-friendbet-service.yaml

# Update: externalName: "YOUR-VPS-IP-OR-HOSTNAME"

# Apply to cluster
kubectl apply -f k8s-friendbet-service.yaml
```

#### Step 2: Configure Cloudflare Access Policy

1. **Go to Cloudflare Dashboard**: https://dash.cloudflare.com/

2. **Navigate to**: Zero Trust > Access > Applications

3. **Click**: "Add an application"

4. **Configure Application**:
   ```
   Application Name: FriendBet
   Session Duration: 24h
   Type: Self-hosted
   
   Path: https://friendbet.yourdomain.com/*
   ```

5. **Add Policy** (choose one):
   - **Email Domain**: `@yourdomain.com`
   - **Email Addresses**: `user1@yourdomain.com, user2@yourdomain.com`
   - **Social Login**: Google, GitHub, Microsoft, etc.

6. **Configure Authentication**:
   - One-Time PIN (recommended)
   - Hardware Key (YubiKey)
   - Mobile app authenticator

#### Step 3: Update PocketBase CORS

1. **Access PocketBase Admin**: https://friendbet.yourdomain.com/_/

2. **Navigate to**: Settings > CORS

3. **Add origins**:
   ```
   https://friendbet.yourdomain.com
   http://localhost:4200  (for development)
   ```

## 🔧 Configuration Files

### Files Created:
- ✅ `deploy/deploy-cloudflare-access.sh` - Automated deployment script
- ✅ `deploy/cloudflare-access-config.sh` - Setup guide and examples
- ✅ `deploy/k8s-friendbet-service.yaml` - K8s service and ingress definitions

### Architecture:
```
User → Cloudflare Access → Cloudflare Tunnel (K8s) → FriendBet Service → VPS (PocketBase)
         (Authentication)        (Your existing)     (ExternalName)     (Backend)
```

## 🎯 Access URLs

After setup:
- **FriendBet App**: https://friendbet.yourdomain.com
- **PocketBase Admin**: https://friendbet.yourdomain.com/_/
- **API Endpoint**: https://friendbet.yourdomain.com/api/

## 🔒 Security Features

Cloudflare Access provides:
- ✅ **Authentication**: Required before reaching your app
- ✅ **Identity Provider**: Google, Microsoft, GitHub, or email-based
- ✅ **Device Posture**: Check device compliance (optional)
- ✅ **Geo-fencing**: Restrict by country (optional)
- ✅ **Logging**: All access attempts logged in Cloudflare
- ✅ **DDoS Protection**: Cloudflare's network protection

## 🛠️ Troubleshooting

### Issue: "Connection Refused"
```bash
# Check if PocketBase is running on VPS
curl http://localhost:8090/api/health

# Check Kubernetes service
kubectl get service friendbet
kubectl describe service friendbet

# Check ingress
kubectl get ingress friendbet-ingress
kubectl describe ingress friendbet-ingress
```

### Issue: "401 Unauthorized" from Cloudflare
- Check Cloudflare Access policy configuration
- Verify you're included in the policy (email address/domain)
- Try accessing in incognito mode

### Issue: "CORS Errors"
- Add your domain to PocketBase CORS settings
- Check browser console for specific CORS errors
- Verify PocketBase ORIGIN_WHITELIST includes your domain

### Issue: "Service Not Found"
```bash
# Verify service exists
kubectl get service friendbet

# Check external name is correct
kubectl get service friendbet -o yaml

# Test connectivity from cluster
kubectl run test-pod --rm -it --image=curlimages/curl -- curl http://friendbet:8090
```

## 📊 Monitoring

### Check Cloudflare Access Logs:
1. Go to: Zero Trust > Logs > Activity
2. Filter by: FriendBet application
3. See: Who accessed, when, from where

### Kubernetes Monitoring:
```bash
# Service status
kubectl get service friendbet

# Ingress status  
kubectl get ingress friendbet-ingress

# Events
kubectl get events --sort-by='.lastTimestamp'
```

### PocketBase Logs:
```bash
# On VPS
ssh user@vps
journalctl -u friendbet -f

# Or check logs directory
tail -f /opt/friendbet/logs/pocketbase.log
```

## 🔄 Updates

### To Update Domain or IP:
```bash
# Edit service
kubectl edit service friendbet

# Or update YAML and reapply
nano k8s-friendbet-service.yaml
kubectl apply -f k8s-friendbet-service.yaml
```

### To Update Cloudflare Access Policy:
1. Go to: Zero Trust > Access > Applications
2. Find: FriendBet application
3. Edit: Policy configuration

### To Remove Cloudflare Access:
```bash
kubectl delete service friendbet
kubectl delete ingress friendbet-ingress

# Then update PocketBase to be accessible directly
```

## 🎉 Benefits of This Setup

1. **Zero Trust Security**: Only authorized users can access FriendBet
2. **No VPN Needed**: Access securely from anywhere
3. **Single Sign-On**: Use existing Google/Microsoft/GitHub accounts
4. **DDoS Protection**: Cloudflare's global network
5. **SSL/TLS**: Automatic HTTPS
6. **No Public IP Required**: VPS can be behind firewall
7. **Centralized Access Control**: Manage all your apps in one place
8. **Audit Trail**: Complete access logs in Cloudflare

## 📝 Example Cloudflare Access Policies

### Policy 1: Email Domain (Recommended)
```yaml
Policy Name: Organization Members
Action: Allow
Condition:
  - Email Domain: yourdomain.com
```

### Policy 2: Specific Emails
```yaml
Policy Name: FriendBet Users  
Action: Allow
Condition:
  - Email: user1@yourdomain.com
  - Email: user2@yourdomain.com
  - Email: user3@yourdomain.com
```

### Policy 3: Social Login
```yaml
Policy Name: Social Login Users
Action: Allow
Condition:
  - Identity Provider: Google
    Email: @yourdomain.com
```

### Policy 4: Multi-Factor
```yaml
Policy Name: High Security
Action: Allow
Condition:
  - Email Domain: yourdomain.com
  - And: Require HardWare Key (YubiKey)
```

---

**Status**: Ready to deploy! 🚀
**Estimated Time**: 5 minutes
**Difficulty**: Easy ⭐

This setup leverages your existing K8s Cloudflare Tunnel infrastructure while keeping PocketBase on your VPS for simplicity.