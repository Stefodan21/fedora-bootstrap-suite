#!/bin/bash

###############################################################################
# bootstrap.sh - Fedora Development Environment Setup Script
#
# This script installs essential development tools, programming languages,
# databases, container tools, cloud utilities, and system administration tools
# for a complete Fedora development environment.
#
# Usage: sudo ./bootstrap.sh
# 
# Requirements: Fedora Linux with sudo privileges
###############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Log functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root or with sudo"
    exit 1
fi

log_info "Starting Fedora development environment setup..."

###############################################################################
# 1. Update System
###############################################################################
log_info "Updating system packages..."
dnf update -y

###############################################################################
# 2. Install Basic Development Tools
###############################################################################
log_info "Installing basic development tools..."
dnf install -y \
    git \
    curl \
    wget \
    gcc \
    gcc-c++ \
    make \
    cmake \
    autoconf \
    automake \
    libtool \
    kernel-devel \
    kernel-headers

###############################################################################
# 3. Install Python Environment
###############################################################################
log_info "Installing Python3 and pip..."
dnf install -y \
    python3 \
    python3-pip \
    python3-devel \
    python3-virtualenv

log_info "Upgrading pip..."
python3 -m pip install --upgrade pip

###############################################################################
# 4. Install Node.js, npm, yarn, and TypeScript
###############################################################################
log_info "Installing Node.js and npm..."
dnf install -y nodejs npm

log_info "Installing yarn..."
npm install -g yarn

log_info "Installing TypeScript globally..."
npm install -g typescript

###############################################################################
# 5. Install VS Code
###############################################################################
log_info "Installing Visual Studio Code..."
rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat > /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
dnf install -y code

###############################################################################
# 6. Install Docker
###############################################################################
log_info "Installing Docker..."
dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
dnf install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

log_info "Enabling and starting Docker service..."
systemctl enable docker
systemctl start docker

###############################################################################
# 7. Install Podman
###############################################################################
log_info "Installing Podman..."
dnf install -y podman podman-compose

###############################################################################
# 8. Install AWS CLI
###############################################################################
log_info "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -o /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update
rm -rf /tmp/awscliv2.zip /tmp/aws

###############################################################################
# 9. Install kubectl
###############################################################################
log_info "Installing kubectl..."
cat > /etc/yum.repos.d/kubernetes.repo <<'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
EOF
dnf install -y kubectl

###############################################################################
# 10. Install Ansible
###############################################################################
log_info "Installing Ansible..."
dnf install -y ansible

###############################################################################
# 11. Install System Utilities
###############################################################################
log_info "Installing system utilities..."
dnf install -y \
    htop \
    tmux \
    net-tools \
    nmap \
    sysstat \
    jq \
    rsync \
    cronie

log_info "Enabling and starting cron service..."
systemctl enable crond
systemctl start crond

###############################################################################
# 12. Install MongoDB
###############################################################################
log_info "Installing MongoDB..."
cat > /etc/yum.repos.d/mongodb-org-7.0.repo <<'EOF'
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
dnf install -y mongodb-org

log_info "Enabling MongoDB service..."
systemctl enable mongod

###############################################################################
# 13. Install PostgreSQL
###############################################################################
log_info "Installing PostgreSQL..."
dnf install -y postgresql-server postgresql-contrib

log_info "Initializing PostgreSQL database..."
postgresql-setup --initdb || true

log_info "Enabling PostgreSQL service..."
systemctl enable postgresql

###############################################################################
# 14. Install Redis
###############################################################################
log_info "Installing Redis..."
dnf install -y redis

log_info "Enabling Redis service..."
systemctl enable redis

###############################################################################
# 15. Install Terraform
###############################################################################
log_info "Installing Terraform..."
dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
dnf install -y terraform

###############################################################################
# 16. Install Jenkins
###############################################################################
log_info "Installing Jenkins..."
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install -y java-17-openjdk
dnf install -y jenkins

log_info "Enabling Jenkins service..."
systemctl enable jenkins

###############################################################################
# 17. Install Nginx
###############################################################################
log_info "Installing Nginx..."
dnf install -y nginx

log_info "Enabling Nginx service..."
systemctl enable nginx

###############################################################################
# 18. Install Apache Kafka
###############################################################################
log_info "Installing Java (required for Kafka)..."
dnf install -y java-17-openjdk-devel

log_info "Downloading and installing Apache Kafka..."
KAFKA_VERSION="3.6.0"
SCALA_VERSION="2.13"
KAFKA_DIR="/opt/kafka"

cd /tmp
wget "https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
tar -xzf "kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
mv "kafka_${SCALA_VERSION}-${KAFKA_VERSION}" "${KAFKA_DIR}"
rm -f "kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"

# Create Kafka systemd service file
cat > /etc/systemd/system/zookeeper.service <<'EOF'
[Unit]
Description=Apache Zookeeper Server
Documentation=http://zookeeper.apache.org
Requires=network.target
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
ExecStop=/opt/kafka/bin/zookeeper-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/kafka.service <<'EOF'
[Unit]
Description=Apache Kafka Server
Documentation=http://kafka.apache.org/documentation.html
Requires=zookeeper.service
After=zookeeper.service

[Service]
Type=simple
User=root
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable zookeeper
systemctl enable kafka

###############################################################################
# Installation Summary
###############################################################################
log_info "================================================"
log_info "Installation completed successfully!"
log_info "================================================"
log_info ""
log_info "Installed components:"
log_info "  ✓ Basic development tools (git, curl, wget, gcc, g++, cmake)"
log_info "  ✓ Python3, pip, virtualenv"
log_info "  ✓ Node.js, npm, yarn, TypeScript"
log_info "  ✓ Visual Studio Code"
log_info "  ✓ Docker"
log_info "  ✓ Podman"
log_info "  ✓ AWS CLI"
log_info "  ✓ kubectl"
log_info "  ✓ Ansible"
log_info "  ✓ System utilities (htop, tmux, net-tools, nmap, sysstat, jq, rsync, cron)"
log_info "  ✓ MongoDB"
log_info "  ✓ PostgreSQL"
log_info "  ✓ Redis"
log_info "  ✓ Terraform"
log_info "  ✓ Jenkins"
log_info "  ✓ Nginx"
log_info "  ✓ Apache Kafka"
log_info ""
log_info "Note: Some services are enabled but not started."
log_info "To start services, use: sudo systemctl start <service-name>"
log_info ""
log_info "Service names:"
log_info "  - docker, mongod, postgresql, redis, jenkins, nginx, zookeeper, kafka"
log_info ""
log_info "Version information:"
log_info "  - Node.js: $(node --version 2>/dev/null || echo 'N/A')"
log_info "  - npm: $(npm --version 2>/dev/null || echo 'N/A')"
log_info "  - yarn: $(yarn --version 2>/dev/null || echo 'N/A')"
log_info "  - TypeScript: $(tsc --version 2>/dev/null || echo 'N/A')"
log_info "  - Python: $(python3 --version 2>/dev/null || echo 'N/A')"
log_info "  - Docker: $(docker --version 2>/dev/null || echo 'N/A')"
log_info "  - kubectl: $(kubectl version --client --short 2>/dev/null || echo 'N/A')"
log_info "  - Terraform: $(terraform --version 2>/dev/null | head -n1 || echo 'N/A')"
log_info ""
log_info "================================================"
