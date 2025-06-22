"""
L2 account funding module using a dedicated Node.js container.
"""

config_module = import_module("./config.star")

def deploy_l2_funding(plan, config, l2_info):
    """
    Deploy L2 funding service to fund accounts after tokenbridge deployment.
    """
    plan.print("Deploying L2 account funding service...")
    
    # Upload the funding scripts directory
    funding_scripts = plan.upload_files(
        src="./scripts/",
        name="funding-scripts"
    )
    
    # Deploy the funding service
    funding_service = plan.add_service(
        name="l2-funding",
        config=ServiceConfig(
            image="node:20-bookworm-slim",
            cmd=["sh", "-c", "cd /workspace && yarn install && tail -f /dev/null"],
            files={
                "/workspace": funding_scripts,
            },
        ),
    )
    
    # Wait for service to be ready and yarn install to complete
    plan.wait(
        service_name="l2-funding",
        recipe=ExecRecipe(command=["test", "-d", "/workspace/node_modules"]),
        field="code",
        assertion="==",
        target_value=0,
        timeout="2m"
    )
    
    plan.print("✅ L2 funding service deployed!")
    
    return {
        "service": funding_service,
    }

def fund_l2_accounts(plan, config, l1_info, l2_info, rollup_info):
    """
    Fund all configured accounts on L2.
    """
    plan.print("Starting L2 account funding...")
    
    # Get all accounts that need funding
    all_accounts = config_module.get_all_prefunded_accounts(config)
    
    # The funnel account private key
    funnel_key = config_module.STANDARD_ACCOUNTS["funnel"]["private_key"]
    
    # Build the accounts list for the funding script
    accounts_list = []
    for addr, info in all_accounts.items():
        if info["name"] != "funnel" and float(info["balance_l2"]) > 0:
            accounts_list.append({
                "name": info["name"],
                "address": addr,
                "amount": str(info["balance_l2"])
            })
    
    if len(accounts_list) == 0:
        plan.print("No accounts need L2 funding, skipping...")
        return {"funded_accounts": 0}
    
    # First, bridge ETH from L1 to L2 for the funnel account
    # This is necessary because the funnel account starts with ETH on L1
    plan.print("🌉 Step 1: Bridging ETH from L1 to L2 for funnel account...")
    
    # Get addresses from deployment info
    l1_rpc_url = l1_info["rpc_url"]
    l2_rpc_url = l2_info["sequencer"]["rpc_url"]
    
    # Get inbox address from rollup deployment
    if "inbox_address" in rollup_info:
        inbox_address = rollup_info["inbox_address"]
    else:
        plan.print("⚠️  Inbox address not found in rollup deployment - skipping bridge")
        plan.print("This might happen if rollup deployment failed or is incomplete")
        inbox_address = None
    
    if inbox_address:
        # Calculate total amount needed for all accounts plus buffer
        total_needed = 0
        for acc in accounts_list:
            total_needed += float(acc["amount"])
        bridge_amount = str(int(total_needed * 1.2))  # 20% buffer
        
        plan.print("Bridging {} ETH from L1 to L2 (need {} for funding)".format(bridge_amount, total_needed))
        plan.print("Using inbox address: {}".format(inbox_address))
        
        # Bridge ETH from L1 to L2 using our bridge script
        plan.exec(
            service_name="l2-funding",
            recipe=ExecRecipe(
                command=[
                    "sh", "-c",
                    "cd /workspace && node bridge-l1-to-l2.js {} {} {} {} {}".format(
                        l1_rpc_url, l2_rpc_url, funnel_key, inbox_address, bridge_amount
                    )
                ]
            )
        )
    else:
        plan.print("⚠️  Skipping bridge step - no inbox address available")
    
    plan.print("🔍 Step 2: Checking funnel account balance on L2...")
    
    # Check funnel balance before proceeding
    plan.exec(
        service_name="l2-funding",
        recipe=ExecRecipe(
            command=[
                "sh", "-c",
                "cd /workspace && node check-balances.js {} accounts.json".format(l2_rpc_url)
            ]
        )
    )
    
    plan.print("💰 Step 3: Funding L2 accounts from funnel...")
    
    # Create the accounts.json file using heredoc
    plan.exec(
        service_name="l2-funding",
        recipe=ExecRecipe(
            command=[
                "sh", "-c", 
                """cat > /workspace/accounts.json << 'EOF'
{}
EOF""".format(json.encode(accounts_list))
            ]
        )
    )
    
    # Verify the accounts.json file was created correctly
    plan.exec(
        service_name="l2-funding",
        recipe=ExecRecipe(
            command=["sh", "-c", "echo 'Accounts to fund:' && cat /workspace/accounts.json"]
        )
    )
    
    # Execute the funding script
    plan.exec(
        service_name="l2-funding",
        recipe=ExecRecipe(
            command=[
                "sh", "-c",
                "cd /workspace && node fund-all.js {} {}".format(l2_rpc_url, funnel_key)
            ]
        )
    )
    
    # Verify funding by checking balances
    plan.print("🔍 Step 4: Verifying L2 account balances...")
    plan.exec(
        service_name="l2-funding",
        recipe=ExecRecipe(
            command=[
                "sh", "-c",
                "cd /workspace && node check-balances.js {} accounts.json".format(l2_rpc_url)
            ]
        )
    )
    
    plan.print("✅ L2 account funding completed!")
    
    return {
        "funded_accounts": len(accounts_list)
    } 