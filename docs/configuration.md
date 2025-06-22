# Configuration Guide

This guide explains all configuration options available in Kurtosis-Orbit.

## Configuration File Format

Kurtosis-Orbit uses YAML configuration files with the following structure:

```yaml
orbit_config:
  # Configuration options go here
```

## Basic Configuration

### Minimal Configuration

```yaml
orbit_config:
  chain_name: "MyOrbitChain"
  chain_id: 412346
```

### Using Configuration Files

```bash
# Use a configuration file
kurtosis run github.com/justmert/kurtosis-orbit --args-file my-config.yml

# Use environment variables
CHAIN_ID=555666 kurtosis run github.com/justmert/kurtosis-orbit
```

## Configuration Options

### Chain Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `chain_name` | string | "Orbit-Dev-Chain" | Human-readable name for your chain |
| `chain_id` | integer | 412346 | Unique chain ID (avoid conflicts) |
| `l1_chain_id` | integer | 1337 | L1 chain ID (1337 for local) |

### Rollup Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `rollup_mode` | boolean | true | true=rollup, false=anytrust |
| `challenge_period_blocks` | integer | 20 | Blocks for challenge period |
| `stake_token` | address | "0x0000...0000" | Token for validator stakes |
| `base_stake` | string | "0" | Minimum stake amount (wei) |

### Account Configuration

**⚠️ WARNING**: Default keys are for development only. Generate your own for production!

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `owner_private_key` | string | (dev key) | Chain owner private key |
| `owner_address` | string | (derived) | MUST match private key |
| `sequencer_private_key` | string | (dev key) | Sequencer private key |
| `sequencer_address` | string | (derived) | MUST match private key |
| `validator_private_key` | string | (dev key) | Validator private key |
| `validator_address` | string | (derived) | MUST match private key |

### Node Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `simple_mode` | boolean | true | Single node for all roles |
| `validator_count` | integer | 1 | Number of validators (max 1) |
| `enable_bridge` | boolean | true | Deploy token bridge |
| `enable_explorer` | boolean | false | Deploy Blockscout |
| `enable_timeboost` | boolean | false | Enable Timeboost (experimental) |

### Funding Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `standard_account_balance_l1` | string | "1000" | ETH balance for standard accounts on L1 |
| `standard_account_balance_l2` | string | "1000" | ETH balance for standard accounts on L2 |
| `pre_fund_accounts` | array | ["funnel", "sequencer", "validator", "l2owner"] | Standard accounts to fund |
| `prefund_addresses` | array | [] | Additional addresses to fund (100 ETH each) |

### Image Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `nitro_image` | string | "offchainlabs/nitro-node:v3.5.5-90ee45c" | Nitro node Docker image |
| `nitro_contracts_branch` | string | "v2.1.1-beta.0" | Contracts version |
| `token_bridge_branch` | string | "v1.2.2" | Token bridge version |
| `blockscout_image` | string | "offchainlabs/blockscout:v1.1.0-0e716c8" | Blockscout explorer image |
| `postgres_image` | string | "postgres:13.6" | PostgreSQL image for Blockscout |

## Example Configurations

### Basic Development Setup

```yaml
orbit_config:
  chain_name: "DevChain"
  chain_id: 999888
  simple_mode: true
  enable_explorer: true
```

### Production-like Configuration

```yaml
orbit_config:
  chain_name: "ProductionTest"
  chain_id: 123456
  simple_mode: false
  validator_count: 1
  enable_bridge: true
  enable_explorer: true
  
  # Higher stakes for validators
  stake_token: "0x0000000000000000000000000000000000000000"
  base_stake: "1000000000000000000"  # 1 ETH
  
  # Longer challenge period
  challenge_period_blocks: 100
```

### Custom Accounts Configuration

```yaml
orbit_config:
  chain_name: "CustomChain"
  chain_id: 777888
  
  # Use your own accounts
  owner_private_key: "YOUR_PRIVATE_KEY_HERE"
  owner_address: "0xYOUR_ADDRESS_HERE"
  
  # Adjust funding amounts
  standard_account_balance_l1: "5000"
  standard_account_balance_l2: "2000"
  
  # Fund specific addresses
  prefund_addresses:
    - "0x742d35Cc6634C0532925a3b844Bc454e4438f44e"
    - "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199"
```

### AnyTrust Configuration

```yaml
orbit_config:
  chain_name: "AnyTrustChain"
  chain_id: 555666
  rollup_mode: false  # Enable AnyTrust mode
  
  # AnyTrust requires additional DAS configuration
  anytrust_config:
    committee_size: 2
    redundancy: 1
```

### Custom Docker Images

```yaml
orbit_config:
  chain_name: "CustomImages"
  chain_id: 888999
  
  # Use specific versions
  nitro_image: "offchainlabs/nitro-node:v3.5.5-90ee45c"
  blockscout_image: "offchainlabs/blockscout:v1.1.0-0e716c8"
  postgres_image: "postgres:14"
  
  # Use specific contract branches
  nitro_contracts_branch: "v2.1.1-beta.0"
  token_bridge_branch: "v1.2.2"
```

### Minimal Resource Configuration

```yaml
orbit_config:
  chain_name: "LightweightChain"
  chain_id: 111222
  simple_mode: true
  enable_bridge: false      # Save resources
  enable_explorer: false    # Save resources
  validator_count: 0        # No separate validators
  
  # Reduce funding for testing
  standard_account_balance_l1: "100"
  standard_account_balance_l2: "100"
  pre_fund_accounts: ["funnel", "sequencer"]  # Only essential accounts
```

## Environment Variables

Some configuration can be overridden using environment variables:

```bash
# Override chain ID
export ORBIT_CHAIN_ID=999888

# Override docker images
export NITRO_NODE_IMAGE=offchainlabs/nitro-node:latest
export BLOCKSCOUT_IMAGE=offchainlabs/blockscout:latest
```

## Advanced Configuration

### Timeboost Configuration (Experimental)

```yaml
orbit_config:
  enable_timeboost: true
  timeboost_config:
    auction_duration: 60  # seconds
    bid_token: "0x..."    # Token address for bidding
```

### Multi-Validator Setup (Limited Support)

```yaml
orbit_config:
  simple_mode: false
  validator_count: 1  # Currently limited to 1
  validator_configs:
    - private_key: "..."
      address: "0x..."
```

## Configuration Validation

Kurtosis-Orbit validates your configuration before deployment:

- Chain IDs must be positive and unique
- Private keys must match their addresses
- Challenge period must be positive
- Incompatible options are flagged

## Best Practices

1. **Use unique chain IDs** - Check [chainlist.org](https://chainlist.org) to avoid conflicts
2. **Secure your keys** - Never commit private keys to version control
3. **Test minimal first** - Start with basic config, add features incrementally
4. **Monitor resources** - Explorer and bridge require additional resources
5. **Document changes** - Keep track of configuration modifications

## Troubleshooting Configuration Issues

### "Invalid configuration" Error

- Check YAML syntax (proper indentation)
- Verify all required fields are present
- Ensure values are correct types (strings vs numbers)

### "Address mismatch" Error

- Private key must generate the provided address
- Use proper hex formatting (with 0x prefix)
- Check for typos in keys/addresses

### Services Not Starting

- Verify Docker images are accessible
- Check resource limits (RAM, disk space)
- Review service dependencies