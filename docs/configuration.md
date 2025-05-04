# Configuration Options

This document details all available configuration options for Kurtosis Orbit deployments.

## Configuration File Structure

The configuration file is in YAML format and consists of several sections:

```yaml
l1:
  # L1 configuration options
orbit:
  # Orbit chain configuration options
bridge:
  # Token bridge configuration options
explorer:
  # Explorer configuration options
```

## L1 Configuration

| Option | Description | Default | Required |
|--------|-------------|---------|----------|
| `chain_id` | Chain ID of the L1 network | `1` (Mainnet) | No |
| `rpc_url` | HTTP RPC URL for the L1 | - | Yes (if not using local) |
| `ws_url` | WebSocket URL for the L1 | - | No |
| `local.enabled` | Deploy a local L1 node | `false` | No |
| `local.type` | Type of local node (`geth`) | `geth` | No |
| `local.version` | Version of the node software | `v1.12.0` | No |
| `local.chain_id` | Chain ID for local node | `1337` | No |
| `local.block_time` | Block time in seconds | `5` | No |
| `local.gas_limit` | Block gas limit | `30000000` | No |
| `local.premine` | Accounts to pre-fund | `[]` | No |

## Orbit Chain Configuration

| Option | Description | Default | Required |
|--------|-------------|---------|----------|
| `chain_id` | Chain ID of the Orbit chain | - | Yes |
| `name` | Human-readable name for the chain | `"Orbit-Chain"` | No |
| `consensus` | Consensus mechanism (`clique`) | `"clique"` | No |
| `block_time` | Block time in seconds | `2` | No |
| `gas_limit` | Block gas limit | `30000000` | No |
| `premine` | Accounts to pre-fund | `[]` | No |
| `validators` | Initial validator addresses | `[]` | Yes |
| `genesis_params` | Additional genesis parameters | `{}` | No |

### Premine Format

```yaml
premine:
  - address: "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199"
    amount: "1000000000000000000000"  # 1000 ETH in wei
```

## Token Bridge Configuration

| Option | Description | Default | Required |
|--------|-------------|---------|----------|
| `enabled` | Enable token bridge | `true` | No |
| `token_list` | List of tokens to bridge | `[]` | No |
| `custom_tokens` | Custom tokens to deploy | `[]` | No |
| `admin_address` | Bridge admin address | First validator | No |
| `gas_limit` | Gas limit for bridge txs | `2000000` | No |
| `confirmation_blocks` | Required confirmations | `12` | No |

### Token List Format

```yaml
token_list:
  - name: "WETH"
    address: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
  - name: "USDC"
    address: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
```

### Custom Token Format

```yaml
custom_tokens:
  - name: "TestToken"
    symbol: "TT"
    decimals: 18
    initial_supply: "1000000000000000000000000"
    cap: "10000000000000000000000000"
```

## Explorer Configuration

| Option | Description | Default | Required |
|--------|-------------|---------|----------|
| `enabled` | Enable block explorer | `true` | No |
| `rpc_polling_interval` | Polling interval in seconds | `3` | No |
| `port` | Explorer UI port | `4000` | No |
| `ui_theme` | UI theme (`light`/`dark`) | `"light"` | No |
| `features` | Enabled explorer features | All enabled | No |
| `admin` | Admin user configuration | `{}` | No |

## Example Configurations

See the [examples directory](../config/examples/) for sample configurations:

- [Basic Configuration](../config/examples/basic.yml) - Minimal setup
- [Full Configuration](../config/examples/full.yml) - All options demonstrated
