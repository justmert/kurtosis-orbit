# Installation Guide

This guide provides detailed instructions for installing all prerequisites and the Kurtosis-Orbit package.

## System Requirements

### Minimum Requirements
- **CPU**: 4 cores
- **RAM**: 8GB (16GB recommended)
- **Storage**: 20GB free space
- **OS**: Linux, macOS, or Windows with WSL2

### Software Requirements
- Docker 20.10.0 or later
- **Kurtosis CLI v1.7.1** (required for compatibility)
- Git (for local development)

**⚠️ Important**: Kurtosis-Orbit requires exactly version 1.7.1 of the Kurtosis CLI. Other versions may not be compatible.

## Installing Docker

### macOS
```bash
# Using Homebrew
brew install --cask docker

# Or download Docker Desktop from:
# https://www.docker.com/products/docker-desktop
```

### Linux (Ubuntu/Debian)
```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Windows
1. Install [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install)
2. Download and install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
3. Enable WSL2 backend in Docker Desktop settings

## Installing Kurtosis CLI

### Option 1: Homebrew (macOS/Linux) - Recommended
```bash
brew install kurtosis-tech/tap/kurtosis-cli@1.7.1
```

### Option 2: Install Script
```bash
# Note: This installs the latest version, which may not be 1.7.1
# Use Option 1 or 3 for version 1.7.1 specifically
curl -s https://get.kurtosis.com | bash

# The script will add Kurtosis to your PATH
# You may need to restart your terminal or run:
source ~/.bashrc  # or ~/.zshrc
```

### Option 3: Manual Installation (Version 1.7.1)
```bash
# Download version 1.7.1 specifically
# Replace PLATFORM with: linux_amd64, darwin_amd64, or darwin_arm64
PLATFORM="linux_amd64"  # Change as needed
wget https://github.com/kurtosis-tech/kurtosis/releases/download/1.7.1/kurtosis-cli_1.7.1_${PLATFORM}.tar.gz

# Extract
tar -xzf kurtosis-cli_1.7.1_${PLATFORM}.tar.gz

# Move to PATH
sudo mv kurtosis /usr/local/bin/

# Verify installation (should show 1.7.1)
kurtosis version
```

## Configuring Docker

### Memory Allocation
Kurtosis-Orbit requires at least 8GB of RAM allocated to Docker.

**Docker Desktop (macOS/Windows):**
1. Open Docker Desktop
2. Go to Settings → Resources
3. Set Memory to at least 8GB
4. Apply & Restart

**Linux:**
Docker on Linux uses all available system memory by default.

### Disk Space
Ensure you have at least 20GB of free disk space for Docker images and volumes.

```bash
# Check Docker disk usage
docker system df

# Clean up unused resources if needed
docker system prune -a
```

## Verifying Installation

### Check Docker
```bash
# Check Docker is running
docker info

# Test Docker installation
docker run hello-world
```

### Check Kurtosis
```bash
# Check Kurtosis version
kurtosis version

# Start Kurtosis engine
kurtosis engine start

# Check engine status
kurtosis engine status
```

## Installing Kurtosis-Orbit

Kurtosis-Orbit doesn't require installation - it runs directly from GitHub:

```bash
# Run latest version
kurtosis run github.com/justmert/kurtosis-orbit

# Run specific version
kurtosis run github.com/justmert/kurtosis-orbit@v1.0.0

# Run from local directory (for development)
git clone https://github.com/justmert/kurtosis-orbit
cd kurtosis-orbit
kurtosis run .
```

## Post-Installation Setup

### Configure Kurtosis Analytics (Optional)
```bash
# Disable analytics if desired
kurtosis analytics disable
```

### Set Up Shell Completion (Optional)
```bash
# Bash
kurtosis completion bash > /etc/bash_completion.d/kurtosis

# Zsh
kurtosis completion zsh > "${fpath[1]}/_kurtosis"
```

## Troubleshooting Installation

### Docker Issues

**"Cannot connect to Docker daemon"**
```bash
# Start Docker service
sudo systemctl start docker  # Linux
open -a Docker  # macOS

# Check Docker is running
docker ps
```

**"Permission denied" errors**
```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
newgrp docker
```

### Kurtosis Issues

**"kurtosis: command not found"**
```bash
# Check if Kurtosis is in PATH
echo $PATH

# Add to PATH manually
export PATH=$PATH:/path/to/kurtosis
```

**"Failed to start engine"**
```bash
# Stop and restart engine
kurtosis engine stop
kurtosis engine start

# Check for port conflicts
lsof -i :9710  # Kurtosis default port
``` 