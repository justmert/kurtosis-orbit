/**
 * Orbit Chain deployment script
 * 
 * This script uses the Arbitrum Orbit SDK to deploy an Orbit chain's core contracts
 * to the parent chain (Ethereum L1 in this case) and generate the chain configuration.
 */

const { ethers } = require('ethers');
const fs = require('fs');
const { 
  createPublicClient, 
  createWalletClient, 
  http, 
  parseEther 
} = require('viem');
const { 
  privateKeyToAccount,
  generatePrivateKey
} = require('viem/accounts');
const { 
  prepareChainConfig,
  createRollupPrepareDeploymentParamsConfig,
  createRollupPrepareTransactionRequest,
  createRollupPrepareTransactionReceipt
} = require('@arbitrum/orbit-sdk');

async function main() {
  try {
    console.log("Starting Orbit chain deployment...");
    
    // Get environment variables
    const rpcUrl = process.env.RPC_URL;
    const deployerPrivateKey = process.env.OWNER_KEY;
    const chainId = parseInt(process.env.CHAIN_ID);
    const chainName = process.env.CHAIN_NAME;
    const challengePeriodBlocks = parseInt(process.env.CHALLENGE_PERIOD);
    const stakeToken = process.env.STAKE_TOKEN;
    const baseStake = process.env.BASE_STAKE;
    const rollupMode = process.env.ROLLUP_MODE === 'anytrust';
    
    console.log(`Deploying ${chainName} (Chain ID: ${chainId})`);
    console.log(`RPC URL: ${rpcUrl}`);
    console.log(`Challenge Period: ${challengePeriodBlocks} blocks`);
    console.log(`Mode: ${rollupMode ? 'AnyTrust' : 'Rollup'}`);

    // Create a wallet from the private key
    const deployerAccount = privateKeyToAccount(deployerPrivateKey);
    
    // Connect to the parent chain
    const publicClient = createPublicClient({
      transport: http(rpcUrl)
    });
    
    const walletClient = createWalletClient({
      account: deployerAccount,
      transport: http(rpcUrl)
    });
    
    // Generate a validator key for fraud proofs
    // In production, this would be a separate secure key
    // For dev/test, we can use a randomly generated one
    const validatorPrivateKey = generatePrivateKey();
    const validatorAccount = privateKeyToAccount(validatorPrivateKey);
    
    console.log("Deployer address:", deployerAccount.address);
    console.log("Validator address:", validatorAccount.address);
    
    // Prepare chain configuration
    console.log("Preparing chain configuration...");
    const chainConfig = prepareChainConfig({
      chainId: chainId,
      chainName: chainName,
      arbitrum: {
        InitialChainOwner: deployerAccount.address,
        DataAvailabilityCommittee: rollupMode,
      }
    });
    
    // Prepare deployment parameters
    console.log("Preparing deployment parameters...");
    const config = createRollupPrepareDeploymentParamsConfig({
      chainId: chainId,
      owner: deployerAccount.address,
      chainConfig: chainConfig,
      nativeToken: stakeToken || "0x0000000000000000000000000000000000000000",
      deployFactoriesToL2: true,
      challengePeriodBlocks: challengePeriodBlocks,
      parentChainDeployment: {}, // Default to mainnet/protocol core contracts
      stakeToken: stakeToken || "0x0000000000000000000000000000000000000000",
      baseStake: BigInt(baseStake) || 0n,
      deployer: deployerAccount.address,
      maxDataSize: 104857n,
      maxFeePerGasForRetryables: 100000000000n, // 100 gwei
      publicClient
    });
    
    // Create the transaction request
    console.log("Creating deployment transaction...");
    const request = await createRollupPrepareTransactionRequest({
      params: {
        config,
        batchPosters: [deployerAccount.address],
        validators: [validatorAccount.address]
      },
      account: deployerAccount.address,
      publicClient
    });
    
    // Send the transaction
    console.log("Sending deployment transaction...");
    const hash = await walletClient.sendTransaction(request);
    
    console.log("Transaction hash:", hash);
    console.log("Waiting for transaction confirmation...");
    
    // Wait for transaction to be mined
    const receipt = await publicClient.waitForTransactionReceipt({ hash });
    
    // Process the transaction receipt
    console.log("Processing transaction receipt...");
    const rollupData = await createRollupPrepareTransactionReceipt({
      receipt,
      publicClient
    });
    
    console.log("Orbit chain core contracts deployed successfully!");
    console.log("Core contracts addresses:");
    console.log("- Rollup:", rollupData.rollupAddress);
    console.log("- Inbox:", rollupData.inboxAddress);
    console.log("- SequencerInbox:", rollupData.sequencerInboxAddress);
    console.log("- Bridge:", rollupData.bridgeAddress);
    
    // Generate chain info JSON for Nitro nodes
    const chainInfo = {
      "chain-id": chainId,
      "parent-chain-id": await publicClient.getChainId(),
      "parent-chain-is-arbitrum": false,
      "chain-name": chainName,
      "chain-config": chainConfig,
      "rollup": {
        "chain-id": chainId,
        "confirmPeriodBlocks": challengePeriodBlocks,
        "stake-token": stakeToken || "0x0000000000000000000000000000000000000000",
        "base-stake": baseStake || "0",
        "rollup-address": rollupData.rollupAddress,
        "inbox-address": rollupData.inboxAddress,
        "sequencer-inbox-address": rollupData.sequencerInboxAddress,
        "bridge-address": rollupData.bridgeAddress,
        "validators": [validatorAccount.address],
        "batch-poster": deployerAccount.address,
        "das-mode": rollupMode ? "anytrust" : "onchain"
      }
    };
    
    // Create contract addresses for the bridge deployment
    const contractAddresses = {
      rollup: rollupData.rollupAddress,
      inbox: rollupData.inboxAddress,
      sequencerInbox: rollupData.sequencerInboxAddress,
      bridge: rollupData.bridgeAddress,
      outbox: rollupData.outboxAddress,
      rollupCreator: rollupData.rollupCreatorAddress,
      validatorUtils: rollupData.validatorUtilsAddress
    };
    
    // Write output files
    console.log("Writing output files...");
    fs.writeFileSync('/app/chain-info.json', JSON.stringify(chainInfo, null, 2));
    fs.writeFileSync('/app/contract-addresses.json', JSON.stringify(contractAddresses, null, 2));
    fs.writeFileSync('/app/validator-key.txt', validatorPrivateKey);
    
    // Write deployment result
    fs.writeFileSync('/app/deployment-result.json', JSON.stringify({
      success: true,
      chainId: chainId,
      chainName: chainName,
      rollupAddress: rollupData.rollupAddress
    }, null, 2));
    
    console.log("Deployment completed successfully!");
    
  } catch (error) {
    console.error("Deployment failed:", error);
    
    // Write error to deployment result
    fs.writeFileSync('/app/deployment-result.json', JSON.stringify({
      success: false,
      error: error.message
    }, null, 2));
    
    process.exit(1);
  }
}

main();