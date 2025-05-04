"""
Ethereum L1 setup for Kurtosis-Orbit package.

This module handles the deployment of a local Ethereum L1 chain using the ethereum-package.
"""

ethereum_package = import_module("github.com/ethpandaops/ethereum-package/main.star")
utils = import_module("./utils.star")

def start_ethereum_l1(plan, orbit_config):
    """
    Start an Ethereum L1 node for the Orbit chain to settle on.
    
    Args:
        plan: The Kurtosis execution plan
        orbit_config: Configuration object for the deployment
    
    Returns:
        L1Output object with connection details for the L1 chain
    """
    # Configure the Ethereum L1 package
    l1_args = {
        "network_params": {
            "preset": "minimal",  # Use minimal preset for fast block times
            "chain_id": orbit_config.l1_chain_id,
            "deposit_contract_address": "0x1111111111111111111111111111111111111111",  # Dummy value, not used
            "seconds_per_slot": 3,  # Fast slots for quicker development
            "genesis_delay": 10,
            "max_churn": 8,  # EIP-7514 max validator churn
            "eth1_follow_distance": 12,  # Shorter distance for dev environment
            "capella_fork_epoch": 0,  # Enable withdrawals from genesis
            "deneb_fork_epoch": 0,  # Enable EIP-4844 from genesis
            "electra_fork_epoch": None
        },
        "participants": [
            {
                "kind": "el-cl-validator",
                "el_type": "geth",
                "cl_type": "lighthouse",
                "count": 1,
            }
        ],
        "prysm_client_image": "",
        "geth_client_image": "",
        "lighthouse_client_image": "",
        "nimbus_client_image": "",
        "teku_client_image": "",
        "mev_boost_image": "",
        "mev_boost_relay_image": "",
        "mev_boost_relay_db_image": "",
        "num_validator_keys_per_node": 64,
        "global_client_log_level": "info",
        "wait_for_finalization": False,  # Don't wait for finalization to speed up startup
        "additional_services": None,
        "enable_mev": False
    }
    
    # Start the Ethereum L1 chain
    plan.print("Starting Ethereum L1 node...")
    
    # Run the Ethereum package
    ethereum_result = ethereum_package.run(plan, l1_args)
    
    # The ethereum package will return information about the deployed nodes
    el_client_context = ethereum_result["el_client_context"]
    cl_client_context = ethereum_result["cl_client_context"]
    
    # Get the endpoint for the execution client (Geth)
    el_client_service = el_client_context["services"][0]
    rpc_port = el_client_service["rpc_port"]
    ws_port = el_client_service["ws_port"]
    
    # Construct service names based on Ethereum package's naming convention
    el_service_name = "el-1-geth-lighthouse"
    
    # Build full RPC URLs
    rpc_endpoint = "http://" + el_service_name + ":" + str(rpc_port)
    ws_endpoint = "ws://" + el_service_name + ":" + str(ws_port)
    
    # Wait for the Ethereum node to be ready
    utils.wait_for_http_endpoint(plan, rpc_endpoint, '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}')
    
    # Get the private key for the prefunded account
    # The ethereum-package automatically funds some accounts - we'll use the first one
    # This is usually the same as our default key for convenience
    
    plan.print("Ethereum L1 node is ready")
    plan.print("RPC endpoint: " + rpc_endpoint)
    
    return struct(
        rpc_endpoint = rpc_endpoint,
        ws_endpoint = ws_endpoint,
        chain_id = orbit_config.l1_chain_id,
        funded_private_key = orbit_config.owner_private_key
    )