"""
Blockscout explorer deployment module.
"""

def deploy_blockscout(plan, config, nodes_info):
    """
    Deploy Blockscout explorer for the L2 chain.
    """
    plan.print("Deploying PostgreSQL database...")
    
    # Deploy PostgreSQL
    postgres_service = plan.add_service(
        name="postgres",
        config=ServiceConfig(
            image=config["postgres_image"],
            ports={
                "postgres": PortSpec(number=5432),
            },
            cmd=[
                "postgres",
                "-c", "max_connections=200",
                "-c", "shared_buffers=256MB",
                "-c", "effective_cache_size=1GB",
                "-c", "maintenance_work_mem=64MB",
                "-c", "checkpoint_completion_target=0.9",
                "-c", "wal_buffers=16MB",
                "-c", "default_statistics_target=100",
                "-c", "random_page_cost=1.1",
                "-c", "effective_io_concurrency=200"
            ],
            env_vars={
                "POSTGRES_PASSWORD": "",
                "POSTGRES_USER": "postgres",
                "POSTGRES_HOST_AUTH_METHOD": "trust",
                "POSTGRES_DB": "blockscout",
            },
        ),
    )
    
    # Wait for PostgreSQL
    plan.wait(
        service_name="postgres",
        recipe=ExecRecipe(
            command=["pg_isready", "-U", "postgres"]
        ),
        field="code",
        assertion="==",
        target_value=0,
        timeout="120s",
    )
    
    # Additional wait for full initialization
    plan.exec(
        service_name="postgres",
        recipe=ExecRecipe(
            command=["sh", "-c", "sleep 5 && psql -U postgres -c 'SELECT version();'"]
        )
    )
    
    plan.print("Deploying Blockscout...")
    
    # Deploy Blockscout
    blockscout_service = plan.add_service(
        name="blockscout",
        config=ServiceConfig(
            image=config["blockscout_image"],
            ports={
                "http": PortSpec(
                    number=4000,
                    transport_protocol="TCP",
                    application_protocol="http",
                    wait="120s"
                ),
            },
            cmd=[
                "/bin/sh",
                "-c",
                """
                bin/blockscout eval "Elixir.Explorer.ReleaseTasks.create_and_migrate()" && \
                echo 'Database migration completed' && \
                bin/blockscout start
                """
            ],
            env_vars={
                "ETHEREUM_JSONRPC_VARIANT": "geth",
                "ETHEREUM_JSONRPC_HTTP_URL": nodes_info["sequencer"]["rpc_url"],
                "INDEXER_DISABLE_PENDING_TRANSACTIONS_FETCHER": "true",
                "DATABASE_URL": "postgresql://postgres:@postgres:5432/blockscout",
                "ECTO_USE_SSL": "false",
                "NETWORK": "Arbitrum",
                "SUBNETWORK": config["chain_name"],
                "CHAIN_ID": str(config["chain_id"]),
                "PORT": "4000",
                "HOST": "0.0.0.0",
                "MIX_ENV": "prod",
                "SECRET_KEY_BASE": "56NtB48ear7+wMSf0+YLefvOsDUW8/vUHvhEq7+sj3+8wKkD/AAMOzALM+vLYqLEeOk2B1TcKVrqDTYL2Bqf4Q==",
                "DATABASE_CONNECTION_POOL_SIZE": "30",
                "DATABASE_QUEUE_TARGET": "50",
                "DATABASE_QUEUE_INTERVAL": "5000",
                "SHOW_TESTNET_LABEL": "true",
                "LOGO": "/images/arbitrum_logo.svg",
                "LOGO_FOOTER": "/images/arbitrum_logo.svg",
                "DISABLE_WEBAPP": "false",
                "DISABLE_READ_API": "false",
                "DISABLE_WRITE_API": "false",
                "DISABLE_INDEXER": "false",
                "INDEXER_MEMORY_LIMIT": "1",
                "INDEXER_EMPTY_BLOCKS_SANITIZER_BATCH_SIZE": "100",
                "TZ": "UTC",
            },
            ready_conditions=ReadyCondition(
                recipe=GetHttpRequestRecipe(
                    port_id="http",
                    endpoint="/"
                ),
                field="code",
                assertion="==",
                target_value=200,
                timeout="10m"
            ),
        ),
    )
    
    explorer_url = "http://{}:{}".format(blockscout_service.hostname, 4000)
    
    plan.print("✅ Blockscout explorer deployed!")
    plan.print("Note: It may take a few minutes for Blockscout to index initial blocks")
    
    return {
        "url": explorer_url,
        "internal_url": "http://blockscout:4000",
        "postgres_url": "postgresql://postgres:@postgres:5432/blockscout",
        "status": "deployed"
    }