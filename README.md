# bashscripts - Linux Development Environment Setup

A comprehensive collection of bash scripts designed to automate the setup and configuration of a complete development environment on Linux systems.

## Purpose

This repository provides automated scripts to bootstrap a Linux system with essential development tools, programming languages, databases, container technologies, cloud utilities, and system administration tools. The primary goal is to enable developers to quickly set up a fully-featured development environment with a single script execution.

**Supported Distributions:**
- Fedora
- CentOS/RHEL
- Rocky Linux / AlmaLinux
- Ubuntu
- Debian
- Linux Mint
- Pop!_OS

## Prerequisites

Before running the bootstrap script, ensure you have:

- **Linux System** - Fedora, CentOS, RHEL, Ubuntu, Debian, or compatible distributions
- **Root or sudo privileges** - Required for installing packages and configuring services
- **Internet connection** - For downloading packages and dependencies
- **Sufficient disk space** - At least 10GB free space recommended

## Usage

### Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/Stefodan21/bash-scripts.git
   cd bash-scripts
   ```

2. Make the script executable (if not already):
   ```bash
   chmod +x bootstrap.sh
   ```

3. Run the bootstrap script with sudo:
   ```bash
   sudo ./bootstrap.sh
   ```

4. Wait for the installation to complete. The script will:
   - Update your system packages
   - Install all dependencies and tools
   - Configure necessary services
   - Display a summary of installed components

### Post-Installation

After the script completes, you may need to:

1. **Start services** as needed:
   ```bash
   sudo systemctl start docker
   sudo systemctl start mongod
   sudo systemctl start postgresql
   sudo systemctl start redis
   sudo systemctl start jenkins
   sudo systemctl start nginx
   sudo systemctl start zookeeper
   sudo systemctl start kafka
   ```

2. **Add your user to the docker group** (to run Docker without sudo):
   ```bash
   sudo usermod -aG docker $USER
   ```
   Then log out and back in for changes to take effect.

3. **Configure databases**:
   - PostgreSQL: Set password for postgres user
   - MongoDB: Configure authentication if needed
   - Redis: Configure security settings

4. **Verify installations**:
   ```bash
   node --version
   npm --version
   yarn --version
   tsc --version
   python3 --version
   docker --version
   kubectl version --client
   terraform --version
   ```

## Dependencies

The `bootstrap.sh` script installs the following components:

### Development Tools
- **git** - Version control system
- **curl** - Command-line tool for transferring data
- **wget** - Network downloader
- **gcc/g++** - GNU C/C++ compilers
- **cmake** - Cross-platform build system
- **make** - Build automation tool

### Programming Languages & Runtimes
- **Python3** - Python programming language
- **pip** - Python package installer
- **virtualenv** - Python virtual environment tool
- **Node.js** - JavaScript runtime
- **npm** - Node.js package manager
- **yarn** - Fast, reliable dependency management
- **TypeScript** - Typed superset of JavaScript (globally installed)
- **Java 17** - Java Development Kit (for Jenkins and Kafka)

### Editors & IDEs
- **Visual Studio Code** - Source code editor

### Container Technologies
- **Docker** - Container platform
  - docker-ce
  - docker-ce-cli
  - containerd.io
  - docker-buildx-plugin
  - docker-compose-plugin
- **Podman** - Daemonless container engine
- **podman-compose** - Docker Compose alternative for Podman

### Cloud & DevOps Tools
- **AWS CLI** - Amazon Web Services command-line interface
- **kubectl** - Kubernetes command-line tool
- **Ansible** - IT automation platform
- **Terraform** - Infrastructure as Code tool
- **Jenkins** - Automation server for CI/CD

### System Utilities
- **htop** - Interactive process viewer
- **tmux** - Terminal multiplexer
- **net-tools** - Network utilities
- **nmap** - Network security scanner
- **sysstat** - System performance monitoring tools
- **jq** - Command-line JSON processor
- **rsync** - Fast file synchronization tool
- **cronie** - Cron daemon for scheduled tasks

### Databases
- **MongoDB** - NoSQL document database
- **PostgreSQL** - Relational database system
- **Redis** - In-memory data structure store

### Web Servers & Messaging
- **Nginx** - High-performance web server and reverse proxy
- **Apache Kafka** - Distributed event streaming platform
- **Apache Zookeeper** - Distributed coordination service (for Kafka)

## Script Features

- **Multi-Distribution Support**: Automatically detects and supports Fedora, CentOS, RHEL, Ubuntu, Debian, and compatible distributions
- **Intelligent Package Management**: Uses the appropriate package manager (dnf or apt) based on the detected distribution
- **Error Handling**: Exits on errors to prevent partial installations
- **Colored Output**: Uses color-coded messages for better visibility
- **Service Management**: Automatically enables installed services
- **Version Summary**: Displays installed versions at completion
- **Comprehensive Logging**: Clear information, warning, and error messages

## Notes

- The script automatically detects your Linux distribution and uses the appropriate package manager
- The script installs the latest stable versions available in official repositories and sources
- Some services are enabled but not started automatically - start them as needed
- MongoDB and PostgreSQL may require additional configuration for production use
- Kafka is installed in `/opt/kafka` with systemd service files
- All globally installed npm packages (yarn, TypeScript) are available system-wide

## Troubleshooting

If you encounter issues:

1. **Check system logs**:
   ```bash
   sudo journalctl -xe
   ```

2. **Verify service status**:
   ```bash
   sudo systemctl status <service-name>
   ```

3. **Review package installation**:
   - On Fedora/CentOS/RHEL:
     ```bash
     dnf list installed | grep <package-name>
     ```
   - On Ubuntu/Debian:
     ```bash
     dpkg -l | grep <package-name>
     ```

4. **Ensure sufficient disk space**:
   ```bash
   df -h
   ```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests to improve the scripts.

## License

This project is open source and available for use and modification.
