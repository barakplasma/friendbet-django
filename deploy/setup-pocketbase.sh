#!/bin/bash
# FriendBet PocketBase Setup Script
# This script downloads and configures PocketBase for FriendBet

set -e

# Configuration
INSTALL_DIR="/opt/friendbet"
SERVICE_NAME="friendbet"
USER="friendbet"\nPORT="8090"
PB_VERSION="0.34.2" # Check https://github.com/pocketbase/pocketbase/releases for latest

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== FriendBet PocketBase Setup ===${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
	echo -e "${RED}Error: Please run as root${NC}"
	exit 1
fi

# Create dedicated user
echo -e "${YELLOW}Creating system user...${NC}"
if ! id "$USER" &>/dev/null; then
	useradd --system --home-dir "$INSTALL_DIR" --create-home --shell /bin/false "$USER"
	echo -e "${GREEN}User $USER created${NC}"
else
	echo -e "${YELLOW}User $USER already exists${NC}"
fi

# Create installation directory
echo -e "${YELLOW}Creating installation directory...${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/backups"
mkdir -p "$INSTALL_DIR/pb_public"

# Download PocketBase
echo -e "${YELLOW}Downloading PocketBase ${PB_VERSION}...${NC}"
if [ ! -f "$INSTALL_DIR/pocketbase" ]; then
	cd /tmp
	wget -q "https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip"
	unzip -q "pocketbase_${PB_VERSION}_linux_amd64.zip"
	mv pocketbase "$INSTALL_DIR/"
	rm "pocketbase_${PB_VERSION}_linux_amd64.zip"
	chmod +x "$INSTALL_DIR/pocketbase"
	echo -e "${GREEN}PocketBase downloaded and installed${NC}"
else
	echo -e "${YELLOW}PocketBase already installed${NC}"
fi

# Create systemd service
echo -e "${YELLOW}Creating systemd service...${NC}"
cat > "/etc/systemd/system/${SERVICE_NAME}.service" << 'EOF'
[Unit]
Description=FriendBet PocketBase Service
After=network.target

[Service]
Type=simple
User=friendbet
WorkingDirectory=/opt/friendbet
ExecStart=/opt/friendbet/pocketbase serve --http=0.0.0.0:8090
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal
SyslogIdentifier=friendbet

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/friendbet

# Resource limits
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
echo -e "${YELLOW}Reloading systemd...${NC}"
systemctl daemon-reload

# Set permissions
echo -e "${YELLOW}Setting permissions...${NC}"
chown -R $USER:$USER "$INSTALL_DIR"
chmod -R 755 "$INSTALL_DIR"
chmod 644 "/etc/systemd/system/${SERVICE_NAME}.service"

# Start service
echo -e "${YELLOW}Starting FriendBet service...${NC}"
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

# Wait for service to start
sleep 3

# Check service status
if systemctl is-active --quiet "$SERVICE_NAME"; then
	echo -e "${GREEN}✓ FriendBet service started successfully${NC}"
	echo -e "${GREEN}✓ PocketBase Admin UI: http://localhost:${PORT}/_/${NC}"
	echo -e "${GREEN}✓ API endpoint: http://localhost:${PORT}/${NC}"
else
	echo -e "${RED}✗ Failed to start FriendBet service${NC}"
	echo -e "${YELLOW}Check logs with: journalctl -u ${SERVICE_NAME} -f${NC}"
	exit 1
fi

echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Access the admin UI: http://localhost:${PORT}/_/"
echo "2. Create your admin account"
echo "3. Configure OAuth providers in the admin UI"
echo "4. Run './deploy-initial-data.sh' to set up initial collections"
echo "5. Configure Cloudflare tunnel for external access"