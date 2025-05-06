"""
Orbit Contracts Deployment and Node configuration for Kurtosis-Orbit package.

This module handles the deployment of Arbitrum Orbit rollup contracts on the L1 chain,
and starts the Arbitrum Nitro sequencer and validator nodes.
"""

utils = import_module("./utils.star")

def deploy_orbit_contracts(plan, orbit_config, l1_output):
    """
    Deploy Arbitrum Orbit contracts on the L1 chain using the Arbitrum Orbit SDK.
    
    Args:
        plan: The Kurtosis execution plan
        orbit_config: Configuration object for the deployment
        l1_output: Output from the L1 chain setup
    
    Returns:
        DeployOutput with contract addresses and chain info
    """
    plan.print("Deploying Arbitrum Orbit contracts...")
    
    # Upload our deployment script and package.json
    deploy_script_artifact = plan.upload_files(
        src = "scripts/deploy-orbit.js", 
        name = "orbit-deploy-script"
    )
    
    package_json_artifact = plan.upload_files(
        src = "scripts/package.json",
        name = "orbit-package-json"
    )
    
    # Deploy the contracts - using a more robust deployment approach
    deployer_service = plan.add_service(
        name = "orbit-deployer",
        config = ServiceConfig(
            image = "node:18",
            files = {
                "/app/deploy-orbit.js": deploy_script_artifact,
                "/app/package.json": package_json_artifact
            },
            entrypoint = ["/bin/bash", "-c"],
            cmd = [
                "cd /app && " +
                "echo 'NODE VERSION:' && node --version && " +
                "echo 'NPM VERSION:' && npm --version && " +
                "echo 'INSTALLING DEPENDENCIES...' && " +
                "npm install --no-fund && " +  # Speed up install by skipping funding messages
                "echo 'RUNNING DEPLOYMENT SCRIPT...' && " +
                "export NODE_OPTIONS='--max-old-space-size=4096' && " +  # Increase Node memory limit
                "node deploy-orbit.js || exit 1 && " +  # Exit on script error
                "echo 'DEPLOYMENT COMPLETED SUCCESSFULLY' && " +
                "touch /app/deployment-complete && " +
                "tail -f /dev/null"  # Keep container alive for file extraction
            ],
            env_vars = {
                "RPC_URL": l1_output.rpc_endpoint,
                "OWNER_KEY": orbit_config.owner_private_key,
                "CHAIN_ID": str(orbit_config.chain_id),
                "CHAIN_NAME": orbit_config.chain_name,
                "CHALLENGE_PERIOD": str(orbit_config.challenge_period_blocks),
                "STAKE_TOKEN": orbit_config.stake_token,
                "BASE_STAKE": orbit_config.base_stake,
                "ROLLUP_MODE": orbit_config.rollup_mode,
                "DEBUG": "true"
            }
        ),
    )
    
    # Wait for deployment completion with timeout
    plan.print("Waiting for contract deployment to complete...")
    deployment_check = plan.wait(
        service_name = "orbit-deployer",
        recipe = ExecRecipe(
            command = ["test", "-f", "/app/deployment-complete"]
        ),
        field = "code",
        assertion = "==",
        target_value = 0,
        timeout = "5m",  # 5 minute timeout for deployment
        interval = "10s"  # Check every 10 seconds
    )
    
    # Verify deployment by checking for expected output files
    files_check = plan.exec(
        service_name = "orbit-deployer",
        recipe = ExecRecipe(
            command = ["ls", "-la", "/app"]
        )
    )
    plan.print("Files in /app directory: " + files_check["output"])
    
    # Verify chain-info.json exists
    chain_info_check = plan.exec(
        service_name = "orbit-deployer",
        recipe = ExecRecipe(
            command = ["test", "-f", "/app/chain-info.json"]
        )
    )
    
    if chain_info_check["code"] != 0:
        fail(chain_info_check['code'])
    
    # Store chain info artifact
    chain_info_artifact = plan.store_service_files(
        service_name = "orbit-deployer",
        src = "/app/chain-info.json",
        name = "chain-info"
    )
    
    # Get contract addresses
    contract_addresses_result = plan.exec(
        service_name = "orbit-deployer",
        recipe = ExecRecipe(
            command = ["cat", "/app/contract-addresses.json"]
        )
    )
    
    if contract_addresses_result["code"] != 0:
        plan.print("Warning: Failed to get contract addresses, using empty object")
        contract_addresses = {}
    else:
        # Parse contract addresses safely without try/catch
        contract_addresses_text = contract_addresses_result["output"]
        if contract_addresses_text and len(contract_addresses_text.strip()) > 0:
            # Attempt to decode the JSON
            contract_addresses = json.decode(contract_addresses_text)
            if contract_addresses == None:
                plan.print("Warning: Contract addresses JSON parsed to null, using empty object")
                contract_addresses = {}
        else:
            plan.print("Warning: Contract addresses text was empty, using empty object")
            contract_addresses = {}
    
    # Get validator key
    validator_key_result = plan.exec(
        service_name = "orbit-deployer",
        recipe = ExecRecipe(
            command = ["cat", "/app/validator-key.txt"]
        )
    )
    
    validator_key = ""
    if validator_key_result["code"] == 0:
        validator_key = validator_key_result["output"].strip()
    else:
        # Fallback to owner key if validator key not found
        validator_key = orbit_config.owner_private_key
        plan.print("Warning: validator-key.txt not found, using owner key as fallback")
    
    plan.print("Arbitrum Orbit contracts deployed successfully")
    
    # Output key contract addresses for debugging
    if contract_addresses and "rollup" in contract_addresses:
        plan.print("Rollup address: " + contract_addresses["rollup"])
    if contract_addresses and "sequencerInbox" in contract_addresses:
        plan.print("SequencerInbox address: " + contract_addresses["sequencerInbox"])
    
    return struct(
        contract_addresses = contract_addresses,
        chain_info_artifact = chain_info_artifact,
        validator_key = validator_key
    )        
# def deploy_orbit_contracts(plan, orbit_config, l1_output):
#     """
#     Deploy Arbitrum Orbit contracts on the L1 chain.
#     """
#     plan.print("Deploying Arbitrum Orbit contracts...")
    
#     # Create a temporary service just to generate the chain-info.json file
#     simple_service = plan.add_service(
#         name = "orbit-deployer",
#         config = ServiceConfig(
#             image = "node:18",
#             entrypoint = ["/bin/sh", "-c"],
#             cmd = [
#                 # Create a minimal but valid chain-info.json file
#                 "mkdir -p /app && " +
#                 "echo '{\"chain-id\": " + str(orbit_config.chain_id) + ", " + 
#                 "\"parent-chain-id\": " + str(orbit_config.l1_chain_id) + ", " + 
#                 "\"chain-name\": \"" + orbit_config.chain_name + "\", " + 
#                 "\"rollup\": {" + 
#                 "\"rollup-address\": \"0x1234567890123456789012345678901234567890\", " + 
#                 "\"inbox-address\": \"0x1234567890123456789012345678901234567890\", " + 
#                 "\"sequencer-inbox-address\": \"0x1234567890123456789012345678901234567890\", " + 
#                 "\"bridge-address\": \"0x1234567890123456789012345678901234567890\"" + 
#                 "}}' > /app/chain-info.json && " +
                
#                 # Also create a contract-addresses.json file
#                 "echo '{" + 
#                 "\"rollup\": \"0x1234567890123456789012345678901234567890\", " + 
#                 "\"inbox\": \"0x1234567890123456789012345678901234567890\", " + 
#                 "\"sequencerInbox\": \"0x1234567890123456789012345678901234567890\", " + 
#                 "\"bridge\": \"0x1234567890123456789012345678901234567890\", " + 
#                 "\"outbox\": \"0x1234567890123456789012345678901234567890\"" + 
#                 "}' > /app/contract-addresses.json && " +
                
#                 # Create a validator key file
#                 "echo '" + orbit_config.owner_private_key + "' > /app/validator-key.txt && " +
                
#                 # Keep the container running
#                 "echo 'Files created successfully' && " +
#                 "tail -f /dev/null"
#             ]
#         ),
#     )
    
#     # Wait a moment to ensure files are created
#     plan.exec(
#         service_name = "orbit-deployer",
#         recipe = ExecRecipe(
#             command = ["sleep", "2"]
#         )
#     )
    
#     # Verify files were created
#     ls_result = plan.exec(
#         service_name = "orbit-deployer",
#         recipe = ExecRecipe(
#             command = ["ls", "-la", "/app"]
#         )
#     )
#     plan.print("Files in /app directory: " + ls_result["output"])
    
#     # Store the chain info JSON as an artifact
#     chain_info_artifact = plan.store_service_files(
#         service_name = "orbit-deployer",
#         src = "/app/chain-info.json",
#         name = "chain-info"
#     )
    
#     # Get the contract addresses from our manually created file
#     contract_addresses_result = plan.exec(
#         service_name = "orbit-deployer",
#         recipe = ExecRecipe(
#             command = ["cat", "/app/contract-addresses.json"]
#         )
#     )
    
#     contract_addresses = {
#         "rollup": "0x1234567890123456789012345678901234567890",
#         "inbox": "0x1234567890123456789012345678901234567890",
#         "sequencerInbox": "0x1234567890123456789012345678901234567890",
#         "bridge": "0x1234567890123456789012345678901234567890",
#         "outbox": "0x1234567890123456789012345678901234567890"
#     }
    
#     if contract_addresses_result["code"] == 0:
#         # Parse the output
#         contract_addresses_json = contract_addresses_result["output"]
#         if contract_addresses_json and len(contract_addresses_json) > 0:
#             # Try to decode the JSON
#             contract_addresses = json.decode(contract_addresses_json)
    
#     # Get the validator key
#     validator_key_result = plan.exec(
#         service_name = "orbit-deployer",
#         recipe = ExecRecipe(
#             command = ["cat", "/app/validator-key.txt"]
#         )
#     )
    
#     validator_key = orbit_config.owner_private_key
#     if validator_key_result["code"] == 0:
#         validator_key = validator_key_result["output"].strip()
    
#     plan.print("Arbitrum Orbit contract information prepared successfully")
    
#     return struct(
#         contract_addresses = contract_addresses,
#         chain_info_artifact = chain_info_artifact,
#         validator_key = validator_key
#     )

# def deploy_orbit_contracts(plan, orbit_config, l1_output): # stubs
#     """
#     Deploy Arbitrum Orbit contracts on the L1 chain (STUB IMPLEMENTATION).
#     """
#     plan.print("STUB: Deploying Arbitrum Orbit contracts...")
    
#     # First, test the environment with a simple container
#     plan.print("Testing environment with a simple container...")
#     test_service = plan.add_service(
#         name = "orbit-test",
#         config = ServiceConfig(
#             image = "node:18",
#             entrypoint = ["/bin/sh", "-c"],
#             cmd = ["echo 'TEST RUNNING' && mkdir -p /app && echo '{\"success\":true}' > /app/test.json && sleep 30"]
#         )
#     )
    
#     # Check if basic test works
#     test_result = plan.exec(
#         service_name = "orbit-test",
#         recipe = ExecRecipe(
#             command = ["cat", "/app/test.json"]
#         )
#     )
#     plan.print("Basic test result: " + test_result["output"])
    
#     # Create a temporary minimal chain-info.json file
#     plan.exec(
#         service_name = "orbit-test",
#         recipe = ExecRecipe(
#             command = ["/bin/sh", "-c", "echo '{\"chain-id\": " + str(orbit_config.chain_id) + ", \"parent-chain-id\": " + str(orbit_config.l1_chain_id) + ", \"chain-name\": \"" + orbit_config.chain_name + "\", \"rollup\": {\"rollup-address\": \"0x1234567890123456789012345678901234567890\", \"inbox-address\": \"0x1234567890123456789012345678901234567890\", \"sequencer-inbox-address\": \"0x1234567890123456789012345678901234567890\", \"bridge-address\": \"0x1234567890123456789012345678901234567890\"}}' > /app/chain-info.json"]
#         )
#     )
    
#     # Store the chain info as a real file artifact
#     chain_info_artifact = plan.store_service_files(
#         service_name = "orbit-test",
#         src = "/app/chain-info.json",
#         name = "chain-info"
#     )
    
#     # Return a properly structured result with a real artifact
#     return struct(
#         contract_addresses = {
#             "rollup": "0x1234567890123456789012345678901234567890",
#             "inbox": "0x1234567890123456789012345678901234567890",
#             "sequencerInbox": "0x1234567890123456789012345678901234567890",
#             "bridge": "0x1234567890123456789012345678901234567890",
#             "outbox": "0x1234567890123456789012345678901234567890"
#         },
#         chain_info_artifact = chain_info_artifact,
#         validator_key = "0x1234567890123456789012345678901234567890"
#     )

# def deploy_orbit_contracts(plan, orbit_config, l1_output):
#     """
#     Deploy Arbitrum Orbit contracts on the L1 chain.
#     """
#     plan.print("Deploying Arbitrum Orbit contracts...")
    
#     # First, test the environment with a simple container
#     plan.print("Testing environment with a simple container...")
#     test_service = plan.add_service(
#         name = "orbit-test",
#         config = ServiceConfig(
#             image = "node:18",
#             entrypoint = ["/bin/sh", "-c"],
#             cmd = ["echo 'TEST RUNNING' && mkdir -p /app && echo '{\"success\":true}' > /app/test.json && sleep 30"]
#         )
#     )
    
#     # Check if basic test works
#     test_result = plan.exec(
#         service_name = "orbit-test",
#         recipe = ExecRecipe(
#             command = ["cat", "/app/test.json"]
#         )
#     )
#     plan.print("Basic test result: " + test_result["output"])
    
#     # Create a placeholder struct with minimal data we need
#     # This lets us proceed with testing the rest of the flow
#     return struct(
#         contract_addresses = {
#             "rollup": "0x1234567890123456789012345678901234567890",
#             "inbox": "0x1234567890123456789012345678901234567890",
#             "sequencerInbox": "0x1234567890123456789012345678901234567890",
#             "bridge": "0x1234567890123456789012345678901234567890",
#             "outbox": "0x1234567890123456789012345678901234567890"
#         },
#         chain_info_artifact = "placeholder-artifact",
#         validator_key = "0x1234567890123456789012345678901234567890"
#     )
    
    # # The rest of your deployment code can go here
    # # We've moved it after the return statement so it doesn't execute for now
    # # This lets us test other parts of the flow
    
    # # Deploy the contracts
    # deployer_service = plan.add_service(
    #     name = "orbit-deployer",
    #     config = ServiceConfig(
    #         image = "node:18",
    #         files = {
    #             "/app/deploy-orbit.js": deploy_script_artifact,
    #             "/app/package.json": package_json_artifact
    #         },
    #         entrypoint = ["/bin/sh", "-c"],
    #         cmd = [
    #             "cd /app && " +
    #             "echo 'NPM VERSION:' && npm --version && " +
    #             "echo 'NODE VERSION:' && node --version && " +
    #             "echo 'STARTING NPM INSTALL...' && " +
    #             "npm install && " +
    #             "echo 'NPM INSTALL COMPLETE. RUNNING DEPLOYMENT SCRIPT...' && " +
    #             "node deploy-orbit.js || " +
    #             "(echo 'DEPLOYMENT SCRIPT FAILED' && " + 
    #             "echo '{\"success\": false, \"error\": \"Script execution failed\"}' > /app/deployment-result.json && " +
    #             "exit 1)"
    #         ],
    #         env_vars = {
    #             "RPC_URL": l1_output.rpc_endpoint,
    #             "OWNER_KEY": orbit_config.owner_private_key,
    #             "CHAIN_ID": str(orbit_config.chain_id),
    #             "CHAIN_NAME": orbit_config.chain_name,
    #             "CHALLENGE_PERIOD": str(orbit_config.challenge_period_blocks),
    #             "STAKE_TOKEN": orbit_config.stake_token,
    #             "BASE_STAKE": orbit_config.base_stake,
    #             "ROLLUP_MODE": orbit_config.rollup_mode,
    #             "DEBUG": "true",
    #             "NODE_OPTIONS": "--max-old-space-size=4096"
    #         }
    #     ),
    # )

    # plan.print("Waiting for orbit-deployer service to be ready...")
    # deploy_check = plan.exec(
    #     service_name = "orbit-deployer",
    #     recipe = ExecRecipe(
    #         command = ["ls", "-la", "/app"]
    #     )
    # )
    # plan.print("Initial service check result: " + str(deploy_check["code"]))
    # plan.print("Files in /app: " + deploy_check["output"])

    # # Then modify the wait section to include more debug output
    # plan.print("Waiting for deployment to complete...")

    # deployment_wait = plan.wait(
    #     service_name = "orbit-deployer",
    #     recipe = ExecRecipe(
    #         command = ["ls", "-la", "/app"]
    #     ),
    #     field = "code", 
    #     assertion = "==",
    #     target_value = 0,
    #     timeout = "3m"  # Increase timeout to 3 minutes
    # )
    # plan.print("Deployment wait completed. Checking for output files...")
    # # except:
    # #     plan.print("Deployment wait failed. Checking service logs...")
        
    # # Get logs from the deployment BEFORE checking for the result file
    # logs_result = plan.exec(
    #     service_name = "orbit-deployer",
    #     recipe = ExecRecipe(
    #         command = ["tail", "-n", "50", "/app/npm-debug.log"]
    #     )
    # )
    # plan.print("NPM debug logs: " + logs_result["output"])

    # # Now check if deployment-result.json exists
    # deploy_result = plan.exec(
    #     service_name = "orbit-deployer",
    #     recipe = ExecRecipe(
    #         command = ["test", "-f", "/app/deployment-result.json"]
    #     )
    # )

    # if deploy_result["code"] != 0:
    #     # Get more debug info first
    #     ls_result = plan.exec(
    #         service_name = "orbit-deployer",
    #         recipe = ExecRecipe(
    #             command = ["ls", "-la", "/app"]
    #         )
    #     )
    #     plan.print("Files in /app: " + ls_result["output"])
        
    #     # Try to capture logs
    #     npm_log = plan.exec(
    #         service_name = "orbit-deployer",
    #         recipe = ExecRecipe(
    #             command = ["sh", "-c", "cat /app/npm-debug.log 2>/dev/null || echo 'No npm log found'"]
    #         )
    #     )
        
    #     # Modified fail with string message
    #     fail("Deployment failed: Could not find deployment-result.json")


    # # # Wait for the deployment to complete
    # # plan.wait(
    # #     service_name = "orbit-deployer",
    # #     recipe = ExecRecipe(
    # #         command = ["ls", "-la", "/app"]
    # #     ),
    # #     field = "code",
    # #     assertion = "==",
    # #     target_value = 0,
    # #     timeout = "5m"
    # # )
    
    # # # Check if deployment-result.json exists
    # # deploy_result = plan.exec(
    # #     service_name = "orbit-deployer",
    # #     recipe = ExecRecipe(
    # #         command = ["test", "-f", "/app/deployment-result.json"]
    # #     )
    # # )
    
    # # # Check if deployment-result.json exists
    # # deploy_result = plan.exec(
    # #     service_name = "orbit-deployer",
    # #     recipe = ExecRecipe(
    # #         command = ["test", "-f", "/app/deployment-result.json"]
    # #     )
    # # )

    # # if deploy_result["code"] != 0:
    # #     fail("Deployment failed: Could not find deployment-result.json. Check logs for details.")
    
    # # Now fail with more information
    # # fail("Deployment failed: Could not find deployment-result.json. Check logs for details.")
    
    # # Get the contract addresses from the deployment
    # contract_addresses_result = plan.exec(
    #     service_name = "orbit-deployer",
    #     recipe = ExecRecipe(
    #         command = ["cat", "/app/contract-addresses.json"]
    #     )
    # )
    
    # if contract_addresses_result["code"] != 0:
    #     fail("Failed to get contract addresses")
    
    # # Store the chain info JSON as an artifact
    # chain_info_artifact = plan.store_service_files(
    #     service_name = "orbit-deployer",
    #     src = "/app/chain-info.json",
    #     name = "chain-info"
    # )
    
    # # Get the validator key from the deployment (for fraud proofs)
    # validator_key_result = plan.exec(
    #     service_name = "orbit-deployer",
    #     recipe = ExecRecipe(
    #         command = ["cat", "/app/validator-key.txt"]
    #     )
    # )
    
    # validator_key = ""
    # if validator_key_result["code"] == 0:
    #     validator_key = validator_key_result["output"].strip()
    
    # plan.print("Arbitrum Orbit contracts deployed successfully")
    
    # # Parse the contract addresses
    # contract_addresses = {}
    # if contract_addresses_result["code"] == 0:
    #     # In Starlark, we can't use try-except, so we'll need to be more careful here
    #     # We'll use a default empty object if parsing fails
    #     contract_addresses_text = contract_addresses_result["output"]
    #     if contract_addresses_text:
    #         parsed_addresses = json.decode(contract_addresses_text)
    #         if parsed_addresses:
    #             contract_addresses = parsed_addresses
    #         else:
    #             plan.print("Warning: Contract addresses JSON parsed to null")
    #     else:
    #         plan.print("Warning: Contract addresses text was empty")
    
    # return struct(
    #     contract_addresses = contract_addresses,
    #     chain_info_artifact = chain_info_artifact,
    #     validator_key = validator_key
    # )

def start_sequencer(plan, orbit_config, l1_output, deploy_output):
    """
    Start an Arbitrum Nitro Sequencer node with minimal configuration.
    """
    plan.print("Starting Arbitrum Nitro Sequencer node with minimal config...")
    
    sequencer_service = plan.add_service(
        name = "orbit-sequencer",
        config = ServiceConfig(
            image = orbit_config.nitro_image,
            # Don't specify files for now
            cmd = [
                # Just use dev mode
                "--dev",
                
                # HTTP API configuration
                "--http.api=net,web3,eth,debug",
                "--http.corsdomain=*",
                "--http.addr=0.0.0.0",
                "--http.port=8547",
                "--http.vhosts=*",
                
                # WebSocket configuration
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
                # Don't specify feed port for now
            }
        ),
    )
    
    # Return connection information
    return struct(
        rpc_endpoint = "http://orbit-sequencer:8547",
        ws_endpoint = "ws://orbit-sequencer:8548",
        feed_endpoint = "ws://orbit-sequencer:9642",  # Keep this in the return value for compatibility
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
            # Parent chain connection
            "--parent-chain.connection.url=" + l1_output.rpc_endpoint,
            
            # Chain configuration
            "--chain.info-json=/home/user/.arbitrum/chain-info.json",
            "--chain.name=" + orbit_config.chain_name,
            
            # Validator configuration
            # No --node.type flag needed for validator, just don't specify sequencer
            
            # Feed configuration
            "--node.feed.input.url=" + sequencer_output.feed_endpoint,
            
            # Forwarding configuration 
            "--execution.forwarding-target=" + sequencer_output.rpc_endpoint,
            
            # HTTP API configuration
            "--http.api=net,web3,eth",
            "--http.corsdomain=*",
            "--http.addr=0.0.0.0",
            "--http.port=8547",
            "--http.vhosts=*",
            
            # WebSocket configuration
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
        ),
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