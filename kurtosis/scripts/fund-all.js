#!/usr/bin/env node

const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

async function fundAllAccounts() {
  const args = process.argv.slice(2);

  if (args.length < 2) {
    console.log(
      "Usage: node fund-all.js <l2_rpc_url> <funnel_private_key> [accounts_file]"
    );
    process.exit(1);
  }

  const [l2RpcUrl, funnelPrivateKey, accountsFile = "accounts.json"] = args;

  console.log("🚀 Starting L2 account funding...");
  console.log(`L2 RPC: ${l2RpcUrl}`);
  console.log(`Accounts file: ${accountsFile}`);

  // Read accounts configuration
  let accounts;
  try {
    const accountsPath = path.resolve(accountsFile);
    if (!fs.existsSync(accountsPath)) {
      console.error(`❌ Accounts file not found: ${accountsPath}`);
      process.exit(1);
    }

    const accountsData = fs.readFileSync(accountsPath, "utf8");
    accounts = JSON.parse(accountsData);
    console.log(`📋 Found ${accounts.length} accounts to fund`);
  } catch (error) {
    console.error(`❌ Error reading accounts file: ${error.message}`);
    process.exit(1);
  }

  let successCount = 0;
  let skipCount = 0;

  for (let i = 0; i < accounts.length; i++) {
    const account = accounts[i];

    if (account.name === "funnel") {
      console.log(`⏭️  Skipping funnel account`);
      skipCount++;
      continue;
    }

    console.log(`\n[${i + 1}/${accounts.length}] 💰 Funding ${account.name}`);
    console.log(`    Address: ${account.address}`);
    console.log(`    Amount: ${account.amount} ETH`);

    const success = await fundSingleAccount(
      l2RpcUrl,
      funnelPrivateKey,
      account.address,
      account.amount
    );

    if (success) {
      successCount++;
    } else {
      console.log(`⚠️  Failed to fund ${account.name}, continuing...`);
    }
  }

  console.log(`\n🎉 L2 account funding completed!`);
  console.log(`✅ Successfully funded: ${successCount} accounts`);
  console.log(`⏭️  Skipped: ${skipCount} accounts`);
  console.log(
    `❌ Failed: ${accounts.length - successCount - skipCount} accounts`
  );
}

function fundSingleAccount(l2RpcUrl, funnelPrivateKey, address, amount) {
  return new Promise((resolve) => {
    const child = spawn(
      "node",
      ["fund-accounts.js", l2RpcUrl, funnelPrivateKey, address, amount],
      {
        stdio: "inherit",
        cwd: __dirname,
      }
    );

    child.on("close", (code) => {
      if (code === 0) {
        resolve(true);
      } else {
        resolve(false);
      }
    });

    child.on("error", (error) => {
      console.error(`❌ Error spawning process: ${error.message}`);
      resolve(false);
    });
  });
}

// Handle process termination gracefully
process.on("SIGINT", () => {
  console.log("\n🛑 Funding process interrupted by user");
  process.exit(0);
});

process.on("SIGTERM", () => {
  console.log("\n🛑 Funding process terminated");
  process.exit(0);
});

fundAllAccounts().catch((error) => {
  console.error(`❌ Fatal error: ${error.message}`);
  process.exit(1);
});
