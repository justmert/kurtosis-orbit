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
    # Import analytics for immediate tracking
    analytics_module = import_module("./kurtosis/analytics.star")
    
    # Track download/usage immediately when Kurtosis command is run
    plan.print("📊 Tracking usage analytics...")
    
    # Process basic config for analytics (before full processing)
    basic_config = {
        "enable_analytics": args.get("orbit_config", {}).get("enable_analytics", True),
        "chain_name": args.get("orbit_config", {}).get("chain_name", "orbit-chain"),
        "chain_id": args.get("orbit_config", {}).get("chain_id", 12345),
    }
    
    # Track the download/usage event immediately
    if analytics_module.is_analytics_enabled(basic_config):
        analytics_module.track_download(plan, "kurtosis", "github", "latest")
        plan.print("✅ Analytics tracking enabled (privacy-first)")
    else:
        plan.print("⏭️  Analytics tracking disabled")
    
    # Import the implementation from the kurtosis subdirectory
    kurtosis_main = import_module("./kurtosis/main.star")
    
    # Delegate execution to the actual implementation
    return kurtosis_main.run(plan, args)