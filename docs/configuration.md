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
| `pre_fund_accounts` | array | ["funnel", "sequencer", "validator", "l2owner"] | Standard accounts to fund |
| `prefund_addresses` | array | [] | Additional addresses to fund |

### Image Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `nitro_image` | string | "offchainlabs/nitro-node:v3.5.5-90ee45c" | Nitro node Docker image |
| `nitro_contracts_branch` | string | "v2.1.1-beta.0" | Contracts version |
| `token_bridge_branch` | string | "v1.2.2" | Token bridge version |

## Example Configurations

### Basic Development Setup

```yaml
orbit_config:
  chain_name: "DevChain"
  chain_id: 999888
  simple_mode: true
  enable_explorer: true
```

### Custom Token Configuration

```yaml
orbit_config:
  chain_name: "CustomTokenChain"
  chain_id: 777888
  
  # Use USDC as stake token (example)
  stake_token: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
  base_stake: "1000000000"  # 1000 USDC
  
  # Fund specific addresses
  prefund_addresses:
    - "0x742d35Cc6634C0532925a3b844Bc454e4438f44e"
    - "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199"
```
