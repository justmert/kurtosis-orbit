#!/usr/bin/env node

const { ethers } = require("ethers");

async function fundL2Account() {
  const args = process.argv.slice(2);

  if (args.length < 4) {
    console.log(
      "Usage: node fund-accounts.js <l2_rpc_url> <funnel_private_key> <recipient_address> <amount_eth>"
    );
    process.exit(1);
  }

  const [l2RpcUrl, funnelPrivateKey, recipientAddress, amountEth] = args;

  console.log(`Funding ${recipientAddress} with ${amountEth} ETH on L2`);

  let provider;
  try {
    // Connect to L2 RPC
    provider = new ethers.providers.JsonRpcProvider(l2RpcUrl);

    // Create wallet from funnel private key
    const wallet = new ethers.Wallet(funnelPrivateKey, provider);

    console.log(`Sending from: ${wallet.address}`);

    // Check funnel balance first
    const balance = await wallet.getBalance();
    const balanceEth = ethers.utils.formatEther(balance);
    console.log(`Funnel balance: ${balanceEth} ETH`);

    if (balance.eq(0)) {
      console.log("⚠️  Funnel account has no balance, skipping funding");
      return;
    }

    // Check if we have enough balance
    const amountWei = ethers.utils.parseEther(amountEth);
    if (balance.lt(amountWei)) {
      console.log(
        `⚠️  Not enough balance. Need ${amountEth} ETH, have ${balanceEth} ETH`
      );
      return;
    }

    // Send transaction
    console.log("Sending transaction...");
    const tx = await wallet.sendTransaction({
      to: recipientAddress,
      value: amountWei,
      gasLimit: 100000, // Higher gas limit for Arbitrum chains
    });

    console.log(`Transaction sent: ${tx.hash}`);

    // Wait for confirmation
    console.log("Waiting for confirmation...");
    const receipt = await tx.wait();
    console.log(`✅ Transaction confirmed in block ${receipt.blockNumber}`);
  } catch (error) {
    console.error(`❌ Error funding account: ${error.message}`);
    process.exit(1);
  } finally {
    if (provider) {
      provider.removeAllListeners();
    }
  }
}

fundL2Account();
