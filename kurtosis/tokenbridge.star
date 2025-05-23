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

       # Extract rollup address directly to avoid runtime value issues
    rollup_address_result = plan.run_sh(
        run="apk add --no-cache jq > /dev/null 2>&1 && cat /config/deployment.json | jq -r '.rollup'",
        image="alpine:latest",
        files={
            "/config": rollup_info["artifacts"]["deployment"],
        }
    )
    rollup_address = rollup_address_result.output.strip()
    
    plan.print("Extracted rollup address: " + rollup_address)


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
                "sh", "-c", 
                "echo 'Starting token bridge deployment...' && " +
                "ls -la /config/ && " +
                "if command -v apt-get >/dev/null 2>&1; then " +
                    "apt-get update >/dev/null 2>&1 && apt-get install -y jq >/dev/null 2>&1; " +
                "elif command -v apk >/dev/null 2>&1; then " +
                    "apk add --no-cache jq >/dev/null 2>&1; " +
                "else " +
                    "echo 'No package manager found, trying without jq...'; " +
                "fi && " +
                "if [ -f /config/deployment.json ]; then " +
                    "export ROLLUP_ADDRESS=$(cat /config/deployment.json | jq -r '.rollup' 2>/dev/null || echo 'jq_failed') && " +
                    "echo 'Using rollup address:' $ROLLUP_ADDRESS; " +
                "else " +
                    "echo 'deployment.json not found at /config/'; " +
                    "exit 1; " +
                "fi && " +
                "yarn deploy:local:token-bridge && " +
                "echo 'Token bridge deployment completed'"
            ],
            files={
                "/config": rollup_info["artifacts"]["deployment"],  # Mount the deployment.json
            },
            env_vars={
                "ROLLUP_OWNER_KEY": "0x" + config.owner_private_key,
                "PARENT_KEY": "0x" + config.owner_private_key,  # Using owner key for parent chain
                "PARENT_RPC": "http://el-1-geth-lighthouse:8545",  # Use internal service name like nitro.star
                "CHILD_KEY": "0x" + config.owner_private_key,   # Using owner key for child chain
                "CHILD_RPC": "http://orbit-sequencer:8547",  # Use internal service name
            },
        ),
    )
    
    # Wait for the deployment to complete by checking for network.json file
    plan.wait(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "test -f /workspace/network.json"]
        ),
        field="code",
        assertion="==",
        target_value=0,
        timeout="10m",  # Token bridge deployment can take time
    )
    
    # Copy the network configuration files
    plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cp /workspace/network.json /workspace/l1l2_network.json && cp /workspace/network.json /workspace/localNetwork.json"]
        )
    )
    
    # Store the network configuration as artifacts
    network_artifact = plan.store_service_files(
        service_name="token-bridge-deployer",
        src="/workspace/network.json",
        name="token-bridge-network",
    )
    
    l1l2_network_artifact = plan.store_service_files(
        service_name="token-bridge-deployer",
        src="/workspace/l1l2_network.json", 
        name="l1l2-network",
    )
    
    # Extract key addresses from the network.json file
    l1_gateway_result = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /workspace/network.json | jq -r '.l1Network.tokenBridge.l1ERC20Gateway'"]
        ),
    )
    l1_gateway = l1_gateway_result["output"].strip()
    
    l1_router_result = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /workspace/network.json | jq -r '.l1Network.tokenBridge.l1GatewayRouter'"]
        ),
    )
    l1_router = l1_router_result["output"].strip()
    
    l2_gateway_result = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /workspace/network.json | jq -r '.l2Network.tokenBridge.l2ERC20Gateway'"]
        ),
    )
    l2_gateway = l2_gateway_result["output"].strip()
    
    l2_router_result = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /workspace/network.json | jq -r '.l2Network.tokenBridge.l2GatewayRouter'"]
        ),
    )
    l2_router = l2_router_result["output"].strip()
    
    l1_weth_result = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /workspace/network.json | jq -r '.l1Network.tokenBridge.l1Weth'"]
        ),
    )
    l1_weth = l1_weth_result["output"].strip()
    
    l2_weth_result = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /workspace/network.json | jq -r '.l2Network.tokenBridge.l2Weth'"]
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