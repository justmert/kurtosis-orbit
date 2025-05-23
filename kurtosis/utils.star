"""
Utility functions for display and helpers.
"""

def print_deployment_banner(plan, config):
    """
    Display deployment banner with configuration.
    """
    plan.print("=" * 60)
    plan.print("🚀 Kurtosis-Orbit: Arbitrum Orbit Deployment")
    plan.print("=" * 60)
    plan.print("Chain Name: {}".format(config.chain_name))
    plan.print("Chain ID: {}".format(config.chain_id))
    plan.print("Mode: {}".format("Rollup" if config.rollup_mode else "AnyTrust"))
    plan.print("Challenge Period: {} blocks".format(config.challenge_period_blocks))
    plan.print("=" * 60)

def display_connection_info(plan, output):
    """
    Display connection information for the deployed services.
    """
    plan.print("\n" + "=" * 60)
    plan.print("✅ Kurtosis-Orbit Deployment Complete!")
    plan.print("=" * 60)
    
    plan.print("\n📊 Chain Information:")
    plan.print("Chain Name: {}".format(output["chain_info"]["name"]))
    plan.print("Chain ID: {}".format(output["chain_info"]["chain_id"]))
    plan.print("Mode: {}".format(output["chain_info"]["mode"]))
    plan.print("Owner Address: {}".format(output["chain_info"]["owner_address"]))
    
    plan.print("\n🔌 Connection Information:")
    plan.print("L1 Ethereum RPC: {}".format(output["ethereum_l1"]["rpc_url"]))
    plan.print("L2 Arbitrum RPC: {}".format(output["arbitrum_l2"]["sequencer"]["rpc_url"]))
    plan.print("L2 Arbitrum WS: {}".format(output["arbitrum_l2"]["sequencer"]["ws_url"]))
    
    # Validator information
    if output["arbitrum_l2"]["validators"]:
        plan.print("\n⚡ Validator Nodes:")
        for i, validator in enumerate(output["arbitrum_l2"]["validators"]):
            plan.print("Validator {}: {}".format(i, validator["rpc_url"]))
    
    # Explorer information
    if output.get("explorer") and output["explorer"].get("url"):
        plan.print("\n🔍 Block Explorer:")
        plan.print("Blockscout URL: {}".format(output["explorer"]["url"]))
        plan.print("Note: Explorer may take 1-2 minutes to fully index blocks")
    
    # Contract addresses
    plan.print("\n📜 Contract Addresses:")
    if output["rollup_contracts"]:
        plan.print("Rollup: {}".format(output["rollup_contracts"]["rollup_address"]))
        plan.print("Bridge: {}".format(output["rollup_contracts"]["bridge_address"]))
        plan.print("Inbox: {}".format(output["rollup_contracts"]["inbox_address"]))
        plan.print("Sequencer Inbox: {}".format(output["rollup_contracts"]["sequencer_inbox_address"]))
    
    if output.get("token_bridge") and output["token_bridge"]:
        plan.print("\n🌉 Token Bridge:")
        plan.print("L1 Gateway Router: {}".format(output["token_bridge"]["l1"]["router"]))
        plan.print("L1 ERC20 Gateway: {}".format(output["token_bridge"]["l1"]["gateway"]))
        plan.print("L2 Gateway Router: {}".format(output["token_bridge"]["l2"]["router"]))
        plan.print("L2 ERC20 Gateway: {}".format(output["token_bridge"]["l2"]["gateway"]))
    
    plan.print("\n📝 Access Instructions:")
    plan.print("1. List enclave services:")
    plan.print("   kurtosis enclave inspect <enclave-name>")
    plan.print("2. Forward RPC port:")
    plan.print("   kurtosis port forward <enclave-name> orbit-sequencer rpc")
    if output.get("explorer"):
        plan.print("3. Forward explorer port:")
        plan.print("   kurtosis port forward <enclave-name> blockscout http")
    
    plan.print("\n🦊 MetaMask Configuration:")
    plan.print("Network Name: {}".format(output["chain_info"]["name"]))
    plan.print("RPC URL: <forwarded-rpc-url>")
    plan.print("Chain ID: {}".format(output["chain_info"]["chain_id"]))
    plan.print("Currency Symbol: ETH")
    
    plan.print("\n🔑 Development Accounts:")
    plan.print("Pre-funded accounts (1000 ETH each):")
    plan.print("  Owner: 0x976EA74026E726554dB657fA54763abd0C3a0aa9")
    plan.print("  Sequencer: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC")
    plan.print("  Validator: 0x90F79bf6EB2c4f870365E785982E1f101E93b906")
    plan.print("  Funnel: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8")
    
    plan.print("\n" + "=" * 60)
    plan.print("🎉 Your Arbitrum Orbit chain is ready for development!")
    plan.print("=" * 60 + "\n")