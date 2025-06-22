#!/usr/bin/env node

const { ethers } = require("ethers");

async function bridgeL1ToL2() {
  const args = process.argv.slice(2);

  if (args.length < 4) {
    console.log(
      "Usage: node bridge-l1-to-l2.js <l1_rpc_url> <l2_rpc_url> <funnel_private_key> <inbox_address> [amount_eth]"
    );
    process.exit(1);
  }

  const [
    l1RpcUrl,
    l2RpcUrl,
    funnelPrivateKey,
    inboxAddress,
    amountEth = "10000",
  ] = args;

  console.log(`🌉 Bridging ${amountEth} ETH from L1 to L2`);
  console.log(`L1 RPC: ${l1RpcUrl}`);
  console.log(`L2 RPC: ${l2RpcUrl}`);
  console.log(`Inbox: ${inboxAddress}`);

  let l1Provider, l2Provider;
  try {
    // Connect to L1
    l1Provider = new ethers.providers.JsonRpcProvider(l1RpcUrl);
    l2Provider = new ethers.providers.JsonRpcProvider(l2RpcUrl);

    // Create wallet from funnel private key
    const l1Wallet = new ethers.Wallet(funnelPrivateKey, l1Provider);
    const l2Wallet = new ethers.Wallet(funnelPrivateKey, l2Provider);

    console.log(`Funnel address: ${l1Wallet.address}`);

    // Check L1 balance
    const l1Balance = await l1Wallet.getBalance();
    const l1BalanceEth = ethers.utils.formatEther(l1Balance);
    console.log(`L1 balance: ${l1BalanceEth} ETH`);

    if (l1Balance.eq(0)) {
      console.log("❌ Funnel account has no L1 balance - cannot bridge");
      process.exit(1);
    }

    const amountWei = ethers.utils.parseEther(amountEth);
    let amountToUse;
    if (l1Balance.lt(amountWei)) {
      console.log(
        `⚠️  Not enough L1 balance. Need ${amountEth} ETH, have ${l1BalanceEth} ETH`
      );
      // Use available balance minus gas
      const gasEstimate = ethers.utils.parseEther("0.01"); // Reserve for gas
      const availableAmount = l1Balance.sub(gasEstimate);
      if (availableAmount.gt(0)) {
        console.log(
          `Using available balance: ${ethers.utils.formatEther(
            availableAmount
          )} ETH`
        );
        amountToUse = availableAmount;
      } else {
        console.log("❌ Insufficient balance even for gas");
        process.exit(1);
      }
    } else {
      amountToUse = amountWei;
    }

    // Get L2 balance before bridging
    const l2BalanceBefore = await l2Wallet.getBalance();
    console.log(
      `L2 balance before: ${ethers.utils.formatEther(l2BalanceBefore)} ETH`
    );

    // Bridge transaction - send ETH to inbox with specific data
    // This data is the same as used in nitro-testnode: depositEth function
    const bridgeData =
      "0x0f4d14e9000000000000000000000000000000000000000000000000000082f79cd90000";

    console.log("📤 Sending bridge transaction...");
    const bridgeTx = await l1Wallet.sendTransaction({
      to: inboxAddress,
      value: amountToUse,
      data: bridgeData,
      gasLimit: 300000,
    });

    console.log(`Transaction sent: ${bridgeTx.hash}`);

    // Wait for L1 confirmation
    console.log("⏳ Waiting for L1 confirmation...");
    const receipt = await bridgeTx.wait();
    console.log(`✅ L1 transaction confirmed in block ${receipt.blockNumber}`);

    // Wait for L2 balance to update
    console.log("⏳ Waiting for L2 balance to update...");
    const maxWaitTime = 120; // 2 minutes
    const checkInterval = 2; // 2 seconds

    for (let i = 0; i < maxWaitTime / checkInterval; i++) {
      const l2BalanceAfter = await l2Wallet.getBalance();
      const bridgedAmount = l2BalanceAfter.sub(l2BalanceBefore);

      if (bridgedAmount.gt(0)) {
        console.log(`✅ Bridge successful!`);
        console.log(
          `L2 balance after: ${ethers.utils.formatEther(l2BalanceAfter)} ETH`
        );
        console.log(
          `Bridged amount: ${ethers.utils.formatEther(bridgedAmount)} ETH`
        );
        return;
      }

      await new Promise((resolve) => setTimeout(resolve, checkInterval * 1000));
      if ((i + 1) % 5 === 0) {
        console.log(`Still waiting... (${i + 1} * ${checkInterval}s elapsed)`);
      }
    }

    console.log(
      "⚠️  Bridge transaction sent but L2 balance did not update within timeout"
    );
    console.log("This may be normal - the bridge might take longer to process");
  } catch (error) {
    console.error(`❌ Error bridging L1 to L2: ${error.message}`);
    process.exit(1);
  } finally {
    if (l1Provider) {
      l1Provider.removeAllListeners();
    }
    if (l2Provider) {
      l2Provider.removeAllListeners();
    }
  }
}

bridgeL1ToL2();
