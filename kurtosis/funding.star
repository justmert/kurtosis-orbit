"""
L2 account funding module using a dedicated Node.js container.
"""

config_module = import_module("./config.star")

def deploy_l2_funding(plan, config, l2_info):
    """
    Deploy L2 funding service with proper service patterns.
    """
    # Upload funding scripts as artifact
    funding_scripts = plan.upload_files(
        src="./scripts/",
        name="funding-scripts"
    )
    
    # Deploy funding service with proper ready conditions
    funding_service = plan.add_service(
        name="l2-funding",
        config=ServiceConfig(
            image="node:20-bookworm-slim",
            cmd=[
                "sh", "-c", 
                "cd /workspace && npm install && tail -f /dev/null"
            ],
            files={
                "/workspace": funding_scripts,
            },
            ready_conditions=ReadyCondition(
                recipe=ExecRecipe(
                    command=["test", "-d", "/workspace/node_modules"]
                ),
                field="code",
                assertion="==",
                target_value=0,
                timeout="5m",
                interval="10s"
            ),
        ),
    )
    
    plan.print("✅ L2 funding service deployed!")
    
    return {
        "service": funding_service,
    }

def fund_l2_accounts(plan, config, l1_info, l2_info, rollup_info):
    """
    Fund L2 accounts using structured funding approach.
    """
    # Prepare funding configuration
    funding_config = _prepare_funding_config(config)
    
    if len(funding_config["accounts"]) == 0:
        plan.print("No accounts require L2 funding")
        return {"funded_accounts": 0}
    
    # Execute funding phases
    _execute_bridge_funding(plan, funding_config, l1_info, l2_info, rollup_info)
    _execute_account_funding(plan, funding_config, l2_info)
    
    return {"funded_accounts": len(funding_config["accounts"])}

def _prepare_funding_config(config):
    """Prepare funding configuration with validation."""
    all_accounts = config_module.get_all_prefunded_accounts(config)
    funnel_key = config_module.STANDARD_ACCOUNTS["funnel"]["private_key"]
    
    accounts_list = []
    for addr, info in all_accounts.items():
        if info["name"] != "funnel" and float(info["balance_l2"]) > 0:
            accounts_list.append({
                "name": info["name"],
                "address": addr,
                "amount": str(info["balance_l2"])
            })
    
    return {
        "accounts": accounts_list,
        "funnel_key": funnel_key
    }

def _execute_bridge_funding(plan, funding_config, l1_info, l2_info, rollup_info):
    """Execute bridge funding phase."""
    if "inbox_address" not in rollup_info:
        plan.print("Warning: Inbox address not available, skipping bridge funding")
        return
    
    # Calculate bridge amount
    total_needed = 0
    for acc in funding_config["accounts"]:
        total_needed += float(acc["amount"])
    bridge_amount = str(int(total_needed * 1.2))  # 20% buffer
    
    plan.print("Bridging {} ETH from L1 to L2".format(bridge_amount))
    
    # Execute bridge operation
    plan.exec(
        service_name="l2-funding",
        recipe=ExecRecipe(
            command=[
                "node", "/workspace/bridge-l1-to-l2.js",
                l1_info["rpc_url"],
                l2_info["sequencer"]["rpc_url"], 
                funding_config["funnel_key"],
                rollup_info["inbox_address"],
                bridge_amount
            ]
        )
    )

def _execute_account_funding(plan, funding_config, l2_info):
    """Execute L2 account funding phase."""
    # Create funding configuration using heredoc approach
    plan.exec(
        service_name="l2-funding",
        recipe=ExecRecipe(
            command=[
                "sh", "-c", 
                "cat > /workspace/accounts.json << 'EOF'\n{}\nEOF".format(
                    json.encode(funding_config["accounts"])
                )
            ]
        )
    )
    
    # Execute funding with proper error handling
    plan.exec(
        service_name="l2-funding",
        recipe=ExecRecipe(
            command=[
                "node", "/workspace/fund-all.js",
                l2_info["sequencer"]["rpc_url"],
                funding_config["funnel_key"]
            ]
        )
    )
    
    # Verify funding results
    plan.exec(
        service_name="l2-funding",
        recipe=ExecRecipe(
            command=[
                "node", "/workspace/check-balances.js",
                l2_info["sequencer"]["rpc_url"],
                "accounts.json"
            ]
        )
    ) 