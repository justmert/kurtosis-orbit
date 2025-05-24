"""
Token bridge deployment module.
"""

def deploy_token_bridge(plan, config, l1_info, nodes_info, rollup_info):
    """
    Deploy token bridge between L1 and L2.
    """
    plan.print("Deploying token bridge contracts...")
    
    # Deploy bridge contracts
    bridge_deployer = plan.add_service(
        name="token-bridge-deployer",
        config=ServiceConfig(
            image=ImageBuildSpec(
                image_name="tokenbridge",
                build_context_dir="./tokenbridge",
                build_args={
                    "TOKEN_BRIDGE_BRANCH": config.token_bridge_branch
                }
            ),
            cmd=[
                "sh", "-c",
                """
                echo 'Starting token bridge deployment...'
                yarn deploy:local:token-bridge
                cp network.json l1l2_network.json
                echo 'Token bridge deployment completed!'
                tail -f /dev/null
                """
            ],
            env_vars={
                "ROLLUP_OWNER_KEY": "0x" + config.owner_private_key,
                "ROLLUP_ADDRESS": rollup_info["rollup_address"],
                "PARENT_KEY": "0x" + config.owner_private_key,
                "PARENT_RPC": l1_info["rpc_url"],
                "CHILD_KEY": "0x" + config.owner_private_key,
                "CHILD_RPC": nodes_info["sequencer"]["rpc_url"],
            },
        ),
    )
    
    # Wait for deployment
    plan.wait(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["test", "-f", "/workspace/network.json"]
        ),
        field="code",
        assertion="==",
        target_value=0,
        timeout="10m",
    )
    
    # Store network configuration
    network_artifact = plan.store_service_files(
        service_name="token-bridge-deployer",
        src="/workspace/network.json",
        name="token-bridge-network",
    )
    
    # Extract bridge addresses
    l1_gateway = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /workspace/network.json | jq -r '.l2Network.tokenBridge.l1ERC20Gateway'"]
        ),
    )["output"].strip()
    
    l1_router = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /workspace/network.json | jq -r '.l2Network.tokenBridge.l1GatewayRouter'"]
        ),
    )["output"].strip()
    
    l2_gateway = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /workspace/network.json | jq -r '.l2Network.tokenBridge.l2ERC20Gateway'"]
        ),
    )["output"].strip()
    
    l2_router = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /workspace/network.json | jq -r '.l2Network.tokenBridge.l2GatewayRouter'"]
        ),
    )["output"].strip()
    
    plan.print("✅ Token bridge deployed successfully!")
    
    return {
        "artifacts": {
            "network": network_artifact,
        },
        "l1": {
            "gateway": l1_gateway,
            "router": l1_router,
        },
        "l2": {
            "gateway": l2_gateway,
            "router": l2_router,
        },
    }