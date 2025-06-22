#!/usr/bin/env node

const { ethers } = require("hardhat");
const { loadEnvironment } = require("./env-utils");

async function main() {
  console.log("=".repeat(60));
  console.log("🔍 Checking Account Balances");
  console.log("=".repeat(60));

  // Load environment variables from .env file
  loadEnvironment();

  // Configuration - use environment variables or command line args
  let l1RpcUrl = process.argv[2] || process.env.L1_RPC_URL;
  let l2RpcUrl = process.argv[3] || process.env.L2_RPC_URL;

  // Fallback to defaults if no environment variables
  if (!l1RpcUrl) {
    console.log(
      "⚠️  L1_RPC_URL not found in environment. Run: node setup-env.js"
    );
    l1RpcUrl = "http://localhost:8545";
  }
  if (!l2RpcUrl) {
    console.log(
      "⚠️  L2_RPC_URL not found in environment. Run: node setup-env.js"
    );
    l2RpcUrl = "http://localhost:8547";
  }

  console.log(`\n⚙️  Configuration:`);
  console.log(`   L1 RPC: ${l1RpcUrl}`);
  console.log(`   L2 RPC: ${l2RpcUrl}`);
  console.log(`   Enclave: ${process.env.KURTOSIS_ENCLAVE || "unknown"}`);

  // Standard accounts from kurtosis-orbit
  const accounts = [
    {
      name: "Funnel",
      address: "0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E",
      privateKey:
        "0xb6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659",
      description: "General testing account",
    },
    {
      name: "Sequencer",
      address: "0xe2148eE53c0755215Df69b2616E552154EdC584f",
      privateKey:
        "0xcb5790da63720727af975f42c79f69918580209889225fa7128c92402a6d3a65",
      description: "Sequencer operations",
    },
    {
      name: "Validator",
      address: "0x6A568afe0f82d34759347bb36F14A6bB171d2CBe",
      privateKey:
        "0x182fecf15bdf909556a0f617a63e05ab22f1493d25a9f1e27c228266c772a890",
      description: "Validator operations",
    },
    {
      name: "L2 Owner",
      address: "0x5E1497dD1f08C87b2d8FE23e9AAB6c1De833D927",
      privateKey:
        "0xdc04c5399f82306ec4b4d654a342f40e2e0620fe39950d967e1e574b32d4dd36",
      description: "Chain ownership",
    },
    {
      name: "L3 Owner",
      address: "0x863c904166E801527125D8672442D736194A3362",
      privateKey:
        "0xecdf21cb41c65afb51f91df408b7656e2c8739a5877f2814add0afd780cc210e",
      description: "L3 chain owner (reserved)",
    },
    {
      name: "L3 Sequencer",
      address: "0x3E6134aAD4C4d422FF2A4391Dc315c4DDf98D1a5",
      privateKey:
        "0x90f899754eb42949567d3576224bf533a20857bf0a60318507b75fcb3edc6f5f",
      description: "L3 sequencer (reserved)",
    },
  ];

  // Add DEFAULT_PREFUNDED_ACCOUNTS from config.star
  const defaultPrefundedAccounts = [
    {
      name: "Dev Account 1",
      address: "0x2093882c87B768469fbD434973bc7a4d20f73a51",
      privateKey:
        "0xe81662053657623793d767b6cb13e614f6c6916b1488de33928baea8ce513c4c", // No private key available for these accounts
      description: "Development account 1 (100 ETH)",
    },
    {
      name: "Dev Account 2",
      address: "0x6D819ceDC7B20b8F755Ec841CBd5934812Cbe13b",
      privateKey:
        "0x203298e6a2b845c6dde179f3f991ae4c081ad963e20c9fe39d45893c00a0aea5",
      description: "Development account 2 (100 ETH)",
    },
    {
      name: "Dev Account 3",
      address: "0xCE46e65a7A7527499e92337E5FBf958eABf314fa",
      privateKey:
        "0x237112963af91b42ca778fbe434a819b7e862cd025be3c86ce453bdd3e633165",
      description: "Development account 3 (100 ETH)",
    },
    {
      name: "Dev Account 4",
      address: "0xdafa61604B4Aa82092E1407F8027c71026982E6f",
      privateKey:
        "0xdbd4bf6a5edb48b1819a2e94920c156ff8296670d5df72e4b8a22df0b6ce573d",
      description: "Development account 4 (100 ETH)",
    },
    {
      name: "Dev Account 5",
      address: "0x1663f734483ceCB07AD6BC80919eA9a5cdDb7FE9",
      privateKey:
        "0xae804cd43a8471813628b123189674469b92e3874674e540b9567e9e986d394d",
      description: "Development account 5 (100 ETH)",
    },
  ];

  // Combine all accounts
  const allAccounts = [...accounts, ...defaultPrefundedAccounts];

  try {
    // Create providers
    const l1Provider = new ethers.JsonRpcProvider(l1RpcUrl);
    const l2Provider = new ethers.JsonRpcProvider(l2RpcUrl);

    // Test connectivity
    console.log(`\n🌐 Testing connectivity...`);
    const l1ChainId = await l1Provider.getNetwork();
    const l2ChainId = await l2Provider.getNetwork();
    console.log(`   L1 Chain ID: ${l1ChainId.chainId}`);
    console.log(`   L2 Chain ID: ${l2ChainId.chainId}`);

    // Check balances
    console.log(`\n💰 Account Balances:`);
    console.log("=".repeat(100));
    console.log(
      `${"Account".padEnd(20)} ${"Address".padEnd(44)} ${"L1 Balance".padEnd(
        15
      )} ${"L2 Balance".padEnd(15)} ${"Private Key".padEnd(10)}`
    );
    console.log("=".repeat(100));

    for (const account of allAccounts) {
      try {
        const l1Balance = await l1Provider.getBalance(account.address);
        const l2Balance = await l2Provider.getBalance(account.address);

        const l1Eth = ethers.formatEther(l1Balance);
        const l2Eth = ethers.formatEther(l2Balance);
        const hasPrivateKey = account.privateKey ? "✅" : "❌";

        console.log(
          `${account.name.padEnd(20)} ${account.address.padEnd(44)} ${(
            l1Eth + " ETH"
          ).padEnd(15)} ${(l2Eth + " ETH").padEnd(15)} ${hasPrivateKey.padEnd(
            10
          )}`
        );
      } catch (error) {
        console.log(
          `${account.name.padEnd(20)} ${account.address.padEnd(
            44
          )} ${"ERROR".padEnd(15)} ${"ERROR".padEnd(15)} ${"?".padEnd(10)}`
        );
        if (process.env.DEBUG) {
          console.log(`   Error: ${error.message}`);
        }
      }
    }

    // Network information
    console.log(`\n🌍 Network Information:`);
    console.log("=".repeat(50));

    try {
      const l1Block = await l1Provider.getBlockNumber();
      const l2Block = await l2Provider.getBlockNumber();
      console.log(`   L1 Latest Block: ${l1Block}`);
      console.log(`   L2 Latest Block: ${l2Block}`);

      const l1GasPrice = await l1Provider.getFeeData();
      const l2GasPrice = await l2Provider.getFeeData();
      console.log(
        `   L1 Gas Price: ${ethers.formatUnits(
          l1GasPrice.gasPrice,
          "gwei"
        )} gwei`
      );
      console.log(
        `   L2 Gas Price: ${ethers.formatUnits(
          l2GasPrice.gasPrice,
          "gwei"
        )} gwei`
      );
    } catch (error) {
      console.log(`   Network info error: ${error.message}`);
    }

    console.log(`\n📊 Account Summary:`);
    console.log("=".repeat(50));
    console.log(`   Standard accounts: ${accounts.length} (with private keys)`);
    console.log(
      `   Default prefunded: ${defaultPrefundedAccounts.length} (development accounts)`
    );
    console.log(`   Total accounts: ${allAccounts.length}`);

    // Connection URLs for reference
    console.log(`\n🔗 Connection URLs:`);
    console.log("=".repeat(50));
    console.log(`   L1 RPC: ${l1RpcUrl}`);
    console.log(`   L2 RPC: ${l2RpcUrl}`);
    if (process.env.L1_WS_URL) {
      console.log(`   L1 WebSocket: ${process.env.L1_WS_URL}`);
    }
    if (process.env.L2_WS_URL) {
      console.log(`   L2 WebSocket: ${process.env.L2_WS_URL}`);
    }
    if (process.env.EXPLORER_URL) {
      console.log(`   Block Explorer: ${process.env.EXPLORER_URL}`);
    }

    console.log("\n" + "=".repeat(60));
    console.log("✅ Balance check complete!");
  } catch (error) {
    console.error(`\n❌ Error: ${error.message}`);
    if (process.env.DEBUG) {
      console.error("Full error:", error);
    }

    console.log("\n💡 Troubleshooting:");
    console.log("   1. Run setup-env.js first: node setup-env.js");
    console.log(
      "   2. Check if services are running: kurtosis enclave inspect"
    );
    console.log("   3. Verify URLs are accessible: curl <RPC_URL>");

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
