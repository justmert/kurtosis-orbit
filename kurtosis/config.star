"""
Improved configuration module for Kurtosis-Orbit.
This module aligns with nitro-testnode's account structure and configuration patterns.
"""

# Standard accounts from nitro-testnode mnemonic: 
# "indoor dish desk flag debris potato excuse depart ticket judge file exit"
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
        "private_key":"92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e",
        "address": "0x976EA74026E726554dB657fA54763abd0C3a0aa9"
    },
    "auctioneer": {
        "private_key": "4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356",
        "address": "0x14dC79964da2C08b23698B3D3cc7Ca32193d9955"
    }
}

# Default configuration matching nitro-testnode patterns
DEFAULT_CONFIG = {
    "chain_name": "Orbit-Dev-Chain",
    "chain_id": 412346,
    "l1_chain_id": 1337,
    
    # Rollup configuration
    "rollup_mode": True,  # True for rollup, False for anytrust
    "challenge_period_blocks": 20,
    "stake_token": "0x0000000000000000000000000000000000000000",  # ETH by default
    "base_stake": "0",
    
    # Account configuration - using l2owner as primary (matches nitro-testnode)
    "owner_key_name": "l2owner",
    "owner_private_key": STANDARD_ACCOUNTS["l2owner"]["private_key"],
    "owner_address": STANDARD_ACCOUNTS["l2owner"]["address"],
    
    "sequencer_key_name": "sequencer", 
    "sequencer_private_key": STANDARD_ACCOUNTS["sequencer"]["private_key"],
    "sequencer_address": STANDARD_ACCOUNTS["sequencer"]["address"],
    
    "validator_key_name": "validator",
    "validator_private_key": STANDARD_ACCOUNTS["validator"]["private_key"], 
    "validator_address": STANDARD_ACCOUNTS["validator"]["address"],
    
    # Service configuration
    "simple_mode": True,  # Single node doing sequencer + staker + poster
    "validator_count": 1,
    "batch_poster_count": 0,  # Only used if simple_mode is False
    "enable_bridge": True,
    "enable_explorer": True,
    
    # Pre-fund these accounts in L1 genesis (matches nitro-testnode)
    "pre_fund_accounts": ["funnel", "sequencer", "validator", "l2owner", "auctioneer"],
    
    # Docker images
    "nitro_image": "offchainlabs/nitro-node:v3.5.5-90ee45c",
    "nitro_contracts_branch": "v2.1.1-beta.0",
    "token_bridge_branch": "v1.2.2",
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
    
    # Handle nested orbit_config structure
    if "orbit_config" in args:
        orbit_config = args["orbit_config"]
        for key, value in orbit_config.items():
            if key in config_dict:
                config_dict[key] = value
    else:
        # Handle flat structure
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
    
    # Validate validator count
    if config.validator_count < 0:
        fail("Validator count must be non-negative")
    
    # Validate private keys
    if not config.owner_private_key or len(config.owner_private_key) != 64:
        fail("Owner private key must be 64 characters (32 bytes) long without '0x' prefix")
    
    if not config.sequencer_private_key or len(config.sequencer_private_key) != 64:
        fail("Sequencer private key must be 64 characters (32 bytes) long without '0x' prefix")
    
    # Validate addresses
    if not config.owner_address or not config.owner_address.startswith("0x"):
        fail("Owner address must be a valid Ethereum address starting with '0x'")
    
    if not config.sequencer_address or not config.sequencer_address.startswith("0x"):
        fail("Sequencer address must be a valid Ethereum address starting with '0x'")

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
    
    # If key names are provided, override with standard account values
    if "owner_key_name" in config_dict and config_dict["owner_key_name"] in STANDARD_ACCOUNTS:
        account = STANDARD_ACCOUNTS[config_dict["owner_key_name"]]
        config_dict["owner_private_key"] = account["private_key"]
        config_dict["owner_address"] = account["address"]
    
    if "sequencer_key_name" in config_dict and config_dict["sequencer_key_name"] in STANDARD_ACCOUNTS:
        account = STANDARD_ACCOUNTS[config_dict["sequencer_key_name"]]
        config_dict["sequencer_private_key"] = account["private_key"]
        config_dict["sequencer_address"] = account["address"]
    
    if "validator_key_name" in config_dict and config_dict["validator_key_name"] in STANDARD_ACCOUNTS:
        account = STANDARD_ACCOUNTS[config_dict["validator_key_name"]]
        config_dict["validator_private_key"] = account["private_key"]
        config_dict["validator_address"] = account["address"]
    
    # Create a new struct with the updated values
    return struct(**config_dict)

def get_prefunded_accounts_json(config):
    """
    Generate JSON for prefunding accounts in the Ethereum genesis block
    Based on nitro-testnode's account funding approach
    
    Args:
        config: Configuration object
        
    Returns:
        JSON string of accounts to prefund
    """
    accounts = {}
    
    # Pre-fund all standard accounts that should be funded
    for acc_name in config.pre_fund_accounts:
        if acc_name in STANDARD_ACCOUNTS:
            # Fund with 1000 ETH each (matching nitro-testnode)
            accounts[STANDARD_ACCOUNTS[acc_name]["address"]] = {
                "balance": "1000000000000000000000"  # 1000 ETH in wei
            }
    
    # Always ensure owner and sequencer have funds
    accounts[config.owner_address] = {"balance": "1000000000000000000000"}
    accounts[config.sequencer_address] = {"balance": "1000000000000000000000"}
    
    # Add the special deployer account (used in nitro-testnode geth genesis)
    accounts["0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E"] = {
        "balance": "1000000000000000000000000000000000"  # Very large balance for deployer
    }
    
    return json.encode(accounts)

def get_account_by_name(name):
    """
    Get account information by name
    
    Args:
        name: Account name (e.g., "sequencer", "validator", etc.)
        
    Returns:
        Account dictionary with private_key and address
    """
    if name in STANDARD_ACCOUNTS:
        return STANDARD_ACCOUNTS[name]
    else:
        fail("Unknown account name: " + name + ". Available accounts: " + str(list(STANDARD_ACCOUNTS.keys())))