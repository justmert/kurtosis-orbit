"""
Corrected Nitro nodes deployment module for Kurtosis-Orbit.
This module handles the deployment of Arbitrum Nitro nodes (sequencer, validator, batch poster).
Based on nitro-testnode repository and Arbitrum documentation.
"""

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
    
    # Validate required artifacts
    if "artifacts" not in rollup_info or "chain_info" not in rollup_info["artifacts"]:
        fail("Error: Missing chain_info artifact in rollup_info. Deployment may have failed.")

    plan.print("Using chain_info from rollup deployment")
    
    # 1. Deploy the sequencer node
    sequencer = deploy_sequencer_node(plan, config, l1_info, rollup_info)
    
    # 2. Deploy validator node(s) if configured
    validators = []
    validator_count = getattr(config, "validator_count", 1)
    if validator_count > 0:
        for i in range(validator_count):
            plan.print("Deploying validator node " + str(i+1) + "/" + str(validator_count) + "...")
            validators.append(deploy_validator_node(plan, config, l1_info, rollup_info, sequencer, i))
    
    return {
        "sequencer": sequencer,
        "validators": validators,
    }

def deploy_sequencer_node(plan, config, l1_info, rollup_info):
    """
    Deploy an Arbitrum Nitro sequencer node following nitro-testnode patterns
    """
    plan.print("Deploying sequencer node...")
    
    # Get configuration values with defaults
    chain_id = getattr(config, "chain_id", 412346)
    chain_name = getattr(config, "chain_name", "OrbitDevChain")
    simple_mode = getattr(config, "simple_mode", True)
    
    # Use the sequencer account (matching nitro-testnode)
    sequencer_key = DEFAULT_ACCOUNTS["sequencer"]["private_key"]
    sequencer_address = DEFAULT_ACCOUNTS["sequencer"]["address"]
    
    # Create sequencer configuration matching nitro-testnode structure
    sequencer_config = {
        "ensure-rollup-deployment": False,  # Important: don't try to deploy rollup
        "parent-chain": {
            "connection": {
                "url": "http://el-1-geth-lighthouse:8545"
            }
        },
        "chain": {
            "id": chain_id,
            "info-files": ["/chain-info/chain_info.json"]
        },
        "node": {
            "sequencer": True,
            "dangerous": {
                "no-sequencer-coordinator": simple_mode,
                "disable-blob-reader": True
            },
            "delayed-sequencer": {
                "enable": True
            },
            "batch-poster": {
                "enable": simple_mode,
                "max-delay": "30s",
                "l1-block-bound": "ignore",
                "parent-chain-wallet": {
                    "private-key": sequencer_key
                },
                "data-poster": {
                    "wait-for-l1-finality": False
                }
            },
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
    
    # Convert to JSON for config file
    sequencer_config_json = json.encode(sequencer_config)
    
    # Create config file artifact
    sequencer_config_artifact = plan.render_templates(
        name="sequencer-config",
        config={
            "sequencer_config.json": struct(
                template=sequencer_config_json,
                data={},
            ),
        },
    )
    
    # Deploy the sequencer service - following nitro-testnode patterns
    sequencer_service = plan.add_service(
        name="orbit-sequencer",
        config=ServiceConfig(
            image=NITRO_NODE_VERSION,
            ports={
                "rpc": PortSpec(
                    number=8547, 
                    transport_protocol="TCP", 
                    application_protocol="http"
                ),
                "ws": PortSpec(
                    number=8548, 
                    transport_protocol="TCP", 
                    application_protocol="ws"
                ),
                "feed": PortSpec(
                    number=9642, 
                    transport_protocol="TCP", 
                    wait=None  # Don't wait for this port immediately
                ),
            },
            # Use command pattern from nitro-testnode with proper initialization
            cmd=[
                "--conf.file=/config/sequencer_config.json",
                "--node.feed.output.enable",
                "--node.feed.output.port=9642",
                "--http.api=net,web3,eth,debug,txpool",
                "--node.seq-coordinator.my-url=http://orbit-sequencer:8547",
                "--validation.wasm.allowed-wasm-module-roots=/home/user/nitro-legacy/machines,/home/user/target/machines"
            ],
            env_vars={
                # Environment variables are optional, the config file has the key
            },
            files={
                "/config": sequencer_config_artifact,
                "/chain-info": rollup_info["artifacts"]["chain_info"],
            },
            # Add ready condition to wait for RPC to be available
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
            ),
        ),
    )
    
    # Test the RPC endpoint is working
    plan.wait(
        service_name="orbit-sequencer",
        recipe=PostHttpRequestRecipe(
            port_id="rpc",
            endpoint="",
            content_type="application/json",
            body='{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}',
        ),
        field="code",
        assertion="==",
        target_value=200,
        timeout="2m",
    )
    
    plan.print("Sequencer node is running and accessible!")
    
    return {
        "rpc_url": "http://" + sequencer_service.hostname + ":" + str(sequencer_service.ports["rpc"].number),
        "ws_url": "ws://" + sequencer_service.hostname + ":" + str(sequencer_service.ports["ws"].number),
        "feed_url": "ws://" + sequencer_service.hostname + ":" + str(sequencer_service.ports["feed"].number),
    }

def deploy_validator_node(plan, config, l1_info, rollup_info, sequencer, index):
    """
    Deploy an Arbitrum Nitro validator node
    """
    chain_id = getattr(config, "chain_id", 412346)
    
    # Use the validator account
    validator_key = DEFAULT_ACCOUNTS["validator"]["private_key"]
    
    # Create validator configuration
    validator_config = {
        "ensure-rollup-deployment": False,  # Important: don't try to deploy rollup
        "parent-chain": {
            "connection": {
                "url": "http://el-1-geth-lighthouse:8545"
            }
        },
        "chain": {
            "id": chain_id,
            "info-files": ["/chain-info/chain_info.json"]
        },
        "node": {
            "feed": {
                "input": {
                    "url": "ws://orbit-sequencer:9642"  # Use static service reference
                }
            },
            "staker": {
                "enable": True,
                "dangerous": {
                    "without-block-validator": True  # Unsafe staker mode for development
                },
                "parent-chain-wallet": {
                    "private-key": validator_key
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
            }
        },
        "execution": {
            "sequencer": {
                "enable": False
            },
            "forwarding-target": "http://orbit-sequencer:8547"  # Use static service reference
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
    
    validator_config_json = json.encode(validator_config)
    validator_config_artifact = plan.render_templates(
        name="validator-" + str(index) + "-config",
        config={
            "validator_config.json": struct(
                template=validator_config_json,
                data={},
            ),
        },
    )
    
    # Deploy the validator node
    validator_name = "orbit-validator-" + str(index)
    validator_service = plan.add_service(
        name=validator_name,
        config=ServiceConfig(
            image=NITRO_NODE_VERSION,
            ports={
                "rpc": PortSpec(
                    number=8547, 
                    transport_protocol="TCP", 
                    application_protocol="http"
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
            env_vars={},
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
            ),
        ),
    )
    
    plan.print("Validator-" + str(index) + " node is running!")
    
    return {
        "rpc_url": "http://" + validator_service.hostname + ":" + str(validator_service.ports["rpc"].number),
        "ws_url": "ws://" + validator_service.hostname + ":" + str(validator_service.ports["ws"].number),
    }