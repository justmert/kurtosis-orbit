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
    funding_module = import_module("./funding.star")
    explorer_module = import_module("./explorer.star")
    utils_module = import_module("./utils.star")
    
    # Process and validate configuration
    config = config_module.process_config(args)
    
    # Display deployment banner
    utils_module.print_deployment_banner(plan, config)
    
    # Phase 1: Deploy Ethereum L1
    plan.print("🚀 Phase 1/6: Deploying Ethereum L1 chain...")
    l1_info = ethereum_module.deploy_ethereum_l1(plan, config)
    
    # Phase 2: Deploy Orbit rollup contracts
    plan.print("📜 Phase 2/6: Deploying Orbit rollup contracts on L1...")
    rollup_info = rollup_module.deploy_rollup_contracts(plan, config, l1_info)
    
    # Phase 3: Deploy Nitro nodes
    plan.print("⚡ Phase 3/6: Deploying Arbitrum Nitro nodes...")
    nodes_info = nitro_module.deploy_nitro_nodes(plan, config, l1_info, rollup_info)
    
    # Phase 4: Deploy token bridge (if enabled)
    bridge_info = {}
    if config["enable_bridge"]:
        plan.print("🌉 Phase 4/6: Deploying token bridge...")
        bridge_info = tokenbridge_module.deploy_token_bridge(plan, config, l1_info, nodes_info, rollup_info)
    else:
        plan.print("⏭️  Phase 4/6: Skipping token bridge (disabled)")
    
    # Phase 5: Deploy L2 funding service and fund accounts
    plan.print("💰 Phase 5/6: Funding L2 accounts...")
    funding_info = {}
    
    # Deploy the funding service
    funding_info["service"] = funding_module.deploy_l2_funding(plan, config, nodes_info)
    
    # Fund the accounts (now with bridging support)
    funding_info["result"] = funding_module.fund_l2_accounts(plan, config, l1_info, nodes_info, rollup_info)
    
    # Phase 6: Deploy explorer (if enabled)
    explorer_info = {}
    if config["enable_explorer"]:
        plan.print("🔍 Phase 6/6: Deploying block explorer...")
        explorer_info = explorer_module.deploy_blockscout(plan, config, nodes_info)
    else:
        plan.print("⏭️  Phase 6/6: Skipping explorer (disabled)")
    
    # Generate deployment summary
    output = {
        "ethereum_l1": l1_info,
        "arbitrum_l2": nodes_info,
        "rollup_contracts": rollup_info,
        "token_bridge": bridge_info,
        "l2_funding": funding_info,
        "explorer": explorer_info,
        "chain_info": {
            "name": config["chain_name"],
            "chain_id": config["chain_id"],
            "mode": "rollup" if config["rollup_mode"] else "anytrust",
            "owner_address": config["owner_address"],
        },
        "config": config  # Pass config for display
    }
    
    # Display connection information
    utils_module.display_connection_info(plan, output)
    
    return output