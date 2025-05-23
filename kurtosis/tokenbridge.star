"""
Token bridge deployment module for Kurtosis-Orbit.
This module handles the deployment of the token bridge between L1 and L2.
Based on nitro-testnode token bridge deployment pattern.
"""

def deploy_token_bridge(plan, config, l1_info, nodes_info, rollup_info):
    """
    Deploy token bridge contracts between L1 and L2 using the official token-bridge-contracts
    
    Args:
        plan: The Kurtosis execution plan
        config: Configuration object
        l1_info: Information about the Ethereum L1 deployment
        nodes_info: Information about the deployed Nitro nodes
        rollup_info: Information about the deployed rollup contracts
        
    Returns:
        Dictionary with token bridge information
    """
    plan.print("Deploying L1-L2 token bridge using token-bridge-contracts...")
    
    # Deploy the token bridge using the official token-bridge-contracts approach
    # This follows the production deployment pattern with two steps:
    # 1. Deploy TokenBridgeCreator
    # 2. Create the actual token bridge
    bridge_deployer = plan.add_service(
        name="token-bridge-deployer",
        config=ServiceConfig(
            image=ImageBuildSpec(
                image_name="tokenbridge",
                build_context_dir="./tokenbridge",
                build_args={
                    "TOKEN_BRIDGE_BRANCH": config.token_bridge_branch if hasattr(config, 'token_bridge_branch') else "v1.2.2"
                }
            ),
            cmd=[
                "sh", "-c", "/workspace/deploy-token-bridge.sh"  # Use the deployment script with yarn commands
            ],
            env_vars={
                # Environment variables for TokenBridgeCreator deployment
                "BASECHAIN_RPC": "http://el-1-geth-lighthouse:8545",  # L1 RPC
                "BASECHAIN_DEPLOYER_KEY": "0x" + config.owner_private_key,  # Deployer private key
                "BASECHAIN_WETH": "0x0000000000000000000000000000000000000000",  # WETH address (zero for local)
                "GAS_LIMIT_FOR_L2_FACTORY_DEPLOYMENT": "6000000",  # Gas limit for L2 factory deployment
                "ORBIT_RPC": "http://orbit-sequencer:8547",  # L2 RPC for gas estimation
                "ROLLUP_ADDRESS": rollup_info["rollup_address"],  # Rollup contract address
                
                # Environment variables for token bridge creation
                "ROLLUP_OWNER": "0x" + config.owner_private_key,  # Same as deployer for local
                # L1_TOKEN_BRIDGE_CREATOR will be extracted and set by the deployment script
                
                # Optional (for verification, can be empty for local)
                "ARBISCAN_API_KEY": "",
            },
        ),
    )
    
    # Wait for the deployment to complete
    # The token bridge deployment creates network.json and other files
    plan.wait(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "test -f network.json"]
        ),
        field="code",
        assertion="==",
        target_value=0,
        timeout="2m",  # Token bridge deployment can take time
    )
    
    # Copy the network configuration files
    plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cp network.json l1l2_network.json && cp network.json localNetwork.json"]
        )
    )
    
    # Store the network configuration as artifacts
    network_artifact = plan.store_service_files(
        service_name="token-bridge-deployer",
        src="network.json",
        name="token-bridge-network",
    )
    
    l1l2_network_artifact = plan.store_service_files(
        service_name="token-bridge-deployer",
        src="l1l2_network.json", 
        name="l1l2-network",
    )
    
    # Extract key addresses from the network.json file
    l1_gateway_result = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat network.json | jq -r '.l1Network.tokenBridge.l1ERC20Gateway'"]
        ),
    )
    l1_gateway = l1_gateway_result["output"].strip()
    
    l1_router_result = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat network.json | jq -r '.l1Network.tokenBridge.l1GatewayRouter'"]
        ),
    )
    l1_router = l1_router_result["output"].strip()
    
    l2_gateway_result = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat network.json | jq -r '.l2Network.tokenBridge.l2ERC20Gateway'"]
        ),
    )
    l2_gateway = l2_gateway_result["output"].strip()
    
    l2_router_result = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat network.json | jq -r '.l2Network.tokenBridge.l2GatewayRouter'"]
        ),
    )
    l2_router = l2_router_result["output"].strip()
    
    l1_weth_result = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat network.json | jq -r '.l1Network.tokenBridge.l1Weth'"]
        ),
    )
    l1_weth = l1_weth_result["output"].strip()
    
    l2_weth_result = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat network.json | jq -r '.l2Network.tokenBridge.l2Weth'"]
        ),
    )
    l2_weth = l2_weth_result["output"].strip()
    
    plan.print("Token bridge deployed successfully!")
    plan.print("L1 Gateway: " + l1_gateway)
    plan.print("L1 Router: " + l1_router)
    plan.print("L2 Gateway: " + l2_gateway)
    plan.print("L2 Router: " + l2_router)
    
    # Return the token bridge information
    return {
        "artifacts": {
            "network": network_artifact,
            "l1l2_network": l1l2_network_artifact,
        },
        "l1": {
            "gateway": l1_gateway,
            "router": l1_router,
            "weth": l1_weth,
        },
        "l2": {
            "gateway": l2_gateway,
            "router": l2_router,
            "weth": l2_weth,
        },
        "network_info": {
            "l1_chain_id": l1_info.get("chain_id", 1337),
            "l2_chain_id": config.chain_id,
        }
    }