"""
Block explorer deployment module for Kurtosis-Orbit.
This module handles the deployment of a Blockscout explorer for the L2 chain.
"""

# Default Blockscout version
BLOCKSCOUT_VERSION = "offchainlabs/blockscout:v1.1.0-0e716c8"

def deploy_blockscout(plan, config, nodes_info):
    """
    Deploy Blockscout explorer for the L2 chain
    
    Args:
        plan: The Kurtosis execution plan
        config: Configuration object
        nodes_info: Information about the deployed Nitro nodes
        
    Returns:
        Dictionary with explorer information
    """
    plan.print("Deploying Blockscout explorer...")
    
    # First deploy a Postgres database for Blockscout
    postgres_service = plan.add_service(
        name="postgres",
        config=ServiceConfig(
            image="postgres:13.6",
            ports={
                "postgres": PortSpec(number=5432),
            },
            env_vars={
                "POSTGRES_PASSWORD": "",
                "POSTGRES_USER": "postgres",
                "POSTGRES_HOST_AUTH_METHOD": "trust",
            },
        ),
    )
    
    # Wait for Postgres to start
    plan.wait(
        service_name="postgres",
        recipe=ExecRecipe(
            command=["pg_isready", "-U", "postgres"]
        ),
        field="code",
        assertion="==",
        target_value=0,
        timeout="30s",
    )
    
    # Create Blockscout environment file
    blockscout_env = """
    ETHEREUM_JSONRPC_VARIANT=geth
    ETHEREUM_JSONRPC_HTTP_URL={rpc_url}
    INDEXER_DISABLE_PENDING_TRANSACTIONS_FETCHER=true
    DATABASE_URL=postgresql://postgres:@postgres:5432/blockscout
    ECTO_USE_SSL=false
    NETWORK={network}
    SUBNETWORK={subnetwork}
    CHAIN_ID={chain_id}
    """.format(
        rpc_url=nodes_info["sequencer"]["rpc_url"],
        network="Arbitrum",
        subnetwork=config.chain_name,
        chain_id=config.chain_id,
    )
    
    # Write Blockscout environment file to a template
    blockscout_env_artifact = plan.render_templates(
        config={
            "/blockscout.env": struct(
                template=blockscout_env,
                data={},
            ),
        },
        name="blockscout-env",
    )
    
    # Deploy Blockscout
    blockscout_service = plan.add_service(
        name="blockscout",
        config=ServiceConfig(
            image=BLOCKSCOUT_VERSION,
            ports={
                "http": PortSpec(number=4000, application_protocol="http"),
            },
            env_vars={
                "ETHEREUM_JSONRPC_VARIANT": "geth",
                "ETHEREUM_JSONRPC_HTTP_URL": nodes_info["sequencer"]["rpc_url"],
                "INDEXER_DISABLE_PENDING_TRANSACTIONS_FETCHER": "true",
                "DATABASE_URL": "postgresql://postgres:@postgres:5432/blockscout",
                "ECTO_USE_SSL": "false",
                "NETWORK": "Arbitrum",
                "SUBNETWORK": config.chain_name,
                "CHAIN_ID": str(config.chain_id),
            },
            cmd=[
                "/bin/sh",
                "-c",
                "bin/blockscout eval \"Elixir.Explorer.ReleaseTasks.create_and_migrate()\" && bin/blockscout start"
            ],
            files={
                "/app/config/blockscout.env": blockscout_env_artifact,
            },
        ),
        ready_conditions=ReadyCondition(
            recipe=GetHttpRequestRecipe(port_id="http", endpoint="/"),
            field="code",
            assertion="==",
            target_value=200,
        ),
    )
    
    return {
        "url": "http://" + blockscout_service.hostname + ":" + str(blockscout_service.ports["http"].number),
    }