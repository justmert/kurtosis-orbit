"""
Utility functions for display and helpers.
"""

config = import_module("./config.star")

def print_deployment_banner(plan, config_obj):
    """
    Display deployment banner with configuration.
    """
    banner_text = ("=" * 60 + "\n" +
                   "🚀 Kurtosis-Orbit: Arbitrum Orbit Deployment\n" +
                   "=" * 60 + "\n" +
                   "Chain Name: {}\n".format(config_obj.chain_name) +
                   "Chain ID: {}\n".format(config_obj.chain_id) +
                   "Mode: {}\n".format("Rollup" if config_obj.rollup_mode else "AnyTrust") +
                   "Challenge Period: {} blocks\n".format(config_obj.challenge_period_blocks) +
                   "=" * 60)
    plan.print(banner_text)

def display_connection_info(plan, output):
    """
    Display connection information for the deployed services.
    """
    # Header section
    header_text = ("\n" + "=" * 60 + "\n" +
                   "✅ Kurtosis-Orbit Deployment Complete!\n" +
                   "=" * 60)
    plan.print(header_text)
    
    # Chain information section
    chain_info_text = ("\n📊 Chain Information:\n" +
                       "Chain Name: {}\n".format(output["chain_info"]["name"]) +
                       "Chain ID: {}\n".format(output["chain_info"]["chain_id"]) +
                       "Mode: {}\n".format(output["chain_info"]["mode"]) +
                       "Owner Address: {}".format(output["chain_info"]["owner_address"]))
    plan.print(chain_info_text)
    
    # Connection information section
    connection_info_text = ("\n🔌 Connection Information:\n" +
                           "L1 Ethereum RPC: {}\n".format(output["ethereum_l1"]["rpc_url"]) +
                           "L2 Arbitrum RPC: {}\n".format(output["arbitrum_l2"]["sequencer"]["rpc_url"]) +
                           "L2 Arbitrum WS: {}".format(output["arbitrum_l2"]["sequencer"]["ws_url"]))
    plan.print(connection_info_text)
    
    # Validator information
    if output["arbitrum_l2"]["validators"]:
        validator_text = "\n⚡ Validator Nodes:"
        for i, validator in enumerate(output["arbitrum_l2"]["validators"]):
            validator_text += "\nValidator {}: {}".format(i, validator["rpc_url"])
        plan.print(validator_text)
    
    # Explorer information
    if output.get("explorer") and output["explorer"].get("url"):
        explorer_text = ("\n🔍 Block Explorer:\n" +
                        "Blockscout URL: {}\n".format(output["explorer"]["url"]) +
                        "Note: Explorer may take 1-2 minutes to fully index blocks")
        plan.print(explorer_text)
    
    # Contract addresses
    contract_text = "\n📜 Contract Addresses:"
    if output["rollup_contracts"]:
        contract_text += ("\nRollup: {}\n".format(output["rollup_contracts"]["rollup_address"]) +
                         "Bridge: {}\n".format(output["rollup_contracts"]["bridge_address"]) +
                         "Inbox: {}\n".format(output["rollup_contracts"]["inbox_address"]) +
                         "Sequencer Inbox: {}".format(output["rollup_contracts"]["sequencer_inbox_address"]))
    plan.print(contract_text)
    
    # Token bridge information
    if output.get("token_bridge") and output["token_bridge"]:
        bridge_text = ("\n🌉 Token Bridge:\n" +
                      "L1 Gateway Router: {}\n".format(output["token_bridge"]["l1"]["router"]) +
                      "L1 ERC20 Gateway: {}\n".format(output["token_bridge"]["l1"]["gateway"]) +
                      "L2 Gateway Router: {}\n".format(output["token_bridge"]["l2"]["router"]) +
                      "L2 ERC20 Gateway: {}".format(output["token_bridge"]["l2"]["gateway"]))
        plan.print(bridge_text)
    
    # Access instructions
    access_text = ("\n📝 Access Instructions:\n" +
                  "1. List enclave services:\n" +
                  "   kurtosis enclave inspect <enclave-name>\n" +
                  "2. Forward RPC port:\n" +
                  "   kurtosis port forward <enclave-name> orbit-sequencer rpc")
    if output.get("explorer"):
        access_text += "\n3. Forward explorer port:\n   kurtosis port forward <enclave-name> blockscout http"
    plan.print(access_text)
    
    # MetaMask configuration
    metamask_text = ("\n🦊 MetaMask Configuration:\n" +
                    "Network Name: {}\n".format(output["chain_info"]["name"]) +
                    "RPC URL: <forwarded-rpc-url>\n" +
                    "Chain ID: {}\n".format(output["chain_info"]["chain_id"]) +
                    "Currency Symbol: ETH")
    plan.print(metamask_text)
    
    # Development accounts - use addresses from config
    accounts_text = ("\n🔑 Development Accounts:\n" +
                    "Pre-funded accounts (1000 ETH each):\n" +
                    "  Funnel: {}\n".format(config.STANDARD_ACCOUNTS["funnel"]["address"]) +
                    "  Sequencer: {}\n".format(config.STANDARD_ACCOUNTS["sequencer"]["address"]) +
                    "  Validator: {}\n".format(config.STANDARD_ACCOUNTS["validator"]["address"]) +
                    "  L2 Owner: {}\n".format(config.STANDARD_ACCOUNTS["l2owner"]["address"]) +
                    "  L3 Owner: {}".format(config.STANDARD_ACCOUNTS["l3owner"]["address"]))
    plan.print(accounts_text)
    
    # Footer section
    footer_text = ("\n" + "=" * 60 + "\n" +
                   "🎉 Your Arbitrum Orbit chain is ready for development!\n" +
                   "=" * 60 + "\n")
    plan.print(footer_text)