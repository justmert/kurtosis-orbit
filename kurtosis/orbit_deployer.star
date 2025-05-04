"""
Orbit Contracts Deployment and Node configuration for Kurtosis-Orbit package.

This module handles the deployment of Arbitrum Orbit rollup contracts on the L1 chain,
and starts the Arbitrum Nitro sequencer and validator nodes.
"""

utils = import_module("./utils.star")
json = import_module("json")

def deploy_orbit_contracts(plan, orbit_config, l1_output):
    """
    Deploy Arbitrum Orbit contracts on the L1 chain.
    
    Args:
        plan: The Kurtosis execution plan
        orbit_config: Configuration object for the deployment
        l1_output: Output from the L1 chain setup
    
    Returns:
        DeployOutput with contract addresses and chain info
    """
    plan.print("Deploying Arbitrum Orbit contracts...")
    
    # Create a service that will deploy the Orbit contracts
    # Using the official Node.js image with Orbit SDK
    
    # First, create our deployment script - changed to use upload_files
    deploy_script_artifact = plan.upload_files(
        src = "scripts/deploy-orbit.js",
        name = "orbit-deploy-script"
    )
    
    package_json_artifact = plan.upload_files(
        src = "scripts/package.json",
        name = "orbit-package-json"
    )
    
    # Deploy the contracts
    deployer_service = plan.add_service(
        name = "orbit-deployer",
        config = ServiceConfig(
            image = "node:18",
            files = {
                "/app/deploy-orbit.js": deploy_script_artifact,
                "/app/package.json": package_json_artifact
            },
            entrypoint = ["/bin/sh", "-c"],
            cmd = [
                "cd /app && npm install && node deploy-orbit.js"
            ],
            env_vars = {
                "RPC_URL": l1_output.rpc_endpoint,
                "OWNER_KEY": orbit_config.owner_private_key,
                "CHAIN_ID": str(orbit_config.chain_id),
                "CHAIN_NAME": orbit_config.chain_name,
                "CHALLENGE_PERIOD": str(orbit_config.challenge_period_blocks),
                "STAKE_TOKEN": orbit_config.stake_token,
                "BASE_STAKE": orbit_config.base_stake,
                "ROLLUP_MODE": orbit_config.rollup_mode
            }
        )
    )
    
    # Wait for the deployment to complete
    plan.wait(
        service_name = "orbit-deployer",
        recipe = ExecRecipe(
            command = ["ls", "-la", "/app"]
        ),
        field = "code",
        assertion = "==",
        target_value = 0,
        timeout = "5m"
    )
    
    # Check if deployment-result.json exists
    deploy_result = plan.exec(
        service_name = "orbit-deployer",
        recipe = ExecRecipe(
            command = ["test", "-f", "/app/deployment-result.json"]
        )
    )
    
    if deploy_result["code"] != 0:
        fail("Deployment failed: Could not find deployment-result.json")
    
    # Get the contract addresses from the deployment
    contract_addresses_result = plan.exec(
        service_name = "orbit-deployer",
        recipe = ExecRecipe(
            command = ["cat", "/app/contract-addresses.json"]
        )
    )
    
    if contract_addresses_result["code"] != 0:
        fail("Failed to get contract addresses")
    
    # Store the chain info JSON as an artifact
    chain_info_artifact = plan.store_service_files(
        service_name = "orbit-deployer",
        src = "/app/chain-info.json",
        name = "chain-info"
    )
    
    # Get the validator key from the deployment (for fraud proofs)
    validator_key_result = plan.exec(
        service_name = "orbit-deployer",
        recipe = ExecRecipe(
            command = ["cat", "/app/validator-key.txt"]
        )
    )
    
    validator_key = ""
    if validator_key_result["code"] == 0:
        validator_key = validator_key_result["output"].strip()
    
    plan.print("Arbitrum Orbit contracts deployed successfully")
    
    # Parse the contract addresses
    contract_addresses = {}
    if contract_addresses_result["code"] == 0:
        # In Starlark, we can't use try-except, so we'll need to be more careful here
        # We'll use a default empty object if parsing fails
        contract_addresses_text = contract_addresses_result["output"]
        if contract_addresses_text:
            parsed_addresses = json.decode(contract_addresses_text)
            if parsed_addresses:
                contract_addresses = parsed_addresses
            else:
                plan.print("Warning: Contract addresses JSON parsed to null")
        else:
            plan.print("Warning: Contract addresses text was empty")
    
    return struct(
        contract_addresses = contract_addresses,
        chain_info_artifact = chain_info_artifact,
        validator_key = validator_key
    )

def start_sequencer(plan, orbit_config, l1_output, deploy_output):
    """
    Start an Arbitrum Nitro Sequencer node.
    
    Args:
        plan: The Kurtosis execution plan
        orbit_config: Configuration object for the deployment
        l1_output: Output from the L1 chain setup
        deploy_output: Output from the contract deployment
    
    Returns:
        SequencerOutput with sequencer connection information
    """
    plan.print("Starting Arbitrum Nitro Sequencer node...")
    
    sequencer_service = plan.add_service(
        name = "orbit-sequencer",
        config = ServiceConfig(
            image = orbit_config.nitro_image,
            files = {
                "/home/user/.arbitrum/chain-info.json": deploy_output.chain_info_artifact
            },
            cmd = [
                "--parent-chain.connection.url=" + l1_output.rpc_endpoint,
                "--chain.info-json=/home/user/.arbitrum/chain-info.json",
                "--chain.name=" + orbit_config.chain_name,
                "--node.sequencer.enable=true",
                "--node.sequencer.key=" + orbit_config.owner_private_key,
                "--node.feed.output.enable=true",
                "--node.feed.output.port=9642",
                "--init.url=file:///home/user/.arbitrum/chain-info.json",
                "--http.api=net,web3,eth,debug",
                "--http.corsdomain=*",
                "--http.addr=0.0.0.0",
                "--http.port=8547",
                "--http.vhosts=*",
                "--ws.port=8548",
                "--ws.addr=0.0.0.0",
                "--ws.origins=*"
            ],
            ports = {
                "rpc": PortSpec(
                    number = 8547,
                    transport_protocol = "TCP"
                ),
                "ws": PortSpec(
                    number = 8548,
                    transport_protocol = "TCP"
                ),
                "feed": PortSpec(
                    number = 9642,
                    transport_protocol = "TCP"
                )
            }
        }
    )
    
    # Wait for the sequencer to be ready by querying the RPC
    sequencer_rpc_endpoint = "http://orbit-sequencer:8547"
    utils.wait_for_http_endpoint(plan, sequencer_rpc_endpoint, '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}')
    
    plan.print("Arbitrum Nitro Sequencer node is ready")
    
    return struct(
        rpc_endpoint = sequencer_rpc_endpoint,
        ws_endpoint = "ws://orbit-sequencer:8548",
        feed_endpoint = "ws://orbit-sequencer:9642",
        service_name = "orbit-sequencer"
    )

def start_validator(plan, orbit_config, l1_output, deploy_output, sequencer_output, index):
    """
    Start an Arbitrum Nitro Validator node.
    
    Args:
        plan: The Kurtosis execution plan
        orbit_config: Configuration object for the deployment
        l1_output: Output from the L1 chain setup
        deploy_output: Output from the contract deployment
        sequencer_output: Output from the sequencer setup
        index: Validator index (for naming when multiple validators)
    
    Returns:
        ValidatorOutput with validator connection information
    """
    plan.print("Starting Arbitrum Nitro Validator node " + str(index) + "...")
    
    validator_service_name = "orbit-validator-" + str(index)
    
    validator_service = plan.add_service(
        name = validator_service_name,
        config = ServiceConfig(
            image = orbit_config.nitro_image,
            files = {
                "/home/user/.arbitrum/chain-info.json": deploy_output.chain_info_artifact
            },
            cmd = [
                "--parent-chain.connection.url=" + l1_output.rpc_endpoint,
                "--chain.info-json=/home/user/.arbitrum/chain-info.json",
                "--chain.name=" + orbit_config.chain_name,
                "--node.feed.input.url=" + sequencer_output.feed_endpoint,
                "--execution.forwarding-target=" + sequencer_output.rpc_endpoint,
                "--http.api=net,web3,eth",
                "--http.corsdomain=*",
                "--http.addr=0.0.0.0",
                "--http.port=8547",
                "--http.vhosts=*",
                "--ws.port=8548",
                "--ws.addr=0.0.0.0",
                "--ws.origins=*"
            ],
            ports = {
                "rpc": PortSpec(
                    number = 8547,
                    transport_protocol = "TCP"
                ),
                "ws": PortSpec(
                    number = 8548,
                    transport_protocol = "TCP"
                )
            }
        }
    )
    
    # Wait for the validator to be ready by querying the RPC
    validator_rpc_endpoint = "http://" + validator_service_name + ":8547"
    utils.wait_for_http_endpoint(plan, validator_rpc_endpoint, '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}')
    
    plan.print("Arbitrum Nitro Validator node " + str(index) + " is ready")
    
    return struct(
        rpc_endpoint = validator_rpc_endpoint,
        ws_endpoint = "ws://" + validator_service_name + ":8548",
        service_name = validator_service_name
    )