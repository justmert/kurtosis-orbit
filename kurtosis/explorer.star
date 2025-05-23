"""
Block explorer deployment module for Kurtosis-Orbit.
This module handles the deployment of a Blockscout explorer for the L2 chain.
Based on nitro-testnode's blockscout implementation.
"""

# Blockscout version from nitro-testnode
BLOCKSCOUT_VERSION = "offchainlabs/blockscout:v1.1.0-0e716c8"
POSTGRES_VERSION = "postgres:13.6"

def deploy_blockscout(plan, config, nodes_info):
    """
    Deploy Blockscout explorer for the L2 chain following nitro-testnode patterns
    
    Args:
        plan: The Kurtosis execution plan
        config: Configuration object
        nodes_info: Information about the deployed Nitro nodes
        
    Returns:
        Dictionary with explorer information
    """
    plan.print("Deploying Blockscout explorer...")
    
    # First deploy PostgreSQL database for Blockscout (matching nitro-testnode)
    postgres_service = plan.add_service(
        name="postgres",
        config=ServiceConfig(
            image=POSTGRES_VERSION,
            ports={
                "postgres": PortSpec(number=5432),
            },
            cmd=[
                "postgres",
                "-c", "max_connections=200",          # Increase from default 100
                "-c", "shared_buffers=256MB",         # Increase shared buffers
                "-c", "effective_cache_size=1GB",     # Set cache size
                "-c", "maintenance_work_mem=64MB",    # Memory for maintenance
                "-c", "checkpoint_completion_target=0.9",
                "-c", "wal_buffers=16MB",
                "-c", "default_statistics_target=100",
                "-c", "random_page_cost=1.1",
                "-c", "effective_io_concurrency=200"
            ],
            env_vars={
                "POSTGRES_PASSWORD": "",  # Empty password like nitro-testnode
                "POSTGRES_USER": "postgres",
                "POSTGRES_HOST_AUTH_METHOD": "trust",  # Trust authentication
                "POSTGRES_DB": "blockscout",  # Create the database automatically
            },
        ),
    )
    
    # Wait for Postgres to be ready
    plan.wait(
        service_name="postgres",
        recipe=ExecRecipe(
            command=["pg_isready", "-U", "postgres"]
        ),
        field="code",
        assertion="==",
        target_value=0,
        timeout="120s",  # Increased timeout for PostgreSQL startup
    )
    
    # Additional wait to ensure PostgreSQL is fully initialized
    plan.exec(
        service_name="postgres",
        recipe=ExecRecipe(
            command=["sh", "-c", "sleep 10 && psql -U postgres -c 'SELECT version();'"]
        )
    )
    
    # Deploy Blockscout service (matching nitro-testnode setup)
    blockscout_service = plan.add_service(
        name="blockscout",
        config=ServiceConfig(
            image=BLOCKSCOUT_VERSION,
            ports={
                "http": PortSpec(
                    number=4000, 
                    transport_protocol="TCP",
                    application_protocol="http"
                ),
            },
            # Command structure from nitro-testnode
            cmd=[
                "/bin/sh",
                "-c",
                # Multi-step startup process matching nitro-testnode
                "bin/blockscout eval \"Elixir.Explorer.ReleaseTasks.create_and_migrate()\" && " +
                "echo 'Database migration completed' && " +
                "bin/blockscout start"
            ],
            env_vars={
                # Core environment variables matching nitro-testnode
                "ETHEREUM_JSONRPC_VARIANT": "geth",
                "ETHEREUM_JSONRPC_HTTP_URL": nodes_info["sequencer"]["rpc_url"],
                "INDEXER_DISABLE_PENDING_TRANSACTIONS_FETCHER": "true",
                "DATABASE_URL": "postgresql://postgres:@postgres:5432/blockscout",
                "ECTO_USE_SSL": "false",
                "NETWORK": "Arbitrum",
                "SUBNETWORK": config.chain_name,
                "CHAIN_ID": str(config.chain_id),
                # Phoenix web server configuration
                "PORT": "4000",  # Required for Phoenix to start the web server
                "HOST": "0.0.0.0",  # Listen on all interfaces
                "MIX_ENV": "prod",  # Set production environment
                "SECRET_KEY_BASE": "56NtB48ear7+wMSf0+YLefvOsDUW8/vUHvhEq7+sj3+8wKkD/AAMOzALM+vLYqLEeOk2B1TcKVrqDTYL2Bqf4Q==",  # Static secret for dev
                # Database connection pool settings
                "DATABASE_CONNECTION_POOL_SIZE": "30",  # Limit pool size
                "DATABASE_QUEUE_TARGET": "50",
                "DATABASE_QUEUE_INTERVAL": "5000",
                # Additional configuration
                "SHOW_TESTNET_LABEL": "true",
                "LOGO": "/images/arbitrum_logo.svg",
                "LOGO_FOOTER": "/images/arbitrum_logo.svg",
                # Disable some features that might cause issues in local dev
                "DISABLE_WEBAPP": "false",
                "DISABLE_READ_API": "false", 
                "DISABLE_WRITE_API": "false",
                "DISABLE_INDEXER": "false",
                # Reduce worker processes to lower DB connection usage
                "INDEXER_MEMORY_LIMIT": "1",
                "INDEXER_EMPTY_BLOCKS_SANITIZER_BATCH_SIZE": "100",
                # Set timezone
                "TZ": "UTC",
            },
            # Ready condition - wait for HTTP endpoint to be available
            ready_conditions=ReadyCondition(
                recipe=GetHttpRequestRecipe(
                    port_id="http", 
                    endpoint="/"
                ),
                field="code",
                assertion="==",
                target_value=200,
            ),
        ),
    )
    
    # Additional wait to ensure Blockscout is fully initialized
    plan.wait(
        service_name="blockscout",
        recipe=GetHttpRequestRecipe(
            port_id="http",
            endpoint="/",
        ),
        field="code",
        assertion="==",
        target_value=200,
        timeout="10m",  # Increased timeout for Blockscout startup with DB management
    )
    
    explorer_url = "http://" + blockscout_service.hostname + ":" + str(blockscout_service.ports["http"].number)
    
    plan.print("Blockscout explorer deployed successfully!")
    plan.print("Explorer URL: " + explorer_url)
    plan.print("Note: It may take a few minutes for Blockscout to index the initial blocks")
    
    return {
        "url": explorer_url,
        "internal_url": "http://blockscout:4000",
        "postgres_url": "postgresql://postgres:@postgres:5432/blockscout",
        "status": "deployed"
    }