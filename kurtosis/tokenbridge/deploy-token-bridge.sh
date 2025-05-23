#!/bin/bash
set -e

echo "Starting token bridge deployment..."

# Install dependencies and build
echo "Installing dependencies..."
yarn install
yarn build

# Step 1: Deploy TokenBridgeCreator and capture the output
echo "Step 1: Deploying TokenBridgeCreator..."
CREATOR_OUTPUT=$(yarn deploy:token-bridge-creator 2>&1)
echo "$CREATOR_OUTPUT"

# Extract the L1TokenBridgeCreator address from the output
L1_TOKEN_BRIDGE_CREATOR=$(echo "$CREATOR_OUTPUT" | grep "L1TokenBridgeCreator:" | awk '{print $2}')
if [ -z "$L1_TOKEN_BRIDGE_CREATOR" ]; then
    echo "Error: Could not extract L1TokenBridgeCreator address from output"
    echo "Full output was:"
    echo "$CREATOR_OUTPUT"
    exit 1
fi

echo "Extracted L1TokenBridgeCreator address: $L1_TOKEN_BRIDGE_CREATOR"
export L1_TOKEN_BRIDGE_CREATOR

# Step 2: Create the actual token bridge with the L1_TOKEN_BRIDGE_CREATOR env var set
echo "Step 2: Creating token bridge..."
yarn create:token-bridge

echo "Token bridge deployment completed successfully!" 