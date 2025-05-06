"""
Kurtosis-Orbit: A one-command deployment of a full Arbitrum Orbit stack.

This Kurtosis package deploys the entire Arbitrum Orbit stack, including:
1. A local Ethereum L1 chain
2. Arbitrum Nitro L2 rollup chain (sequencer, validator, batch poster)
3. Bridge contracts between L1 and L2
4. Optional block explorer

Typical usage:
kurtosis run github.com/arbitrumfoundation/kurtosis-orbit
or with custom config:
kurtosis run github.com/arbitrumfoundation/kurtosis-orbit --args-file orbit-config.yml
"""

# Import required external module
ethereum_package = import_module("github.com/ethpandaops/ethereum-package/main.star")

# Import local modules - the right way for Starlark
input_parser = import_module("./input_parser.star")
ethereum_l1 = import_module("./ethereum_l1.star")
orbit_deployer = import_module("./orbit_deployer.star")
token_bridge = import_module("./token_bridge.star")
explorer = import_module("./explorer.star")
utils = import_module("./utils.star")

def run(plan, args={}):
    """
    Main entry point for the Kurtosis package.
    
    Args:
        plan: The Kurtosis execution plan
        args: Configuration parameters passed via command line or config file
    
    Returns:
        Dictionary containing the endpoints and connection information for the deployed services
    """
    # Parse input arguments with defaults
    orbit_config = input_parser.parse_input(args)
    
    # Phase 1: Start Ethereum L1 node
    l1_output = ethereum_l1.start_ethereum_l1(plan, orbit_config)
    
    # Phase 2: Deploy Orbit Rollup contracts on L1
    deploy_output = orbit_deployer.deploy_orbit_contracts(plan, orbit_config, l1_output)
    
    # Phase 3: Start Arbitrum Nitro Sequencer Node
    plan.print("Step 3: Starting Nitro Sequencer (stubbed)...")
    sequencer_output = orbit_deployer.start_sequencer(plan, orbit_config, l1_output, deploy_output)
    plan.print("Sequencer started")

    # Phase 4: Use stubbed token bridge
    plan.print("Step 4: Deploying token bridge (stubbed)...")
    if orbit_config.enable_bridge:
        bridge_output = token_bridge.deploy_token_bridge(plan, orbit_config, l1_output, sequencer_output)
        plan.print("Token bridge deployed")

    # Phase 5: Explorer is stubbed as well
    explorer_output = None
    if orbit_config.enable_explorer:
        plan.print("Step 5: Starting explorer (stubbed)...")
        explorer_output = explorer.start_explorer(plan, orbit_config, sequencer_output)
        plan.print("Explorer started")

    # # Phase 3: Start Arbitrum Nitro Sequencer Node
    # sequencer_output = orbit_deployer.start_sequencer(plan, orbit_config, l1_output, deploy_output)
    
    # # Phase 4: Start Arbitrum Nitro Validator Node(s)
    # validator_outputs = []
    # if orbit_config.validator_count > 0:
    #     for i in range(orbit_config.validator_count):
    #         validator_output = orbit_deployer.start_validator(plan, orbit_config, l1_output, deploy_output, sequencer_output, i)
    #         validator_outputs.append(validator_output)
    
    # # Phase 5: Deploy Token Bridge
    # if orbit_config.enable_bridge:
    #     bridge_output = token_bridge.deploy_token_bridge(plan, orbit_config, l1_output, sequencer_output)
    
    # Phase 6: Start Block Explorer (if enabled)
    explorer_output = None
    if orbit_config.enable_explorer:
        explorer_output = explorer.start_explorer(plan, orbit_config, sequencer_output)
    
    # Prepare output dictionary with connection information
    result = {
        "l1_chain": {
            "rpc_endpoint": l1_output.rpc_endpoint,
            "chain_id": l1_output.chain_id,
            "ws_endpoint": l1_output.ws_endpoint
        },
        "orbit_chain": {
            "rpc_endpoint": sequencer_output.rpc_endpoint,
            "chain_id": orbit_config.chain_id,
            "ws_endpoint": sequencer_output.ws_endpoint,
            "feed_endpoint": sequencer_output.feed_endpoint,
            "deployed_contracts": deploy_output.contract_addresses
        }
    }
    
    if explorer_output:
        result["explorer"] = {
            "web_endpoint": explorer_output.web_endpoint
        }
    
    # Output connection information
    orbit_info = "Orbit L2 Chain Deployment Completed\n"
    orbit_info += "---------------------------------\n"
    orbit_info += "Ethereum L1 RPC: " + l1_output.rpc_endpoint + "\n"
    orbit_info += "Orbit L2 RPC: " + sequencer_output.rpc_endpoint + "\n"
    orbit_info += "Orbit L2 Chain ID: " + str(orbit_config.chain_id) + "\n"
    
    if explorer_output:
        orbit_info += "Block Explorer: " + explorer_output.web_endpoint + "\n"
    
    orbit_info += "\nAdd to MetaMask:\n"
    orbit_info += "1. Network Name: " + orbit_config.chain_name + "\n"
    orbit_info += "2. RPC URL: " + sequencer_output.rpc_endpoint + "\n"
    orbit_info += "3. Chain ID: " + str(orbit_config.chain_id) + "\n"
    orbit_info += "4. Currency Symbol: ETH\n"
    
    plan.print(orbit_info)
    
    return result