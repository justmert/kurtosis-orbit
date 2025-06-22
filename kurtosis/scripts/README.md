# L2 Funding Scripts

This directory contains Node.js scripts for funding Arbitrum Orbit L2 accounts during deployment.

## Scripts

### `bridge-l1-to-l2.js`
Bridge ETH from L1 to L2 using the inbox contract (similar to nitro-testnode's `bridge-funds` command).

**Usage:**
```bash
node bridge-l1-to-l2.js <l1_rpc_url> <l2_rpc_url> <funnel_private_key> <inbox_address> [amount_eth]
```

**Example:**
```bash
node bridge-l1-to-l2.js http://localhost:8545 http://localhost:8547 0x123... 0xabc... 5000
```

### `fund-accounts.js`
Single account funding script that transfers ETH from a funnel account to a recipient.

**Usage:**
```bash
node fund-accounts.js <l2_rpc_url> <funnel_private_key> <recipient_address> <amount_eth>
```

**Example:**
```bash
node fund-accounts.js http://localhost:8547 0x123... 0xabc... 10.5
```

### `fund-all.js`
Batch funding script that reads account configurations from a JSON file and funds all accounts.

**Usage:**
```bash
node fund-all.js <l2_rpc_url> <funnel_private_key> [accounts_file]
```

**Example:**
```bash
node fund-all.js http://localhost:8547 0x123... accounts.json
```

**Accounts JSON Format:**
```json
[
  {
    "name": "sequencer",
    "address": "0xe2148eE53c0755215Df69b2616E552154EdC584f",
    "amount": "1000"
  },
  {
    "name": "validator",
    "address": "0x6A568afe0f82d34759347bb36F14A6bB171d2CBe", 
    "amount": "1000"
  }
]
```

### `check-balances.js`
Balance verification script that checks ETH balances for all configured accounts.

**Usage:**
```bash
node check-balances.js <l2_rpc_url> [accounts_file]
```

**Example:**
```bash
node check-balances.js http://localhost:8547 accounts.json
```

## Dependencies

- **Node.js**: 20.x
- **ethers**: ^5.7.2

Install dependencies:
```bash
yarn install
```

## Deployment Integration

These scripts are automatically used during Kurtosis Orbit deployment:

1. **Phase 5**: L2 funding service is deployed in a Node.js container
2. **Bridging**: `bridge-l1-to-l2.js` bridges ETH from L1 to L2 for the funnel account
3. **Funding**: `fund-all.js` funds all configured accounts from the funnel account
4. **Verification**: `check-balances.js` verifies successful funding

## Funding Flow

The funding process follows the same pattern as nitro-testnode:

1. **L1 Genesis**: Funnel account starts with ETH on L1 (from genesis/prefunding)
2. **L1→L2 Bridge**: Bridge ETH from L1 to L2 using inbox contract
3. **L2 Funding**: Use funnel account to fund other L2 accounts
4. **Verification**: Check that all accounts have the expected balances

This mirrors the nitro-testnode commands:
- `bridge-funds` → `bridge-l1-to-l2.js`
- `send-l2` → `fund-accounts.js`

## Error Handling

- Scripts continue execution if individual accounts fail to fund
- Detailed logging shows success/failure for each account
- Non-zero exit codes indicate critical failures
- Graceful handling of insufficient balances
- Bridge timeouts are handled gracefully

## Security Notes

- Private keys are passed as command line arguments (consider environment variables for production)
- Scripts validate account balances before attempting transfers
- Transaction confirmations are awaited before proceeding
- Provider connections are properly cleaned up 