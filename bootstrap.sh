#!/bin/bash

###############################################################################
# bootstrap.sh - Linux Development Environment Setup Script
#
# This script installs essential development tools, programming languages,
# databases, container tools, cloud utilities, and system administration tools
# for a complete development environment.
#
# Supported distributions: Fedora, CentOS/RHEL, Ubuntu/Debian
#
# Usage: sudo ./bootstrap.sh
# 
# Requirements: Linux with sudo privileges
###############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Version variables (modify here to update versions)
KAFKA_VERSION="3.6.0"
SCALA_VERSION="2.13"
KUBERNETES_VERSION="v1.28"

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

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION_ID=${VERSION_ID:-}
    elif [ -f /etc/fedora-release ]; then
        DISTRO="fedora"
    elif [ -f /etc/centos-release ]; then
        DISTRO="centos"
    elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
    else
        log_error "Unsupported Linux distribution"
        exit 1
    fi
    
    log_info "Detected distribution: $DISTRO"
}

# Set package manager commands based on distribution
set_package_manager() {
    case "$DISTRO" in
        fedora|centos|rhel|rocky|almalinux)
            PKG_MANAGER="dnf"
            PKG_INSTALL="dnf install -y"
            PKG_UPDATE="dnf update -y"
            PKG_CONFIG_MANAGER="dnf config-manager"
            ;;
        ubuntu|debian|linuxmint|pop)
            PKG_MANAGER="apt"
            PKG_INSTALL="apt-get install -y"
            PKG_UPDATE="apt-get update && apt-get upgrade -y"
            PKG_CONFIG_MANAGER="add-apt-repository"
            # Update package lists for Debian-based systems
            apt-get update
            ;;
        *)
            log_error "Unsupported distribution: $DISTRO"
            exit 1
            ;;
    esac
    
    log_info "Using package manager: $PKG_MANAGER"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root or with sudo"
    exit 1
fi

log_info "Starting Linux development environment setup..."

# Detect distribution and set package manager
detect_distro
set_package_manager

###############################################################################
# 1. Update System
###############################################################################
log_info "Updating system packages..."
$PKG_UPDATE

###############################################################################
# 2. Install Basic Development Tools
###############################################################################
log_info "Installing basic development tools..."

if [ "$PKG_MANAGER" = "dnf" ]; then
    $PKG_INSTALL \
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
else
    # Debian/Ubuntu
    $PKG_INSTALL \
        git \
        curl \
        wget \
        gcc \
        g++ \
        make \
        cmake \
        autoconf \
        automake \
        libtool \
        build-essential
    
    # Try to install kernel headers, fallback to generic if specific version not available
    if ! $PKG_INSTALL "linux-headers-$(uname -r)"; then
        log_warn "Specific kernel headers not available, installing generic headers"
        $PKG_INSTALL linux-headers-generic || true
    fi
fi

###############################################################################
# 3. Install Python Environment
###############################################################################
log_info "Installing Python3 and pip..."

if [ "$PKG_MANAGER" = "dnf" ]; then
    $PKG_INSTALL \
        python3 \
        python3-pip \
        python3-devel \
        python3-virtualenv
else
    # Debian/Ubuntu
    $PKG_INSTALL \
        python3 \
        python3-pip \
        python3-dev \
        python3-venv
fi

log_info "Upgrading pip..."
python3 -m pip install --upgrade pip

###############################################################################
# 4. Install Node.js, npm, yarn, and TypeScript
###############################################################################
log_info "Installing Node.js and npm..."

if [ "$PKG_MANAGER" = "dnf" ]; then
    $PKG_INSTALL nodejs npm
else
    # Debian/Ubuntu - use NodeSource repository for newer versions
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    $PKG_INSTALL nodejs
fi

log_info "Installing yarn..."
npm install -g yarn

log_info "Installing TypeScript globally..."
npm install -g typescript

###############################################################################
# 5. Install VS Code
###############################################################################
log_info "Installing Visual Studio Code..."

if [ "$PKG_MANAGER" = "dnf" ]; then
    rpm --import https://packages.microsoft.com/keys/microsoft.asc
    cat > /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    $PKG_INSTALL code
else
    # Debian/Ubuntu
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
    apt-get update
    $PKG_INSTALL code
fi

###############################################################################
# 6. Install Docker
###############################################################################
log_info "Installing Docker..."

if [ "$PKG_MANAGER" = "dnf" ]; then
    $PKG_INSTALL dnf-plugins-core
    
    # Determine the correct repository URL based on distribution
    case "$DISTRO" in
        fedora)
            DOCKER_REPO_URL="https://download.docker.com/linux/fedora/docker-ce.repo"
            ;;
        centos|rhel|rocky|almalinux)
            DOCKER_REPO_URL="https://download.docker.com/linux/centos/docker-ce.repo"
            ;;
        *)
            # Default to CentOS repo for other RHEL-based distributions
            DOCKER_REPO_URL="https://download.docker.com/linux/centos/docker-ce.repo"
            ;;
    esac
    
    $PKG_CONFIG_MANAGER --add-repo "$DOCKER_REPO_URL"
    $PKG_INSTALL \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
else
    # Debian/Ubuntu
    $PKG_INSTALL \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    mkdir -p /etc/apt/keyrings
    
    # Determine the correct Docker repository base URL
    case "$DISTRO" in
        ubuntu|pop|linuxmint)
            DOCKER_DISTRO="ubuntu"
            ;;
        debian)
            DOCKER_DISTRO="debian"
            ;;
        *)
            DOCKER_DISTRO="ubuntu"
            ;;
    esac
    
    curl -fsSL "https://download.docker.com/linux/${DOCKER_DISTRO}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DOCKER_DISTRO} \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    $PKG_INSTALL \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
fi

log_info "Enabling and starting Docker service..."
systemctl enable docker
systemctl start docker

###############################################################################
# 7. Install Podman
###############################################################################
log_info "Installing Podman..."

if [ "$PKG_MANAGER" = "dnf" ]; then
    $PKG_INSTALL podman podman-compose
else
    # Debian/Ubuntu
    $PKG_INSTALL podman
    # podman-compose via pip
    python3 -m pip install podman-compose
fi

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

if [ "$PKG_MANAGER" = "dnf" ]; then
    cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/rpm/repodata/repomd.xml.key
EOF
    $PKG_INSTALL kubectl
else
    # Debian/Ubuntu
    curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
    apt-get update
    $PKG_INSTALL kubectl
fi

###############################################################################
# 10. Install Ansible
###############################################################################
log_info "Installing Ansible..."

if [ "$PKG_MANAGER" = "dnf" ]; then
    $PKG_INSTALL ansible
else
    # Debian/Ubuntu
    $PKG_INSTALL software-properties-common
    add-apt-repository --yes --update ppa:ansible/ansible
    $PKG_INSTALL ansible
fi

###############################################################################
# 11. Install System Utilities
###############################################################################
log_info "Installing system utilities..."

if [ "$PKG_MANAGER" = "dnf" ]; then
    $PKG_INSTALL \
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
else
    # Debian/Ubuntu
    $PKG_INSTALL \
        htop \
        tmux \
        net-tools \
        nmap \
        sysstat \
        jq \
        rsync \
        cron
    
    log_info "Enabling and starting cron service..."
    systemctl enable cron
    systemctl start cron
fi

###############################################################################
# 12. Install MongoDB
###############################################################################
log_info "Installing MongoDB..."

if [ "$PKG_MANAGER" = "dnf" ]; then
    # Determine the RHEL major version
    if [ -n "${VERSION_ID:-}" ]; then
        RHEL_VERSION=$(echo "$VERSION_ID" | cut -d. -f1)
    else
        # Default to 9 if version cannot be determined
        RHEL_VERSION="9"
    fi
    
    cat > /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/${RHEL_VERSION}/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
    $PKG_INSTALL mongodb-org
else
    # Debian/Ubuntu
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
        gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
    
    # Determine the correct release codename
    case "$DISTRO" in
        ubuntu|pop|linuxmint)
            # Use Ubuntu repository - detect the release
            RELEASE_CODENAME=$(lsb_release -cs)
            # Map older/newer releases to supported MongoDB releases
            case "$RELEASE_CODENAME" in
                noble|mantic|lunar)
                    MONGO_RELEASE="jammy"
                    ;;
                jammy|focal)
                    MONGO_RELEASE="$RELEASE_CODENAME"
                    ;;
                *)
                    # Default to jammy for unknown Ubuntu releases
                    MONGO_RELEASE="jammy"
                    ;;
            esac
            echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu ${MONGO_RELEASE}/mongodb-org/7.0 multiverse" | \
                tee /etc/apt/sources.list.d/mongodb-org-7.0.list
            ;;
        debian)
            # Use Debian repository
            RELEASE_CODENAME=$(lsb_release -cs)
            echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/debian ${RELEASE_CODENAME}/mongodb-org/7.0 main" | \
                tee /etc/apt/sources.list.d/mongodb-org-7.0.list
            ;;
    esac
    
    apt-get update
    $PKG_INSTALL mongodb-org
fi

log_info "Enabling MongoDB service..."
systemctl enable mongod

###############################################################################
# 13. Install PostgreSQL
###############################################################################
log_info "Installing PostgreSQL..."

if [ "$PKG_MANAGER" = "dnf" ]; then
    $PKG_INSTALL postgresql-server postgresql-contrib
    
    log_info "Initializing PostgreSQL database..."
    postgresql-setup --initdb || true
else
    # Debian/Ubuntu
    $PKG_INSTALL postgresql postgresql-contrib
    # PostgreSQL is automatically initialized on Debian/Ubuntu
fi

log_info "Enabling PostgreSQL service..."
systemctl enable postgresql

###############################################################################
# 14. Install Redis
###############################################################################
log_info "Installing Redis..."
$PKG_INSTALL redis

log_info "Enabling Redis service..."
if [ "$PKG_MANAGER" = "dnf" ]; then
    systemctl enable redis
else
    systemctl enable redis-server
fi

###############################################################################
# 15. Install Terraform
###############################################################################
log_info "Installing Terraform..."

if [ "$PKG_MANAGER" = "dnf" ]; then
    $PKG_INSTALL dnf-plugins-core
    
    # Determine the correct repository URL based on distribution
    case "$DISTRO" in
        fedora)
            HASHICORP_REPO_URL="https://rpm.releases.hashicorp.com/fedora/hashicorp.repo"
            ;;
        centos|rhel|rocky|almalinux)
            HASHICORP_REPO_URL="https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo"
            ;;
        *)
            # Default to RHEL repo for other RHEL-based distributions
            HASHICORP_REPO_URL="https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo"
            ;;
    esac
    
    $PKG_CONFIG_MANAGER --add-repo "$HASHICORP_REPO_URL"
    $PKG_INSTALL terraform
else
    # Debian/Ubuntu
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        tee /etc/apt/sources.list.d/hashicorp.list
    apt-get update
    $PKG_INSTALL terraform
fi

###############################################################################
# 16. Install Jenkins
###############################################################################
log_info "Installing Jenkins..."

if [ "$PKG_MANAGER" = "dnf" ]; then
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    $PKG_INSTALL java-17-openjdk
    $PKG_INSTALL jenkins
else
    # Debian/Ubuntu
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
        /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
        tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    apt-get update
    $PKG_INSTALL fontconfig openjdk-17-jre
    $PKG_INSTALL jenkins
fi

log_info "Enabling Jenkins service..."
systemctl enable jenkins

###############################################################################
# 17. Install Nginx
###############################################################################
log_info "Installing Nginx..."
$PKG_INSTALL nginx

log_info "Enabling Nginx service..."
systemctl enable nginx

###############################################################################
# 18. Install Apache Kafka
###############################################################################
log_info "Installing Java (required for Kafka)..."

if [ "$PKG_MANAGER" = "dnf" ]; then
    $PKG_INSTALL java-17-openjdk-devel
else
    $PKG_INSTALL openjdk-17-jdk
fi

log_info "Downloading and installing Apache Kafka..."
KAFKA_DIR="/opt/kafka"

cd /tmp
wget "https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
tar -xzf "kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"
mv "kafka_${SCALA_VERSION}-${KAFKA_VERSION}" "${KAFKA_DIR}"
rm -f "kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"

# Create Kafka systemd service file
# NOTE: For production use, create a dedicated 'kafka' user instead of running as root
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
log_info "  - kubectl: $(kubectl version --client 2>/dev/null | head -n1 || echo 'N/A')"
log_info "  - Terraform: $(terraform --version 2>/dev/null | head -n1 || echo 'N/A')"
log_info ""
log_info "================================================"
