# Getting Started with Kurtosis-Orbit

This guide will help you deploy your first Arbitrum Orbit chain in minutes.

## Prerequisites

Before you begin, ensure you have:

1. **Docker** installed and running
   - Minimum 8GB RAM allocated
   - 20GB free disk space
   - For Mac users: Docker Desktop 4.27.0 or later

2. **Kurtosis CLI** installed
   ```bash
   # MacOS/Linux
   brew install kurtosis-tech/tap/kurtosis-cli
   
   # or using the install script
   curl -s https://get.kurtosis.com | bash
   ```

3. **System Requirements**
   - 4+ CPU cores
   - 8GB+ RAM
   - Linux, macOS, or Windows with WSL2

## Quick Start

### Step 1: Start Kurtosis Engine

```bash
kurtosis engine start
```

### Step 2: Deploy Default Orbit Chain

```bash
kurtosis run github.com/justmert/kurtosis-orbit
```

This deploys a complete Orbit stack with:
- Local Ethereum L1 chain
- Arbitrum Orbit L2 chain (sequencer + validator)
- Token bridge between L1 and L2
- Pre-funded development accounts

### Step 3: Access Your Chain

After deployment, you'll see output like:
```
✅ Kurtosis-Orbit Deployment Complete!
============================================================

📊 Chain Information:
Chain Name: Orbit-Dev-Chain
Chain ID: 412346
Mode: rollup
Owner Address: 0x5E1497dD1f08C87b2d8FE23e9AAB6c1De833D927

🔌 Connection Information:
L1 Ethereum RPC: http://el-1-geth-lighthouse:8545
L2 Arbitrum RPC: http://orbit-sequencer:8547
L2 Arbitrum WS: ws://orbit-sequencer:8548
```

### Step 4: Forward Ports to Localhost

To access the services from your host machine:

```bash
# Get your enclave name
kurtosis enclave ls

# Forward L2 RPC port
kurtosis port forward <enclave-name> orbit-sequencer rpc

# Forward L1 RPC port
kurtosis port forward <enclave-name> el-1-geth-lighthouse rpc
```

### Step 5: Connect MetaMask

1. Open MetaMask
2. Add Network > Add a network manually
3. Enter:
   - Network Name: `Orbit Dev Chain`
   - RPC URL: `http://localhost:<forwarded-port>`
   - Chain ID: `412346`
   - Currency Symbol: `ETH`

### Step 6: Use Pre-funded Accounts

Import these development accounts into MetaMask:

**Funnel Account** (10,000 ETH on L1 & L2)
- Address: `0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E`
- Private Key: `b6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659`

**Sequencer Account** (100 ETH on L1 & L2)
- Address: `0xe2148eE53c0755215Df69b2616E552154EdC584f`
- Private Key: `cb5790da63720727af975f42c79f69918580209889225fa7128c92402a6d3a65`

### Basic Usage - Using Helper Scripts

The repository includes useful scripts for testing and development:

```bash
# Navigate to the tests directory
cd tests
npm install

# Set up environment variables automatically
npm run setup

# Check account balances
npm run check-balances

# Deploy a test contract
npm run deploy-contract

# Interact with deployed contracts
npm run interact-contract

# Bridge ETH between L1 and L2
npm run bridge-eth

# Generate new development accounts
npm run generate-accounts
```

## Custom Configuration

Create `my-orbit-config.yml`:

```yaml
orbit_config:
  chain_name: "MyCustomChain"
  chain_id: 555666
  enable_explorer: true  # Enable Blockscout
```

Deploy with:
```bash
kurtosis run github.com/justmert/kurtosis-orbit --args-file my-orbit-config.yml
```

## Cleanup

To stop and remove your deployment:

```bash
# Remove specific enclave
kurtosis enclave rm <enclave-name>

# Remove all enclaves
kurtosis clean -a
```

## Getting Help

- Check [Troubleshooting](./troubleshooting.md) for common issues
- Report issues on [GitHub](https://github.com/justmert/kurtosis-orbit/issues) 