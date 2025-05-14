"""
Nitro nodes deployment module for Kurtosis-Orbit.
This module handles the deployment of Arbitrum Nitro nodes (sequencer, validator, batch poster).
"""

# Default Nitro node version
NITRO_NODE_VERSION = "offchainlabs/nitro-node:v3.5.5-90ee45c"

# Default private key for development
DEV_PRIVATE_KEY = "b6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659"

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
    
    # 1. First deploy the sequencer node
    sequencer = deploy_sequencer_node(plan, config, l1_info, rollup_info)
    
    # 2. Deploy validator node(s) if configured
    validators = []
    if config.validator_count > 0:
        for i in range(config.validator_count):
            validators.append(deploy_validator_node(plan, config, l1_info, rollup_info, sequencer, i))
    
    # 3. Deploy batch poster node if configured separately (otherwise sequencer handles it)
    batch_posters = []
    if not config.simple_mode and config.batch_poster_count > 0:
        for i in range(config.batch_poster_count):
            batch_posters.append(deploy_batch_poster_node(plan, config, l1_info, rollup_info, i))
    
    return {
        "sequencer": sequencer,
        "validators": validators,
        "batch_posters": batch_posters,
    }

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
    # Create sequencer configuration
    sequencer_config = {
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
            "sequencer": {
                "enable": True,
                "dangerous": {
                    "without-block-validator": True
                }
            },
            "feed": {
                "output": {
                    "enable": True,
                    "port": 9642
                }
            },
            "batch-poster": {
                "enable": config.simple_mode,  # Enable batch poster in simple mode
                "max-size": {"l1-messages": 20, "data": 90000}
            },
            "staker": {
                "enable": config.simple_mode,  # Enable staker in simple mode
                "dangerous": {
                    "without-block-validator": True
                }
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
            "chain": "/home/user/.arbitrum/local/nitro"
        }
    }
    
    # If anytrust mode is enabled, add DAS configuration
    if not config.rollup_mode:
        sequencer_config["node"]["data-availability"] = {
            "enable": True,
            "mode": "anytrust",
            "rest-aggregator": {
                "enable": True,
                "urls": ["http://das-server:9876"]
            }
        }
    
    # Create sequencer configuration file
    sequencer_config_json = json.encode(sequencer_config)
    sequencer_config_artifact = plan.render_templates(
        config={
            "/sequencer_config.json": struct(
                template="{sequencer_config_json}",
                data={"sequencer_config_json": sequencer_config_json},
            ),
        },
        name="sequencer-config",
    )
    
    # Create volume for sequencer data
    sequencer_data_artifact = plan.upload_files(src="./files/seqdata/.gitkeep", name="seqdata-placeholder")
    
    # Deploy the sequencer node
    sequencer_service = plan.add_service(
        name="sequencer",
        config=ServiceConfig(
            image=NITRO_NODE_VERSION,
            ports={
                "http": PortSpec(number=8547, transport_protocol="TCP", application_protocol="http"),
                "ws": PortSpec(number=8548, transport_protocol="TCP", application_protocol="ws"),
                "feed": PortSpec(number=9642, transport_protocol="TCP", application_protocol="ws"),
            },
            cmd=[
                "--conf.file=/config/sequencer_config.json",
                "--node.feed.output.enable",
                "--node.feed.output.port=9642",
                "--http.api=net,web3,eth,debug",
            ],
            env_vars={
                "NITRO_SEQUENCER_PRIVATE_KEY": config.owner_private_key if hasattr(config, 'owner_private_key') else DEV_PRIVATE_KEY,
            },
            files={
                "/home/user/.arbitrum/local/nitro": sequencer_data_artifact,
                "/config/sequencer_config.json": sequencer_config_artifact,
                "/config/chain_info.json": rollup_info["artifacts"]["chain_info"],
            },
        ),
    )
    
    # Wait for sequencer to start
    plan.wait(
        service_name="sequencer",
        recipe=GetHttpRequestRecipe(
            port_id="http",
            endpoint="",
            extract={
                "blockNumber": ".result"
            }
        ),
        field="code",
        assertion="==",
        target_value=200,
        timeout="2m",
    )
    
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
            "chain": "/home/user/.arbitrum/local/nitro"
        }
    }
    
    # If anytrust mode is enabled, add DAS configuration
    if not config.rollup_mode:
        validator_config["node"]["data-availability"] = {
            "enable": True,
            "mode": "onchain",
            "rest-aggregator": {
                "enable": True,
                "urls": ["http://das-server:9876"]
            }
        }
    
    # Create validator configuration file
    validator_config_json = json.encode(validator_config)
    validator_config_artifact = plan.render_templates(
        config={
            "/validator_config.json": struct(
                template="{validator_config_json}",
                data={"validator_config_json": validator_config_json},
            ),
        },
        name="validator-" + str(index) + "-config",
    )
    
    # Create volume for validator data
    validator_data_artifact = plan.upload_files(
        src="./files/valdata/.gitkeep", 
        name="valdata-" + str(index) + "-placeholder"
    )
    
    # Deploy the validator node
    validator_service = plan.add_service(
        name="validator-" + str(index),
        config=ServiceConfig(
            image=NITRO_NODE_VERSION,
            ports={
                "http": PortSpec(number=8547, transport_protocol="TCP", application_protocol="http"),
                "ws": PortSpec(number=8548, transport_protocol="TCP", application_protocol="ws"),
            },
            cmd=[
                "--conf.file=/config/validator_config.json",
                "--http.api=net,web3,eth,debug",
            ],
            files={
                "/home/user/.arbitrum/local/nitro": validator_data_artifact,
                "/config/validator_config.json": validator_config_artifact,
                "/config/chain_info.json": rollup_info["artifacts"]["chain_info"],
            },
        ),
    )
    
    # Wait for validator to start
    plan.wait(
        service_name="validator-" + str(index),
        recipe=GetHttpRequestRecipe(
            port_id="http",
            endpoint="",
            extract={
                "blockNumber": ".result"
            }
        ),
        field="code",
        assertion="==",
        target_value=200,
        timeout="2m",
    )
    
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
                "max-size": {"l1-messages": 20, "data": 90000}
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
            "chain": "/home/user/.arbitrum/local/nitro"
        }
    }
    
    # Create batch poster configuration file
    batch_poster_config_json = json.encode(batch_poster_config)
    batch_poster_config_artifact = plan.render_templates(
        config={
            "/batch_poster_config.json": struct(
                template="{batch_poster_config_json}",
                data={"batch_poster_config_json": batch_poster_config_json},
            ),
        },
        name="batch-poster-" + str(index) + "-config",
    )
    
    # Create volume for batch poster data
    batch_poster_data_artifact = plan.upload_files(
        src="./files/posterdata/.gitkeep", 
        name="posterdata-" + str(index) + "-placeholder"
    )
    
    # Deploy the batch poster node
    batch_poster_service = plan.add_service(
        name="batch-poster-" + str(index),
        config=ServiceConfig(
            image=NITRO_NODE_VERSION,
            ports={
                "http": PortSpec(number=8547, transport_protocol="TCP", application_protocol="http"),
                "ws": PortSpec(number=8548, transport_protocol="TCP", application_protocol="ws"),
            },
            cmd=[
                "--conf.file=/config/batch_poster_config.json",
                "--http.api=net,web3,eth,debug",
            ],
            env_vars={
                "NITRO_BATCHPOSTER_PRIVATE_KEY": config.owner_private_key if hasattr(config, 'owner_private_key') else DEV_PRIVATE_KEY,
            },
            files={
                "/home/user/.arbitrum/local/nitro": batch_poster_data_artifact,
                "/config/batch_poster_config.json": batch_poster_config_artifact,
                "/config/chain_info.json": rollup_info["artifacts"]["chain_info"],
            },
        ),
    )
    
    # Wait for batch poster to start
    plan.wait(
        service_name="batch-poster-" + str(index),
        recipe=GetHttpRequestRecipe(
            port_id="http",
            endpoint="",
            extract={
                "blockNumber": ".result"
            }
        ),
        field="code",
        assertion="==",
        target_value=200,
        timeout="2m",
    )
    
    return {
        "rpc_url": "http://" + batch_poster_service.hostname + ":" + str(batch_poster_service.ports["http"].number),
        "ws_url": "ws://" + batch_poster_service.hostname + ":" + str(batch_poster_service.ports["ws"].number),
    }