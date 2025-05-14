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
    plan.print("\nConnection Information:")
    plan.print("  L1 Ethereum RPC: " + output["ethereum_l1"]["rpc_url"])
    plan.print("  L2 Arbitrum RPC: " + output["arbitrum_l2"]["sequencer"]["rpc_url"])
    
    if output["explorer"] and "url" in output["explorer"]:
        plan.print("  Block Explorer: " + output["explorer"]["url"])
    
    plan.print("\nContract Addresses:")
    
    if output["token_bridge"]:
        plan.print("  L1 Bridge: " + output["token_bridge"]["l1"]["gateway"])
    else:
        plan.print("  Token Bridge: Not deployed")
    
    plan.print("\nTo access these services from your host machine, use:")
    plan.print("  kurtosis port forward <enclave> <service> <port>")
    plan.print("  For example: kurtosis port forward orbit sequencer http")
    
    plan.print("\n===== Deployment Successful =====")

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