# Account Management

This guide explains the account system used in Kurtosis-Orbit.

## Overview

Kurtosis-Orbit uses a deterministic account system compatible with Arbitrum's nitro-testnode. All accounts are derived from a standard mnemonic, ensuring predictable addresses across deployments.

## Standard Mnemonic

```
indoor dish desk flag debris potato excuse depart ticket judge file exit
```

**⚠️ WARNING**: This mnemonic is public and for development only. Never use it for real value!

## Default Accounts

### System Accounts

These accounts have special roles in the Orbit chain:

#### Funnel Account
- **Address**: `0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E`
- **Private Key**: `b6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659`
- **Purpose**: General funding and testing
- **Balance**: 1000 ETH on L1 and L2

#### Sequencer Account
- **Address**: `0xe2148eE53c0755215Df69b2616E552154EdC584f`
- **Private Key**: `cb5790da63720727af975f42c79f69918580209889225fa7128c92402a6d3a65`
- **Purpose**: Operates the sequencer node
- **Balance**: 1000 ETH on L1 and L2

#### Validator Account
- **Address**: `0x6A568afe0f82d34759347bb36F14A6bB171d2CBe`
- **Private Key**: `182fecf15bdf909556a0f617a63e05ab22f1493d25a9f1e27c228266c772a890`
- **Purpose**: Operates validator nodes
- **Balance**: 1000 ETH on L1 and L2

#### L2 Owner Account
- **Address**: `0x5E1497dD1f08C87b2d8FE23e9AAB6c1De833D927`
- **Private Key**: `dc04c5399f82306ec4b4d654a342f40e2e0620fe39950d967e1e574b32d4dd36`
- **Purpose**: Owns the L2 chain contracts
- **Balance**: 1000 ETH on L1 and L2

#### L3 Owner Account
- **Address**: `0x863c904166E801527125D8672442D736194A3362`
- **Private Key**: `ecdf21cb41c65afb51f91df408b7656e2c8739a5877f2814add0afd780cc210e`
- **Purpose**: Reserved for L3 deployments
- **Balance**: 1000 ETH on L1

#### L3 Sequencer Account
- **Address**: `0x3E6134aAD4C4d422FF2A4391Dc315c4DDf98D1a5`
- **Private Key**: `90f899754eb42949567d3576224bf533a20857bf0a60318507b75fcb3edc6f5f`
- **Purpose**: Reserved for L3 deployments
- **Balance**: 1000 ETH on L1

## Using Accounts

### Import to MetaMask

1. Open MetaMask
2. Click account icon → Import Account
3. Select "Private Key"
4. Paste the private key
5. Click Import

### Using with Hardhat

```javascript
// hardhat.config.js
module.exports = {
  networks: {
    orbit: {
      url: "http://localhost:PORT",  // Your forwarded port
      accounts: [
        "b6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659", // funnel
        "cb5790da63720727af975f42c79f69918580209889225fa7128c92402a6d3a65", // sequencer
        "182fecf15bdf909556a0f617a63e05ab22f1493d25a9f1e27c228266c772a890", // validator
      ],
      chainId: 412346
    }
  }
};
```

### Using with Foundry

```bash
# Set up environment
export PRIVATE_KEY=b6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659
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

// Connect to your Orbit chain
const provider = new ethers.providers.JsonRpcProvider('http://localhost:PORT');

// Use a funded account
const privateKey = 'b6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659';
const wallet = new ethers.Wallet(privateKey, provider);

// Send transaction
const tx = await wallet.sendTransaction({
  to: '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
  value: ethers.utils.parseEther('1.0')
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
  
  # Pre-fund your accounts
  prefund_addresses:
    - "0xYOUR_ADDRESS_1"
    - "0xYOUR_ADDRESS_2"
```

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
2. **Don't commit private keys** - Use environment variables
3. **Rotate test accounts** - Generate new ones periodically

### Production Considerations

1. **Generate secure keys** - Use hardware security modules
2. **Multi-signature wallets** - For admin operations
3. **Key management** - Use proper key storage solutions
4. **Access control** - Implement role-based permissions

## Funding Accounts

### Pre-funding on Deployment

Accounts can be pre-funded during deployment:

```yaml
orbit_config:
  # Fund standard accounts
  pre_fund_accounts: ["funnel", "sequencer", "validator", "l2owner"]
  
  # Fund additional addresses (100 ETH each)
  prefund_addresses:
    - "0x742d35Cc6634C0532925a3b844Bc454e4438f44e"
    - "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199"
```

### Manual Funding

After deployment, use the funnel account to fund others:

```bash
# Using cast (Foundry)
cast send --rpc-url http://localhost:PORT \
  --private-key b6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659 \
  0xRECIPIENT_ADDRESS \
  --value 10ether
```

## Troubleshooting

### "Insufficient funds" Error

1. Check you're using a funded account
2. Verify you're on the correct network (L1 vs L2)
3. Ensure account has ETH for gas

### "Invalid private key" Error

1. Check key format (should NOT start with 0x)
2. Verify key length (64 hex characters)
3. Ensure no extra spaces or characters

### Account Not Recognized

1. Verify address matches private key
2. Check capitalization (addresses are case-insensitive)
3. Ensure proper formatting 