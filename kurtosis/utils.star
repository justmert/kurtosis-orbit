"""
Utilities module for Kurtosis-Orbit.
This module provides utility functions for the Kurtosis-Orbit package.
"""

def display_connection_info(plan, output):
    """
    Display connection information for the deployed services
    
    Args:
        plan: The Kurtosis execution plan
        output: Output dictionary with connection information
    """
    plan.print("\n===== Kurtosis-Orbit Deployment Complete =====")
    plan.print("Chain Name: " + output["chain_info"]["name"])
    plan.print("Chain ID: " + str(output["chain_info"]["chain_id"]))
    plan.print("Mode: " + output["chain_info"]["mode"])
    plan.print("Owner Address: " + output["chain_info"]["owner_address"])
    
    plan.print("\n===== Connection Information =====")
    plan.print("L1 Ethereum RPC:    " + output["ethereum_l1"]["rpc_url"])
    plan.print("L2 Arbitrum RPC:    " + output["arbitrum_l2"]["sequencer"]["rpc_url"])
    plan.print("L2 Arbitrum WS:     " + output["arbitrum_l2"]["sequencer"]["ws_url"])
    
    # Display validator information if available
    if output["arbitrum_l2"]["validators"] and len(output["arbitrum_l2"]["validators"]) > 0:
        plan.print("\nValidator Nodes:")
        for i, validator in enumerate(output["arbitrum_l2"]["validators"]):
            plan.print("  Validator " + str(i+1) + " RPC: " + validator["rpc_url"])
    
    # Display explorer information prominently
    if output["explorer"] and "url" in output["explorer"]:
        plan.print("\n===== Block Explorer =====")
        plan.print("Blockscout URL:      " + output["explorer"]["url"])
        plan.print("Note: Explorer may take 1-2 minutes to fully index initial blocks")
    
    plan.print("\n===== Contract Addresses =====")
    if output["token_bridge"]:
        plan.print("L1 Gateway Router:   " + output["token_bridge"]["l1"]["router"])
        plan.print("L1 ERC20 Gateway:    " + output["token_bridge"]["l1"]["gateway"])
        plan.print("L1 WETH:             " + output["token_bridge"]["l1"]["weth"])
        plan.print("L2 Gateway Router:   " + output["token_bridge"]["l2"]["router"])
        plan.print("L2 ERC20 Gateway:    " + output["token_bridge"]["l2"]["gateway"])
        plan.print("L2 WETH:             " + output["token_bridge"]["l2"]["weth"])
    else:
        plan.print("Token Bridge:        Not deployed")
    
    plan.print("\n===== Access Instructions =====")
    plan.print("To access services from your host machine:")
    plan.print("  1. List enclave services:")
    plan.print("     kurtosis enclave inspect <enclave-name>")
    plan.print("  2. Forward RPC port:")
    plan.print("     kurtosis port forward <enclave-name> orbit-sequencer rpc")
    plan.print("  3. Forward explorer port (if enabled):")
    plan.print("     kurtosis port forward <enclave-name> blockscout http")
    
    plan.print("\n===== MetaMask Configuration =====")
    plan.print("Add this network to MetaMask:")
    plan.print("  Network Name:    " + output["chain_info"]["name"])
    plan.print("  RPC URL:         <forwarded-rpc-url>")
    plan.print("  Chain ID:        " + str(output["chain_info"]["chain_id"]))
    plan.print("  Currency Symbol: ETH")
    
    plan.print("\n===== Development Accounts =====")
    plan.print("Pre-funded development accounts (private keys for testing):")
    plan.print("  Owner:      0x976EA74026E726554dB657fA54763abd0C3a0aa9")
    plan.print("  Sequencer:  0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC")  
    plan.print("  Validator:  0x90F79bf6EB2c4f870365E785982E1f101E93b906")
    plan.print("  Funnel:     0x70997970C51812dc3A010C7d01b50e0d17dc79C8")
    
    plan.print("\n===== Deployment Successful =====")
    plan.print("Your Arbitrum Orbit chain is ready for development!")

def generate_address_from_private_key(plan, private_key_without_0x):
    """
    Generate Ethereum address from private key
    
    Args:
        plan: The Kurtosis execution plan
        private_key_without_0x: Private key without 0x prefix
        
    Returns:
        Ethereum address
    """
    # Use ethers.js inside a Node.js script to get the address for the private key
    script = """
    const { ethers } = require('ethers');
    const privateKey = "0x" + process.argv[2];
    const wallet = new ethers.Wallet(privateKey);
    console.log(wallet.address);
    """
    
    # Save the script to a file
    script_artifact = plan.render_templates(
        config={
            "/script.js": struct(
                template=script,
                data={},
            ),
        },
        name="address-script",
    )
    
    # Run the script
    result = plan.run_sh(
        run="npm install -g ethers && node /script.js " + private_key_without_0x,
        image="node:18-slim",
        files={
            "/script.js": script_artifact,
        },
    )
    
    return result.output.strip()