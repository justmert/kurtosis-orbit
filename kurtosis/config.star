"""
Configuration module for Kurtosis-Orbit.
This module handles processing and validation of user-provided configuration parameters.
Based on Arbitrum's nitro-testnode setup.
"""

# Define the standard accounts based on nitro-testnode's mnemonic
# These accounts are expected to be pre-funded in the L1 genesis
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
    "l3owner": {
        "private_key": "47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a",
        "address": "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"
    },
    "l3sequencer": {
        "private_key": "8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba",
        "address": "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc"
    },
    "l2owner": {
        "private_key": "92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e",
        "address": "0x976EA74026E726554dB657fA54763abd0C3a0aa9"
    },
    "auctioneer": {
        "private_key": "4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356",
        "address": "0x14dC79964da2C08b23698B3D3cc7Ca32193d9955"
    }
}

# Default configuration values
DEFAULT_CONFIG = {
    "chain_name": "Orbit-Dev-Chain",
    "chain_id": 412346,
    "l1_chain_id": 1337,
    "rollup_mode": True,  # True for rollup, False for anytrust
    "challenge_period_blocks": 20,
    # Use the l2owner account as default for compatibility with nitro-testnode
    "owner_key_name": "l2owner",  # Using a named account
    "owner_private_key": STANDARD_ACCOUNTS["l2owner"]["private_key"],
    "owner_address": STANDARD_ACCOUNTS["l2owner"]["address"],
    "sequencer_key_name": "sequencer",
    "sequencer_private_key": STANDARD_ACCOUNTS["sequencer"]["private_key"],
    "sequencer_address": STANDARD_ACCOUNTS["sequencer"]["address"],
    "simple_mode": True,  # True for simple mode with one node doing everything
    "validator_count": 1,
    "batch_poster_count": 0,  # Only used if simple_mode is False
    "simple_validator": True,  # True for validator without block validator
    "enable_bridge": True,
    "enable_explorer": False,
    "stake_token": "0x0000000000000000000000000000000000000000",  # ETH by default
    "base_stake": "0",
    "pre_fund_accounts": ["funnel", "sequencer", "validator", "l2owner"]  # Accounts to fund in genesis
}

def process_config(args):
    """
    Process and validate user-provided configuration parameters
    
    Args:
        args: Dictionary containing user-provided configuration parameters
        
    Returns:
        Configuration object containing validated parameters
    """
    # Start with default configuration
    config_dict = dict(DEFAULT_CONFIG)
    
    # Override with user-provided parameters
    for key, value in args.items():
        if key in config_dict:
            config_dict[key] = value
    
    # Create a struct from the dictionary
    config = struct(**config_dict)
    
    # Validate configuration
    validate_config(config)
    
    # Set derived parameters
    config = set_derived_parameters(config)
    
    return config

def validate_config(config):
    """
    Validate the configuration parameters
    
    Args:
        config: Configuration object
    """
    # Validate chain ID
    if config.chain_id <= 0:
        fail("Chain ID must be greater than 0")
    
    # Validate L1 chain ID
    if config.l1_chain_id <= 0:
        fail("L1 chain ID must be greater than 0")
    
    # Validate challenge period
    if config.challenge_period_blocks <= 0:
        fail("Challenge period blocks must be greater than 0")
    
    # Validate batch poster count
    if config.batch_poster_count < 0:
        fail("Batch poster count must be non-negative")
    
    # Validate validator count
    if config.validator_count < 0:
        fail("Validator count must be non-negative")
    
    # Validate owner private key
    if not config.owner_private_key or len(config.owner_private_key) != 64:
        fail("Owner private key must be 64 characters (32 bytes) long without '0x' prefix")
    
    # Validate owner address
    if not config.owner_address or not config.owner_address.startswith("0x"):
        fail("Owner address must be a valid Ethereum address starting with '0x'")

def set_derived_parameters(config):
    """
    Set derived parameters based on existing configuration
    
    Args:
        config: Configuration object
        
    Returns:
        Updated configuration object
    """
    # Create a dictionary from the config struct
    config_dict = {key: getattr(config, key) for key in dir(config) if not key.startswith("_")}
    
    # If owner_key_name is provided but not owner_private_key/address, set them from STANDARD_ACCOUNTS
    if "owner_key_name" in config_dict and config_dict["owner_key_name"] in STANDARD_ACCOUNTS:
        account_name = config_dict["owner_key_name"]
        config_dict["owner_private_key"] = STANDARD_ACCOUNTS[account_name]["private_key"]
        config_dict["owner_address"] = STANDARD_ACCOUNTS[account_name]["address"]
    
    # If sequencer_key_name is provided but not sequencer_address, set it from STANDARD_ACCOUNTS
    if "sequencer_key_name" in config_dict and config_dict["sequencer_key_name"] in STANDARD_ACCOUNTS:
        account_name = config_dict["sequencer_key_name"]
        config_dict["sequencer_private_key"] = STANDARD_ACCOUNTS[account_name]["private_key"]
        config_dict["sequencer_address"] = STANDARD_ACCOUNTS[account_name]["address"]
    
    # If sequencer_address is not provided, use owner_address
    if not config_dict.get("sequencer_address"):
        config_dict["sequencer_address"] = config_dict["owner_address"]
    
    # Create a new struct with the updated values
    return struct(**config_dict)

def get_prefunded_accounts_json(config):
    """
    Generate JSON for prefunding accounts in the Ethereum genesis block
    
    Args:
        config: Configuration object
        
    Returns:
        JSON string of accounts to prefund
    """
    accounts = {}
    
    # Add all standard accounts that should be prefunded
    for acc_name in config.pre_fund_accounts:
        if acc_name in STANDARD_ACCOUNTS:
            accounts[STANDARD_ACCOUNTS[acc_name]["address"]] = {"balance": "1000000000000000000000"}  # 1000 ETH
    
    # Always include the owner and sequencer addresses with large balances
    accounts[config.owner_address] = {"balance": "1000000000000000000000"}  # 1000 ETH
    accounts[config.sequencer_address] = {"balance": "1000000000000000000000"}  # 1000 ETH
    
    # Convert to JSON string
    return json.encode(accounts)