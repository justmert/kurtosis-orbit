"""
Ethereum L1 deployment using ethereum-package.
"""

ethereum_pkg = import_module("github.com/ethpandaops/ethereum-package/main.star@5.0.1")
config_module = import_module("./config.star")

def deploy_ethereum_l1(plan, config):
    """
    Deploy a local Ethereum L1 chain using ethereum-package.
    """
    plan.print("Preparing Ethereum L1 configuration...")
    
    # Get prefunded accounts
    prefunded_accounts_json = config_module.get_prefunded_accounts_json(config)
    
    # Configure ethereum-package
    ethereum_config = {
        "participants": [
            {
                "el_type": "geth",
                "el_image": "ethereum/client-go:stable",
            }
        ],
        "network_params": {
            "network": "kurtosis",
            "network_id": str(config.l1_chain_id),
            "seconds_per_slot": 3,
            "genesis_delay": 10,
            "preset": "minimal",
            "prefunded_accounts": prefunded_accounts_json,
        },
        "additional_services": [],
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
    )
    
    plan.print("✅ Ethereum L1 is ready!")
    
    return {
        "rpc_url": el_client.rpc_http_url,
        "ws_url": el_client.ws_url,
        "chain_id": config.l1_chain_id,
        "network_id": ethereum_result.network_id,
        "prefunded_accounts": ethereum_result.pre_funded_accounts,
    }