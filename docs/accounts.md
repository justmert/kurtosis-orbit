# Account Management

This guide explains the account system used in Kurtosis-Orbit.

## Overview

Kurtosis-Orbit uses a deterministic account system compatible with Arbitrum's nitro-testnode. All accounts are derived from a standard mnemonic, ensuring predictable addresses across deployments.

## Standard Mnemonic

```
indoor dish desk flag debris potato excuse depart ticket judge file exit
```

**⚠️ WARNING**: This mnemonic is public and for development only. Never use it for real value!

## Prefunded Accounts

All prefunded accounts receive ETH on both L1 and L2 chains during deployment. The system manages three types of accounts:

### System Accounts

These accounts have special roles in the Orbit chain and are automatically funded:

| Account | Address | Private Key | L1 Balance | L2 Balance | Purpose |
|---------|---------|-------------|------------|------------|---------|
| **Funnel** | `0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E` | `b6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659` | 10000 ETH | 10000 ETH | General funding and testing (high balance to fund other accounts) |
| **Sequencer** | `0xe2148eE53c0755215Df69b2616E552154EdC584f` | `cb5790da63720727af975f42c79f69918580209889225fa7128c92402a6d3a65` | 100 ETH | 100 ETH | Operates the sequencer node |
| **Validator** | `0x6A568afe0f82d34759347bb36F14A6bB171d2CBe` | `182fecf15bdf909556a0f617a63e05ab22f1493d25a9f1e27c228266c772a890` | 100 ETH | 100 ETH | Operates validator nodes |
| **L2 Owner** | `0x5E1497dD1f08C87b2d8FE23e9AAB6c1De833D927` | `dc04c5399f82306ec4b4d654a342f40e2e0620fe39950d967e1e574b32d4dd36` | 100 ETH | 100 ETH | Owns the L2 chain contracts |
| **L3 Owner** | `0x863c904166E801527125D8672442D736194A3362` | `ecdf21cb41c65afb51f91df408b7656e2c8739a5877f2814add0afd780cc210e` | 100 ETH | 100 ETH | Reserved for L3 deployments |
| **L3 Sequencer** | `0x3E6134aAD4C4d422FF2A4391Dc315c4DDf98D1a5` | `90f899754eb42949567d3576224bf533a20857bf0a60318507b75fcb3edc6f5f` | 100 ETH | 100 ETH | Reserved for L3 deployments |

### Default Development Accounts


| Address | Private Key | Description |
|---------|-------------|-------------|
| `0x2093882c87B768469fbD434973bc7a4d20f73a51` | `e81662053657623793d767b6cb13e614f6c6916b1488de33928baea8ce513c4c` | Development account 1 |
| `0x6D819ceDC7B20b8F755Ec841CBd5934812Cbe13b` | `203298e6a2b845c6dde179f3f991ae4c081ad963e20c9fe39d45893c00a0aea5` | Development account 2 |
| `0xCE46e65a7A7527499e92337E5FBf958eABf314fa` | `237112963af91b42ca778fbe434a819b7e862cd025be3c86ce453bdd3e633165` | Development account 3 |
| `0xdafa61604B4Aa82092E1407F8027c71026982E6f` | `dbd4bf6a5edb48b1819a2e94920c156ff8296670d5df72e4b8a22df0b6ce573d` | Development account 4 |
| `0x1663f734483ceCB07AD6BC80919eA9a5cdDb7FE9` | `ae804cd43a8471813628b123189674469b92e3874674e540b9567e9e986d394d` | Development account 5 |


### Custom Funded Accounts

You can add additional addresses to be funded during deployment:

```yaml
orbit_config:
  prefund_addresses:
    - "0xYOUR_ADDRESS_1"
    - "0xYOUR_ADDRESS_2"
    # Or add development accounts for automatic funding:
    - "0x2093882c87B768469fbD434973bc7a4d20f73a51"  # Dev Account 1
    - "0x6D819ceDC7B20b8F755Ec841CBd5934812Cbe13b"  # Dev Account 2
```

Each custom address will receive 100 ETH on both L1 and L2.

## Configuration Options

### Adjusting Balances

You can customize the ETH balance for standard accounts (defaults shown):

```yaml
orbit_config:
  standard_account_balance_l1: "100"  # ETH on L1 (default: 100)
  standard_account_balance_l2: "100"  # ETH on L2 (default: 100)
```

**Note**: The funnel account automatically receives 10,000 ETH on both chains to fund other accounts.

### Selecting Which Accounts to Fund

By default, these standard accounts are funded:

```yaml
orbit_config:
  pre_fund_accounts: ["funnel", "sequencer", "validator", "l2owner"]
```

You can modify this list to include only the accounts you need.

## Using Accounts

### Import to MetaMask

1. Open MetaMask
2. Click account icon → Import Account
3. Select "Private Key"
4. Paste the private key (with or without 0x prefix)
5. Click Import

### Using with Hardhat

```javascript
// hardhat.config.js
module.exports = {
  networks: {
    orbit: {
      url: "http://localhost:PORT",  // Your forwarded port
      accounts: [
        "0xb6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659", // funnel
        "0xcb5790da63720727af975f42c79f69918580209889225fa7128c92402a6d3a65", // sequencer
        "0x182fecf15bdf909556a0f617a63e05ab22f1493d25a9f1e27c228266c772a890", // validator
      ],
      chainId: 412346
    }
  }
};
```

### Using with Foundry

```bash
# Set up environment
export PRIVATE_KEY=0xb6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659
export RPC_URL=http://localhost:PORT

# Deploy contract
forge create --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  src/MyContract.sol:MyContract

# Send transaction
cast send --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  0xTARGET_ADDRESS \
  "transfer(address,uint256)" \
  0xRECIPIENT 1ether
```

### Using with ethers.js

```javascript
const { ethers } = require('ethers');

// Connect to your Orbit chain (ethers v6 syntax)
const provider = new ethers.JsonRpcProvider('http://localhost:PORT');

// Use a funded account
const privateKey = '0xb6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659';
const wallet = new ethers.Wallet(privateKey, provider);

// Send transaction (ethers v6 syntax)
const tx = await wallet.sendTransaction({
  to: '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
  value: ethers.parseEther('1.0')  // Note: no .utils in v6
});
```

## Custom Account Configuration

### Using Your Own Accounts

You can override default accounts in your configuration:

```yaml
orbit_config:
  # Provide both private key and address
  owner_private_key: "YOUR_PRIVATE_KEY"
  owner_address: "0xYOUR_ADDRESS"  # Must match the private key!
  
  # Fund your custom accounts
  prefund_addresses:
    - "0xYOUR_ADDRESS_1"
    - "0xYOUR_ADDRESS_2"
```

**Important**: When providing custom keys, you must provide BOTH the private key and its corresponding address.

### Generating New Accounts

```javascript
// Generate a new random account
const wallet = ethers.Wallet.createRandom();
console.log('Address:', wallet.address);
console.log('Private Key:', wallet.privateKey);

// Generate from mnemonic
const mnemonic = "your twelve word mnemonic phrase goes here from wallet";
const wallet = ethers.Wallet.fromMnemonic(mnemonic);
```

## Account Security

### Development Best Practices

1. **Use only test accounts** - Never use real accounts with value
2. **Don't commit private keys** - Use environment variables for custom keys
3. **Rotate test accounts** - Generate new ones periodically
4. **Isolate test networks** - Keep development separate from production

### Production Considerations

1. **Generate secure keys** - Use hardware security modules (HSM)
2. **Multi-signature wallets** - For admin operations
3. **Key management** - Use proper key storage solutions (AWS KMS, HashiCorp Vault)
4. **Access control** - Implement role-based permissions
5. **Regular audits** - Monitor account activity

## Funding Additional Accounts

### During Deployment

Configure additional addresses to receive funds:

```yaml
orbit_config:
  prefund_addresses:
    - "0x742d35Cc6634C0532925a3b844Bc454e4438f44e"
    - "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199"
```

### After Deployment

Use the funnel account to fund others:

```bash
# Using cast (Foundry)
cast send --rpc-url http://localhost:PORT \
  --private-key 0xb6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659 \
  0xRECIPIENT_ADDRESS \
  --value 10ether

# Using the test scripts
cd tests
npm install
npm run check-balances  # Check current balances
```

## Troubleshooting

### "Insufficient funds" Error

1. Check you're using a funded account (run balance check)
2. Verify you're on the correct network (L1 vs L2)
3. Ensure account has ETH for gas fees

### "Invalid private key" Error

1. Check key format (64 hex characters)
2. Try with/without 0x prefix
3. Ensure no extra spaces or characters

### Account Not Recognized

1. Verify address matches private key
2. Check capitalization (addresses are case-insensitive)
3. Ensure proper hex formatting (0x prefix)

### Balance Not Showing

1. Wait for deployment to complete fully
2. Check if ports are properly forwarded
3. Verify RPC connection is working