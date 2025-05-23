"""
Nitro nodes deployment module for Kurtosis-Orbit.
This module handles the deployment of Arbitrum Nitro nodes (sequencer, validator, batch poster).
"""

def create_empty_dir_artifact(plan, name):
    """Create an empty directory artifact with just a .gitkeep file"""
    return plan.render_templates(
        config={
            "/.gitkeep": struct(
                template="",
                data={},
            ),
        },
        name=name + "-empty-dir",
    )

# # Default Nitro node version
# NITRO_NODE_VERSION = "offchainlabs/nitro-node:v3.5.5-90ee45c"

# # Default private key for development
# DEV_PRIVATE_KEY = "b6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659"


# Default Nitro node version (updated to match nitro-testnode)
NITRO_NODE_VERSION = "offchainlabs/nitro-node:v3.5.5-90ee45c"

# Default development accounts (from nitro-testnode mnemonic)
DEFAULT_ACCOUNTS = {
    "funnel": {
        "private_key": "59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
        "address": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
    },
    "sequencer": {
        "private_key": "5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a", 
        "address": "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
    },
    "validator": {
        "private_key": "7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6",
        "address": "0x90F79bf6EB2c4f870365E785982E1f101E93b906"
    },
    "l2owner": {
        "private_key": "92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e",
        "address": "0x976EA74026E726554dB657fA54763abd0C3a0aa9"
    }
}


def deploy_nitro_nodes(plan, config, l1_info, rollup_info):
    """ 
    Deploy Arbitrum Nitro nodes (sequencer, validator, batch poster)
    
    Args:
        plan: The Kurtosis execution plan
        config: Configuration object
        l1_info: Information about the Ethereum L1 deployment
        rollup_info: Information about the deployed rollup contracts
        
    Returns:
        Dictionary with node information
    """
    plan.print("Deploying Arbitrum Nitro nodes...")
    
    # Validate config properties and set defaults if missing
    config_with_defaults = get_config_with_defaults(config)
    
    # Verify chain info artifact exists
    if "artifacts" not in rollup_info or "chain_info" not in rollup_info["artifacts"]:
        fail("Error: Missing chain_info artifact in rollup_info. Deployment may have failed.")

    plan.print("Using chain_info from " + rollup_info["artifacts"]["chain_info"])
    
    # 1. First deploy the sequencer node
    sequencer = deploy_sequencer_node(plan, config_with_defaults, l1_info, rollup_info)
    
    # 2. Deploy validator node(s) if configured
    validators = []
    if config_with_defaults.validator_count > 0:
        for i in range(config_with_defaults.validator_count):
            plan.print("Deploying validator node " + str(i+1) + "/" + str(config_with_defaults.validator_count) + "...")
            validators.append(deploy_validator_node(plan, config_with_defaults, l1_info, rollup_info, sequencer, i))
    
    # 3. Deploy batch poster node if configured separately (otherwise sequencer handles it)
    batch_posters = []
    if not config_with_defaults.simple_mode and config_with_defaults.batch_poster_count > 0:
        for i in range(config_with_defaults.batch_poster_count):
            plan.print("Deploying batch poster node " + str(i+1) + "/" + str(config_with_defaults.batch_poster_count) + "...")
            batch_posters.append(deploy_batch_poster_node(plan, config_with_defaults, l1_info, rollup_info, i))
    
    return {
        "sequencer": sequencer,
        "validators": validators,
        "batch_posters": batch_posters,
    }

def get_config_with_defaults(config):
    """Add default values for missing config properties"""
    # Create a copy of the config to avoid modifying the original
    config_dict = {key: getattr(config, key) for key in dir(config) if not key.startswith("_")}
    
    # Add defaults for missing properties
    if "simple_mode" not in config_dict:
        config_dict["simple_mode"] = True
    if "simple_validator" not in config_dict:
        config_dict["simple_validator"] = True
    if "rollup_mode" not in config_dict:
        config_dict["rollup_mode"] = True  # Default to rollup mode (not anytrust)
    if "batch_poster_count" not in config_dict:
        config_dict["batch_poster_count"] = 0
    
    # Convert back to struct
    return struct(**config_dict)

def deploy_sequencer_node(plan, config, l1_info, rollup_info):
    """
    Deploy an Arbitrum Nitro sequencer node
    
    Args:
        plan: The Kurtosis execution plan
        config: Configuration object
        l1_info: Information about the Ethereum L1 deployment
        rollup_info: Information about the deployed rollup contracts
        
    Returns:
        Dictionary with sequencer information
    """
    plan.print("Deploying sequencer node...")
    
    # Get the private key to use
    sequencer_key = config.owner_private_key if hasattr(config, 'owner_private_key') else DEV_PRIVATE_KEY
    if sequencer_key == DEV_PRIVATE_KEY:
        plan.print("WARNING: Using default development private key. This should not be used in production.")
    
    # Create sequencer configuration
    sequencer_config = {
        "ensure-rollup-deployment": False,
        "parent-chain": {
            "connection": {
                "url": "http://el-1-geth-lighthouse:8545"
            }
        },
        "node": {
            "staker": {
                "dangerous": {
                    "without-block-validator": True
                },
                "parent-chain-wallet": {
                    "private-key": sequencer_key,
                },
                "disable-challenge": False,
                "enable": config.simple_mode,
                "use-smart-contract-wallet": True,
                "staker-interval": "10s",
                "make-assertion-interval": "10s",
                "strategy": "MakeNodes",
            },
            "sequencer": True,
            "dangerous": {
                "no-sequencer-coordinator": True,
                "disable-blob-reader": True,
            },
            "delayed-sequencer": {
                "enable": True
            },
            "feed": {
                "output": {
                    "enable": True,
                    "port": 9642
                }
            },
            "batch-poster": {
                "enable": config.simple_mode,
                "redis-url": "",
                "max-delay": "30s",
                "l1-block-bound": "ignore",
                "max-size": 90000,
                "parent-chain-wallet": {
                    "private-key": sequencer_key,
                },
                "data-poster": {
                    "redis-signer": {
                        "signing-key": sequencer_key
                    },
                    "wait-for-l1-finality": False
                }
            }
        },
        "execution": {
            "sequencer": {
                "enable": True
            },
            "forwarding-target": "",
        },
        "http": {
            "addr": "0.0.0.0",
            "port": 8547,
            "vhosts": "*",
            "corsdomain": "*",
            "api": ["eth", "net", "web3", "arb", "debug"]
        },
        "ws": {
            "addr": "0.0.0.0",
            "port": 8548,
            "origins": "*"
        },
        "persistent": {
            "chain": "/home/user/.arbitrum"
        }
    }

        # Add data-availability configuration if anytrust is enabled
    if hasattr(config, 'rollup_mode') and not config.rollup_mode:
        sequencer_config["node"]["data-availability"] = {
            "enable": True,
            "rpc-aggregator": {
                "enable": True,
                "assumed-honest": 1,
                "backends": [
                    {
                        "url": "http://das-committee-a:9876",
                        "pubkey": config.dasBlsA if hasattr(config, 'dasBlsA') else ""
                    },
                    {
                        "url": "http://das-committee-b:9876",
                        "pubkey": config.dasBlsB if hasattr(config, 'dasBlsB') else ""
                    }
                ]
            },
            "rest-aggregator": {
                "enable": True,
                "urls": ["http://das-mirror:9877"],
            },
            "parent-chain-node-url": l1_info["rpc_url"],
            "sequencer-inbox-address": rollup_info["sequencer_inbox_address"] if "sequencer_inbox_address" in rollup_info else ""
        }
    
    # Add timeboost configuration if enabled
    if hasattr(config, 'timeboost') and config.timeboost:
        if "dangerous" not in sequencer_config["execution"]["sequencer"]:
            sequencer_config["execution"]["sequencer"]["dangerous"] = {}
        
        sequencer_config["execution"]["sequencer"]["dangerous"]["timeboost"] = {
            "enable": False,  # Initially disabled, will be enabled after contract setup
            "redis-url": "redis://redis:6379"
        }
    
    # Generate the sequencer configuration JSON
    sequencer_config_json = json.encode(sequencer_config)

    # Create a file with the raw JSON content
    sequencer_config_artifact = plan.render_templates(
        name="sequencer-config",
        config={
            "sequencer_config.json": struct(
                template=sequencer_config_json,
                data={},
            ),
        },
    )



    # Create empty directory for sequencer data - FIXED
    sequencer_data_artifact = create_empty_dir_artifact(plan, "sequencer-data")

    # plan.print("Chain info: " + str(rollup_info["artifacts"]["chain_info"]))
    # Deploy the sequencer node
    sequencer_service = plan.add_service(
        name="orbit-sequencer",
        config=ServiceConfig(
            image=NITRO_NODE_VERSION,
            ports={
                "http": PortSpec(number=8547, transport_protocol="TCP", application_protocol="http"),
                "ws": PortSpec(number=8548, transport_protocol="TCP", application_protocol="ws"),
                "feed": PortSpec(number=9642, transport_protocol="TCP", application_protocol="ws"),
            },
            entrypoint=["/usr/local/bin/nitro"],  # Explicitly set entrypoint
            cmd=[
                "--validation.wasm.allowed-wasm-module-roots",
                "/home/user/nitro-legacy/machines,/home/user/target/machines",
                "--conf.file=/config/sequencer_config.json",
                "--chain.info-json",  # Add this line
                str(rollup_info["chain_info"]),
                "--node.feed.output.enable",
                "--node.feed.output.port=9642",
                "--http.api=net,web3,eth,debug",
            ],
            env_vars={
                "NITRO_SEQUENCER_PRIVATE_KEY": sequencer_key,
            },
            files={
                "/config": sequencer_config_artifact,  # Mount to directory, not file
                # "/config/chain_info.json": rollup_info["artifacts"]["chain_info"],
                "/home/user/.arbitrum": sequencer_data_artifact,
            },
        ),
    )    
    # # Wait for sequencer to be accessible via HTTP
    # plan.print("Waiting for sequencer node to start...")
    # wait_result = plan.wait(
    #     service_name="orbit-sequencer",
    #     recipe=PostHttpRequestRecipe(
    #         port_id="http",
    #         endpoint="",
    #         content_type="application/json",
    #         body='{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}',
    #     ),
    #     field="code",
    #     assertion="==",
    #     target_value=200,
    #     timeout="1m",
    # )
    
    # if wait_result["code"] == 200:
    #     plan.print("Sequencer node is running!")
    # else:
    #     plan.print("WARNING: Sequencer health check timed out. The node might still be starting.")
    
    # Perform a JSON-RPC call to verify the node is operational
    block_response = plan.exec(
        service_name="orbit-sequencer",
        recipe=ExecRecipe(
            command=["curl", "-s", "-X", "POST", "-H", "Content-Type: application/json", 
                    "--data", '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}',
                    "http://localhost:8547"]
        )
    )
    plan.print("Sequencer block height response: " + block_response['output'])
    
    return {
        "rpc_url": "http://" + sequencer_service.hostname + ":" + str(sequencer_service.ports["http"].number),
        "ws_url": "ws://" + sequencer_service.hostname + ":" + str(sequencer_service.ports["ws"].number),
        "feed_url": "ws://" + sequencer_service.hostname + ":" + str(sequencer_service.ports["feed"].number),
    }

def deploy_validator_node(plan, config, l1_info, rollup_info, sequencer, index):
    """
    Deploy an Arbitrum Nitro validator node
    
    Args:
        plan: The Kurtosis execution plan
        config: Configuration object
        l1_info: Information about the Ethereum L1 deployment
        rollup_info: Information about the deployed rollup contracts
        sequencer: Information about the deployed sequencer
        index: Validator index (for multiple validators)
        
    Returns:
        Dictionary with validator information
    """
    # Create validator configuration
    validator_config = {
        "parent-chain": {
            "connection": {
                "url": l1_info["rpc_url"]
            }
        },
        "chain": {
            "id": config.chain_id,
            "name": config.chain_name
        },
        "node": {
            "feed": {
                "input": {
                    "url": sequencer["feed_url"]
                }
            },
            "staker": {
                "enable": True,
                "dangerous": {
                    "without-block-validator": config.simple_validator
                }
            },
            "forwarding-target": sequencer["rpc_url"]
        },
        "http": {
            "addr": "0.0.0.0",
            "port": 8547,
            "vhosts": "*",
            "corsdomain": "*",
            "api": ["eth", "net", "web3", "arb", "debug"]
        },
        "ws": {
            "addr": "0.0.0.0",
            "port": 8548,
            "origins": "*"
        },
        "persistent": {
            "chain": "/home/user/.arbitrum"
        }
    }
    
    # If anytrust mode is enabled, add DAS configuration
    if not config.rollup_mode:
        validator_config["node"]["data-availability"] = { # TODO: Add DAS support
            "enable": True,
            "mode": "onchain",
            "rest-aggregator": {
                "enable": True,
                "urls": ["http://das-server:9876"]
            }
        }
    
    validator_config_json = json.encode(validator_config)
    validator_config_artifact = plan.render_templates(
        config={
            "validator_config.json": struct(
                template="{validator_config_json}",
                data={"validator_config_json": validator_config_json},
            ),
        },
        name="validator-" + str(index) + "-config",
    )
    
    # Create empty directory for validator data - FIXED
    validator_data_artifact = create_empty_dir_artifact(plan, "validator-" + str(index) + "-data")
    
    # Deploy the validator node
    validator_name = "orbit-validator-" + str(index)
    validator_service = plan.add_service(
        name=validator_name,
        config=ServiceConfig(
            image=NITRO_NODE_VERSION,
            ports={
                "http": PortSpec(number=8547, transport_protocol="TCP", application_protocol="http"),
                "ws": PortSpec(number=8548, transport_protocol="TCP", application_protocol="ws"),
            },
            entrypoint=["/usr/local/bin/nitro"],  # Explicitly set entrypoint
            cmd=[
                "--validation.wasm.allowed-wasm-module-roots",
                "/home/user/nitro-legacy/machines,/home/user/target/machines",
                "--conf.file=/config/validator_config.json",
                "--http.api=net,web3,eth,debug",
            ],
            files={
                "/home/user/.arbitrum": validator_data_artifact,
                "/config/validator_config.json": validator_config_artifact,
                "/config/chain_info.json": rollup_info["artifacts"]["chain_info"],
            },
        ),
    )
    
    # Wait for validator to be accessible via HTTP
    plan.print("Waiting for validator-" + str(index) + " node to start...")
    wait_result = plan.wait(
        service_name=validator_name,
        recipe=PostHttpRequestRecipe(
            port_id="http",
            endpoint="",
            content_type="application/json",
            body='{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}',
        ),
        field="code",
        assertion="==",
        target_value=200,
        timeout="2m",
    )
    
    if wait_result["code"] == 200:
        plan.print("Validator-" + str(index) + " node is running!")
    else:
        plan.print("WARNING: Validator-" + str(index) + " health check timed out. The node might still be starting.")
    return {
        "rpc_url": "http://" + validator_service.hostname + ":" + str(validator_service.ports["http"].number),
        "ws_url": "ws://" + validator_service.hostname + ":" + str(validator_service.ports["ws"].number),
    }

def deploy_batch_poster_node(plan, config, l1_info, rollup_info, index):
    """
    Deploy an Arbitrum Nitro batch poster node
    
    Args:
        plan: The Kurtosis execution plan
        config: Configuration object
        l1_info: Information about the Ethereum L1 deployment
        rollup_info: Information about the deployed rollup contracts
        index: Batch poster index (for multiple batch posters)
        
    Returns:
        Dictionary with batch poster information
    """
    # Create batch poster configuration
    batch_poster_config = {
        "parent-chain": {
            "connection": {
                "url": l1_info["rpc_url"]
            }
        },
        "chain": {
            "id": config.chain_id,
            "name": config.chain_name
        },
        "node": {
            "batch-poster": {
                "enable": True,
                "max-size": 90000
            }
        },
        "http": {
            "addr": "0.0.0.0",
            "port": 8547,
            "vhosts": "*",
            "corsdomain": "*",
            "api": ["eth", "net", "web3", "arb", "debug"]
        },
        "ws": {
            "addr": "0.0.0.0",
            "port": 8548,
            "origins": "*"
        },
        "persistent": {
            "chain": "/home/user/.arbitrum"
        }
    }
    
    # Create batch poster configuration file - FIXED TEMPLATE
    batch_poster_config_json = json.encode(batch_poster_config)
    batch_poster_config_artifact = plan.render_templates(
        config={
            "batch_poster_config.json": struct(
                template="{batch_poster_config_json}",
                data={"batch_poster_config_json": batch_poster_config_json},
            ),
        },
        name="batch-poster-" + str(index) + "-config",
    )
    
    # Create empty directory for batch poster data - FIXED
    batch_poster_data_artifact = create_empty_dir_artifact(plan, "batch-poster-" + str(index) + "-data")
    
    
    # Get the private key to use
    poster_key = config.owner_private_key if hasattr(config, 'owner_private_key') else DEV_PRIVATE_KEY
    if poster_key == DEV_PRIVATE_KEY:
        plan.print("WARNING: Using default development private key for batch poster. This should not be used in production.")
    
    # Deploy the batch poster node
    batch_poster_name = "orbit-batch-poster-" + str(index)
    batch_poster_service = plan.add_service(
        name=batch_poster_name,
        config=ServiceConfig(
            image=NITRO_NODE_VERSION,
            ports={
                "http": PortSpec(number=8547, transport_protocol="TCP", application_protocol="http"),
                "ws": PortSpec(number=8548, transport_protocol="TCP", application_protocol="ws"),
            },
            entrypoint=["/usr/local/bin/nitro"],  # Explicitly set entrypoint
            cmd=[
                "--validation.wasm.allowed-wasm-module-roots",
                "/home/user/nitro-legacy/machines,/home/user/target/machines",
                "--conf.file=/config/batch_poster_config.json",
                "--http.api=net,web3,eth,debug",
            ],
            env_vars={
                "NITRO_BATCHPOSTER_PRIVATE_KEY": poster_key,
            },
            files={
                "/home/user/.arbitrum": batch_poster_data_artifact,
                "/config/batch_poster_config.json": batch_poster_config_artifact,
                "/config/chain_info.json": rollup_info["artifacts"]["chain_info"],
            },
        ),
    )
    
    # Wait for batch poster to be accessible via HTTP
    plan.print("Waiting for batch-poster-" + str(index) + " node to start...")
    wait_result = plan.wait(
        service_name=batch_poster_name,
        recipe=PostHttpRequestRecipe(
            port_id="http",
            endpoint="",
            content_type="application/json",
            body='{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}',
        ),
        field="code",
        assertion="==",
        target_value=200,
        timeout="2m",
    )
    
    if wait_result["code"] == 200:
        plan.print("Batch-poster-" + str(index) + " node is running!")
    else:
        plan.print("WARNING: Batch-poster-" + str(index) + " health check timed out. The node might still be starting.")
    return {
        "rpc_url": "http://" + batch_poster_service.hostname + ":" + str(batch_poster_service.ports["http"].number),
        "ws_url": "ws://" + batch_poster_service.hostname + ":" + str(batch_poster_service.ports["ws"].number),
    }
