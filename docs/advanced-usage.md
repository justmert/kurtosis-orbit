# Advanced Usage

This guide covers advanced usage scenarios for Kurtosis Orbit deployments.

## Custom Network Topologies

### Multi-Chain Deployments

You can deploy multiple Orbit chains that connect to the same L1:

```bash
# Deploy the first Orbit chain
kurtosis run ./kurtosis/main.star --args-file ./config/chain1.yml

# Deploy a second Orbit chain in the same enclave
kurtosis run ./kurtosis/main.star --args-file ./config/chain2.yml --enclave my-enclave
```

### Cross-Chain Communication

To set up communication between two Orbit chains:

1. Deploy both chains as described above
2. Use the bridge contracts on each chain to enable asset transfers
3. Configure the bridge endpoints to point to each other

## Custom Token Deployment

### Deploying Custom ERC-20 Tokens

To deploy custom tokens on your Orbit chain:

```yaml
# In your configuration file
bridge:
  enabled: true
  custom_tokens:
    - name: "MyToken"
      symbol: "MTK"
      decimals: 18
      initial_supply: "1000000000000000000000000"
      cap: "10000000000000000000000000"
```

### Using Custom Token Contracts

To use your own token contract implementation:

1. Place your contract source in `scripts/contracts/tokens/`
2. Reference it in your configuration:

```yaml
custom_tokens:
  - name: "AdvancedToken"
    symbol: "ADV"
    decimals: 18
    contract_path: "./scripts/contracts/tokens/AdvancedToken.sol"
```

## Performance Tuning

### Optimizing for High Throughput

For high-throughput deployments:

```yaml
orbit:
  block_time: 1  # Faster blocks
  gas_limit: 50000000  # Higher gas limit
  
  # Advanced performance settings
  performance:
    tx_pool_size: 5000
    cache_size: 1024  # MB
    state_pruning: "archive"  # or "full" for smaller storage
```

### Scaling Validator Nodes

To deploy multiple validator nodes for better reliability:

```yaml
orbit:
  validators:
    - "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199"
    - "0x1111111111111111111111111111111111111111"
    - "0x2222222222222222222222222222222222222222"
  
  # Specify validator node count
  validator_nodes: 3
```

## Integration with External Systems

### Connecting to External Data Sources

To integrate with external data sources using oracles:

1. Deploy the Orbit chain with bridge enabled
2. Deploy oracle contracts on the Orbit chain
3. Configure external data feeds

Example oracle configuration:

```yaml
# Advanced configuration
oracles:
  enabled: true
  type: "chainlink"
  feeds:
    - name: "ETH/USD"
      address: "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419"
    - name: "BTC/USD"
      address: "0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c"
```

### Exposing RPC Endpoints

To securely expose your Orbit chain RPC endpoints:

```yaml
orbit:
  rpc:
    enabled: true
    port: 8545
    cors_domains: ["*"]
    methods: ["eth_*", "net_*"]
    auth:
      enabled: true
      jwt_secret: "your-secret-key"
```

## Monitoring and Observability

### Setting Up Monitoring

To enable comprehensive monitoring:

```yaml
monitoring:
  enabled: true
  prometheus:
    enabled: true
    port: 9090
  grafana:
    enabled: true
    port: 3000
    dashboards:
      - "node-metrics"
      - "transaction-metrics"
```

### Log Management

For advanced log management:

```yaml
logging:
  level: "debug"  # or "info", "warn", "error"
  format: "json"  # or "text"
  output: "file"  # or "stdout"
  file_path: "/var/log/orbit.log"
  rotation:
    enabled: true
    max_size: 100  # MB
    max_age: 7     # days
```

## Backup and Recovery

### Automated Backups

To configure automated state backups:

```yaml
backup:
  enabled: true
  schedule: "0 0 * * *"  # Daily at midnight (cron format)
  retention: 7  # days
  storage:
    type: "local"  # or "s3", "gcs"
    path: "/backups"
```

### Disaster Recovery

For disaster recovery scenarios, you can:

1. Create regular backups as described above
2. Implement a standby node that can take over if the primary fails
3. Use the backup to restore state on a new deployment
