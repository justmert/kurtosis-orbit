/**
 * Environment utilities for Kurtosis-Orbit scripts
 * Separated to avoid circular dependencies
 */

const fs = require("fs");
const path = require("path");

/**
 * Load environment variables from .env file if it exists
 */
function loadEnvironment() {
  const envPath = path.join(process.cwd(), ".env");
  if (fs.existsSync(envPath)) {
    const envContent = fs.readFileSync(envPath, "utf8");
    envContent.split("\n").forEach((line) => {
      const trimmedLine = line.trim();
      if (trimmedLine && !trimmedLine.startsWith("#")) {
        const equalIndex = trimmedLine.indexOf("=");
        if (equalIndex > 0) {
          const key = trimmedLine.substring(0, equalIndex).trim();
          const value = trimmedLine.substring(equalIndex + 1).trim();
          if (key && value) {
            process.env[key] = value;
          }
        }
      }
    });
    return true;
  }
  return false;
}

/**
 * Check if environment is properly set up
 */
function checkEnvironment() {
  const required = ["L1_RPC_URL", "L2_RPC_URL", "KURTOSIS_ENCLAVE"];
  const missing = required.filter((key) => !process.env[key]);
  return {
    isSetup: missing.length === 0,
    missing: missing,
  };
}

/**
 * Get environment info for display
 */
function getEnvironmentInfo() {
  return {
    enclave: process.env.KURTOSIS_ENCLAVE || "unknown",
    l1RpcUrl: process.env.L1_RPC_URL || "not set",
    l2RpcUrl: process.env.L2_RPC_URL || "not set",
    explorerUrl: process.env.EXPLORER_URL || "not set",
    l1Port: process.env.L1_RPC_PORT || "unknown",
    l2Port: process.env.L2_RPC_PORT || "unknown",
  };
}

module.exports = {
  loadEnvironment,
  checkEnvironment,
  getEnvironmentInfo,
};
