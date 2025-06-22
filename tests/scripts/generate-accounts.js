#!/usr/bin/env node

const { ethers } = require("ethers");

function generateAccounts(count = 3) {
  console.log("=".repeat(60));
  console.log("🔑 Generating Private Keys and Addresses");
  console.log("=".repeat(60));

  const accounts = [];

  for (let i = 1; i <= count; i++) {
    // Generate a random wallet
    const wallet = ethers.Wallet.createRandom();

    const account = {
      name: `Development account ${i}`,
      address: wallet.address,
      privateKey: wallet.privateKey,
      balance_eth: "100",
      description: `Development account ${i}`,
    };

    accounts.push(account);

    console.log(`\n👤 Account ${i}:`);
    console.log(`   Name: ${account.name}`);
    console.log(`   Address: ${account.address}`);
    console.log(`   Private Key: ${account.privateKey}`);
    console.log(`   Balance: ${account.balance_eth} ETH`);
  }
  DEFAULT_PREFUNDED_ACCOUNTS = [
    {
      address: "0x2093882c87B768469fbD434973bc7a4d20f73a51",
      balance_eth: "100",
      description: "Development account 1",
    },
    {
      address: "0x6D819ceDC7B20b8F755Ec841CBd5934812Cbe13b",
      balance_eth: "100",
      description: "Development account 2",
    },
    {
      address: "0xCE46e65a7A7527499e92337E5FBf958eABf314fa",
      balance_eth: "100",
      description: "Development account 3",
    },
    {
      address: "0xdafa61604B4Aa82092E1407F8027c71026982E6f",
      balance_eth: "100",
      description: "Development account 4",
    },
    {
      address: "0x1663f734483ceCB07AD6BC80919eA9a5cdDb7FE9",
      balance_eth: "100",
      description: "Development account 5",
    },
  ];
  console.log("\n" + "=".repeat(60));
  console.log("📋 Config Format (for copy-paste):");
  console.log("=".repeat(60));

  console.log("\n// JavaScript/JSON format:");
  console.log(JSON.stringify(accounts, null, 2));

  console.log("\n// Kurtosis config.star format:");
  console.log("DEFAULT_PREFUNDED_ACCOUNTS = [");
  accounts.forEach((account, index) => {
    console.log("    {");
    console.log(`        "address": "${account.address}",`);
    console.log(`        "balance_eth": "${account.balance_eth}",`);
    console.log(`        "description": "${account.description}"`);
    console.log("    }" + (index < accounts.length - 1 ? "," : ""));
  });
  console.log("]");

  console.log("\n// Private keys (keep secure!):");
  accounts.forEach((account, index) => {
    console.log(`// ${account.name}: ${account.privateKey}`);
  });

  console.log("\n" + "=".repeat(60));
  console.log("✅ Account generation complete!");
  console.log("⚠️  Keep private keys secure and never commit them to git!");

  return accounts;
}

// Export for use in other scripts
module.exports = { generateAccounts };

// Run if called directly
if (require.main === module) {
  const count = parseInt(process.argv[2]) || 3;
  generateAccounts(count);
}
