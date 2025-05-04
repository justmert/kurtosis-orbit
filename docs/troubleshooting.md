# Troubleshooting Kurtosis-Orbit

This guide addresses common issues you might encounter when running Kurtosis-Orbit.

## Docker and Kurtosis Issues

### Kurtosis Engine Not Starting

**Symptoms**: `kurtosis engine start` fails or hangs

**Solutions**:

1. Check Docker is running:
   ```bash
   docker info
   ```

2. Ensure Docker has enough resources:
   - At least 8GB RAM
   - At least 4 CPU cores
   - At least 20GB free disk space

3. Restart Docker and Kurtosis:
   ```bash
   docker restart
   kurtosis engine restart
   ```

### Docker Container Limits

**Symptoms**: Services start but then crash with resource-related errors

**Solutions**:

1. Increase Docker memory limits:
   - Docker Desktop: Settings > Resources > Memory (increase to at least 8GB)

2. Reduce resource usage in configuration:
   ```yaml
   orbit_config:
     validator_count: 0  # Reduce or eliminate validators
     enable_explorer: false  # Disable explorer
   ```

## Deployment Issues

### Contract Deployment Fails

**Symptoms**: The orbit-deployer service fails with errors

**Solutions**:

1. Check deployment logs:
   ```bash
   kurtosis service logs <enclave-name> orbit-deployer
   ```

2. Ensure L1 chain is running:
   ```bash
   kurtosis service logs <enclave-name> el-1-geth-lighthouse
   ```

3. Verify the owner account has enough ETH on L1

### Nitro Node Startup Fails

**Symptoms**: Sequencer or validator fails to start

**Solutions**:

1. Check the sequencer logs:
   ```bash
   kurtosis service logs <enclave-name> orbit-sequencer
   ```

2. Verify the chain-info.json file was created correctly:
   ```bash
   kurtosis service exec <enclave-name> orbit-sequencer cat /home/user/.arbitrum/chain-info.json
   ```

3. Ensure the L1 RPC endpoint is accessible from the Nitro node:
   ```bash
   kurtosis service exec <enclave-name> orbit-sequencer curl -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://el-1-geth-lighthouse:8545
   ```

## Connectivity Issues

### Cannot Connect to RPC Endpoints

**Symptoms**: Tools like MetaMask or web3.js can't connect to the RPC

**Solutions**:

1. Verify port forwarding is active:
   ```bash
   kurtosis port status <enclave-name>
   ```

2. Create or check port forwarding:
   ```bash
   kurtosis port forward <enclave-name> orbit-sequencer rpc
   ```

3. Test the RPC from host:
   ```bash
   curl -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:<port>
   ```

### Explorer Not Accessible

**Symptoms**: Block explorer URL doesn't load

**Solutions**:

1. Check if explorer is enabled in your config:
   ```yaml
   orbit_config:
     enable_explorer: true
   ```

2. Forward the explorer port:
   ```bash
   kurtosis port forward <enclave-name> orbit-explorer http
   ```

3. Check explorer logs for startup issues:
   ```bash
   kurtosis service logs <enclave-name> orbit-explorer
   ```

## Transaction Issues

### Transactions Not Being Mined

**Symptoms**: Transactions get stuck in pending state

**Solutions**:

1. Check sequencer is running and processing transactions:
   ```bash
   kurtosis service logs <enclave-name> orbit-sequencer | grep -i "transaction"
   ```

2. Verify you're using the correct chain ID:
   ```bash
   kurtosis service exec <enclave-name> orbit-sequencer curl -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' http://localhost:8547
   ```

3. Ensure the account has enough ETH on L2:
   ```bash
   kurtosis service exec <enclave-name> orbit-sequencer curl -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_getBalance","params":["YOUR_ADDRESS", "latest"],"id":1}' http://localhost:8547
   ```

### Bridge Transactions Failing

**Symptoms**: Unable to bridge tokens between L1 and L2

**Solutions**:

1. Verify bridge contracts were deployed successfully:
   ```bash
   kurtosis service logs <enclave-name> bridge-deployer
   ```

2. Check if the account has enough ETH on L1:
   ```bash
   kurtosis service exec <enclave-name> orbit-sequencer curl -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_getBalance","params":["YOUR_ADDRESS", "latest"],"id":1}' http://el-1-geth-lighthouse:8545
   ```

3. For custom tokens, ensure they're properly registered on the bridge

## Advanced Troubleshooting

### Recreating the Environment

If you're having persistent issues, try creating a fresh environment:

```bash
# Remove existing enclave
kurtosis clean -a

# Stop and restart Kurtosis engine
kurtosis engine stop
kurtosis engine start

# Run with default config
kurtosis run github.com/arbitrumfoundation/kurtosis-orbit
```

### Debugging Nitro Node Issues

For deeper investigation of Nitro node issues:

```bash
# Get an interactive shell
kurtosis service shell <enclave-name> orbit-sequencer

# Inside the container:
cd /home/user/.arbitrum
cat chain-info.json
tail -f /home/user/.arbitrum/log/sequencer.log
```

### Checking L1-L2 Communication

To verify L1-L2 communication:

```bash
# Check L1 blocks are being processed
kurtosis service logs <enclave-name> orbit-sequencer | grep -i "l1 block"

# Check batch posting
kurtosis service logs <enclave-name> orbit-sequencer | grep -i "batch"
```

## Getting Help

If you're still experiencing issues:

1. Create a GitHub issue with:
   - Steps to reproduce
   - Full logs from affected services
   - Your configuration file
   - Environment details (OS, Docker version, Kurtosis version)

2. Check the Arbitrum Discord for community support

3. Consult Arbitrum's official documentation for more details on Orbit chain configuration