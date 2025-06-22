#!/usr/bin/env node

const { ethers } = require("ethers");
const { loadEnvironment } = require("./env-utils");

// Load contract source code from file
function loadContractSource() {
  const fs = require("fs");
  const path = require("path");
  const contractPath = path.join(__dirname, "contracts", "SimpleStorage.sol");

  if (!fs.existsSync(contractPath)) {
    throw new Error(`Contract file not found: ${contractPath}`);
  }

  return fs.readFileSync(contractPath, "utf8");
}

async function compileContract() {
  const solc = require("solc");
  const contractSource = loadContractSource();

  const input = {
    language: "Solidity",
    sources: {
      "SimpleStorage.sol": {
        content: contractSource,
      },
    },
    settings: {
      outputSelection: {
        "*": {
          "*": ["abi", "evm.bytecode"],
        },
      },
    },
  };

  const output = JSON.parse(solc.compile(JSON.stringify(input)));

  if (output.errors) {
    const errors = output.errors.filter((error) => error.severity === "error");
    if (errors.length > 0) {
      throw new Error(
        `Compilation failed: ${errors.map((e) => e.message).join("\n")}`
      );
    }
  }

  const contract = output.contracts["SimpleStorage.sol"]["SimpleStorage"];
  return {
    abi: contract.abi,
    bytecode: contract.evm.bytecode.object,
  };
}

async function main() {
  console.log("=".repeat(60));
  console.log("🚀 Deploying Smart Contract to Orbit Chain");
  console.log("=".repeat(60));

  // Load environment variables
  loadEnvironment();

  // Configuration
  const l2RpcUrl = process.env.L2_RPC_URL;
  const initialValue = process.env.INITIAL_VALUE || "123";

  if (!l2RpcUrl) {
    console.error("❌ L2_RPC_URL not found. Run: npm run setup");
    process.exit(1);
  }

  console.log(`\n⚙️  Configuration:`);
  console.log(`   L2 RPC: ${l2RpcUrl}`);
  console.log(`   Initial Value: ${initialValue}`);
  console.log(`   Enclave: ${process.env.KURTOSIS_ENCLAVE || "unknown"}`);

  try {
    // Compile contract
    console.log(`\n📄 Compiling SimpleStorage contract...`);
    const { abi, bytecode } = await compileContract();
    console.log(`   ✅ Contract compiled successfully`);
    console.log(`   Bytecode size: ${bytecode.length / 2} bytes`);

    // Create provider and signer
    const provider = new ethers.JsonRpcProvider(l2RpcUrl);

    // Use the funnel account for deployment (has plenty of ETH)
    const deployerPrivateKey =
      "0xb6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659";
    const signer = new ethers.Wallet(deployerPrivateKey, provider);

    console.log(`\n👤 Deployer Account:`);
    console.log(`   Address: ${signer.address}`);

    // Check balance
    const balance = await provider.getBalance(signer.address);
    console.log(`   Balance: ${ethers.formatEther(balance)} ETH`);

    if (balance === 0n) {
      throw new Error(
        "Deployer account has no ETH. Run funding scripts first."
      );
    }

    // Get network info
    const network = await provider.getNetwork();
    console.log(`   Chain ID: ${network.chainId}`);

    // Create contract factory
    console.log(`\n📄 Preparing contract deployment...`);
    const contractFactory = new ethers.ContractFactory(abi, bytecode, signer);

    // Estimate gas
    console.log(`   Estimating deployment gas...`);
    const deploymentTx = await contractFactory.getDeployTransaction(
      initialValue
    );
    const gasEstimate = await provider.estimateGas(deploymentTx);
    const feeData = await provider.getFeeData();

    console.log(`   Estimated gas: ${gasEstimate} units`);
    console.log(
      `   Gas price: ${ethers.formatUnits(feeData.gasPrice, "gwei")} gwei`
    );

    const estimatedCost = gasEstimate * feeData.gasPrice;
    console.log(`   Estimated cost: ${ethers.formatEther(estimatedCost)} ETH`);

    // Deploy contract
    console.log(`\n🚀 Deploying contract...`);
    const contract = await contractFactory.deploy(initialValue);

    console.log(
      `   Transaction hash: ${contract.deploymentTransaction().hash}`
    );
    console.log(`   Waiting for confirmation...`);

    // Wait for deployment
    await contract.waitForDeployment();
    const contractAddress = await contract.getAddress();

    console.log(`   ✅ Contract deployed successfully!`);
    console.log(`   Contract address: ${contractAddress}`);

    // Verify deployment by calling methods
    console.log(`\n🔍 Verifying deployment...`);
    const deployedNumber = await contract.getNumber();
    const deployedMessage = await contract.getMessage();
    console.log(`   Initial number: ${deployedNumber}`);
    console.log(`   Initial message: "${deployedMessage}"`);

    const contractInfo = await contract.getInfo();
    console.log(`   Contract info:`);
    console.log(`     Number: ${contractInfo[0]}`);
    console.log(`     Message: "${contractInfo[1]}"`);
    console.log(`     Owner: ${contractInfo[2]}`);
    console.log(`     Block: ${contractInfo[3]}`);
    console.log(`     Chain ID: ${contractInfo[4]}`);

    // Test contract interaction
    console.log(`\n🔄 Testing contract interaction...`);
    const newNumber = Math.floor(Math.random() * 1000);
    console.log(`   Setting number to: ${newNumber}`);

    // Wait a moment for the deployment transaction to be fully processed
    console.log(`   Waiting for deployment to finalize...`);
    await new Promise((resolve) => setTimeout(resolve, 2000));

    // Get current nonce to avoid nonce conflicts - use "latest" instead of "pending"
    const currentNonce = await provider.getTransactionCount(
      signer.address,
      "latest"
    );
    console.log(`   Current nonce: ${currentNonce}`);

    const updateTx = await contract.setNumber(newNumber, {
      nonce: currentNonce,
    });
    console.log(`   Update transaction: ${updateTx.hash}`);
    await updateTx.wait();

    const updatedNumber = await contract.getNumber();
    console.log(`   Updated number: ${updatedNumber}`);
    console.log(`   ✅ Contract interaction successful!`);

    // Save deployment info
    const contractSource = loadContractSource();
    const deploymentInfo = {
      contractAddress,
      deployerAddress: signer.address,
      transactionHash: contract.deploymentTransaction().hash,
      initialValue,
      chainId: network.chainId.toString(),
      deployedAt: new Date().toISOString(),
      rpcUrl: l2RpcUrl,
      abi: abi,
      bytecode: bytecode,
      contractSource: contractSource,
    };

    // Write to file for other scripts to use
    const fs = require("fs");
    fs.writeFileSync(
      "deployment.json",
      JSON.stringify(deploymentInfo, null, 2)
    );

    console.log(`\n💾 Deployment info saved to deployment.json`);

    // Explorer link if available
    if (process.env.EXPLORER_URL) {
      console.log(`\n🔍 View in explorer:`);
      console.log(`   ${process.env.EXPLORER_URL}/address/${contractAddress}`);
    }

    console.log(`\n📚 Contract ABI:`);
    console.log(`   Saved in deployment.json for use with other tools`);

    console.log("\n" + "=".repeat(60));
    console.log("✅ Smart contract deployment complete!");
    console.log(`Contract address: ${contractAddress}`);
    console.log("You can now interact with your contract using:");
    console.log("- The contract address above");
    console.log("- ABI from deployment.json");
    console.log("- Or create an interact-contract script");
  } catch (error) {
    console.error(`\n❌ Deployment failed: ${error.message}`);

    if (error.message.includes("insufficient funds")) {
      console.log("\n💡 Try running: npm run fund-accounts");
    } else if (error.message.includes("network")) {
      console.log("\n💡 Try running: npm run setup");
    } else if (error.message.includes("Compilation")) {
      console.log("\n💡 Solidity compilation failed. Check contract syntax.");
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
