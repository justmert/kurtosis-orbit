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
    # ────────────────────────────
    # Network-level configuration
    # ────────────────────────────
    "network_params": {
        # Fast, dev-friendly chain
        "preset": "minimal",
        "network_id": str(orbit_config.l1_chain_id),  # Convert to string
        "deposit_contract_address": "0x1111111111111111111111111111111111111111",
        "seconds_per_slot": 3,
        "genesis_delay": 10,

        # Shorter PoW → PoS follow distance for quicker sync
        "eth1_follow_distance": 12,

        # Forks active from genesis
        "capella_fork_epoch": 0,
        "deneb_fork_epoch": 0,
        "electra_fork_epoch": 18446744073709551615,

        # Number of keys each validator gets (belongs *inside* `network_params`)
        "num_validator_keys_per_node": 64,
    },

    # ────────────────────────────
    # Node fleet
    # ────────────────────────────
    "participants": [
        {
            "el_type": "geth",
            "cl_type": "lighthouse",
            "count": 1,          # single EL/CL pair is fine for local dev
            # everything else inherits defaults
        }
    ],

    # ────────────────────────────
    # Global toggles
    # ────────────────────────────
    "global_log_level": "info",   # spec key is `global_log_level`
    "wait_for_finalization": False,

    # Disable all the default extras so startup stays snappy
    # (give an empty *list*, not a dict)
    "additional_services": [],

    # Turn MEV infra off (spec uses `mev_type`)
    "mev_type": None,
}

    
    # Start the Ethereum L1 chain
    plan.print("Starting Ethereum L1 node...")
    
    # Run the Ethereum package
    ethereum_result = ethereum_package.run(plan, l1_args)
    
    # The ethereum package will return information about the deployed nodes
    el_client_context = ethereum_result.el_client_context
    cl_client_context = ethereum_result.cl_client_context
    
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