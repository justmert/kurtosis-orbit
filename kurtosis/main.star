"""
Kurtosis-Orbit: Production-ready Arbitrum Orbit deployment package.
Provides one-command deployment of complete Arbitrum Orbit stack.
"""

def run(plan, args={}):
    """
    Main entry point for Kurtosis Orbit deployment.
    
    Args:
        plan: Kurtosis execution plan
        args: Configuration parameters
    """
    # Import modules
    config_module = import_module("./config.star")
    ethereum_module = import_module("./ethereum.star")
    rollup_module = import_module("./rollup.star")
    nitro_module = import_module("./nitro.star")
    tokenbridge_module = import_module("./tokenbridge.star")
    explorer_module = import_module("./explorer.star")
    utils_module = import_module("./utils.star")
    
    # Process and validate configuration
    config = config_module.process_config(args)
    
    # Display deployment banner
    utils_module.print_deployment_banner(plan, config)
    
    # Phase 1: Deploy Ethereum L1
    plan.print("🚀 Phase 1/5: Deploying Ethereum L1 chain...")
    l1_info = ethereum_module.deploy_ethereum_l1(plan, config)
    
    # Phase 2: Deploy Orbit rollup contracts
    plan.print("📜 Phase 2/5: Deploying Orbit rollup contracts on L1...")
    rollup_info = rollup_module.deploy_rollup_contracts(plan, config, l1_info)
    
    # Phase 3: Deploy Nitro nodes
    plan.print("⚡ Phase 3/5: Deploying Arbitrum Nitro nodes...")
    nodes_info = nitro_module.deploy_nitro_nodes(plan, config, l1_info, rollup_info)
    
    # Phase 4: Deploy token bridge (if enabled)
    bridge_info = {}
    if config.enable_bridge:
        plan.print("🌉 Phase 4/5: Deploying token bridge...")
        bridge_info = tokenbridge_module.deploy_token_bridge(plan, config, l1_info, nodes_info, rollup_info)
    else:
        plan.print("⏭️  Phase 4/5: Skipping token bridge (disabled)")
    
    # Phase 5: Deploy explorer (if enabled)
    explorer_info = {}
    if config.enable_explorer:
        plan.print("🔍 Phase 5/5: Deploying block explorer...")
        explorer_info = explorer_module.deploy_blockscout(plan, config, nodes_info)
    else:
        plan.print("⏭️  Phase 5/5: Skipping explorer (disabled)")
    
    # Generate deployment summary
    output = {
        "ethereum_l1": l1_info,
        "arbitrum_l2": nodes_info,
        "rollup_contracts": rollup_info,
        "token_bridge": bridge_info,
        "explorer": explorer_info,
        "chain_info": {
            "name": config.chain_name,
            "chain_id": config.chain_id,
            "mode": "rollup" if config.rollup_mode else "anytrust",
            "owner_address": config.owner_address,
        }
    }
    
    # Display connection information
    utils_module.display_connection_info(plan, output)
    
    return output