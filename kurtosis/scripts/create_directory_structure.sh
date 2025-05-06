#!/bin/bash
# Script to create the directory structure for kurtosis-orbit

# Create root directory if it doesn't exist
mkdir -p kurtosis-orbit

# Create kurtosis subdirectory
mkdir -p kurtosis-orbit/kurtosis
mkdir -p kurtosis-orbit/kurtosis/scripts

# Create files subdirectory with necessary placeholders
mkdir -p kurtosis-orbit/kurtosis/files/keystore
mkdir -p kurtosis-orbit/kurtosis/files/l1data
mkdir -p kurtosis-orbit/kurtosis/files/seqdata
mkdir -p kurtosis-orbit/kurtosis/files/valdata
mkdir -p kurtosis-orbit/kurtosis/files/posterdata

# Create placeholder files
touch kurtosis-orbit/kurtosis/files/keystore/.gitkeep
touch kurtosis-orbit/kurtosis/files/l1data/.gitkeep
touch kurtosis-orbit/kurtosis/files/seqdata/.gitkeep
touch kurtosis-orbit/kurtosis/files/valdata/.gitkeep
touch kurtosis-orbit/kurtosis/files/posterdata/.gitkeep

# Copy main.star and config.star files
# (Assuming they are in the current directory)
cp kurtosis/main.star kurtosis-orbit/kurtosis/
cp kurtosis/config.star kurtosis-orbit/kurtosis/

# Copy script files
cp kurtosis/scripts/deploy_token_bridge.js kurtosis-orbit/kurtosis/scripts/

# Create root main.star
cat > kurtosis-orbit/main.star << 'EOF'
"""
Kurtosis-Orbit: A one-command deployment of a full Arbitrum Orbit stack.

This Kurtosis package deploys the entire Arbitrum Orbit stack, including:
1. A local Ethereum L1 chain
2. Arbitrum Nitro L2 rollup chain (sequencer, validator, batch poster)
3. Bridge contracts between L1 and L2
4. Optional block explorer
"""

def run(plan, args={}):
    """
    Main entry point for the Kurtosis package.
    
    Args:
        plan: The Kurtosis execution plan
        args: Configuration parameters passed via command line or config file
    
    Returns:
        Dictionary containing the endpoints and connection information for the deployed services
    """
    # Import the implementation from the kurtosis subdirectory
    kurtosis_main = import_module("./kurtosis/main.star")
    
    # Delegate execution to the actual implementation
    return kurtosis_main.run(plan, args)
EOF

# Create kurtosis.yml file
cat > kurtosis-orbit/kurtosis.yml << 'EOF'
name: github.com/arbitrumfoundation/kurtosis-orbit
EOF

echo "Directory structure created successfully"