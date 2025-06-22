#!/usr/bin/env node

const { ethers } = require("ethers");
const { loadEnvironment } = require("./env-utils");

async function main() {
  console.log("=".repeat(60));
  console.log("🌉 Bridging ETH from L1 to L2 (Real Bridge)");
  console.log("=".repeat(60));

  // Load environment variables
  loadEnvironment();

  // Configuration - accept CLI args or use environment
  const inboxAddress = process.argv[2] || process.env.INBOX_ADDRESS;
  const bridgeAmount = process.argv[3] || process.env.BRIDGE_AMOUNT || "0.1";
  const l1RpcUrl = process.argv[4] || process.env.L1_RPC_URL;
  const l2RpcUrl = process.argv[5] || process.env.L2_RPC_URL;

  if (!l1RpcUrl || !l2RpcUrl) {
    console.error("❌ L1_RPC_URL or L2_RPC_URL not found.");
    console.log(
      "Usage: node bridge-eth.js [l1_rpc_url] [l2_rpc_url] [inbox_address] [amount_eth]"
    );
    console.log("Or run: npm run setup");
    process.exit(1);
  }

  if (!inboxAddress) {
    console.error("❌ INBOX_ADDRESS not provided.");
    console.log("You need to provide the inbox contract address:");
    console.log(
      "Usage: node bridge-eth.js <l1_rpc_url> <l2_rpc_url> <inbox_address> [amount_eth]"
    );
    console.log("\nGet inbox address from deployment logs or:");
    console.log("kurtosis files download <enclave> chain-deployment-info");
    process.exit(1);
  }

  console.log(`\n⚙️  Configuration:`);
  console.log(`   L1 RPC: ${l1RpcUrl}`);
  console.log(`   L2 RPC: ${l2RpcUrl}`);
  console.log(`   Inbox Address: ${inboxAddress}`);
  console.log(`   Bridge Amount: ${bridgeAmount} ETH`);
  console.log(`   Enclave: ${process.env.KURTOSIS_ENCLAVE || "unknown"}`);

  try {
    // Create providers
    const l1Provider = new ethers.JsonRpcProvider(l1RpcUrl);
    const l2Provider = new ethers.JsonRpcProvider(l2RpcUrl);

    // Use the funnel account (has plenty of ETH)
    const funnelPrivateKey =
      "0xb6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659";
    const l1Wallet = new ethers.Wallet(funnelPrivateKey, l1Provider);
    const l2Wallet = new ethers.Wallet(funnelPrivateKey, l2Provider);

    console.log(`\n👤 Bridger Account:`);
    console.log(`   Address: ${l1Wallet.address}`);

    // Check initial balances
    console.log(`\n💰 Initial Balances:`);
    const l1BalanceBefore = await l1Provider.getBalance(l1Wallet.address);
    const l2BalanceBefore = await l2Provider.getBalance(l2Wallet.address);

    console.log(`   L1 Balance: ${ethers.formatEther(l1BalanceBefore)} ETH`);
    console.log(`   L2 Balance: ${ethers.formatEther(l2BalanceBefore)} ETH`);

    const amountWei = ethers.parseEther(bridgeAmount);

    if (l1BalanceBefore === 0n) {
      throw new Error("Funnel account has no L1 balance - cannot bridge");
    }

    // Determine amount to use
    let amountToUse;
    if (l1BalanceBefore < amountWei) {
      console.log(
        `⚠️  Not enough L1 balance. Need ${bridgeAmount} ETH, have ${ethers.formatEther(
          l1BalanceBefore
        )} ETH`
      );
      // Use available balance minus gas
      const gasReserve = ethers.parseEther("0.01"); // Reserve for gas
      const availableAmount = l1BalanceBefore - gasReserve;
      if (availableAmount > 0n) {
        console.log(
          `   Using available balance: ${ethers.formatEther(
            availableAmount
          )} ETH`
        );
        amountToUse = availableAmount;
      } else {
        throw new Error("Insufficient balance even for gas");
      }
    } else {
      amountToUse = amountWei;
    }

    // Get network info
    const l1Network = await l1Provider.getNetwork();
    const l2Network = await l2Provider.getNetwork();
    console.log(`   L1 Chain ID: ${l1Network.chainId}`);
    console.log(`   L2 Chain ID: ${l2Network.chainId}`);

    // Real bridge transaction using Arbitrum inbox
    console.log(`\n🌉 Bridge Process:`);
    console.log(
      `   Sending ${ethers.formatEther(
        amountToUse
      )} ETH to inbox: ${inboxAddress}`
    );

    // This is the depositEth function call data (same as nitro-testnode)
    const bridgeData =
      "0x0f4d14e9000000000000000000000000000000000000000000000000000082f79cd90000";

    // Estimate gas for the bridge transaction
    let gasEstimate;
    try {
      gasEstimate = await l1Provider.estimateGas({
        to: inboxAddress,
        value: amountToUse,
        data: bridgeData,
        from: l1Wallet.address,
      });
    } catch (error) {
      console.log(`⚠️  Gas estimation failed, using default: ${error.message}`);
      gasEstimate = 300000n;
    }

    const feeData = await l1Provider.getFeeData();
    console.log(`   Estimated gas: ${gasEstimate} units`);
    console.log(
      `   Gas price: ${ethers.formatUnits(feeData.gasPrice, "gwei")} gwei`
    );

    const estimatedCost = gasEstimate * feeData.gasPrice;
    console.log(
      `   Estimated gas cost: ${ethers.formatEther(estimatedCost)} ETH`
    );

    // Send bridge transaction
    console.log(`\n📤 Sending bridge transaction...`);
    const bridgeTx = await l1Wallet.sendTransaction({
      to: inboxAddress,
      value: amountToUse,
      data: bridgeData,
      gasLimit: gasEstimate,
    });

    console.log(`   Transaction hash: ${bridgeTx.hash}`);
    console.log(`   ⏳ Waiting for L1 confirmation...`);

    // Wait for L1 confirmation
    const receipt = await bridgeTx.wait();
    console.log(
      `   ✅ L1 transaction confirmed in block: ${receipt.blockNumber}`
    );
    console.log(`   Gas used: ${receipt.gasUsed}`);

    // Wait for L2 balance to update
    console.log(`\n📥 Waiting for L2 balance update...`);
    const maxWaitTime = 120; // 2 minutes
    const checkInterval = 3; // 3 seconds

    for (let i = 0; i < maxWaitTime / checkInterval; i++) {
      const l2BalanceAfter = await l2Provider.getBalance(l2Wallet.address);
      const bridgedAmount = l2BalanceAfter - l2BalanceBefore;

      if (bridgedAmount > 0n) {
        console.log(`   ✅ Bridge successful!`);
        console.log(
          `   L2 balance increased by: ${ethers.formatEther(bridgedAmount)} ETH`
        );

        // Show final balances
        const l1BalanceAfter = await l1Provider.getBalance(l1Wallet.address);
        console.log(`\n💰 Final Balances:`);
        console.log(`   L1 Balance: ${ethers.formatEther(l1BalanceAfter)} ETH`);
        console.log(`   L2 Balance: ${ethers.formatEther(l2BalanceAfter)} ETH`);

        // Save bridge info
        const bridgeInfo = {
          txHash: bridgeTx.hash,
          amount: ethers.formatEther(amountToUse),
          fromChainId: l1Network.chainId.toString(),
          toChainId: l2Network.chainId.toString(),
          account: l1Wallet.address,
          inboxAddress: inboxAddress,
          timestamp: new Date().toISOString(),
          l1Block: receipt.blockNumber,
          gasUsed: receipt.gasUsed.toString(),
          status: "completed",
        };

        const fs = require("fs");
        fs.writeFileSync("bridge.json", JSON.stringify(bridgeInfo, null, 2));
        console.log(`\n💾 Bridge info saved to bridge.json`);

        console.log("\n" + "=".repeat(60));
        console.log("✅ Real bridge transaction completed successfully!");
        console.log(
          `Bridged ${ethers.formatEther(amountToUse)} ETH from L1 to L2`
        );
        return;
      }

      await new Promise((resolve) => setTimeout(resolve, checkInterval * 1000));
      if ((i + 1) % 5 === 0) {
        console.log(
          `   Still waiting... (${(i + 1) * checkInterval}s elapsed)`
        );
      }
    }

    console.log(
      `\n⚠️  Bridge transaction sent but L2 balance did not update within ${maxWaitTime}s`
    );
    console.log("This may be normal - the bridge might take longer to process");
    console.log("Check the transaction status and L2 balance manually");
  } catch (error) {
    console.error(`\n❌ Bridge failed: ${error.message}`);

    if (error.message.includes("insufficient")) {
      console.log("\n💡 Try funding the account first: npm run fund-accounts");
    } else if (error.message.includes("inbox")) {
      console.log("\n💡 Make sure the inbox address is correct");
      console.log(
        "   Get it from: kurtosis files download <enclave> chain-deployment-info"
      );
    } else if (error.message.includes("network")) {
      console.log("\n💡 Try running: npm run setup");
    }

    if (process.env.DEBUG) {
      console.error("Full error:", error);
    }

    process.exit(1);
  }
}

// Export for testing
module.exports = { main };

// Run if called directly
if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}
