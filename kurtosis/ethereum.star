"""
Ethereum L1 deployment using ethereum-package.
"""

ethereum_pkg = import_module("github.com/ethpandaops/ethereum-package/main.star@0e1548a638fde573fa77840441c4a2cf149ef3d6")
config_module = import_module("./config.star")

def deploy_ethereum_l1(plan, config):
    """
    Deploy a local Ethereum L1 chain using ethereum-package.
    """
    plan.print("Preparing Ethereum L1 configuration...")
    
    # Get prefunded accounts
    prefunded_accounts_json = config_module.get_prefunded_accounts_json(config)
    
    # Configure ethereum-package with stable setup for development
    ethereum_config = {
        "participants": [
            {
                "el_type": "geth",
                "el_image": "ethereum/client-go:latest",
                "cl_type": "lighthouse", 
                "cl_image": "ethpandaops/lighthouse:unstable-a93cafe",
            }
        ],
        "network_params": {
            "network": "kurtosis",
            "network_id": str(config["l1_chain_id"]),
            "seconds_per_slot": 12,
            "genesis_delay": 30,  # Increased delay for better coordination
            "preset": "minimal",
            "prefunded_accounts": prefunded_accounts_json,
        },
        "additional_services": [],
        "global_log_level": "info",
    }
    
    # Deploy Ethereum
    ethereum_result = ethereum_pkg.run(plan, ethereum_config)
    
    # Extract connection info
    el_client = ethereum_result.all_participants[0].el_context
    
    # Wait for L1 to be ready
    plan.wait(
        service_name=el_client.service_name,
        recipe=PostHttpRequestRecipe(
            port_id="rpc",
            endpoint="",
            body='{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}',
            content_type="application/json",
        ),
        field="code",
        assertion="==",
        target_value=200,
        timeout="60s",
        interval="2s",
    )
    
    plan.print("✅ Ethereum L1 is ready!")
    
    return {
        "rpc_url": el_client.rpc_http_url,
        "ws_url": el_client.ws_url,
        "chain_id": config["l1_chain_id"],
        "network_id": ethereum_result.network_id,
        "prefunded_accounts": ethereum_result.pre_funded_accounts,
    }