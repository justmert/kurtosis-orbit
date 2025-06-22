#!/usr/bin/env node

/**
 * Kurtosis-Orbit Environment Setup
 * Detects running Kurtosis enclave and extracts port information using the official SDK
 * Creates .env file with detected ports for use by other scripts
 */

const { KurtosisContext } = require("kurtosis-sdk");
const fs = require("fs");
const path = require("path");

async function detectKurtosisPorts() {
  console.log("🔍 Kurtosis-Orbit Environment Setup");
  console.log("====================================");

  try {
    // Connect to Kurtosis engine using the official SDK
    console.log("🔌 Connecting to Kurtosis engine...");
    const kurtosisContextResult =
      await KurtosisContext.newKurtosisContextFromLocalEngine();

    if (kurtosisContextResult.isErr()) {
      throw new Error(
        `Failed to connect to Kurtosis engine: ${kurtosisContextResult.error}`
      );
    }

    const kurtosisContext = kurtosisContextResult.value;

    // Get all enclaves
    console.log("📋 Searching for running Kurtosis enclave...");
    const enclavesResult = await kurtosisContext.getEnclaves();

    if (enclavesResult.isErr()) {
      throw new Error(`Failed to get enclaves: ${enclavesResult.error}`);
    }

    const enclaves = enclavesResult.value;

    // Find a running enclave
    let runningEnclaveName = null;

    if (process.env.DEBUG) {
      console.log("🐛 Enclaves structure:", enclaves);
      console.log("🐛 EnclavesByName:", enclaves.enclavesByName);
    }

    // Handle the enclavesByName Map structure from the API
    if (enclaves.enclavesByName) {
      console.log(
        `📋 Found ${
          enclaves.enclavesByName.size ||
          Object.keys(enclaves.enclavesByName).length
        } enclave(s)`
      );

      // Try Map iteration first, then Object iteration as fallback
      let entries = [];
      try {
        if (enclaves.enclavesByName instanceof Map) {
          entries = Array.from(enclaves.enclavesByName.entries());
        } else {
          entries = Object.entries(enclaves.enclavesByName);
        }
      } catch (error) {
        console.log(`⚠️  Could not iterate enclaves: ${error.message}`);
      }

      for (const [enclaveName, enclaveInfo] of entries) {
        console.log(`   Checking enclave: ${enclaveName}`);

        if (process.env.DEBUG) {
          console.log("🐛 EnclaveInfo object:", enclaveInfo);
          console.log(
            "🐛 Available methods:",
            Object.getOwnPropertyNames(enclaveInfo)
          );
        }

        // Use the correct API method from documentation
        let status = null;
        try {
          if (typeof enclaveInfo.getContainersStatus === "function") {
            status = enclaveInfo.getContainersStatus();
          } else if (enclaveInfo.status) {
            status = enclaveInfo.status;
          }

          console.log(`   Status: ${status}`);

          // According to API docs, status is one of 'EMPTY', 'RUNNING', 'STOPPED'
          if (status === 1) {
            runningEnclaveName = enclaveName;
            break;
          }
        } catch (error) {
          console.log(
            `   Could not get status for ${enclaveName}: ${error.message}`
          );
          // If we can't get status but enclave exists, assume it's running
          runningEnclaveName = enclaveName;
          break;
        }
      }
    } else {
      console.log("⚠️  No enclavesByName found in response");
    }

    if (!runningEnclaveName) {
      throw new Error(
        "No running Kurtosis enclave found. Please run: kurtosis run github.com/justmert/kurtosis-orbit"
      );
    }

    console.log(`✅ Found running enclave: ${runningEnclaveName}`);

    // Get enclave context
    const enclaveContextResult = await kurtosisContext.getEnclaveContext(
      runningEnclaveName
    );
    if (enclaveContextResult.isErr()) {
      throw new Error(
        `Failed to get enclave context: ${enclaveContextResult.error}`
      );
    }

    const enclaveContext = enclaveContextResult.value;

    // Detect service ports
    const ports = {}; // Initialize ports object
    const services = [
      { name: "el-1-geth-lighthouse", type: "L1", ports: ["rpc", "ws"] },
      { name: "orbit-sequencer", type: "L2", ports: ["rpc", "ws"] },
      { name: "blockscout", type: "EXPLORER", ports: ["http"] },
    ];

    for (const serviceInfo of services) {
      try {
        console.log(`🔍 Detecting ports for ${serviceInfo.name}...`);
        const serviceContextResult = await enclaveContext.getServiceContext(
          serviceInfo.name
        );

        if (serviceContextResult.isErr()) {
          console.log(
            `⚠️  Service ${serviceInfo.name} not found: ${serviceContextResult.error}`
          );
          continue;
        }

        const serviceContext = serviceContextResult.value;

        if (process.env.DEBUG) {
          console.log(
            `🐛 ${serviceInfo.name} service context:`,
            serviceContext
          );
          console.log(
            `🐛 Available methods:`,
            Object.getOwnPropertyNames(serviceContext)
          );
        }

        // Use the correct API method from documentation
        let publicPorts = null;
        try {
          if (typeof serviceContext.getPublicPorts === "function") {
            publicPorts = serviceContext.getPublicPorts();
          }
        } catch (error) {
          console.log(
            `⚠️  Could not get public ports for ${serviceInfo.name}: ${error.message}`
          );
          continue;
        }

        if (process.env.DEBUG) {
          console.log(`🐛 ${serviceInfo.name} public ports:`, publicPorts);
        }

        if (!publicPorts) {
          console.log(`⚠️  No public ports found for ${serviceInfo.name}`);
          continue;
        }

        // Extract port numbers - publicPorts is Map<PortID, PortSpec>
        for (const portName of serviceInfo.ports) {
          if (publicPorts.has && publicPorts.has(portName)) {
            // It's a Map
            const portSpec = publicPorts.get(portName);
            let portNumber = null;

            if (typeof portSpec.getNumber === "function") {
              portNumber = portSpec.getNumber();
            } else if (portSpec.number) {
              portNumber = portSpec.number;
            }

            if (portNumber) {
              const envKey = `${
                serviceInfo.type
              }_${portName.toUpperCase()}_PORT`;
              ports[envKey] = portNumber;
              console.log(`   📡 ${portName}: ${portNumber}`);
            }
          } else if (publicPorts[portName]) {
            // It's an object
            const portSpec = publicPorts[portName];
            let portNumber = null;

            if (typeof portSpec.getNumber === "function") {
              portNumber = portSpec.getNumber();
            } else if (portSpec.number) {
              portNumber = portSpec.number;
            } else if (typeof portSpec === "number") {
              portNumber = portSpec;
            }

            if (portNumber) {
              const envKey = `${
                serviceInfo.type
              }_${portName.toUpperCase()}_PORT`;
              ports[envKey] = portNumber;
              console.log(`   📡 ${portName}: ${portNumber}`);
            }
          }

          if (
            process.env.DEBUG &&
            !ports[`${serviceInfo.type}_${portName.toUpperCase()}_PORT`]
          ) {
            console.log(
              `🐛 Could not find port ${portName} for ${serviceInfo.name}`
            );
            console.log(`🐛 Available ports:`, Object.keys(publicPorts));
          }
        }
      } catch (error) {
        console.log(
          `⚠️  Could not get ports for ${serviceInfo.name}: ${error.message}`
        );
        if (process.env.DEBUG) {
          console.error(`🐛 Full error for ${serviceInfo.name}:`, error);
        }
      }
    }

    // If no ports were detected via SDK, try CLI fallback
    if (Object.keys(ports).length === 0) {
      console.log(`\n⚠️  No ports detected via SDK, trying CLI fallback...`);
      try {
        const { execSync } = require("child_process");
        const inspectOutput = execSync(
          `kurtosis enclave inspect ${runningEnclaveName}`,
          { encoding: "utf8" }
        );

        if (process.env.DEBUG) {
          console.log("🐛 CLI output:", inspectOutput);
        }

        // Parse CLI output for ports
        const lines = inspectOutput.split("\n");
        for (const line of lines) {
          // Look for port mappings like: rpc: 8547/tcp -> 127.0.0.1:57426
          const portMatch = line.match(
            /^\s*(\w+):\s*\d+\/tcp\s*->\s*127\.0\.0\.1:(\d+)/
          );
          if (portMatch) {
            const [, portName, portNumber] = portMatch;

            // Map to service types
            if (line.includes("el-1-geth-lighthouse")) {
              const envKey = `L1_${portName.toUpperCase()}_PORT`;
              ports[envKey] = parseInt(portNumber);
              console.log(`   📡 L1 ${portName}: ${portNumber} (CLI)`);
            } else if (line.includes("orbit-sequencer")) {
              const envKey = `L2_${portName.toUpperCase()}_PORT`;
              ports[envKey] = parseInt(portNumber);
              console.log(`   📡 L2 ${portName}: ${portNumber} (CLI)`);
            } else if (line.includes("blockscout")) {
              const envKey = `EXPLORER_HTTP_PORT`;
              ports[envKey] = parseInt(portNumber);
              console.log(`   📡 Explorer http: ${portNumber} (CLI)`);
            }
          }
        }
      } catch (error) {
        console.log(`⚠️  CLI fallback also failed: ${error.message}`);
      }
    }

    // Generate URLs from detected ports
    const envVars = {
      KURTOSIS_ENCLAVE: runningEnclaveName,
      ...ports,
    };

    // Add convenience URL variables
    if (ports.L1_RPC_PORT) {
      envVars.L1_RPC_URL = `http://127.0.0.1:${ports.L1_RPC_PORT}`;
    }
    if (ports.L1_WS_PORT) {
      envVars.L1_WS_URL = `ws://127.0.0.1:${ports.L1_WS_PORT}`;
    }
    if (ports.L2_RPC_PORT) {
      envVars.L2_RPC_URL = `http://127.0.0.1:${ports.L2_RPC_PORT}`;
    }
    if (ports.L2_WS_PORT) {
      envVars.L2_WS_URL = `ws://127.0.0.1:${ports.L2_WS_PORT}`;
    }
    if (ports.EXPLORER_HTTP_PORT) {
      envVars.EXPLORER_URL = `http://127.0.0.1:${ports.EXPLORER_HTTP_PORT}`;
    }

    // Write .env file
    const envContent = Object.entries(envVars)
      .map(([key, value]) => `${key}=${value}`)
      .join("\n");

    const envPath = path.join(process.cwd(), ".env");
    fs.writeFileSync(envPath, envContent + "\n");

    console.log("\n📁 Environment variables written to .env file:");
    console.log("=".repeat(50));
    Object.entries(envVars).forEach(([key, value]) => {
      console.log(`${key}=${value}`);
    });

    console.log("\n✅ Setup complete! You can now run:");
    console.log("   npm run check-balances");
    console.log("   npm run deploy-contract");
    console.log("   npm run bridge-eth");

    return envVars;
  } catch (error) {
    console.error(`❌ Error: ${error.message}`);
    if (process.env.DEBUG) {
      console.error("🐛 Full error:", error);
    }

    console.log("\n💡 Troubleshooting:");
    console.log(
      "   1. Make sure Kurtosis engine is running: kurtosis engine status"
    );
    console.log("   2. Make sure enclave is running: kurtosis enclave ls");
    console.log(
      "   3. Try restarting: kurtosis clean -a && kurtosis run github.com/justmert/kurtosis-orbit"
    );

    process.exit(1);
  }
}

// Export function for use in other scripts
module.exports = {
  detectKurtosisPorts,
};

// Run if called directly
if (require.main === module) {
  detectKurtosisPorts()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error("Setup failed:", error.message);
      process.exit(1);
    });
}
