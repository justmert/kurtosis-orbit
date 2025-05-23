"""
Rollup contracts deployment module for Kurtosis-Orbit.
This module handles the deployment of Arbitrum Orbit rollup contracts on L1.
"""

def deploy_rollup_contracts(plan, config, l1_info):
    """
    Deploy Arbitrum Orbit rollup contracts on L1
    
    Args:
        plan: The Kurtosis execution plan
        config: Configuration object
        l1_info: Information about the Ethereum L1 deployment
        
    Returns:
        Dictionary with rollup contract information
    """

    
    plan.print("Deploying Arbitrum Orbit rollup contracts on L1...")
    
    # Prepare rollup configuration
    rollup_config = {
        "chainId": config.chain_id,
        "chainName": config.chain_name,
        "parentChainId": config.l1_chain_id,
        "maxDataSize": 117964,  # Default from Arbitrum Orbit docs
        "challengePeriodBlocks": config.challenge_period_blocks,
        "stakeToken": config.stake_token if hasattr(config, 'stake_token') else "0x0000000000000000000000000000000000000000",  # ETH by default
        "baseStake": config.base_stake if hasattr(config, 'base_stake') else "0",
        "ownerAddress": config.owner_address,
        "sequencerAddress": config.sequencer_address,
        "dataAvailabilityMode": "rollup" if config.rollup_mode else "anytrust"
    }
    
    # In rollup.star
    rollup_config_json = json.encode(rollup_config)

    # Create a file artifact using render_templates
    config_template = plan.render_templates(
        name="rollup-config",
        config={
            "rollup_config.json": struct(
                template=rollup_config_json,
                data={},
            ),
        },
    )


    # Extract the WASM module root and properly trim it
    wasm_root_result = plan.run_sh(
        run="sh -c 'cat /home/user/target/machines/latest/module-root.txt | tr -d \"\\n\"'",
        image="offchainlabs/nitro-node:v3.5.5-90ee45c"
    )

    wasm_module_root = wasm_root_result.output.strip()
    plan.print("Extracted WASM module root (trimmed): " + wasm_module_root)

    # Deploy the service using the artifact
    deployer_service = plan.add_service(
        name="orbit-deployer",
        config=ServiceConfig(
                # Add this service config
            image=ImageBuildSpec(
                image_name="rollupcreator",
                build_context_dir="./rollupcreator",
                build_args={
                    "NITRO_CONTRACTS_BRANCH": config.nitro_contracts_branch if hasattr(config, 'nitro_contracts_branch') else "v2.1.1-beta.0"
                }
            ),
            cmd=[
                "sh",
                "-c",
                "apt-get update && apt-get install -y curl && " +
                "echo 'Waiting for L1 node...' && " +
                # First wait for basic response
                "count=0 && " +
                "while [ $count -lt 30 ]; do " +
                    "response=$(curl -s -X POST -H 'Content-Type: application/json' " +
                    "--data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}' " +
                    "$PARENT_CHAIN_RPC) && " +
                    "if echo \"$response\" | grep -q 'result'; then " +
                        "echo 'L1 node is responding' && " +
                        "break; " +
                    "fi && " +
                    "echo 'Waiting for L1 node to respond...' && " +
                    "sleep 2 && " +
                    "count=$((count+1)); " +
                "done && " +
                # Then wait for blocks to be mined
                "echo 'Waiting for L1 to mine blocks...' && " +
                "sleep 15 && " +  # Add an initial delay to let node stabilize
                "count=0 && " +
                "while [ $count -lt 30 ]; do " +
                    "block_response=$(curl -s -X POST -H 'Content-Type: application/json' " +
                    "--data '{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}' " +
                    "$PARENT_CHAIN_RPC) && " +
                    "if [ \"$?\" -eq 0 ] && echo \"$block_response\" | grep -q '\"result\":\"0x[1-9a-f]'; then " +
                        "echo 'L1 has mined blocks beyond genesis' && " +
                        "break; " +
                    "fi && " +
                    "echo 'Waiting for L1 to mine blocks...' && " +
                    "sleep 2 && " +
                    "count=$((count+1)); " +
                "done && " +
                # Final delay and deploy
                "echo 'Giving L1 a final moment to stabilize...' && " +
                "sleep 5 && " +
                "echo 'Proceeding with deployment' && " +
                "mkdir -p /config && cp /rollup/rollup_config.json /config/ && yarn create-rollup-testnode && "  +
                "echo 'Deployment complete! Files created:' && ls -l /config/deployment.json /config/chain_info.json && " +
                "tail -f /dev/null"
            ],
            files={
                "/rollup": config_template,  # Mount the template files to /rollup
            },
            env_vars={
                "PARENT_CHAIN_RPC": l1_info["rpc_url"],
                "DEPLOYER_PRIVKEY": config.owner_private_key,
                "PARENT_CHAIN_ID": str(config.l1_chain_id),
                "CHILD_CHAIN_NAME": config.chain_name,
                "MAX_DATA_SIZE": "117964",
                "OWNER_ADDRESS": config.owner_address,
                "SEQUENCER_ADDRESS": config.sequencer_address,
                "AUTHORIZE_VALIDATORS": "10",
                "CHILD_CHAIN_CONFIG_PATH": "/config/rollup_config.json",
                "CHAIN_DEPLOYMENT_INFO": "/config/deployment.json",
                "CHILD_CHAIN_INFO": "/config/chain_info.json",
                # Add this critical parameter
                "WASM_MODULE_ROOT": wasm_module_root,
            },
        ),
    )    
    
    # Wait directly for the deployment files to be created
    plan.wait(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "test -f /config/deployment.json && test -f /config/chain_info.json"]
        ),
        field="code",
        assertion="==",
        target_value=0,
        timeout="10m",  # Keep a reasonable timeout
    )

    # Optionally print the deployment info summary
    plan.exec(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "echo 'Deployment complete! Files created:' && ls -l /config/deployment.json /config/chain_info.json"]
        )
    )


    # Store deployment.json and chain_info.json as artifacts
    deployment_artifact = plan.store_service_files(
        service_name="orbit-deployer",
        src="/config/deployment.json",
        name="deployment-info",
    )
    
    chain_info_artifact = plan.store_service_files(
        service_name="orbit-deployer",
        src="/config/chain_info.json",
        name="chain-info",
    )
    
    # Extract important values from deployment.json (with corrected field names)
    rollup_address_result = plan.exec(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.rollup'"]
        ),
    )
    rollup_address = rollup_address_result["output"].strip()

    bridge_address_result = plan.exec(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.bridge'"]
        ),
    )
    bridge_address = bridge_address_result["output"].strip()

    inbox_address_result = plan.exec(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.inbox'"]
        ),
    )
    inbox_address = inbox_address_result["output"].strip()

    sequencer_inbox_address_result = plan.exec(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.\"sequencer-inbox\"'"]
        ),
    )
    sequencer_inbox_address = sequencer_inbox_address_result["output"].strip()

    validator_utils_address_result = plan.exec(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.\"validator-utils\"'"]
        ),
    )
    validator_utils_address = validator_utils_address_result["output"].strip()

    validator_wallet_creator_address_result = plan.exec(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.\"validator-wallet-creator\"'"]
        ),
    )
    validator_wallet_creator_address = validator_wallet_creator_address_result["output"].strip()

    deployed_block_num_result = plan.exec(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.\"deployed-at\"'"]
        ),
    )
    deployed_block_num = deployed_block_num_result["output"].strip()

    # Note: deployedBlockHash doesn't exist in the JSON, using empty string or null
    deployed_block_hash = ""

    # Optional: Extract additional fields that are in the JSON but weren't captured before
    upgrade_executor_result = plan.exec(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.\"upgrade-executor\"'"]
        ),
    )
    upgrade_executor = upgrade_executor_result["output"].strip()

    native_token_result = plan.exec(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.\"native-token\"'"]
        ),
    )

    chain_result = plan.exec(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/chain_info.json"]
        ),
    )
    chain_info = chain_result["output"].strip()
    
    bridge_address = bridge_address_result["output"].strip()

    native_token = native_token_result["output"].strip()    
    # Return the deployment information
    return {
        "artifacts": {
            "deployment": deployment_artifact,
            "chain_info": chain_info_artifact,
        },
        "chain_info": chain_info,
        "rollup_address": rollup_address,
        "bridge_address": bridge_address,
        "inbox_address": inbox_address,
        "sequencer_inbox_address": sequencer_inbox_address,
        "validator_utils_address": validator_utils_address,
        "validator_wallet_creator_address": validator_wallet_creator_address,
        "deployed_block_num": deployed_block_num,
        "deployed_block_hash": deployed_block_hash,  # Will be empty string
        "owner_address": config.owner_address,
        "sequencer_address": config.sequencer_address,
        "upgrade_executor": upgrade_executor,  # New field
        "native_token": native_token,  # New field
    }
