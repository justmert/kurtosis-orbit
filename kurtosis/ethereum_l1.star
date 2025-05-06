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
    
    ethereum_result = ethereum_package.run(plan, l1_args)

    # ---------- compatibility layer ----------
    def _first(lst):  # tiny helper
        return lst[0] if len(lst) > 0 else None

    result_keys = dir(ethereum_result)

    # v1/v2 (legacy – top-level context)
    if "el_client_context" in result_keys:
        el_ctxs = [ethereum_result.el_client_context]
        cl_ctxs = [getattr(ethereum_result, "cl_client_context", None)]

    # v3+ (context lives on each participant)
    elif "all_participants" in result_keys:
        el_ctxs = [p.el_context        for p in ethereum_result.all_participants
                                        if hasattr(p, "el_context")]
        cl_ctxs = [p.cl_context        for p in ethereum_result.all_participants
                                        if hasattr(p, "cl_context")]
    else:
        fail("Unknown ethereum-package output shape: %s" % result_keys)

    if len(el_ctxs) == 0:
        fail("No execution-layer context found in package output.")

    # Pick the first EL/CL node for now (Kurtosis names are deterministic)
    el_ctx = _first(el_ctxs)
    cl_ctx = _first(cl_ctxs)   # may be None if you don’t need it

    rpc_http_url = el_ctx.rpc_http_url   # http://…:8545
    ws_url       = getattr(el_ctx, "ws_url", "")  # if you need WS
    # ------------------------------------------

    plan.print("Ethereum L1 ready – RPC: %s" % rpc_http_url)
    plan.print("RPC endpoint: " + rpc_http_url)
    
    return struct(
        rpc_endpoint = rpc_http_url,
        ws_endpoint = ws_url,
        chain_id = orbit_config.l1_chain_id,
        funded_private_key = orbit_config.owner_private_key
    )