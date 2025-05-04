# Kurtosis-Orbit

A Kurtosis package that deploys a full Arbitrum Orbit stack with a single command.

## Overview

Kurtosis-Orbit provides a one-command deployment of a complete Arbitrum Orbit environment for development and testing. It includes:

- A local Ethereum L1 chain
- Arbitrum Nitro L2 rollup chain (sequencer, validator, batch poster)
- Bridge contracts between L1 and L2
- Optional block explorer

This dramatically simplifies the setup process for developers who want to experiment with Arbitrum Orbit chains.

## Requirements

- Docker (>= 4.27.0 for Mac users)
- [Kurtosis CLI](https://docs.kurtosis.com/install)

## Quick Start

Deploy a default Orbit chain:

```bash
kurtosis run github.com/arbitrumfoundation/kurtosis-orbit
```

Deploy with custom configuration:

```bash
kurtosis run github.com/arbitrumfoundation/kurtosis-orbit --args-file orbit-config.yml
```

## Configuration

You can customize your Orbit chain by providing a YAML configuration file. Here's an example:

```yaml
orbit_config:
  chain_name: "MyOrbitChain"
  chain_id: 412346
  rollup_mode: "rollup"
  challenge_period_blocks: 20
  owner_private_key: "0x8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63"
  validator_count: 1
  enable_bridge: true
  enable_explorer: true
```

### Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `chain_name` | Name of the Orbit chain | "OrbitDevChain" |
| `chain_id` | Chain ID for the L2 | 412346 |
| `l1_chain_id` | Chain ID for the L1 devnet | 1337 |
| `rollup_mode` | "rollup" or "anytrust" | "rollup" |
| `challenge_period_blocks` | Number of blocks for challenge period | 20 |
| `stake_token` | Address of token used for staking | ETH (address 0) |
| `base_stake` | Minimum stake required | "0x0" |
| `owner_private_key` | Private key for chain owner | Default dev key |
| `validator_count` | Number of validators to run | 1 |
| `enable_bridge` | Enable token bridge | true |
| `enable_explorer` | Enable block explorer | false |
| `nitro_image` | Docker image for Nitro nodes | Latest stable version |

## Accessing Your Orbit Chain

After deployment, the connection information will be displayed:

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

To access the RPC endpoints from your host machine:

```bash
kurtosis port forward <enclave-name> orbit-sequencer rpc
```

## Development

To contribute to this package:

1. Clone the repository
2. Make your changes
3. Test locally with `kurtosis run .`
4. Submit a pull request

## License

Apache 2.0