# Getting Started with Kurtosis Orbit

This guide will help you quickly deploy your first Orbit chain using Kurtosis Orbit.

## Prerequisites

Before you begin, ensure you have the following installed:

- [Kurtosis CLI](https://docs.kurtosis.com/install) (v0.47.0 or later)
- [Docker](https://docs.docker.com/get-docker/)
- [Node.js](https://nodejs.org/) (v16 or later)
- [Git](https://git-scm.com/downloads)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/kurtosis-orbit.git
cd kurtosis-orbit
```

### 2. Start Kurtosis Engine

Ensure the Kurtosis engine is running:

```bash
kurtosis engine start
```

### 3. Deploy a Basic Orbit Chain

Use the basic configuration to deploy a simple Orbit chain:

```bash
kurtosis run ./kurtosis/main.star --args-file ./config/examples/basic.yml
```

This will:
- Connect to the Sepolia testnet as L1 (or deploy a local L1 if specified)
- Deploy an Orbit chain with default parameters
- Set up a token bridge with WETH and USDC
- Deploy a block explorer

### 4. Access Your Deployment

Once deployed, Kurtosis will output the URLs for accessing your services:

- **Orbit RPC Endpoint**: http://localhost:8545
- **Block Explorer**: http://localhost:4000

## Using a Custom Configuration

To customize your deployment, create a new configuration file or modify an existing one:

```bash
cp config/examples/basic.yml my-orbit-config.yml
# Edit my-orbit-config.yml with your preferred settings
kurtosis run ./kurtosis/main.star --args-file ./my-orbit-config.yml
```

## Configuration Options

For a complete list of configuration options, see the [Configuration Documentation](configuration.md).

## Next Steps

- Learn about the [architecture](architecture.md) of Kurtosis Orbit
- Explore [advanced usage scenarios](advanced-usage.md)
- Check the [troubleshooting guide](troubleshooting.md) if you encounter issues
