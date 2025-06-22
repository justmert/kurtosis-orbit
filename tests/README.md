# Kurtosis-Orbit Helper Scripts

This directory contains comprehensive helper scripts for testing, interacting with, and managing your Arbitrum Orbit deployment. All scripts are designed to be flexible and configurable through environment variables and automatic port detection.

## 🚀 Quick Start

### Option 1: Auto-Detection (Recommended)

The scripts can automatically detect Kurtosis forwarded ports:

```bash
# Auto-setup environment with detected ports
npm run setup
```


## 📋 Available Scripts

### 1. Setup Environment (`setup-env.js`)

Automatically detects Kurtosis forwarded ports and creates environment configuration.

**Usage:**
```bash
npm run setup
```

### 2. Check Balances (`check-balances.js`)

Checks account balances on both L1 and L2 networks for all system and development accounts.

**Usage:**
```bash
# Using npm script (auto-detects ports)
npm run check-balances

# Direct execution with custom RPC URLs
node scripts/check-balances.js
```

### 3. Bridge ETH (`bridge-eth.js`)

Bridges ETH from L1 to L2 using real bridge contracts (not Arbitrum SDK).

**Usage:**
```bash
# Using npm script (bridges 0.1 ETH by default)
npm run bridge-eth

# Bridge custom amount with command line args
node scripts/bridge-eth.js <inbox_address> <amount> <l1_rpc> <l2_rpc> 
```

### 4. Deploy Contract (`deploy-contract.js`)

Deploys a smart contract to the L2 network with automatic compilation.

**Usage:**
```bash
# Deploy SimpleStorage with default initial value (123)
npm run deploy-contract
```

### 5. Interact with Contract (`interact-contract.js`)

Interacts with a previously deployed contract using multiple accounts.

**Usage:**
```bash
# Interact with deployed contract
npm run interact-contract
```

### 6. Generate Accounts (`generate-accounts.js`)

Generates new private keys and addresses for development use.

**Usage:**
```bash
# Generate 3 accounts (default)
npm run generate-accounts

# Generate custom number of accounts
node scripts/generate-accounts.js 5
```
