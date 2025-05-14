# Import the Ethereum package
ethereum_pkg = import_module("github.com/ethpandaops/ethereum-package/main.star")
# Import our config module
config_module = import_module("./config.star")

def deploy_ethereum_l1(plan, config):
    """
    Deploy a local Ethereum L1 chain using the ethpandaops ethereum-package
    """
    plan.print("Deploying Ethereum L1 chain...")
    
    # Get prefunded accounts JSON
    prefunded_accounts_json = config_module.get_prefunded_accounts_json(config)
    
    # Configure the Ethereum package for a minimal devnet
    ethereum_config = {
        "participants": [
            {
                "el_type": "geth",
                "el_image": "ethereum/client-go:stable"
            }
        ],
        "network_params": {
            "network": "kurtosis",
            "network_id": str(config.l1_chain_id),
            "seconds_per_slot": 3,
            "genesis_delay": 10,
            "preset": "minimal",
            "prefunded_accounts": prefunded_accounts_json
        }
    }
    
    # Run the Ethereum package
    ethereum_result = ethereum_pkg.run(plan, ethereum_config)
    
    # Access the execution layer (Ethereum L1) client information from the first participant
    el_client = ethereum_result.all_participants[0].el_context

    return {
        "rpc_url": el_client.rpc_http_url,
        "ws_url": el_client.ws_url,
        "chain_id": ethereum_result.network_id,
        "dev_accounts": {
            "deployer": ethereum_result.pre_funded_accounts[0].address,
            "user": ethereum_result.pre_funded_accounts[1].address,
        }
    }