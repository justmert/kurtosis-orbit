# Troubleshooting Guide

This guide helps you resolve common issues with Kurtosis-Orbit deployments.

## Common Issues

### Deployment Failures

#### "Kurtosis engine not running"

**Symptoms**: 
```
Error: Kurtosis engine is not running
```

**Solution**:
```bash
# Start the engine
kurtosis engine start

# Verify it's running
kurtosis engine status
```

#### "Insufficient Docker resources"

**Symptoms**: 
- Services crash during deployment
- "Out of memory" errors
- Deployment hangs

**Solutions**:

1. **Increase Docker memory** (Recommended: 8GB minimum)
   - Docker Desktop → Settings → Resources → Memory

2. **Reduce resource usage**:
   ```yaml
   orbit_config:
     simple_mode: true        # Use single node
     validator_count: 0       # No separate validators
     enable_explorer: false   # Disable Blockscout
   ```

3. **Clean up Docker resources**:
   ```bash
   docker system prune -a --volumes
   ```

#### "Port already in use"

**Symptoms**:
```
Error: port 8545 is already allocated
```

**Solutions**:
```bash
# Find process using port
lsof -i :8545  # macOS/Linux
netstat -ano | findstr :8545  # Windows

# Stop conflicting service or use different enclave
kurtosis enclave rm <old-enclave>
```

### Connection Issues

#### "Cannot connect to RPC"

**Symptoms**:
- MetaMask shows "Could not fetch chain ID"
- Web3 connection errors

**Solutions**:

1. **Check port forwarding**:
   ```bash
   # List forwarded ports
   kurtosis enclave inspect <enclave-name>
   
   # Forward RPC port
   kurtosis port forward <enclave-name> orbit-sequencer rpc
   ```

2. **Verify service is running**:
   ```bash
   # Check service status
   kurtosis service logs <enclave-name> orbit-sequencer
   ```

3. **Test connection**:
   ```bash
   # Test RPC endpoint
   curl -X POST http://localhost:<port> \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
   ```

#### "WebSocket connection failed"

**Symptoms**:
- Can't connect to ws://localhost:PORT
- WebSocket errors in console

**Solution**:
```bash
# Forward WebSocket port specifically
kurtosis port forward <enclave-name> orbit-sequencer ws
```

### Transaction Issues

#### "Transaction stuck pending"

**Symptoms**:
- Transaction doesn't get mined
- Stuck in MetaMask

**Solutions**:

1. **Check nonce**:
   ```javascript
   // Reset account in MetaMask
   // Settings → Advanced → Reset Account
   ```

2. **Verify chain ID**:
   ```bash
   # Should return 0x647ba (412346 in hex)
   curl -X POST http://localhost:<port> \
     -H "Content-Type: application/json" \
     -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
   ```

3. **Check gas price**:
   ```javascript
   // Use higher gas price
   await wallet.sendTransaction({
     to: recipient,
     value: amount,
     gasPrice: ethers.utils.parseUnits('10', 'gwei')
   });
   ```

#### "Insufficient funds for gas"

**Symptoms**:
- Transaction fails with gas error
- Even though account has ETH

**Solutions**:

1. **Check correct network**:
   - Ensure you're on L2 not L1
   - Verify account balance on correct chain

2. **Use funded account**:
   ```bash
   # Funnel account has 1000 ETH
   # Private key: b6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659
   ```

### Service-Specific Issues

#### Sequencer Not Starting

**Check logs**:
```bash
kurtosis service logs <enclave-name> orbit-sequencer --follow
```

**Common issues**:
- L1 not ready: Wait for L1 to mine blocks
- Chain info missing: Check orbit-deployer completed
- Port conflicts: Another service using same port

#### Validator Staking Errors

**Symptoms**:
```
Error: insufficient stake
```

**Solutions**:
1. Ensure validator account has ETH on L1
2. Check stake token configuration
3. Verify validator private key is correct

#### Explorer Not Loading

**Symptoms**:
- Blockscout page blank
- Database connection errors

**Solutions**:

1. **Check PostgreSQL**:
   ```bash
   kurtosis service logs <enclave-name> postgres
   ```

2. **Wait for indexing**:
   - Blockscout needs time to index
   - Check logs for progress

3. **Verify configuration**:
   ```yaml
   orbit_config:
     enable_explorer: true  # Must be enabled
   ```

### Bridge Issues

#### "Bridge transaction failed"

**Solutions**:

1. **Check allowance** (for ERC20):
   ```javascript
   await token.approve(bridgeAddress, amount);
   ```

2. **Verify bridge contracts**:
   ```bash
   # Check deployment logs
   kurtosis service logs <enclave-name> token-bridge-deployer
   ```

3. **Wait for confirmations**:
   - L1 → L2: Wait ~1 minute
   - L2 → L1: Wait for challenge period

### Advanced Troubleshooting

#### Enable Debug Logging

```yaml
orbit_config:
  debug_mode: true
  log_level: "debug"
```

#### Inspect Service Files

```bash
# Execute commands in container
kurtosis service exec <enclave-name> orbit-sequencer /bin/sh

# Check configuration
cat /config/sequencer_config.json

# View chain info
cat /chain-info/chain_info.json
```

#### Monitor Resources

```bash
# Check Docker stats
docker stats

# Monitor specific service
docker stats $(docker ps -q --filter "name=orbit-sequencer")
```

#### Network Debugging

```bash
# Check service connectivity
kurtosis service exec <enclave-name> orbit-sequencer \
  curl http://el-1-geth-lighthouse:8545

# Verify DNS resolution
kurtosis service exec <enclave-name> orbit-sequencer \
  nslookup el-1-geth-lighthouse
```

## Getting Help

### Before Asking for Help

1. **Collect information**:
   ```bash
   # Kurtosis version
   kurtosis version
   
   # Docker version
   docker version
   
   # Enclave status
   kurtosis enclave inspect <enclave-name>
   
   # Service logs
   kurtosis service logs <enclave-name> <service-name>
   ```

2. **Check existing issues**:
   - [GitHub Issues](https://github.com/justmert/kurtosis-orbit/issues)
   - [Arbitrum Discord](https://discord.gg/arbitrum)

3. **Prepare details**:
   - Configuration file used
   - Exact error messages
   - Steps to reproduce

### Support Channels

1. **GitHub Issues**: For bugs and feature requests
2. **Discord**: For community help
3. **Documentation**: Check all guides first

## Recovery Procedures

### Clean Restart

```bash
# Remove everything
kurtosis clean -a

# Restart engine
kurtosis engine restart

# Try again with defaults
kurtosis run github.com/justmert/kurtosis-orbit
```

### Partial Recovery

```bash
# Remove specific enclave
kurtosis enclave rm <enclave-name>

# Keep engine running
# Retry deployment
```

### Data Recovery

```bash
# Export logs before cleanup
kurtosis enclave dump <enclave-name> ./debug-logs

# Save service files
kurtosis service exec <enclave-name> <service> \
  tar -czf /tmp/backup.tar.gz /important/data
```

