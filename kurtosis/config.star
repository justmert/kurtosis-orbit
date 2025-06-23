"""
Configuration module with validation and nitro-testnode alignment.
"""

# Standard test mnemonic used by nitro-testnode (same as Hardhat/Ganache)
L1_MNEMONIC = "indoor dish desk flag debris potato excuse depart ticket judge file exit"

# Derived from mnemonic - these are the core accounts used by the system
STANDARD_ACCOUNTS = {
    "funnel": {
        "private_key": "b6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659",
        "address": "0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E",
        "description": "General funding and testing account"
    },
    "sequencer": {
        "private_key": "cb5790da63720727af975f42c79f69918580209889225fa7128c92402a6d3a65",
        "address": "0xe2148eE53c0755215Df69b2616E552154EdC584f",
        "description": "Operates the sequencer node"
    },
    "validator": {
        "private_key": "182fecf15bdf909556a0f617a63e05ab22f1493d25a9f1e27c228266c772a890",
        "address": "0x6A568afe0f82d34759347bb36F14A6bB171d2CBe",
        "description": "Operates validator nodes"
    },
    "l3owner": {
        "private_key": "ecdf21cb41c65afb51f91df408b7656e2c8739a5877f2814add0afd780cc210e",
        "address": "0x863c904166E801527125D8672442D736194A3362",
        "description": "L3 chain owner (for L3 deployments)"
    },
    "l3sequencer": {
        "private_key": "90f899754eb42949567d3576224bf533a20857bf0a60318507b75fcb3edc6f5f",
        "address": "0x3E6134aAD4C4d422FF2A4391Dc315c4DDf98D1a5",
        "description": "L3 sequencer (for L3 deployments)"
    },
    "l2owner": {
        "private_key": "dc04c5399f82306ec4b4d654a342f40e2e0620fe39950d967e1e574b32d4dd36",
        "address": "0x5E1497dD1f08C87b2d8FE23e9AAB6c1De833D927",
        "description": "L2 chain owner"
    },
}

# Default prefunded accounts for development
DEFAULT_PREFUNDED_ACCOUNTS = [
  {
    "name": "Development account 1",
    "address": "0x2093882c87B768469fbD434973bc7a4d20f73a51",
    "privateKey": "0xe81662053657623793d767b6cb13e614f6c6916b1488de33928baea8ce513c4c",
    "balance_eth": "100",
    "description": "Development account 1"
  },
  {
    "name": "Development account 2",
    "address": "0x6D819ceDC7B20b8F755Ec841CBd5934812Cbe13b",
    "privateKey": "0x203298e6a2b845c6dde179f3f991ae4c081ad963e20c9fe39d45893c00a0aea5",
    "balance_eth": "100",
    "description": "Development account 2"
  },
  {
    "name": "Development account 3",
    "address": "0xCE46e65a7A7527499e92337E5FBf958eABf314fa",
    "privateKey": "0x237112963af91b42ca778fbe434a819b7e862cd025be3c86ce453bdd3e633165",
    "balance_eth": "100",
    "description": "Development account 3"
  },
  {
    "name": "Development account 4",
    "address": "0xdafa61604B4Aa82092E1407F8027c71026982E6f",
    "privateKey": "0xdbd4bf6a5edb48b1819a2e94920c156ff8296670d5df72e4b8a22df0b6ce573d",
    "balance_eth": "100",
    "description": "Development account 4"
  },
  {
    "name": "Development account 5",
    "address": "0x1663f734483ceCB07AD6BC80919eA9a5cdDb7FE9",
    "privateKey": "0xae804cd43a8471813628b123189674469b92e3874674e540b9567e9e986d394d",
    "balance_eth": "100",
    "description": "Development account 5"
  }
]


# Default configuration aligned with nitro-testnode
DEFAULT_CONFIG = {
    # Chain configuration
    "chain_name": "Orbit-Dev-Chain",
    "chain_id": 412346,
    "l1_chain_id": 1337,
    "rollup_mode": True,
    "challenge_period_blocks": 20,
    "stake_token": "0x0000000000000000000000000000000000000000",
    "base_stake": "0",
    
    # Account configuration
    "owner_private_key": STANDARD_ACCOUNTS["l2owner"]["private_key"],
    "owner_address": STANDARD_ACCOUNTS["l2owner"]["address"],
    "sequencer_private_key": STANDARD_ACCOUNTS["sequencer"]["private_key"],
    "sequencer_address": STANDARD_ACCOUNTS["sequencer"]["address"],
    "validator_private_key": STANDARD_ACCOUNTS["validator"]["private_key"],
    "validator_address": STANDARD_ACCOUNTS["validator"]["address"],
    
    # Node configuration
    "simple_mode": True,
    "validator_count": 1,
    "enable_bridge": True,
    "enable_explorer": True,
    # "enable_timeboost": False,
    
    # Funding configuration
    "standard_account_balance_l1": "100",  # ETH balance for standard accounts on L1
    "standard_account_balance_l2": "100",  # ETH balance for standard accounts on L2
    "pre_fund_accounts": ["funnel", "sequencer", "validator", "l2owner"],
    "prefund_addresses": [],  # Additional addresses to fund
    
    # Docker images and versions
    "nitro_image": "offchainlabs/nitro-node:v3.5.5-90ee45c",
    "nitro_contracts_branch": "v2.1.1-beta.0",
    "token_bridge_branch": "v1.2.2",
    "blockscout_image": "offchainlabs/blockscout:v1.1.0-0e716c8",
    "postgres_image": "postgres:13.6",
}

def process_config(args):
    """
    Process and validate user configuration.
    """
    # Start with defaults
    config_dict = dict(DEFAULT_CONFIG)
    
    # Merge user config with enhanced handling
    if "orbit_config" in args:
        orbit_config = args["orbit_config"]
        for key, value in orbit_config.items():
            if key == "rollup_mode":
                # Accept boolean or string for rollup_mode
                if type(value) == type(True):
                    config_dict["rollup_mode"] = value
                elif str(value).lower() == "anytrust":
                    config_dict["rollup_mode"] = False
                else:
                    config_dict["rollup_mode"] = True
            elif key in config_dict:
                config_dict[key] = value
            else:
                print("WARNING: Unrecognized config field '{}'; ignoring.".format(key))
        
        # Validate key/address consistency after merging
        if "owner_private_key" in orbit_config and "owner_address" not in orbit_config:
            fail("owner_address must be provided if owner_private_key is overridden")
        if "sequencer_private_key" in orbit_config and "sequencer_address" not in orbit_config:
            fail("sequencer_address must be provided if sequencer_private_key is overridden")
        if "validator_private_key" in orbit_config and "validator_address" not in orbit_config:
            fail("validator_address must be provided if validator_private_key is overridden")
    
    # Validate configuration
    validate_config(config_dict)
    
    # Generate dynamic values
    config_dict["jwt_secret"] = generate_jwt_secret()
    config_dict["val_jwt_secret"] = generate_jwt_secret()
    
    # Set derived values
    if not config_dict.get("owner_private_key"):
        config_dict["owner_private_key"] = STANDARD_ACCOUNTS["l2owner"]["private_key"]
        config_dict["owner_address"] = STANDARD_ACCOUNTS["l2owner"]["address"]
    
    return config_dict

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
    
    # Enhanced mode validation
    if not config["rollup_mode"]:
        print("WARNING: AnyTrust mode selected. Make sure a data availability service is configured.")
        if config.get("anytrust_config") == None:
            fail("AnyTrust mode requires an 'anytrust_config' with DAS settings.")
    
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

def get_all_prefunded_accounts(config):
    """
    Get a consolidated list of all accounts that should be prefunded.
    Returns a dict with account info including balances for L1 and L2.
    """
    accounts = {}
    
    # Add standard accounts
    for acc_name in config["pre_fund_accounts"]:
        if acc_name in STANDARD_ACCOUNTS:
            acc_info = STANDARD_ACCOUNTS[acc_name]
            # Funnel account needs extra balance to fund all other accounts
            if acc_name == "funnel":
                balance_l1 = "10000"  # Extra balance for funding other accounts
                balance_l2 = "10000"
            else:
                balance_l1 = config["standard_account_balance_l1"]
                balance_l2 = config["standard_account_balance_l2"]
            
            accounts[acc_info["address"]] = {
                "name": acc_name,
                "private_key": acc_info["private_key"],
                "balance_l1": balance_l1,
                "balance_l2": balance_l2,
                "description": acc_info["description"]
            }
    
    # Always fund the deployer account with extra balance
    deployer_address = "0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E"
    if deployer_address not in accounts:
        accounts[deployer_address] = {
            "name": "deployer",
            "private_key": STANDARD_ACCOUNTS["funnel"]["private_key"],
            "balance_l1": "10000",  # Large balance for deployments
            "balance_l2": "10000",
            "description": "Deployment account"
        }
    
    # Add default prefunded accounts
    for acc in DEFAULT_PREFUNDED_ACCOUNTS:
        if acc["address"] not in accounts:
            accounts[acc["address"]] = {
                "name": "dev_account",
                "private_key": None,
                "balance_l1": acc["balance_eth"],
                "balance_l2": acc["balance_eth"],
                "description": acc["description"]
            }
    
    # Add any custom prefund addresses
    if config["prefund_addresses"]:
        for addr in config["prefund_addresses"]:
            if addr.startswith("0x") and len(addr) == 42:
                if addr not in accounts:
                    accounts[addr] = {
                        "name": "custom",
                        "private_key": None,
                        "balance_l1": "100",
                        "balance_l2": "100",
                        "description": "Custom funded address"
                    }
            else:
                print("WARNING: Invalid address format '{}'; skipping prefund.".format(addr))
    
    return accounts

def get_prefunded_accounts_json(config):
    """
    Generate JSON for prefunding accounts in L1 genesis.
    """
    accounts = {}
    all_prefunded = get_all_prefunded_accounts(config)
    
    for addr, info in all_prefunded.items():
        # Convert ETH to wei (multiply by 10^18)
        balance_wei = str(int(float(info["balance_l1"]) * 1000000000000000000))
        accounts[addr] = {"balance": balance_wei}
    
    return json.encode(accounts)