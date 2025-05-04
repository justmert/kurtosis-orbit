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