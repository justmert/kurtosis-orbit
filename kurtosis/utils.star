"""
Utility functions for Kurtosis-Orbit package.

This module provides helper functions used across different components of the package.
"""

def wait_for_http_endpoint(plan, endpoint, request_body=None, timeout="120s"):
    """
    Wait for an HTTP endpoint to become available using curl.
    
    Args:
        plan: The Kurtosis execution plan
        endpoint: The HTTP endpoint URL to wait for
        request_body: Optional JSON body to send in the request
        timeout: Maximum time to wait before giving up
    """
    plan.print("Waiting for endpoint to be available: " + endpoint)
    
    # Create a temporary service to run curl
    curl_service = plan.add_service(
        name = "curl-checker",
        config = ServiceConfig(
            image = "curlimages/curl:latest",
            entrypoint = ["/bin/sh", "-c"],
            cmd = ["tail -f /dev/null"]  # Keep container running
        )
    )
    
    # Build the curl command
    curl_cmd = []
    if request_body:
        # For POST requests with a body
        curl_cmd = [
            "curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", 
            "-X", "POST", "-H", "Content-Type: application/json",
            "-d", request_body, endpoint
        ]
    else:
        # For GET requests
        curl_cmd = [
            "curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", 
            endpoint
        ]
    
    # Wait for the endpoint to return 200
    plan.wait(
        service_name = "curl-checker",
        recipe = ExecRecipe(command = curl_cmd),
        field = "output",
        assertion = "==",
        target_value = "200",
        interval = "5s",
        timeout = timeout
    )
    
    # Clean up the temporary service
    plan.remove_service(name = "curl-checker")
    

def derive_address_from_private_key(plan, private_key):
    """
    Derive an Ethereum address from a private key.
    
    Args:
        plan: The Kurtosis execution plan
        private_key: The private key in hex format (with or without 0x prefix)
    
    Returns:
        The derived Ethereum address
    """
    # Run a script to derive the address using ethers.js
    script_content = """
    const { ethers } = require('ethers');
    
    // Remove 0x prefix if present
    const privateKey = process.env.PRIVATE_KEY.startsWith('0x') 
        ? process.env.PRIVATE_KEY 
        : '0x' + process.env.PRIVATE_KEY;
    
    const wallet = new ethers.Wallet(privateKey);
    console.log(wallet.address);
    """
    
    # Create a temporary service to run the script
    key_service = plan.add_service(
        name = "address-derivation",
        config = ServiceConfig(
            image = "node:18",
            entrypoint = ["/bin/sh", "-c"],
            cmd = [
                "echo \"" + script_content + "\" > derive.js && npm install ethers@5.7.2 && node derive.js"
            ],
            env_vars = {
                "PRIVATE_KEY": private_key
            }
        )
    )
    
    # Get the output
    exec_result = plan.exec(
        service_name = "address-derivation",
        recipe = ExecRecipe(
            command = ["cat", "derive.js"]
        )
    )
    
    address_result = plan.exec(
        service_name = "address-derivation",
        recipe = ExecRecipe(
            command = ["node", "derive.js"]
        )
    )
    
    # Clean up the temporary service
    plan.remove_service(name = "address-derivation")
    
    return address_result["output"].strip()

def generate_random_private_key(plan):
    """
    Generate a random Ethereum private key.
    
    Args:
        plan: The Kurtosis execution plan
    
    Returns:
        A random private key in hex format
    """
    # Run a script to generate a random key using ethers.js
    script_content = """
    const { ethers } = require('ethers');
    
    const wallet = ethers.Wallet.createRandom();
    console.log(wallet.privateKey);
    """
    
    # Create a temporary service to run the script
    key_service = plan.add_service(
        name = "key-generation",
        config = ServiceConfig(
            image = "node:18",
            entrypoint = ["/bin/sh", "-c"],
            cmd = [
                "echo \"" + script_content + "\" > generate.js && npm install ethers@5.7.2 && node generate.js"
            ]
        )
    )
    
    # Get the output
    key_result = plan.exec(
        service_name = "key-generation",
        recipe = ExecRecipe(
            command = ["node", "generate.js"]
        )
    )
    
    # Clean up the temporary service
    plan.remove_service(name = "key-generation")
    
    return key_result["output"].strip()