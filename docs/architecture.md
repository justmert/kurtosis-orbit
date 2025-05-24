# Kurtosis-Orbit Architecture

This document explains the architecture and components of Kurtosis-Orbit.

## Overview

Kurtosis-Orbit orchestrates a complete Arbitrum Orbit deployment using Kurtosis's Starlark-based configuration language. The package automates the complex process of deploying an Arbitrum L2 chain on top of an Ethereum L1.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Kurtosis Engine                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Kurtosis-Orbit Package                  │   │
│  │                                                      │   │
│  │  ┌──────────┐  ┌──────────┐  ┌─────────────────┐  │   │
│  │  │ main.star│  │config.star│ │ ethereum.star   │  │   │
│  │  └─────┬────┘  └─────┬────┘  └────────┬────────┘  │   │
│  │        │             │                 │           │   │
│  │  ┌─────┴─────────────┴─────────────────┴────────┐  │   │
│  │  │          Orchestration Layer                  │  │   │
│  │  └───────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     Docker Containers                        │
│                                                              │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐   │
│  │   Geth L1   │  │Orbit Rollup  │  │ Orbit Sequencer │   │
│  │  (Ethereum) │  │  Contracts   │  │   (Nitro Node)  │   │
│  └─────────────┘  └──────────────┘  └─────────────────┘   │
│                                                              │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────┐   │
│  │  Validator  │  │Token Bridge  │  │   Blockscout    │   │
│  │(Nitro Node) │  │  Contracts   │  │   (Explorer)    │   │
│  └─────────────┘  └──────────────┘  └─────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Ethereum L1 Layer

**Service**: `el-1-geth-lighthouse`
- **Image**: `ethereum/client-go:stable`
- **Purpose**: Local Ethereum L1 blockchain
- **Configuration**: 
  - Chain ID: 1337 (default)
  - Block time: 3 seconds
  - Pre-funded accounts for deployment

### 2. Rollup Contracts

**Service**: `orbit-deployer`
- **Image**: Custom built from `rollupcreator/Dockerfile`
- **Purpose**: Deploy Arbitrum rollup contracts to L1
- **Contracts Deployed**:
  - Rollup contract
  - Bridge contract
  - Sequencer Inbox
  - Outbox
  - Challenge Manager

### 3. Nitro Nodes

#### Sequencer Node
**Service**: `orbit-sequencer`
- **Image**: `offchainlabs/nitro-node:v3.5.5-90ee45c`
- **Purpose**: Process transactions and produce blocks
- **Ports**: 
  - RPC: 8547
  - WebSocket: 8548
  - Feed: 9642

#### Validator Node
**Service**: `orbit-validator-0`
- **Image**: `offchainlabs/nitro-node:v3.5.5-90ee45c`
- **Purpose**: Validate blocks and submit fraud proofs
- **Configuration**: Connects to sequencer feed

#### Validation Node
**Service**: `validation-node`
- **Image**: `offchainlabs/nitro-node:v3.5.5-90ee45c`
- **Purpose**: WASM validation for fraud proofs
- **Note**: Only deployed if validators > 0

### 4. Token Bridge

**Service**: `token-bridge-deployer`
- **Image**: Custom built from `tokenbridge/Dockerfile`
- **Purpose**: Deploy token bridge contracts
- **Enables**: Asset transfers between L1 and L2

### 5. Block Explorer

**Service**: `blockscout` + `postgres`
- **Image**: `offchainlabs/blockscout:v1.1.0-0e716c8`
- **Purpose**: Web-based blockchain explorer
- **Port**: 4000

## Deployment Phases

### Phase 1: L1 Setup
1. Deploy local Ethereum L1 node
2. Wait for L1 to be ready
3. Fund deployment accounts

### Phase 2: Rollup Deployment
1. Build rollup configuration
2. Deploy rollup contracts to L1
3. Extract deployment artifacts

### Phase 3: Nitro Node Setup
1. Deploy validation node (if needed)
2. Deploy sequencer with chain configuration
3. Deploy validators with staking

### Phase 4: Token Bridge
1. Deploy bridge contracts on L1
2. Deploy bridge contracts on L2
3. Initialize bridge connections

### Phase 5: Explorer
1. Deploy PostgreSQL database
2. Deploy Blockscout indexer
3. Configure chain connections

