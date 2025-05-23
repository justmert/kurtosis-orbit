"""
Configuration module with validation and nitro-testnode alignment.
"""

# Standard accounts from nitro-testnode mnemonic
STANDARD_ACCOUNTS = {
    "funnel": {
        "private_key": "59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
        "address": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
    },
    "sequencer": {
        "private_key": "5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a",
        "address": "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
    },
    "validator": {
        "private_key": "7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6",
        "address": "0x90F79bf6EB2c4f870365E785982E1f101E93b906"
    },
    "l2owner": {
        "private_key": "92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e",
        "address": "0x976EA74026E726554dB657fA54763abd0C3a0aa9"
    }
}

# Default configuration
DEFAULT_CONFIG = {
    "chain_name": "Orbit-Dev-Chain",
    "chain_id": 412346,
    "l1_chain_id": 1337,
    "rollup_mode": True,
    "challenge_period_blocks": 20,
    "stake_token": "0x0000000000000000000000000000000000000000",
    "base_stake": "0",
    "owner_private_key": STANDARD_ACCOUNTS["l2owner"]["private_key"],
    "owner_address": STANDARD_ACCOUNTS["l2owner"]["address"],
    "sequencer_private_key": STANDARD_ACCOUNTS["sequencer"]["private_key"],
    "sequencer_address": STANDARD_ACCOUNTS["sequencer"]["address"],
    "validator_private_key": STANDARD_ACCOUNTS["validator"]["private_key"],
    "validator_address": STANDARD_ACCOUNTS["validator"]["address"],
    "simple_mode": True,
    "validator_count": 1,
    "enable_bridge": True,
    "enable_explorer": False,
    "enable_timeboost": False,
    "pre_fund_accounts": ["funnel", "sequencer", "validator", "l2owner"],
    "nitro_image": "offchainlabs/nitro-node:v3.5.5-90ee45c",
    "nitro_contracts_branch": "v2.1.1-beta.0",
    "token_bridge_branch": "v1.2.2",
}

def process_config(args):
    """
    Process and validate user configuration.
    """
    # Start with defaults
    config_dict = dict(DEFAULT_CONFIG)
    
    # Merge user config
    if "orbit_config" in args:
        orbit_config = args["orbit_config"]
        for key, value in orbit_config.items():
            if key in config_dict:
                config_dict[key] = value
    
    # Validate configuration
    validate_config(config_dict)
    
    # Generate dynamic values
    config_dict["jwt_secret"] = generate_jwt_secret()
    config_dict["val_jwt_secret"] = generate_jwt_secret()
    
    # Set derived values
    if not config_dict.get("owner_private_key"):
        config_dict["owner_private_key"] = STANDARD_ACCOUNTS["l2owner"]["private_key"]
        config_dict["owner_address"] = STANDARD_ACCOUNTS["l2owner"]["address"]
    
    return struct(**config_dict)

def validate_config(config):
    """
    Validate configuration parameters.
    """
    # Chain ID validation
    if config["chain_id"] <= 0:
        fail("chain_id must be positive")
    
    if config["l1_chain_id"] <= 0:
        fail("l1_chain_id must be positive")
    
    if config["chain_id"] == config["l1_chain_id"]:
        fail("L2 chain_id must be different from L1 chain_id")
    
    # Challenge period validation
    if config["challenge_period_blocks"] <= 0:
        fail("challenge_period_blocks must be positive")
    
    # Validator count validation
    if config["validator_count"] < 0:
        fail("validator_count must be non-negative")
    
    if config["validator_count"] > 1:
        print("WARNING: Multiple validators not fully supported. Using 1 validator.")
        config["validator_count"] = 1
    
    # Mode validation
    if not config["rollup_mode"] and config.get("anytrust_config") == None:
        print("WARNING: AnyTrust mode requires das_config. Falling back to rollup mode.")
        config["rollup_mode"] = True
    
    # Timeboost validation
    if config.get("enable_timeboost"):
        print("WARNING: Timeboost is experimental and may not be fully functional.")

def generate_jwt_secret():
    """
    Generate a deterministic JWT secret for development.
    In production, this should use proper randomness.
    """
    # Using a fixed value for deterministic development environment
    return "0x" + ("0" * 64)

def get_prefunded_accounts_json(config):
    """
    Generate JSON for prefunding accounts in L1 genesis.
    """
    accounts = {}
    
    # Fund standard accounts
    for acc_name in config.pre_fund_accounts:
        if acc_name in STANDARD_ACCOUNTS:
            accounts[STANDARD_ACCOUNTS[acc_name]["address"]] = {
                "balance": "1000000000000000000000"  # 1000 ETH
            }
    
    # Always fund the deployer account
    accounts["0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E"] = {
        "balance": "1000000000000000000000000000000000"  # Large balance
    }
    
    # Add any custom prefund addresses
    if hasattr(config, "prefund_addresses"):
        for addr in config.prefund_addresses:
            if addr.startswith("0x") and len(addr) == 42:
                accounts[addr] = {"balance": "100000000000000000000"}  # 100 ETH
    
    return json.encode(accounts)