"""
Kurtosis-Orbit: Main implementation file for Arbitrum Orbit deployment.
This file orchestrates the deployment of all components of an Arbitrum Orbit stack.
"""

def run(plan, args={}):
    """
    Main entry point for Kurtosis Orbit deployment
    
    Args:
        plan: The Kurtosis execution plan
        args: Configuration parameters for customizing the deployment
        
    Returns:
        Dictionary containing endpoints and connection information for the deployed services
    """
    # Import supporting modules - do this inside the function to avoid circular imports
    config_module = import_module("./config.star")
    ethereum_module = import_module("./ethereum.star")
    rollup_module = import_module("./rollup.star")
    nitro_module = import_module("./nitro.star")
    tokenbridge_module = import_module("./tokenbridge.star")
    explorer_module = import_module("./explorer.star")
    utils_module = import_module("./utils.star")
    
    # Process and validate configuration
    config = config_module.process_config(args)
    
    # Display banner with configuration information
    plan.print("=========================================")
    plan.print("Kurtosis-Orbit: Arbitrum Orbit Deployment")
    plan.print("=========================================")
    plan.print("Chain name: " + config.chain_name)
    plan.print("Chain ID: " + str(config.chain_id))
    plan.print("Deploying in " + ("rollup" if config.rollup_mode else "anytrust") + " mode")
    
    # Step 1: Deploy Ethereum L1 Chain
    l1_info = ethereum_module.deploy_ethereum_l1(plan, config)
    
    # Step 2: Deploy Orbit rollup contracts on L1
    rollup_info = rollup_module.deploy_rollup_contracts(plan, config, l1_info)
    
    # Step 3: Deploy Arbitrum Nitro nodes
    nodes_info = nitro_module.deploy_nitro_nodes(plan, config, l1_info, rollup_info)
    
    # Step 4: Deploy token bridge (if enabled)
    bridge_info = {}
    if config.enable_bridge:
        bridge_info = tokenbridge_module.deploy_token_bridge(plan, config, l1_info, nodes_info, rollup_info)
    
    # Step 5: Deploy block explorer (if enabled)
    explorer_info = {}
    if config.enable_explorer:
        explorer_info = explorer_module.deploy_blockscout(plan, config, nodes_info)
    
    # Prepare output with connection information
    output = {
        "ethereum_l1": l1_info,
        "arbitrum_l2": nodes_info,
        "token_bridge": bridge_info,
        "explorer": explorer_info,
        "chain_info": {
            "name": config.chain_name,
            "chain_id": config.chain_id,
            "mode": "rollup" if config.rollup_mode else "anytrust",
            "owner_address": rollup_info["owner_address"],
        }
    }
    
    # Display connection information
    utils_module.display_connection_info(plan, output)
    
    return output