"""
Nitro node deployment module with nitro-testnode alignment.
"""

def deploy_nitro_nodes(plan, config, l1_info, rollup_info):
    """
    Deploy Arbitrum Nitro nodes (sequencer and validators).
    """
    plan.print("Deploying Nitro nodes...")
    
    # Deploy validation node first (if validators are enabled)
    validation_node = None
    if config.validator_count > 0:
        validation_node = deploy_validation_node(plan, config, l1_info, rollup_info)
    
    # Deploy sequencer
    sequencer = deploy_sequencer_node(plan, config, l1_info, rollup_info)
    
    # Deploy validators
    validators = []
    for i in range(config.validator_count):
        validator = deploy_validator_node(plan, config, l1_info, rollup_info, sequencer, validation_node, i)
        validators.append(validator)
    
    return {
        "sequencer": sequencer,
        "validators": validators,
        "validation_node": validation_node,
    }

def deploy_sequencer_node(plan, config, l1_info, rollup_info):
    """
    Deploy Nitro sequencer node.
    """
    # Create sequencer configuration
    sequencer_config = {
        "parent-chain": {
            "connection": {
                "url": "http://el-1-geth-lighthouse:8545"
            }
        },
        "chain": {
            "id": config.chain_id,
            "info-files": ["/chain-info/chain_info.json"]
        },
        "node": {
            "sequencer": True,
            "dangerous": {
                "no-sequencer-coordinator": config.simple_mode,
                "disable-blob-reader": True
            },
            "delayed-sequencer": {
                "enable": True
            },
            "batch-poster": {
                "enable": config.simple_mode,
                "max-delay": "30s",
                "l1-block-bound": "ignore",
                "parent-chain-wallet": {
                    "private-key": config.sequencer_private_key
                },
                "data-poster": {
                    "wait-for-l1-finality": False
                }
            },
            "staker": {
                "enable": config.simple_mode,
                "dangerous": {
                    "without-block-validator": True
                },
                "parent-chain-wallet": {
                    "private-key": config.validator_private_key
                },
                "use-smart-contract-wallet": True
            } if config.simple_mode else {},
            "feed": {
                "output": {
                    "enable": True,
                    "port": 9642
                }
            }
        },
        "execution": {
            "sequencer": {
                "enable": True
            },
            "forwarding-target": ""
        },
        "http": {
            "addr": "0.0.0.0",
            "port": 8547,
            "vhosts": "*",
            "corsdomain": "*",
            "api": ["net", "web3", "eth", "debug", "txpool"]
        },
        "ws": {
            "addr": "0.0.0.0", 
            "port": 8548,
            "origins": "*",
            "api": ["net", "web3", "eth", "debug", "txpool"]
        },
        "persistent": {
            "chain": "/home/user/.arbitrum/local/nitro"
        },
        "validation": {
            "wasm": {
                "allowed-wasm-module-roots": [
                    "/home/user/nitro-legacy/machines",
                    "/home/user/target/machines"
                ]
            }
        }
    }
    
    # Create config artifact
    sequencer_config_artifact = plan.render_templates(
        name="sequencer-config",
        config={
            "sequencer_config.json": struct(
                template=json.encode(sequencer_config),
                data={},
            ),
        },
    )
    
    # Deploy sequencer service
    sequencer_service = plan.add_service(
        name="orbit-sequencer",
        config=ServiceConfig(
            image=config.nitro_image,
            ports={
                "rpc": PortSpec(
                    number=8547,
                    transport_protocol="TCP",
                    application_protocol="http",
                    wait="60s"
                ),
                "ws": PortSpec(
                    number=8548,
                    transport_protocol="TCP",
                    application_protocol="ws",
                    wait="60s"
                ),
                "feed": PortSpec(
                    number=9642,
                    transport_protocol="TCP",
                    wait=None
                ),
            },
            cmd=[
                "--conf.file=/config/sequencer_config.json",
                "--node.feed.output.enable",
                "--node.feed.output.port=9642",
                "--http.api=net,web3,eth,debug,txpool",
                "--node.seq-coordinator.my-url=http://orbit-sequencer:8547",
                "--validation.wasm.allowed-wasm-module-roots=/home/user/nitro-legacy/machines,/home/user/target/machines"
            ],
            files={
                "/config": sequencer_config_artifact,
                "/chain-info": rollup_info["artifacts"]["chain_info"],
            },
            ready_conditions=ReadyCondition(
                recipe=PostHttpRequestRecipe(
                    port_id="rpc",
                    endpoint="",
                    content_type="application/json",
                    body='{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
                ),
                field="code",
                assertion="==",
                target_value=200,
                timeout="5m"
            ),
        ),
    )
    
    plan.print("✅ Sequencer node is running!")
    
    return {
        "service": sequencer_service,
        "rpc_url": "http://{}:{}".format(sequencer_service.hostname, 8547),
        "ws_url": "ws://{}:{}".format(sequencer_service.hostname, 8548),
        "feed_url": "ws://{}:{}".format(sequencer_service.hostname, 9642),
    }

def deploy_validation_node(plan, config, l1_info, rollup_info):
    """
    Deploy nitro-val validation node.
    """
    validation_config = {
        "persistent": {
            "chain": "/home/user/.arbitrum/local/nitro"
        },
        "ws": {
            "addr": "",
        },
        "http": {
            "addr": "",
        },
        "validation": {
            "api-auth": True,
            "api-public": False,
        },
        "auth": {
            "jwtsecret": "/config/val_jwt.hex",
            "addr": "0.0.0.0",
            "port": 8549,
        },
    }
    
    # Create config artifact with JWT file included
    validation_config_artifact = plan.render_templates(
        name="validation-node-config",
        config={
            "validation_node_config.json": struct(
                template=json.encode(validation_config),
                data={},
            ),
            "val_jwt.hex": struct(
                template=config.val_jwt_secret,
                data={},
            ),
        },
    )
    
    # Deploy validation node
    validation_service = plan.add_service(
        name="validation-node",
        config=ServiceConfig(
            image=config.nitro_image,
            entrypoint=["/usr/local/bin/nitro-val"],
            cmd=["--conf.file=/config/validation_node_config.json"],
            ports={
                "api": PortSpec(
                    number=8549,
                    transport_protocol="TCP",
                    wait="30s"
                ),
            },
            files={
                "/config": validation_config_artifact,
            },
        ),
    )
    
    plan.print("✅ Validation node is running!")
    
    return {
        "service": validation_service,
        "url": "http://{}:{}".format(validation_service.hostname, 8549),
        "jwt": config.val_jwt_secret,
    }

def deploy_validator_node(plan, config, l1_info, rollup_info, sequencer, validation_node, index):
    """
    Deploy Nitro validator node.
    """
    # Create validator configuration
    validator_config = {
        "parent-chain": {
            "connection": {
                "url": "http://el-1-geth-lighthouse:8545"
            }
        },
        "chain": {
            "id": config.chain_id,
            "info-files": ["/chain-info/chain_info.json"]
        },
        "node": {
            "feed": {
                "input": {
                    "url": "ws://orbit-sequencer:9642"
                }
            },
            "staker": {
                "enable": True,
                "dangerous": {
                    "without-block-validator": False
                },
                "parent-chain-wallet": {
                    "private-key": config.validator_private_key
                },
                "use-smart-contract-wallet": True
            },
            "sequencer": False,
            "dangerous": {
                "no-sequencer-coordinator": False,
                "disable-blob-reader": True
            },
            "delayed-sequencer": {
                "enable": False
            },
            "batch-poster": {
                "enable": False
            },
            "block-validator": {
                "validation-server": {
                    "url": "ws://validation-node:8549",
                    "jwtsecret": "/config/val_jwt.hex",
                }
            } if validation_node else {}
        },
        "execution": {
            "sequencer": {
                "enable": False
            },
            "forwarding-target": "http://orbit-sequencer:8547"
        },
        "http": {
            "addr": "0.0.0.0",
            "port": 8547,
            "vhosts": "*",
            "corsdomain": "*",
            "api": ["net", "web3", "eth", "debug"]
        },
        "ws": {
            "addr": "0.0.0.0",
            "port": 8548,
            "origins": "*",
            "api": ["net", "web3", "eth", "debug"]
        },
        "persistent": {
            "chain": "/home/user/.arbitrum/local/nitro"
        },
        "validation": {
            "wasm": {
                "allowed-wasm-module-roots": [
                    "/home/user/nitro-legacy/machines",
                    "/home/user/target/machines"
                ]
            }
        }
    }
    
    # Create config artifact with JWT file included
    validator_config_artifact = plan.render_templates(
        name="validator-{}-config".format(index),
        config={
            "validator_config.json": struct(
                template=json.encode(validator_config),
                data={},
            ),
            "val_jwt.hex": struct(
                template=config.val_jwt_secret,
                data={},
            ),
        },
    )
    
    # Deploy validator service
    validator_service = plan.add_service(
        name="orbit-validator-{}".format(index),
        config=ServiceConfig(
            image=config.nitro_image,
            ports={
                "rpc": PortSpec(
                    number=8547,
                    transport_protocol="TCP",
                    application_protocol="http",
                    wait="60s"
                ),
                "ws": PortSpec(
                    number=8548,
                    transport_protocol="TCP",
                    application_protocol="ws"
                ),
            },
            cmd=[
                "--conf.file=/config/validator_config.json",
                "--http.api=net,web3,eth,debug",
                "--validation.wasm.allowed-wasm-module-roots=/home/user/nitro-legacy/machines,/home/user/target/machines"
            ],
            files={
                "/config": validator_config_artifact,
                "/chain-info": rollup_info["artifacts"]["chain_info"],
            },
            ready_conditions=ReadyCondition(
                recipe=PostHttpRequestRecipe(
                    port_id="rpc",
                    endpoint="",
                    content_type="application/json",
                    body='{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
                ),
                field="code",
                assertion="==",
                target_value=200,
                timeout="3m"
            ),
        ),
    )
    
    plan.print("✅ Validator {} is running!".format(index))
    
    return {
        "service": validator_service,
        "rpc_url": "http://{}:{}".format(validator_service.hostname, 8547),
        "ws_url": "ws://{}:{}".format(validator_service.hostname, 8548),
    }