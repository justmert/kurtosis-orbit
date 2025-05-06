/**
 * Create Rollup Script for Kurtosis-Orbit
 * 
 * This script uses the Arbitrum Orbit SDK to create a new Orbit chain.
 */

const { ethers } = require('ethers');
const fs = require('fs');
const { OrbitChainParams, createChain } = require('@arbitrum/orbit-sdk');

async function main() {
  console.log('=== Creating Arbitrum Orbit Chain ===');
  
  // Check environment variables
  const requiredEnvVars = [
    'PARENT_CHAIN_RPC',
    'DEPLOYER_PRIVKEY',
    'PARENT_CHAIN_ID',
    'CHILD_CHAIN_NAME',
    'MAX_DATA_SIZE',
    'OWNER_ADDRESS',
    'SEQUENCER_ADDRESS',
    'CHILD_CHAIN_CONFIG_PATH',
    'CHAIN_DEPLOYMENT_INFO',
    'CHILD_CHAIN_INFO'
  ];
  
  for (const envVar of requiredEnvVars) {
    if (!process.env[envVar]) {
      console.error(`Missing required environment variable: ${envVar}`);
      process.exit(1);
    }
  }
  
  try {
    // Read chain configuration
    const configPath = process.env.CHILD_CHAIN_CONFIG_PATH;
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    console.log('Chain configuration:', JSON.stringify(config, null, 2));
    
    // Connect to parent chain
    const parentProvider = new ethers.providers.JsonRpcProvider(process.env.PARENT_CHAIN_RPC);
    const deployer = new ethers.Wallet(process.env.DEPLOYER_PRIVKEY, parentProvider);
    console.log(`Deployer address: ${deployer.address}`);
    
    // Check parent chain connection
    const parentChainId = await parentProvider.getNetwork().then(n => n.chainId);
    console.log(`Connected to parent chain with ID: ${parentChainId}`);
    const expectedChainId = parseInt(process.env.PARENT_CHAIN_ID);
    if (parentChainId !== expectedChainId) {
      console.warn(`Warning: Connected to chain ID ${parentChainId}, but expected ${expectedChainId}`);
    }
    
    // Create chain parameters
    const params = new OrbitChainParams({
      chainId: config.chainId,
      chainName: config.chainName,
      parentChainId: parentChainId,
      parentChainSignerUrl: process.env.PARENT_CHAIN_RPC,
      parentChainWsUrl: undefined, // Optional
      maxDataSize: parseInt(process.env.MAX_DATA_SIZE),
      challengePeriodBlocks: config.challengePeriodBlocks,
      stakeToken: config.stakeToken,
      baseStake: config.baseStake,
      dataAvailabilityMode: config.dataAvailabilityMode || 'rollup',
    });
    
    console.log('Creating Orbit chain with params:', params);
    
    // Create the chain
    const deploymentData = await createChain({
      params,
      privateKey: process.env.DEPLOYER_PRIVKEY,
      ownerAddress: process.env.OWNER_ADDRESS,
      sequencerAddress: process.env.SEQUENCER_ADDRESS,
    });
    
    console.log('Deployment data:', deploymentData);
    
    // Save deployment data
    fs.writeFileSync(process.env.CHAIN_DEPLOYMENT_INFO, JSON.stringify(deploymentData, null, 2));
    
    // Create chain information for nodes
    const chainInfo = [{
      "chain-id": config.chainId,
      "parent-chain-id": parentChainId,
      "parent-chain-is-arbitrum": false,
      "chain-name": config.chainName,
      "rollup": {
        "bridge": deploymentData.bridge,
        "inbox": deploymentData.inbox,
        "sequencer-inbox": deploymentData.sequencerInbox,
        "rollup": deploymentData.rollup,
        "validator-utils": deploymentData.validatorUtils,
        "validator-wallet-creator": deploymentData.validatorWalletCreator,
        "deployed-at": deploymentData.deployedBlockNumber
      },
      "consensus": {
        "is-sequencer": false
      },
      "genesis": {
        "l1-base-block-num": deploymentData.deployedBlockNumber,
        "l1-base-block-hash": deploymentData.deployedBlockHash,
        "timestamp": Math.floor(Date.now() / 1000)
      }
    }];
    
    // Save chain info
    fs.writeFileSync(process.env.CHILD_CHAIN_INFO, JSON.stringify(chainInfo, null, 2));
    
    console.log('=== Orbit Chain Created Successfully ===');
    console.log(`Chain ID: ${config.chainId}`);
    console.log(`Chain Name: ${config.chainName}`);
    console.log(`Rollup Address: ${deploymentData.rollup}`);
    console.log(`Bridge Address: ${deploymentData.bridge}`);
    console.log(`Inbox Address: ${deploymentData.inbox}`);
    console.log(`Sequencer Inbox Address: ${deploymentData.sequencerInbox}`);
    
  } catch (error) {
    console.error('Error creating Orbit chain:', error);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('Unexpected error:', error);
    process.exit(1);
  });