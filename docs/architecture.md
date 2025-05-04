# Getting Started with Kurtosis-Orbit

This guide will walk you through deploying your own Arbitrum Orbit chain using Kurtosis-Orbit.

## Prerequisites

Before you begin, make sure you have:

1. **Docker** installed (>=4.27.0 for Mac users)
2. **Kurtosis CLI** installed following the [official documentation](https://docs.kurtosis.com/install)
3. At least 8GB of free RAM and 4 CPU cores

## Installation

### Install Kurtosis CLI

For Linux/macOS, run:

```bash
curl -L 'https://get.kurtosis.com' -o install-kurtosis.sh
./install-kurtosis.sh
```

For Windows, run in PowerShell:

```powershell
iwr 'https://get.kurtosis.com/windows' -OutFile 'install-kurtosis.ps1'
.\install-kurtosis.ps1
```

### Verify Installation

```bash
kurtosis --version
```

### Start Kurtosis Engine

```bash
kurtosis engine start
```

## Basic Usage

### Deploy with Default Settings

To deploy a basic Orbit chain with default settings:

```bash
kurtosis run github.com/arbitrumfoundation/kurtosis-orbit
```

This will:

1. Create a local Ethereum L1 chain
2. Deploy Arbitrum Orbit contracts on L1
3. Start an Arbitrum Nitro sequencer
4. Start an Arbitrum Nitro validator
5. Deploy a token bridge between L1 and L2

### Deploy with Custom Configuration

Create a `my-orbit-config.yml` file with your desired configuration:

```yaml
orbit_config:
  chain_name: "MyCustomChain"
  chain_id: 444555
  challenge_period_blocks: 10
  validator_count: 2
  enable_explorer: true
```

Then run:

```bash
kurtosis run github.com/arbitrumfoundation/kurtosis-orbit --args-file my-orbit-config.yml
```

## Accessing Your Orbit Chain

After deployment, you'll see output with connection information:

```
Orbit L2 Chain Deployment Completed
---------------------------------
Ethereum L1 RPC: http://el-1-geth-lighthouse:8545
Orbit L2 RPC: http://orbit-sequencer:8547
Orbit L2 Chain ID: 412346
Block Explorer: http://orbit-explorer:4000

Add to MetaMask:
1. Network Name: OrbitDevChain
2. RPC URL: http://orbit-sequencer:8547
3. Chain ID: 412346
4. Currency Symbol: ETH
```

### Forward Ports to Host Machine

To access these services from your host machine, use:

```bash
# Get the enclave name
kurtosis enclave ls

# Forward the L2 RPC port
kurtosis port forward <enclave_name> orbit-sequencer rpc

# Forward the explorer port (if enabled)
kurtosis port forward <enclave_name> orbit-explorer http
```

### Connect a Wallet

Add your chain to MetaMask:

1. Open MetaMask and click on the network dropdown
2. Select "Add network"
3. Click "Add a network manually"
4. Fill in the details:
   - Network Name: Your chain name (e.g., "OrbitDevChain")
   - New RPC URL: The forwarded RPC URL (e.g., "http://localhost:50160")
   - Chain ID: Your chain ID (e.g., 412346)
   - Currency Symbol: ETH
5. Click "Save"

### Deploy Smart Contracts

You can use standard Ethereum tools like Hardhat or Foundry to deploy smart contracts to your Orbit chain.

Example with Hardhat:

Update your `hardhat.config.js`:

```javascript
module.exports = {
  networks: {
    orbitDevnet: {
      url: "http://localhost:50160", // Forwarded RPC port
      chainId: 412346, // Your chain ID
      accounts: ["0x8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63"] // Default owner key
    }
  }
};
```

Deploy a contract:

```bash
npx hardhat run scripts/deploy.js --network orbitDevnet
```

## Using the Token Bridge

The token bridge enables transferring assets between L1 and L2. For testing purposes, you can use the default owner account that is prefunded on both L1 and L2.

To transfer ETH from L1 to L2:

1. Connect to L1 and approve a deposit
2. Wait for the transaction to be confirmed on L1
3. Wait for the deposit to be executed on L2

For a more detailed guide on using the bridge, refer to Arbitrum's official documentation.

## Working with the Block Explorer

If you enabled the block explorer, you can access it at the forwarded explorer port (e.g., http://localhost:50161).

The explorer provides:

- Block and transaction browsing
- Account and balance viewing
- Smart contract verification and interaction
- Token tracking

## Cleaning Up

To stop and remove your Orbit chain:

```bash
# Remove a specific enclave
kurtosis enclave rm <enclave_name>

# Or remove all enclaves
kurtosis clean -a
```

## Troubleshooting

### Service Fails to Start

If a service fails to start, check the logs:

```bash
kurtosis service logs <enclave_name> <service_name>
```

### RPC Connection Issues

If you can't connect to the RPC:

1. Verify the service is running:
   ```bash
   kurtosis enclave inspect <enclave_name>
   ```

2. Check if the port forwarding is active:
   ```bash
   kurtosis port status <enclave_name>
   ```

### Insufficient Resources

If services are stopping due to resource constraints:

1. Increase Docker's memory allocation (recommended: at least 8GB)
2. Reduce the number of validators in your configuration
3. Disable the block explorer to save resources

## Next Steps

- Learn more about [Arbitrum Orbit](https://docs.arbitrum.io/launch-orbit-chain/orbit-quickstart)
- Explore the [Arbitrum Orbit SDK](https://docs.arbitrum.io/launch-orbit-chain/orbit-sdk-introduction)
- Try deploying a custom token on your Orbit chain
- Set up a frontend application to interact with your chain