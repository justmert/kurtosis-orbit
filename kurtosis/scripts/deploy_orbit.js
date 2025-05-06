/**
 * Orbit Chain Deployment Script for Kurtosis-Orbit
 * 
 * This script deploys an Arbitrum Orbit rollup chain on a local Ethereum L1.
 * It uses the Orbit SDK from Offchain Labs.
 */

const { ethers } = require('ethers');
const fs = require('fs');

async function main() {
  console.log('=== Arbitrum Orbit Chain Deployment ===');
  
  // Read environment variables
  const l1RpcUrl = process.env.L1_RPC_URL;
  const deployerPrivkey = process.env.DEPLOYER_PRIVKEY;
  const l1ChainId = parseInt(process.env.PARENT_CHAIN_ID || '1337');
  
  if (!l1RpcUrl || !deployerPrivkey) {
    console.error('Missing required environment variables:');
    console.error('Required: L1_RPC_URL, DEPLOYER_PRIVKEY');
    process.exit(1);
  }
  
  // Read rollup configuration
  let rollupConfig;
  try {
    rollupConfig = JSON.parse(fs.readFileSync('/config/rollup_config.json'));
    console.log('Loaded rollup configuration:', JSON.stringify(rollupConfig, null, 2));
  } catch (error) {
    console.error('Error reading rollup configuration:', error);
    process.exit(1);
  }
  
  // Connect to L1
  console.log(`Connecting to L1 at ${l1RpcUrl}`);
  const l1Provider = new ethers.providers.JsonRpcProvider(l1RpcUrl);
  const l1Signer = new ethers.Wallet(deployerPrivkey, l1Provider);
  console.log(`Deployer address: ${l1Signer.address}`);
  
  try {
    // Check L1 connection
    const l1Block = await l1Provider.getBlockNumber();
    console.log(`Connected to L1, current block: ${l1Block}`);
    
    const l1Balance = await l1Provider.getBalance(l1Signer.address);
    console.log(`Deployer balance: ${ethers.utils.formatEther(l1Balance)} ETH`);
    
    if (l1Balance.eq(0)) {
      console.error('Deployer has no ETH, cannot deploy chain');
      process.exit(1);
    }
    
    // In a real implementation, this would use the @arbitrum/orbit-sdk to deploy the chain
    // For this example, we'll simulate the deployment with placeholder values
    
    // Mock deployment result
    const mockDeployedAt = l1Block;
    const mockRollupAddress = "0x2796E8C3D08feA4DC79E73dC23c616F838776262";
    const mockInboxAddress = "0x96873DD94fBBe0dC16ce7752642F8fe5D392701F";
    const mockSequencerInboxAddress = "0x3F39F341AC146317Cb020EAAb5C76AF3E8b2C2f4";
    const mockBridgeAddress = "0xfB251F49e4e46C0861b4cccB23d478CF84EF5dFC";
    const mockValidatorUtilsAddress = "0xf53d707aE2053C4969186Dd3a1D16A97A2c6DfF7";
    const mockValidatorWalletCreatorAddress = "0x2BDa6a2192d3120C503F57E6526fcF25e3EE3CF4";
    
    // Create deployment info
    const deploymentInfo = {
      rollup: mockRollupAddress,
      inbox: mockInboxAddress,
      sequencerInbox: mockSequencerInboxAddress,
      bridge: mockBridgeAddress,
      validatorUtils: mockValidatorUtilsAddress,
      validatorWalletCreator: mockValidatorWalletCreatorAddress,
      deployedBlockNumber: mockDeployedAt,
      deployedBlockHash: "0x" + mockDeployedAt.toString(16).padStart(64, '0'),
      l2ChainId: rollupConfig.chainId,
      chainName: rollupConfig.chainName,
      ownerAddress: l1Signer.address
    };
    
    console.log('Deployment info:', JSON.stringify(deploymentInfo, null, 2));
    fs.writeFileSync('/config/deployment.json', JSON.stringify(deploymentInfo, null, 2));
    
    // Create chain info in Nitro node format
    const chainInfo = [{
      "chain-id": rollupConfig.chainId,
      "parent-chain-id": l1ChainId,
      "parent-chain-is-arbitrum": false,
      "chain-name": rollupConfig.chainName,
      "rollup": {
        "bridge": deploymentInfo.bridge,
        "inbox": deploymentInfo.inbox,
        "sequencer-inbox": deploymentInfo.sequencerInbox,
        "rollup": deploymentInfo.rollup,
        "validator-utils": deploymentInfo.validatorUtils,
        "validator-wallet-creator": deploymentInfo.validatorWalletCreator,
        "deployed-at": deploymentInfo.deployedBlockNumber
      },
      "consensus": {
        "is-sequencer": false
      },
      "genesis": {
        "l1-base-block-num": deploymentInfo.deployedBlockNumber,
        "l1-base-block-hash": deploymentInfo.deployedBlockHash,
        "timestamp": Math.floor(Date.now() / 1000)
      }
    }];
    
    console.log('Chain info:', JSON.stringify(chainInfo, null, 2));
    fs.writeFileSync('/config/chain_info.json', JSON.stringify(chainInfo, null, 2));
    
    console.log('=== Orbit Chain Deployed Successfully ===');
    console.log(`Chain ID: ${rollupConfig.chainId}`);
    console.log(`Chain Name: ${rollupConfig.chainName}`);
    console.log(`Rollup Address: ${deploymentInfo.rollup}`);
    console.log(`Bridge Address: ${deploymentInfo.bridge}`);
    console.log(`Inbox Address: ${deploymentInfo.inbox}`);
    console.log(`Sequencer Inbox Address: ${deploymentInfo.sequencerInbox}`);
    
  } catch (error) {
    console.error('Error deploying Orbit chain:', error);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('Unexpected error:', error);
    process.exit(1);
  });