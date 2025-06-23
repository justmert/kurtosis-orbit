"""
Blockscout explorer deployment module.
"""

def deploy_blockscout(plan, config, nodes_info):
    """
    Deploy Blockscout explorer for the L2 chain.
    """
    plan.print("Deploying PostgreSQL database...")
    
    # Deploy PostgreSQL
    # PostgreSQL service
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
                "-c", "effective_io_concurrency=200",
                # Add these for better connection handling:
                "-c", "log_connections=on",
                "-c", "log_disconnections=on",
                "-c", "log_statement=all"
            ],
            env_vars={
                "POSTGRES_PASSWORD": "",
                "POSTGRES_USER": "postgres", 
                "POSTGRES_HOST_AUTH_METHOD": "trust",
                "POSTGRES_DB": "blockscout",
                # Add explicit database creation
                "POSTGRES_INITDB_ARGS": "--encoding=UTF8 --lc-collate=C --lc-ctype=C",
            },
        ),
    )
        
    # After PostgreSQL deployment, add this check
# Simple PostgreSQL readiness check
    plan.exec(
        service_name="postgres",
        recipe=ExecRecipe(
            command=["sh", "-c", 
                    "until psql -U postgres -d blockscout -c 'SELECT 1;' > /dev/null 2>&1; do " +
                    "echo 'Waiting for PostgreSQL and blockscout database...'; sleep 2; done && " +
                    "echo 'PostgreSQL is ready!'"
            ]
        )
    )
    
    # # Additional wait for full initialization
    # plan.exec(
    #     service_name="postgres",
    #     recipe=ExecRecipe(
    #         command=["sh", "-c", "sleep 5 && psql -U postgres -c 'SELECT version();'"]
    #     )
    # )
    
    plan.print("Deploying Blockscout...")
    
    # Deploy Blockscout
    blockscout_service = plan.add_service(
        name="blockscout",
        config=ServiceConfig(
            image=config["blockscout_image"],
            ports={
                "http": PortSpec(
                    number=4001,
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
                "ETHEREUM_JSONRPC_TRACE_URL": nodes_info["sequencer"]["rpc_url"],
                "ETHEREUM_JSONRPC_WS_URL": nodes_info["sequencer"]["ws_url"],
                "DATABASE_URL": "postgresql://postgres:@postgres:5432/blockscout",
                "ECTO_USE_SSL": "false",
                "NETWORK": "Arbitrum",
                "SUBNETWORK": config["chain_name"],
                "CHAIN_ID": str(config["chain_id"]),
                "PORT": "4001",
                "HOST": "0.0.0.0",
                "MIX_ENV": "prod",
                "SECRET_KEY_BASE": "56NtB48ear7+wMSf0+YLefvOsDUW8/vUHvhEq7+sj3+8wKkD/AAMOzALM+vLYqLEeOk2B1TcKVrqDTYL2Bqf4Q==",
                "DATABASE_CONNECTION_POOL_SIZE": "30",
                "DATABASE_QUEUE_TARGET": "50", 
                "DATABASE_QUEUE_INTERVAL": "5000",
                "SHOW_TESTNET_LABEL": "true",
                "LOGO": "/images/arbitrum_logo.svg",
                "LOGO_FOOTER": "/images/arbitrum_logo.svg",                
                "EMISSION_FORMAT": "DEFAULT",
                "POOL_SIZE": "40",
                "POOL_SIZE_API": "10",
                "HEART_BEAT_TIMEOUT": "30",
                "BLOCKSCOUT_VERSION": "Arbitrum 0.0.1",
                "RELEASE_LINK": "",
                "BLOCK_TRANSFORMER": "base",
                "LINK_TO_OTHER_EXPLORERS": "false",
                "OTHER_EXPLORERS": "{}",
                "SUPPORTED_CHAINS": "{}",
                "BLOCK_COUNT_CACHE_PERIOD": "7200",
                "TXS_COUNT_CACHE_PERIOD": "7200",
                "ADDRESS_COUNT_CACHE_PERIOD": "7200",
                "ADDRESS_SUM_CACHE_PERIOD": "3600",
                "TOTAL_GAS_USAGE_CACHE_PERIOD": "3600",
                "ADDRESS_TRANSACTIONS_GAS_USAGE_COUNTER_CACHE_PERIOD": "1800",
                "TOKEN_HOLDERS_COUNTER_CACHE_PERIOD": "3600",
                "TOKEN_TRANSFERS_COUNTER_CACHE_PERIOD": "3600",
                "ADDRESS_WITH_BALANCES_UPDATE_INTERVAL": "1800",
                "TOKEN_METADATA_UPDATE_INTERVAL": "172800",
                "AVERAGE_BLOCK_CACHE_PERIOD": "1800",
                "MARKET_HISTORY_CACHE_PERIOD": "21600",
                "ADDRESS_TRANSACTIONS_CACHE_PERIOD": "1800",
                "ADDRESS_TOKENS_USD_SUM_CACHE_PERIOD": "1800",
                "ADDRESS_TOKEN_TRANSFERS_COUNTER_CACHE_PERIOD": "1800",
                "BRIDGE_MARKET_CAP_UPDATE_INTERVAL": "1800",
                "TOKEN_EXCHANGE_RATE_CACHE_PERIOD": "1800",
                "ALLOWED_EVM_VERSIONS": "homestead,tangerineWhistle,spuriousDragon,byzantium,constantinople,petersburg,istanbul,berlin,london,default",
                "UNCLES_IN_AVERAGE_BLOCK_TIME": "false",
                "DISABLE_WEBAPP": "false",
                "DISABLE_READ_API": "false",
                "DISABLE_WRITE_API": "false",
                "DISABLE_INDEXER": "false",
                "INDEXER_DISABLE_PENDING_TRANSACTIONS_FETCHER": "false",
                "INDEXER_DISABLE_INTERNAL_TRANSACTIONS_FETCHER": "false",
                "WOBSERVER_ENABLED": "false",
                "SHOW_ADDRESS_MARKETCAP_PERCENTAGE": "true",
                "CHECKSUM_ADDRESS_HASHES": "true",
                "CHECKSUM_FUNCTION": "eth",
                "DISABLE_EXCHANGE_RATES": "true",
                "DISABLE_KNOWN_TOKENS": "false",
                "ENABLE_TXS_STATS": "true",
                "SHOW_TXS_CHART": "true",
                "HISTORY_FETCH_INTERVAL": "30",
                "TXS_HISTORIAN_INIT_LAG": "0",
                "TXS_STATS_DAYS_TO_COMPILE_AT_INIT": "10",
                "COIN_BALANCE_HISTORY_DAYS": "90",
                "APPS_MENU": "false",
                "EXTERNAL_APPS": "[]",
                "DISABLE_BRIDGE_MARKET_CAP_UPDATER": "true",
                "ENABLE_POS_STAKING_IN_MENU": "false",
                "SHOW_MAINTENANCE_ALERT": "false",
                "MAINTENANCE_ALERT_MESSAGE": "",
                "SHOW_STAKING_WARNING": "false",
                "STAKING_WARNING_MESSAGE": "",
                "CUSTOM_CONTRACT_ADDRESSES_TEST_TOKEN": "",
                "ENABLE_SOURCIFY_INTEGRATION": "false",
                "SOURCIFY_SERVER_URL": "",
                "SOURCIFY_REPO_URL": "",
                "MAX_SIZE_UNLESS_HIDE_ARRAY": "50",
                "HIDE_BLOCK_MINER": "false",
                "DISPLAY_TOKEN_ICONS": "false",
                "SHOW_TENDERLY_LINK": "false",
                "TENDERLY_CHAIN_PATH": "",
                "MAX_STRING_LENGTH_WITHOUT_TRIMMING": "2040",
                "RE_CAPTCHA_SECRET_KEY": "",
                "RE_CAPTCHA_CLIENT_KEY": "",
                "API_RATE_LIMIT": "50",
                "API_RATE_LIMIT_BY_KEY": "50",
                "API_RATE_LIMIT_BY_IP": "50",
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
    
    explorer_url = "http://{}:{}".format(blockscout_service.hostname, 4001)
    
    plan.print("✅ Blockscout explorer deployed!")
    plan.print("Note: It may take a few minutes for Blockscout to index initial blocks")
    
    return {
        "url": explorer_url,
        "internal_url": "http://blockscout:4001",
        "postgres_url": "postgresql://postgres:@postgres:5432/blockscout",
        "status": "deployed"
    }