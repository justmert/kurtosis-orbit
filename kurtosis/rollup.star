"""
Rollup contract deployment module.
"""

def deploy_rollup_contracts(plan, config, l1_info):
    """
    Deploy Arbitrum Orbit rollup contracts on L1.
    """
    plan.print("Preparing rollup deployment configuration...")
    
    # Create L2 chain configuration
    l2_chain_config = {
        "chainId": config.chain_id,
        "homesteadBlock": 0,
        "daoForkSupport": True,
        "eip150Block": 0,
        "eip150Hash": "0x0000000000000000000000000000000000000000000000000000000000000000",
        "eip155Block": 0,
        "eip158Block": 0,
        "byzantiumBlock": 0,
        "constantinopleBlock": 0,
        "petersburgBlock": 0,
        "istanbulBlock": 0,
        "muirGlacierBlock": 0,
        "berlinBlock": 0,
        "londonBlock": 0,
        "clique": {
            "period": 0,
            "epoch": 0
        },
        "arbitrum": {
            "EnableArbOS": True,
            "AllowDebugPrecompiles": True,
            "DataAvailabilityCommittee": not config.rollup_mode,
            "InitialArbOSVersion": 32,
            "InitialChainOwner": config.owner_address,
            "GenesisBlockNum": 0
        }
    }
    
    # Create rollup configuration
    rollup_config = {
        "chainId": config.chain_id,
        "chainName": config.chain_name,
        "parentChainId": config.l1_chain_id,
        "maxDataSize": 117964,
        "challengePeriodBlocks": config.challenge_period_blocks,
        "stakeToken": config.stake_token,
        "baseStake": config.base_stake,
        "ownerAddress": config.owner_address,
        "sequencerAddress": config.sequencer_address,
        "dataAvailabilityMode": "rollup" if config.rollup_mode else "anytrust"
    }
    
    # Create config artifacts
    config_artifact = plan.render_templates(
        name="rollup-config",
        config={
            "rollup_config.json": struct(
                template=json.encode(rollup_config),
                data={},
            ),
            "l2_chain_config.json": struct(
                template=json.encode(l2_chain_config),
                data={},
            ),
        },
    )
    
    # Extract WASM module root
    wasm_root_result = plan.run_sh(
        run="cat /home/user/target/machines/latest/module-root.txt | tr -d '\\n'",
        image=config.nitro_image,
    )
    wasm_module_root = wasm_root_result.output.strip()
    plan.print("WASM module root: {}".format(wasm_module_root))
        
    # Deploy rollup contracts
    deployer_service = plan.add_service(
        name="orbit-deployer",
        config=ServiceConfig(
            image=ImageBuildSpec(
                image_name="rollupcreator",
                build_context_dir="./rollupcreator",
                build_args={
                    "NITRO_CONTRACTS_BRANCH": config.nitro_contracts_branch
                }
            ),
            cmd=[
                "/bin/sh",
                "-c",
                # Wait for L1 and deploy contracts
                """
                echo 'Waiting for L1 to be ready...'
                for i in {1..30}; do
                    if curl -s -X POST -H 'Content-Type: application/json' \
                        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
                        $PARENT_CHAIN_RPC | grep -q result; then
                        echo 'L1 is ready'
                        break
                    fi
                    sleep 2
                done
                
                # Wait for blocks
                sleep 10
                
                # Deploy contracts
                mkdir -p /config
                cp /rollup/*.json /config/
                yarn create-rollup-testnode
                
                echo 'Deployment complete!'
                tail -f /dev/null
                """
            ],
            files={
                "/rollup": config_artifact,
            },
            env_vars={
                "PARENT_CHAIN_RPC": "http://el-1-geth-lighthouse:8545",
                "DEPLOYER_PRIVKEY": config.owner_private_key,
                "PARENT_CHAIN_ID": str(config.l1_chain_id),
                "CHILD_CHAIN_NAME": config.chain_name,
                "MAX_DATA_SIZE": "117964",
                "OWNER_ADDRESS": config.owner_address,
                "SEQUENCER_ADDRESS": config.sequencer_address,
                "AUTHORIZE_VALIDATORS": "10",
                "CHILD_CHAIN_CONFIG_PATH": "/config/l2_chain_config.json",
                "CHAIN_DEPLOYMENT_INFO": "/config/deployment.json",
                "CHILD_CHAIN_INFO": "/config/chain_info.json",
                "WASM_MODULE_ROOT": wasm_module_root,
            },
        ),
    )
    
    # Wait for deployment to complete
    plan.wait(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["test", "-f", "/config/chain_info.json"]
        ),
        field="code",
        assertion="==",
        target_value=0,
        timeout="10m",
    )
    
    # Store deployment artifacts
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
    
    # Extract key addresses
    rollup_address = plan.exec(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.rollup' | tr -d '\\n'"]
        ),
    )["output"].strip()
    
    bridge_address = plan.exec(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.bridge' | tr -d '\\n'"]
        ),
    )["output"].strip()
    
    inbox_address = plan.exec(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.inbox' | tr -d '\\n'"]
        ),
    )["output"].strip()
    
    sequencer_inbox_address = plan.exec(
        service_name="orbit-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.\"sequencer-inbox\"' | tr -d '\\n'"]
        ),
    )["output"].strip()
    
    plan.print("✅ Rollup contracts deployed successfully!")
    plan.print("Rollup address: {}".format(rollup_address))
    
    return {
        "artifacts": {
            "deployment": deployment_artifact,
            "chain_info": chain_info_artifact,
        },
        "rollup_address": rollup_address,
        "bridge_address": bridge_address,
        "inbox_address": inbox_address,
        "sequencer_inbox_address": sequencer_inbox_address,
        "owner_address": config.owner_address,
        "sequencer_address": config.sequencer_address,
    }