"""
Utility functions for display and helpers.
"""

config_module = import_module("./config.star")

def print_deployment_banner(plan, config_obj):
    """
    Display deployment banner with configuration.
    """
    banner_text = ("=" * 60 + "\n" +
                   "🚀 Kurtosis-Orbit: Arbitrum Orbit Deployment\n" +
                   "=" * 60 + "\n" +
                   "Chain Name: {}\n".format(config_obj["chain_name"]) +
                   "Chain ID: {}\n".format(config_obj["chain_id"]) +
                   "Mode: {}\n".format("Rollup" if config_obj["rollup_mode"] else "AnyTrust") +
                   "Challenge Period: {} blocks\n".format(config_obj["challenge_period_blocks"]) +
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
    chain_info_text = ("\n📊 CHAIN INFORMATION\n" +
                       "-" * 40 + "\n" +
                       "Chain Name: {}\n".format(output["chain_info"]["name"]) +
                       "Chain ID: {}\n".format(output["chain_info"]["chain_id"]) +
                       "Mode: {}\n".format(output["chain_info"]["mode"]) +
                       "Owner Address: {}".format(output["chain_info"]["owner_address"]))
    plan.print(chain_info_text)
    
    # Connection endpoints section
    endpoints_text = ("\n🔌 CONNECTION ENDPOINTS\n" +
                     "-" * 40 + "\n" +
                     "L1 Ethereum RPC: {}\n".format(output["ethereum_l1"]["rpc_url"]) +
                     "L2 Arbitrum RPC: {}\n".format(output["arbitrum_l2"]["sequencer"]["rpc_url"]) +
                     "L2 Arbitrum WS: {}".format(output["arbitrum_l2"]["sequencer"]["ws_url"]))
    
    # Add validator information (if any)
    if output["arbitrum_l2"]["validators"]:
        for i, validator in enumerate(output["arbitrum_l2"]["validators"]):
            endpoints_text += "\nValidator {} RPC: {}".format(i, validator["rpc_url"])
    
    plan.print(endpoints_text)
    
    # Contract addresses section
    contracts_text = "\n📜 DEPLOYED CONTRACTS\n" + "-" * 40
    if output["rollup_contracts"]:
        contracts_text += ("\nRollup: {}\n".format(output["rollup_contracts"]["rollup_address"]) +
                          "Bridge: {}\n".format(output["rollup_contracts"]["bridge_address"]) +
                          "Inbox: {}\n".format(output["rollup_contracts"]["inbox_address"]) +
                          "Sequencer Inbox: {}".format(output["rollup_contracts"]["sequencer_inbox_address"]))
    plan.print(contracts_text)
    
    # Token bridge (if deployed)
    if output.get("token_bridge") and output["token_bridge"]:
        bridge_text = ("\n🌉 TOKEN BRIDGE\n" +
                      "-" * 40 + "\n" +
                      "L1 Gateway Router: {}\n".format(output["token_bridge"]["l1"]["router"]) +
                      "L1 ERC20 Gateway: {}\n".format(output["token_bridge"]["l1"]["gateway"]) +
                      "L2 Gateway Router: {}\n".format(output["token_bridge"]["l2"]["router"]) +
                      "L2 ERC20 Gateway: {}".format(output["token_bridge"]["l2"]["gateway"]))
        plan.print(bridge_text)
    
    # Explorer (if deployed)
    if output.get("explorer") and output["explorer"].get("url"):
        explorer_text = ("\n🔍 BLOCK EXPLORER\n" +
                        "-" * 40 + "\n" +
                        "Blockscout URL: {}\n".format(output["explorer"]["url"]) +
                        "Note: Explorer may take 1-2 minutes to fully index blocks")
        plan.print(explorer_text)
    
    # Prefunded accounts section
    accounts_header = ("\n💰 PREFUNDED ACCOUNTS\n" +
                      "-" * 40 + "\n" +
                      "The following accounts are funded with ETH on both L1 and L2:\n")
    
    # Get the configuration to access prefunded accounts
    config = output.get("config")
    if config:
        all_accounts = config_module.get_all_prefunded_accounts(config)
        
        # Group accounts by type
        system_accounts = []
        dev_accounts = []
        custom_accounts = []
        
        for addr, info in all_accounts.items():
            account_entry = {
                "address": addr,
                "name": info["name"],
                "balance_l1": info["balance_l1"],
                "balance_l2": info["balance_l2"],
                "description": info["description"],
                "private_key": info.get("private_key")
            }
            
            if info["name"] in ["funnel", "sequencer", "validator", "l2owner", "l3owner", "l3sequencer"]:
                system_accounts.append(account_entry)
            elif info["name"] == "dev_account":
                dev_accounts.append(account_entry)
            else:
                custom_accounts.append(account_entry)
        
        # Build system accounts text
        system_text = ""
        if system_accounts:
            system_text = "System Accounts:\n"
            for acc in system_accounts:
                system_text += "  • {} ({})\n".format(acc["name"], acc["address"])
                system_text += "    {}, Balance: {} ETH (L1), {} ETH (L2)\n".format(
                    acc["description"], acc["balance_l1"], acc["balance_l2"]
                )
                if acc["private_key"]:
                    system_text += "    Private Key: {}\n".format(acc["private_key"])
                system_text += "\n"
        
        # Build development accounts text
        dev_text = ""
        if dev_accounts:
            dev_text = "Development Accounts:\n"
            for acc in dev_accounts:
                dev_text += "  • {}\n".format(acc["address"])
                dev_text += "    {}, Balance: {} ETH (L1), {} ETH (L2)\n\n".format(
                    acc["description"], acc["balance_l1"], acc["balance_l2"]
                )
        
        # Build custom accounts text
        custom_text = ""
        if custom_accounts:
            custom_text = "Custom Funded Accounts:\n"
            for acc in custom_accounts:
                custom_text += "  • {}\n".format(acc["address"])
                custom_text += "    Balance: {} ETH (L1), {} ETH (L2)\n\n".format(
                    acc["balance_l1"], acc["balance_l2"]
                )
        
        # Print all account information in one go
        full_accounts_text = accounts_header + system_text + dev_text + custom_text
        plan.print(full_accounts_text)
    
    # Quick start guide
    guide_text = ("📝 QUICK START GUIDE\n" +
                 "-" * 40 + "\n" +
                 "1. List enclave services:\n" +
                 "   kurtosis enclave inspect <enclave-name>\n\n" +
                 "2. Forward RPC port to localhost:\n" +
                 "   kurtosis port forward <enclave-name> orbit-sequencer rpc\n\n")
    
    if output.get("explorer"):
        guide_text += ("3. Forward explorer port:\n" +
                      "   kurtosis port forward <enclave-name> blockscout http\n\n")
    
    guide_text += ("4. Configure MetaMask:\n" +
                  "   • Network Name: {}\n".format(output["chain_info"]["name"]) +
                  "   • RPC URL: http://localhost:<forwarded-port>\n" +
                  "   • Chain ID: {}\n".format(output["chain_info"]["chain_id"]) +
                  "   • Currency Symbol: ETH\n\n" +
                  "5. Import a funded account to MetaMask:\n" +
                  "   Use one of the private keys listed above")
    
    plan.print(guide_text)
    
    # Footer
    footer_text = ("\n" + "=" * 60 + "\n" +
                  "🎉 Your Arbitrum Orbit chain is ready!\n" +
                  "=" * 60 + "\n")
    plan.print(footer_text)