#!/usr/bin/env node

const { ethers } = require("ethers");
const fs = require("fs");
const path = require("path");

async function checkBalances() {
  const args = process.argv.slice(2);

  if (args.length < 1) {
    process.exit(1);
  }

  const [l2RpcUrl, accountsFile = "accounts.json"] = args;

  let provider;
  try {
    // Connect to L2 RPC
    provider = new ethers.providers.JsonRpcProvider(l2RpcUrl);

    // Test connection
    const chainId = await provider.getNetwork();

    // Read accounts configuration if provided
    let accounts = [];
    if (fs.existsSync(accountsFile)) {
      const accountsData = fs.readFileSync(accountsFile, "utf8");
      accounts = JSON.parse(accountsData);
    } else {
      accounts = [
        {
          name: "funnel",
          address: "0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E",
        },
        {
          name: "sequencer",
          address: "0xe2148eE53c0755215Df69b2616E552154EdC584f",
        },
        {
          name: "validator",
          address: "0x6A568afe0f82d34759347bb36F14A6bB171d2CBe",
        },
      ];
    }

    const results = [];

    for (const account of accounts) {
      try {
        const balance = await provider.getBalance(account.address);
        const balanceEth = ethers.utils.formatEther(balance);
        const balanceNum = parseFloat(balanceEth);

        const status = balanceNum > 0 ? "✅" : "❌";
        const result = {
          name: account.name,
          address: account.address,
          balance: balanceEth,
          balanceNum: balanceNum,
          status: status,
        };

        results.push(result);
      } catch (error) {
        results.push({
          name: account.name,
          address: account.address,
          balance: "0",
          balanceNum: 0,
          status: "❌",
          error: error.message,
        });
      }
    }

    // Summary
    const funded = results.filter((r) => r.balanceNum > 0).length;
    const total = results.length;
  } catch (error) {
    // console.error(`❌ Error checking balances: ${error.message}`);
    process.exit(1);
  } finally {
    if (provider) {
      provider.removeAllListeners();
    }
  }
}

checkBalances();
