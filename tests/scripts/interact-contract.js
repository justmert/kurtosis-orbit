const { ethers } = require("ethers");
const { loadEnvironment } = require("./env-utils");
const fs = require("fs");
const path = require("path");

async function main() {
  console.log("=".repeat(60));
  console.log("🔧 Interacting with Deployed Contract");
  console.log("=".repeat(60));

  try {
    // Load environment variables
    loadEnvironment();

    // Configuration - can be overridden by command line args
    const contractName =
      process.argv[2] || process.env.CONTRACT_NAME || "SimpleStorage";
    const l2RpcUrl = process.env.L2_RPC_URL;

    if (!l2RpcUrl) {
      console.error("❌ L2_RPC_URL not found. Run: npm run setup");
      process.exit(1);
    }

    console.log(`\n⚙️  Configuration:`);
    console.log(`   Contract: ${contractName}`);
    console.log(`   L2 RPC: ${l2RpcUrl}`);
    console.log(`   Enclave: ${process.env.KURTOSIS_ENCLAVE || "unknown"}`);

    // Load deployment info
    const deploymentFile = path.join(`deployment.json`);

    if (!fs.existsSync(deploymentFile)) {
      console.error(`\n❌ No deployment found for ${contractName}!`);
      console.error(`   Expected file: ${deploymentFile}`);
      console.error(`   Please run 'npm run deploy-contract' first.`);
      process.exit(1);
    }

    const deploymentInfo = JSON.parse(fs.readFileSync(deploymentFile, "utf8"));
    console.log(`\n📄 Using deployment from: ${deploymentInfo.deployedAt}`);
    console.log(`   Contract address: ${deploymentInfo.contractAddress}`);

    // Create provider and signers
    const provider = new ethers.JsonRpcProvider(l2RpcUrl);

    // Use the funnel and sequencer accounts
    const funnelPrivateKey =
      "0xb6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659";
    const sequencerPrivateKey =
      "0xcb5790da63720727af975f42c79f69918580209889225fa7128c92402a6d3a65";

    const signer1 = new ethers.Wallet(funnelPrivateKey, provider);
    const signer2 = new ethers.Wallet(sequencerPrivateKey, provider);

    // Get contract instance using the ABI from deployment info
    const contract = new ethers.Contract(
      deploymentInfo.contractAddress,
      deploymentInfo.abi,
      signer1
    );

    console.log(`\n👥 Available accounts:`);
    console.log(`   Account 1: ${signer1.address}`);
    console.log(`   Account 2: ${signer2.address}`);

    // Check balances
    console.log(`\n💰 Account Balances:`);
    const balance1 = await provider.getBalance(signer1.address);
    const balance2 = await provider.getBalance(signer2.address);
    console.log(
      `   Account 1 (${signer1.address}): ${ethers.formatEther(balance1)} ETH`
    );
    console.log(
      `   Account 2 (${signer2.address}): ${ethers.formatEther(balance2)} ETH`
    );

    // Get network info
    const network = await provider.getNetwork();
    console.log(`   Chain ID: ${network.chainId}`);

    // Read current state
    console.log(`\n📖 Reading current contract state...`);
    const currentNumber = await contract.getNumber();
    const currentMessage = await contract.getMessage();
    const currentOwner = await contract.owner();

    console.log(`   Current number: ${currentNumber}`);
    console.log(`   Current message: "${currentMessage}"`);
    console.log(`   Current owner: ${currentOwner}`);

    // Update number
    console.log(`\n✏️  Updating stored number...`);
    const newNumber = Math.floor(Math.random() * 1000);
    console.log(`   New number: ${newNumber}`);

    const updateTx = await contract.setNumber(newNumber);
    console.log(`   Transaction hash: ${updateTx.hash}`);
    console.log(`   Waiting for confirmation...`);

    const updateReceipt = await updateTx.wait();
    console.log(
      `   ✅ Transaction confirmed in block ${updateReceipt.blockNumber}`
    );

    // Check events
    console.log(`\n📣 Checking events...`);
    const events = await contract.queryFilter(
      "NumberChanged",
      updateReceipt.blockNumber
    );

    if (events.length > 0) {
      const event = events[0];
      console.log(`   NumberChanged event emitted:`);
      console.log(`     Old number: ${event.args.oldNumber}`);
      console.log(`     New number: ${event.args.newNumber}`);
      console.log(`     Changed by: ${event.args.changer}`);
    }

    // Update message
    console.log(`\n📝 Updating stored message...`);
    const newMessage = `Updated at ${new Date().toISOString()}`;
    console.log(`   New message: "${newMessage}"`);

    // Wait a moment and get proper nonce
    await new Promise((resolve) => setTimeout(resolve, 1000));
    const currentNonce = await provider.getTransactionCount(
      signer1.address,
      "latest"
    );

    const messageTx = await contract.setMessage(newMessage, {
      nonce: currentNonce,
    });
    await messageTx.wait();
    console.log(`   ✅ Message updated successfully!`);

    // Try to update from different account
    console.log(`\n🔄 Testing update from different account...`);
    const contractAsSigner2 = contract.connect(signer2);

    try {
      const anotherNumber = Math.floor(Math.random() * 1000);
      console.log(`   Account 2 setting number to: ${anotherNumber}`);

      // Wait a moment and get proper nonce for account 2
      await new Promise((resolve) => setTimeout(resolve, 1000));
      const account2Nonce = await provider.getTransactionCount(
        signer2.address,
        "latest"
      );

      const tx2 = await contractAsSigner2.setNumber(anotherNumber, {
        nonce: account2Nonce,
      });
      await tx2.wait();

      console.log(`   ✅ Update successful!`);

      const finalNumber = await contract.getNumber();
      console.log(`   Final number: ${finalNumber}`);
    } catch (error) {
      console.log(`   ❌ Update failed: ${error.message}`);
      console.log(
        `   (This is normal - both accounts can update the contract)`
      );
    }

    // Get contract info
    console.log(`\n📊 Final contract info...`);
    const contractInfo = await contract.getInfo();
    console.log(`   Number: ${contractInfo[0]}`);
    console.log(`   Message: "${contractInfo[1]}"`);
    console.log(`   Owner: ${contractInfo[2]}`);
    console.log(`   Block: ${contractInfo[3]}`);
    console.log(`   Chain ID: ${contractInfo[4]}`);

    // Gas estimation
    console.log(`\n⛽ Estimating gas costs...`);
    const estimatedGas = await contract.setNumber.estimateGas(999);
    const gasPrice = await provider.getFeeData();

    console.log(`   Estimated gas: ${estimatedGas} units`);
    console.log(
      `   Current gas price: ${ethers.formatUnits(
        gasPrice.gasPrice,
        "gwei"
      )} gwei`
    );

    const estimatedCost = estimatedGas * gasPrice.gasPrice;
    console.log(`   Estimated cost: ${ethers.formatEther(estimatedCost)} ETH`);

    console.log("\n" + "=".repeat(60));
    console.log("✅ Contract interaction complete!");
  } catch (error) {
    console.error(`\n❌ Contract interaction failed: ${error.message}`);

    if (error.message.includes("insufficient funds")) {
      console.log("\n💡 Try running: npm run fund-accounts");
    } else if (error.message.includes("network")) {
      console.log("\n💡 Try running: npm run setup");
    } else if (error.message.includes("deployment")) {
      console.log("\n💡 Try running: npm run deploy-contract");
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
