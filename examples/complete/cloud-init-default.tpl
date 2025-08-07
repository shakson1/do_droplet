#!/bin/bash

# Cloud-init script for DigitalOcean droplets
# Variables available: {{ droplet_name }}, {{ domain_name }}, {{ app_version }}, {{ db_host }}

set -e

# Update system
apt-get update
apt-get upgrade -y

# Install common packages
apt-get install -y \
  curl \
  wget \
  git \
  htop \
  unzip \
  software-properties-common \
  apt-transport-https \
  ca-certificates \
  gnupg \
  lsb-release

# Set hostname
hostnamectl set-hostname {{ droplet_name }}

# Configure timezone
timedatectl set-timezone UTC

# Create application user
useradd -m -s /bin/bash app || true
usermod -aG sudo app

# Create application directory
mkdir -p /opt/app
chown app:app /opt/app

# Install Docker (if needed)
if command -v docker &> /dev/null; then
    echo "Docker already installed"
else
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    usermod -aG docker app
fi

# Configure firewall (if ufw is available)
if command -v ufw &> /dev/null; then
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
fi

# Create application configuration
cat > /opt/app/config.env << EOF
DOMAIN_NAME={{ domain_name }}
APP_VERSION={{ app_version }}
DB_HOST={{ db_host }}
DROPLET_NAME={{ droplet_name }}
EOF

# Create health check endpoint
cat > /opt/app/health.sh << 'EOF'
#!/bin/bash
echo "OK"
EOF
chmod +x /opt/app/health.sh

# Install nginx for health checks
apt-get install -y nginx
cat > /etc/nginx/sites-available/health << EOF
server {
    listen 80;
    server_name _;
    
    location /health {
        content_by_lua_block {
            ngx.say("OK")
            ngx.exit(200)
        }
    }
    
    location / {
        return 404;
    }
}
EOF
ln -sf /etc/nginx/sites-available/health /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# Create systemd service for application
cat > /etc/systemd/system/app.service << EOF
[Unit]
Description=Application Service
After=network.target

[Service]
Type=simple
User=app
WorkingDirectory=/opt/app
ExecStart=/bin/bash -c 'echo "Application started on {{ droplet_name }}" && sleep infinity'
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start application service
systemctl daemon-reload
systemctl enable app
systemctl start app

# Log completion
echo "Cloud-init completed for {{ droplet_name }}" >> /var/log/cloud-init-output.log
echo "Domain: {{ domain_name }}" >> /var/log/cloud-init-output.log
echo "App Version: {{ app_version }}" >> /var/log/cloud-init-output.log
echo "DB Host: {{ db_host }}" >> /var/log/cloud-init-output.log 